---
title: Community Resilience Dashboard
linkTitle: Resilience Dashboard
description: Visualizing the "Lottery Factor" (Bus Factor) across Kubernetes subprojects.
---

{{< lottery-factor >}}

## About the Lottery Factor
The "Lottery Factor" (traditionally known as the Bus Factor) represents the minimum number of maintainers who, if they were to win the lottery and leave the project tomorrow, would result in the loss of >50% of the project's institutional knowledge and activity.

### How it is calculated
Our Go-based ingestion engine analyzes activity from the last 6 months across repositories maintained by **SIG Contributor Experience**:
- **Commits:** Direct code contributions.
- **Pull Requests:** Review and authoring activity.
- **Issues:** Participation in triage and discussion.

### Understanding the Visualization
- **Size of boxes:** Represents the total activity (points) in that subproject/repository.
- **Color:** Indicates the Lottery Factor.
    - <span style="color: #dc3545; font-weight: bold;">Red (LF <= 2):</span> High Risk - Single Point of Failure.
    - <span style="color: #ffc107; font-weight: bold;">Yellow (LF 3-4):</span> Moderate Risk.
    - <span style="color: #28a745; font-weight: bold;">Green (LF >= 5):</span> Healthy distribution.

### Take Action
If you see a project with a high risk (low Lottery Factor), it's a great opportunity to get involved!
- Check out the [Good First Issues](https://github.com/kubernetes/community/issues?q=is%3Aopen+is%3Aissue+label%3A%22help+wanted%22+label%3A%22good+first+issue%22).
- Read our [SIG Onboarding Guides](/docs/onboarding/).
- Join the `#sig-contribex` channel on Slack to learn how you can help.
