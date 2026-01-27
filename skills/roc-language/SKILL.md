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

- Mini Tutorial: @references/mini-tutorial-new-compiler.md (~700 lines, 28KB)
- Gotchas: @references/GOTCHAS.md (~450 lines, 12KB)

## Lazy Load

Search or read as necessary:

- Mini Tutorial Augments: references/MINI_TUTORIAL_AUGMENTS.md (~1100 lines, 28KB)
- Builtin Reference: references/Builtin.roc (~1500 lines, 48KB)
- Syntax Reference: references/all_syntax_test.roc (~400 lines, 12KB)
- Language Reference Tutorial: references/ROC_LANGREF_TUTORIAL.md (~2200 lines, 44KB)
