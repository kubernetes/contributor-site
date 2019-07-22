#!/usr/bin/env bash

# Copyright 2019 The Kubernetes Authors.
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

readonly DEBUG=${DEBUG:-"false"}
readonly REPO_ROOT="$(git rev-parse --show-toplevel)"
readonly CONTENT_DIR="$REPO_ROOT/content"
readonly TEMP_DIR="$REPO_ROOT/_tmp"
readonly KCOMMUNITY_REPO="${KCOMMUNITY_REPO:-"https://github.com/kubernetes/community.git"}"
readonly KCOMMUNITY_SRC_DIR="${KCOMMUNITY_SRC_DIR:-"$TEMP_DIR/community"}"
readonly GUIDE_SRC_DIR="${GUIDE_SRC_DIR:-"/contributors/guide"}"
readonly GUIDE_DST_DIR="${GUIDE_DST_DIR:-"/guide"}"

cd "$REPO_ROOT"

cleanup() {
	rm -rf "$TEMP_DIR"
}

if [[ "$DEBUG" == false ]]; then
  trap cleanup EXIT
fi

# Intializes source repositores in build directory. If executing a build (CI)
# Ensure that it is up to date and in a clean state.
# Args:
# $1 - git repo to be cloned/fetched
# $2 - path to destination directory for cloned repo
init_src() {
  if [[ ! -d "$2" ]]; then
    echo "Cloning $1"
    git clone --depth=1 "$1" "$2"
  elif [[ $(git -C "$2" rev-parse --show-toplevel) == "$2" ]]; then
    echo "Syncing with latest content from master."
    git -C "$2" checkout .
    git -C "$2" pull
  else
    echo "Destination $2 already exists and is not a git repository."
    exit 1
  fi
}

# Returns all markdown files within a directory
# Args:
# $1 - Path to directory to search for markdown files
find_md_files() {
  find "$1" -type f -name '*.md' -print0 | sort -z
}


# Processes files inteneded for Hugo.
# - Expands and updates links to their correct address within the Hugo site
# - Renames any needed files (README.md's) to their appropirate file name.
# Args:
# $1 - Full path to markdown file to be processed
# $2 - Full file system path to root of cloned git repo
# $3 - Path to "root" of desired content in src dir
# $4 - Path to "root" of desired content in dst dir
# $5 - GitHub repo link or friendly domain used for external links  e.g. git.k8s.io/community
process_content() {
  local inline_link_matches=()
  local ref_link_matches=()

  # Additional a-z0-9 section was to ignore some regex's used in design
  # proposals. It's an ugly hack, but will prevent expansion.
  mapfile -t inline_link_matches < \
    <(grep -o -i -P '\[(?!a\-z0\-9).+\]\((?!http|https|mailto|#|\))\K\S+?(?=\))' "$1")

  if [[ -v inline_link_matches ]]; then
    for match in "${inline_link_matches[@]}"; do

      local replacement_link=""
      replacement_link="$(gen_link "$match" "$1" "$2" "$3" "$4" "$5")"

      if [[ "$match" != "$replacement_link" ]]; then
        echo "Replace link: File: $1 Original: $match Replaced: $replacement_link"
        sed -i -e "s|]($match)|]($replacement_link)|g" "$1"
      fi
    done
  fi

  mapfile -t ref_link_matches < \
    <(grep -o -i -P '^\[.+\]:\s*(?!http|https|mailto|#)\K\S+$' "$1")

  if [[ -v ref_link_matches ]]; then
    for match in "${ref_link_matches[@]}"; do

      local replacement_link=""
      replacement_link="$(gen_link "$match" "$1" "$2" "$3" "$4" "$5")"

      if [[ "$match" != "$replacement_link" ]]; then
        echo "Replace link: File: $1 Original: $match Replaced: $replacement_link"
        sed -i -e "s|]:\s*$match|]: $replacement_link|g" "$1"
      fi
    done
  fi

  if [[ $(basename "${1,,}") == 'readme.md' ]]; then
    local filename=""
    filename="$(dirname "$1")/_index.md"
    mv "$1" "$filename"
    echo "Renamed: $1 to $filename"
  fi
}


# Generates the correct link for the destination location. If it is an internal
# link. It expands the path relative to the file and replaces it with the path
# at the destination location. If it is an external link, it will update it with
# the repo or "friendly" domain.
# $1 - Link String
# $2 - Full path to markdown file to be processed
# $3 - Full file system path to root of cloned git repo
# $4 - Path to "root" of desired content in src dir
# $5 - Path to "root" of desired content in dst dir
# $6 - GitHub repo link or friendly domain used for external links  e.g. git.k8s.io/community

gen_link() {
   local generated_link=""

  # if the link does not start with http* expand the path for evaluation
  if echo "$1" | grep -q -i -v "^http"; then
    generated_link="$(expand_link_path "$2" "$match" "$3")"

    # If linking within the same directory or lower, replace the path with
    # destination path. Otherwise gen an external link.
     if echo "$generated_link" | grep -q -i "^${4}"; then
      generated_link="${generated_link/${4}/${5}}"
    else
      generated_link="${6}${generated_link}"
    fi
  fi

  # README's default to the index page and must be fully removed.
  # Internal links must have '.md' stripped from their link for hugo. 
  if echo "$generated_link" | grep -q -i -v '^http'; then
    if basename "$generated_link" | grep -i -q '\/readme\.md'; then
      # shellcheck disable=SC2001 # prefer sed for native ignorecase
      replacement_link="$(echo "$generated_link" | sed -e 's|/readme\.md|/|I')"
    else
      # shellcheck disable=SC2001 # prefer sed for native ignorecase
      replacement_link="$(echo "$generated_link" | sed -e 's|\.md||I')"
    fi
  fi
  echo "$generated_link"
}

# Generates (or expands) the full path relative to the root of the directory if
# it is valid path, otherwise return the passed path assuming it in reference
# to something else.
# Args:
# $1 - path to file containing relative link
# $2 - path to be expanded
# $3 - relative base to trim from path
expand_link_path() {
  local dirpath=""
  local filename=""
  local expanded_path=""
  dirpath="$( (cd "$(dirname "$1")" && readlink -f "$(dirname "$2")") || \
          dirname "$2" )"
  filename="$(basename "$2")"
  [[ "$dirpath" == '.' || "$dirpath" == "/" ]] && dirpath=""
  expanded_path="$dirpath/$filename"
  if echo "$2" | grep -q -P "^\.?\/?$expanded_path"; then
    echo "$expanded_path"
  else
    echo "${expanded_path##"$3"}"
  fi
}


main() {
  mkdir -p "$TEMP_DIR"

  echo "Beginning preprocessing of contributor guide content."
  init_src "$KCOMMUNITY_REPO" "$KCOMMUNITY_SRC_DIR"
  while IFS= read -r -d $'\0' file; do
    process_content "$file" "$KCOMMUNITY_SRC_DIR" "$GUIDE_SRC_DIR" "$GUIDE_DST_DIR" "https://git.k8s.io/community"
  done < <(find_md_files "${KCOMMUNITY_SRC_DIR}${GUIDE_SRC_DIR}")

  echo "Copying to hugo content directory."
  cp -v -r  "${KCOMMUNITY_SRC_DIR}${GUIDE_SRC_DIR}/" "${CONTENT_DIR}${GUIDE_DST_DIR}"

 while IFS= read -r -d $'\0' file; do
   [[ $(basename "${file,,}") == 'readme.md' ]] && rename_readme "$file"
 done < <(find_md_files "${CONTENT_DIR}${GUIDE_DST_DIR}")
 echo "Content synced."
}


main "$@"
