---
layout: blog
title: "February 2022 Community Meeting Highlights"
date: 2022-05-05
slug: community-meeting-februrary-2022
---

**Author:** Nigel Brown (VMware)

We just had our first contributor community meeting this year, and it was awesome to be back with you 
in that format. These meetings will be happening on Zoom once per month, on the third Thursday of the 
month - that should be available in your calendar if you’re subscribed to the k-dev mailing list. 
Community meetings are an opportunity for you to meet synchronously with other members of the 
Kubernetes community to talk about issues of general appeal.

This meeting kicked off with an update on the 1.24 release with Xander Grzywinski, who is one of the 
shadows for the release team leads. This release is scheduled for April 19, 2022 with a code freeze 
scheduled for March 30th. At the time of the meeting there were 66 individual enhancements included, 
as well as bug fixes. You can join the conversation on Slack in 
[#sig-release](https://kubernetes.slack.com/archives/C2C40FMNF).

_Update:_ Kubernetes 1.24 was delayed and released on May 3, 2022.

From there, the discussion moved to the dockershim removal and the docs updates we need to make 
around that, with the discussion led by Kat Cosgrove. The main takeaway was that if you have a 
platform, talk to folks about this change. To most interacting with Kubernetes, it is probably not as 
impactful as it sounds. We have a [helpful FAQ](https://kubernetes.io/dockershim) if you need. You 
can even try out an alpha release from the [1.24 release page](https://github.com/kubernetes/kubernetes/releases?q=v1.24.0-alpha).

We moved on to a spirited discussion of a Kubernetes Enhancement Proposal (KEP) about raising the bar 
for reliability brought by Wojciech Tyczynski. It was emphasized that effort on this proposal should 
be a collaborative effort with SIG Testing who are managing dashboards on test flakiness among other 
metrics. You can find the proposed [KEP](https://github.com/kubernetes/enhancements/pull/3139) on 
GitHub.

Finally, Paris mentioned the k-dev migration of the developer mailing list. If you manage Google Docs 
assets, you may need to share them with the new developer list. New community members may not be able 
to join from assets shared with the old lists.

You can find the 
[full meeting notes](https://docs.google.com/document/d/1VQDIAB0OqiSjIHI8AWMvSdceWhnz56jNpZrLs6o7NJY/edit?pli=1#heading=h.lk3ecc5rt40z) 
posted online (thanks Josh Berkus!) as well as the 
[recording on YouTube](https://www.youtube.com/watch?v=qwLsGfqHEhk). If you have topics you would 
like to discuss or you’re interested in being the host of a future community meeting, please reach 
out to Laura Santamaria (@nimbinatus) on Slack.