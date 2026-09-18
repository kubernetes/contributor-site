#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const CONTENT_DIR = path.join(__dirname, '..', 'content', 'en');

function findMarkdownFiles(dir) {
  const files = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...findMarkdownFiles(fullPath));
    } else if (entry.isFile() && entry.name.endsWith('.md')) {
      files.push(fullPath);
    }
  }
  return files;
}

function stripCodeBlocks(content) {
  return content
    .replace(/```[\s\S]*?```/g, '')
    .replace(/`[^`\n]*`/g, '');
}

function lineNumberAt(content, index) {
  return content.slice(0, index).split('\n').length;
}

function checkFile(filePath) {
  const original = fs.readFileSync(filePath, 'utf8');
  const content = stripCodeBlocks(original);
  const violations = [];

  const markdownImageRe = /!\[([^\]]*)\]\(([^)]+)\)/g;
  let match;
  while ((match = markdownImageRe.exec(content)) !== null) {
    if (match[1].trim() === '') {
      violations.push({
        line: lineNumberAt(content, match.index),
        message: `Markdown image is missing alt text: ${match[0]}`,
      });
    }
  }

  const htmlImageRe = /<img\b[^>]*>/gs;
  while ((match = htmlImageRe.exec(content)) !== null) {
    if (!/\balt\s*=\s*(["']).*?\1/s.test(match[0])) {
      violations.push({
        line: lineNumberAt(content, match.index),
        message: `<img> tag is missing an alt attribute: ${match[0].replace(/\s+/g, ' ')}`,
      });
    }
  }

  return violations;
}

function main() {
  const files = findMarkdownFiles(CONTENT_DIR);
  let violationCount = 0;

  for (const file of files) {
    const violations = checkFile(file);
    if (violations.length > 0) {
      violationCount += violations.length;
      const relPath = path.relative(process.cwd(), file);
      for (const violation of violations) {
        console.error(`${relPath}:${violation.line}: ${violation.message}`);
      }
    }
  }

  if (violationCount > 0) {
    console.error(
      `\nFound ${violationCount} image(s) missing alt text. Every image needs descriptive alt text for accessibility and SEO. Use alt="" only for purely decorative images.`
    );
    process.exit(1);
  }

  console.log(`Checked ${files.length} markdown file(s) under content/en/, all images have alt text.`);
}

main();
