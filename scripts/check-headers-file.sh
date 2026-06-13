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

if [ "${HUGO_ENV}" = "production" ]; then
  echo "INFO: Production environment. Checking the _headers file for noindex headers."

  if [ ! -f public/_headers ]; then
    echo "INFO: No _headers file found in public/. Skipping check."
    exit 0
  fi

  if grep -q "noindex" public/_headers; then
    echo "PANIC: noindex headers were found in the _headers file. This build has failed."
    exit 1
  else
    echo "INFO: noindex headers were not found in the _headers file. All clear."
    exit 0
  fi
else
  echo "Non-production environment. Skipping the _headers file check."
  exit 0
fi
