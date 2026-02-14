# Copyright 2018 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

CONTAINER_ENGINE		?= docker
STAGING_IMAGE_REGISTRY	:= us-central1-docker.pkg.dev/k8s-staging-images
IMAGE_REGISTRY			?= ${STAGING_IMAGE_REGISTRY}/contributor-site
IMAGE_NAME				:= k8s-contrib-site-hugo
IMAGE_REPO				:= $(IMAGE_REGISTRY)/$(IMAGE_NAME)
IMAGE_VERSION			:= $(shell scripts/hash-files.sh Dockerfile Makefile netlify.toml .dockerignore cloudbuild.yaml package.json package-lock.json hugo.yaml go.mod go.sum 2>/dev/null | cut -c 1-12)
COMMIT					:= $(shell git rev-parse --short HEAD)
CONTAINER_BASE_OPTS := --rm -it --security-opt=no-new-privileges --cap-drop=ALL
ifeq ($(CONTAINER_ENGINE),podman)
	# Rootless Podman requires userns mapping and SELinux relabeling
	CONTAINER_BASE_OPTS += --userns=keep-id
	MOUNT_OPTS := ,relabel=shared
else
	# Docker hardening: run as non-root user (assuming UID 1000 matches common dev setups)
	# Note: In rootless Podman, keep-id maps the host user to the same UID inside,
	# so we don't need (and shouldn't use) --user 1000:1000 there.
	CONTAINER_BASE_OPTS += --user 1000:1000
endif

CONTAINER_RUN			:= $(CONTAINER_ENGINE) run $(CONTAINER_BASE_OPTS) -v "$(CURDIR):/src$(if $(filter podman,$(CONTAINER_ENGINE)),:z)"
CONTAINER_RUN_TTY		:= $(CONTAINER_ENGINE) run $(CONTAINER_BASE_OPTS)

HUGO_VERSION			:= $(shell grep ^HUGO_VERSION netlify.toml | tail -n 1 | cut -d '=' -f 2 | tr -d " \"\n")
GIT_TAG					?= v$(HUGO_VERSION)-$(IMAGE_VERSION)
CONTAINER_IMAGE			:= $(IMAGE_REPO):$(GIT_TAG)

# Docker buildx related settings for multi-arch images
DOCKER_BUILDX ?= docker buildx

# Reuse host Go module cache in container so modules aren't re-downloaded each run (default: $HOME/go/pkg/mod)
GOMODCACHE_HOST		?= $(HOME)/go/pkg/mod
CONTAINER_HUGO_ENV	:= -e GOMODCACHE=/tmp/gomod
CONTAINER_HUGO_MOUNTS = \
	--read-only \
	--mount type=bind,source=$(CURDIR)/.git,target=/src/.git,readonly$(MOUNT_OPTS) \
	--mount type=bind,source=$(CURDIR)/go.mod,target=/src/go.mod$(MOUNT_OPTS) \
	--mount type=bind,source=$(CURDIR)/go.sum,target=/src/go.sum$(MOUNT_OPTS) \
	--mount type=bind,source=$(GOMODCACHE_HOST),target=/tmp/gomod$(MOUNT_OPTS) \
	--mount type=bind,source=$(CURDIR)/assets,target=/src/assets,readonly$(MOUNT_OPTS) \
	--mount type=bind,source=$(CURDIR)/content,target=/src/content,readonly$(MOUNT_OPTS) \
	--mount type=bind,source=$(CURDIR)/layouts,target=/src/layouts,readonly$(MOUNT_OPTS) \
	--mount type=bind,source=$(CURDIR)/static,target=/src/static,readonly$(MOUNT_OPTS) \
	--mount type=tmpfs,destination=/tmp,tmpfs-mode=01777 \
	--mount type=bind,source=$(CURDIR)/hugo.yaml,target=/src/hugo.yaml,readonly$(MOUNT_OPTS)
# Writable mount for container-render output (Hugo writes to /out -> host public/)
CONTAINER_RENDER_MOUNT	:= --mount type=bind,source=$(CURDIR)/public,target=/out$(MOUNT_OPTS)

# Command to ensure the container image is available locally (pull or build)
IMAGE_ENSURE := $(CONTAINER_ENGINE) pull $(CONTAINER_IMAGE) || $(MAKE) container-image

# Base command for running Hugo in the container with all shared mounts and env vars
CONTAINER_HUGO_RUN := $(CONTAINER_RUN_TTY) $(CONTAINER_HUGO_ENV) $(CONTAINER_HUGO_MOUNTS)

# Fast NONBLOCKING IO to stdout caused by the hack/gen-content.sh script can
# cause Netlify builds to terminate unexpectedly. This forces stdout to block.
BLOCK_STDOUT_CMD	:= python -c "import os,sys,fcntl; \
					flags = fcntl.fcntl(sys.stdout, fcntl.F_GETFL); \
					fcntl.fcntl(sys.stdout, fcntl.F_SETFL, flags&~os.O_NONBLOCK);"

.DEFAULT_GOAL	:= help

.PHONY: targets container-targets
targets: help modules-get modules-tidy render server clean clean-all production-build preview-build
container-targets: container-image container-push container-render container-server

help: ## Show this help text.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

dependencies:
	npm ci

modules-get: ## Download and update Hugo modules.
	hugo mod get -u

modules-tidy: ## Clean up Hugo module dependencies.
	hugo mod tidy


render: dependencies ## Build the site using Hugo on the host. Run 'make modules-get' once if modules are missing.
	hugo --logLevel info --ignoreCache --minify


server: dependencies ## Run Hugo locally. Run 'make modules-get' once if modules are missing.
	hugo server \
		--logLevel info \
		--buildDrafts \
		--buildFuture \
		--disableFastRender \
		--ignoreCache

docker-image:
	@echo -e "**** The use of docker-image is deprecated. Use container-image instead. ****" 1>&2
	$(MAKE) container-image

container-image: ## Build container image for use with container-* targets.
	$(CONTAINER_ENGINE) build . -t $(CONTAINER_IMAGE) --label git_commit=$(COMMIT) --build-arg HUGO_VERSION=$(HUGO_VERSION)

container-push: container-image ## Push container image for the preview of the website
	$(CONTAINER_ENGINE) push $(CONTAINER_IMAGE)

PLATFORMS ?= linux/arm64,linux/amd64
docker-push: ## Build a multi-architecture image and push that into the registry
	docker run --rm --privileged tonistiigi/binfmt:qemu-v8.1.5-43@sha256:46c5a036f13b8ad845d6703d38f8cce6dd7c0a1e4d42ac80792279cabaeff7fb --install all
	docker version
	$(DOCKER_BUILDX) version
	$(DOCKER_BUILDX) inspect image-builder > /dev/null 2>&1 || $(DOCKER_BUILDX) create --name image-builder --use
	# copy existing Dockerfile and insert --platform=${TARGETPLATFORM} into Dockerfile.cross, and preserve the original Dockerfile
	sed -e 's/\(^FROM\)/FROM --platform=\$$\{TARGETPLATFORM\}/' Dockerfile > Dockerfile.cross
	$(DOCKER_BUILDX) build \
		--push \
		--platform=$(PLATFORMS) \
		--build-arg HUGO_VERSION=$(HUGO_VERSION) \
		--tag $(CONTAINER_IMAGE) \
		-f Dockerfile.cross .
	$(DOCKER_BUILDX) stop image-builder
	rm Dockerfile.cross


docker-render:
	@echo -e "**** The use of docker-render is deprecated. Use container-render instead. ****" 1>&2
	$(MAKE) container-render

container-render: ## Build the site using Hugo within a container (equiv to render).
	@$(IMAGE_ENSURE)
	$(CONTAINER_HUGO_RUN) $(CONTAINER_RENDER_MOUNT) $(CONTAINER_IMAGE) bash -c 'cd /src && hugo mod get && hugo --noBuildLock --destination /out --logLevel info --ignoreCache --minify'

docker-server:
	@echo -e "**** The use of docker-server is deprecated. Use container-server instead. ****" 1>&2
	$(MAKE) container-server

container-server: ## Run Hugo locally within a container, available at http://localhost:1313/
	# no build lock to allow for read-only mounts
	@$(IMAGE_ENSURE)
	$(CONTAINER_HUGO_RUN) -p 1313:1313 $(CONTAINER_IMAGE) \
	bash -c 'cd /src && hugo mod get && \
		hugo server \
		--environment preview \
		--logLevel info \
		--noBuildLock \
		--bind 0.0.0.0 \
		--buildDrafts \
		--buildFuture \
		--disableFastRender \
		--ignoreCache \
		--destination /tmp/hugo \
		--cleanDestinationDir'

clean: ## Cleans build artifacts.
	rm -rf public/ resources/ _tmp/ _vendor/

clean-all: ## Cleans both build artifacts and files synced to content directory
	rm -rf public/ resources/ _tmp/ _vendor/
	rm -f content/en/events/community-meeting.md
	rm -f content/en/events/meet-our-contributors.md
	rm -f content/en/events/office-hours.md
	rm -f content/en/docs/cheatsheet.md
	rm -f content/en/resources/rename.md
	find content/en/docs/guide -maxdepth 1 \
		-not -path content/en/docs/guide \
		-not -name ".gitignore" \
		-exec rm -rf {} \;
	find content/en/docs/comms -maxdepth 1 \
		-not -path content/en/docs/comms \
		-not -name ".gitignore" \
		-not -name "_index.md" \
		-exec rm -rf {} \;
	find content/en/resources/release -maxdepth 1  \
		-not -path content/en/resources/release \
		-not -name ".gitignore" \
		-exec rm -rf {} \;
	find content/en/community -maxdepth 1 \
		-not -path content/en/community \
		-not -name ".gitignore" \
		-not -name "_index.md" \
		-not -name "code-of-conduct.md" \
		-exec rm -rf {} \;

production-build: dependencies ## Builds the production site (this command used only by Netlify).
	$(BLOCK_STDOUT_CMD)
	hugo mod get
	hugo \
		--environment production \
		--logLevel info \
		--ignoreCache \
		--minify

preview-build: dependencies ## Builds a deploy preview of the site (this command used only by Netlify).
	$(BLOCK_STDOUT_CMD)
	hugo mod get
	hugo \
		--environment preview \
		--logLevel info \
		--baseURL $(DEPLOY_PRIME_URL) \
		--buildDrafts \
		--buildFuture \
		--ignoreCache \
		--minify
