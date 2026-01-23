# New Roc Application Development: 3 Starter Platforms

This repository provides three different approaches to developing applications against various Roc platforms.

## Overview

| Workflow | File | Platform Source | Capabilities | Toolchain Required | Use Case |
|----------|------|-----------------|--------------|-------------------|----------|
| **Zig Template** | `zig_template.roc` | Remote (GitHub release) | stdin/stdout/stderr only | None | Learning Roc, simple scripts |
| **Rust Template** | `rust_platform.roc` | Remote (GitHub release) | stdin/stdout/stderr only | None | Learning Roc, simple scripts |
| **Basic-CLI** | `basic-cli.roc` | Local (`../basic-cli/platform/main.roc`) | Full platform (files, network, env, etc.) | Rust toolchain | Real applications |

## 1. Zig Template (Minimal - Remote)

**Capabilities:**
- `Stdout.line!` - Write strings to stdout with newline
- `Stderr.line!` - Write strings to stderr with newline
- `Stdin.line!` - Read a line from stdin (returns empty string on EOF)

**Limitations:**
- No file system access (read/write files)
- No network I/O
- No binary I/O
- No time/date functions
- Line-based text I/O only

```roc
app [main!] { pf: platform "https://github.com/lukewilliamboswell/roc-platform-template-zig/releases/download/0.6/2BfGn4M9uWJNhDVeMghGeXNVDFijMfPsmmVeo6M4QjKX.tar.zst" }

import pf.Stdout

main! = |_args| {
    Stdout.line!("Hello from Zig platform!")
    Ok({})
}
```

**How it works:**
- Roc downloads the platform archive from GitHub releases
- Extracts and caches it locally
- Your app runs against this pre-built platform

**Requirements:**
- Roc compiler only (no Zig installation needed)

**Run:**
```bash
roc run zig_template.roc
```

## 2. Rust Template (Minimal - Remote)

**Capabilities:**
- `Stdout.line!` - Write strings to stdout with newline
- `Stderr.line!` - Write strings to stderr with newline
- `Stdin.line!` - Read a line from stdin (returns empty string on EOF)

**Limitations:**
- No file system access (read/write files)
- No network I/O
- No binary I/O
- No time/date functions
- Line-based text I/O only

*Note: Similar capabilities to Zig template; choose based on your preference for Zig vs Rust ecosystems.*

```roc
app [main!] { pf: platform "https://github.com/lukewilliamboswell/roc-platform-template-rust/releases/download/0.1/H8GgQfvW5hwgAwbwRJ1Whmq3CAX3A5dGbZWHefB6NXtN.tar.zst" }

import pf.Stdout

main! = |_args| {
    Stdout.line!("Hello from Rust platform!")
    Ok({})
}
```

**How it works:**
- Same as Zig template, but using a Rust-based platform
- Downloads and caches platform from GitHub releases

**Requirements:**
- Roc compiler only (no Rust installation needed)

**Run:**
```bash
roc run rust_platform.roc
```

## 3. Basic-CLI (Full-Featured - Local Build)

> **Transitional Note:** Basic-cli requires building from source because pre-built releases for the new Zig-based compiler aren't available yet. Once basic-cli publishes new compiler releases, this workflow will be as simple as the templates—just point to a remote URL and run. The current setup complexity is temporary.

**Capabilities (much more than templates):**
- Full file system I/O (read/write files, directories)
- Network operations
- Environment variables
- Command-line argument parsing
- Time/date functions
- Path manipulation
- And more...

**Why use this workflow?**
- Building real applications that need file I/O
- Working with directories or configuration files
- Network operations
- Any system programming beyond stdin/stdout
- You need a complete, production-capable platform

```roc
app [main!] { pf: platform "../basic-cli/platform/main.roc" }

import pf.Stdout

main! = |_args| {
    Stdout.line!("Hello from local basic-cli platform!")
    Ok({})
}
```

**How it works:**
- Roc loads platform from a local relative path
- Platform must be built from source before running
- Provides complete platform capabilities for your applications

**Requirements:**
- Roc compiler
- Rust toolchain (rustc, cargo) *(transitional - won't be needed after releases)*
- The `basic-cli` repository cloned at `../basic-cli/`

**Setup (transitional - will be simplified after releases):**

```bash
# From outside roc-init, clone the basic-cli platform repository
git clone https://github.com/roc-lang/basic-cli

# Switch to the migrate-zig-compiler branch (for new compiler support)
cd basic-cli
git checkout migrate-zig-compiler

# Build the platform
./build.sh

# Return to this repo and run your app
cd ../roc-init
roc run basic-cli.roc # this points to ../basic-cli/platform/main.roc
```

## Comparison

### When to use each workflow

| Use Case | Recommended Workflow |
|----------|---------------------|
| Learning Roc language basics | Zig or Rust template |
| Simple scripts (stdin → stdout) | Zig or Rust template |
| File I/O (read/write files) | Basic-CLI |
| Network operations | Basic-CLI |
| Working with directories | Basic-CLI |
| Environment variables | Basic-CLI |
| Real-world applications | Basic-CLI |

### Trade-offs

**Remote Templates (Zig/Rust):**
- ✅ Zero setup beyond Roc compiler
- ✅ Stable, tested releases
- ✅ Cross-platform compatibility handled for you
- ❌ **Minimal capabilities** (stdin/stdout/stderr only)
- ❌ No file I/O, no network, no system access
- ❌ Not suitable for most real applications

**Local (Basic-CLI):**
- ✅ **Full platform capabilities** for applications (files, network, env, etc.)
- ✅ Production-ready for real applications
- ✅ Complete standard library interface
- ❌ Requires Rust toolchain *(transitional - until releases are available)*
- ❌ Must build platform from source *(transitional - until releases are available)*
- ❌ More complex setup *(will match templates after releases)*

## Platform URLs Explained

### Remote Platform URLs

The remote platform URLs follow this pattern:
```
https://github.com/{org}/{repo}/releases/download/{version}/{archive}.tar.zst
```

Roc will:
1. Download the `.tar.zst` archive
2. Cache it locally
3. Extract and verify the platform interface
4. Use it for compilation and execution

### Local Platform Paths

Local platforms use a relative path to a `platform/main.roc` file:
```
app [main!] { pf: platform "../basic-cli/platform/main.roc" }
```

The path is relative to your `.roc` file location.

## Switching Between Workflows

You can easily switch between workflows by changing the platform URL in your app's header:

```roc
# Start with Zig template
app [main!] { pf: platform "https://.../zig-platform-...tar.zst" }

# Later switch to local development
app [main!] { pf: platform "../basic-cli/platform/main.roc" }

# Or try Rust
app [main!] { pf: platform "https://.../rust-platform-...tar.zst" }
```

The rest of your Roc code remains the same - only the platform declaration changes.
