# Zig-based Roc Platform Development Guide

This covers development of Roc platforms using the "new Roc compiler" in Zig using the host ABI.

## What is a Roc Platform?

A Roc platform provides I/O, memory management, and host functions that Roc applications call. Platforms are implemented in a systems language (Zig, C, Rust) and expose functionality through a well-defined ABI.

## What does a Roc Platform look like?

Some fundamentals:

* `platform/main.roc` is the entry point for your platform's Roc API
* `platform/host.zig` provides your "hosted platform functions"

Build files:

* `build.zig` - Zig build configuration for compiling `host.zig` into static libraries (`libhost.a`) for each target platform
* `build.zig.zon` - Zig dependency management (pins Roc compiler version - **must match installed `roc`**)

### The Two File Contract (main.roc and host.zig)

Your platform is defined by the contract between `main.roc` (what you expose) and `host.zig` (what you implement).

#### `main.roc` - The Platform Declaration

```roc
platform ""
    requires {} { main! : List(Str) => Try({}, [Exit(I32)]) }
    exposes [Host, Stderr, Stdin, Stdout]  # Alphabetical!
    packages {}
    provides { main_for_host! : "main_for_host" }
    targets: {
        files: "targets/",
        exe: {
            x64linux: ["crt1.o", "libhost.a", app, "libc.a"],
            arm64mac: ["libhost.a", app],
        }
    }

import Host
import Stderr
import Stdin
import Stdout

main_for_host! : List(Str) => I32
main_for_host! = |args| {
    result = main!(args)
    match result {
        Ok({}) => 0
        Err(Exit(code)) => code
    }
}
```

**Key points:**
- `exposes` lists all modules - **must be alphabetical**
- `targets.exe` defines linker configuration per platform
- `main_for_host!` converts Roc's `Result` to raw `I32` exit code

#### Module Interface Files (`Host.roc`, `Stdout.roc`, etc.)

Each module in `exposes` needs an interface file:

```roc
# Host.roc
Host := [].{
    ## Compute hash of input string
    hash! : Str => List U8
}
```

These modules can contain Roc function signatures and definitions, but if there is no
definition provided, then it must be a "host function", implemented in `host.zig`,
with a specific naming convention: `hosted` `ModuleName` `FunctionName`

So `Host.hash!` must be implemented in Zig as `fn hostedHostHash`.

#### `host.zig` - The Implementation

```zig
const std = @import("std");
const builtins = @import("builtins");

const RocList = builtins.list.RocList;
const RocStr = builtins.str.RocStr;

// Naming convention: hosted + ModuleName + FunctionName
// Host.hash -> hostedHostHash
fn hostedHostHash(ops: *builtins.host_abi.RocOps, ret_ptr: *anyopaque, args_ptr: *anyopaque) callconv(.c) void {
    const Args = extern struct { input: RocStr };
    const args: *Args = @ptrCast(@alignCast(args_ptr));

    // Implementation...

    const result: *RocList = @ptrCast(@alignCast(ret_ptr));
    result.* = /* return value */;
}
```

#### The Function Pointer Array (FPA)

**CRITICAL:** Must be sorted alphabetically by fully-qualified name:

```zig
const hosted_function_ptrs = [_]builtins.host_abi.HostedFn{
    hostedHostHash,       // Host.hash
    hostedStderrLine,     // Stderr.line!
    hostedStdinLine,      // Stdin.line!
    hostedStdoutLine,     // Stdout.line!
};
```

#### The Complete Mapping

| Roc Call | Interface File | Zig Function |
|----------|---------------|--------------|
| `Host.hash!("foo")` | `Host.roc` | `hostedHostHash` |
| `Stdout.line!("bar")` | `Stdout.roc` | `hostedStdoutLine` |

**Two levels of alphabetical ordering:**
1. **Module level:** `exposes [Host, Stderr, Stdin, Stdout]` in `main.roc`
2. **Function level:** FPA sorted by `Module.function` in `host.zig`

### The Roc API for hosted functions

If you have a hosted function, you can expose it to your Roc API by creating a function type signature that lacks a function definition.  Such hosted function signatures can be created in any Roc platform module, e.g. `platform/Foo.roc` or `platform/Bar.roc`, though a common pattern is to put all hosted functions in `platform/Host.roc`.  The following examples and discussion will use the `platform/Host.roc` pattern, but this is not a requirement.

#### Function Signature Patterns

Hosted functions are defined as records of function signatures:

```roc
# Host.roc
Host := [].{
    ## Effectful function - has side effects or can fail
    do_something! : Str => {}

    ## Pure function - no side effects
    compute : U8, U8 => U8

    ## Return bytes on success, empty list on error
    process_bytes! : List(U8) => List(U8)

    ## Return a string
    get_name! : {} => Str

    ## Return a boolean
    is_valid! : Str => Bool

    ## Multiple arguments
    combine! : Str, U8, Bool => List(U8)
}
```

**Type conventions:**
- `Str` - Strings (text data)
- `List(U8)` - Byte arrays (binary data)
- `Bool` - Boolean values (`true`/`false`)
- `I32`, `U8`, `U64`, etc. - Numeric types
- `{}` - Empty tuple (void/no return value)

**Hosted functions are always effectful:**
- All hosted functions must use the `!` suffix
- They call foreign code that can perform I/O, mutate state, or fail
- Even if a function appears "pure" (like hashing), it's still effectful because it crosses the FFI boundary

**Error handling:**
- Return empty `List(U8)` or empty `Str` on errors
- Return `Bool` for success/failure checks
- No exception types - errors are signaled through return values

**Documentation:**
- Use `##` comments to document each function's behavior
- Include error conditions in documentation
- Note any side effects or performance characteristics
