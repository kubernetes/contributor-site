# Kubernetes Contributor Site

This repository contains the [Hugo][hugo] site and generator scripts for the
Kubernetes Contributor site. The published website is available at
https://kubernetes.dev/ (served via Netlify).

## Site content

The content for the Contributor Site is sourced from multiple locations.
Content managed within this repository is generated from generated from [Markdown]
found within the [`content`][ct] directory. To update the site's content,
make changes to the Markdown sources and [submit a pull request][pr] to this
repository.

**Note**: If the site's content needs to be published at the future date, please use `publishDate` as the front matter variable instead of `date`.

Some content is externally sourced and changes to that must be made in the
original location. A list of sources and their locations within the
[`content`][ct] is available below:

### External sources

- **Source:** https://git.k8s.io/community/contributors/guide <br>
  **Destination:** `/guide`
- **Source:** https://github.com/cncf/foundation/blob/master/code-of-conduct.md <br>
  **Destination:** `/code-of-conduct.md`
- **Source:** https://git.k8s.io/sig-release/releases/release-1.18/README.md <br>
  **Destination:** `/release.md`

## Running the site locally

To develop site content, you can run the site locally using [Hugo][hugo] in
two ways:

1. [Inside a Docker container](#using-docker)
2. [Natively](#natively) (not inside a Docker container)

When you make changes to the site's content, Hugo will automatically update
the site and refresh your browser window.

### Using Docker

The easiest and most cross-system-compatible way to run the Contributor
Site is to use [Docker][docker]. To begin, create the docker image to be used
with generating the site by executing `make container-image`.

To ensure you can view the site with externally sourced content, run
`make container-gen-content` before previewing the site by with
`make container-server`.


### Natively

For instructions on installing and using Hugo, see the [Hugo Documentation][hugo-docs].
Note that the extended version is required.

In addition to Hugo, the [postcss-cli] and [autoprefixer] JavaScript packages are
required. These can be installed via the [Node Package Manager] (`npm`) from a
recent version of [nodejs] with `npm install -g postcss-cli autoprefixer`.

The Contributor Site uses the [docsy] theme. It is included as a [git submodule].
To fetch docsy and it's requirements, run the command:
```
git submodule update --init --recursive --depth 1
```

To ensure you can view the site with externally sourced content, run
`make gen-content` before previewing the site by with `make server`.

**NOTE to OSX Users**

 The `hack/gen-content.sh` script requires the gnu version
of base packages such as `find`, `grep`, and `sed`. 
```
brew install coreutils findutils grep gnu-sed gnu-tar make readlink
```
You will then need to update your path to include these:
```
export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
```


## Community, discussion, contribution, and support

This project is managed by [SIG Contributor Experience][sig-contribex] as a
part of [KEP-0005][kep-0005]

You can reach the maintainers of this project at:

- [Slack][sig-contribex-slack]
- [Mailing List][sig-contribex-list]

## Evolution of this site:

We’re building out this site in real-time! Want to join us and help? Here’s what we have in store for next iterations:

* [x] An Events page showcasing all current and future happenings within the Kubernetes community. We hope to launch this feature by November 2019. Want to help us hit this target? Help us [work on this project](https://github.com/kubernetes-sigs/contributor-site/issues/15) by forking the repo and submitting a pull request!
* [x] Contributor guide/handbook: Feature launch date estimated November 2019
* [ ] Developers' guide/handbook: Feature launch date estimated April 2020
* [ ] Role Board: Feature launch date estimated April 2020
* [ ] Directory of Kubernetes SIGs and other community groups
* [x] Pathways to success for [new Kubernetes contributors](https://git.k8s.io/community/community-membership.md) and mentoring programs
* [ ] Workshop videos

### Code of conduct

Participation in the Kubernetes community is governed by the
[Kubernetes Code of Conduct](code-of-conduct.md).

[hugo]: https://gohugo.io/
[Markdown]: https://www.markdownguide.org/
[ct]: ./content/
[pr]: https://help.github.com/en/articles/about-pull-requests
[hugo-docs]: https://gohugo.io/getting-started/installing
[frontmatter]: https://gohugo.io/content-management/front-matter/
[docker]: https://www.docker.com/get-started
[sig-contribex]: https://git.k8s.io/community/sig-contributor-experience/README.md
[sig-contribex-slack]: http://slack.k8s.io/#sig-contribex
[sig-contribex-list]: https://groups.google.com/forum/#!forum/kubernetes-sig-contribex
[kep-0005]: https://git.k8s.io/enhancements/keps/sig-contributor-experience/0005-contributor-site.md
[docsy]: https://docsy.dev
[postcss-cli]: https://postcss.org/
[autoprefixer]: https://github.com/postcss/autoprefixer
[git submodule]: https://git-scm.com/book/en/v2/Git-Tools-Submodules
