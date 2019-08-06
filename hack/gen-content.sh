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

#readonly DEBUG=${DEBUG:-"false"}
readonly DEBUG=${DEBUG:-"true"}
readonly REPO_ROOT="$(git rev-parse --show-toplevel)"
readonly CONTENT_DIR="$REPO_ROOT/content"
readonly TEMP_DIR="$REPO_ROOT/_tmp"

readonly GH_ROOT="${GH_ROOT:-"https://github.com/kubernetes"}"
readonly EXTERNAL_SOURCES="${EXTERNAL_SOURCES:-"$REPO_ROOT/external-sources"}"


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


# $1 - Full path to markdown file to be processed
# $2 - Full file system path to root of cloned git repo
# $3 - srcs array name 
# $4 - dest array name
process_content() {
  local inline_link_matches=()
  local ref_link_matches=()

  mapfile -t inline_link_matches < \
    <(grep -o -i -P '\[(?!a\-z0\-9).+\]\((?!http|https|mailto|#|\))\K\S+?(?=\))' "$1")

 if [[ -v inline_link_matches ]]; then
    for match in "${inline_link_matches[@]}"; do
      local replacement_link=""
      replacement_link="$(expand_path "$1" "$match" "$2")"
      replacement_link=$(gen_link "$replacement_link" "$2" "$3" "$4")
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
      replacement_link="$(expand_path "$1" "$match" "$2")"
      replacement_link=$(gen_link "$replacement_link" "$2" "$3" "$4")
      if [[ "$match" != "$replacement_link" ]]; then
        echo "Replace link: File: $1 Original: $match Replaced: $replacement_link"
        sed -i -e "s|]:\s*$match|]: $replacement_link|g" "$1"
      fi
    done
  fi

}

# Generates (or expands) the full path relative to the root of the directory if
# it is valid path, otherwise return the passed path assuming it in reference
# to something else.
# Args:
# $1 - path to file containing relative link
# $2 - path to be expanded
# $3 - prefix to repo trim from path
expand_path() {
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


# Generates the correct link for the destination location.
# $1 - Link String
# $2 - Full file system path to root of cloned git repo 
# $3 - Array of sources (passed by reference)
# $4 - Array of destinations (passed by reference)

gen_link() {
  local -n glsrcs=$3
  local -n gldsts=$4
  local generated_link=""; generated_link="$1"

  # If it was previously an "external" link but now local to the contributor site
  # update the link to strip the url portion.
  if echo "$generated_link" | grep -q -i -E "[http|https]://(git.k8s.io|(www\.)?github.com/kubernetes)"; then
    local i; i=0
    while (( i < ${glsrcs[@]} )); do
      local repo=""
      local src=""
      repo="$(echo "${glsrcs[i]}" | cut -d '/' -f2)"
      src="${glsrcs[i]#/${repo}}"
      if echo "$generated_link" grep -q -i -E"(/${repo}(/tree/master)?${src}"; then
        generated_link="$src"
        break
      fi
      ((i++))
    done
  fi

  # if the link does not start with http* expand the path for evaluation
  if echo "$generated_link" | grep -q -i -v "^http"; then
    local internal_link; internal_link="false"
    local i; i=0
    while (( i < ${#glsrcs[@]} )); do
      local repo=""
      local src=""
      repo="$(echo "${glsrcs[i]}" | cut -d '/' -f2)"
      src="${glsrcs[i]#/${repo}}"
      if echo "$generated_link" | grep -i -q "^${src}"; then
        generated_link="${generated_link/${src}/${gldsts[i]}}"
        if basename "$generated_link" | grep -i -q 'readme\.md'; then
          # shellcheck disable=SC2001 # prefer sed for native ignorecase
          generated_link="$(echo "$generated_link" | sed -e 's|/readme\.md|/|I')"
          internal_link="true"
          break
        else
          # shellcheck disable=SC2001 # prefer sed for native ignorecase
          generated_link="$(echo "$generated_link" | sed -e 's|\.md||I')"
          internal_link="true"
          break
        fi
      fi
     ((i++))
    done
    if [[ "$internal_link" == "false" ]]; then
      generated_link="https://git.k8s.io/$(basename "$2")${generated_link}"
    fi
  fi

  echo "$generated_link"
}


main() {
  mkdir -p "$TEMP_DIR"

  local repos=()
  local srcs=()
  local dsts=()

  repos=("${EXTERNAL_SOURCES}"/*)

  for repo in "${repos[@]}"; do
    # shellcheck disable=SC2094 # false detection on read/write to $repo at the same time
    while IFS=, read -re src dst; do
      srcs+=("/$(basename "$repo")$(echo "$src" | sed -e 's/^\"//g;s/\"$//g')")
      dsts+=("$(echo "$dst" | sed -e 's/^\"//g;s/\"$//g')")
    done < "$repo"
    init_src "${GH_ROOT}/$(basename "$repo").git" "${TEMP_DIR}/$(basename "$repo")"
  done


  for s in "${srcs[@]}"; do
    local repo=""
    local src=""
    repo="$(echo "${s}" | cut -d '/' -f2)"
    src="${s#/${repo}}"
    while IFS= read -r -d $'\0' file; do
      process_content "$file" "${TEMP_DIR}/${repo}" srcs dsts
      if [[ $(basename "${file,,}") == 'readme.md' ]]; then
        filename=""
        filename="$(dirname "$file")/_index.md"
        mv "$file" "$filename"
        echo "Renamed: $file to $filename"
      fi
    done < <(find_md_files "${TEMP_DIR}${s}")
  done


  echo "Copying to hugo content directory."
  for (( i=0; i < ${#srcs[@]}; i++ )); do
    echo "${TEMP_DIR}${srcs[i]}/* ${CONTENT_DIR}${dsts[i]}"
    rsync -av "${TEMP_DIR}${srcs[i]}/" "${CONTENT_DIR}${dsts[i]}"
  done 
  echo "Content synced."
}


main "$@"
