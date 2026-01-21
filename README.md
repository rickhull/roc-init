# README.md

## Notes

Note that `skills/roc-language/references` is a symlink to `docs/`

Use `just fetch` to pull `docs/Builtin.roc` and `docs/all_syntax_test.roc`
from the main Roc repo.

## roc-init Project Overview

This is a **Roc** programming language template and learning environment. Roc is a modern functional programming language with strong static typing. This repository serves as a starting point for Roc projects, particularly for competitive programming (Advent of Code) and learning the language.

**Important**: This codebase uses the new Zig-based Roc compiler (released late 2024/early 2025). Much of the online documentation at roc-lang.org is outdated and refers to the old compiler. Always refer to the local `docs/` files or use the `roc-language` skill for authoritative syntax and API reference.

## Development Commands

### Building and Running
- `roc run main.roc` - Run the main application
- `roc build main.roc` - Build an executable
- `roc test` - Run tests (in `*_test.roc` files)

### Documentation
- `just fetch` - Download latest Roc reference documentation from GitHub
  - Fetches `docs/Builtin.roc` (complete built-in functions reference)
  - Fetches `docs/all_syntax_test.roc` (comprehensive syntax examples)

### Code Sharing
- `./rocgist.sh path/to/execute.roc [additional_files...]` - Run a Roc file and create a GitHub Gist with the code, stdout, and stderr

## Project Structure

```
roc-init/
├── main.roc              # Application entry point
├── justfile             # Build automation (run `just fetch`)
├── rocgist.sh           # Gist sharing script
├── docs/                # Authoritative Roc language documentation
│   ├── Builtin.roc      # Complete built-in functions reference
│   ├── all_syntax_test.roc  # All syntax examples
│   ├── ROC_TUTORIAL*.md     # Learning materials
│   └── roc-advent-2025.md   # AoC 2025 guide (some content outdated - see AOC_2025_UPDATES.md)
└── skills/
    └── roc-language/    # Claude Code skill for Roc language reference
        └── references/ -> ../../docs  (symlink)
```

## Roc Application Structure

Roc applications use the following structure:

```roc
app [main!] { pf: platform "..." }

import pf.Stdout

main! = |_args| {
    Stdout.line!("Hello, World!")
    Ok({})
}
```

- The `app [main!]` declaration defines the entry point
- Platform functionality (file I/O, stdout, etc.) is imported via the platform URL
- The `main!` function takes command-line arguments and returns `Result({}, Error)`

## Common Syntax Patterns

### List Operations
```roc
# Get first element (returns Try(item, [ListWasEmpty, ..]))
match myList.first() {
    Ok(first) => first
    Err(ListWasEmpty) => defaultValue
}
```

### String Operations
- Use `Str.inspect` for converting values to strings (new compiler)
- Numeric `from_str` returns `Result(num, BadNumStr)`
- `Str.from_utf8` returns `Result(Str, BadUtf8)`

### Error Handling
Error tags are more specific in the new compiler:
- `ListWasEmpty` (not just `WasEmpty`)
- `BadNumStr` for numeric parse failures
- `BadUtf8` for UTF-8 conversion failures

## Working with Claude Code

When working with Roc code in this repository, use the `roc-language` skill for authoritative syntax and API reference. The skill has access to the latest `docs/` files and provides correct information for the new Zig-based compiler.

**Important**: If you see examples using old syntax like `Num.to_str`, they are likely outdated. The new compiler uses `Str.inspect` instead.

## Environment Configuration

The `.envrc` file configures the Z.AI API integration for Claude Code:
- Uses Anthropic API through Z.AI proxy
- Source with `direnv allow` or manually set the environment variables

## Documentation Updates

Some files in `docs/` track known issues with outdated documentation:
- `AOC_2025_UPDATES.md` - Records discrepancies between early AoC 2025 guide and current compiler implementation
- Always cross-reference with `Builtin.roc` and `all_syntax_test.roc` for current syntax
