---
layout: blog
title: Human-Centered Automation for Kubernetes Localization in the AI Era
draft: true
slug: human-centered-automation-kubernetes-localization-ai-era
author: Peter Chang
---

This year, the Kubernetes localization subproject participated in LFX Mentorship for the first time through the project ["CNCF - Kubernetes: SIG Docs Localization: AI-era localization automation"](https://mentorship.lfx.linuxfoundation.org/project/c71fdb2a-8e77-447d-ae8b-3e977e0fd86a). The work was also tracked in [kubernetes/website#54075](https://github.com/kubernetes/website/issues/54075).

As the mentee on this project, I worked with Kubernetes SIG Docs localization mentors on a practical maintenance question:

> In an era of rapidly improving AI translation tools, what kind of automation actually helps localization maintainers?

Kubernetes documentation is used by readers around the world. Localization helps make the project more accessible to users and contributors by providing content in their native languages. But localization is not only about translating pages once. It is also about maintaining those pages as Kubernetes changes.

For this mentorship project, the focus was human-centered automation: tools that improve visibility, reduce repetitive triage, and protect human reviewer attention.

The goal was not to automate translation. The goal was to make localization review work easier to prioritize.

## The maintenance problem behind localization

Kubernetes documentation changes continuously. Concepts are clarified, examples are updated, feature states move forward, commands are corrected, and API-related wording changes.

When English documentation changes, localized pages may also need updates. For active localization teams, this creates ongoing maintenance work. Reviewers need to understand both the source content and the target language, and they need enough Kubernetes context to decide whether a change affects technical accuracy.

Existing signals can help detect possible drift. Some localization teams compare Git history to see whether the English source changed after a localized page was last updated, and Kubernetes website pages may also show `lastmod` warnings when localized content appears older than the English source.

These signals are useful, but they do not always explain what kind of review is needed. A localized page may look recently updated because of a small local edit while still missing an important upstream change. Another page may appear stale because the English source changed, even though the change was only cosmetic.

For localization contributors, the hard question is often not:

> Did something change?

It is:

> Where should we look first?

Without a quick triage view, maintainers still need to inspect diffs, understand the impact of upstream changes, and decide which pages deserve review first. This can be difficult for large or long-running localization efforts, where many pages may have changed for different reasons.

## What the mentorship project prototyped

As part of the mentorship, I worked with my mentors to prototype a Markdown-aware localization triage script for the `kubernetes/website` repository. An initial version of the script was proposed in [kubernetes/website#55731](https://github.com/kubernetes/website/pull/55731).

The script compares English source pages with localized Markdown pages and looks for signals that may indicate drift. Some signals are structural, such as missing headings, code blocks, or anchors. Others are related to technical content, such as Kubernetes version references, API-related values, or feature-state differences. It can also flag localized files that no longer have a matching English source, or pages with unusually large line-count differences.

Rather than treating these findings as final judgments, the script organizes them into broad triage categories such as `Orphan`, `Strong signal`, `Moderate signal`, and `No signal`. The goal is to give maintainers a clearer starting point for review, not to decide automatically whether a localized page is current.

![Example triage report grouping localized pages by signal category](/blog/2026/human-centered-automation-kubernetes-localization-ai-era/triage-report.png)

The prototype outputs Markdown reports that can fit naturally into existing Kubernetes documentation workflows around GitHub, pull requests, and reviewer discussion. It is intended as an optional helper tool: localization teams can choose whether this kind of report is useful for their own maintenance process.

## A path forward for AI-era localization tooling

This kind of triage can also provide useful context for future AI-assisted workflows.

The key distinction is that AI assistance should support human review, not create a new stream of unverified content. A deterministic report can help identify where reviewer attention may be needed; an AI assistant could then help summarize context, prepare review notes, or organize follow-up work.

That is different from asking AI to generate large amounts of translated content and then leaving maintainers to validate the output. Without clear signals and reviewer control, automation can create more work instead of saving time.

A healthier AI-era workflow might look like this:

1. English documentation changes.
2. A localization team optionally runs a deterministic triage report.
3. Contributors inspect the explainable signals.
4. Optional AI assistance helps summarize or prepare review context.
5. Localization reviewers decide what, if anything, should change.
6. Human contributors submit pull requests following existing SIG Docs localization policy.

In this model, automation is assistive, not prescriptive. It helps maintainers inspect possible upstream impact more efficiently, while leaving final decisions to localization reviewers.

The principle is simple:

> Automation should protect reviewer attention, not consume it.

## Conclusion

This LFX Mentorship project was the first mentorship project for the Kubernetes localization subproject, and it gave us a chance to explore a real maintenance challenge in SIG Docs localization.

Although the project started with a question about AI-era localization automation, the most useful direction was not to generate more translation. It was to make maintenance work easier to see, prioritize, and discuss.

For me, the main lesson is that good automation should build contributor trust. It should reduce the effort needed to find review targets, explain why a page may need attention, and leave room for localization teams to decide what works for their own process.

I hope this experience is useful to Kubernetes contributors who are thinking about localization maintenance, AI-assisted workflows, or future mentorship projects in SIG Docs.

## Acknowledgements

Thank you to my LFX Mentorship mentors, Seokho, Ian, Eunjeong, and Wonyong, for their guidance and feedback throughout the project.

I also want to thank Kubernetes SIG Docs contributors, localization maintainers, and everyone who reviewed or discussed the localization outdatedness triage work.
