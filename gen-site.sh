#!/usr/bin/env bash

set -e
set -o pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P)"

# short circuit if requirements cannot be met
[[ ! -f "$DIR/header.tmplt" ]] && echo 'Header Template missing. Exiting.' && exit 1
[[ ! -f "$DIR/exclude.list" ]] && echo 'Exclude list missing. Exiting.' && exit 1
[[ ! -f "$DIR/include.list" ]] && echo 'Include list missing. Exiting.' && exit 1

# KCOMMUNITY_ROOT is passed as src dir if executing from k/community context
SRC_DIR="${KCOMMUNITY_ROOT:-"$DIR/build/src"}"
KCOMMUNITY_REPO="${KCOMMUNITY_REPO:-"https://github.com/kubernetes/community.git"}"
CONTENT_DIR="$DIR/content"
HEADER_STRING=$(head -n 1 "$DIR/header.tmplt")
HEADER_TMPLT=$(sed -e ':a;N;$!ba;s/\n/\\n/g' "$DIR/header.tmplt")
EXCLUDE_LIST="$DIR/exclude.list"
INCLUDE_LIST="$DIR/include.list"
HUGO_BUILD=${HUGO_BUILD:-false}

# ensures directory structure and git repo in place
init() {
  mkdir -p "$CONTENT_DIR"
  if [[ ! -d "$SRC_DIR" ]]; then
    echo "Cloning k/community."
    git clone "$KCOMMUNITY_REPO" "$SRC_DIR"
  fi
}

# syncs content from community repo to content dir
sync_content() {
  echo "Syncing k/community to content dir."
  mkdir -p "$CONTENT_DIR/special-interest-groups"
  mkdir -p "$CONTENT_DIR/working-groups"
  find "$SRC_DIR" -type d -name "sig-*" -maxdepth 1 \
    -exec rsync -av --exclude-from="$EXCLUDE_LIST" "{}" "$CONTENT_DIR/special-interest-groups/" \;
  find "$SRC_DIR" -type d -name "wg-*" -maxdepth 1 \
    -exec rsync -av --exclude-from="$EXCLUDE_LIST" "{}" "$CONTENT_DIR/working-groups/" \;
  find "$SRC_DIR" ! -path "$SRC_DIR" -type d  -maxdepth 1 \
    -exec rsync -av --exclude-from="$EXCLUDE_LIST" --exclude="/wg-*" --exclude="/sig-*" {} "$CONTENT_DIR" \;
  rsync -av --include-from="$INCLUDE_LIST" --exclude="*" "$SRC_DIR/" "$CONTENT_DIR"
  cp "$SRC_DIR/sig-list.md" "$CONTENT_DIR/special-interest-groups/README.md"
  cp "$SRC_DIR/sig-list.md" "$CONTENT_DIR/working-groups/README.md"
  cp "$SRC_DIR/README.md" "$CONTENT_DIR/README.md"
}

# gets all markdown files in content directory
find_md_files() {
  find "$CONTENT_DIR" -type f -name '*.md' -print0
}

# Cleans up formatting of links found in docs
sub_links() {
  sed -i \
      -e 's|https://github\.com/kubernetes/community/blob/master||Ig' \
      -e 's|README\.md)|)|Ig' \
      -e 's|README\.md#|#|Ig' \
      -e 's|\.md)|)|Ig' \
      -e 's|\.md#|#|Ig' \
      -e 's|\](sig-|](/special-interest-groups/sig-|Ig' \
      -e 's|\](wg-|](/working-groups/wg-|Ig' \
      -e 's|\](../sig-|](/special-interest-groups/sig-|Ig' \
      -e 's|\](../wg-|](/working-groups/wg-|Ig' \
      "$1"
  echo "Links Updated in: $1"
}

# inserts header into file
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
  sed -i "1i${HEADER_TMPLT//__TITLE__/$title}" "$1"
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
    # short circult early if already 
    [[ $(head -n 1 "$file") == "$HEADER_STRING" ]] && continue
    sub_links "$file"
    insert_header "$file"
    # if its a README, it must be renamed to _index
    [[ $(basename "${file,,}") == 'readme.md' ]] && rename_file "$file"
  done < <(find_md_files)
  echo "Community Site Content Generated."
  if [[ "$HUGO_BUILD" = true ]]; then
    echo "Building Site with: hugo --source \"$DIR\" $*"
    hugo --source "$DIR" "$@"
  fi
}

main "$@"
