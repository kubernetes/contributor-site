---
layout: blog
title: "Spotlight on SIG Network"
slug: sig-network-spotlight
date: 2023-05-09
slug: sig-network-spotlight-2023
author: "Sujay Dey"
---

Networking is one of the core pillars of Kubernetes, and the Special Interest
Group for Networking (SIG Network) is responsible for developing and maintaining
the networking features of Kubernetes. It covers all aspects to ensure
Kubernetes provides a reliable and scalable network infrastructure for
containerized applications.

In this SIG Network spotlight, [Sujay Dey](https://twitter.com/Sujaystwt) talked
with [Shane Utt](https://twitter.com/ShaneUtt), Software Engineer at Kong, chair
of SIG Network and maintainer of Gateway API, on different aspects of the SIG,
what are the exciting things going on and how anyone can get involved and
contribute here.

**Sujay**: Hello, and first of all, thanks for the opportunity of learning more
about SIG Network. I would love to hear your story, so could you please tell us
a bit about yourself, your role, and how you got involved in Kubernetes,
especially in SIG Network?

**Shane**: Hello! Thank you for reaching out.

My Kubernetes journey started while I was working for a small data centre: we
were early adopters of Kubernetes and focused on using Kubernetes to provide
SaaS products. That experience led to my next position developing a distribution
of Kubernetes with a focus on networking. During this period in my career, I was
active in SIG Network (predominantly as a consumer).

When I joined [Kong][kong] my role in the community changed significantly, as
Kong actively encourages upstream participation. I greatly increased my
engagement and contributions to the [Gateway API][gwapi] project during those
years, and eventually became a maintainer.

I care deeply about this community and the future of our technology, so when a
chair position for the SIG became available, I volunteered my time immediately.
I've enjoyed working on Kubernetes over the better part of a decade and I want
to continue to do my part to ensure our community and technology continues to
flourish.

[kong]:https://konghq.com/
[gwapi]:https://gateway-api.sigs.k8s.io/

**Sujay**: I have to say, that was a truely inspiring journey! Now, let us talk
a bit more about SIG Network. Since we know it covers a lot of ground, could you
please highlight its scope and current focus areas?

**Shane**: For those who may be uninitiated: SIG Network is responsible for the
components, interfaces, and APIs which expose networking capabilities to
Kubernetes users and workloads. The [charter][net-charter] is a pretty good
indication of our scope, but I can add some additional highlights on some of our
current areas of focus (this is a non-exhaustive list of sub-projects):

**kube-proxy & KPNG**

Those familiar with Kubernetes will know the `Service` API, which enables
exposing a group of `Pods` over a network. The current standard implementation
of `Service` is known as `kube-proxy`, but what may be unfamiliar to people is
that there are a growing number of disparate alternative implementations on the
rise in recent years. To try and give provisions to these implementations (and
also provide some areas of alignment so that implementations do not become too
disparate from each other) upstream Kubernetes efforts are underway to create a
more modular public interface for `kube-proxy`. The intention is for
implementations to join in around a common set of libraries and speak a common
language. This area of focus is known as the KPNG project, and if this sounds
interesting to you, please join us in the KPNG [community meetings][meet] and
`#sig-network-kpng` on [Kubernetes Slack][kslack].

[meet]:https://github.com/kubernetes/community/blob/master/sig-network/README.md#meetings
[kslack]:https://kubernetes.slack.com/

**Multi-Network**

Today one of the primary requirements for Kubernetes networking is to achieve
connectivity between `Pods` in a cluster, satisfying a large number of
Kubernetes end-users. However, some use cases require isolated networks and
special interfaces for performance-oriented needs (e.g. `AF_XDP`, `memif`,
`SR-IOV`). There's a growing need for special networking configurations in
Kubernetes in general. The Multi-Network project exists to improve the
management of multiple different networks for `Pods`: anyone interested in some
of the lower-level details of `Pod` networking (or anyone having relevant use
cases) can join us in the Multi-Network community meetings and
`#sig-network-multi-network` on Kubernetes Slack.

**Network Policy**

The `NetworkPolicy` API sub-group was formed to address network security beyond
the well-known version 1 of the `NetworkPolicy` resource. We've also been
working on the `AdminNetworkPolicy` resource (previously known as
`ClusterNetworkPolicy`) to provide cluster administrator-focused functionality.
The network policy sub-project is a great place to join in if you're
particularly interested in security and CNI, please feel free to join our
community meetings and the `#sig-network-policy-api` channel on Kubernetes
Slack.

**Gateway API**

If you're specially interested in **ingress** or **mesh** networking the Gateway
API may be a sub-project you would enjoy. In Gateway API , we're actively
developing the successor to the illustrious `Ingress` API, which includes a
`Gateway` resource which defines the addresses and listeners of the gateway and
various routing types (e.g. `HTTPRoute`, `GRPCRoute`, `TLSRoute`, `TCPRoute`,
`UDPRoute`, etc.) that attach to `Gateways`. We also have an initiative within
this project called GAMMA, geared towards using Gateway API resources in a mesh
network context. There are some up-and-coming side projects within Gateway API
as well, including `ingress2gateway` which is a tool for compiling existing
`Ingress` resources to equivalent Gateway API resources and `Blixt`, a Layer4
implementation of Gateway API using Rust/eBPF for the data plane, intended as a
testing and reference implementation. If this sounds interesting, we would love
to have readers join us in our Gateway API community meetings and
`#sig-network-gateway-api` on Kubernetes Slack.



**Sujay**: Couldn’t agree more! That was a very informative description, thanks
for highlighting them so nicely. As you have already mentioned about the SIG
channels to get involved, would you like to add anything about where people like
beginners can jump in and contribute?


**Shane**: For help getting started [Kubernetes Slack][kslack] is a great place
to talk to community members and includes several `#sig-network-<project>`
channels as well as our main `#sig-network` channel. Also, check for issues
labelled `good-first-issue` if you prefer to just dive right into the
repositories. Let us know how we can help you!

[net-charter]:https://github.com/kubernetes/community/blob/master/sig-network/charter.md
[kslack]:https://kubernetes.slack.com/

**Sujay**: What skills are contributors to SIG Network likely to learn?

**Shane**: To me, it feels limitless. Practically speaking, it's very much up to
the individual what they _want_ to learn. However, if you just intend to learn
as much as you possibly can about networking, SIG Network is a great place to
join in and grow your knowledge.

If you've ever wondered how Kubernetes `Service` API works or wanted to
implement an ingress controller, this is a great place to join in. If you wanted
to dig down deep into the inner workings of CNI, or how the network interfaces
at the `Pod` level are configured, you can do that here as well.

We have an awesome and diverse community of people from just about every kind of
background you can imagine. This is a great place to share ideas and raise
proposals, improving your skills in design, as well as alignment and consensus
building.

There's a wealth of opportunities here in SIG Network. There are lots of places
to jump in, and the learning opportunities are boundless.

**Sujay**: Thanks a lot! It was a really great discussion, we got to know so
many great things about SIG Network. I'm sure that many others will find this
just as useful as I did.
