#!/usr/bin/env bash

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

# shellcheck disable=SC1117
# see https://github.com/koalaman/shellcheck/wiki/SC1117#retired

set -o errexit
set -o nounset
set -o pipefail

readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P)"
readonly HUGO_BUILD="${HUGO_BUILD:-false}"
readonly KCOMMUNITY_REPO="${KCOMMUNITY_REPO:-"https://github.com/kubernetes/community.git"}"
readonly KCOMMUNITY_SRC_DIR="${KCOMMUNITY_SRC_DIR:-"$DIR/build/community"}"
readonly CONTENT_DIR="$DIR/content"
readonly FRONTMATTER_STRING=$(head -n 1 "$DIR/frontmatter.tmplt")
readonly FRONTMATTER_TMPLT=$(sed -e ':a;N;$!ba;s/\n/\\n/g' "$DIR/frontmatter.tmplt")
readonly KCOMMUNITY_EXCLUDE_LIST="$DIR/kcommunity_exclude.list"


# Initializes content directory. If executing a build (CI) wipe content
# directory to ensure there are no left over artifacts from previous build.
init_content() {
  mkdir -p "$CONTENT_DIR"
  [[ "$HUGO_BUILD" = true ]] && (rm -r "${CONTENT_DIR:?}/"* || true) 
}

# Intializes source repositores in build directory. If executing a build (CI)
# Ensure that it is up to date and in a clean state.
# Args:
# $1 - git repo to be cloned/fetched
# $2 - path to destination directory for cloned repo
init_src() {
  if [[ ! -d "$2" ]]; then
    echo "Cloning $1"
    git clone "$1" "$2"
  elif [[ "$HUGO_BUILD" = true && \
          $(git -C "$2" rev-parse --show-toplevel) == "$2" ]]; then
    echo "Syncing with latest content from master."
    git -C "$2" checkout .
    git -C "$2" pull
  fi
}


# Returns all markdown files within a directory
# Args:
# $1 - Path to directory to search for markdown files
find_md_files() {
  find "$1" -type f -name '*.md' -print0 | sort -z
}


# Expands any relative links with regard to the root or base directory passed.
# Expanding the links before moving to the content dir makes it much easier to
# update them to the correct path later during processing.
# Args:
# $1 - Full path to markdown file to be processed
# $2 - Full file system path to root of cloned git repo
expand_file_paths() {
  local inline_link_matches=()
  local ref_link_matches=()
  local expanded_path=""

  # Additional a-z0-9 section was to ignore some regex's used in design
  # proposals. It's an ugly hack, but will prevent expansion.
  mapfile -t inline_link_matches < \
    <(grep -o -i -P '\[(?!a\-z0\-9).+\]\((?!http|mailto|#|\))\K.+?(?=\))' "$1")

  for match in "${inline_link_matches[@]}"; do
    expanded_path=$(cd "$(dirname "$1")" && \
      realpath "$match" -m --relative-base="$2")
    [[ ${expanded_path:0:1} != "/" ]] && expanded_path="/$expanded_path"
    if [[ "$match" != "$expanded_path" ]]; then
      echo "Expanding Path: File: $1 Original: $match Expanded: $expanded_path"
      sed -i -e "s|]($match)|]($expanded_path)|g" "$1"
    fi
  done

  mapfile -t ref_link_matches < \
    <(grep -o -i -P '^\[.+\]\:\s*(?!http|mailto|#|\))\K.+$' "$1")

  for match in "${inline_link_matches[@]}"; do
    expanded_path=$(cd "$(dirname "$1")" && \
      realpath "$match" -m --relative-base="$2")
    [[ ${expanded_path:0:1} != '/' ]] && expanded_path="/$expanded_path"
    if [[ "$match" != "$expanded_path" ]]; then
      echo "Expanding Path: File: $1 Original: $match Expanded: $expanded_path"
      sed -i -e "s|]:\s*$match|]: $expanded_path|g" "$1"
    fi
  done
}


# Trims or replaces URLS with their relative link counterpart. This 'fixes'
# links that would direct the use back to the github repo directly and instead
# replaces it with the relative url for the contributor site.
# Args:
# $1 - Full path to markdown
# $2 - URL to 'trim'
trim_repo_url() {
  local inline_link_matches=()
  local ref_link_matches=()

  mapfile -t inline_link_matches < <(grep -o -P "\[.+\]\($2\K.+?(?=\))" "$1")

  for match in "${inline_link_matches[@]}"; do
    echo "Trimming URL: File: $1 Original: $2$match New: $match"
    sed -i -e "s|]($2$match)|]($match)|g" "$1"
  done

  mapfile -t ref_link_matches < <(grep -o -P "^\[.+\]\:\s*$2\K.+$" "$1")

  for match in "${ref_link_matches[@]}"; do
    echo "Trimming URL: File: $1 Original: $2$1 New: $match"
    sed -i -e "s|]:\s*$2$match|]: $match|g" "$1"
  done
}


# Injects or updates the frontmatter of a the markdown file with 2 attributes:
# title, and original_url. The original_url attribute is added by concating
# the repo url (or friendly url) with the relative path to the markdown file
# in the context of the cloned repo. This is  done to the files before they are
# moved to the content dir as some of their locations change and any sort of 
# generated url from that context would be innacurate.
# Args:
# $1 - Full path to markdown file to be updated
# $2 - Full file system path to root of cloned git repo
# $3 - Repo URL to be prepended to file location (e.g. https://git.k8s.io/community) 
update_frontmatter_metadata() {
  local original_path=""
  if [[ $(head -n 1 "$1") != "$FRONTMATTER_STRING" ]]; then
    echo "Injecting Front Matter Header in $1" 
    sed -i -e "1i$FRONTMATTER_TMPLT" "$1"
  else
    sed -n "/^$FRONTMATTER_STRING/,/^$FRONTMATTER_STRING/p" "$1" | \
      grep -i -q '^title:\s*' || \
       (sed -i -e '2ititle: ' "$1" && \
        echo "Adding title attribute: File: $1")

    sed -n "/^$FRONTMATTER_STRING/,/^$FRONTMATTER_STRING/p" "$1" | \
      grep -i -q "^original_url:\s*" || \
       (sed -i -e '2ioriginal_url: ' "$1" && \
        echo "Adding original_url attribute: File: $1")
  fi

  original_path="$(realpath --relative-to="$2" "$1")"
  [[ "${original_path:0:1}" != '/' ]] && original_path="/$original_path"
  
  grep -q "^original_url: $3$original_path" "$1" || \
    (sed -i -e "s|^original_url:\s*|original_url: $3$original_path|g" "$1" && \
     echo "Updated original_url attribute: File: $1 original_url: $3$original_path")
}


# Syncs kcommunity content to content dir. 
sync_kcommunity_content() {

  # Governance Content
  mkdir -p "$CONTENT_DIR/governance/steering-committee"
  mkdir -p "$CONTENT_DIR/governance/cocc"

  rsync -av --exclude-from="$KCOMMUNITY_EXCLUDE_LIST" \
    "$KCOMMUNITY_SRC_DIR/committee-steering/" \
    "$CONTENT_DIR/governance/steering-committee"

  rsync -av --exclude-from="$KCOMMUNITY_EXCLUDE_LIST" \
    "$KCOMMUNITY_SRC_DIR/committee-code-of-conduct/" \
    "$CONTENT_DIR/governance/cocc"

  rsync -av --exclude-from="$KCOMMUNITY_EXCLUDE_LIST" \
    "$KCOMMUNITY_SRC_DIR/github-management" \
    "$CONTENT_DIR/governance"
  
  cp "$KCOMMUNITY_SRC_DIR/governance.md" "$CONTENT_DIR/governance/README.md"
  cp "$KCOMMUNITY_SRC_DIR/sig-governance.md" "$CONTENT_DIR/governance/"
  cp "$KCOMMUNITY_SRC_DIR/community-membership.md" "$CONTENT_DIR/governance/"

 # SIG Content
  mkdir -p "$CONTENT_DIR/sigs"
  find "$KCOMMUNITY_SRC_DIR" -type d -name "sig-*" -maxdepth 1 -exec \
    rsync -av --exclude-from="$KCOMMUNITY_EXCLUDE_LIST" "{}" "$CONTENT_DIR/sigs/" \;
  
  find "$KCOMMUNITY_SRC_DIR" -type d -name "wg-*" -maxdepth 1 -exec \
    rsync -av --exclude-from="$KCOMMUNITY_EXCLUDE_LIST" "{}" "$CONTENT_DIR/sigs/" \;

  cp "$KCOMMUNITY_SRC_DIR/sig-list.md" "$CONTENT_DIR/sigs/README.md"

  # Other Content
  find "$KCOMMUNITY_SRC_DIR" ! -path "$KCOMMUNITY_SRC_DIR" -type d  \
    -maxdepth 1 -exec rsync -av --exclude-from="$KCOMMUNITY_EXCLUDE_LIST" \
    --exclude="/wg-*" \
    --exclude="/sig-*" \
    --exclude="/committee-steering" \
    --exclude="/committee-code-of-conduct" \
    --exclude="github-management" \
    {} "$CONTENT_DIR" \;

  cp "$KCOMMUNITY_SRC_DIR/README.md" "$CONTENT_DIR/README.md"
}


# Corrects the links in the content directory.
update_links() {

  # replace 'README.md' with '/' if the link begins with '/'
  sed -i -E 's|(\[.+\]\(/.+)/README\.md|\1/|Ig' "$1"
  sed -i -E 's|(^\[.+\]:\s*/.*)/README\.md|\1/|g' "$1"

  # replace '.md' with '/' if the link begins with '/'
  sed -i -E 's|(\[.+\]\(/.+)\.md|\1/|Ig' "$1"
  sed -i -E 's|(^\[.+\]:\s*/.*)\.md|\1/|g' "$1"

  # governance links
  sed -i \
      -e 's|](/committee-steering|](/governance/steering-committee|g' \
      -e 's|]:\s*/committee-steering|]: /governance/steering-committee|g' \
      -e 's|](/committee-code-of-conduct|](/governance/cocc|g' \
      -e 's|]:\s*/committee-code-of-conduct|]: /governance/cocc|g' \
      -e 's|](/github-management|](/governance/github-management|g' \
      -e 's|]:\s*/github-management|]: /governance/github-management|g' \
      -e 's|](/governance|](/governance|g' \
      -e 's|]:\s*/governance|]: /governance|g' \
      -e 's|](/sig-governance|](/governance/sig-governance|g' \
      -e 's|]:\s*/sig-governance|]: /governance/sig-governance|g' \
      -e 's|](/community-membership|](/governance/community-membership|g' \
      -e 's|]:\s*/community-membership|]: /governance/community-membership|g' \
      "$1"

  # sig and wg links
  sed -i \
      -e 's|\](/sig-list|](/sigs|Ig' \
      -e 's|\]:\s*/sig-list|]: /sigs|Ig' \
      -e 's|\](/sig-|](/sigs/sig-|Ig' \
      -e 's|\]:\s*/sig-|]: /sigs/sig-|Ig' \
      -e 's|\](/wg-|](/sigs/wg-|Ig' \
      -e 's|\]:\s*/wg-|]: /sigs/wg-|Ig' \
      "$1"

  # Embedding links to images that are not https will trigger a warning due to
  # linking to non secure content from a secure page.
  sed -i -E 's|(!\[.*\]\()http:|\1https:|Ig' "$1"
  sed -i -e 's|src="http:|src="https:|Ig' "$1"
  echo "Links Updated in: $1"
}


# Inserts the page title attribute into the page frontmatter
# Args:
# $1 - full path to file to be updated
insert_page_title() {
  local title=""
  local filename=""
  filename="$(basename "$1")"

  # If its README, assume the title should be that of the parent dir unless
  # it is one of the top level dirs that should have an overrided name. 
  if [[ "${filename,,}" == 'readme.md' || "${filename,,}" == '_index.md' ]]; then
   case "$(dirname "$1")" in
      "$CONTENT_DIR") title="Kubernetes Contributor Community" ;;
      "$CONTENT_DIR/communication") title="How We Communicate" ;;
      "$CONTENT_DIR/governance") title="Governance" ;;
      "$CONTENT_DIR/governance/cocc") title="Code of Conduct Committee" ;;
      "$CONTENT_DIR/governance/github-management") title="GitHub Management" ;;
      "$CONTENT_DIR/keps") title="Enhancement Proposals (KEPs)" ;;
      "$CONTENT_DIR/sigs") title="SIGs and WGs" ;;
      *) title="$(basename "$(dirname "$1")")" ;;
    esac
    echo "Updating index title attribute: File: $1 Title: $title"
    sed -i -e "0,/^title:.*/I{s//title: $title/}" "$1"

  # If in kep subdirectory call gen_kep_title
  elif echo "$1" | grep -i -q "$CONTENT_DIR/keps/"; then
    title="$(gen_kep_title "$1")"
    echo "Updating KEP title attribute: File: $1 Title: $title"
    sed -i -e "0,/^title:.*/I{s//title: $title/}" "$1"
  
  # If the title attribute in the frontmatter block is blank, update it with
  # the name of the file.
  elif sed -n "/^$FRONTMATTER_STRING/,/^$FRONTMATTER_STRING/p" "$1" | \
       grep -i -q '^title:\s*$'; then
    title="${filename%.md}"
    echo "Updating file title attribute: File: $1 Title: $title"
    sed -i -e "0,/^title:.*/I{s//title: $title/}" "$1"
  fi
}


# Not all content within the kep directory has the kep-number metadata
# attribute. However the files do contain the associated kep number in their
# filename. The kep number itself may also contain letters (e.g. kep 1a) so they 
# cannot be sorted numerically without some custom sorting work in hugo. 
# Instead the 'kep number' is used and prepended to the title attribute and 
# sorted alphabetically as the kep number prefix is a 4 character 0 padded
# number and the content should be diplayed in correct order.
# Args:
# $1 - full path to kep md file
gen_kep_title () {
  local filename=""
  local kep_file_prefix=""
  local title=""
  filename="$(basename "$1")"
  kep_file_prefix="$(echo "$filename" | grep -o -i -P '^[a-z0-9]+')"
  title="$(grep -i -m 1 -o -P '^title:\s*\K.+$' "$1" || "${filename%.md}")"
  echo "$kep_file_prefix - $title"
}


# README's are used for each section's 'list' page. As such, they must be
# renamed to _index.md for hugo to use them correctly.
# Args:
# $1 - full path to a README.md file
rename_readme() {
  local filename=""
  filename="$(dirname "$1")/_index.md"
  mv "$1" "$filename"
  echo "Renamed: $1 to $filename"
}

main() {
  init_content
  init_src "$KCOMMUNITY_REPO" "$KCOMMUNITY_SRC_DIR"
  echo "Beginning preprocessing of k/community content."
  while IFS= read -r -d $'\0' file; do
    expand_file_paths "$file" "$KCOMMUNITY_SRC_DIR"
    trim_repo_url "$file" "https://github.com/kubernetes/community/tree/master"
    trim_repo_url "$file" "https://git.k8s.io/community"
    update_frontmatter_metadata "$file" "$KCOMMUNITY_SRC_DIR" "https://git.k8s.io/community"
  done < <(find_md_files "$KCOMMUNITY_SRC_DIR")

  echo "Syncing k/community to content dir."
  sync_kcommunity_content

  while IFS= read -r -d $'\0' file; do
    update_links "$file"
    insert_page_title "$file"
    [[ $(basename "${file,,}") == 'readme.md' ]] && rename_readme "$file"
  done < <(find_md_files "$CONTENT_DIR")

  if [[ "$HUGO_BUILD" = true ]]; then
    echo "Building Site with: hugo --cleanDestinationDir --source \"$DIR\" $*"
    hugo --source "$DIR" "$@"
  fi
}


main "$@"