# Contributing Guidelines

Welcome to Kubernetes. We are excited about the prospect of you joining our [community](https://github.com/kubernetes/community)! The Kubernetes community abides by the CNCF [code of conduct](https://github.com/cncf/foundation/blob/master/code-of-conduct.md). Here is an excerpt:

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

We welcome contributions to localize `kubernetes.dev`. Our localization efforts are conducted in partnership with the **SIG Docs Localization subproject**.

### Governance and Review
To ensure translation accuracy and consistency across the Kubernetes project:
- **Delegated Approval**: Approval for localized content is delegated to the established SIG Docs Language Teams. 
- **Ownership**: Each language directory (e.g., `content/ko/`) should contain an `OWNERS` file that references the corresponding SIG Docs GitHub team (e.g., `@kubernetes/sig-docs-ko-owners`).
- **Process**: Localization contributors should follow the [SIG Docs Localization guide](https://kubernetes.io/docs/contribute/localization/) for best practices, but all PRs should be opened against the `kubernetes/contributor-site` repository.

### Adding a New Language
To bootstrap support for a new language on the contributor site:

1. **Update `hugo.yaml`**:
   Add a new language block under `languages` in the site configuration.
   ```yaml
   languages:
     # ... existing languages
     ko:
       contentDir: content/ko
       title: Kubernetes Contributors
       languageName: 한국어
       languageNameLatinScript: Korean
       weight: 2
       languagedirection: ltr
       params:
         languageNameLatinScript: Korean
   ```

2. **Create the Content Directory**:
   Create the base directory for the new language (e.g., `content/ko/`) and copy the `_index.md` from `content/en/` to start.

3. **Set Up the `OWNERS` File**:
   Add an `OWNERS` file in the root of the new language directory (`content/<lang>/OWNERS`) to properly delegate reviews and approvals to the SIG Docs language team.
   ```yaml
   # content/ko/OWNERS
   # This is the localization project for Korean.
   # Teams and members are visible at https://github.com/orgs/kubernetes/teams.
   
   reviewers:
   - sig-docs-ko-reviews
   
   approvers:
   - sig-docs-ko-owners
   
   labels:
   - area/localization
   - language/ko
   ```

4. **Translate UI Strings**:
   Create a new translation file in `i18n/<lang>/<lang>.toml` (e.g., `i18n/ko/ko.toml`) and translate the English site strings used in the layouts.

5. **Update README.md**:
   Add a link to the new localized `README-<lang>.md` file in the root `README.md` under the Localization section.

## Mentorship

- [Mentoring Initiatives](https://git.k8s.io/community/mentoring) - We have a diverse set of mentorship programs available that are always looking for volunteers!

<!---
Custom Information - if you're copying this template for the first time you can add custom content here, for example:

## Contact Information

- [Slack channel](https://kubernetes.slack.com/messages/kubernetes-users) - Replace `kubernetes-users` with your slack channel string, this will send users directly to your channel. 
- [Mailing list](URL) 

-->
