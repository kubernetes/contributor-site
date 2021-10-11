---
title: "Community Groups"
weight: 3
aliases: [ "/workshop/community-groups" ]
description: |
  The Kubernetes community is a large distributed team of people, and to
  help wrangle that team, we separate responsibilities and tasks into
  several different types groups.
---

# Community Group Types

All of these groups are defined in a specific repo, k/community -- you can see the shortcut to a specific file at the bottom

## Special Interest Groups (SIGs)

Persistent open groups that focus on a part of the project. 

SIGs are our foundation, and drive the majority of the work

## User Groups (UGs)

Groups for facilitating communication and discovery of information

User Groups - Provide a means for end users to collaborate along with a unifying voice to drive specific features

## Working Groups (WGs)

Temporary groups that are formed to address issues that cross SIG boundaries.

Working Groups are formed when there is a large task, feature or issue that involves multiple SIGs

## Committees

Sets of people that are chartered to take on sensitive topics.

Committees are elected and handle sensitive matters such as things related to the CoC

# Community Governance

* Special Interest Groups (SIGs)
  * Primary organizational unit
  * Topic specific (Networking, Doc, etc.)
* Subprojects
  * Work in SIGs divided into one or more subprojects
  * Every part of Kubernetes must be owned by subproject
* Working Groups (WGs)
  * Short-lived rallying point
  * Work spanning multiple SIGs

* Most of the groups with the project are SIGs, and they serve as the primary org unit. The others, largely, are there to support them.
* SIGs themselves can cover quite a bit, so they divide work and focus into different subprojects
  * Every part of Kubernetes MUST be owned by a subproject.
  * We’ll see where you can find this breakdown of ownership a little bit later, but most of the subprojects will directly own repos or parts of a repo.
* Working groups as I touched on earlier are ephemeral, they come together to do something and then disband.
  * A good example is the “apply” working group that is working on enabling server side apply which involves both sig-cli and sig-api-machinery

## User Groups

  * Facilitate communication between users and contributors
  * Topics include usage of, extension of, and integration with Kubernetes and Kubernetes subprojects
  * Examples:
    * Big Data
    * Cloud Providers
    * Machine Learning

User groups are the newest addition to the Kubernetes community groups.
* Provide a means for end users to collaborate along with a unifying voice to drive specific features
* They DO NOT own code.

## Committees

* Don't have open membership
  * Don't always operate in the open (Security or Code of Conduct)
  * Formed by Steering Committee
  * Committees:
    * Steering 
    * Product Security
    * Code of Conduct

* Lastly we have Committees
  * They tend to be a bit more private and deal with sensitive aspects such as security, or the Code of Conduct
  * The 3 committees the project has at the moment are
    * Steering
    * Product Security
    * Code of Conduct
  * The people in these roles are elected or appointed by the Steering Committee, which in itself serves as the governing body of the Kubernetes project.

# Special Interest Group

Kubernetes is a big project

2000 contributors in one pool would be too noisy

A SIG is a sub-community; these are you K8s people

TODO: get image from slide 33.

* SIG sounds like of like a meetup group, it both is and isn’t
* They are their own sub-community and in general self manage themselves

## Charter

* Code ownership
  * Scope/area
  * Binaries
* Governing processes
* Subprojects
* Working Groups

Each SIG has a charter the defines what they are tasked with.
* It states what is in and out of scope for them
* Lists what broad areas they are tasked with stewardship of.
* It will also includes their own governing processes and potentially any working groups they have a stakehold in.

## Mailing list

* Communications with SIG members

Every SIG also has its own Mailing list and slack channel
The easiest way to get a feeling for what they’re doing is read their charter, their README, and to join their Mailing List. 

If you want a bit more of the day to day stuff, you should also join their slack channel

# Types of SIGs

* Project
* Horizontal
* Vertical
  * Applications
  * Resource Management
  * Infrastructure

* There are actually different types of SIGs
  * project
  * horizontal
  * vertical - vertical can be further subdivided into an additional 3 categories including:
    * apps
    * resource management
    * infrastructure

## Vertical SIGs: Infrastructure

sig-cloud-provider
* ensures that Kubernetes is neutral to all (public and private) cloud providers and provides the right hooks/abstraction for them to function well
sig-cluster-lifecycle
* manages upgrades, downgrades and provisioning of clusters -- if you’ve heard of the cluster-api, its own by cluster-lifecycle

# Community Groups Overview

TODO: bring in image from slide 37

* This is a picture of the current groups -- It can look a little complex, but it breaks down like this:
  * project groups
    * impact or provide services to the project and community as a whole. They are things like managing the infrastructure around testing and releasing Kubernetes, with sig testing and sig release. There's also contributor experience who is tasked with putting on events like this.
    * horizontal
      * which covers cross-cutting areas, like api-machinery, scalability, or windows.
      * They touch multiple areas of the project but have their specific focused areas
    * vertical
      * Has a very specific focus like storage or networking
      * You can see the break down of Application, Resource Management and Infrastructure

# Project SIGs

sig-architecture
* ensures the features that are being developed adhere to the design principles of Kubernetes. - Mostly API Review
sig-contribex
* Does everything it can to maintain a healthy contributor community.
sig-docs
* owns k/website - sort of self explanatory
sig-pm
* pm, or project management, provides some pm services to other SIGs and owns some of the process work around managing the project
sig-release
* Ensure quality of Kubernetes releases, and manages the release process.
sig-testing
* Handles the test infrastructure used by the project, note that they do NOT write the tests, they maintain the testing infrastructure
sig-usability
* focus on improving the core end-user usability of the Kubernetes project.

# Horizontal SIGs

sig-api-machinery
* essentially owns everything related to the API server, and how it uses the storage backend (etcd)
sig-auth
* authentication, authorization and security policies
sig-cli
* kubectl
sig-instrumentation
* metrics, logging, and how kubernetes emits events
sig-multicluster
* Focused on developing the tooling and solving common challenges related to the management of multiple Kubernetes clusters.
sig-scalability
* Defines the scalability goals of kubernetes, and works to improve it’s performance / remove bottlenecks -- want to see kubernetes support 20,000 nodes? they’re the group you want to help.
sig-ui
* owners of the kubernetes dashboard
sig-windows
* windows 

# Vertical SIGs

## Vertical SIGs: Applications

sig-apps
* owns apps api, deployments, statefulsets etc
sig-service-catalog
* building an interfaces for  the Open Service Broker API.


## Vertical SIGs: Resource Management

sig-autoscaling
sig-network
sig-node
sig-scheduling
sig-storage

# Subprojects

TODO: Bring in image from slide 42

Focus areas for SIGS
* May have their own mailing list, slack channel

Own Code, Issues
* Roadmap is owned by a single SIG
* mostly found in the kubernetes-sigs org, you’ll find a tag on each repo for the owning sig
  * pull open browser and goto k-sigs

# Working Groups

Working Groups: Inter-SIG efforts 

For specific:
* Goals (ex. Code Cleanup)
* Areas (ex. multi tenancy)

https://github.com/kubernetes/community/blob/master/README.md#governance

# Project Working Groups

wg-security-audit
* security-audit - recently completed their 3rd party security audit of the kubernetes code base
wg-k8s-infra
* automate, migrate and maintain the kubernetes testing infrastructure -- right now it’s managed by googlers and moving towards CNCF owned resources
wg-LTS
* put together to answer the question if Kubernetes should maintain an LTS release. If so, how much effort would be needed to support it.

# Horizontal Working Groups

wg-apply
* effort from sig-cli and sig-api-machinery to work towards supporting service side apply instead of relying on the apply being handled client side.
wg-component-standard
* Put together standards for cli flags,status endpoints etc -- essentially normalize how all our configs are done across binaries and projects
wg-multitenancy
* Define the models of multitenancy that Kubernetes will support, and improve the kubernetes multitenancy posture.
wg-policy
* Provide an overall architecture that describes both the current policy related implementations as well as future policy related proposals in Kubernetes. Think “what do we do with pod security policies”

# Vertical Working Groups

## Applications
wg-machine-learning
* what features are needed to better support ML workloads, and how should they be prioritized
wg-io-edge
* improving Kubernetes IoT and Edge deployments

## Resource Management
wg-resource-management
* improve support for performance sensitive workloads, improve support for devices etc

# Quick Reference

Governance reference
git.k8s.io/community/governance.md

Project Group List
git.k8s.io/community/sig-list.md
