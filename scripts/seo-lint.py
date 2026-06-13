#!/usr/bin/env python3
import os
import re
import sys
import subprocess

REPO_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def get_tracked_markdown_files():
    result = subprocess.run(["git", "ls-files"], cwd=REPO_DIR, capture_output=True, text=True, check=True)
    files = []
    for line in result.stdout.splitlines():
        line = line.strip()
        if line.startswith("content/en/") and line.endswith(".md"):
            files.append(os.path.join(REPO_DIR, line))
    return files

def lint_file(path):
    errors = []
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    # 1. Frontmatter validation
    frontmatter_match = re.match(r"^---\s*\n(.*?)\n---\s*\n", content, re.DOTALL)
    if not frontmatter_match:
        return errors

    frontmatter = frontmatter_match.group(1)
    lines = frontmatter.splitlines()
    
    # Check for duplicate description keys case-insensitively
    description_keys = []
    has_title = False
    has_description = False
    for line in lines:
        line_stripped = line.strip()
        if line_stripped.lower().startswith("description:"):
            description_keys.append(line_stripped)
            has_description = True
        elif line_stripped.lower().startswith("title:"):
            has_title = True

    if len(description_keys) > 1:
        errors.append(f"Duplicate description keys found in frontmatter: {description_keys}")

    # Description requirements for docs and blogs
    rel_path = os.path.relpath(path, REPO_DIR)
    is_doc_or_blog = "content/en/docs" in rel_path or "content/en/blog" in rel_path
    
    if is_doc_or_blog:
        if not has_description:
            errors.append("Missing 'description' key in frontmatter.")
        else:
            # Check length/validity of description
            desc_val = ""
            for line in lines:
                if line.strip().lower().startswith("description:"):
                    desc_val = line.split(":", 1)[1].strip().strip('"').strip("'")
                    break
            if not desc_val:
                errors.append("Description field is empty.")
            elif len(desc_val) > 160:
                errors.append(f"Description is too long ({len(desc_val)} characters, max 160).")

    # 2. Heading hierarchy validation (no H1 in body if title in frontmatter)
    body = content[frontmatter_match.end():]
    if has_title:
        in_code_block = False
        body_lines = body.splitlines()
        for idx, line in enumerate(body_lines):
            if line.startswith("```"):
                in_code_block = not in_code_block
            if not in_code_block and re.match(r"^#\s+[^#]", line):
                errors.append(f"H1 heading found in body at line {idx+1}: '{line}'. Use H2 (##) or lower instead.")

    # 3. Image alt text validation
    # Raw HTML image tags
    img_pattern = re.compile(r'<img\s+([^>]*src="([^"]+)"[^>]*)>', re.IGNORECASE)
    for match in img_pattern.finditer(body):
        tag_attrs = match.group(1)
        src = match.group(2)
        # Check for alt attribute
        alt_match = re.search(r'alt="([^"]*)"', tag_attrs, re.IGNORECASE)
        if not alt_match:
            errors.append(f"Raw <img> tag missing 'alt' attribute: src='{src}'")
        elif not alt_match.group(1).strip():
            errors.append(f"Raw <img> tag has empty 'alt' attribute: src='{src}'")

    # Markdown images: ![alt](src)
    md_img_pattern = re.compile(r'!\[(.*?)\]\((.*?)\)')
    for match in md_img_pattern.finditer(body):
        alt_text = match.group(1).strip()
        src = match.group(2).strip()
        if not alt_text:
            errors.append(f"Markdown image missing alt text: src='{src}'")

    return errors

def main():
    files = get_tracked_markdown_files()
    total_errors = 0
    
    print(f"Linting {len(files)} tracked markdown files for SEO and heading guidelines...")
    
    for path in files:
        errors = lint_file(path)
        if errors:
            rel_path = os.path.relpath(path, REPO_DIR)
            print(f"\n[ERROR] {rel_path}:")
            for err in errors:
                print(f"  - {err}")
            total_errors += len(errors)
            
    if total_errors > 0:
        print(f"\nSEO lint failed: {total_errors} errors found.")
        sys.exit(1)
    else:
        print("\nSEO lint passed successfully.")
        sys.exit(0)

if __name__ == "__main__":
    main()
