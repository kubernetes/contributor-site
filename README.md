# Kubernetes Contributor Site

This repository contains the [Hugo][hugo] site and generator scripts for the
Kubernetes Contributor site. In the future, the site will be available at
https://contributors.kubernetes.io. For now, you can access the in-progress
site at https://kubernetes-contributor.netlify.com.

## Site content

The content for the Contributor Site is sourced from multiple locations.
Content managed within this repository is generated from generated from [Markdown]
found within the [`content`][ct] directory. To update the site's content,
make changes to the Markdown sources and [submit a pull request][pr] to this
repository.

Some content is externally sourced and changes to that must be made in the
original location. A list of sources and their locations within the
[`content`][ct] is available below:

### External sources

- **Source:** https://git.k8s.io/community/contributors/guide <br>
  **Destination:** `/guide`


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
with generating the site by executing `make docker-image`.

To ensure you can view the site with externally sourced content, run
`make docker-gen-content` before previewing the site by with `make docker-server`.


### Natively

> For instructions on installing and using Hugo, see the [Hugo
> Documentation][hugo-docs].

To run the site locally using an installed Hugo executable, run `make server`.

## YouTube embeds

You can embed YouTube videos on pages using the `youtube` shortcode and
specifying the unique ID of the video. Here's an example:

```bash
Check out this cool video:

{{< youtube 6cCEmAisx8A >}}
```

This embed would take up the full width of the surrounding element. You can
specify a smaller width as a percentage by changing the second argument. This
embed, for example, would occupy 70% of the width:

```bash
Check out this cool video:

{{< youtube 6cCEmAisx8A 70 >}}
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
* [x] Pathways to success for [new Kubernetes contributors](https://github.com/kubernetes/community/blob/master/community-membership.md) and mentoring programs
* [ ] Workshop videos

### Code of conduct

Participation in the Kubernetes community is governed by the
[Kubernetes Code of Conduct](code-of-conduct.md).

[hugo]: https://gohugo.io/
[Markdown]: https://www.markdownguide.org/
[ct]: ./content/
[pr]: https://help.github.com/en/articles/about-pull-requests
[hugo-docs]: https://gohugo.io/documentation/
[frontmatter]: https://gohugo.io/content-management/front-matter/
[docker]: https://www.docker.com/get-started
[sig-contribex]: https://github.com/kubernetes/community/blob/master/sig-contributor-experience/README.md
[sig-contribex-slack]: http://slack.k8s.io/#sig-contribex
[sig-contribex-list]: https://groups.google.com/forum/#!forum/kubernetes-sig-contribex
[kep-0005]: https://github.com/kubernetes/enhancements/blob/master/keps/sig-contributor-experience/0005-contributor-site.md
