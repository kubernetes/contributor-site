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

BASE_REF="${1:-main}"
LINT_BLOGS_WARN_ONLY="${LINT_BLOGS_WARN_ONLY:-0}"

CHANGED=$(git diff --name-only "origin/${BASE_REF}...HEAD" -- 'content/*/blog/*.md')

if [ -z "${CHANGED}" ]; then
  echo "No blog files changed."
  exit 0
fi

echo "Linting blog files changed against ${BASE_REF}..."

set +o errexit
OUTPUT=$(echo "${CHANGED}" | xargs markdownlint --config .markdownlint.jsonc 2>&1)
STATUS=$?
set -o errexit

if [ -n "${OUTPUT}" ]; then
  printf '%s\n' "${OUTPUT}"
fi

if [ "${STATUS}" -eq 0 ]; then
  exit 0
fi

if [ "${LINT_BLOGS_WARN_ONLY}" = "1" ]; then
  # markdownlint format: path:line[:column] error RULE message
  while IFS= read -r line; do
    if [[ "${line}" =~ ^([^:]+):([0-9]+)(:[0-9]+)?[[:space:]]+error[[:space:]]+(.+)$ ]]; then
      file="${BASH_REMATCH[1]}"
      lineno="${BASH_REMATCH[2]}"
      msg="${BASH_REMATCH[4]}"
      msg="${msg//'%'/'%25'}"
      msg="${msg//$'\r'/}"
      echo "::warning file=${file},line=${lineno}::${msg}"
    fi
  done <<< "${OUTPUT}"
  echo "Lint findings treated as warnings (LINT_BLOGS_WARN_ONLY=1)."
  exit 0
fi

exit "${STATUS}"
