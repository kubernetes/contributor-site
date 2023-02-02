---
title: "Section 2: Getting Into GitHub"
type: reveal
weight: 2
description: |
    Learn how the Kubernetes organization uses GitHub and how to work
    with repositories there.
---

# Section 2: Getting Into GitHub

---

# What you're about to learn

The first step to being a Kubernetes contributor is getting into GitHub! After this unit, you will:

* Understand GitHub capabilities and how Kubernetes uses it
* Understand fork and clone and be able to perform these on a repository
* Be able to complete the contributor license agreement (CLA) and make a first pull request

---

# What is GitHub?

* GitHub is a web service for managing software development with Git.
* It provides bug tracking, task management, hosted development environments, continuous integration, and [other important features](https://github.com/about).
* GitHub hosts the source code for many open source projects, including Kubernetes.

Working with GitHub is straightforward, but if you are new to it, it can seem complex. We want to make the process as easy as possible for you!

---

# How does Kubernetes use GitHub?

As one of the largest open source projects with thousands of contributors, Kubernetes relies on GitHub for organization and sharing information.

* [Kubernetes hosts multiple projects on GitHub](https://github.com/kubernetes/), including Kubernetes itself and the [Kubernetes Community repository](https://github.com/kubernetes/community).
* Contributions are managed using GitHub features such as issue tracking and pull requests.
* Organization membership is managed using GitHub accounts.
* There are four GitHub organizations used by the Kubernetes project: kubernetes, kubernetes-sigs, kubernetes-csi, and kubernetes-client. They contain over 300 projects.

---

# How do I set up my GitHub account?

You _probably_ already have a GitHub account, but just in case:

* If you don't have one yet, [create a GitHub account on their sign up page](https://github.com/signup). The Free plan works fine!
* Official members of the Kubernetes community need their GitHub accounts to [meet certain other requirements](https://github.com/kubernetes/community/blob/master/community-membership.md).

---

# Which GitHub features will I use as a contributor?

Now it's time to learn all of these extra GitHub features.

* Kubernetes uses a [fork and pull collaborative development model](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/getting-started/about-collaborative-development-models).
* To get started, you will need to understand:
    * Pull requests
    * Issue management
* Both will be covered in this course!

---

# What is a Contributor License Agreement (CLA)?

Once you are ready to contribute, you will have to jump through one small legal hoop, but we make it as easy as possible.

* The Kubernetes CLA gives Kubernetes the permission to use content and source code that you contribute.
* Kubernetes can only accept original source code from CLA signatories.
* If you change employers and still contribute to Kubernetes, you need to update your CLA.

---

# How do I sign a CLA?

* After you make your first pull request, a GitHub bot will walk you through the process.
* The process is [outlined in the Community repository](https://github.com/kubernetes/community/blob/master/CLA.md).

---

# Okay, you are ready to make your first pull request!

1. Visit the [Kubernetes Contributor Playground repository](https://github.com/kubernetes-sigs/contributor-playground).
2. Use the "Fork" button in the upper right corner to fork the repository to your own account.
3. In your new fork, [create a new branch](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-and-deleting-branches-within-your-repository).
4. Follow the directions to [clone the repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) to your workstation.
5. Make edits in your new branch and push those changes to your fork.
6. Back on GitHub, [create a pull request from your fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork).

<div class="bottom-nav">
    <a href="/docs/onboarding">Onboarding Index</a> | <a href="../03-pull-requests/">Next Section</a>
</div>
