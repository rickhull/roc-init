---
name: roc-language
description: |
  Authoritative Roc programming language reference. When Claude needs to 
  read, write, edit, debug, or analyze any .roc file, or understand Roc 
  syntax, types, or compiler errors. Provides current API reference and 
  syntax patterns using Roc compiler source as ground truth.
version: 1.0.0
---

# Roc Language

## Critical Notes

**WARNING: Outdated Documentation Exists**
- Many online tutorials reference the old Rust-based Roc compiler
- Current Roc uses different builtin functions than old docs show
- Example: `Num.to_str` does NOT exist in current Roc; use `Str.inspect` instead

## Eager Load

Always read in full:

- Condensed Tutorial: @references/ROC_TUTORIAL_CONDENSED.md

## Lazy Load

Search or read as necessary:

- Builtin Reference: references/Builtin.roc
- Syntax Reference: references/all_syntax_test.roc
- Full Tutorial: references/ROC_LANGREF_TUTORIAL.md
