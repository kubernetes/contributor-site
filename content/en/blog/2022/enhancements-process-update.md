---
layout: blog
title: "Enhancements Opt-in Process Change for v1.26"
date: 2022-09-06
slug: enhancements-opt-in
---

# Enhancements Opt-in Process Change for v1.26 

## Context and Motivations

Since the inception of the Kubernetes release team, we have used a spreadsheet to keep track of enhancements for the release. The project has scaled massively in the past few years, with almost a hundred enhancements collected for the 1.24 release. This process has become error-prone and time consuming. A lot of manual work is required from the release team and the SIG leads to populate KEPs data in the sheet. We have received continuous feedback from our contributors to streamline the process.

Starting at the beginning of the 1.26 release, we are replacing the sheet with an automated [GitHub project board](https://github.com/orgs/kubernetes/projects/98).

## How does the Github Project Board work?

The board is populated with a script gathering all KEP issues in the `kubernetes/enhancements` repo that have the tag `lead-opted-in`. The enhancements' stage and SIG information will also be automatically pulled from the KEP issue.


## What does this mean for the community?

If you are not a SIG lead, nothing will change beside the view of the enhancements collections and the change of platform. KEP authors will continue working with their respective SIG leads to opt in to the release.

For SIG leads, opting in is simple. The KEP issue will be the single source of truth so ensure that all metadata are up to date. Simply comment `/label lead-opted-in` on the enhancement tracking issue to opt it into the current release. That's all you need to do to opt in! Since the script runs periodically, kindly come back to check that the KEP is on the board and that there is an enhancements team member assigned to it.

We are excited to bring this highly requested feature into our release process and appreciate your patience. Email us at [release-enhancements-team@kubernetes.io](mailto:release-enhancements-team@kubernetes.io) or  find us on Slack at [#release-enhancements](https://kubernetes.slack.com/archives/C02BY55KV7E) if you have any feedback, questions or concern.
