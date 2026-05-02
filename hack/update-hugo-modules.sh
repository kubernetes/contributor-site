#!/usr/bin/env bash

# Copyright 2026 The Kubernetes Authors.
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

set -o errexit
set -o nounset
set -o pipefail

DRY_RUN=${DRY_RUN:-false}
for arg in "$@"; do
  if [[ "$arg" == "--dry-run" ]]; then
    DRY_RUN=true
  fi
done

# 1. Update Hugo modules
# GOMODCACHE is set to a writeable directory in CI
export GOMODCACHE="${GOMODCACHE:-/tmp/gomod}"

make modules-get
make modules-tidy

# 2. Validate the build
echo "Validating the build..."
make production-build

# 3. Check if there are changes
if git diff --quiet go.mod go.sum; then
  echo "No module updates found. Exiting."
  exit 0
fi

if [[ "$DRY_RUN" == "true" ]]; then
  echo "Changes detected in dry-run mode. Validation successful."
  exit 0
fi

# 3. Create a PR using Prow's pr-creator
echo "Changes detected. Creating a PR..."

# pr-creator tool from k8s.io/test-infra is used to create the PR.
# This requires GITHUB_TOKEN_PATH to be set in the environment.
go run k8s.io/test-infra/robots/pr-creator@latest \
  --github-token-path="${GITHUB_TOKEN_PATH}" \
  --org="kubernetes" \
  --repo="contributor-site" \
  --branch="master" \
  --source="automation/update-modules" \
  --title="Update external content modules" \
  --body="This PR updates the Hugo modules to pull the latest content from upstream repositories.

This is an automated update created by Prow. 
**Action Required:** A human reviewer must apply \`/lgtm\` and \`/approve\` for this to merge.

/sig contributor-experience
/kind feature" \
  --commit-message="chore: update external content modules" \
  --label="kind/feature" \
  --label="sig/contributor-experience" \
  --confirm
