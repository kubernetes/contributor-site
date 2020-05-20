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
readonly CONTENT_DIR="$REPO_ROOT/content/en"
readonly TEMP_DIR="$REPO_ROOT/_tmp"
readonly EXTERNAL_SOURCES="${EXTERNAL_SOURCES:-"$REPO_ROOT/external-sources"}"
readonly HEADER_TMPLT="---\ntitle: __TITLE__\n---\n"


cd "$REPO_ROOT"

cleanup() {
	rm -rf "$TEMP_DIR"
}

if [[ "$DEBUG" == false ]]; then
  trap cleanup EXIT
fi

# init_src
# Intializes source repositores by pulling the latest content. If the repo
# is alread present, fetch the latest content from the master branch.
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

# find_md_files
# Returns all markdown files within a directory
# Args:
# $1 - Path to directory to search for markdown files
find_md_files() {
  find "$1" -type f -name '*.md' -print0 | sort -z
}


# process_content
# Updates the links within a markdown file so that they will resolve within
# the Hugo generated site. If the link is a file reference, it is expanded 
# so the path is from the root of the git repo. The links are then passed
# to gen_link which will determine if the link references content within one
# of the sources being synced to the content directory. If so, update the link
# with the path that it will be after being copied over. This includes removing
# the extension and if the file is a README, trim it (README's function as the 
# root page.) If the link references something not within the content that is
# being copied over, it will be expanded to the full github url.
# Example:
#   Repo: https://github.com/kubernetes/community
#   Content to be synced: /contributors/guide -> /guide
#   Markdown file: /contributors/guide/README.md
#   Links:
#   ./bug-bounty.md -> /guide/bug-bounty
#   contributor-cheatsheet/README.md -> /guide/contributor-cheatsheet
#   ../../sig-list.md -> https://github.com/kubernetes/community/blob/master/sig-list.md
#   /contributors/devel/README.md -> https://github.com/kubernetes/community/blob/master/contributors/devel/README.md
#   http://git.k8s.io/cotributors/guide/collab.md -> /guide/collab
# 
# Args:
# $1 - Full path to markdown file to be processed
# $2 - Full file system path to root of cloned git repo
# $3 - srcs array name 
# $4 - dest array name
process_content() {
  local inline_link_matches=()
  local ref_link_matches=()

  mapfile -t inline_link_matches < \
    <(grep -o -i -P '\[(?!a\-z0\-9).+?\]\((?!mailto|\S+?@|<|>|\?|\!|@|#|\$|%|\^|&|\*|\))\K\S+?(?=\))' "$1")

 if [[ -v inline_link_matches ]]; then
    for match in "${inline_link_matches[@]}"; do
      local replacement_link=""
      if echo "$match" | grep -i -q "^http"; then
        replacement_link="$match"
      else
        replacement_link="$(expand_path "$1" "$match" "$2")"
      fi
      replacement_link=$(gen_link "$replacement_link" "$2" "$3" "$4")
      if [[ "$match" != "$replacement_link" ]]; then
        echo "Update link: File: $1 Original: $match Updated: $replacement_link"
        sed -i -e "s|]($match)|]($replacement_link)|g" "$1"
      fi
    done
  fi

  mapfile -t ref_link_matches < \
    <(grep -o -i -P '^\[.+\]:\s*(?!mailto|\S+?@|<|>|\?|\!|@|#|\$|%|\^|&|\*)\K\S+$' "$1")

  if [[ -v ref_link_matches ]]; then
    for match in "${ref_link_matches[@]}"; do
      local replacement_link=""
      if echo "$match" | grep -i -q "^http"; then
        replacement_link="$match"
      else
        replacement_link="$(expand_path "$1" "$match" "$2")"
      fi
      replacement_link=$(gen_link "$replacement_link" "$2" "$3" "$4")
      if [[ "$match" != "$replacement_link" ]]; then
        echo "Update link: File: $1 Original: $match Updated: $replacement_link"
        sed -i -e "s|]:\s*$match|]: $replacement_link|g" "$1"
      fi
    done
  fi

  if [[ $(head -n 1 "$1") != "---" ]]; then
    insert_header "$1"
  fi
}

# expand_paths
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

# gen_link
# Generates the correct link for the destination location. If it is a url that
# references content that will be synced, convert it to a path.
# $1 - Link String
# $2 - Full file system path to root of cloned git repo 
# $3 - Array of sources (passed by reference)
# $4 - Array of destinations (passed by reference)
gen_link() {
  local -n glsrcs=$3
  local -n gldsts=$4
  local generated_link=""; generated_link="$1"

  # If it was previously an "external" link but now local to the contributor site
  # update the link by trimming the url portion.
  # TODO: Improve support for handling additional external repos.
  # Detection is a problem for non kubernetes orgs. New org names must be
  # appended for generation of correct url rewrites. It may need to be further
  # updated if the external org/repo uses their own domain shortener similar to
  # git.k8s.io.
  if echo "$generated_link" | grep -q -i -E "https?:\/\/((sigs|git)\.k8s\.io|(www\.)?github\.com\/(kubernetes(-(client|csi|incubator|sigs))?|cncf))"; then
    local i; i=0
    while (( i < ${#glsrcs[@]} )); do
      local repo=""
      local src=""
      repo="$(echo "${glsrcs[i]}" | cut -d '/' -f2)/$(echo "${glsrcs[i]}" | cut -d '/' -f3)"
      src="${glsrcs[i]#/${repo}}"
      if echo "$generated_link" | grep -q -i -E "/${repo}(/(blob|tree)/master)?${src}"; then
        generated_link="$src"
        break
      fi
      ((i++))
    done
  fi

  # If the link's path matches against one of the source locations, update it
  # to use the matching destination path. If no match is found, expand to
  # a full github.com/$org/$repo address
  if echo "$generated_link" | grep -q -i -v "^http"; then
    local internal_link; internal_link="false"
    local i; i=0
    while (( i < ${#glsrcs[@]} )); do
      local repo=""
      local src=""
      repo="$(echo "${glsrcs[i]}" | cut -d '/' -f2)/$(echo "${glsrcs[i]}" | cut -d '/' -f3)"
      src="${glsrcs[i]#/${repo}}"
      if echo "$generated_link" | grep -i -q "^${src}"; then
        generated_link="${generated_link/${src}/${gldsts[i]}}"
        if basename "$generated_link" | grep -i -q 'readme\.md'; then
          # shellcheck disable=SC2001 # prefer sed for native ignorecase
          generated_link="$(echo "$generated_link" | sed -e 's|/readme\.md|/|I')"
          internal_link="true"
          break
        # If the destination is intended to be the root for a directory and the
        # source was not a README, set the generated link to the "root" of the
        # destination.
        elif basename "$generated_link" | grep -i -q '_index.md'; then
          generated_link="$(dirname "${gldsts[i]}")"
          internal_link="true"
          break
        else
          # shellcheck disable=SC2001 # prefer sed for native ignorecase
          generated_link="$(echo "$generated_link" | sed -e 's|\.md||I')"
          internal_link="true"
          break
        fi
      # This catches the condition if the link to be expanded did not link
      # to a file directly (a README), but should when copied over. By default
      # GitHub will display the README in a directory if no file is specified.
      # This updates those types of links to reference the destination file
      # path.
      elif basename "$generated_link" | grep -q -v -i -E ".+\..+" && \
           basename "$src" | grep -q -i "^readme\.md" && \
           [[ "$generated_link" == $(dirname "$src") ]]; then
        # shellcheck disable=SC2001 # prefer sed for native ignorecase
        generated_link="$(echo "${gldsts[i]}" | sed -e 's|\.md||I')"
        internal_link="true"
      fi
     ((i++))
    done
    if [[ "$internal_link" == "false" ]]; then
      local org
      org="$(echo "$2" | rev | cut -d '/' -f2 | rev)" # reverse the string to trim from the "right"
      generated_link="https://github.com/$org/$(basename "$2")/blob/master${generated_link}"
    fi
  fi

  echo "$generated_link"
}

# insert_header
# Inserts the base hugo header needed to render a page correctly. This should
# only be called if -no- header is already detected.
# $1 - The full path to the markdown file.
insert_header() {
  local title
  local filename
  filename="$(basename "$1")"
  # If its README, assume the title should be that of the parent dir.
  # Otherwise use the name of the file.
  if [[ "${filename,,}" == 'readme.md' || "${filename,,}" == '_index.md' ]]; then
    title="$(basename "$(dirname "$1")")"
  else
    title="${filename%.md}"
  fi
  title="$(echo "${title//[-|_]/ }" | sed -r 's/\<./\U&/g')"
  sed -i "1i${HEADER_TMPLT//__TITLE__/$title}" "$1"
  echo "Header inserted into: $1"
}


main() {
  mkdir -p "$TEMP_DIR"

  local repos=() # array of kubernetes repos containing content to be synced
  local srcs=() # array of sources of content to be synced 
  local dsts=() # array of destinations for the content to be synced to

  # Files within the EXTERNAL_SOURCES directory should be csv formatted with the
  # directory being the GitHub org and name of the file being the repo name
  # (e.g. kubernetes/community), and the  content being the path to the content
  # to be synced within the repo to the to the destination within the HUGO
  # content directory.
  # Example:
  # file-path: external-sources/kubernetes/community
  # "/contributors/guide", "/guide" 

  shopt -s globstar
  for repo in "${EXTERNAL_SOURCES}"/**; do
    if [[ -f "$repo" ]]; then
      repos+=("$repo")
    fi
  done
  shopt -u globstar

  # populate the arrays with information parsed from files in ${EXTERNAL_SOURCES}
  for repo in "${repos[@]}"; do
    local org
    org="$(basename "$(dirname "$repo")")"
    # shellcheck disable=SC2094 # false detection on read/write to $repo at the same time
    while IFS=, read -re src dst || [ -n "$src" ]; do
      srcs+=("/$org/$(basename "$repo")$(echo "$src" | sed -e 's/^\"//g;s/\"$//g')")
      dsts+=("$(echo "$dst" | sed -e 's/^\"//g;s/\"$//g')")
    done < "$repo"
    init_src "https://github.com/$org/$(basename "$repo").git" "${TEMP_DIR}/$org/$(basename "$repo")"
  done

  # Duplicate of the srcs array used to reference the file paths of the source
  # files as some file names may be changed in place to be copied over correctly.
  # The original src array cannot be used as it would break link generation. This
  # is because the src paths are used to determine if the content is "internal"
  # or "external" before link generation.
  renamed_srcs=("${srcs[@]}")
  for ((i=0; i<${#srcs[@]};i++)); do
    local repo=""
    local src=""
    repo="$(echo "${srcs[i]}" | cut -d '/' -f2)/$(echo "${srcs[i]}" | cut -d '/' -f3)"
    src="${srcs[i]#/${repo}}"
    while IFS= read -r -d $'\0' file; do
      process_content "$file" "${TEMP_DIR}/${repo}" srcs dsts
      # if the source file is a readme, or the destination is a singular file it
      # should be evaluated and if needed renamed.
      if [[ $(basename "${file,,}") == 'readme.md' ]] \
          || echo "${dsts[i]}" | grep -q "\.md$"; then
        filename=""
        # if file is a readme and the destination is NOT a file, assume it is
        # the "root" of a directory.
        if [[ $(basename "${file,,}") == 'readme.md' ]] \
            && echo "${dsts[i]}" | grep -v -q "\.md$" ; then
          filename="$(dirname "$file")/_index.md"
        else
          # If not a readme, assume its a singular file that should be moved.
          # Because it is renamed in place before syncing, the renamed_srcs array
          # is updated to reflect its rename, leaving the srcs array untouched
          # for use in passing to the process_content function.
          filename="$(dirname "$file")/$(basename "${dsts[i]}")"
          renamed_srcs[i]="$(dirname "${srcs[i]}")/$(basename "${dsts[i]}")"
        fi
        # checks if both the source and destination would be the same. If so
        # skip updating.
        if [[ "$file" != "$filename" ]]; then
          mv "$file" "$filename"
          echo "Renamed: $file to $filename"
        fi
      fi
    done < <(find_md_files "${TEMP_DIR}${srcs[i]}")
  done


  echo "Copying to hugo content directory."
  for (( i=0; i < ${#renamed_srcs[@]}; i++ )); do
    if [[ -d "${TEMP_DIR}${renamed_srcs[i]}" ]]; then
      # OWNERS files are excluded when copied to prevent potential overwriting of desired
      # owner config.
      rsync -av "${TEMP_DIR}${renamed_srcs[i]}/" "${CONTENT_DIR}${dsts[i]}" --exclude "OWNERS"
    elif [[ -f "${TEMP_DIR}${renamed_srcs[i]}" ]]; then
      rsync -av "${TEMP_DIR}${renamed_srcs[i]}" "${CONTENT_DIR}${dsts[i]}" --exclude "OWNERS"
    fi
  done 
  echo "Content synced."
}


main "$@"
