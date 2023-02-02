---
title: "Section 3: Pull Requests"
type: reveal
weight: 3
description: |
  Learn how to submit and manage pull requests for the different
  Kubernetes repositories.
---

# Section 3: Pull Requests

---

## Objectives

This unit will teach you all about how to submit and manage pull requests for the different Kuberenetes repositories. By the end of this unit, you will be able to:

* Reference and operate in the Kubernetes GitHub workflow
* Recognize common bots and their messages
* Respond to code comments and test failures

---

## What is a pull request?

Before we start teaching you how to use pull requests, we should tell you what they are!

* A pull request is how you communicate that you have a Git branch filled with completed changes that you wish to merge with a repository on GitHub.
* Pull requests allow contributors to collaborate, review code, run tests, and confirm critical details _before_ new changes are integrated into a project.
* You will frequently see a pull request called a “PR”.
* Kubernetes relies heavily on GitHub’s pull request system. The [GitHub docs have a thorough dive into pull requests](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests). [Go deeper!](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests)

---

## Where do I make a pull request?

Before creating a pull request, you should:

1. Figure out which repository and SIG is responsible for your changes.
2. Check to see if an issue already exists for your change, and if not open one.
3. Consider attending a SIG meeting and adding your issue to the agenda.
4. Discuss your issue on Slack or on the mailing list.

---

## How do I open a pull request?

You’ll want to review the basic pull request process you learned at the end of [Unit 2](../02-getting-into-github/).

* Every pull request [starts with a branch on your fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-and-deleting-branches-within-your-repository) of a Kubernetes project.
* You can create pull requests using the GitHub website, any of the GitHub tools, or some third-party GitHub interfaces.
* Take time to review the [GitHub Workflow documentation](https://www.kubernetes.dev/docs/guide/github-workflow/).

---

## How does Kubernetes use pull requests?

Kubernetes generally follows the standard GitHub pull request process, but there is a layer of additional Kubernetes specific (and sometimes SIG specific) differences.

* Right away, a bot starts adding automated labels to your PR.
* The bot helps you facilitate PR review. You can use [these commands to interact with the bot](https://prow.k8s.io/command-help).
* [You can learn more about the Kubernetes pull request process here.](https://www.kubernetes.dev/docs/guide/pull-requests/)

---

## How does the pull request review process work?

* Anyone can review a documentation pull request. Code pull requests require approved reviewers.
* In addition to code-related concerns, pull request reviews also look at:
    * Language and grammar
    * Content
    * Potential website changes

You can respond to comments from reviewers through comments or additional changes that you push to your development branch. [We will cover code review in a later unit.](../07-code-review)

---

## When are my pull requests run through tests?

* A bot runs your PR through a few pre-commit tests automatically.
* The results of these tests will be posted to your pull request’s discussion automatically.
* Once a reviewer adds the **ok-to-test** label, [the bot will run your changes through end-to-end (e2e) tests](https://www.kubernetes.dev/docs/guide/pull-requests/#how-the-e2e-tests-work).

---

## What do I do if my test fails?

* The test results should give some indication of what went wrong.
* Make changes, push them to your branch, and [continue iterating through the pull request process](https://www.kubernetes.dev/docs/guide/pull-requests/).

We will cover tests in more detail [in a later unit](../06-testing/).

<div class="bottom-nav">
    <a href="/docs/onboarding">Onboarding Index</a> | <a href="../04-issues-management/">Next Section</a>
</div>
