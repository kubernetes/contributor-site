<!--
# Kubernetes Contributor Site

This repository contains the [Hugo][hugo] site and generator scripts for the
Kubernetes Contributor site. The published website is available at
https://kubernetes.dev/ (served via Netlify).
-->
# Kubernetes 贡献者网站
此仓库包含 Kubernetes 贡献者网站的 [Hugo][hugo] 网站生成器脚本。
已发布的网站位于 https://kubernetes.dev/ （通过 Netlify 提供）。

<!--
## Site content

The content for the Contributor Site is sourced from multiple locations.
Content managed within this repository is generated from generated from [Markdown]
found within the [`content`][ct] directory. To update the site's content,
make changes to the Markdown sources and [submit a pull request][pr] to this
repository.

Some content is externally sourced and changes to that must be made in the
original location. A list of sources and their locations within the
[`content`][ct] is available below:
-->
## 网站内容

贡献者网站的内容来自多个地方。
此仓库中管理的内容是由 [`content`][ct] 目录中的 [Markdown] 生成的。要更新网站的内容，请更改 Markdown 源文件并 [提交拉取请求][pr] 到此仓库。

某些内容是来源于外部的，必须在原始位置进行更改。 [`content`][ct] 目录中的文件来源及其位置如下所示：

<!--
### External sources

- **Source:** https://git.k8s.io/community/contributors/guide <br>
  **Destination:** `/guide`
- **Source:** https://github.com/cncf/foundation/blob/master/code-of-conduct.md <br>
  **Destination:** `/code-of-conduct.md`
- **Source:** https://git.k8s.io/sig-release/releases/release-1.18/README.md <br>
  **Destination:** `/release.md`
-->
### 外部来源

- **源路径：** https://git.k8s.io/community/contributors/guide <br>
  **目标路径：** `/guide`
- **源路径：** https://github.com/cncf/foundation/blob/master/code-of-conduct.md <br>
  **目的路径：** `/code-of-conduct.md`
- **源路径：** https://git.k8s.io/sig-release/releases/release-1.18/README.md <br>
  **目标路径：** `/release.md`

<!--
## Running the site locally

To develop site content, you can run the site locally using [Hugo][hugo] in
two ways:

1. [Inside a Docker container](#using-docker)
2. [Natively](#natively) (not inside a Docker container)

When you make changes to the site's content, Hugo will automatically update
the site and refresh your browser window.
-->
## 在本地运行网站

要开发网站内容，你可以使用 [Hugo][hugo] 在本地运行网站。

两种方式：

1. [在 Docker 容器内](#using-docker)
2. [Natively](#natively)（不在 Docker 容器内）

当对网站内容进行更改时，Hugo 会自动更新并刷新浏览器窗口。

<!--
### Using Docker

The easiest and most cross-system-compatible way to run the Contributor
Site is to use [Docker][docker]. To begin, create the docker image to be used
with generating the site by executing `make container-image`.

To ensure you can view the site with externally sourced content, run
`make container-gen-content` before previewing the site by with
`make container-server`.
-->
### 容器内运行

运行贡献者网站最简单和跨系统兼容的方法是在[容器][docker]内运行。

首先，通过执行`make container-image` 创建用于生成网站的 docker 镜像。

为确保可以在网站查看外部来源内容，请在使用 `make container-server` 预览网站之前运行 `make container-gen-content`。

<!--
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
-->
### 本地运行

有关安装和使用 Hugo 的说明，请参阅 [Hugo 文档][hugo-docs]。请注意，需要安装 extended 版本。

除了 Hugo，还需要 [postcss-cli] 和 [autoprefixer] JavaScript 包。这些可以通过 [Node Package Manager] (`npm`) 从最新版本的 [nodejs] 中使用 

`npm install -g postcss-cli autoprefixer` 安装。

贡献者网站使用 [docsy] 主题。它作为 [git 子模块] 被包含在内。要获取 docsy 及其依赖，请运行以下命令：
```
git submodule update --init --recursive --depth 1
```

为确保可以查看网站外部来源的内容，请在使用 `make server` 预览网站之前执行 `make gen-content` 命令。

**给 OSX 用户的注意事项**

`hack/gen-content.sh` 脚本需要 `find`、`grep` 和 `sed` 等基本软件包的 gnu 版。
```
brew install coreutils findutils grep gnu-sed gnu-tar make readlink
```
然后，更新路径：
```
export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
```

<!--
## Community, discussion, contribution, and support

This project is managed by [SIG Contributor Experience][sig-contribex] as a
part of [KEP-0005][kep-0005]

You can reach the maintainers of this project at:

- [Slack][sig-contribex-slack]
- [Mailing List][sig-contribex-list]
-->
## 社区、讨论、贡献和支持

该项目由 [SIG Contributor Experience][sig-contribex] 作为 [KEP-0005][kep-0005] 的一部分进行管理。

你可以通过以下方式联系工作人员：

- [Slack][sig-contribex-slack]
- [邮件列表][sig-contribex-list]

<!--
## Evolution of this site:

We’re building out this site in real-time! Want to join us and help? Here’s what we have in store for next iterations:

* [x] An Events page showcasing all current and future happenings within the Kubernetes community. We hope to launch this feature by November 2019. Want to help us hit this target? Help us [work on this project](https://github.com/kubernetes-sigs/contributor-site/issues/15) by forking the repo and submitting a pull request!
* [x] Contributor guide/handbook: Feature launch date estimated November 2019
* [ ] Developers' guide/handbook: Feature launch date estimated April 2020
* [ ] Role Board: Feature launch date estimated April 2020
* [ ] Directory of Kubernetes SIGs and other community groups
* [x] Pathways to success for [new Kubernetes contributors](https://git.k8s.io/community/community-membership.md) and mentoring programs
* [ ] Workshop videos
-->
## 本站的演变

我们正在构建这个网站！想加入我们并提供帮助吗？以下是我们为下一次迭代准备的内容：

* [x] 一个活动页面，展示 Kubernetes 社区内所有当前和未来发生的事情。我们希望在 2019 年 11 月之前推出这个功能。想帮助我们实现这个目标吗？通过创建副本并提交拉取请求来帮助我们[在这个项目上的工作](https://github.com/kubernetes-sigs/contributor-site/issues/15)！
* [x] 贡献者指南/手册：预计发布日期为 2019 年 11 月
* [ ] 开发者指南/手册：发布日期预计为 2020 年 4 月
* [ ] 角色委员会：发布日期预计为 2020 年 4 月
* [ ] Kubernetes SIG 和其他社区组的目录
* [x] [新 Kubernetes 贡献者](https://git.k8s.io/community/community-membership.md) 和指导计划的成功之路
* [ ] 会议视频
### 行为守则

参与 Kubernetes 社区要遵守 [Kubernetes 社区行为准则](code-of-conduct.md).

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
[git 子模块]: https://git-scm.com/book/en/v2/Git-Tools-Submodules
