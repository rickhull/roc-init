---
name: roc-language
description: "Authoritative Roc programming language reference. When Claude needs to read, write, edit, debug, or analyze any .roc file, or understand Roc syntax, types, or compiler errors. Provides current API reference and syntax patterns using Roc compiler source as ground truth."
version: 1.0.0
---

# Roc Language

## Critical Notes

**WARNING: Outdated Documentation Exists**
- Many online tutorials reference the old Rust-based Roc compiler
- Current Roc uses different builtin functions than old docs show
- Common old-vs-new pitfalls:

| Old (Wrong) | New (Correct) | Notes |
|-------------|---------------|-------|
| `Num.to_str(42)` | `Str.inspect(42)` or `42.to_str()` | Builtin conversion changed |
| `List U8` | `List(U8)` | Type params need parentheses |
| `if x then y else z` | `if x y else z` | No `then` keyword |
| `true` / `True` | `Bool.True` | Module-qualified for creation |
| `Err(WasEmpty)` | `Err(ListWasEmpty)` | Error tags are more specific |

## Quick Reference

### App Structure
```roc
app [main!] { pf: platform "https://..." }

import pf.Stdout

main! = |_args| {
    Stdout.line!("Hello, World!")
    Ok({})
}
```

### Common Patterns
```roc
# Effectful functions use ! and => arrow
greet! : Str => Result({}, _)
greet! = |name| {
    Stdout.line!("Hello, ${name}!")
    Ok({})
}

# Pattern matching
match my_list.first() {
    Ok(val) => val
    Err(ListWasEmpty) => default_value
}

# Pure functions use -> arrow
add : I64, I64 -> I64
add = |a, b| a + b
```

## Debugging Roc Compiler Errors

1. Read the error message — the new compiler gives specific, helpful errors
2. Check the Critical Notes table above for old-vs-new syntax mismatches
3. Search @references/GOTCHAS.md for the error pattern or function name
4. Look up the correct API in @references/Builtin.roc
5. Verify the fix compiles with `roc check <file>.roc`
6. If check fails, return to step 2 and iterate until it passes

## Eager Load

Always read in full:

- Mini Tutorial: @references/mini-tutorial-new-compiler.md (~700 lines, 28KB)
- Gotchas: @references/GOTCHAS.md (~200 lines, 8KB)

## Lazy Load

Search or read as necessary:

- Mini Tutorial Augments: references/MINI_TUTORIAL_AUGMENTS.md (~1100 lines, 28KB)
- Builtin Reference: references/Builtin.roc (~1500 lines, 48KB)
- Syntax Reference: references/all_syntax_test.roc (~400 lines, 12KB)
- Language Reference Tutorial: references/ROC_LANGREF_TUTORIAL.md (~2200 lines, 44KB)
