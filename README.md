# roc-init

A **Roc** programming language template and learning environment. Roc is a modern functional programming language with strong static typing. This repository serves as a starting point for Roc projects, particularly for competitive programming (Advent of Code) and learning the language.

**Important**: This project focuses on the new Zig-based Roc compiler (released late 2024/early 2025). Much of the online documentation at roc-lang.org is outdated and refers to the old compiler. Always refer to the local `docs/` files or use the `roc-language` skill for authoritative syntax and API reference.

## Quick Start

```bash
# Install Roc nightly (to ~/.local/bin)
just install-roc

# Fetch latest documentation
# Install user-level `roc-language` skill
just update-docs

# Run the application
roc run zig_template.roc # or rust_template.roc
```

**Editor Support:** Roc includes an experimental LSP server. Configure your editor to use `roc experimental-lsp` for features like auto-completion, go-to-definition, and diagnostics. See [LSP Setup](#language-server-protocol-lsp) below.

## Slow Start

### Just Commands

In order to use "just commands" (from the `justfile`, like a `Makefile`), you need to have `Just` installed.

### Install Roc

`just install-roc` will run some checks to ensure the tooling exists to:

1. Download the latest roc-nightly release
2. Extract the binaries in a temp dir
3. Copy the binaries to ~/.local/bin (typically in a user's PATH)

### Roc-language Skill

There is a claude-native skill provided that will read docs provided by this project (`roc-init`) as well as from upstream Roc (`roc-lang/roc`).

`just update-docs` will fetch the latest Roc docs and then install the skill at the user level: `~/.claude/skills/roc-language/`

You can optionally install the skill at the project level with `just skill-install local`, but this would put the skill in the `roc-init` project, so maybe not all that useful.

### Choose A Platform

Your "hello world" Roc application requires a platform.  For the new Roc compiler, there are 3 "starter platforms" that are available:

* `roc-platform-template-zig`
* `roc-platform-template-rust`
* `basic-cli`

Starting from a platform template (the first 2 options) is the easiest and quickest way to get started, but these platform templates are quite basic, providing Stdin, Stdout, Stderr, and not much else.

There is no release URL for the `basic-cli` platform for the new compiler (YET!), so you must build a specific git branch using a Rust toolchain.  This is more involved but provides a much more capable platform to build your Roc application against.

## Just Commands

e.g. `just install-roc`

| Task | Description | Depends | Invokes |
|------|-------------|---------|---------|
| `check-nightly` | Check if Roc nightly is latest | `tools-install` | |
| `fetch-docs` | Fetch Roc docs with ETag caching | | |
| `fetch-roc` | Download Roc nightly to cache | `tools-install` | |
| `install-roc` | Fetch and install Roc nightly | `tools-install` `fetch-roc` | `check-nightly` `fetch-roc` `prune-roc` |
| `install-rocgist` | Install `~/.local/bin/rocgist` | | |
| `install-skill` | Install `roc-language` skill (to `~/.claude` or `.claude`) | | |
| `prune-roc` | Keep latest 3 nightly cache entries | | |
| `tools-fetch` | Verify `curl` is available | | |
| `tools-install` | Verify `jq` is available | `tools-fetch` | |
| `update-docs` | Fetch docs, install user skill | `fetch-docs` `install-skill` | |

## Development Commands

### Building and Running
- `roc run main.roc` - Run the main application
- `roc build main.roc` - Build an executable
- `roc test` - Run tests (`expect` calls at the toplevel of `*.roc` files)

### Documentation Management
- `just fetch-docs` - Download latest Roc reference documentation from GitHub with ETag caching
  - Fetches `docs/Builtin.roc` (complete built-in functions reference)
  - Fetches `docs/all_syntax_test.roc` (comprehensive syntax examples)
  - Uses ETag caching to avoid unnecessary downloads

### Claude Code Skills
- `just install-skill` - Install roc-language skill to `~/.claude/skills/` (user-level, available in all repos)
- `just install-skill local` - Install skill in-repo to `.claude/skills/` (project-specific)
- `just update-docs` - One-command: fetch docs + install to user-level skill

### Code Sharing with rocgist

The `rocgist` script runs a Roc file and creates a GitHub Gist with the code, stdout, and stderr.

**Installation:**
```bash
just install-rocgist
```

**Usage:**
```bash
# Basic usage - run a file and create a gist
rocgist main.roc

# Include additional files in the gist
rocgist solution.roc input.txt
```

**What it does:**
1. Runs the specified `.roc` file with `roc`
2. Captures stdout and stderr to `STDOUT.txt` and `STDERR.txt`
3. Creates a GitHub Gist with:
   - The source code file
   - `STDOUT.txt` (program output)
   - `STDERR.txt` any error messages)
   - Any additional files you specify
4. Prints the Gist URL

**Requirements:**
- `roc` must be installed and in PATH
- `gh` (GitHub CLI) must be installed and authenticated

---

## Language Server Protocol (LSP)

Roc includes an experimental LSP server that provides:
- **Go to definition** - Jump to where functions/variables are defined
- **Find references** - Find all uses of a function/variable
- **Auto-completion** - Suggest completions as you type
- **Hover information** - Show type signatures on hover
- **Diagnostics** - Real-time error and warning highlighting
- **Signature help** - Parameter hints while typing function calls

**Usage:** Configure your editor to use `roc experimental-lsp` as the language server command.

### Editor Configuration

#### Emacs (including terminal)

**Eglot** (built into Emacs 26+):
```elisp
(add-to-list 'eglot-server-programs '(roc-mode . ("roc" "experimental-lsp")))
(add-hook 'roc-mode-hook 'eglot-ensure)
```

**lsp-mode**:
```elisp
(lsp-register-client
 (make-lsp-client :new-connection (lsp-stdio-connection '("roc" "experimental-lsp"))
                  :major-modes '(roc-mode)
                  :server-id 'roc))
(add-hook 'roc-mode-hook 'lsp-deferred)
```

#### Neovim

Using `nvim-lspconfig`:
```lua
require('lspconfig').roc.setup({
  cmd = { 'roc', 'experimental-lsp' },
})
```

#### Helix

In `~/.config/helix/languages.toml`:
```toml
[language-server.roc]
command = "roc"
args = ["experimental-lsp"]

[[language]]
name = "roc"
language-servers = ["roc"]
```

#### VS Code

Install the official Roc extension, or add to `settings.json`:
```json
{
  "roc.languageServerPath": "roc",
  "roc.languageServerArgs": ["experimental-lsp"]
}
```

#### Zed

Zed has built-in Roc support. If you need to configure it manually, add to `settings.json`:
```json
{
  "lsp": {
    "roc": {
      "command": "roc",
      "arguments": ["experimental-lsp"]
    }
  }
}
```

## Project Structure

```
roc-init/
├── justfile             # Build automation with just commands
├── rocgist              # Gist sharing script
├── docs/                # Authoritative Roc language documentation
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

## Documentation

The `docs/` directory contains authoritative Roc language reference materials:

| File | Description |
|------|-------------|
| [Builtin.roc](docs/Builtin.roc) | Complete built-in functions reference from Roc compiler |
| [all_syntax_test.roc](docs/all_syntax_test.roc) | Comprehensive syntax examples from Roc test suite |
| [ROC_TUTORIAL.md](docs/ROC_TUTORIAL.md) | Full Roc tutorial |
| [ROC_TUTORIAL_CONDENSED.md](docs/ROC_TUTORIAL_CONDENSED.md) | Condensed Roc tutorial |
| [ROC_LANGREF_TUTORIAL.md](docs/ROC_LANGREF_TUTORIAL.md) | Language reference tutorial |
| [roc-advent-2025.md](docs/roc-advent-2025.md) | Advent of Code 2025 guide |
| [AOC_2025_UPDATES.md](docs/AOC_2025_UPDATES.md) | Corrections to outdated AoC documentation |


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

Quick start: `just update-docs`

This will fetch the latest docs and install a user-level (`~/.claude`) `roc-language` skill.

```bash
# Fetch the latest docs, ETag caching
just fetch-docs

# Install to user-level (recommended - available in all repos)
just install-skill

# Or install in-repo only (project-specific)
just install-skill local
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
