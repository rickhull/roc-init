# roc-init

A **Roc** programming language template and learning environment. Roc is a modern functional programming language with strong static typing. This repository serves as a starting point for Roc projects, particularly for competitive programming (Advent of Code) and learning the language.

**Important**: This codebase uses the new Zig-based Roc compiler (released late 2024/early 2025). Much of the online documentation at roc-lang.org is outdated and refers to the old compiler. Always refer to the local `docs/` files or use the `roc-language` skill for authoritative syntax and API reference.

## Quick Start

```bash
# Install Roc nightly (to ~/.local/bin)
just install-roc

# Fetch latest documentation
just update-docs

# Run the application
roc run main.roc
```

## Just Commands

e.g. `just install-roc`

| Task | Description | Depends | Invokes |
|------|-------------|---------|---------|
| `fetch-docs` | Fetch Roc docs with ETag caching | | |
| `prune-roc` | Keep latest 3 nightly cache entries | | |
| `skill-init` | Initialize roc-language skill in-repo | | |
| `skill-install` | Install roc-language skill user-level | | |
| `tools-fetch` | Verify curl is available | | |
| `check-nightly` | Check if Roc nightly is latest | tools-install | |
| `fetch-roc` | Download Roc nightly to cache | tools-install | |
| `install-roc` | Fetch and install Roc nightly | tools-install<br>fetch-roc | check-nightly<br>fetch-roc<br>prune-roc |
| `skill-all` | Install skill in-repo and user-level | skill-init<br>skill-install | |
| `tools-install` | Verify jq is available | tools-fetch | |
| `update-docs` | Fetch docs, install user skill | fetch-docs<br>skill-install | |

## Development Commands

### Building and Running
- `roc run main.roc` - Run the main application
- `roc build main.roc` - Build an executable
- `roc test` - Run tests (in `*_test.roc` files)

### Documentation Management
- `just fetch-docs` - Download latest Roc reference documentation from GitHub with ETag caching
  - Fetches `docs/Builtin.roc` (complete built-in functions reference)
  - Fetches `docs/all_syntax_test.roc` (comprehensive syntax examples)
  - Uses ETag caching to avoid unnecessary downloads

### Claude Code Skills
- `just skill-install` - Install roc-language skill to `~/.claude/skills/` (user-level, available in all repos)
- `just skill-init` - Initialize skill in `.claude/skills/` (in-repo, project-specific)
- `just skill-all` - Install to both locations
- `just update-docs` - One-command: fetch docs + install to user-level skill

### Code Sharing
- `./rocgist.sh path/to/execute.roc [additional_files...]` - Run a Roc file and create a GitHub Gist with the code, stdout, and stderr

## Project Structure

```
roc-init/
├── main.roc              # Application entry point
├── justfile             # Build automation with just commands
├── rocgist.sh           # Gist sharing script
├── docs/                # Authoritative Roc language documentation
│   ├── Builtin.roc      # Complete built-in functions reference
│   ├── all_syntax_test.roc  # All syntax examples
│   ├── ROC_TUTORIAL*.md     # Learning materials
│   ├── roc-advent-2025.md   # AoC 2025 guide
│   └── AOC_2025_UPDATES.md  # Corrections to outdated docs
├── cache/               # ETag cached downloads (gitignored)
│   ├── roc-docs/        # Cached documentation fetches
│   └── roc-nightly/     # Cached Roc nightly builds
├── skills/              # Claude Code skills
│   └── roc-language/
│       └── references/ -> ../../docs  (symlink)
└── .claude/             # In-repo skills (auto-generated, gitignored)
    └── skills/
        └── roc-language/
            └── references/  (copies from docs/)
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

### Setting Up Skills

After fetching documentation, install the skill:

```bash
# Install to user-level (recommended - available in all repos)
just skill-install

# Or install in-repo only (project-specific)
just skill-init

# Or both
just skill-all
```

The skill copies documentation files directly (not via symlinks) to ensure they work correctly with Claude Code.

**Important**: If you see examples using old syntax like `Num.to_str`, they are likely outdated. The new compiler uses `Str.inspect` instead.

## Environment Configuration

The `.envrc` file configures the Z.AI API integration for Claude Code:
- Uses Anthropic API through Z.AI proxy
- Source with `direnv allow` or manually set the environment variables

## Documentation Updates

Some files in `docs/` track known issues with outdated documentation:
- `AOC_2025_UPDATES.md` - Records discrepancies between early AoC 2025 guide and current compiler implementation
- Always cross-reference with `Builtin.roc` and `all_syntax_test.roc` for current syntax

## Notes

- `skills/roc-language/references` is a symlink to `docs/` (for in-repo development)
- When installing skills, files are copied directly (not symlinked) to work correctly with Claude Code
- The `cache/` directory is gitignored and stores ETag-cached downloads to avoid unnecessary network requests
