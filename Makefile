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
IMAGE_VERSION			:= $(shell scripts/hash-files.sh Dockerfile Makefile netlify.toml .dockerignore cloudbuild.yaml package.json package-lock.json go.mod go.sum | cut -c 1-12)
COMMIT					:= $(shell git rev-parse --short HEAD)
CONTAINER_RUN			:= $(CONTAINER_ENGINE) run --rm -v "$(CURDIR):/src"
CONTAINER_RUN_TTY		:= $(CONTAINER_ENGINE) run --rm
HUGO_VERSION			:= $(shell grep ^HUGO_VERSION netlify.toml | tail -n 1 | cut -d '=' -f 2 | tr -d " \"\n")
GO_VERSION				:= $(shell grep ^GO_VERSION netlify.toml | tail -n 1 | cut -d '=' -f 2 | tr -d " \"\n")
GIT_TAG					?= v$(HUGO_VERSION)-$(IMAGE_VERSION)
CONTAINER_IMAGE			:= $(IMAGE_REPO):$(GIT_TAG)
GOMODCACHE				?= $(shell go env GOMODCACHE)

# Docker buildx related settings for multi-arch images
DOCKER_BUILDX ?= docker buildx

CONTAINER_HUGO_MOUNTS = \
	--read-only \
	--mount type=bind,source=$(CURDIR)/.git,target=/src/.git,readonly \
	--mount type=bind,source=$(CURDIR)/go.mod,target=/src/go.mod \
	--mount type=bind,source=$(CURDIR)/go.sum,target=/src/go.sum \
	--mount type=bind,source=$(CURDIR)/assets,target=/src/assets,readonly \
	--mount type=bind,source=$(CURDIR)/content,target=/src/content,readonly \
	--mount type=bind,source=$(CURDIR)/layouts,target=/src/layouts,readonly \
	--mount type=bind,source=$(CURDIR)/static,target=/src/static,readonly \
	--mount type=tmpfs,destination=/tmp,tmpfs-mode=01777 \
	--mount type=bind,source=$(CURDIR)/hugo.yaml,target=/src/hugo.yaml,readonly

# Fast NONBLOCKING IO to stdout caused by Hugo module operations can
# cause Netlify builds to terminate unexpectedly. This forces stdout to block.
BLOCK_STDOUT_CMD	:= python -c "import os,sys,fcntl; \
					flags = fcntl.fcntl(sys.stdout, fcntl.F_GETFL); \
					fcntl.fcntl(sys.stdout, fcntl.F_SETFL, flags&~os.O_NONBLOCK);"

.DEFAULT_GOAL	:= help

.PHONY: targets container-targets
targets: help modules-get render server clean clean-all production-build preview-build
container-targets: container-image container-push container-modules-get container-render container-server

help: ## Show this help text.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

dependencies:
	npm ci

modules-get: ## Pulls latest Hugo module content.
	hugo mod get -u
	hugo mod tidy

modules-tidy: ## Clean and tidy Hugo modules.
	hugo mod tidy

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
	$(CONTAINER_ENGINE) build . -t $(CONTAINER_IMAGE) --label git_commit=$(COMMIT) --build-arg HUGO_VERSION=$(HUGO_VERSION) --build-arg GO_VERSION=$(GO_VERSION)

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
		--build-arg GO_VERSION=$(GO_VERSION) \
		--tag $(CONTAINER_IMAGE) \
		-f Dockerfile.cross .
	$(DOCKER_BUILDX) stop image-builder
	rm Dockerfile.cross

docker-gen-content:
	@echo -e "**** The use of docker-gen-content is deprecated. Use container-gen-content instead. ****" 1>&2
	$(MAKE) container-modules-get

container-modules-get: ## Pulls latest Hugo module content within a container.
	$(CONTAINER_RUN) -e GOMODCACHE=/tmp/gomod $(CONTAINER_IMAGE) hugo mod get -u

docker-render:
	@echo -e "**** The use of docker-render is deprecated. Use container-render instead. ****" 1>&2
	$(MAKE) container-render

container-render: ## Build the site using Hugo within a container (equiv to render).
	$(CONTAINER_RUN_TTY) $(CONTAINER_HUGO_MOUNTS) -e GOMODCACHE=/tmp/gomod $(CONTAINER_IMAGE) hugo --noBuildLock --logLevel info --ignoreCache --minify

docker-server:
	@echo -e "**** The use of docker-server is deprecated. Use container-server instead. ****" 1>&2
	$(MAKE) container-server

container-server: ## Run Hugo locally within a container, available at http://localhost:1313/
	# no build lock to allow for read-only mounts
	$(CONTAINER_RUN_TTY) -p 1313:1313 \
		$(CONTAINER_HUGO_MOUNTS) \
		--cap-drop=ALL \
		--cap-drop=AUDIT_WRITE \
		-e GOMODCACHE=/tmp/gomod \
		$(CONTAINER_IMAGE) \
	bash -c 'cd /src && hugo mod get -u && \
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
	rm -rf public/ resources/ _tmp/

clean-all: ## Cleans both build artifacts and Hugo cache.
	rm -rf public/ resources/ _tmp/
	hugo mod clean

production-build: ## Builds the production site (this command used only by Netlify).
	$(BLOCK_STDOUT_CMD)
	hugo \
		--environment production \
		--logLevel info \
		--ignoreCache \
		--minify

preview-build: ## Builds a deploy preview of the site (this command used only by Netlify).
	$(BLOCK_STDOUT_CMD)
	hugo \
		--environment preview \
		--logLevel info \
		--baseURL $(DEPLOY_PRIME_URL) \
		--buildDrafts \
		--buildFuture \
		--ignoreCache \
		--minify
