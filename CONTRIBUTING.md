# Contributing Guidelines

Welcome to Kubernetes. We are excited about the prospect of you joining our [community](https://github.com/kubernetes/community)! The Kubernetes community abides by the CNCF [code of conduct](https://github.com/cncf/foundation/blob/main/code-of-conduct.md). Here is an excerpt:

_As contributors and maintainers of this project, and in the interest of fostering an open and welcoming community, we pledge to respect all people who contribute through reporting issues, posting feature requests, updating documentation, submitting pull requests or patches, and other activities._

## Getting Started

We have full documentation on how to get started contributing here: 

<!---
If your repo has certain guidelines for contribution, put them here ahead of the general k8s resources
-->

- [Contributor License Agreement](https://git.k8s.io/community/CLA.md) Kubernetes projects require that you sign a Contributor License Agreement (CLA) before we can accept your pull requests
- [Kubernetes Contributor Guide](http://git.k8s.io/community/contributors/guide) - Main contributor documentation, or you can just jump directly to the [contributing section](http://git.k8s.io/community/contributors/guide#contributing)
- [Contributor Cheat Sheet](https://git.k8s.io/community/contributors/guide/contributor-cheatsheet) - Common resources for existing developers

## Localization (i18n)

We welcome contributions to localize `kubernetes.dev` for the contributor community.

### Governance
English localization is governed by the existing contributor site owners
(listed in the repository's root [OWNERS](./OWNERS)). Localization teams for
other languages own their respective content within the site. Established
localization teams from across the project (e.g., [SIG Docs
Localization](https://kubernetes.io/docs/contribute/localization/) contributors)
can contribute and provide guidance on the contributor site.

If you are interested in starting a new localization from scratch, first see the
[SIG Docs Localization guide](https://kubernetes.io/docs/contribute/localization/#start-a-new-localization).

#### Branch Convention
Open a PR from a branch named `i18n/<lang-code>` (e.g., `i18n/ko`).

#### Setup Steps

1. **Update `hugo.yaml`** — add a new language block under `languages`.

2. **Create the content directory** — `content/<lang>/` with a translated `_index.md`.

3. **Set up an `OWNERS` file** at `content/<lang>/OWNERS` referencing your localization
   team's aliases (defined in the repository's `OWNERS_ALIASES`), with
   `sig-contribex-website-owners` as a recommended fallback approver:
   ```yaml
   options:
     no_parent_owners: true

   reviewers:
   - <lang>-reviews

   approvers:
   - <lang>-owners
   - sig-contribex-website-owners
   ```

4. **Translate UI strings** — create `i18n/<lang>/<lang>.toml` with the site's
   translatable strings.

5. **Update README.md** — add a link to your localized `README-<lang>.md` under
   the Localization section.

6. **Open a pull request** from your `i18n/<lang-code>` branch against `main`.

## Mentorship

- [Mentoring Initiatives](https://git.k8s.io/community/mentoring) - We have a diverse set of mentorship programs available that are always looking for volunteers!

<!---
Custom Information - if you're copying this template for the first time you can add custom content here, for example:

## Contact Information

- [Slack channel](https://kubernetes.slack.com/messages/kubernetes-users) - Replace `kubernetes-users` with your slack channel string, this will send users directly to your channel. 
- [Mailing list](URL) 

-->
