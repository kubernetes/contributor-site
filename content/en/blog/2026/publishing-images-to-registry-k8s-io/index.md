---
layout: blog
title: "Publishing a Kubernetes SIG's Images to registry.k8s.io"
draft: true
slug: publishing-images-to-registry-k8s-io
author: >
  [Kahiro Okina](https://github.com/kahirokunn) (Craftsman Software, Inc.)
---

If you're publishing container images for a Kubernetes SIG project, you might
expect the same publishing workflow used by other container registries to work.
That was my assumption too. My workflow successfully published the images, but
they weren't publicly available. Instead, official Kubernetes project images
are distributed through
[registry.k8s.io](https://github.com/kubernetes/k8s.io/tree/main/registry.k8s.io),
the Kubernetes project's official container image registry.

No single step was hard, but the steps were spread across multiple repositories
and had to happen in a particular order, something I mostly learned by tripping
over them. This post is the guide I wish I had at the start. It walks through
that workflow end to end using Cluster Inventory API from
[SIG Multicluster](https://github.com/kubernetes/community/tree/master/sig-multicluster)
as an example. The same process applies to eligible Kubernetes subprojects that
publish official container images.

## My first attempt: GHCR

I first tried a common GitHub release pattern: using GitHub Actions to publish
images to `ghcr.io` on a tag push
([cluster-inventory-api#40](https://github.com/kubernetes-sigs/cluster-inventory-api/pull/40)).
The workflow succeeded, but Kubernetes GitHub organizations keep GHCR packages
private, so GHCR cannot be used for public distribution.

{{< figure src="ghcr-path-blocked.svg" class="text-center" width="660" alt="The blocked GHCR path: a tag push triggers GitHub Actions, which pushes the image to ghcr.io, where it cannot be made public." >}}

As described in the
[registry.k8s.io documentation](https://github.com/kubernetes/k8s.io/tree/main/registry.k8s.io),
official images take a different route:
[Prow](https://docs.prow.k8s.io/) (the Kubernetes project's CI/CD system)
picks up a tag push and runs Google Cloud Build on Kubernetes-owned
infrastructure to push the image to a staging registry, and the image promoter
then copies it to `registry.k8s.io`.

{{< figure src="official-publishing-path.svg" class="text-center" width="820" alt="The official publishing path: a tag push triggers a Prow postsubmit job, which runs Cloud Build and pushes to a staging registry. The image promoter then copies the image to registry.k8s.io." >}}

## The first-time setup, step by step

Besides the image-owning repository, this touches three infrastructure
repositories: [`kubernetes/k8s.io`](https://github.com/kubernetes/k8s.io),
[`kubernetes/test-infra`](https://github.com/kubernetes/test-infra), and
[`kubernetes/org`](https://github.com/kubernetes/org). The pieces depend on
each other like this:

{{< figure src="dependency-overview.svg" alt="A dependency graph for first-time registry.k8s.io image publishing. The image-owning repository provides cloudbuild.yaml and image build configuration, and a signed release tag triggers the kubernetes/test-infra image-pushing postsubmit job. In kubernetes/k8s.io, a staging Google Group must exist before the staging registry can be created, and that registry is the job's push target. The postsubmit job pushes the staging image. That staging image, together with image promoter config in kubernetes/k8s.io and OWNERS validation through kubernetes/org membership, promotes the image to registry.k8s.io." >}}

### Before you start: decide your project details

Before setting up the publishing workflow, decide a few project-specific
details. These values will be reused throughout the setup when creating the
staging registry, configuring image builds, and setting up image promotion:

- `<project>`, which determines the staging registry path
  `us-central1-docker.pkg.dev/k8s-staging-images/<project>`.
- `<image>` for each image you ship.
- Decide how your project will version releases.

For the Cluster Inventory API example, these values form
`registry.k8s.io/cluster-inventory-api/secretreader:v0.1.3`, where `<project>`
is `cluster-inventory-api`, `<image>` is `secretreader`, and `<version>` is
`0.1.3`.

### 1. Set up your project repository to build images

Before Kubernetes infrastructure can build and publish your images, the
image-owning repository must define how they are built. As described in the
[image-pushing documentation](https://github.com/kubernetes/test-infra/blob/master/config/jobs/image-pushing/README.md),
this requires:

- a `RELEASE.md` documenting the release steps,
- a `cloudbuild.yaml` file that invokes the project's image build and push
  process,
- the project-specific build configuration invoked by `cloudbuild.yaml`. See
  the [build example](https://github.com/kubernetes/test-infra/blob/master/config/jobs/image-pushing/README.md#build-example).

References:
[cluster-inventory-api#53](https://github.com/kubernetes-sigs/cluster-inventory-api/pull/53)
(moving to the Prow/Cloud Build approach) and
[cluster-inventory-api#57](https://github.com/kubernetes-sigs/cluster-inventory-api/pull/57)
(passing the staging repository explicitly to `kpromo`).

### 2. Add a Google Group for staging artifacts

Kubernetes uses a Google Group to control who can push images into the staging
registry. Before the registry can be created, this group must exist.

Create a Google Group named
`k8s-infra-staging-<project-name>@kubernetes.io` in your SIG's
[`groups/` configuration](https://github.com/kubernetes/k8s.io/tree/main/groups)
in `kubernetes/k8s.io`. After the PR merges, Kubernetes infrastructure creates
the group automatically. For example, see
[kubernetes/k8s.io#9385](https://github.com/kubernetes/k8s.io/pull/9385).

Keep the `<project-name>` suffix within the **18-character limit**. See
[kubernetes/k8s.io#9402](https://github.com/kubernetes/k8s.io/pull/9402) for an
example where the group name was shortened to meet this requirement.

### 3. Add a staging registry in kubernetes/k8s.io

Add one entry to the `registries` map in
`infra/gcp/terraform/k8s-staging-images/registries.tf`, mapping `<project>` to
the group from step 2. The module gives that group writer access and makes the
repository publicly readable. Reference:
[kubernetes/k8s.io#9347](https://github.com/kubernetes/k8s.io/pull/9347).

### 4. Add an image-pushing postsubmit job in kubernetes/test-infra

Add a job under `config/jobs/image-pushing/` that runs the image-owning
repository's `cloudbuild.yaml` on a tag push and pushes to the staging
registry. See the
[Prow config template](https://github.com/kubernetes/test-infra/blob/master/config/jobs/image-pushing/README.md#prow-config-template).
For reference:
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

Verify that the image was successfully published to the staging registry.

Tag events are not processed retroactively: tags created before the release
pipeline existed will not produce a staging image.

Note: Staging registries have a 90-day retention policy and are intended only
for intermediate builds. End users should consume images from
`registry.k8s.io` after they have been promoted.

### 6. Add the image promoter configuration in kubernetes/k8s.io

At this point, the image exists only in the staging registry. The next step
configures the Image Promoter, which copies approved images into the public
`registry.k8s.io` registry.

Open a `kubernetes/k8s.io` PR that adds the promotion configuration for this
project
([kubernetes/k8s.io#9499](https://github.com/kubernetes/k8s.io/pull/9499)):

- `registry.k8s.io/images/k8s-staging-<project>/OWNERS`,
- `registry.k8s.io/images/k8s-staging-<project>/images.yaml` (the promotion
  target),
- `registry.k8s.io/manifests/k8s-staging-<project>/promoter-manifest.yaml`.

The `promoter-manifest.yaml` file stores credentials and other registry
metadata, while `images.yaml` stores the image data. The `OWNERS` file lets more
project members approve new images for promotion.

For the first promotion, include the digest and tag entries for the staging
images in `images.yaml`, and get `/lgtm` from a SIG lead. For later releases,
follow the routine release steps below to create the promotion PR with
`kpromo`. If you are curious how the promotion machinery works, see
[The Invisible Rewrite: Modernizing the Kubernetes Image Promoter](https://kubernetes.io/blog/2026/03/17/image-promoter-rewrite/).

If anyone you plan to list in `OWNERS` is not yet a Kubernetes organization
member, submit a membership request first
([kubernetes/org#6385](https://github.com/kubernetes/org/pull/6385),
[kubernetes/org#6386](https://github.com/kubernetes/org/pull/6386)).

### 7. Verify the release and publish it

Once the promotion PR merges, the image promoter workflow publishes the image
from the staging registry to `registry.k8s.io`. The promotion is handled by
Kubernetes CI jobs:

- `post-k8sio-image-promo` runs after the merge and performs the promotion.
- `ci-k8sio-image-promo` periodically retries promotions in case of transient
  failures.

Verify that the promotion jobs complete successfully and that the image is
available from `registry.k8s.io`.

When that works, publish or update the GitHub release and announce it in the
related issues and Slack channels.

For Cluster Inventory API, completing these steps made both images publicly
available:

```none
registry.k8s.io/cluster-inventory-api/secretreader:v0.1.3
registry.k8s.io/cluster-inventory-api/kubeconfig-secretreader:v0.1.3
```

### Where to ask for help

Several of these steps depend on other people: reviewers, approvers, and SIG
leads. Expect to wait on reviews between steps rather than finishing in one
sitting. On the [Kubernetes Slack](https://slack.k8s.io/), these channels line
up with the work:

| Channel | Use it for |
| --- | --- |
| [`#github-management`](https://kubernetes.slack.com/archives/C01672LSZL0) | Repository access, Kubernetes organization membership, and GitHub-related questions |
| [`#sig-k8s-infra`](https://kubernetes.slack.com/archives/CCK68P2Q2) | The staging Google Group, staging registry, and image publishing infrastructure |

## After the first time, it is much lighter

Routine releases only touch the image-owning repository and one promotion PR:

1. Push a signed tag, create a draft GitHub release, and confirm the
   postsubmit pushed the staging image, as in step 5 of the first-time setup.
2. Follow the
   [promotion pull request guide](https://sigs.k8s.io/promo-tools/docs/promotion-pull-requests.md)
   and create the promotion PR with `kpromo pr`, naming the Artifact Registry
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
