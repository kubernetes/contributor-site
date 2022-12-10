---
layout: blog
title: Prow and Tide for Kubernetes Contributors
date: 2022-12-12
slug: prow-and-tide-for-kubernetes-contributors
---

**Authors:** [Chris Short](https://github.com/chris-short), [Frederico Muñoz](https://github.com/fsmunoz)

---

In my work in the Kubernetes world, I look up a label or Prow command often. The systems behind the scenes
([Prow](https://prow.kubernetes.io/) and
[Tide](https://pkg.go.dev/k8s.io/test-infra/prow/cmd/tide#section-readme)) are here to help Kubernetes
Contributors get stuff done.

Labeling which SIG, WG, or subproject is as important as the issue or PR having someone assigned. To quote
[the docs](https://docs.prow.k8s.io/docs/components/core/tide/), "Tide is a
[Prow](https://docs.prow.k8s.io/docs/) component for managing a pool of GitHub PRs that match a given set of
criteria. It will automatically retest PRs that meet the criteria ('tide comes in') and automatically merge
them when they have up-to-date passing test results ('tide goes out')."

What actually prompted this article is the awesomely amazing folks on the [Contributor Comms
team](https://github.com/kubernetes/community/tree/master/communication) saying, "I need to squash my commits
and push that." Which immediately made me remember the wonder of the Tide label:
[`tide/merge-method-squash`](https://github.com/kubernetes/test-infra/blob/master/label_sync/labels.md#tide/merge-method-squash).

## Why is this helpful

Contributing to Kubernetes will, most of the time, involve some kind of git-based action, specifically on the
Kubernetes GitHub. This can be an obstacle to those less exposed to `git` and/or GitHub, and is especially
noticeable when we're dealing with non-code contributions (documentation, blog posts, etc.).


When a contributor submits something, it will generally be through a [pull
request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests). When
it comes to how the change will go from request to approval, there are a number of considerations that must be
made, such as:

* How should we request reviews?
* How do we assign the request to a specific SIG?
* How do we approve things while making it public and easily traceable?
* How to merge a contribution without carrying all the commit messages that were created during the review?

These are some of the main tasks in which Tide will help, allowing us to use the GitHub interface for these
tasks (and more), making the actions more visible to the community (since they are visible as plain comments
in the GitHub discussion), and allowing us to manage contributions without necessarily having to clone git
repositories or having to manually issue git commands.


## Back to squashing

One of the most common examples, and getting back to my initial one, is squashing commits: if someone makes a
change in a PR, there will likely be reviews and changes, and each one of them will add a new commit
message. If left like this, the PR will add to the main branch all the commit messages created during the
review process, which will make the history of the main branch less readable: instead of a [single informative
description about a specific unit of
work](https://www.kubernetes.dev/docs/guide/github-workflow/#squash-commits), it will contain multiple commit
messages that, out of the original context of the PR, will not be very helpful.

To avoid this, we can _squash_ the commit messages to keep just one of them (usually, the first one):
the changes will still be visible for anyone reading the PR, but they will appear as a single commit to the
main branch.

This can be done [through git](https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History), and a cursory read
of how it's done will not be obvious to someone relatively new to git! Is there a way to avoid cloning the
repository (or PR), issuing `git` commands locally, and pushing the changes?

There is, with Tide. Squashing your commits is a label away and the tooling will do the rest. To do this on
your PR you'll need to comment with the following:

`/label tide/merge-method-squash`

This will:

1. Trigger Tide to squash the messages prior to merging.
2. As a secondary effect, make your action clearly visible in the discussion section of the PR.

This use of Tide is one of the most useful when submitting changes that undergo changes during the PR
discussion, since it automates something to do The Right Thing (TM).

There's often nothing better than an example, so let's take a look at [this proposed change to the Kubernetes
website](https://github.com/kubernetes/website/pull/32685), on the topic of the `dockershim` removal FAQ. The
initial commit is [followed by several others](https://github.com/kubernetes/website/pull/32685/commits), a
result of the conversation and proposed reviews. The result of all those changes [is
merged](https://github.com/kubernetes/website/commit/a582a21cf00c88446a7feda4effd853b108c5c9c) as a single
commit, with the commit message retaining the title of the very first commit done, and the commit description
being the aggregate of all the commits done in the PR. This was achieved by using `/label
tide/merge-method-squash` [in a
comment](https://github.com/kubernetes/website/pull/32685#issuecomment-1085801034), and did away with the need
to manually rebase and/or squash using `git`: everything was possible through the GitHub interface.

## Assignment, review, approval.

Another area in which Prow and Tide are very useful is in dealing with assignments, reviews, and approvals.

Starting with **assignment**, the need to assign a PR to someone is very common. There are ways to do it
through the GitHub interface, but using Prow commands, as mentioned before, makes the actions more visible and
explicitly trigger the automation mechanism. Using `/assign` in a comment will assign the PR to yourself, or
reassign it to someone else.

Asking for **reviews** is another very common task: with Prow it's just a `/cc @foo @bar @baz` away, and this
can be directly added in the initial PR description, or in any subsequent comment.

**Approving** a PR is one area in which making the process easily visible is very important, and,
unsurprisingly, we can use `/lgtm` (_looks good to me_) to publicly state our agreement, and at the same time
trigger the automated processes that will, hopefully, result in the merging of the contribution. Using
`lgtm` adds (or, if using `/lgtm cancel`, removes) the `lgtm` label, while using `/approve` will approve the
PR for merging (and can only be used by those with the necessary authorization).

To summarize, `/assign` makes it public that an assignment as been made (I use it often when I need to assign
an issue to myself), and by who; `/lgtm` makes it clear from the comments that a review was made and,
automatically, adds the `lgtm` label which is required for approval, and `/approve` approves the PR for
merging.

An [example of many of these is this update to the Kubernetes Community
site](https://github.com/kubernetes/community/pull/6765): we can see how additional reviewers were added with
`/cc`, and following the discussion and changes, both the `/lgtm` and `/approve` commands are used to trigger
the merging.

More information on the review and approval cycle can be found [in the
documentation](https://kubernetes.io/docs/contribute/review/for-approvers/), which also explains in more
detail when should certain commands be used, and by who.

## More about Prow and Tide

The previous examples are some of the most commonly used, but Prow and Tide provide a lot more. These two
pages document all the functionality available to Kubernetes contributors (either through labels or Prow):

* [Prow Command Help](https://prow.kubernetes.io/command-help)
* [test-infra/label_sync/labels.md](https://github.com/kubernetes/test-infra/tree/master/label_sync)

Labels are most commonly applied by using an associated command (e.g. `/lgtm`, instead of `/label lgtm`): only
when no such command exists are labels applied directly with the `label` command; some of my more often used
commands and labels:

* `/assign` (using it without adding a name assigns yourself)
* `/honk`
* `/(woof|bark|this-is-{fine|not-fine|unbearable})`
* `/remove-lifecycle stale` (when issues aren't touched for a period of time they're marked stale)
* `/shrug`
* `/area contributor-comms` (You can use this to flag down the contributor communications team for reviews, comments on any issue, feedback, etc.)
* `/label size/X` (Sizes are assigned automatically based on the number of lines changed in the PR)
* `/hold` (This one is used for many things; if your PR is a work in progress, needs to be held to a certain date, etc.)
* `/lgtm` (Adds or removes the 'lgtm' label which is typically used to gate merging)
* `/approve` (Approves a pull request; must be done by someone in the repo's OWNERS file)

## More advanced usage

What if you need a label that isn't available on a certain GitHub repository? I'm glad you asked! This PR
demonstrates how to add labels to a repo:
[https://github.com/kubernetes/test-infra/pull/24315](https://github.com/kubernetes/test-infra/pull/24315). You'll
need to update the [labels.yaml
file](https://github.com/kubernetes/test-infra/blob/master/label_sync/labels.yaml) (the configuration) and the
[labels.md file](https://github.com/kubernetes/test-infra/blob/master/label_sync/labels.md) (documentation).

This is why the [label_sync](https://github.com/kubernetes/test-infra/blob/master/label_sync/labels.md#intro)
tool, along with the logic Prow and Tide, simplify GitHub-based processes: they allow the automation of common
actions without necessarily having to leave the web-based GitHub interface. `label_sync` ensures that labels
are applied uniformly across repositories.

I've done this once in five years of contributing. But, it's good to write it down as it's something that
isn't as trivial as you think because of the importance of the label_sync tooling.

These are a handful of the [commands](https://prow.kubernetes.io/command-help) and
[labels](https://github.com/kubernetes/test-infra/blob/master/label_sync/labels.md) I enjoy. I'm sure there
are many others that are helpful to folks. With that in mind, see if there's something you can benefit from in
these resources. They are there to make working on Kubernetes a better experience. If you think there's some
functionality missing, I'd invite you to drop a Slack message in [SIG
ContribEx](https://kubernetes.slack.com/archives/C1TU9EB9S) or [SIG
Testing](https://kubernetes.slack.com/archives/C09QZ4DQB) to discuss.

**Huge shoutout**: To the folks that keep these systems humming along for the Kubernetes community. Couldn't do it without y'all.
