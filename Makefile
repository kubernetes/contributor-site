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
IMAGE_VERSION			:= $(shell scripts/hash-files.sh Dockerfile Makefile netlify.toml .dockerignore cloudbuild.yaml package.json package-lock.json | cut -c 1-12)
COMMIT					:= $(shell git rev-parse --short HEAD)
CONTAINER_RUN			:= $(CONTAINER_ENGINE) run --rm -it -v "$(CURDIR):/src"
CONTAINER_RUN_TTY		:= $(CONTAINER_ENGINE) run --rm -it
HUGO_VERSION			:= $(shell grep ^HUGO_VERSION netlify.toml | tail -n 1 | cut -d '=' -f 2 | tr -d " \"\n")
GO_VERSION				:= $(shell grep ^GO_VERSION netlify.toml | tail -n 1 | cut -d '=' -f 2 | tr -d " \"\n")
UNAME_OS				:= $(shell uname -s | tr '[:upper:]' '[:lower:]')
UNAME_ARCH				:= $(shell uname -m)
GO_OS					:= $(if $(findstring darwin,$(UNAME_OS)),darwin,linux)
GO_ARCH					:= $(if $(findstring arm64,$(UNAME_ARCH)),arm64,$(if $(findstring aarch64,$(UNAME_ARCH)),arm64,amd64))
GO_BIN					:= PATH="/tmp/go/bin:$(PATH)"
GIT_TAG					?= v$(HUGO_VERSION)-$(IMAGE_VERSION)
CONTAINER_IMAGE			:= $(IMAGE_REPO):$(GIT_TAG)

# Docker buildx related settings for multi-arch images
DOCKER_BUILDX ?= docker buildx

CONTAINER_HUGO_MOUNTS = \
	--read-only \
	--mount type=bind,source=$(CURDIR)/.git,target=/src/.git,readonly \
	--mount type=bind,source=$(CURDIR)/assets,target=/src/assets,readonly \
	--mount type=bind,source=$(CURDIR)/content,target=/src/content,readonly \
	--mount type=bind,source=$(CURDIR)/hack,target=/src/hack,readonly \
	--mount type=bind,source=$(CURDIR)/layouts,target=/src/layouts,readonly \
	--mount type=bind,source=$(CURDIR)/static,target=/src/static,readonly \
	--mount type=tmpfs,destination=/tmp,tmpfs-mode=01777 \
	--mount type=bind,source=$(CURDIR)/hugo.yaml,target=/src/hugo.yaml,readonly \
	--mount type=bind,source=$(CURDIR)/go.mod,target=/src/go.mod,relabel=shared \
	--mount type=bind,source=$(CURDIR)/go.sum,target=/src/go.sum,relabel=shared

# Fast NONBLOCKING IO to stdout can cause Netlify builds to terminate
# unexpectedly. This forces stdout to block.
BLOCK_STDOUT_CMD	:= python3 -c "import os,sys,fcntl; \
					flags = fcntl.fcntl(sys.stdout, fcntl.F_GETFL); \
					fcntl.fcntl(sys.stdout, fcntl.F_SETFL, flags&~os.O_NONBLOCK);"

.DEFAULT_GOAL	:= help

.PHONY: targets container-targets
targets: help modules-update modules-download modules-tidy install-go render server clean clean-all production-build preview-build
container-targets: container-image container-push container-render container-server

help: ## Show this help text.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

dependencies:
	npm ci

modules-update: ## Update Hugo modules to latest upstream commits.
	$(GO_BIN) hugo mod get -u
	$(GO_BIN) hugo mod tidy

modules-tidy: ## Clean up unused Hugo module entries from go.sum.
	$(GO_BIN) hugo mod tidy

modules-download: ## Download pinned Hugo modules to local cache (no update).
	$(GO_BIN) hugo mod download

render: dependencies ## Build the site using Hugo on the host.
	hugo --logLevel info --ignoreCache --minify

server: dependencies ## Run Hugo locally (if Hugo "extended" is installed locally)
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
	$(CONTAINER_RUN_TTY) $(CONTAINER_HUGO_MOUNTS) $(CONTAINER_IMAGE) hugo --logLevel info --ignoreCache --minify

docker-server:
	@echo -e "**** The use of docker-server is deprecated. Use container-server instead. ****" 1>&2
	$(MAKE) container-server

container-server: modules-download ## Run Hugo locally within a container, available at http://localhost:1313/
	# no build lock to allow for read-only mounts
	$(CONTAINER_RUN_TTY) -p 1313:1313 \
		$(CONTAINER_HUGO_MOUNTS) \
		--cap-drop=ALL \
		--cap-drop=AUDIT_WRITE \
		--mount type=bind,source=$(HOME)/go/pkg/mod,target=/tmp/gomod,relabel=shared \
		-e GOMODCACHE=/tmp/gomod \
		$(CONTAINER_IMAGE) \
	bash -c 'hugo server \
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
	rm -rf public/ resources/ _tmp/

clean-all: ## Cleans both build artifacts and files synced to content directory
	rm -rf public/ resources/ _tmp/

install-go: ## Install Go for Hugo module support.
	$(GO_BIN) go version 2>/dev/null | grep -qF "go$(GO_VERSION)" || { \
		rm -rf /tmp/go; \
		curl -sSfL "https://go.dev/dl/go$(GO_VERSION).$(GO_OS)-$(GO_ARCH).tar.gz" -o /tmp/go.tgz; \
		mkdir -p /tmp/go; \
		tar -xz -C /tmp/go -f /tmp/go.tgz; \
		mv /tmp/go/go/* /tmp/go/; \
		rm -rf /tmp/go/go; \
	}

production-build: install-go ## Builds the production site (this command used only by Netlify).
	$(BLOCK_STDOUT_CMD)
	$(GO_BIN) hugo mod get -u
	$(GO_BIN) hugo mod tidy
	$(GO_BIN) hugo \
		--environment production \
		--logLevel info \
		--ignoreCache \
		--minify

preview-build: install-go ## Builds a deploy preview of the site (this command used only by Netlify).
	$(BLOCK_STDOUT_CMD)
	$(GO_BIN) hugo \
		--environment preview \
		--logLevel info \
		--baseURL $(DEPLOY_PRIME_URL) \
		--buildDrafts \
		--buildFuture \
		--ignoreCache \
		--minify
