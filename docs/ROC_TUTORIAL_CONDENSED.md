# Roc Tutorial - Condensed (New Compiler Syntax)

> ⚠️ **DEPRECATED** - This document has been superseded.
>
> **Use instead:**
> - `mini-tutorial-new-compiler.md` - Primary tutorial (upstream)
> - `MINI_TUTORIAL_AUGMENTS.md` - Advanced topics and practical examples
> - `GOTCHAS.md` - Common pitfalls and gotchas
>
> **The `roc-language` skill still uses this file for eager-loading.**
> **This file is kept for that purpose but will not be updated.**

---

> **Condensed reference** - For complete coverage, see `docs/Builtin.roc`, `docs/all_syntax_test.roc`, and `MINI_TUTORIAL_AUGMENTS.md`

## Table of Contents

1. [Bool & Conditionals](#bool--conditionals)
2. [Numbers](#numbers)
3. [Strings](#strings)
4. [Lists](#lists)
5. [Tag Unions](#tag-unions)
6. [Pattern Matching](#pattern-matching)
7. [Try (Error Handling)](#try-error-handling)
8. [Effectful Functions](#effectful-functions)
9. [Common Gotchas](#common-gotchas)

---

## Bool & Conditionals

### Bool Values

**Creating values:** `Bool.True` / `Bool.False` (capitalized, with prefix)

**Pattern matching:** `True` / `False` (capitalized, no prefix)

```roc
is_active = Bool.True
match is_active {
    True => "yes"
    False => "no"
}
```

### if/else

The new compiler uses `if/else` (NOT `if/then/else`):

```roc
one_line = if num == 1 "One" else "NotOne"

multi_line =
    if num == 2
        "Two"
    else if num == 3
        "Three"
    else
        "Other"
```

---

## Numbers

### Integer Types

```roc
# Unsigned: U8, U16, U32, U64, U128
# Signed: I8, I16, I32, I64, I128

inferred = 42           # I64 by default
u8_val : U8 = 255
i64_val : I64 = -42
hex = 0xFF              # => 255
```

### Operations

```roc
# Arithmetic
sum = 10 + 5
diff = 10 - 5
div = 10.0 / 5.0        # F64 or Dec
div_trunc = 10 // 3     # => 3
rem = 10 % 3            # => 1

# Comparisons
eq = 10 == 5            # => Bool.False
gt = 10 > 5             # => Bool.True

# Conversions (example with U64)
to_u64 = u8.to_u64()           # Safe widening
try_u8 = u64.to_u8_try()       # Try(U8, [OutOfRange, ..])
wrap_u8 = u64.to_u8_wrap()     # Wraps around
```

---

## Strings

```roc
# Literals
greeting = "Hello, ${name}!"     # Interpolation
multiline =
    \\Line 1
    \\Line 2
unicode = "\u(20AC)"             # Euro sign

# Core operations
"hello".concat(" world")         # => "hello world"
"".is_empty()                    # => Bool.True
"  spaces  ".trim()              # => "spaces"
"a,b,c".split_on(",")            # => ["a", "b", "c"]
"hello".to_utf8()                # => [104, 101, 108, 108, 111]
List(U8).from_utf8_lossy(bytes)  # Back to Str
```

---

## Lists

### Type Application Syntax

**NEW:** Use `List(Type)` with parentheses:

```roc
numbers : List(I64) = [1, 2, 3]
bytes : List(U8) = [0, 1, 2]

# WRONG - old syntax
# numbers : List I8 = [1, 2, 3]
```

### Core Operations

```roc
# Basic
[1, 2, 3].len()              # => 3
[1, 2, 3].is_empty()         # => Bool.False
[1, 2, 3].first()            # => Ok(1)
[].first()                   # => Err(ListWasEmpty)
[1, 2, 3].get(1)             # => Ok(2)

# Combining
[1, 2].concat([3, 4])        # => [1, 2, 3, 4]
[1, 2].append(3)             # => [1, 2, 3]

# Transforming
[1, 2, 3].map(|n| n * 2)     # => [2, 4, 6]
[1, 2, 3, 4].keep_if(|n| n % 2 == 0)  # => [2, 4]
[1, 2, 3, 4].drop_if(|n| n % 2 == 0)  # => [1, 3]
[1, 2, 3, 4].fold(0, |acc, n| acc + n)  # => 10
```

---

## Tag Unions

Tag unions represent enumerated types with optional data:

```roc
# Define (using = for structural type)
Color = [Red, Green, Blue]

# Local types: bare tags everywhere
favorite = Red
match favorite {
    Red => "red"
    Green => "green"
    Blue => "blue"
}

# Tags with data
Result = [Success(Str), Error(Str), Pending]
match Success("Done") {
    Success(msg) => "✓ ${msg}"
    Error(err) => "✗ ${err}"
    Pending => "..."
}
```

### Local vs Module Types

```roc
# Local type definition
Color = [Red, Green, Blue]
fav = Red                     # Bare tag
match fav { Red => "red" }    # Bare tag

# Module type (like Try)
result = Try.Ok(42)           # Need Try.Ok
match result {
    Ok(v) => "ok"            # Bare Ok in match
    Err(e) => "err"
}
```

**Rule of thumb:** Local types use bare tags everywhere. Module types need prefix to create, bare in patterns.

### Type Definitions: `=` vs `:=` vs `::`

Roc has three ways to define types with different semantics:

```roc
# 1. Structural type alias (=)
# - Can substitute freely - identical types are interchangeable
MyResult = [Ok(Str), Err(Str)]
YourResult = [Ok(Str), Err(Str)]
# MyResult and YourResult are THE SAME type

# 2. Nominal type (:=)
# - Distinct type even if structure is identical
# - Public: can be used from other modules
MyBytes := [Wrapped(List(U8))]
YourBytes := [Wrapped(List(U8))]
# MyBytes and YourBytes are DIFFERENT types

# 3. Opaque type (::)
# - Nominal AND module-private
# - Can only be used within the module where it's defined
SecretDigest :: List(U8)  # Only visible in this module
```

**When to use each:**

- **Use `=`** for simple aliases where interchangeability is fine
- **Use `:=`** for wrapper types that need type safety across modules
- **Use `::`** for implementation details you want to hide from other modules

**Example with `:=` (public wrapper type):**

```roc
# Define (public, can be used from other modules)
UserId := [UserId(I64)]
PostId := [PostId(I64)]

# Prevents mixing up different ID types
get_user : UserId -> Str
get_user = |id|
    match id {
        UserId(num) => "User_${num.to_str()}"
    }

# Compile-time error: can't pass PostId where UserId expected!
# get_user(PostId(123))  # TYPE ERROR
```

---

## Pattern Matching

```roc
# Basic
describe = |n|
    match n {
        0 => "zero"
        1 => "one"
        _ => "many"          # _ matches anything
    }

# List patterns
match_list = |lst|
    match lst {
        [] => "empty"
        [x] => "single: ${x.to_str()}"
        [1, 2, ..] => "starts with 1, 2"
        [1, ..as tail] => "starts with 1"
        _ => "other"
    }

# Tuple destructuring
(num, str) = (42, "hello")  # num = 42, str = "hello"

# Record destructuring
{ name, age } = { name: "Alice", age: 30 }
```

---

## Try (Error Handling)

The NEW compiler uses `Try(ok, err)`:

### Creating & Matching

```roc
# Creating (with module prefix)
success = Try.Ok(42)
error = Try.Err("something failed")

# Pattern matching (bare tags)
describe = |result|
    match result {
        Ok(value) => "Success: ${value.to_str()}"
        Err(msg) => "Error: ${msg}"
    }
```

### Working with Try

```roc
# Check status
Try.is_ok(success)           # => Bool.True
Try.is_err(error)            # => Bool.True

# Unwrap with fallback
Try.ok_or(success, 0)        # => 42
Try.ok_or(error, 0)          # => 0

# Mapping
Try.map_ok(success, |n| n * 2)      # => Ok(84)
Try.map_err(error, |e| "Err: ${e}")  # => Err("Err: something failed")
```

---

## Effectful Functions

Functions with side effects are marked with `!` and use `=>`:

```roc
# Pure function
add : I64, I64 -> I64
add = |a, b| a + b

# Effectful function
log_and_add! : I64, I64 => I64
log_and_add! = |a, b| {
    Stdout.line!("Adding ${a.to_str()} and ${b.to_str()}")
    a + b
}

# In app
app [main!] { pf: platform "./platform/main.roc" }

main! = |_args| => {
    log_and_add!(1, 2)
    Ok({})
}
```

---

## Summary: Key Changes from Old Compiler

| Old | New |
|-----|-----|
| `List U8` | `List(U8)` |
| `if/then/else` | `if/else` |
| `true`/`false` | `Bool.True`/`Bool.False` |
| `Result` | `Try(ok, err)` |
| `Num.to_str` | `Str.inspect` or `num.to_str()` |
| `->` (effectful) | `=>` (effectful) |

### Best Practices

1. **Always verify** against `docs/Builtin.roc` - online docs may be outdated
2. **Use Try** for error handling - it's the standard
3. **Leverage pattern matching** - more powerful than if/else chains
4. **Use `=>`** for effectful functions - makes side effects explicit

---

**For complete coverage:** See `docs/Builtin.roc` and `docs/all_syntax_test.roc`
