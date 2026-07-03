---
layout: blog
title: "Publishing a Kubernetes SIG's Images to registry.k8s.io"
draft: true
slug: publishing-images-to-registry-k8s-io
author: >
  [Kahiro Okina](https://github.com/kahirokunn) (Craftsman Software, Inc.)
---

For many Kubernetes SIG projects, shipping container images eventually
becomes necessary, and `registry.k8s.io` is the official channel for them. I recently published a
SIG project's first images there. No single step is hard, but the steps live
in four repositories and have to happen in a particular order, which I mostly
learned by tripping over them.

This post is the guide I wish I had at the start. The example project is
`cluster-inventory-api` from
[SIG Multicluster](https://github.com/kubernetes/community/tree/master/sig-multicluster),
but nothing in the procedure is specific to that SIG.

## What Cluster Inventory API publishes

Cluster Inventory API helps applications and tools work with multiple
Kubernetes clusters. It publishes the
[`secretreader`](https://github.com/kubernetes-sigs/cluster-inventory-api/tree/main/plugins/secretreader/cmd/plugin)
and
[`kubeconfig-secretreader`](https://github.com/kubernetes-sigs/cluster-inventory-api/tree/main/plugins/kubeconfig-secretreader/cmd/plugin)
access-provider plugins as OCI images. Consumers mount these images as
[image volumes](https://kubernetes.io/docs/tasks/configure-pod-container/image-volumes/).

## My first plan: ghcr.io

I first tried a common GitHub release pattern: using GitHub Actions to publish
images to `ghcr.io` on a tag push
([cluster-inventory-api#40](https://github.com/kubernetes-sigs/cluster-inventory-api/pull/40)).
The workflow succeeded, but Kubernetes GitHub organizations keep GHCR packages
private, so GHCR cannot be used for public distribution.

{{< figure src="ghcr-path-blocked.svg" class="text-center" width="660" alt="The blocked GHCR path: a tag push triggers GitHub Actions, which pushes the image to ghcr.io, where it cannot be made public." >}}

As described in the
[artifacts documentation](https://github.com/kubernetes/k8s.io/tree/main/artifacts#staging-buckets),
official images take a different route:
[Prow](https://docs.prow.k8s.io/) (the Kubernetes project's CI/CD system)
picks up a tag push and runs Google Cloud Build on Kubernetes-owned
infrastructure to push the image to a staging registry, and the image promoter
then copies it to `registry.k8s.io`.

{{< figure src="official-publishing-path.svg" class="text-center" width="820" alt="The official publishing path: a tag push triggers a Prow postsubmit job, which runs Cloud Build and pushes to a staging registry. The image promoter then copies the image to registry.k8s.io." >}}

For this project, the images that finally shipped through that route were:

```none
registry.k8s.io/cluster-inventory-api/secretreader:v0.1.3
registry.k8s.io/cluster-inventory-api/kubeconfig-secretreader:v0.1.3
```

## The first-time setup, step by step

Besides the image-owning repository, this touches three infrastructure
repositories: [`kubernetes/k8s.io`](https://github.com/kubernetes/k8s.io),
[`kubernetes/test-infra`](https://github.com/kubernetes/test-infra), and
[`kubernetes/org`](https://github.com/kubernetes/org). The pieces depend on
each other like this:

{{< figure src="dependency-overview.svg" alt="A dependency graph for first-time registry.k8s.io image publishing. The image-owning repository provides cloudbuild.yaml and make release-staging, and a signed release tag triggers the kubernetes/test-infra image-pushing postsubmit job. In kubernetes/k8s.io, a staging Google Group must exist before the staging registry can be created, and that registry is the job's push target. The postsubmit job pushes the staging image. That staging image, together with image promoter config in kubernetes/k8s.io and OWNERS validation through kubernetes/org membership, promotes the image to registry.k8s.io." >}}

### Before you start: choose registry paths, tag policy, and owners

Reading `registry.k8s.io/cluster-inventory-api/secretreader:v0.1.3` from the
example above: `<project>` is `cluster-inventory-api`, `<image>` is
`secretreader`, and `v<version>` is `v0.1.3`. For your project, decide:

- `<project>`, which also fixes the staging path
  `us-central1-docker.pkg.dev/k8s-staging-images/<project>`.
- `<image>` for each image you ship.
- The tag policy behind `<version>`.
- Which SIG owns the project, and who reviews and approves.
- Who goes in the promotion `OWNERS` file.
- The staging access group name.

### 1. Make the image-owning repository build images

Set up the repository so that a tag push can build and push a staging image.
You need:

- a `RELEASE.md` documenting the release steps,
- a `cloudbuild.yaml` (the `test-infra` job in step 4 invokes this to build
  and push the image),
- a Dockerfile and/or Make target to build the image,
- a release target that pushes to the staging registry (for example
  `make release-staging`).

References:
[cluster-inventory-api#53](https://github.com/kubernetes-sigs/cluster-inventory-api/pull/53)
(moving to the Prow/Cloud Build approach) and
[cluster-inventory-api#57](https://github.com/kubernetes-sigs/cluster-inventory-api/pull/57)
(passing the staging repository explicitly to `kpromo`).

### 2. Add a Google Group for staging artifacts

Create the Google Group that will get push access to the staging registry, in
your SIG's group configuration under `groups/` in `kubernetes/k8s.io`
([kubernetes/k8s.io#9385](https://github.com/kubernetes/k8s.io/pull/9385)),
and get approval from your SIG leads or chairs. Keep the group-name suffix
within the 18-character limit
([kubernetes/k8s.io#9402](https://github.com/kubernetes/k8s.io/pull/9402)).

### 3. Add a staging registry in kubernetes/k8s.io

Add one entry to the `registries` map in
`infra/gcp/terraform/k8s-staging-images/registries.tf`, mapping `<project>` to
the group from step 2. The module gives that group writer access and makes the
repository publicly readable. Reference:
[kubernetes/k8s.io#9347](https://github.com/kubernetes/k8s.io/pull/9347).

### 4. Add an image-pushing postsubmit job in kubernetes/test-infra

Add a job under `config/jobs/image-pushing/` that runs the image-owning
repository's `cloudbuild.yaml` on a tag push and pushes to the staging
registry. Reference:
[kubernetes/test-infra#36821](https://github.com/kubernetes/test-infra/pull/36821).

### 5. Push a release tag to build a staging image

With everything above in place, push a
[signed tag](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-tags)
from the image-owning repository:

```bash
git tag -s v<version>
git push origin v<version>
gh release create v<version> --draft --generate-notes --verify-tag
```

Then verify the staging image:

```bash
docker manifest inspect us-central1-docker.pkg.dev/k8s-staging-images/<project>/<image>:v<version>
```

Tag events are not processed retroactively: tags created before the release
pipeline existed will not produce a staging image.

### 6. Add the image promoter configuration in kubernetes/k8s.io

Open a `kubernetes/k8s.io` PR that adds the promotion configuration for this
project
([kubernetes/k8s.io#9499](https://github.com/kubernetes/k8s.io/pull/9499)):

- `registry.k8s.io/images/k8s-staging-<project>/OWNERS`,
- `registry.k8s.io/images/k8s-staging-<project>/images.yaml` (the promotion
  target),
- `registry.k8s.io/manifests/k8s-staging-<project>/promoter-manifest.yaml`.

For the first promotion, include the digest and tag entries for the staging
images in `images.yaml`, and get `/lgtm` from a SIG lead. For later releases,
[`kpromo`](https://github.com/kubernetes-sigs/promo-tools) generates this PR
for you (see the routine release steps below). If you are curious how the
promotion machinery works, see
[The Invisible Rewrite: Modernizing the Kubernetes Image Promoter](https://kubernetes.io/blog/2026/03/17/image-promoter-rewrite/).

If anyone you plan to list in `OWNERS` is not yet a Kubernetes organization
member, submit a membership request first
([kubernetes/org#6385](https://github.com/kubernetes/org/pull/6385),
[kubernetes/org#6386](https://github.com/kubernetes/org/pull/6386)).

### 7. Verify the release and publish it

Once the promotion PR merges, run the project's release verification and
confirm the production image is available:

```bash
docker manifest inspect registry.k8s.io/<project>/<image>:v<version>
```

When that works, publish or update the GitHub release and announce it in the
related issues and Slack channels.

### Where to ask for help

Several of these steps depend on other people: reviewers, approvers, and SIG
leads. Expect to wait on reviews between steps rather than finishing in one
sitting. On the [Kubernetes Slack](https://slack.k8s.io/), these channels line
up with the work:

| Channel | Use it for |
| --- | --- |
| `#github-management` | Repository access, GHCR questions, and Kubernetes organization membership |
| `#sig-k8s-infra` | The staging Google Group and staging registry |

## After the first time, it is much lighter

Routine releases only touch the image-owning repository and one promotion PR:

1. Push a signed tag, create a draft GitHub release, and confirm the
   postsubmit pushed the staging image, as in step 5 of the first-time setup.
2. Create the promotion PR with `kpromo pr`, naming the Artifact Registry
   staging repository explicitly with `--staging-repo`:

   ```bash
   kpromo pr \
     --fork <your-github-username> \
     --project <project> \
     --tag v<version> \
     --staging-repo us-central1-docker.pkg.dev/k8s-staging-images/<project>
   ```

3. Once the promotion PR is reviewed and merged, finish as in step 7 of the
   first-time setup.

## Acknowledgments

Thanks to [Mike Ng](https://github.com/mikeshng) and
[Laura Lorenz](https://github.com/lauralorenz) for attending meetings on my
behalf, connecting me with the right people, and coordinating the work across
SIG Multicluster; [Jian Qiu](https://github.com/qiujian16) for reviewing the
implementation;
[Stephen Kitt](https://github.com/skitt) for reviewing the release process and
clarifying the publishing rules; and
[Arnaud M.](https://github.com/ameukam) for reviewing the `kubernetes/k8s.io`
pull requests and guiding the infrastructure and promotion changes.

## References

- [cluster-inventory-api releases](https://github.com/kubernetes-sigs/cluster-inventory-api/releases)
- [Using Plugin OCI Images](https://github.com/kubernetes-sigs/cluster-inventory-api/blob/main/docs/plugin-images.md)
- [Image volumes](https://kubernetes.io/docs/tasks/configure-pod-container/image-volumes/)
- [registry.k8s.io: faster, cheaper and Generally Available (GA)](https://kubernetes.io/blog/2022/11/28/registry-k8s-io-faster-cheaper-ga/)
- [Publishing official artifact images (`kubernetes/k8s.io/artifacts`)](https://github.com/kubernetes/k8s.io/tree/main/artifacts#staging-buckets)
- [`kpromo` (promo-tools)](https://github.com/kubernetes-sigs/promo-tools)
- [Kubernetes Slack](https://slack.k8s.io/)
