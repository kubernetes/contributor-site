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

CONTAINER_ENGINE	?= docker
CONTAINER_RUN		:= $(CONTAINER_ENGINE) run --rm -it -v $(CURDIR):/src
HUGO_VERSION		:= $(shell grep ^HUGO_VERSION netlify.toml | tail -n 1 | cut -d '=' -f 2 | tr -d " \"\n")
CONTAINER_IMAGE		:= k8s-contrib-site-hugo
REPO_ROOT	:=${CURDIR}

# Fast NONBlOCKING IO to stdout caused by the hack/gen-content.sh script can
# cause Netlify builds to terminate unexpectantly. This forces stdout to block.
BLOCK_STDOUT_CMD	:= python -c "import os,sys,fcntl; \
					flags = fcntl.fcntl(sys.stdout, fcntl.F_GETFL); \
					fcntl.fcntl(sys.stdout, fcntl.F_SETFL, flags&~os.O_NONBLOCK);"

.DEFAULT_GOAL	:= help

.PHONY: targets container-targets
targets: help gen-content render serve clean clean-all sproduction preview-build
container-targets: container-image container-gen-content container-render container-server

help: ## Show this help text.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

gen-content: ## Generates content from external sources.
	hack/gen-content.sh

render: ## Build the site using Hugo on the host.
	git submodule update --init --recursive --depth 1
	hugo --verbose --ignoreCache --minify

server: ## Run Hugo locally (if Hugo "extended" is installed locally)
	git submodule update --init --recursive --depth 1
	hugo server \
		--verbose \
		--buildDrafts \
		--buildFuture \
		--disableFastRender \
		--ignoreCache

docker-image: container-image
	@echo -e "**** The use of docker-image is deprecated. Use container-image instead. ****" 1>&2

container-image: ## Build container image for use with container-* targets.
	$(CONTAINER_ENGINE) build . -t $(CONTAINER_IMAGE) --build-arg HUGO_VERSION=$(HUGO_VERSION)

docker-gen-content:
	@echo -e "**** The use of docker-gen-content is deprecated. Use container-gen-content instead. ****" 1>&2
	$(MAKE) container-gen-content

container-gen-content: ## Generates content from external sources within a container (equiv to gen-content).
	$(CONTAINER_RUN) $(CONTAINER_IMAGE) hack/gen-content.sh

docker-render:
	@echo -e "**** The use of docker-render is deprecated. Use container-render instead. ****" 1>&2
	$(MAKE) container-render

container-render: ## Build the site using Hugo within a container (equiv to render).
	git submodule update --init --recursive --depth 1
	$(CONTAINER_RUN) $(CONTAINER_IMAGE) hugo --verbose --ignoreCache --minify

docker-server:
	@echo -e "**** The use of docker-server is deprecated. Use container-server instead. ****" 1>&2
	$(MAKE) container-server

container-server: ## Run Hugo locally within a container, available at http://localhost:1313/
	git submodule update --init --recursive --depth 1
	$(CONTAINER_RUN) -p 1313:1313 \
		--mount type=tmpfs,destination=/tmp,tmpfs-mode=01777 \
		$(CONTAINER_IMAGE) \
	hugo server \
		--verbose \
		--bind 0.0.0.0 \
		--buildDrafts \
		--buildFuture \
		--disableFastRender \
		--ignoreCache \
		--destination /tmp/hugo \
		--cleanDestinationDir

clean: ## Cleans build artifacts.
	rm -rf public/ resources/ _tmp/

clean-all: ## Cleans both build artifacts and files sycned to content directory
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
	git submodule update --init --recursive --depth 1
	hack/gen-content.sh
	hugo \
		--verbose \
		--buildFuture \
		--ignoreCache \
		--minify

preview-build: ## Builds a deploy preview of the site (this command used only by Netlify).
	$(BLOCK_STDOUT_CMD)
	git submodule update --init --recursive --depth 1
	hack/gen-content.sh
	hugo \
		--verbose \
		--baseURL $(DEPLOY_PRIME_URL) \
		--buildDrafts \
		--buildFuture \
		--ignoreCache \
		--minify
