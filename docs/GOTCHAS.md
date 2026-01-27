# Roc Gotchas (Condensed)

Quick reference for common pitfalls in Roc's new compiler.

---

## Quick Reference

| Gotcha | Wrong | Right |
|--------|-------|-------|
| **Type Application** | `List U8` | `List(U8)` |
| **if/else** | `if x then y else z` | `if x y else z` |
| **Bool Creation** | `true`, `True` | `Bool.True` |
| **Bool Matching** | `Bool.True` | `True` (bare) |
| **String Convert** | `Num.to_str(42)` | `Str.inspect(42)` or `42.to_str()` |
| **Error Tags** | `Err(WasEmpty)` | `Err(ListWasEmpty)` |
| **Effectful Type** | `-> I64` | `=> I64` |
| **Unsigned negate** | `num.negate()` on U64 | Use signed type (I64) |
| **List.repeat** | `List.pad` or manual loop | `List.repeat(item, n)` |

---

## Expanded Details

### Type Application Syntax

The new compiler requires parentheses around type parameters. Use `List(U8)` instead of `List U8`.

```roc
# Wrong:
bytes : List U8 = [0, 1, 2]

# Right:
bytes : List(U8) = [0, 1, 2]
numbers : List(I64) = [1, 2, 3]
dict : Dict(Str, I64) = {}
```

### if/else (no `then` keyword)

The new compiler simplified conditional syntax. Every `if` must have an `else` branch, and `then` doesn't exist.

```roc
# Wrong:
result = if x > 0 then "positive" else "negative"

# Right: (one-line)
result = if x > 0 "positive" else "negative"

# Multi-line
result =
    if x > 0
        "positive"
    else if x == 0
        "zero"
    else
        "negative"
```

### Bool: Creation vs Pattern Matching

Module types require the prefix when creating values, but use bare tags in pattern matching.

```roc
# Creation - need prefix
is_valid = Bool.True
is_disabled = Bool.False

# Pattern matching - bare, capitalized
match is_valid {
    True => "yes"
    False => "no"
}
```

### Local vs Module Tag Creation

Local types (defined in your file) use bare tags everywhere. Module types need prefix to create, bare in patterns.

```roc
# Local type - bare everywhere
Color = [Red, Green, Blue]
favorite = Red              # Bare to create
match favorite { Red => }    # Bare to match

# Module type - prefix to create, bare to match
result = Try.Ok(42)         # Try.Ok to create
match result {
    Ok(value) => value      # Bare Ok in match
}
```

### String Conversion

`Num.to_str` doesn't exist. Use type-specific methods like `42.to_str()` or `Str.inspect()` for any value.

```roc
# Wrong:
num_str = Num.to_str(42)

# Right:
num_str = 42.to_str()              # "42" (I64 method)
any_str = Str.inspect([1, 2, 3])   # "[1, 2, 3]" (any value)

# String interpolation needs explicit conversion
result = "Number: ${42.to_str()}"  # NOT ${42}
```

### Signed-Only Numeric Methods

`negate` and `abs` only work on signed types (I64, I128, Dec, F64). Unsigned types (U64, U128) can't represent negatives.

```roc
# Wrong:
count : U64 = 5
neg = count.negate()    # COMPILER ERROR

# Right:
num : I64 = 5
neg = num.negate()      # => -5
abs = num.abs()         # => 5

# For unsigned types, use abs_diff
diff = U64.abs_diff(5, 10)  # => 5 (no underflow)
```

### Error Tag Names

Error tags are more specific in the new compiler. `WasEmpty` is now `ListWasEmpty`, `ParseFailed` is now `BadNumStr`.

```roc
# List.first() errors
match numbers.first() {
    Ok(first) => first
    Err(ListWasEmpty) => 0    # WasEmpty -> ListWasEmpty
}

# Numeric parsing
match I64.from_str("42") {
    Ok(num) => num
    Err(BadNumStr) => 0       # ParseFailed -> BadNumStr
}
```

### Effectful Function Types

Pure functions use thin arrow `->`, effectful functions use thick arrow `=>`. This makes side effects explicit in type signatures.

```roc
# Pure function
add : I64, I64 -> I64
add = |a, b| a + b

# Effectful function
main! : List(Str) => Try({}, [..])
main! = |_args| {
    Stdout.line!("Hello!")
    Ok({})
}
```

### List Creation Helpers

Use `List.repeat(item, n)` to create a list with n copies of an element. Empty lists need type annotations since the compiler can't infer the type.

```roc
# Repeat an element
List.repeat(0, 5)    # => [0, 0, 0, 0, 0]
List.repeat("x", 3)  # => ["x", "x", "x"]

# Empty lists need type annotation
empty : List(I64) = []

# Non-empty lists infer type automatically
numbers = [1, 2, 3]  # List(I64)
```

### Record Syntax

Records use dot notation for field access, spread syntax for updates, and support destructuring in assignments and function parameters.

```roc
person = { name: "Alice", age: 30 }

# Access
name = person.name

# Update (creates new record, doesn't modify original)
older = { ..person, age: 31 }

# Destructure
{ name, age } = person
get_name = |{ name }| name
```

---

## Related Docs

- [mini-tutorial-new-compiler.md](mini-tutorial-new-compiler.md) - Primary tutorial
- [Builtin.roc](Builtin.roc) - Complete builtin reference
- [MINI_TUTORIAL_AUGMENTS.md](MINI_TUTORIAL_AUGMENTS.md) - Advanced topics
