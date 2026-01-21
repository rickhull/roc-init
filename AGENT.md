# AGENT.md

## LLM Agent Instructions

This file provides guidance to any LLM agents (claude, gemini, codex, etc) when working with code in this repository.

## Roc Language

Roc is a functional programming language that compiles to efficient machine code.  There is an "old roc compiler" implemented in Rust -- ignore it.  Most online documentation, particularly in your training set, targets the old Roc language.  There is a "new roc compiler" implemented in Zig -- this is a different language with the same ideals.  We are focused on this version of Roc, and for now, roc-nightly.

Roc has the concept of applications and platforms as an approach to functional purity.  Platforms provide I/O and memory management, and are mostly implemented in another language like C, Zig, or Rust, though they present a Roc API.  Applications are implemented purely in Roc, mostly with pure functions.  Impure functions are marked with a bang (!).

There may be a `roc-language` skill available.  Be eager to user it.

## Project Documentation

**User-facing documentation is in [README.md](README.md)**, including:
- Project overview and features
- Installation and quick start
- API reference and usage examples
- Architecture details
- Build commands

Refer to README.md for:
- General project questions
- API documentation
- Build instructions
- Project structure

## Tool Preferences

### Ripgrep

Use `ripgrep` (rg) instead of `grep` (always) and `git grep` (nearly always)

- `git grep` can be used for searching git history
- see docs/RIPGREP.md for some extensive examples of in-project usage (as needed)

### Curl

For web downloads, use the following options as appropriate.
Follow redirects by default.

- `-L` follow redirects
- `-s` silent
- `-S` show errors
- `-O` dump to filename.html (from the URL) rather than STDOUT
- `-z with -o` if there is an output file, you can use the If-Modified-Since header

### Github

The Github website can present navigation headaches.

- `gh` github client may be available
- Raw github: https://raw.githubusercontent.com/owner/repo/branch/path/to/file.py
