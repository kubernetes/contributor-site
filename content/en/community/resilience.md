---
title: Community Resilience Dashboard
linkTitle: Resilience Dashboard
description: See which Kubernetes projects need contributors and where you can jump in.
---

{{< lottery-factor >}}

## The Lottery Factor

Some projects depend on just a handful of people. If those people left, the project would struggle. We call that the Lottery Factor (some call it the bus factor). A low number means higher risk.

### How we measure it

We check activity over the last 6 months across SIG Contributor Experience repos:

- **Commits** who is writing code.
- **Pull requests** who is reviewing and authoring.
- **Issues** who is triaging and discussing.

### How to read the treemap

- **Box size** shows total activity in that repo.
- **Color** shows the Lottery Factor.
  - **LF of 1 or 2** means high risk. One person leaving could be a big problem.
  - **LF of 3 or 4** means moderate risk.
  - **LF of 5 or more** means the load is shared. Healthier.

## Projects That Need You

The projects below are looking for help:

{{< call-for-help title="Projects Calling for Help" >}}

### What can you do?

A low Lottery Factor means your contribution would go further there.

- Browse all projects on the [Help Wanted Dashboard](/community/help-wanted/) and filter by language, skills, or meeting time.
- Check out [Good First Issues](https://github.com/kubernetes/community/issues?q=is%3Aopen+is%3Aissue+label%3A%22help+wanted%22+label%3A%22good+first+issue%22).
- Read the [SIG Onboarding Guides](/docs/onboarding/).
- Join `#sig-contribex` on Slack.

### You are a SIG lead?

If your project is short on people, [file a Call for Help request](https://github.com/kubernetes/contributor-site/issues/new?template=call-for-help.yaml). It will show up on this page and in New Contributor Orientation.
