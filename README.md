# Kubernetes Contributor Site

This repository contains the [Hugo][hugo] site and generator scripts for the
Kubernetes Contributor site.  Much of the content is generated from the [kubernetes/community][kcommunity]
repo directly and care should be taken when working within the [content directory](content/). The
hugo theme being used is a slimmed down derivative of the [docdock theme][docdock].

The heavy lifting occurs within the [gen-site.sh](gen-site.sh) script. If not being called externally,
it will clone the [kubernetes/community][kcommunity] within the [build](build/) directory then sync
specific directories and files to the [content directory](content/). 

Content is synced following the below rules:
* `committee-steering` is moved to `governance/steering-committee`.
* `committee-code-of-conduct` directory is moved to `/governance/cocc`.
* `github-management` is moved to `governance/github-management`
* `governance.md` is moved to `governance/README.md` and will become the default index page for the
   governance section.
* `sig-governance.md` and `community-membership.md` are moved to the root of `governance/`.
* Directories prefixed with `sig-`  and `wg-` will be synced to the `sigs` directory.
* `sig-list.md` is moved to `sigs/README.md` and will become the default index page for the sigs section
* Other directories not included in the [exclude.list](exclude.list) are copied to the 
  root of the [content directory](content/).
* Files at the root of the directory will **only** be copied over if they are listed in the
  [include.list](include.list) with the exclusion of `sig-list.md` and `README.md`.
* `sig-list.md` is copied to both the `special-interest-groups` and `working-groups` and renamed
  to `README.md`.
* The `README.md` from the root of the community repository is copied over to the root of the
  [content directory](content/) for now.


Next it will go through all the files within the [content directory](content/) and search for any
links that may need to be corrected to function outside of github along with inserting a
[front-matter][frontmatter] header (if needed).

Lastly, any `README.md` files are renamed to `_index.md`. These function similarly to `README.md`
files within a GitHub repository, but are what Hugo is expecting.

At that point the site can be previewed locally with `hugo serve`, or the site built with `hugo`.
If it is built, the default location is `build/public`. 


# Building the Site

The Kubernetes Contributor Site is built with [Hugo][hugo].  For instructions on installing and
general usage, see the [Hugo Documentation]().

Once Hugo is installed, clone the repository locally. Then run the [`gen-site.sh`](gen-site.sh), 
script to pull down the [kubernetes/community][kcommunity] repository and generate the site content. 

After the script completes, the site can be previewed by executing `hugo serve` from the project
directory. If satisfied with your changes, the site can be fully rendered with the `hugo` command
to the `build/public` directory.

### Note to MAC Users
OSX by default ships with an outdated version of bash that does not support all the functionality
used by the site generator script. Bash can be safely updated via [homebrew](https://brew.sh/).
Once installed, execute the below commands to install a newer version of bash.
```
$ brew install bash
$ sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells'
$ chsh -s /usr/local/bin/bash
```
You may need to restart or log out and log back in again to have it fully apply.


## Community, discussion, contribution, and support

This project is managed by [SIG Contributor Experience][sig-contribex] as a part of [KEP-0005][kep-0005]

You can reach the maintainers of this project at:

- [Slack](http://slack.k8s.io/#sig-contribex)
- [Mailing List](https://groups.google.com/forum/#!forum/kubernetes-sig-contribex)


### Code of conduct

Participation in the Kubernetes community is governed by the [Kubernetes Code of Conduct](code-of-conduct.md).

[hugo]: https://gohugo.io/
[hugo-docs]: https://gohugo.io/documentation/
[docdock]: https://github.com/vjeantet/hugo-theme-docdock
[kcommunity]: https://git.k8s.io/community
[frontmatter]: https://gohugo.io/content-management/front-matter/
[sig-contribex]: https://github.com/kubernetes/community/blob/master/sig-contributor-experience/README.md
[kep-0005]: https://github.com/kubernetes/community/blob/master/keps/sig-contributor-experience/0005-contributor-site.md