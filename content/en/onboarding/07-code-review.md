---
title: "Section 7: Code Review"
type: reveal
weight: 7
description: |
    Find out everything there is to know about code review, including
    what to do when you need a reviewer.
---

# Section 7: Code Review

---

# What you're about to learn

In this unit, you will learn everything about getting your code contributions to Kubernetes reviewed. By the end of this unit, you will be able to:

* Understand the role of code reviews in the lifecycle of a pull request.
* Use your SIG process to get a senior contributor to review code for approval.

---

# What is a code review?

A code review is when other developers examine proposed changes and additions to source code.

* A code review validates new designs and implementations.
* Code review can also help newer developers learn the intricacies and architecture of existing code.

---

# Why are code reviews important?

Like testing, code reviews help make sure Kubernetes remains stable, reliable, and bug-free.

* With our huge contributor base, we need great guardrails to keep our code in good shape.
* Code reviews are a cornerstone of successful large software projects.
* Code reviews make sure that at least two pairs of eyes examine everything before integration into the main branch.

---

# Where does a code review fit into the process?

To understand code reviews, you need to understand pull requests first. Make sure you've finished that unit!

* After you have submitted a pull request, the bot will assign two reviewers to your changes.
* Their code reviews must be passed before your pull request will be accepted into the main branch.

---

# Who can review my code?

Anybody can review your code, but only approved reviewers can add the `lgtm` label to your PR, which marks it as ready for merging.

* Every SIG and section of the code base has its own approved reviewers.
* The requirements for becoming an approved reviewer differ across SIGs.
    * For an excellent example, [read about SIG-Node approvers and reviewers](https://github.com/kubernetes/community/blob/master/sig-node/sig-node-contributor-ladder.md#sig-node-reviewers-and-approvers).

---

# How can I make sure my changes pass review?

There are a number of points to keep in mind while preparing your pull request for review.

* Follow the project [coding conventions](https://github.com/kubernetes/community/blob/master/contributors/guide/coding-conventions.md).
* Write [good commit messages](https://chris.beams.io/posts/git-commit/).
* Break large changes into smaller patches that are easier to understand.
* Label your PR appropriately.
* Pay attention to the instructions the bot gives you.

The Contributor Guide has [more guidelines and tips for passing reviews](https://github.com/kubernetes/community/blob/master/contributors/guide/contributing.md#code-review).

---

# Help! My pull request isn't getting any reviews!

If you need help finding reviewers for your pull request, try one of the following:

* Post a message on the appropriate SIG's Slack channel.
* Ask for assistance on the [#pr-reviews Slack channel](https://kubernetes.slack.com/messages/pr-reviews).

<div class="bottom-nav">
    <a href="/onboarding">Onboarding Index</a> | <a href="../08-community/">Next Section</a>
</div>
