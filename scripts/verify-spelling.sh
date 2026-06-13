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

TOOL_VERSION="v0.3.4"

LANGUAGE="${1:-en}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "${ROOT}"

# create a temporary directory
TMP_DIR=$(mktemp -d)

# cleanup
exitHandler() (
  rm -rf "${TMP_DIR}"
)
trap exitHandler EXIT

# perform go install in a temp dir
cd "${TMP_DIR}"
GO111MODULE=on GOBIN="${TMP_DIR}" go install "github.com/client9/misspell/cmd/misspell@${TOOL_VERSION}"
export PATH="${TMP_DIR}:${PATH}"
cd "${ROOT}"

# check spelling
RES=0
echo "Checking spelling..."
ERROR_LOG="${TMP_DIR}/errors.log"

skipping_file="${ROOT}/scripts/.spelling_failures"
if [ -f "${skipping_file}" ]; then
  failing_packages=$(sed "s| | -e |g" "${skipping_file}")
  git ls-files -z | grep --null-data "^content/${LANGUAGE}" | grep --null-data -v -e ${failing_packages} | xargs -0 -r misspell > "${ERROR_LOG}"
else
  git ls-files -z | grep --null-data "^content/${LANGUAGE}" | xargs -0 -r misspell > "${ERROR_LOG}"
fi

if [[ -s "${ERROR_LOG}" ]]; then
  sed 's/^/error: /' "${ERROR_LOG}"
  echo "Found spelling errors!" >&2
  RES=1
fi
exit "${RES}"
