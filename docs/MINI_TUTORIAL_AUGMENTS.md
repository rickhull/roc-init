# Mini Tutorial Augments

This document augments `mini-tutorial-new-compiler.md` with additional details and clarifications based on the current Roc compiler implementation. These topics complement the mini-tutorial with deeper dives into specific areas.

## Table of Contents

1. [Local vs Module Tag Creation](#local-vs-module-tag-creation)
2. [Signed-Only Numeric Methods](#signed-only-numeric-methods)
3. [The `main!` Return Type Convention](#-the-main-return-type-convention)
4. [Type Definition Variants: `=` vs `:=` vs `::`](#type-definition-variants--vs--)
5. [List Pattern Matching Details](#list-pattern-matching-details)
6. [Common Conversion Gotchas](#common-conversion-gotchas)

---

## Local vs Module Tag Creation

### The Rule

Roc has two different rules for creating tag values depending on whether the type is **local** or **from a module**:

| Context | Local Type | Module Type |
|---------|-----------|-------------|
| **Creating values** | Bare tag everywhere | Module prefix required |
| **Pattern matching** | Bare tag | Bare tag |

### Examples

**Local types** (defined in current file): Use bare tags everywhere

```roc
# Define local type
Color = [Red, Green, Blue]

# Create with bare tag
favorite = Red                # Correct

# Match with bare tag
match favorite {
    Red => "red"              # Correct
    Green => "green"
    Blue => "blue"
}
```

**Module types** (from stdlib or imports): Need prefix to create, bare to match

```roc
# Create with module prefix
result = Try.Ok(42)           # Need Try.Ok
error = Try.Err("failed")     # Need Try.Err

# Match with bare tag
match result {
    Ok(value) => value        # Bare Ok - correct
    Err(msg) => "Error: ${msg}"  # Bare Err - correct
}
```

### Why This Distinction?

Local types are unambiguous - there's only one place they could come from. Module types need the prefix to:
1. Make it clear where the tag comes from (improves code readability)
2. Avoid conflicts when multiple modules define tags with the same name

### Quick Reference

```roc
# Bool is a module type
is_valid = Bool.True          # Need prefix
match is_valid {
    True => "yes"             # Bare in match
    False => "no"
}

# Try is a module type
success = Try.Ok(42)          # Need Try.Ok
match success {
    Ok(v) => v                # Bare Ok
    Err(e) => 0
}

# Local types use bare everywhere
Status = [Ready, Running, Done]
state = Ready                 # Bare is fine
match state {
    Ready => "starting..."    # Bare is fine
    Running => "working..."
    Done => "finished"
}
```

---

## Signed-Only Numeric Methods

### The Issue

Some numeric methods are **only available on signed types** (`I8`, `I16`, `I32`, `I64`, `I128`, `Dec`, `F32`, `F64`) and **not on unsigned types** (`U8`, `U16`, `U32`, `U64`, `U128`).

### Signed-Only Methods

- `negate` - Returns the negated value (e.g., `-5` from `5`)
- `abs` - Returns the absolute value

### Why Unsigned Types Can't Use These

Unsigned types cannot represent negative numbers, so operations that would produce negative values don't make sense:

```roc
# Signed types - negate and abs work fine
num_i64 : I64 = 5
negated = num_i64.negate()    # => -5
absolute = num_i64.abs()      # => 5

# Unsigned types - compile error!
num_u64 : U64 = 5
negated = num_u64.negate()    # COMPILER ERROR: negate not available
absolute = num_u64.abs()      # COMPILER ERROR: abs not available
```

### What About `abs_diff`?

Both signed and unsigned types have `abs_diff`, which computes the absolute difference between two numbers **without overflow**:

```roc
# Works on both signed and unsigned
I64.abs_diff(10, 15)    # => 5  (U64 return type)
U64.abs_diff(10, 15)    # => 5  (U64 return type)

# Handles underflow correctly
U64.abs_diff(5, 10)     # => 5  (would underflow if using 5 - 10)
```

### Practical Impact

If you're working with numeric data and need to use `negate` or `abs`, ensure you're using a signed type:

```roc
# If you need negate/abs, use signed types
score_diff : I64 = calculate_score().negate()

# If you're counting unsigned quantities, avoid negate/abs
byte_count : U64 = bytes.len()
# byte_count.negate()  # This won't work!
```

---

## The `main!` Return Type Convention

### What `main!` Must Return

Every Roc application's `main!` function must return a `Try` type:

```roc
app [main!] { pf: platform "..." }

main! = |_args| {
    Stdout.line!("Hello, World!")
    Ok({})    # Returns Try({}, error)
}
```

### Why an Empty Record?

The return value `Ok({})` uses an empty record `{}` as a placeholder. This is because:

1. **The return type must be `Try`** - Roc applications always return `Try(something, error)`
2. **The value isn't used** - When your program exits, nobody reads the return value
3. **`{}` is simple** - An empty record is the simplest possible value

### Could We Use Other Values?

Yes, but there's no benefit:

```roc
# All valid, but unnecessary
main! = |_args| { Ok(0) }        # Try(I64, error)
main! = |_args| { Ok("done") }   # Try(Str, error)
main! = |_args| { Ok({}) }       # Try({}, error)  # Standard convention
```

### What About Errors?

If `main!` returns an `Err`, the program will exit with an error:

```roc
main! = |_args| {
    result = do_sething()
    match result {
        Ok(val) => Ok({})
        Err(err) => {
            Stderr.line!("Error: ${err}")
            Err(err)  # Program exits with error
        }
    }
}
```

### Type Signature

If you were to write the type explicitly (optional in Roc):

```roc
main! : List(Str) => Try({}, [FileErr, ..])
main! = |_args| {
    Ok({})
}
```

The `_args` parameter is a `List(Str)` containing command-line arguments.

---

## Type Definition Variants: `=` vs `:=` vs `::`

Roc has three ways to define types with different semantics and visibility:

### 1. Structural Type Alias (`=`)

**Use for:** Simple aliases where interchangeability is fine

```roc
# Two aliases for the same type
MyResult = [Ok(Str), Err(Str)]
YourResult = [Ok(Str), Err(Str)]

# These are THE SAME type - can use interchangeably
val : MyResult = Ok("success")
other : YourResult = val  # No error - same type!
```

**Characteristics:**
- Can substitute freely
- Identical structures are the same type
- Good for convenience aliases

### 2. Nominal Type (`:=`)

**Use for:** Wrapper types that need type safety across modules

```roc
# Define distinct types
UserId := [UserId(I64)]
PostId := [PostId(I64)]

# These are DIFFERENT types - can't mix them
get_user : UserId -> Str
get_user = |id|
    match id {
        UserId(num) => "User_${num.to_str()}"
    }

# Compile-time error: can't pass PostId where UserId expected
# get_user(PostId(123))  # TYPE ERROR!
```

**Characteristics:**
- Distinct type even if structure is identical
- **Public:** Can be used from other modules
- Prevents mixing up different semantic types
- Good for IDs, wrappers, domain types

### 3. Opaque Type (`::`)

**Use for:** Implementation details you want to hide

```roc
# Only visible in this module
SecretDigest :: List(U8)

# Public API uses the type
hash = compute_digest()

# But outside this module, SecretDigest is opaque
# Users can pass it around but can't inspect its contents
```

**Characteristics:**
- Nominal (distinct from identical structures)
- **Module-private:** Can only be used within the defining module
- Good for hiding implementation details
- Users of your module can see the type exists but can't access its structure

### Which Should You Use?

| Situation | Use | Example |
|-----------|-----|---------|
| Convenience alias | `=` | `type Path = Str` |
| Domain-specific wrapper (public) | `:=` | `UserId := [UserId(I64)]` |
| Hidden implementation detail | `::` | `InternalState :: List(U8)` |

### Practical Example

```roc
# Public API types (:=)
UserId := [UserId(I64)]
SessionId := [SessionId(U64)]

# Can't accidentally use a SessionId where a UserId is expected
lookup_user : UserId -> Str
lookup_user = |id|
    match id {
        UserId(num) => get_user_by_id(num)
        # SessionId would be a compile error here
    }

# Internal state (hidden from other modules)
DatabaseConnection :: [Connected(Handle), Disconnected]

# Within this module, we can match on it
connect! : => DatabaseConnection
connect! = || {
    handle = open_database_handle()
    Connected(handle)
}

# Outside the module, users can't see the Connected/Disconnected tags
```

---

## List Pattern Matching Details

### The `..` Spread Operator

The `..` operator in list patterns matches zero or more elements:

```roc
match animals {
    ["bird", "crab", "lizard"] => 10              # Exact match
    ["bird", "crab", ..] => 5                     # Starts with bird, crab
    ["bird", ..] => 1                             # Starts with bird
    [first, second, ..] => count(first, second)  # First two elements
    _ => 0                                        # Default
}
```

### Position of `..`

The `..` can appear at the **end only** (as of the current implementation):

```roc
# Valid - .. at the end
[first, second, ..] => ...

# Valid - .. alone
[1, 2, 3, ..] => ...

# Also valid - comma before .. is optional
[first, second, .. ] => ...

# NOT valid - .. in middle (not yet implemented)
# [1, .., 10] => ...
```

### Capturing the Rest

You can give `..` a name to capture the remaining elements:

```roc
match numbers {
    [first, ..as rest] => {
        # first = 1
        # rest = [2, 3, 4, 5]
        "First: ${first.to_str()}, Rest: ${rest.to_str()}"
    }
}
```

### Multiple Patterns

You can use multiple list patterns with different `..` positions in the same match:

```roc
describe_list = |nums|
    match nums {
        [] => "empty"
        [x] => "one: ${x.to_str()}"
        [x, y] => "two: ${x.to_str()}, ${y.to_str()}"
        [x, y, z, ..] => "starts with ${x.to_str()}, ${y.to_str()}, ${z.to_str()}"
    }
```

---

## Common Conversion Gotchas

### Converting Anything to String

**Wrong:** `Num.to_str(42)` - doesn't exist in new compiler

**Right:** Use the appropriate method

```roc
# For numbers specifically
num_str = 42.to_str()           # => "42"

# For any value
any_str = Str.inspect(42)       # => "42"
any_str = Str.inspect([1, 2])   # => "[1, 2]"

# For string interpolation (automatically converts)
result = "Answer: ${42}"        # => "Answer: 42"
```

### Str.from_utf8 vs Str.from_utf8_lossy

When converting bytes to strings:

```roc
bytes = [72, 101, 108, 108, 111]  # "Hello" in UTF-8

# Strict - returns Try(Str, BadUtf8)
strict = Str.from_utf8(bytes)
match strict {
    Ok(s) => Stdout.line!(s)
    Err(BadUtf8) => Stdout.line!("Invalid UTF-8!")
}

# Lossy - replaces invalid sequences with replacement character
lossy = List(U8).from_utf8_lossy(bytes)  # Always returns Str
```

### Numeric Parse Errors

Parsing strings to numbers returns `Try` with specific errors:

```roc
match I64.from_str("42") {
    Ok(num) => num
    Err(BadNumStr) => 0  # Invalid number format
}
```

Different numeric types may have different error tags - always check the type signature!

---

## Summary

This document covered:

1. ✅ **Local vs module tag creation** - When to use prefixes
2. ✅ **Signed-only methods** - `negate` and `abs` only on signed types
3. ✅ **`main!` return type** - Why `Ok({})` is the convention
4. ✅ **Type definition variants** - `=`, `:=`, and `::`
5. ✅ **List pattern matching** - How `..` works
6. ✅ **Common conversion gotchas** - String conversion best practices

For complete reference:
- `docs/Builtin.roc` - All builtin functions
- `docs/all_syntax_test.roc` - Comprehensive syntax examples
- `mini-tutorial-new-compiler.md` - Full tutorial
