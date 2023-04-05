---
layout: blog
title: "E2E Testing Best Practices, Reloaded"
date: 2023-04-12
slug: e2e-testing-best-practices-reloaded
author: "Patrick Ohly (Intel)"
---

End-to-end (E2E) testing in Kubernetes is how the project validates
functionality with real clusters. Contributors sooner or later encounter it
when asked to write E2E tests for new features or to help with debugging test
failures. Cluster admins or vendors might run the conformance tests, a subset
of all tests in the [E2E test
suite](https://github.com/kubernetes/kubernetes/tree/v1.27.0-rc.0/test/e2e).

The underlying [E2E
framework](https://github.com/kubernetes/kubernetes/tree/v1.27.0-rc.0/test/e2e/framework)
for writing these E2E tests has been around for a long
time. Functionality was added to it as needed, leading to code that became hard
to maintain and use. The [testing commons
WG](https://github.com/kubernetes/community/blob/master/sig-testing/README.md#testing-commons)
started cleaning it up, but dissolved before completely achieving their
goals.

After the [migration to Gingko
v2](https://github.com/kubernetes/kubernetes/pull/109111) in Kubernetes 1.25, I
picked up several of the loose ends and started untangling them. This blog post
is a summary of those changes. Some of this content is also found in the
Kubernetes contributor document about [writing good E2E
tests](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-testing/writing-good-e2e-tests.md)
and gets reproduced here to raise awareness that the document has been updated.

## Overall architecture

At the moment, the framework is used in-tree for testing against a cluster
(`test/e2e`), testing kubeadm (`test/e2e_kubeadm`) and kubelet
(`test/e2e_node`). The goal is to make the core `test/e2e/framework` a package
that has no dependencies on internal code and that can be used in different E2E
suites without polluting them with features or options that make no sense for
them. This is currently only a *technical* goal. There are no plans anymore to
actually move the code into a staging repository.

The framework acts like a normal client of an apiserver and thus doesn't need
much more than client-go. Since [the sub-package
refacoring](https://github.com/kubernetes/kubernetes/pull/112043), additional
sub-packages like `test/e2e/framework/pod` depend on the framework, not the
other way around. Those other sub-packages therefore can still use internal
code. The import boss configuration enforces [these
constraints](https://github.com/kubernetes/kubernetes/pull/115710).

What's left to clean up is that the framework contains a `TestContext` with
fields that are used only by some tests or some test suites. The [configuration
for `test/e2e_node`](https://github.com/kubernetes/kubernetes/blob/330b5a2b8dbd681811cb8235947557c99dd8e593/test/e2e/framework/test_context.go#L237-L263)
is the last remaining dependency on internal code. Such settings should get
moved into the different test suites and/or tests. The advantage besides
avoiding such dependencies will be that they will only show up in the command
line of a suite when the option really has an effect.

## Debuggability

If your test fails, it should provide as detailed as possible reasons for the
failure in its failure message. The failure message is the string that gets
passed (directly or indirectly) to `ginkgo.Fail[f]`. That text is what gets
shown in the overview of failed tests for a Prow job and what gets aggregated
by https://go.k8s.io/triage.

A good failure message:
- identifies the test failure
- has enough details to provide some initial understanding of what went wrong

It's okay for it to contain information that changes during each test
run. Aggregation [simplifies the failure message with regular
expressions](https://github.com/kubernetes/test-infra/blob/d56bc333ae8acf176887a3249f750e7a8e0377f0/triage/summarize/text.go#L39-L69)
before looking for similar failures.

Helper libraries like [Gomega](https://onsi.github.io/gomega/) or
[testify](https://pkg.go.dev/github.com/stretchr/testify) can be used to
produce informative failure messages. Gomega is a bit easier to use in
combination with Ginkgo.

The E2E framework itself only has one helper function for assertions that is
still recommended. The others are deprecated. Compared to
`gomega.Expect(err).NotTo(gomega.HaveOccurred())`,
`framework.ExpectNoError(err)` is shorter and produces better failure
messages because it logs the full error and then includes only the shorter
`err.Error()` in the failure message.

As with any other assertion, it is recommended to include additional context in
cases where the parameters being checked by an assertion helper lack relevant
information:

```
framework.ExpectNoError(err, "tried creating %d foobars, only created %d", foobarsReqd, foobarsCreated)
```

Use assertions that match the check in the test. Using Go
code to evaluate some condition and then checking the result often isn't
informative. For example this check should be avoided:

```
gomega.Expect(strings.Contains(actualStr, expectedSubStr)).To(gomega.Equal(true))
```

[Comparing a boolean](https://github.com/kubernetes/kubernetes/issues/105678)
like this against `true` or `false` with `gomega.Equal` or
`framework.ExpectEqual` is not useful because dumping the actual and expected
value just distracts from the underlying failure reason.
Better pass the actual values to Gomega, which will automatically include them in the
failure message. Add an annotation that explains what the assertion is about:

```
gomega.Expect(actualStr).To(gomega.ContainSubstring("xyz"), "checking log output")
```

This produces the following failure message:
```
  [FAILED] checking log output
  Expected
      <string>: hello world
  to contain substring
      <string>: xyz
```

If there is no suitable Gomega assertion, call `ginkgo.Failf` directly:
```
import "github.com/onsi/gomega/format"

ok := someCustomCheck(abc)
if !ok {
    ginkgo.Failf("check xyz failed for object:\n%s", format.Object(abc))
}
```

It is good practice to include details like the object that failed some
assertion in the failure message because then a) the information is available
when analyzing a failure that occurred in the CI and b) it only gets logged
when some assertion fails. Always dumping objects via log messages can make the
test output very large and may distract from the relevant information.

Dumping structs with `format.Object` is recommended. Starting with Kubernetes
1.26, `format.Object` will pretty-print Kubernetes API objects or structs [as
YAML and omit unset
fields](https://github.com/kubernetes/kubernetes/pull/113384), which is more
readable than other alternatives like `fmt.Sprintf("%+v")`.

    import (
        "fmt"
        "k8s.io/api/core/v1"
        "k8s.io/kubernetes/test/utils/format"
    )
    
    var pod v1.Pod
    fmt.Printf("Printf: %+v\n\n", pod)
    fmt.Printf("format.Object:\n%s", format.Object(pod, 1 /* indent one level */))
    
    =>
    
    Printf: {TypeMeta:{Kind: APIVersion:} ObjectMeta:{Name: GenerateName: Namespace: SelfLink: UID: ResourceVersion: Generation:0 CreationTimestamp:0001-01-01 00:00:00 +0000 UTC DeletionTimestamp:<nil> DeletionGracePeriodSeconds:<nil> Labels:map[] Annotations:map[] OwnerReferences:[] Finalizers:[] ManagedFields:[]} Spec:{Volumes:[] InitContainers:[] Containers:[] EphemeralContainers:[] RestartPolicy: TerminationGracePeriodSeconds:<nil> ActiveDeadlineSeconds:<nil> DNSPolicy: NodeSelector:map[] ServiceAccountName: DeprecatedServiceAccount: AutomountServiceAccountToken:<nil> NodeName: HostNetwork:false HostPID:false HostIPC:false ShareProcessNamespace:<nil> SecurityContext:nil ImagePullSecrets:[] Hostname: Subdomain: Affinity:nil SchedulerName: Tolerations:[] HostAliases:[] PriorityClassName: Priority:<nil> DNSConfig:nil ReadinessGates:[] RuntimeClassName:<nil> EnableServiceLinks:<nil> PreemptionPolicy:<nil> Overhead:map[] TopologySpreadConstraints:[] SetHostnameAsFQDN:<nil> OS:nil HostUsers:<nil> SchedulingGates:[] ResourceClaims:[]} Status:{Phase: Conditions:[] Message: Reason: NominatedNodeName: HostIP: PodIP: PodIPs:[] StartTime:<nil> InitContainerStatuses:[] ContainerStatuses:[] QOSClass: EphemeralContainerStatuses:[] Resize:}}

    format.Object:
        <v1.Pod>: 
            metadata:
              creationTimestamp: null
            spec:
              containers: null
            status: {}

## Recovering from test failures

All tests should ensure that a cluster is restored to the state that it was in
before the test ran. [`ginkgo.DeferCleanup`
](https://pkg.go.dev/github.com/onsi/ginkgo/v2#DeferCleanup) is recommended for
this because it can be called similar to `defer` directly after setting up
something. It is better than `defer` because Ginkgo will show additional
details about which cleanup code is running and (if possible) handle timeouts
for that code (see next section). Is is better than `ginkgo.AfterEach` because
it is not necessary to define additional variables and because
`ginkgo.DeferCleanup` executes code in the more useful last-in-first-out order,
i.e. things that get set up first get removed last.

Objects created in the test namespace do not need to be deleted because
deleting the namespace will also delete them. However, if deleting an object
may fail, then explicitly cleaning it up is better because then failures or
timeouts related to it will be more obvious.

In cases where the test may have removed the object, `framework.IgnoreNotFound`
can be used to ignore the "not found" error:
```
podClient := f.ClientSet.CoreV1().Pods(f.Namespace.Name)
pod, err := podClient.Create(ctx, testPod, metav1.CreateOptions{})
framework.ExpectNoError(err, "create test pod")
ginkgo.DeferCleanup(framework.IgnoreNotFound(podClient.Delete), pod.Name, metav1.DeleteOptions{})
```

## Interrupting tests

When aborting a manual `gingko ./test/e2e` invocation with CTRL-C or a signal,
the currently running test(s) should stop immediately. This gets achieved by
accepting a `ctx context.Context` as first parameter in the Ginkgo callback
function and then passing that context through to all code that might
block. When Ginkgo notices that it needs to shut down, it will cancel that
context and all code trying to use it will immediately return with a `context
canceled` error. Cleanup callbacks get a new context which will time out
eventually to ensure that tests don't get stuck. For a detailed description,
see https://onsi.github.io/ginkgo/#interrupting-aborting-and-timing-out-suites.
Most of the E2E tests [were update to use the Ginkgo
context](https://github.com/kubernetes/kubernetes/pull/112923) at the start of
the 1.27 development cycle.

There are some gotchas:

- Don't use the `ctx` passed into `ginkgo.It` in a `ginkgo.DeferCleanup`
  callback because the context will be canceled when the cleanup code
  runs. This is wrong:

        ginkgo.It("something", func(ctx context.Context) {
              ...
              ginkgo.DeferCleanup(func() {
                  // do something with ctx
              })
        })

  Instead, register a function which accepts a new context:

         ginkgo.DeferCleanup(func(ctx context.Context) {
             // do something with the new ctx
         })

  Anonymous functions can be avoided by passing some existing function and its
  parameters directly to `ginkgo.DeferCleanup`. Again, beware to *not* pass the
  wrong `ctx`. This is wrong:

        ginkgo.It("something", func(ctx context.Context) {
              ...
              ginkgo.DeferCleanup(myDeleteFunc, ctx, objName)
        })

  Instead, just pass the other parameters and let `ginkgo.DeferCleanup`
  add a new context:

        ginkgo.DeferCleanup(myDeleteFunc, objName)

- When starting some background goroutine in a `ginkgo.BeforeEach` callback,
  use `context.WithCancel(context.Background())`. The context passed into the
  callback will get canceled when the callback returns, which would cause the
  background goroutine to stop before the test runs. This works:

        backgroundCtx, cancel := context.WithCancel(context.Background())
        ginkgo.DeferCleanup(cancel)
        _, controller = cache.NewInformer( ... )
        go controller.Run(backgroundCtx.Done())

- When adding a timeout to the context for one particular operation,
  beware of overwriting the `ctx` variable. This code here applies
  the timeout to the next call and everything else that follows:

        ctx, cancel := context.WithTimeout(ctx, 5 * time.Second)
        defer cancel()
        someOperation(ctx)
        ...
        anotherOperation(ctx)

  Better use some other variable name:

        timeoutCtx, cancel := context.WithTimeout(ctx, 5 * time.Second)
        defer cancel()
        someOperation(timeoutCtx)

  When the intention is to set a timeout for the entire callback, use
  [`ginkgo.NodeTimeout`](https://pkg.go.dev/github.com/onsi/ginkgo/v2#NodeTimeout):

        ginkgo.It("something", ginkgo.NodeTimeout(30 * time.Second), func(ctx context.Context) {
        })

  There is also a `ginkgo.SpecTimeout`, but that then also includes the time
  taken for `BeforeEach`, `AfterEach` and `DeferCleanup` callbacks.

## Polling and timeouts

When waiting for something to happen, use a reasonable timeout. Without it, a
test might keep running until the entire test suite gets killed by the
CI. Beware that the CI under load may take a lot longer to complete some
operation compared to running the same test locally. On the other hand, a too
long timeout can be annoying when trying to debug tests locally.

The framework provides some [common
timeouts](https://github.com/kubernetes/kubernetes/blob/eba98af1d8b19b120e39f3/test/e2e/framework/timeouts.go#L44-L109)
through the [framework
instance](https://github.com/kubernetes/kubernetes/blob/1e84987baccbccf929eba98af1d8b19b120e39f3/test/e2e/framework/framework.go#L122-L123).
When writing a test, check whether one of those fits before defining a custom
timeout in the test.

Good code that waits for something to happen meets the following criteria:
- accepts a context for test timeouts
- informative during interactive use (i.e. intermediate reports, either
  periodically or on demand)
- little to no output during a CI run except when it fails
- full explanation when it fails: when it observes some state and then
  encounters errors reading the state, then dumping both the latest
  observed state and the latest error is useful
- extension mechanism for writing custom checks
- early abort when condition cannot be reached anymore

[`gomega.Eventually`](https://pkg.go.dev/github.com/onsi/gomega#Eventually)
satisfies all of these criteria and therefore is recommended, but not required.
In https://github.com/kubernetes/kubernetes/pull/113298,
[test/e2e/framework/pods/wait.go](https://github.com/kubernetes/kubernetes/blob/222f65506252354da012c2e9d5457a6944a4e681/test/e2e/framework/pod/wait.go)
and the framework were modified to use gomega. Typically, `Eventually` is
passed a function which gets an object or lists several of them, then `Should`
checks against the expected result. Errors and retries specific to Kubernetes
are handled by [wrapping client-go
functions](https://github.com/kubernetes/kubernetes/blob/master/test/e2e/framework/get.go).

Using normal Gomega assertions in helper packages is problematic for two reasons:
- The stacktrace associated with the failure starts with the helper unless
  extra care is take to pass in a stack offset.
- Additional explanations for a potential failure must be prepared beforehand
  and passed in.

The E2E framework therefore uses a different approach:
- [`framework.Gomega()`](https://github.com/kubernetes/kubernetes/blob/222f65506252354da012c2e9d5457a6944a4e681/test/e2e/framework/expect.go#L80-L101)
  offers similar functions as the `gomega` package, except that they return a
  normal error instead of failing the test.
- That error gets wrapped with `fmt.Errorf("<explanation>: %w)` to
  add additional information, just as in normal Go code.
- Wrapping the error (`%w` instead of `%v`) is important because then
  `framework.ExpectNoError` directly uses the error message as failure without
  additional boiler plate text. It also is able to log the stacktrace where
  the error occurred and not just where it was finally treated as a test
  failure.

## Tips for writing and debugging long-running tests

- Use `ginkgo.By` to record individual steps. Ginkgo will use that information
  when describing where a test timed out.

- Invoke the `ginkgo` CLI with `--poll-progress-after=30s` or some other
  suitable duration to [be informed
  early](https://onsi.github.io/ginkgo/#getting-visibility-into-long-running-specs)
  why a test doesn't complete and where it is stuck. A SIGINFO or SIGUSR1
  signal can be sent to the CLI and/or e2e.test processes to trigger an
  immediate progress report.

- Use [`gomega.Eventually`](https://pkg.go.dev/github.com/onsi/gomega#Eventually)
  to wait for some condition. When it times out or
  gets stuck, the last failed assertion will be included in the report
  automatically. A good way to invoke it is:

        gomega.Eventually(ctx, func(ctx context.Context) (book Book, err error) {
            // Retrieve book from API server and return it.
            ...
         }).WithPolling(5 * time.Second).WithTimeout(30 * time.Second).
         Should(gomega.HaveField("Author.DOB.Year()", BeNumerically("<", 1900)))

  Avoid testing for some condition inside the callback and returning a boolean
  because then failure messages are not informative (see above). See
  https://github.com/kubernetes/kubernetes/pull/114640 for an example where
  [gomega/gcustom](https://pkg.go.dev/github.com/onsi/gomega@v1.27.2/gcustom)
  was used to write assertions.

  Some of the E2E framework sub-packages have helper functions that wait for
  certain domain-specific conditions. Currently most of these functions don't
  follow best practices (not using gomega.Eventually, error messages not very
  informative). [Work is
  planned](https://github.com/kubernetes/kubernetes/issues/106575) in that
  area, so beware that these APIs may
  change at some point.

- Use `gomega.Consistently` to ensure that some condition is true
  for a while. As with `gomega.Eventually`, make assertions about the
  value instead of checking the value with Go code and then asserting
  that the code returns true.

- Both `gomega.Consistently` and `gomega.Eventually` can be aborted early via
  [`gomega.StopPolling`](https://onsi.github.io/gomega/#bailing-out-early---polling-functions).

- Avoid polling with functions that don't take a context (`wait.Poll`,
  `wait.PollImmediate`, `wait.Until`, ...) and replace with their counterparts
  that do (`wait.PollWithContext`, `wait.PollImmediateWithContext`,
  `wait.UntilWithContext`, ...) or even better, with `gomega.Eventually`.

## Next steps

Using `wait.Poll` in E2E tests can be detected with
[forbidigo](https://github.com/ashanbrown/forbidigo) since [import alias
support](https://github.com/ashanbrown/forbidigo/pull/21) was merged. In
Kubernetes, that can be enabled in a golangci-lint invocation as soon as a
[configuration extension](https://github.com/golangci/golangci-lint/pull/3612)
is merged. Another
[enhancement](https://github.com/golangci/golangci-lint/pull/3617) would be
useful, but not absolutely required.

Because a lot of existing code wouldn't pass such a check, it probably will
only be enabled in the [new stricter pull request
linting](https://groups.google.com/a/kubernetes.io/g/dev/c/myGiml72IbM/m/BhQqP4_OAwAJ)
initially. Converting individual sub packages similar to
[`test/e2e/framework/pod`](https://github.com/kubernetes/kubernetes/pull/115548)
to match current best practices would be a good way for new contributors to get
involved.

The [SIG
Testing](https://github.com/kubernetes/community/blob/master/sig-testing/README.md)'s
Slack channel is a good place to start. At KubeCon EU 2023, the ["Keeping the
lights on and the bugs away"
talk](https://kccnceu2023.sched.com/event/1Hzcr/keeping-the-lights-on-and-the-bugs-away-patrick-ohly-intel)
will cover some of the material of this blog post. Catch me there or meet me at
the Intel booth to discuss this further!
