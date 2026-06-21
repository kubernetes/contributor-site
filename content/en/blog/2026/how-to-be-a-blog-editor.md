---
layout: blog
title: "How to be a blog editor"
draft: true
slug: how-to-be-a-blog-editor
author: >
  Kashish Verma (independent)
---

If you're new to the blog team, this guide walks you through the whole journey of being a Kubernetes blog editor, from picking up a draft PR to seeing the article being published.

## Step 1: Find blogs that need review

Depending on which site the article targets, check one of these:

- [k/website](https://github.com/kubernetes/website/pulls?q=is%3Aopen+is%3Apr+label%3Aarea%2Fblog) (kubernetes.io)
- [k/contributor-site](https://github.com/kubernetes/contributor-site/pulls?q=is%3Aopen+is%3Apr+label%3Aarea%2Fblog) (kubernetes.dev)

Pick one up, and move on to reviewing it against our guidelines.

## Step 2: Review against guidelines and style

We use the same documentation style guide for both docs PRs and blog PRs:

- [Blog guidelines](https://kubernetes.io/docs/contribute/blog/guidelines/)
- [Style guide](https://kubernetes.io/docs/contribute/style/style-guide/)

Blogs are not docs, though, so a handful of exceptions apply on top of the standard style guide, for example, around tone and structure. Always check these before flagging something as a style issue:

- [Blog-specific exceptions to the style guide](https://kubernetes.io/docs/contribute/blog/article-submission/#article-content)

## Step 3: Catch the overlooked details

These are the details that are easy to miss but will delay or block publication if they're wrong. Treat this as your pre-merge checklist.

### 3.1 Front matter

Front matter is the most important part of the PR. A mistake here is the single most common reason a blog doesn't get published on time, so review it carefully:

- [Front matter reference](https://kubernetes.io/docs/contribute/blog/article-submission/#front-matter)

Key things to know:

- We use **Hugo** as our static site generator.
- Hugo only publishes an article once `draft: true` is removed (or set to `false`) in the front matter.
- Initially, the front matter should have only `draft: true`
- The `date:` field gets added later, at the publish-PR stage, where it replaces `draft: true` with the scheduled publish date.
- On the scheduled date, automation triggers a site build and the article goes live automatically.

### 3.2 Filename must match the slug

The filename must always match the `slug` field in the front matter.

**Example:** if `slug: demo-blog`, the file must be named `demo-blog.md`.

### 3.3 Author formatting

Check how the author field is filled in:

- If the author has no organizational affiliation to credit, just use their name on its own  or use `Name (independent)`, with "independent" in lowercase.


### 3.4 Determine the article's scope (which site it publishes to)

We publish blogs to two different sites, and getting this wrong means the article ends up in the wrong place:

1. [kubernetes.io](https://kubernetes.io): the main Kubernetes blog
1. [kubernetes.dev](https://www.kubernetes.dev): the contributor blog

As a rule of thumb: content from the `k/contributor-site` repo goes to [kubernetes.dev](https://www.kubernetes.dev), and content from `k/website` goes to [kubernetes.io](https://kubernetes.io). To judge scope properly:

- [Content examples: kubernetes.io vs. kubernetes.dev](https://kubernetes.io/docs/contribute/blog/guidelines/#content-examples)

Once the blog team has decided which site (or sites) an article belongs on, follow one of the two publishing paths below.

## Step 4: Get the draft merged, then publish

### Path A: Publishing to a single site

1. The draft PR is merged first. At this stage, the front matter should still have `draft: true`, this is essential.
1. Once the draft PR is merged, open a **second, small "publish PR."** This PR does only one thing: it replaces `draft: true` with `date: YYYY-MM-DD`.


### Path B: Publishing to both sites (mirroring)

If the team decides an article should appear on both sites:

1. The draft PR in the contributor site (`k/contributor-site`) is merged first.
1. A mirror draft PR is opened in `k/website`, making sure there's no content drift between the two versions,  they should read identically. Read more about [Blog mirroring](https://kubernetes.io/docs/contribute/blog/article-mirroring/).
1. Once **both** draft PRs are merged, open a small publish PR, replacing `draft: true` with `date: YYYY-MM-DD`.
1. Because kubernetes.io is hosting a mirrored article, the k/website front matter also needs `canonicalUrl` set, pointing back to the original on kubernetes.dev:

   ```
   canonicalUrl: https://www.kubernetes.dev/blog/{YYYY}/{MM}/{DD}/{slug}
   ```

   Replace `{YYYY}`, `{MM}`, `{DD}`, and `{slug}` with the actual values.

A few notes on mirroring:

- We almost always mirror **from** the contributor blog **to** the main site. Mirroring the other direction (main site to contributor site) is rare but technically possible.
- The publish PR should always be small and scoped only to the front matter change (date and URL). Don't bundle in content changes.

## Step 5: Make the editing process faster

We encourage authors to share an editable version of the article, either via **HackMD** (a web-based Markdown editor) or a **Google Doc**, before content is fully translated into a PR. This makes back-and-forth editing significantly faster than reviewing every change as a new commit.

## Step 6: Know what we don't publish

Not every draft is a fit for the blog. Before investing review time, check the list of content the project won't publish:

- [What we do not publish](https://kubernetes.io/docs/contribute/blog/guidelines/#what-we-do-not-publish)

Keep this list in mind throughout review, not just at the start, it's worth a second look once the full content is in front of you.