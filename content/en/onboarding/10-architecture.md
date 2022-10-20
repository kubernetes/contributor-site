---
title: "Section 10: Architecture and Enhancements"
type: reveal
weight: 10
description: |
    Dig into the guts of Kubernetes and learn about its architecture
    and how to change it.
---

# Section 10: Architecture and Enhancements

---

# What you’re about to learn

We’re getting into the guts of Kubernetes now! After this module, you will:

* Be able to locate the architecture documents for Kubernetes
* Understand how the different components interact
* Know how features and major changes are added to Kubernetes

---

# Where are the architecture documents?

The good news is that the Kubernetes architecture is very well documented.

* A great place to start is [this overview of Kubernetes components](https://kubernetes.io/docs/concepts/overview/components/).
* You can find the cluster architecture in the [Concepts section of the documentation](https://kubernetes.io/docs/concepts/architecture/).

---

# What are the components of a Kubernetes cluster?

A Kubernetes deployment is called a cluster. So what is it made of?

* The control plane makes global decisions about the cluster, as well as detecting and responding to cluster events
* [Compute resources, known as nodes](https://kubernetes.io/docs/concepts/architecture/nodes/), run pods and provide the Kubernetes runtime environment.
* [Pods are the smallest deployable units](https://kubernetes.io/docs/concepts/workloads/pods/) of computing that you can create and manage in Kubernetes.

You can also learn [how they communicate with each other](https://kubernetes.io/docs/concepts/architecture/control-plane-node-communication/).

---

# How are new features added to Kubernetes?

New features are added through a process that begins with a [Kubernetes Enhancement Proposal](https://github.com/kubernetes/enhancements/blob/master/keps/README.md).

KEPs are required for most non-trivial changes. Specifically:

* Anything that may be controversial
* Most new features
* Major changes to existing features
* Changes that are wide ranging or impact most of the project

---

# Who manages the Kubernetes Enhancement Proposal process?

First, we call it KEP for short. And second, the KEP process is managed by the Architecture Special Interest Group (SIG Architecture).

* To learn more, [read the SIG Architecture documentation](https://github.com/kubernetes/community/blob/master/sig-architecture/README.md).

<div class="bottom-nav">
    <a href="/onboarding">Onboarding Index</a>
</div>
