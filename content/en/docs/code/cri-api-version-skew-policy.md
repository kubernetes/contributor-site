---
content_type: "reference"
title: CRI API version skew policy
weight: 51
---

CRI is a plugin interface which enables the kubelet to use a wide variety of container runtimes,
without the need to recompile. CRI consists of a protocol buffers and gRPC API.
Read more about CRI API at [kubernetes docs](https://kubernetes.io/docs/concepts/architecture/cri/).

The CRI API is **only** intended to be used for the kubelet to container runtime
interactions, or for node-level troubleshooting using a tool such as `crictl`.
It is **not** a common purpose container runtime API for general use, and is **intended**
to be Kubernetes-centric. This is why there may be an undocumented logic
within a container runtimes that assumes the order or specific parameters
of call(s) that the kubelet makes. Attempts to call CRI API in a different order
by a client different than the kubelet, might result in unrecoverable error.
Whenever discovered, this logic is being documented and avoided.

## Version skew on a node

On a single Node there may be installed multiple components implementing
different versions of CRI API.

For example, on a single node there might be:

- _Kubelet_ may call into _Container Runtime_ (e.g. [containerd](https://containerd.io))
  and _Image Service Proxy_ (e.g. [stargz-snapshotter](https://github.com/containerd/stargz-snapshotter)).
  _Container Runtime_ may be versioned with the OS Image, _Kubelet_ is installed
  by system administrator and _Image Service proxy_ is versioned by the third party vendor.
- _Image Service Proxy_ calls into _Container Runtime_.
- _CRI tools_ (e.g. [crictl](https://kubernetes.io/docs/tasks/debug/debug-cluster/crictl/))
  may be installed by end user to troubleshoot, same as a third party daemonsets.
  All of them are used to call into the _Container Runtime_ to collect container information.

So on a single node it may happen that _Container Runtime_ is serving a newer
version'd kubelet and older versioned crictl. This is a supported scenario within
the version skew policy.

### Version Skew Policy for CRI API

CRI API has two versions:

- Major semantic version (known versions are
  `v1alpha2` ([removed in 1.26](https://kubernetes.io/blog/2022/12/09/kubernetes-v1-26-release/#cri-v1alpha2-removed)), `v1`).
- Kubernetes version (for example: `@1.23`). Note, the `cri-api` Golang library
  is versioned as `0.23` as it doesn't guarantee Go types backward compatibility.

Major semantic version (e.g. `v1`) is used to introduce breaking changes
and major new features that are incompatible with the current API.

Kubernetes version is used to indicate a specific feature set implemented
on top of the major semantic version. All changes made without the change
of a major semantic version API must be backward and forward compatible.

- _Kubelet_ must work with the older _Container Runtime_ if it implements
  the same semantic version of CRI API (e.g. `v1`) of up to three Kubernetes minor
  versions back. New features implemented in CRI API must be gracefully degraded.
  For example, _Kubelet_ of version 1.26 must work with _Container Runtime_
  implementing `k8s.io/cri-api@v0.23.0`+.
- _Kubelet_ must work with _Container Runtime_ if it implements
  the same semantic version of CRI API (e.g. `v1`) of up to
  three minor versions up. New features implemented in CRI API must not change
  behavior of old method calls and response values. For example, _Kubelet_ of
  version 1.22 must work with _Container Runtime_ implementing `k8s.io/cri-api@v0.25.5`.

## Versioning

This library contains go classes generated from the CRI API protocol buffers and gRPC API.

The library versioned as `0.XX` as Kubernetes doesn't provide any guarantees
on backward compatibility of Go wrappers between versions. However CRI API itself
(protocol buffers and gRPC API) is marked as stable `v1` version and it is
backward compatible between versions.

Versions like `v0.<minor>.<patch>` (e.g. `v0.25.5`) are considered stable.
It is discouraged to introduce CRI API changes in patch releases and recommended
to use versions like `v0.<minor>.0`.

All alpha and beta versions (e.g. `k8s.io/cri-api@v0.26.0-beta.0`) should be
backward and forward compatible.

## Feature development

Some features development requires changes in CRI API and corresponding changes
in _Container Runtime_. Coordinating between Kubernetes branches and release
versions and _Container Runtime_ versions is not always trivial.

The recommended feature development flow is following:

- Review proposed CRI API changes during the KEP review stage.
  Some field names and types may not be spelled out exactly at this stage.
- Locally implement a prototype that implement changes in both - Kubernetes and Container Runtime.
- Submit a Pull Request for Kubernetes implementing CRI API changes alongside the feature code.
  Feature must be developed to degrade gracefully when used with older Container Runtime
  according to the Version Skew policy.
- Once PR is merged, wait for the next Kubernetes release tag being produced.
  Find the corresponding CRI API tag (e.g. `k8s.io/cri-api@v0.26.0-beta.0`).
- This tag can be used to implement the feature in Container Runtime. It is recommended
  to switch to the stable tag like (`k8s.io/cri-api@v0.26.0`) once available.

### Designing new CRI APIs

The following are considerations to take into account designing new features:

1. The intended behavior, expectations, and call sequence, must be documented directly
   in the protocol definition to simplify runtime adoption.
2. The CRI API change must be as simple as possible. Choosing between simplicity and
   expressiveness, simplicity has a preference.
3. Existing fields must be reused only if their logical meaning allows it
   and does not interfere with the existing features. Changing the expected value
   format or call sequence may break things in a way that is hard to test and should be avoided.

### Feature testing

It is highly encouraged to add critest to every new CRI API.
Read about CRI API [validation](https://github.com/kubernetes-sigs/cri-tools/blob/master/docs/validation.md).

## What's next

- What is [Container Runtime Interface (CRI)](https://kubernetes.io/docs/concepts/architecture/cri/)
- [Kubernetes feature development and container runtimes](/docs/code/cri-api-dev-policies)
- [Installing Container Runtimes](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)