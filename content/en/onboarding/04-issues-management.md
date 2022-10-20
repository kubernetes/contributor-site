---
title: "Section 4: Issues Management and Triage"
type: reveal
weight: 4
description: |
    Learn how to work with GitHub issues and how they are prioritized
    and organized.
---

# Section 4: Issues Management/Triage

---

# What you're about to learn

This unit will help you get started with issue management across the Kubernetes GitHub repositories. By the end, you'll:

* Understand and locate the issues management and triage tags
* Know where bugs are reported and how they are triaged
* Be able to understand how to prioritize work based on issues
* Be able to locate the security response committee for security issues

---

# How does Kubernetes use GitHub issues?

Contributors and end users use issues for a variety of reasons:

* Reporting bugs
* Tracking tasks
* Community organization
* Discussion

You can identify different types of issues with their labels (AKA tags).

---

# What are labels?

* Labels are a GitHub feature used to organize issues and pull requests.
* They allow you to quickly identify at a glance what type of issue or pull request you are looking at.
* They are helpful when using the search feature to look for issues.
* Labels are also called tags!

---

# Where can I find all of the Kubernetes issues?

Issues are managed in many of the different Kubernetes GitHub repositories, and can be accessed via the _Issues_ tab. Here are the most common:

* [kubernetes/kubernetes](https://github.com/kubernetes/kubernetes/issues)
* [kubernetes/community](https://github.com/kubernetes/community/issues)
* [kubernetes/website](https://github.com/kubernetes/website/issues)

---

# What are some common labels?

There are [A LOT of different labels](https://github.com/kubernetes/test-infra/blob/master/label_sync/labels.md), and both issues and pull requests (PRs) can have their own labels. Here are a few you will run into frequently.

<table style="font-size: 45%">
  <tr>
   <td><code>help wanted</code> and <code>good first issue</code>
   </td>
   <td>Use these to figure out what to work on first or next.
   </td>
  </tr>
  <tr>
   <td><code>needs-sig</code> and <code>needs-triage</code>
   </td>
   <td>Bugs that haven't been assigned or triaged
   </td>
  </tr>
  <tr>
   <td><code>lgtm</code>
   </td>
   <td>"Looks good to me", a PR is ready to merge.
   </td>
  </tr>
  <tr>
   <td><code>approved</code>
   </td>
   <td>Indicates a PR has been approved by an approver from all required OWNERS files.
   </td>
  </tr>
  <tr>
   <td><code>sig/*</code>
   </td>
   <td>Each Special Interest Group (SIG) has their own label.
   </td>
  </tr>
  <tr>
   <td><code>area/*</code>
   </td>
   <td>For issues and PRs that apply to a specific area of Kubernetes
   </td>
  </tr>
  <tr>
   <td><code>kind/*</code>
   </td>
   <td>Label different kinds of issues or PRs, such as bugs, API changes, or support requests.
   </td>
  </tr>
</table>

---

# Which labels will you have to worry about?

That list of labels is really long, but you won't need to worry about most of them at the beginning.

* When starting out, you just need to look for issues labeled `help wanted` or `good first issue`.
* Many labels are managed automatically by bots.
* The community will suggest other labels for issues, or add them for you.

---

# What is triaging?

* Triaging is the process where new issues and requests are reviewed and organized.
* Factors considered include priority/urgency, SIG ownership of the issue, and the kind of issue (bug, feature, etc.).
* Triage can happen asynchronously and continuously, or in regularly scheduled meetings. 
* Each SIG may have its own approach to triaging.

Triaging is critical for keeping track of new issues, bugs, and problems. [Read the Issue Triage Guidelines for more information.](https://www.kubernetes.dev/docs/guide/issue-triage/)

---

# How are issues prioritized?

Each SIG is responsible for triaging and deciding on the priority of issues that affect their area.

* The lowest priority is priority/awaiting-more-evidence
* The highest priority issues are labeled priority/critical-urgent and require somebody to work on them immediately.

---

# What is the Security Response Committee?

* The Security Response Committee (SRC) is responsible for triaging and handling the security issues for Kubernetes.
* The SRC is also responsible for disclosing vulnerabilities to the public.
* Report to them when you think you have discovered a potential security vulnerability in Kubernetes.

You can learn more about [Kubernetes security disclosure and reporting here](https://kubernetes.io/docs/reference/issues-security/security/).

<div class="bottom-nav">
    <a href="/onboarding">Onboarding Index</a> | <a href="../05-development/">Next Section</a>
</div>
