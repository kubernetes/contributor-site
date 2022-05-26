---
layout: blog
title: Prow and Tide for Kubernetes Contributors
date: 2022-05-31
slug: prow-and-tide-for-kubernetes-contributors
---

**Authors:** [Chris Short](https://github.com/chris-short)

---

In my work in the Kubernetes world, I look up a label or Prow command often. The systems behind the scenes ([Prow](https://prow.kubernetes.io/) and [Tide](https://pkg.go.dev/k8s.io/test-infra/prow/cmd/tide#section-readme)) are here to help Kubernetes Contributors get stuff done.

Labeling which SIG, WG, subproject, etc. is as important as the issue or PR having someone assigned. To quote [the docs](https://github.com/kubernetes/test-infra/blob/master/prow/cmd/tide/README.md), "Tide is a [Prow](https://github.com/kubernetes/test-infra/blob/master/prow/README.md) component for managing a pool of GitHub PRs that match a given set of criteria. It will automatically retest PRs that meet the criteria ('tide comes in') and automatically merge them when they have up-to-date passing test results ('tide goes out')."

Something that really helps move things along is the [label_sync](https://github.com/kubernetes/test-infra/blob/master/label_sync/labels.md#intro) tool along with the logic Prow and Tide bring to the community.

What actually prompted this article is the awesomely amazing folks on the Contributor Comms team saying, "I need to squash my commits and push that." Which immediately made me remember the wonder of the Tide label: [`tide/merge-method-squash`](https://github.com/kubernetes/test-infra/blob/master/label_sync/labels.md#tide/merge-method-squash)

That's right. Squashing your commits is a label away and the tooling will do the rest. To do this on your PR you'll need to comment with the following:

`/label tide/merge-method-squash`

These two pages document all the functionality available to Kubernetes contributors (either through labels or Prow). The biggest thing to remember is when a something is a label or a command:

* [Prow Command Help](https://prow.kubernetes.io/command-help)
* [test-infra/label_sync/labels.md](https://github.com/kubernetes/test-infra/tree/master/label_sync) (remember, all labels are preceded with `/label`)

Some of my more often used commands and labels:

* `/assign` (using it without adding a name assigns yourself)
* `/honk`
* `/(woof|bark|this-is-{fine|not-fine|unbearable})`
* `/remove-lifecycle stale` (when issues aren't touched for a period of time they're marked stale)
* `/shrug`
* `/label area/contributor-comms` (You can use this to flag down the contributor communications team for reviews, comments on any issue, feedback, etc.)
* `/label size/X` (Sizes are assigned automatically based on the number of lines changed in the PR)
* `/label do-not-merge/hold` (This one is used for many things; if your PR is a work in progress, needs to be held to a certain date, etc.)
* `/lgtm` (Adds or removes the 'lgtm' label which is typically used to gate merging)
* `/approve` (Approves a pull request; must be done by someone in the repo's OWNERS file)

What if you need a label that isn't available on a certain GitHub repository? I'm glad you asked! This PR demonstrates how to add labels to a repo: [https://github.com/kubernetes/test-infra/pull/24315](https://github.com/kubernetes/test-infra/pull/24315). You'll need to update the [labels.yaml file](https://github.com/kubernetes/test-infra/blob/master/label_sync/labels.yaml) (the configuration) and the [labels.md file](https://github.com/kubernetes/test-infra/blob/master/label_sync/labels.md) (documentation).

I've done this once in five years of contributing. But, it's good to write it down as it's something that isn't as trivial as you think because of the importance of the label_sync tooling.

These are a handful of the [commands](https://prow.kubernetes.io/command-help) and [labels](https://github.com/kubernetes/test-infra/blob/master/label_sync/labels.md) I enjoy. I'm sure there are many others that are helpful to folks. With that in mind, see if there's something you can benefit from in these resources. They are there to make working on Kubernetes a better experience. If you think there's some functionality missing, I'd invite you to drop a Slack message in [SIG ContribEx](https://kubernetes.slack.com/archives/C1TU9EB9S) or [SIG K8s Infra](https://kubernetes.slack.com/archives/CCK68P2Q2) to discuss.

**Huge shoutout**: To the folks that keep these systems humming along for the Kubernetes community. Couldn't do it without y'all.
