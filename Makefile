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
IMAGE_VERSION			:= $(shell git rev-parse --short HEAD)
CONTAINER_RUN			:= $(CONTAINER_ENGINE) run --rm -it -v "$(CURDIR):/src"
CONTAINER_RUN_TTY		:= $(CONTAINER_ENGINE) run --rm -it
HUGO_VERSION			:= $(shell grep ^HUGO_VERSION netlify.toml | tail -n 1 | cut -d '=' -f 2 | tr -d " \"\n")
GIT_TAG					?= v$(HUGO_VERSION)-$(IMAGE_VERSION)
CONTAINER_IMAGE			:= $(IMAGE_REPO):$(GIT_TAG)

CONTAINER_HUGO_MOUNTS = \
	--read-only \
	--mount type=bind,source=$(CURDIR)/.git,target=/src/.git,readonly \
	--mount type=bind,source=$(CURDIR)/assets,target=/src/assets,readonly \
	--mount type=bind,source=$(CURDIR)/content,target=/src/content,readonly \
	--mount type=bind,source=$(CURDIR)/external-sources,target=/src/external-sources,readonly \
	--mount type=bind,source=$(CURDIR)/hack,target=/src/hack,readonly \
	--mount type=bind,source=$(CURDIR)/layouts,target=/src/layouts,readonly \
	--mount type=bind,source=$(CURDIR)/static,target=/src/static,readonly \
	--mount type=tmpfs,destination=/tmp,tmpfs-mode=01777 \
	--mount type=bind,source=$(CURDIR)/hugo.yaml,target=/src/hugo.yaml,readonly

# Fast NONBLOCKING IO to stdout caused by the hack/gen-content.sh script can
# cause Netlify builds to terminate unexpectedly. This forces stdout to block.
BLOCK_STDOUT_CMD	:= python -c "import os,sys,fcntl; \
					flags = fcntl.fcntl(sys.stdout, fcntl.F_GETFL); \
					fcntl.fcntl(sys.stdout, fcntl.F_SETFL, flags&~os.O_NONBLOCK);"

.DEFAULT_GOAL	:= help

.PHONY: targets container-targets
targets: help gen-content render server clean clean-all production-build preview-build
container-targets: container-image container-push container-gen-content container-render container-server

help: ## Show this help text.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

dependencies:
	npm ci

gen-content: ## Generates content from external sources.
	hack/gen-content.sh

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
	$(CONTAINER_ENGINE) build . -t $(CONTAINER_IMAGE) --build-arg HUGO_VERSION=$(HUGO_VERSION)

container-push: container-image ## Push container image for the preview of the website
	$(CONTAINER_ENGINE) push $(CONTAINER_IMAGE)

docker-gen-content:
	@echo -e "**** The use of docker-gen-content is deprecated. Use container-gen-content instead. ****" 1>&2
	$(MAKE) container-gen-content

container-gen-content: ## Generates content from external sources within a container (equiv to gen-content).
	$(CONTAINER_RUN) $(CONTAINER_IMAGE) hack/gen-content.sh

docker-render:
	@echo -e "**** The use of docker-render is deprecated. Use container-render instead. ****" 1>&2
	$(MAKE) container-render

container-render: ## Build the site using Hugo within a container (equiv to render).
	$(CONTAINER_RUN_TTY) $(CONTAINER_HUGO_MOUNTS) $(CONTAINER_IMAGE) hugo --logLevel info --ignoreCache --minify

docker-server:
	@echo -e "**** The use of docker-server is deprecated. Use container-server instead. ****" 1>&2
	$(MAKE) container-server

container-server: ## Run Hugo locally within a container, available at http://localhost:1313/
	# no build lock to allow for read-only mounts
	$(CONTAINER_RUN_TTY) -p 1313:1313 \
		$(CONTAINER_HUGO_MOUNTS) \
		--cap-drop=ALL \
		--cap-drop=AUDIT_WRITE \
		$(CONTAINER_IMAGE) \
	bash -c 'cd /src && hack/gen-content.sh --in-container && \
		 cd /tmp/src && \
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

clean-all: ## Cleans both build artifacts and files synced to content directory
	rm -rf public/ resources/ _tmp/
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

production-build: ## Builds the production site (this command used only by Netlify).
	$(BLOCK_STDOUT_CMD)
	hack/gen-content.sh
	hugo \
		--environment production \
		--logLevel info \
		--ignoreCache \
		--minify

preview-build: ## Builds a deploy preview of the site (this command used only by Netlify).
	$(BLOCK_STDOUT_CMD)
	hack/gen-content.sh
	hugo \
		--environment preview \
		--logLevel info \
		--baseURL $(DEPLOY_PRIME_URL) \
		--buildDrafts \
		--buildFuture \
		--ignoreCache \
		--minify
