---
title: Community Resilience Dashboard
linkTitle: Resilience Dashboard
description: See which Kubernetes projects might be in trouble and where you can help.
---

{{< lottery-factor >}}

## The Lottery Factor

Here's the basic idea. Some projects depend heavily on a small group of people. If a couple of key maintainers won the lottery and disappeared tomorrow, that project would be in trouble. We call that the "Lottery Factor" (some people call it the bus factor). A low number means higher risk.

### How we measure it

We look at activity over the last 6 months in repositories managed by SIG Contributor Experience:

- **Commits** — who's writing code.
- **Pull requests** — who's reviewing and authoring.
- **Issues** — who's triaging and discussing.

### How to read the treemap

- **Box size** shows total activity in that repo or subproject.
- **Color** shows the Lottery Factor.
  - **LF of 1 or 2** means high risk. A single person leaving could cripple things.
  - **LF of 3 or 4** means moderate risk.
  - **LF of 5 or more** means the knowledge is spread out. Healthier.

## Projects That Need Your Help

The projects below are looking for contributors:

{{< call-for-help title="Projects Calling for Help" >}}

### What can you do?

If a project has a low Lottery Factor, that's a sign. It means your contribution would matter more there.

- Browse all projects on the [Help Wanted Dashboard](/community/help-wanted/) and filter by language, skills, or meeting time.
- Check out [Good First Issues](https://github.com/kubernetes/community/issues?q=is%3Aopen+is%3Aissue+label%3A%22help+wanted%22+label%3A%22good+first+issue%22) across Kubernetes.
- Read the [SIG Onboarding Guides](/docs/onboarding/).
- Join `#sig-contribex` on Slack and ask around.

### You're a SIG lead?

If your project is short on people, [file a Call for Help request](https://github.com/kubernetes/contributor-site/issues/new?template=call-for-help.yaml). It will show up on this page and in New Contributor Orientation sessions.
