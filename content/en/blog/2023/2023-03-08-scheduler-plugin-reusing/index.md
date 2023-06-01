---
layout: blog
title: "Scheduler plugin reusing"
---

**Author:** Ukri Niemimuukko (Intel)

The Kubernetes Scheduler comes with a well-established [scheduling framework](https://kubernetes.io/docs/concepts/scheduling-eviction/scheduling-framework/) which allows for creating both in-tree and out-of-tree plugins. By the nature and design of the plugins, they do not have much in terms of dependencies between each other. This is intentional and a good thing, plugins can be disabled and enabled at will. But even such entities which aim to be cohesive and without coupling, could occasionally benefit from being able to reuse the code from existing plugins.

## The use-case

A particular use-case for such plugin reuse arose from the need of getting a score for topologies within a cluster based on the resource status of the topology, such as a rack, instead of scoring just the resource status of the individual nodes in that rack. The aim there, was to be able to bin-pack Pods to racks, and at other times to be able to find a rack for a Pod with very little resources in use at the moment. A plugin which gives the nodes in the best rack a score of 100, and the nodes in the worst rack a score of 0, and then gives nodes in other racks scores linearly between the two, would enable that.

Resource calculations and scoring of nodes is currently done quite nicely and with a well configurable interface within the _NodeResourcesFit_ plugin. It can be [configured](https://kubernetes.io/docs/reference/config-api/kube-scheduler-config.v1/#kubescheduler-config-k8s-io-v1-NodeResourcesFitArgs) to use different scoring strategies such as _LeastAllocated_ and _MostAllocated_. It does the job, and it does it well. Reinventing the wheel which has been implemented in _NodeResourcesFit_ for calculating of node resources, would seem like a lot of unnecessary, duplicated work. Ideally, one would take up topology resource calculations and scoring from where _NodeResourcesFit_ plugin left off, and form the topology score based on the scores already calculated for individual nodes.

## Alternative approaches for plugin reuse

### Ctrl-C, Ctrl-V

The simplest and probably most frowned upon code-reuse practice is of course copy-paste. Due to well known issues with copy-paste code, this approach can't be recommended, and is mentioned here only as an example of what not to do. Copy-pasting won't be any faster anyway, as you will see below.

### Plugin composition

Typically a valid option for reusing something is composition. Nothing really stops instantiating an existing plugin in the factory function of a new plugin, and then wrapping things up so that the implementation of the already existing plugin gets reused instead of rewriting the code.

A minimal example of such plugin composite reduces to three main parts. First, one declares the composite plugin interface(s) inside the new plugin's type:

```go
type CompositionExample struct {
	framework.ScorePlugin
}
```

The new plugin's type now has a placeholder for the ScorePlugin composite. Next, it needs to be instantiated in the new plugin's factory function:

```go
fit, err := noderesources.NewFit(args.CompositeArgs, handle, fts)
if err != nil {
	return nil, fmt.Errorf("fit instantiation failed: %w", err)
}

ce := CompositionExample{
	ScorePlugin: fit.(framework.ScorePlugin),
}
```

Above are the essential parts in order to get NodeResourceFit scores calculated, and it certainly didn't take too many lines of code. Normal plugin boilerplate is required of course as well, and the new plugin needs to be configured as an enabled score-plugin in the scheduler profile.

There are some caveats, as usual. Arguments for the composite are needed, which basically means the args of the new plugin needs to contain and validate the args for the composite also. That may look rather redundant in the scheduler configuration, especially in case the args match exactly what the _NodeResourcesFit_ plugin is doing for individual node scoring, anyhow. The other caveat is, that the new plugin is then running the same node resource calculations another time, which isn't ideal.

Putting these unfortunate drawbacks aside, getting the newly calculated node resource scores back to the new plugin is now only lacking a little bit of code:

```go
// NormalizeScore implements framework.ScoreExtensions.
func (ce *CompositionExample) NormalizeScore(ctx context.Context, state *framework.CycleState, p *v1.Pod, scores framework.NodeScoreList) *framework.Status {
	// logic for using and adjusting the incoming scores goes here
	return nil
}

// ScoreExtensions of the Score plugin.
func (ce *CompositionExample) ScoreExtensions() framework.ScoreExtensions {
	return ce
}
```

Notably `ScoreExtensions` function wasn't used from the composite, instead it was implemented again. By not returning nil it tells the framework to call the `NormalizeScore` function. That then receives the calculated node scores, which can be adjusted as necessary. Also the `NormalizeScore` of the composite could be called, but in the case of _NodeResourcesFit_ it isn't implemented. And there you have it, a composite plugin based on another plugin. Hook it up, generate all the boilerplate code which is needed for all new plugins, configure it with proper args and it will run.

The dependency to the composite does require some understanding of the composite code, and there may be some introduced fragility with having that dependency. For example, looking into the _NodeResourceFit_ plugin internals reveals that it utilizes the [framework.CycleState](https://github.com/kubernetes/kubernetes/blob/2f977fd8c400971deed365dcc437e519bce475f0/pkg/scheduler/framework/cycle_state.go#L42-L47) during running of other Plugin interfaces. Luckily during running of the `ScorePlugin` interface parts no such state is utilized, so in this case it wasn't necessary to add and run those other plugin interfaces. However should such a thing change in the composite plugin, then running of the composite using plugin might also require changes.

### More efficient and flexible alternative, plugin pipelining

Going through the exercise of building a new plugin via composition and realizing the caveats of such reuse raised some questions related to if and how things could be better in an ideal world. Such as:

* Could a plugin utilize scores from multiple other plugins?
* Could multiple new plugins utilize scores from the same plugin, without running the same scoring logic N times?
* Could the dependency to the reused plugin be made less fragile, reducing the coupling?
* Could reuse be achieved without duplicated args and configuring same algorithms the same way, twice (or more)?
* Could things be configured more dynamically instead of hard-coding to the sources one plugin uses another plugin?

These questions had the author thinking about finding a better solution than just composition. Also the documentation of the [framework.CycleState](https://github.com/kubernetes/kubernetes/blob/2f977fd8c400971deed365dcc437e519bce475f0/pkg/scheduler/framework/cycle_state.go#L42-L47) was looking rather tempting.

> **Warning**
> The following section is speculative and based on proof-of-concepting by the author. It doesn't represent what you can do with the Kubernetes scheduler at the time of writing. Some day the concept below might be part of Kubernetes, should the PoC develop into a successful KEP. For now, this is merely a sig-scheduling discussion item which shows the potential of the CycleState.

Ideally, a new plugin could ask for getting the scores from another plugin, or multiple plugins, without rerunning them. The tricky thing is, that plugins run highly parallel in order to execute faster. Thus proper synchronization would be needed. Also it would be ideal, if no changes to existing plugins would be required, and the framework would provide for plugins in need of reusing other plugins' results.

This got the author thinking, that if the `framework.CycleState` object could contain a channel for the scores, and if the framework would create such a channel when it is needed, then the parallel running plugins which are interested in score reuse, could wait for the scores to appear from such "ScoreChannels".

```go
// ScoreChannel for giving score results to other plugins.
type ScoreChannel struct {
	C chan framework.NodeScoreList
}
```

A little less than 80 framework lines of PoC-code later the now very dirty scheduler was able to pick up from the arguments of plugins, whether they wanted to use scores from other plugins, and it was creating such "ScoreChannels" into the `framework.CycleState` and wrote scores to them as requested. A couple of experimental plugins later it was possible to verify that indeed, plugin scoring graphs such as the following were entirely possible:

{{< figure src="diagram1.svg" alt="Plugins A, B, C and D with connections A->B, A->C, B->D, C->D">}}

Which makes a nice demo of the one-to-many and many-to-one pipelining possibilities for plugin score reusing.

However, the real use-case has a much more simplistic graph:

{{< figure src="diagram2.svg" alt="Plugins NodeResourcesFit and TopologyScorer with connection NodeResourcesFit->TopologyScorer">}}

As pseudo-code, the topology scoring would work like this, directly at `NormalizeScore` step. The `Score` step which runs before it can return zeros.

```go
// error handling omitted in this pseudo-code example
func (f *TopologyScorer) NormalizeScore(ctx context.Context, cycleState *framework.CycleState,
    p *v1.Pod, scores framework.NodeScoreList) *framework Status {
	// fetch score channel from cycleState by configured piped plugin name as the key
	c, _ := cycleState.Read(f.pipedPluginNameAsKey)
	// type assert as ScoreChannel
	s := c.(*frameworkruntime.ScoreChannel)
	// receive scores from channel (blocks until the scores are ready)
	inputScores := <-s.C

	// calculate score sums over all nodes with the selected topology key and same value for that key.
	// One sum for each topologyKey=value pair of the one topology key. Stored in map[topologyValue]int64.
	topologyScoreSums, _ := sumTopologyScores(f.frameworkHandle, inputScores, f.topologyKey)

	// from all the score sums for topologyKey=value pairs (for one topology key)
	// find minimum and maximum topology score sums (worst and best topology)
	minTopologyScoreSum, maxTopologyScoreSum := getMinAndMax(topologyScoreSums)

	// go through the given nodes and output normalized scores based on which topology
	// any given node belongs to
	for i := range scores {
		nodeName = scores[i].Name
		// based on the topology where the node belongs, fetch its topology score sum
		currentNodeTopologyScoreSum = getTopologyScoreSumOfNode(nodeName, topologyScoreSums,
		    f.frameworkHandle, f.topologyKey)
		// calculate score between 0-100 linearly based on distance from min and max
		scores[i].Score := linearize(currentNodeTopologyScoreSum, minTopologyScoreSum, maxTopologyScoreSum)
	}

	return nil
}
```

With `NodeResourcesFit` as the piped plugin, such a `TopologyScorer` could give scores based on overall resource status of the rack the nodes belong to, assuming a rack topology key would be used in configuring the `TopologyScorer`.

Even such a simple graph can reveal a lot of potential over simple composition. Namely:
 * It doesn't run node resource scoring twice
 * It doesn't require configuring node resource scoring for two plugins
 * It only depends on the reused plugin being able to provide node scores. Internal changes to the reused plugin won't break the plugin which reuses the results, as long as scores are created.
 * It allows changing the connected node score source plugin with a single value in plugin args. What used to be a hard-coded topology resource scorer composite, became a generic TopologyScorer which can use any other score plugin as the source. There are no changes needed to the reused plugins.

This sort of plugin connecting would allow creating simple, quickly running plugins which modify the node scores of the connected source plugin. For instance, a plugin which optionally normalizes and/or inverts (reverses) the scores of the connected source plugin, would be rather
trivial to create. The new plugin could choose to either alter the scores of the source, or output its own scores. The author experimented with multiple daisy-chained plugins which altered the original source plugin scores, and it worked fine. The obvious caveat lies in the plugins being single instances. It would be easy to normalize, reverse or otherwise change the scores of one plugin, but what if one would need to do it for two plugins? Solving that would require further innovating.

## Summary

There are several ways to do Kubernetes scheduler plugin reusing, ranging from strictly not recommended copy-pasting to composition and all the way to modifying the scheduler framework, depending on how efficient you need things to be. The scheduler framework includes built-in utilities such as the `CycleState`, and by no means does it prevent plugins from passing information between each other. The pieces are there, only thing currently missing is perhaps a bit of assisting from the side of the Scheduler framework runtime.

## Next steps

As per discussed in the sig-scheduling meetings, the topology resource scoring plugin will proceed with the more conservative composition approach, because it can get the job done without framework changes, associated risks and maintenance burden. However, if you find that it would indeed benefit your use-cases to be able to simply configure scheduler profiles in such a way that certain score plugins are connected, chime in at slack [#sig-scheduling].

[#sig-scheduling]: https://kubernetes.slack.com/messages/sig-scheduling/