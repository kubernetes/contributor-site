#!/usr/bin/env python3

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

"""Fails if any image under content/en is missing alt text."""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTENT_DIR = os.path.join(ROOT, "content", "en")

CODE_FENCE_RE = re.compile(r"```.*?```", re.DOTALL)
INLINE_CODE_RE = re.compile(r"`[^`\n]*`")
MARKDOWN_IMAGE_RE = re.compile(r"!\[([^\]]*)\]\(([^)]+)\)")
HTML_IMAGE_RE = re.compile(r"<img\b[^>]*>", re.DOTALL)
ALT_ATTR_RE = re.compile(r"""\balt\s*=\s*(["']).*?\1""", re.DOTALL)


def find_markdown_files(directory):
    for dirpath, _, filenames in os.walk(directory):
        for filename in filenames:
            if filename.endswith(".md"):
                yield os.path.join(dirpath, filename)


def strip_code(content):
    content = CODE_FENCE_RE.sub("", content)
    content = INLINE_CODE_RE.sub("", content)
    return content


def check_file(path):
    with open(path, encoding="utf-8") as f:
        original = f.read()
    content = strip_code(original)
    violations = []

    for match in MARKDOWN_IMAGE_RE.finditer(content):
        if match.group(1).strip() == "":
            line = content.count("\n", 0, match.start()) + 1
            violations.append((line, "markdown image is missing alt text: " + match.group(0)))

    for match in HTML_IMAGE_RE.finditer(content):
        if not ALT_ATTR_RE.search(match.group(0)):
            line = content.count("\n", 0, match.start()) + 1
            tag = " ".join(match.group(0).split())
            violations.append((line, "<img> tag is missing an alt attribute: " + tag))

    return violations


def main():
    files = list(find_markdown_files(CONTENT_DIR))
    violation_count = 0

    for path in files:
        for line, message in check_file(path):
            violation_count += 1
            rel_path = os.path.relpath(path, os.getcwd())
            print(f"{rel_path}:{line}: {message}", file=sys.stderr)

    if violation_count > 0:
        print(
            f"\nfound {violation_count} image(s) missing alt text; "
            'every image needs descriptive alt text for accessibility and SEO, '
            'use alt="" only for purely decorative images',
            file=sys.stderr,
        )
        return 1

    print(f"checked {len(files)} markdown file(s) under content/en/, all images have alt text")
    return 0


if __name__ == "__main__":
    sys.exit(main())
