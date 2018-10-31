# Kubernetes Contributor Site

This repository contains the [Hugo][hugo] site and generator scripts for the
Kubernetes Contributor site.  Much of the content is generated from the 
[kubernetes/community][kcommunity] repo directly and care should be taken when
working within the [content directory](content/). The hugo theme being used is
a slimmed down derivative of the [docdock theme][docdock].

The heavy lifting occurs within the [gen-site.sh](gen-site.sh) script. If not
being called externally, it will clone the [kubernetes/community][kcommunity]
within the [build](build/) directory, do some pre-processing (expand relative
links, insert [frontmatter][frontmatter] etc), then sync specific directories
and files to the [content directory](content/).

Content is synced following the below rules:
* `committee-steering` is moved to `governance/steering-committee`.
* `committee-code-of-conduct` directory is moved to `/governance/cocc`.
* `github-management` is moved to `governance/github-management`
* `governance.md` is moved to `governance/README.md` and will become the default
   index page for the governance section.
* `sig-governance.md` and `community-membership.md` are moved to the root of
  `governance/`.
* Directories prefixed with `sig-`  and `wg-` will be synced to the `sigs`
  directory.
* `sig-list.md` is moved to `sigs/README.md` and will become the default index
  page for the sigs section/
* Other directories not included in the
  [kcommunity_exclude.list](kcommunity_exclude.list) are copied to the root of
  the [content directory](content/).
* `sig-list.md` is copied to both the `special-interest-groups` and
  `working-groups` and renamed to `README.md`.
* The `README.md` from the root of the community repository is copied over to
  the root of the [content directory](content/) for now.


Next it will go through all the files within the [content directory](content/)
and search for any links that may need to be corrected and rename  `README.md`
files are renamed to `_index.md`. These function similarly to `README.md` files
within a GitHub repository, but are what Hugo is expecting.

Lastly, it will layer the content from [managed_content directory](managed_content)
directory on top of the [content directory](content/). Files within the
[managed_content directory](managed_content) are 'out of band' and intended 
**NOT** to be managed from another source.

At that point the site can be previewed locally with `hugo serve`, or the site
built with `hugo`. If it is built, the default location is `build/public`. 


# Building the Site

The Kubernetes Contributor Site is built with [Hugo][hugo].  For instructions
on installing and general usage, see the [Hugo Documentation][hugo-docs].

Once Hugo is installed, clone the repository locally. Then run the
[`gen-site.sh`](gen-site.sh),  script to pull down the [kubernetes/community][kcommunity]
repository and generate the site content. 

After the script completes, the site can be previewed by executing `hugo serve`
from the project directory. If satisfied with your changes, the site can be
fully rendered with the `hugo` command to the `build/public` directory.

### Note to MAC Users
OSX by default ships with an outdated version of bash that does not support all
the functionality used by the site generator script. Bash can be safely updated
via [homebrew](https://brew.sh/). Once installed, execute the below commands to
install a newer version of bash.
```
$ brew install bash
$ sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells'
$ chsh -s /usr/local/bin/bash
```
You may need to restart or log out and log back in again to have it fully apply.

The site generator script also makes use of the gnu version of several tools.
```
$ brew install gnu-sed grep --with-default-names
$ brew install coreutils
```

Installing `coreutils` will require some additional configuration that it will
display post install to function correctly with the gen-site script.


## Community, discussion, contribution, and support

This project is managed by [SIG Contributor Experience][sig-contribex] as a
part of [KEP-0005][kep-0005]

You can reach the maintainers of this project at:

- [Slack][sig-contribex-slack]
- [Mailing List][sig-contribex-list]


### Code of conduct

Participation in the Kubernetes community is governed by the
[Kubernetes Code of Conduct](code-of-conduct.md).

[hugo]: https://gohugo.io/
[hugo-docs]: https://gohugo.io/documentation/
[docdock]: https://github.com/vjeantet/hugo-theme-docdock
[kcommunity]: https://git.k8s.io/community
[frontmatter]: https://gohugo.io/content-management/front-matter/
[sig-contribex]: https://github.com/kubernetes/community/blob/master/sig-contributor-experience/README.md
[sig-contribex-slack]: http://slack.k8s.io/#sig-contribex
[sig-contribex-list]: https://groups.google.com/forum/#!forum/kubernetes-sig-contribex
[kep-0005]: https://github.com/kubernetes/community/blob/master/keps/sig-contributor-experience/0005-contributor-site.md