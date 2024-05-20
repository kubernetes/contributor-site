---
layout: blog
title: "Introducing Hydrophone"
slug: introducing-hydrophone
date: 2024-05-23
author: "Ricky Sadowski (ICR)"
---

In the ever-changing landscape of Kubernetes, ensuring that clusters operate as intended is
essential. This is where conformance testing becomes crucial, verifying that a Kubernetes cluster
meets the required standards set by the community. Today, we're thrilled to introduce
[*Hydrophone*](https://github.com/kubernetes-sigs/hydrophone/), a lightweight runner designed to
streamline Kubernetes tests using the official conformance images released by the Kubernetes release
team.

## Simplified Kubernetes testing with Hydrophone

Hydrophone's design philosophy centers around ease of use. By starting the conformance image as a
pod within the *conformance* namespace, Hydrophone waits for the tests to conclude, then prints and
exports the results. This approach offers a hassle-free method for running either individual tests
or the entire [Conformance Test
Suite](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/conformance-tests.md).

## Key features of Hydrophone

- **Ease of Use**: Designed with simplicity in mind, Hydrophone provides an easy-to-use tool for
  conducting Kubernetes conformance tests.
- **Official Conformance Images**: It leverages the official conformance images from the Kubernetes
  Release Team, ensuring that you're using the most up-to-date and reliable resources for testing.
- **Flexible Test Execution**: Whether you need to run a single test, the entire Conformance Test
  Suite, or anything in between.

## Streamlining Kubernetes conformance with Hydrophone

In the Kubernetes world, where providers like EKS, Rancher, and k3s offer diverse environments,
ensuring consistent experiences is vital. This consistency is anchored in conformance testing, which
validates whether these environments adhere to Kubernetes community standards. Historically, this
validation has either been cumbersome or requires third-party tools. Hydrophone offers a simple,
single binary tool that streamlines running these essential conformance tests. It's designed to be
user-friendly, allowing for straightforward validation of Kubernetes clusters against community
benchmarks, ensuring providers can offer a certified, consistent service.

Hydrophone doesn't aim to replace the myriad of Kubernetes testing frameworks out there but rather
to complement them. It focuses on facilitating conformance tests efficiently, without developing new
tests or heavy integration with other tools.

## Getting started with Hydrophone

Installing Hydrophone is straightforward. You need a Go development environment; once you have that:

```bash
go install sigs.k8s.io/hydrophone@latest
```

Running `hydrophone` by default will:

- Create a pod, and supporting resources in the `conformance` namespace on your cluster.
- Execute the entire conformance test suite for the cluster version you're running.
- Output the test results and export `e2e.log` and `junit_01.xml` needed for conformance validation.

There are supporting flags to specify which tests to run, which to skip, the cluster you're targeting and much more!

## Community and contributions

The Hydrophone project is part of SIG Testing and open to the community for bugs, feature requests,
and other contributions. You can engage with the project maintainers via Kubernetes Slack channels
*#hydrophone*, *#sig-testing*, and *#k8s-conformance*, or by filing an issue against the
repository. We're also active in the Kubernetes SIG-Testing and SIG-Release Mailing Lists. We
encourage pull requests and discussions to make Hydrophone even better.

## Join us in simplifying Kubernetes testing

In SIG Testing, we believe Hydrophone will be a valuable tool for anyone looking to validate the conformance of
their Kubernetes clusters easily. Whether you're developing new features, or testing your
application, Hydrophone offers an efficient testing experience.
