---
title: Services and Requests
linkTitle: Services and Requests
description: |
  Services and requests that are available to the contributor community, such
  as slack channels, github repos, tweets, netlify sites and more.
weight: 1
type: docs
aliases: [ "/services", "/requests" ]
slug: services
---


- [GitHub requests](#github-requests)
  - [Organization membership](#organization-membership)
  - [Team membership](#team-membership)
  - [Repo requests](#repo-requests)
- [Communication platform and services](#communication-platform-and-services)
  - [Contributor communications](#contributor-communications)
  - [Mailing lists](#mailing-lists)
  - [Slack](#slack)
  - [Surveys](#surveys)
  - [YouTube](#youtube)
  - [Zoom](#zoom)
- [Other](#other)
  - [Netlify websites](#netlify-websites)
  - [Funding](#funding)

## GitHub requests

### Organization membership

[Kubernetes GitHub Org members] should be actively contributing to the upstream
project, and should meet the general requirements outlined in the
[community membership guidelines]. 

Org membership requests can be made using the [Org Membership Request] form in
the [kubernetes/org] repo. Requests are often processed in batch once every 2-3
business days.

**NOTE:** If you are an existing member of the [kubernetes] org, you are **note**
required to apply for org membership in another Kubernetes org, such as
[kubernetes-sigs]. Instead, open a pull request to the [kubernetes/org] repo
adding yourself a member of the other org.


[Kubernetes GitHub Org members]: https://git.k8s.io/community/community-membership.md
[community membership guidelines]: https://git.k8s.io/community/community-membership.md#member
[Org Membership Request]: https://github.com/kubernetes/org/issues/new?assignees=&labels=area%2Fgithub-membership&template=membership.md&title=REQUEST%3A+New+membership+for+%3Cyour-GH-handle%3E



### Team membership

GitHub team membership changes should be made by directly opening a pull request
against the [kubernetes/org] repo, updating the desired team.



### Repo requests

GitHub requests such as repo [creation, migration], or [archival] can be made
using one of the [issue templates] in the [kubernetes/org] repo.

Repo requests require approval from the owning SIG leads, or in some instances,
community members that are granted permission to request repos on behalf of a
subproject.

[Donated repos], or repos that were originally created outside the project have
some additional requirements that must be satisfied before they can be transferred
to a Kubernetes project owned GitHub organization.

For more information, see the Kubernetes [GitHub Repository Guidelines].


[creation, migration]: https://github.com/kubernetes/org/issues/new?assignees=&labels=area%2Fgithub-repo&template=repo-create.md&title=
[archival]: https://github.com/kubernetes/org/issues/new?assignees=&labels=area%2Fgithub-repo&template=repo-archive.md&title=
[issue templates]: https://github.com/kubernetes/org/issues/new/choose
[Donated repos]: http://git.k8s.io/community/github-management/kubernetes-repositories.md#rules-for-donated-repositories
[GitHub Repository Guidelines]: http://git.k8s.io/community/github-management/kubernetes-repositories.md


## Communication platform and services

### Contributor communications

Contributor communication requests, such as tweets ([@k8contributors]), blog
posts, editorial support, promotion requests, or announcements can be made by
filling out the [Contributor Comms Request] form in the [kubernetes/community]
repo.

[@k8scontributors]: https://twitter.com/k8scontributors
[Contributor Comms Request]: https://github.com/kubernetes/community/issues/new?labels=area%2Fcontributor-comms%2C+sig%2Fcontributor-experience&template=marketing-request.md&title=REQUEST%3A+New+communication+about+%3Ctopic%3E



### Mailing lists

Mailing lists are largely intended for [community groups][cg], but are available
for subprojects if the need arises. These groups should be made following the
community [mailing list creation procedure]. With the subproject's entry in
[sigs.yaml], being updated with the new mailing list.


[mailing list creation procedure]: https://git.k8s.io/community/communication/mailing-list-guidelines.md#mailing-list-creation
[sigs.yaml]: https://git.k8s.io/community/sigs.yaml



### Slack

Public Slack channels and user groups may be requested by opening a pull request
updating the [slack-config] in the [kubernetes/community] repo. Slack channels
must adhere to some common-criteria to be added. As an example, project focused
channels must be for an Open Source project and not a private commercial one.

Other Slack requests, such as for private channels or integration requests should
be through the [Slack Request] form in the [kubernetes/community] readme.

For more information, see the [Slack Guidelines].


[slack-config]: https://git.k8s.io/community/communication/slack-config
[Slack Request]: https://github.com/kubernetes/community/issues/new?assignees=&labels=area%2Fcommunity-management%2C+area%2Fslack-management%2C+sig%2Fcontributor-experience&template=slack-request.md&title=REQUEST%3A+New+Slack+%3C%5Bchannel%7Cusergroup%7Cbot%7Ctoken%7Cwebhook%5D%3E+%3C%5Bchannel%7Cusergroup%7Cbot%7Ctoken%7Cwebhook%5D+name%3E
[Slack Guidelines]: https://git.k8s.io/community/communication/slack-guidelines.md



### Surveys

The Kubernetes project has access to the CNCF SurveyMonkey account for creating
community surveys, and SIG-Contributor Experience includes people who can give
advice on improving the quality of surveys, as well as promote them. Requests
can be made using the [Community Survey Request] form in the [kubernetes/community]
repo.

For additional information, on survey services, see the community
[Survey request guidelines].

[Community Survey Request]: https://github.com/kubernetes/community/issues/new?labels=area%2Fcontributor-comms%2C+sig%2Fcontributor-experience&template=survey-request.md&title=SURVEY+REQUEST%3A+%3Ctopic%3E
[Survey request guidelines]: https://git.k8s.io/community/communication/requesting-survey.md



### YouTube

YouTube playlists or upload requests can be made to the [YouTube admin team], by
pinging `@youtube-admins` in the [SIG ContribEx Slack channel].

For more information, see the [YouTube guidelines].


[YouTube admin team]: https://git.k8s.io/community/communication/moderators.md#youtube-channel
[YouTube guidelines]: https://git.k8s.io/community/communication/youtube/youtube-guidelines.md



### Zoom

Zoom meetings requests should be made to the owning [community group][cg] leads.
They are responsible for the creation and posting of the meeting to the group's
mailing list.

For more information, see the Kubernetes [Zoom guidelines].

If you need further assistance, you can open an issue in the [kubernetes/community]
repo, or ping the `@zoom-admins` in the [SIG ContribEx Slack channel].

[Zoom guidelines]: https://git.k8s.io/community/communication/zoom-guidelines.md



## Other

### Netlify websites

Official Kubernetes subprojects can request a domain and site hosting for their
project specific documentation. The Kubernetes community has standardized on
[Netlify] for this purpose. 

Requesting a site requires three things:
- Configuring a site and it's corresponding [config] within the repo.
- Opening a [Netlify Site Request] in the [kubernetes/org] repo.
- Opening a corresponding pull request or [issue] adding the domain in the
  [kubernetes/k8s.io] repo.

There are some specific formats and guidelines around some of these items, they
can be be reviewed in the [Netlify subproject site guidelines].

[Netlify]: https://netlify.com
[config]: http://git.k8s.io/community/github-management/subproject-site-requests.md#example-netlify-configuration
[issue]: https://github.com/kubernetes/k8s.io/issues/new?assignees=&labels=wg%2Fk8s-infra%2C+area%2Fdns&template=dns-request.md&title=DNS+REQUEST%3A+%3Cyour-dns-record%3E
[Netlify Site Request]: https://github.com/kubernetes/org/issues/new?assignees=&labels=area%2Fgithub-integration&template=site-create.md&title=
[Netlify subproject site guidelines]: http://git.k8s.io/community/github-management/subproject-site-requests.md#subproject-domain-reques



### Funding

Need to pay for something on behalf of the Kubernetes Project? Funding requests
can be made by opening an issue in the [kubernetes/funding] repo using one of
the available [issue templates].

Items that are covered fall largely into one of four categories:
- **Infrastructure:** testing infra, video conferencing, mailing lists, domains,
  etc
- **Events:** SIG face-to-face meetings, developer summits, etc
- **Consulting services:** docs writers, security auditors, etc
- **Community Gifts:** swag codes, thank you cards, etc

For more information on funding requests, see the [Project Funding] page.

[kubernetes/funding]: https://github.com/kubernetes/funding
[issue templates]: https://github.com/kubernetes/funding/issues/new/choose
[Project Funding]: https://github.com/kubernetes/funding#project-funding



<!-- shared links -->
[cg]: /resources/community-groups
[kubernetes/community]: https://github.com/kubernetes/community
[kubernetes/org]: https://github.com/org
[kubernetes/k8s.io]: https://github.com/kubernetes/k8s.io
[kubernetes]: https://github.com/kubernetes
[kubernetes-sigs]: https://github.com/kubernetes-sigs
[SIG ContribEx Slack channel]: https://kubernetes.slack.com/messages/sig-contribex