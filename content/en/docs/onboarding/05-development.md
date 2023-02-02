---
title: "Section 5: Getting Started with Kubernetes Development"
type: reveal
weight: 5
description: |
  This is the first unit of slides in the Kubernetes Contributor On-Boarding series.
---


# Section 5: Getting Started with Kubernetes Development

---

# What you’re about to learn

It’s time to set up a development environment so you can build Kubernetes. By end of this unit, you will:

* Know the various environments for building and developing Kubernetes
* Know where to find the Kubernetes Development Guide

---

# What are your options for a development environment?

There are three primary options, all with their own benefits and drawbacks.

1. Building Kubernetes with Docker
2. Building Kubernetes on your local OS and shell environment
3. Building Kubernetes with GitHub Codespaces

---

# Why build with Docker?

This method uses a containerized build environment. There are some good reasons to use it:

* Official releases are built using Docker containers.
* Initial setup is simple.
* This provides a very consistent build and test environment.

Read more about this method in [Building Kubernetes](https://github.com/kubernetes/kubernetes/blob/master/build/README.md).

---

# Why build using a local OS?

This method takes the most effort to set up. But it has its own advantages:

* You’ll have fine-grained control over all aspects of the build process.
* There is no overheard from a container system like Docker.

To set this method up, [follow the steps from the Development Guide](https://github.com/kubernetes/community/blob/master/contributors/devel/development.md#building-kubernetes-on-a-local-osshell-environment).

---

# Why build using GitHub Codespaces?

The newest method takes advantage of [GitHub Codespaces](https://github.com/features/codespaces) to provide a container-based development environment.

* All of your development resources (CPU, memory, and disk) are in the cloud.
* The only tool you need to install locally is a web browser!

To build Kubernetes with Codespaces, follow the steps in this document.

---

# What are the next steps?

Once you have a working development environment, you will be ready to develop and run tests against Kubernetes.

But first, we recommend that you [become familiar with the Development Guide](https://github.com/kubernetes/community/blob/master/contributors/devel/development.md).


<div class="bottom-nav">
    <a href="/docs/onboarding">Onboarding Index</a> | <a href="../06-testing/">Next Section</a>
</div>
