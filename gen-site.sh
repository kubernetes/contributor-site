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

set -o errexit
set -o nounset
set -o pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P)"

# short circuit if requirements cannot be met
[[ ! -f "$DIR/header.tmplt" ]] && echo 'Header Template missing. Exiting.' && exit 1
[[ ! -f "$DIR/exclude.list" ]] && echo 'Exclude list missing. Exiting.' && exit 1

# KCOMMUNITY_ROOT is passed as src dir if executing from k/community context
SRC_DIR="${KCOMMUNITY_ROOT:-"$DIR/build/src"}"
KCOMMUNITY_REPO="${KCOMMUNITY_REPO:-"https://github.com/kubernetes/community.git"}"
CONTENT_DIR="$DIR/content"
HEADER_STRING=$(head -n 1 "$DIR/header.tmplt")
HEADER_TMPLT=$(sed -e ':a;N;$!ba;s/\n/\\n/g' "$DIR/header.tmplt")
EXCLUDE_LIST="$DIR/exclude.list"
HUGO_BUILD=${HUGO_BUILD:-false}

# Ensures top level directory structure and git repo in place
init() {
  mkdir -p "$CONTENT_DIR"
  if [[ ! -d "$SRC_DIR" ]]; then
    echo "Cloning kubernetes/community."
    git clone "$KCOMMUNITY_REPO" "$SRC_DIR"
  fi
}

# syncs content from community repo to content dir
sync_content() {
  echo "Syncing k/community to content dir."

  # Governance Content
  mkdir -p "$CONTENT_DIR/governance/steering-committee"
  mkdir -p "$CONTENT_DIR/governance/cocc"
  rsync -av --exclude-from="$EXCLUDE_LIST" \
    "$SRC_DIR/committee-steering/" "$CONTENT_DIR/governance/steering-committee"
  rsync -av --exclude-from="$EXCLUDE_LIST" \
    "$SRC_DIR/committee-code-of-conduct/" "$CONTENT_DIR/governance/cocc"
  rsync -av --exclude-from="$EXCLUDE_LIST" \
    "$SRC_DIR/github-management" "$CONTENT_DIR/governance"
  cp "$SRC_DIR/governance.md" "$CONTENT_DIR/governance/README.md"
  cp "$SRC_DIR/sig-governance.md" "$CONTENT_DIR/governance/"
  cp "$SRC_DIR/community-membership.md" "$CONTENT_DIR/governance/"

  # SIG Content
  mkdir -p "$CONTENT_DIR/sigs"
  find "$SRC_DIR" -type d -name "sig-*" -maxdepth 1 \
    -exec rsync -av --exclude-from="$EXCLUDE_LIST" "{}" "$CONTENT_DIR/sigs/" \;
  find "$SRC_DIR" -type d -name "wg-*" -maxdepth 1 \
    -exec rsync -av --exclude-from="$EXCLUDE_LIST" "{}" "$CONTENT_DIR/sigs/" \;
  cp "$SRC_DIR/sig-list.md" "$CONTENT_DIR/sigs/README.md"

  # Other Content
  find "$SRC_DIR" ! -path "$SRC_DIR" -type d  -maxdepth 1 \
    -exec rsync -av --exclude-from="$EXCLUDE_LIST" \
    --exclude="/wg-*" \
    --exclude="/sig-*" \
    --exclude="/committee-steering" \
    --exclude="/committee-code-of-conduct" \
    --exclude="github-management" \
    {} "$CONTENT_DIR" \;

  cp "$SRC_DIR/README.md" "$CONTENT_DIR/README.md"
}

# gets all markdown files in content directory
find_md_files() {
  find "$CONTENT_DIR" -type f -name '*.md' -print0
}

# Cleans up formatting of links found in docs
sub_links() {

  # Inserts the correct path if link is made to local README.md.
  # This rule must be executed before any rule that potentially removes or
  # changes a path containing README.md 
  if grep -q -i "(README.md)" "$1"; then
    local dir_path
    dir_path="$(dirname "$1")"
    sed -i -e "s|(README.md)|(${dir_path#"$CONTENT_DIR"}/|Ig" "$1"
  fi

  # Corrects inline link extensions and github references
  sed -i \
      -e 's|https://github\.com/kubernetes/community/blob/master||Ig' \
      -e 's|/README\.md)|/)|Ig' \
      -e 's|/README\.md#|/#|Ig' \
      -e 's|\.md)|/)|Ig' \
      -e 's|\.md#|/#|Ig' \
      "$1"

  # Corrects relative links
  sed -i -E 's|(\[.*\]:.*)/README.md|\1/|Ig' "$1"
  sed -i -E 's|(\[.*\]:.*)\.md|\1/|Ig'  "$1"

  # Corrects sig and wg links
  sed -i \
      -e 's|\](sig-list)|](/sigs/)|Ig' \
      -e 's|\](sig-list/)|(/sigs/)|Ig' \
      -e 's|\](/sig-list/)|](/sigs/)|Ig' \
      -e 's|\](sig-|](/sigs/sig-|Ig' \
      -e 's|\](wg-|](/sigs/wg-|Ig' \
      -e 's|\](../sig-|](/sigs/sig-|Ig' \
      -e 's|\](../wg-|](/sigs/wg-|Ig' \
      "$1"

 # Corrects links to items placed in governance directory
  sed -i \
      -e 's|/committee-steering/|/governance/steering-committee/|Ig' \
      -e 's|]: committee-steering/|]:/governance/steering-committee/|Ig' \
      -e 's|/community-membership/|/governance/community-membership/|Ig' \
      -e 's|]: community-membership/|]: /governance/community-membership/|Ig' \
      -e 's|/committee-code-of-conduct/|governance/cocc/|Ig' \
      -e 's|]: committee-code-of-conduct/|governance/cocc/|Ig' \
      -e 's|/github-management/|/governance/github-management|Ig' \
      -e 's|]: github-management/|/governance/github-management|Ig' \
      "$1"

  # Embedding links to images that are not https will trigger a warning due to
  # linking to non secure content from a secure page.
  sed -i -E 's|(!\[.*\]\()http:|\1https:|Ig' "$1"
  echo "Links Updated in: $1"
}

# inserts header into file
insert_header() {
  local title
  local filename
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
  else
    title="${filename%.md}"
  fi
  sed -i "1i${HEADER_TMPLT//__TITLE__/${title}}" "$1"
  echo "Header inserted into: $1"
}

# Renames readme.md to _index.md
rename_file() {
  local filename
  filename="$(dirname "$1")/_index.md"
  mv "$1" "$filename"
  echo "Renamed: $1 to $filename"
}

main() {
  init
  sync_content
  while IFS= read -r -d $'\0' file; do
    sub_links "$file"
    # insert header if not found
    [[ $(head -n 1 "$file") != "$HEADER_STRING" ]] && insert_header "$file"
    # if its a README, it must be renamed to _index
    [[ $(basename "${file,,}") == 'readme.md' ]] && rename_file "$file"
  done < <(find_md_files)
  echo "Contributor Site Content Generated."
  if [[ "$HUGO_BUILD" = true ]]; then
    echo "Building Site with: hugo --source \"$DIR\" $*"
    hugo --source "$DIR" "$@"
  fi
}

main "$@"
