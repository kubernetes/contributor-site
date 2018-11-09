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


DIR		:= $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
BUILD_DIR	:= $(join $(DIR), build)
CONTENT_DIR	:= $(join $(DIR), content)
DOCKER		?= docker    
DOCKER_IMAGE	:= k8s-contrib-site-hugo
DOCKER_RUN	:= $(DOCKER) run --rm -it -v $(DIR):/src
HUGO_VERSION	:= 0.49.2

.DEFAULT_GOAL	:= help

.PHONY: targets docker-targets
targets: help render serve clean-all clean-build clean-content
docker-targets: docker-image docker-build docker-serve docker-gen-site docker-gen-site-ci

help: ## Show this help text.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

render: ## Build Hugo site.
	hugo

server: ## Start Hugo webserver.
	hugo server --ignoreCache --disableFastRender

gen-site: ## Generate Contributor Site content.
	./gen-site.sh

gen-site-ci: ## Generate Contributor Site content as if called from CI system.
	CI_BUILD=true ./gen-site.sh

docker-image: ## Build container imagefor use with docker-* targets.
	$(DOCKER) build . -t $(DOCKER_IMAGE) --build-arg HUGO_VERSION=$(HUGO_VERSION)

docker-render: ## Build Hugo site executing within a container (equiv to render).
	$(DOCKER_RUN) $(DOCKER_IMAGE) hugo

docker-server: ## Start Hugo webserver executing within a container (equiv to server).
	$(DOCKER_RUN) -p 1313:1313 $(DOCKER_IMAGE) hugo server --watch --bind 0.0.0.0

docker-gen-site: ## Generate Contributor Site content executing within a container (equiv to gen-site).
	$(DOCKER_RUN) $(DOCKER_IMAGE) ./gen-site.sh

docker-gen-site-ci: ## Generate Contributor Site content as if called from CI system (equiv to gen-site-ci).
	$(DOCKER_RUN) -e CI_BUILD=true $(DOCKER_IMAGE) ./gen-site.sh

clean-all: clean-build clean-content clean-docker ## Executes clean-build, clean-content, and clean-docker.

clean-build: ## Cleans build dependnecies.
	[ -d $(BUILD_DIR) ] && rm -rf $(BUILD_DIR)/*

clean-content: ## Cleans generated content.
	[ -d $(CONTENT_DIR) ] && rm -rf $(CONTENT_DIR)/*

clean-docker: ## Removes docker image if found.
	$(DOCKER) rmi $(DOCKER_IMAGE)
