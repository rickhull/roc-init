# roc-init

This project provides tools for getting your first [**Roc**](https://roc-lang.org/) program or environment up and running. Roc is a modern functional programming language with strong static typing. This repository focuses strictly on the relatively-unsupported, bleeding-edge "new Roc compiler".

## New Roc Compiler

The new Roc compiler is implemented in [Zig](https://ziglang.org/), replacing [Rust](https://www.rust-lang.org/)'s role in the old Roc compiler.  Much of the online documentation at https://roc-lang.org/ is outdated and refers to the old compiler. Not only has the compiler changed but also some language fundamentals. Always refer to the local [`docs/`](docs/) files or use the `roc-language` [skill](SKILL.md) for authoritative syntax and API reference.

## Quick Start

```bash
# Install Roc nightly (to ~/.local/bin)
just install-roc

# Fetch latest documentation
# Install user-level `roc-language` skill
just update-docs

# Run the application
roc main.roc

# Explicitly run the application; same behavior
roc run main.roc

# Build, then run
roc build main.roc && ./main
```

*Tip:* [`main.roc`](main.roc) is a symlink to [`examples/zig-platform.roc`](examples/zig-platform.roc).

### Editor Support ###

Roc includes an experimental LSP server. Configure your editor to use `roc experimental-lsp` for features like auto-completion, go-to-definition, and diagnostics. See [LSP Setup](#language-server-protocol-lsp) below.

## Slow Start

*For Nix users:* clone [`roc-lang/roc`](https://github.com/roc-lang/roc) and from within: `nix develop ./src` targeting `src/flake.nix`.  *Otherwise:*

### Just Commands

In order to use "just commands" (from the [`justfile`](justfile), like a `Makefile`), you need to have [Just](https://just.systems/) installed.

### Install Roc

`just install-roc` will run some checks to ensure the tooling exists to:

1. Download the latest roc-nightly release
2. Extract the binaries in a temp dir
3. Copy the binaries to ~/.local/bin (typically in a user's PATH)

### Roc-language Skill

There is a claude-native [skill](SKILL.md) provided that will read docs provided by this project (`roc-init`) as well as from upstream [roc-lang/roc](https://github.com/roc-lang/roc).

`just update-docs` will fetch the latest Roc docs and then install the skill at the user level: `~/.claude/skills/roc-language/`

You can optionally install the skill at the project level with `just skill-install local`, but this would put the skill in the `roc-init` project, so maybe not all that useful.

### Choose A Platform

Your Roc application needs a platform for I/O. Two immediate options:

| Platform | Setup | Use For |
|----------|-------|---------|
| **Template** | Built-in | Learning, simple scripts |
| **Basic-CLI** | `just basic-cli` | Real applications (files, network) |

Execute `roc main.roc` to run "hello world" against the default platform: a zero-setup remotely hosted Zig platform, built from a simple template.  `main.roc` is merely a symlink to [`examples/zig-platform.roc`](examples/zig-platform.roc).
If you prefer Rust to Zig, try `roc examples/rust-platform.roc`: same behavior on a slightly different platform.

To access files or the network, you need [`basic-cli`](https://github.com/roc-lang/basic-cli). Run `just basic-cli` to build the platform, and then `roc examples/basic-cli.roc` to run against it.

*See [Platform Details](#platform-details) below for more information.*

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
- `roc main.roc` - Run the main application
- `roc run main.roc` - Same as above (`run` is default subcommand)
- `roc build main.roc` - Build an executable
- `roc test` - Run tests (`expect` calls at toplevel of `*.roc` files)
  - See [`examples/expect/`](examples/expect/) for expect behavior patterns

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

The [`tools/rocgist`](tools/rocgist) shell script runs a Roc file and creates a GitHub Gist with the code, stdout, and stderr.

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
├── SKILL.md             # roc-language skill definition for Claude Code
├── justfile             # Build automation with just commands
├── main.roc -> examples/zig-platform.roc  (symlink)
├── tools/
│   └── rocgist          # Gist sharing script
├── docs/                # Authoritative Roc language documentation
├── examples/            # Example programs and expect tests
│   ├── zig-platform.roc # Zig platform template
│   ├── rust-platform.roc # Rust platform template
│   └── expect/          # Comprehensive expect behavior examples
└── cache/               # ETag cached downloads (gitignored)
    ├── roc-docs/        # Cached documentation fetches
    └── roc-nightly/     # Cached Roc nightly builds
```

## Documentation

The `docs/` directory contains authoritative Roc language reference materials:

| File | Description |
|------|-------------|
| [mini-tutorial-new-compiler.md](docs/mini-tutorial-new-compiler.md) | Primary tutorial for the new Zig-based compiler |
| [MINI_TUTORIAL_AUGMENTS.md](docs/MINI_TUTORIAL_AUGMENTS.md) | Advanced topics augmenting the mini-tutorial |
| [Builtin.roc](docs/Builtin.roc) | Complete built-in functions reference from Roc compiler |
| [all_syntax_test.roc](docs/all_syntax_test.roc) | Comprehensive syntax examples from Roc test suite |
| [ROC_LANGREF_TUTORIAL.md](docs/ROC_LANGREF_TUTORIAL.md) | Comprehensive language reference tutorial |


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

The skill copies documentation files directly from `docs/` to the installation destination. Each run of `install-skill` copies the current versions of the 6 reference files needed by the skill.

**Important**: If you see examples using old syntax like `Num.to_str`, they are likely outdated. The new compiler uses `Str.inspect` instead.

## Environment Configuration

The `.envrc` file configures the Z.AI API integration for Claude Code:
- Uses Anthropic API through Z.AI proxy
- Source with `direnv allow` or manually set the environment variables

---

## Platform Details

Your Roc application requires a platform. For the new Roc compiler, there are 3 starter platforms available:

| Platform | Source | Toolchain | Capabilities | Best For |
|----------|--------|-----------|--------------|----------|
| **Zig Template** | Remote (GitHub release) | None | stdin/stdout/stderr only | Learning, simple scripts |
| **Rust Template** | Remote (GitHub release) | None | stdin/stdout/stderr only | Learning, simple scripts |
| **Basic-CLI** | Local (automated setup) | Rust (for build) | Full platform (files, network, env) | Real applications |

### Quick Start: Zig or Rust Templates

Zero setup beyond the `roc` compiler. Start coding immediately:

```bash
# Run the template directly
roc main.roc
```

**Capabilities:** `Stdout.line!`, `Stderr.line!`, `Stdin.line!` (text I/O only)
**Limitations:** No file I/O, no network, no system access

### Full-Featured: Basic-CLI

For real applications requiring file I/O, network operations, or system access:

```bash
# One-command setup (clones and builds basic-cli)
just basic-cli

# Run your app
roc examples/basic-cli.roc
```

**Capabilities:** Files, directories, network, environment variables, paths, time/date, and more

**How it works:** The `just basic-cli` command:
1. Clones `roc-lang/basic-cli` to `../basic-cli/` (if not present)
2. Checks out the `migrate-zig-compiler` branch
3. Builds the platform with `./build.sh`
4. Creates `basic-cli.roc` pointing to the local platform

*Note: The build step is transitional—once basic-cli publishes pre-built releases for the new compiler, this will be as simple as the remote templates.*

### When to use each platform

| Use Case | Recommended |
|----------|-------------|
| Learning Roc basics | Zig or Rust template |
| Simple scripts (stdin → stdout) | Zig or Rust template |
| File I/O, configuration files | Basic-CLI |
| Network operations | Basic-CLI |
| Real-world applications | Basic-CLI |

### Switching platforms

Change the platform URL in your app's header—no other code changes needed:

```roc
# Remote template
app [main!] { pf: platform "https://github.com/.../zig-platform-...tar.zst" }

# Local basic-cli
app [main!] { pf: platform "../basic-cli/platform/main.roc" }
```

---

## Documentation Updates

Some files in `docs/` track known issues with outdated documentation:
- `AOC_2025_UPDATES.md` - Records discrepancies between early AoC 2025 guide and current compiler implementation
- Always cross-reference with `Builtin.roc` and `all_syntax_test.roc` for current syntax

## Notes

- [`SKILL.md`](SKILL.md) is the skill definition; `install-skill` copies it with docs from `docs/` to the installation destination
- The `cache/` directory is gitignored and stores ETag-cached downloads to avoid unnecessary network requests
