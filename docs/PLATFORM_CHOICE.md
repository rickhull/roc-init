# Roc Platform Development: 3-Way Workflow

This repository provides three different approaches to developing with Roc platforms, ranging from simple usage to advanced platform development.

## Overview

| Workflow | File | Platform Source | Toolchain Required | Use Case |
|----------|------|-----------------|-------------------|----------|
| **Zig Template** | `zig_template.roc` | Remote (GitHub release) | None | App developers using pre-built Zig platform |
| **Rust Template** | `rust_platform.roc` | Remote (GitHub release) | None | App developers using pre-built Rust platform |
| **Basic-CLI (Local)** | `basic-cli.roc` | Local (`../basic-cli/platform/main.roc`) | Rust toolchain | Platform developers extending/modifying the platform |

## 1. Zig Template (Trivial - Remote)

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

## 2. Rust Template (Trivial - Remote)

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

## 3. Basic-CLI (Advanced - Local Development)

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
- Changes to platform code are immediately available

**Requirements:**
- Roc compiler
- Rust toolchain (rustc, cargo)
- The `basic-cli` repository cloned at `../basic-cli/`

**Setup:**
```bash
# Clone the basic-cli platform repository
git clone https://github.com/roc-lang/basic-cli ../basic-cli

# Switch to the migrate-zig-compiler branch (for new compiler support)
cd ../basic-cli
git checkout migrate-zig-compiler

# Build the platform
./build.sh

# Return to this repo and run your app
cd ../roc-init
roc run basic-cli.roc
```

**Why use this workflow?**
- You're developing or modifying the platform itself
- You need to debug platform-level issues
- You want to add new host functions or platform capabilities
- You're contributing to the basic-cli platform

## Comparison

### When to use each workflow

| Use Case | Recommended Workflow |
|----------|---------------------|
| Learning Roc language basics | Zig or Rust template |
| Building a standalone application | Zig or Rust template |
| Competitive programming (AoC, etc) | Zig or Rust template |
| Contributing to Roc platform | Basic-CLI local |
| Developing new host functions | Basic-CLI local |
| Debugging platform-specific issues | Basic-CLI local |
| Testing unreleased platform features | Basic-CLI local |

### Trade-offs

**Remote Templates (Zig/Rust):**
- ✅ Zero setup beyond Roc compiler
- ✅ Stable, tested releases
- ✅ Cross-platform compatibility handled for you
- ❌ Can't modify platform
- ❌ Dependent on release cycle

**Local (Basic-CLI):**
- ✅ Full platform source access
- ✅ Immediate iteration on platform changes
- ✅ Can add custom host functions
- ❌ Requires Rust toolchain
- ❌ Must build from source
- ❌ Higher complexity

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

## See Also

- [platform-dev-guide.md](platform-dev-guide.md) - Detailed guide for platform developers
- [ZIG_PLATFORM_GUIDE.md](ZIG_PLATFORM_GUIDE.md) - Zig-specific platform development
- [ROC_TUTORIAL.md](ROC_TUTORIAL.md) - Roc language fundamentals
