# Roc Gotchas - Common Pitfalls and How to Avoid Them

This document consolidates the most common gotchas when working with Roc's new compiler. These are differences from the old compiler, typical mistakes, and confusing aspects that trip up newcomers.

**Quick reference** - See also: [ROC_TUTORIAL_CONDENSED.md](ROC_TUTORIAL_CONDENSED.md), [mini-tutorial-new-compiler.md](mini-tutorial-new-compiler.md)

---

## Table of Contents

1. [Type Application Syntax](#1-type-application-syntax)
2. [if/else vs if/then/else](#2-ifelse-vs-ifthenelse)
3. [Bool: Creation vs Pattern Matching](#3-bool-creation-vs-pattern-matching)
4. [Local vs Module Tag Creation](#4-local-vs-module-tag-creation)
5. [String Conversion](#5-string-conversion)
6. [Signed-Only Numeric Methods](#6-signed-only-numeric-methods)
7. [Error Tag Names](#7-error-tag-names)
8. [Record Syntax](#8-record-syntax)
9. [List Literals](#9-list-literals)
10. [Function Calls and Returns](#10-function-calls-and-returns)
11. [Effectful Function Types](#11-effectful-function-types)

---

## 1. Type Application Syntax

**OLD:** `List U8` (space, no parentheses)
**NEW:** `List(U8)` (parentheses required)

### Wrong ❌
```roc
bytes : List U8 = [0, 1, 2]  # OLD SYNTAX - doesn't work
```

### Right ✅
```roc
bytes : List(U8) = [0, 1, 2]  # NEW SYNTAX - parentheses required
numbers : List(I64) = [1, 2, 3]
```

**Why:** The new compiler requires parentheses around type parameters for consistency and to avoid parsing ambiguity.

---

## 2. if/else vs if/then/else

**OLD:** `if/then/else` (doesn't exist in new compiler)
**NEW:** `if/else`

### Wrong ❌
```roc
result = if x > 0 then "positive" else "negative"  # THEN doesn't exist
```

### Right ✅
```roc
# One-line
result = if x > 0 "positive" else "negative"

# Multi-line
result =
    if x > 0
        "positive"
    else if x == 0
        "zero"
    else
        "negative"

# With blocks
result =
    if x > 0 {
        "positive"
    } else {
        "negative"
    }
```

**Why:** The new compiler simplified the syntax. Every `if` must have an `else` branch.

---

## 3. Bool: Creation vs Pattern Matching

**Gotcha:** Module types use prefix to create, bare tags in patterns.

### Creating Bool Values
Use `Bool.True` and `Bool.False` (lowercase t/f, with module prefix):

```roc
is_valid = Bool.True    # Correct - use prefix
is_disabled = Bool.False

# These are wrong:
# is_valid = true        # Wrong
# is_valid = True        # Wrong (no prefix for creation)
```

### Pattern Matching on Bool
Use bare `True` and `False` (capitalized, no prefix):

```roc
match is_valid {
    True => "yes"       # Correct - capitalized, no prefix
    False => "no"
}
```

### Key Distinction
```roc
# Creation
value = Bool.True       # Need Bool.True

# Matching
match value {
    True => "yes"       # Bare True in match
    False => "no"
}
```

**Why:** This is consistent with all module types - prefix to create, bare tags in patterns.

---

## 4. Local vs Module Tag Creation

**Gotcha:** Local types use bare tags everywhere. Module types need prefix to create, bare in patterns.

### Local Type Definitions
```roc
# Define local type
Color = [Red, Green, Blue]

# Create with bare tag
favorite = Red                # Correct - bare is fine

# Match with bare tag
match favorite {
    Red => "red"              # Correct - bare is fine
    Green => "green"
    Blue => "blue"
}
```

### Module-Defined Types
```roc
# Create with module prefix
result = Try.Ok(42)           # Need Try.Ok to create
error = Try.Err("failed")     # Need Try.Err to create

# Match with bare tags
match result {
    Ok(value) => value        # Bare Ok - correct
    Err(msg) => "Error: ${msg}"  # Bare Err - correct
}
```

### Rule of Thumb
- **Local types** (defined in current file): Bare tags everywhere
- **Module types** (from stdlib or imports): Prefix to create, bare in match

---

## 5. String Conversion

**OLD:** `Num.to_str(42)` (doesn't exist in new compiler)
**NEW:** `Str.inspect(value)` or specific type methods

### Wrong ❌
```roc
num_str = Num.to_str(42)  # WRONG - Num.to_str doesn't exist
```

### Right ✅
```roc
# For specific numeric types
num_str = 42.to_str()         # => "42" (I64.to_str)
num_str = 42.0.to_str()       # => "42" (Dec/F64.to_str)

# For any value (general purpose)
num_str = Str.inspect(42)     # => "42"
list_str = Str.inspect([1, 2, 3])  # => "[1, 2, 3]"
bool_str = Str.inspect(Bool.True)  # => "True"

# For string interpolation (automatic)
result = "Answer: ${42}"      # => "Answer: 42"
greeting = "Hello, ${name}"   # name must be Str already
```

**Why:** `Num.to_str` was too generic. The new compiler has specific methods on each type, plus `Str.inspect` for debugging.

### String Interpolation Gotcha
String interpolation does NOT auto-convert to string:

```roc
num = 42

# Wrong - interpolation doesn't convert
# result = "The number is ${num}"  # ERROR

# Right - convert explicitly
result = "The number is ${num.to_str()}"  # OK
result = "The number is ${Str.inspect(num)}"  # OK
```

---

## 6. Signed-Only Numeric Methods

**Gotcha:** Some methods only work on signed types, not unsigned.

### Methods That Require Signed Types
- `negate` - Returns the negated value
- `abs` - Returns the absolute value

### Wrong ❌
```roc
count : U64 = 5
negated = count.negate()  # COMPILER ERROR - negate not available on U64
absolute = count.abs()    # COMPILER ERROR - abs not available on U64
```

### Right ✅
```roc
# Use signed types if you need negate/abs
num : I64 = 5
negated = num.negate()    # => -5
absolute = num.abs()      # => 5

# For unsigned types, use abs_diff if needed
count : U64 = 5
diff = U64.abs_diff(count, 10)  # => 5 (no underflow)
```

### Why?
Unsigned types can't represent negative numbers, so operations that produce negatives don't make sense.

---

## 7. Error Tag Names

**Gotcha:** Error tags are more specific in the new compiler.

### List.first()
```roc
# Wrong (old compiler)
match numbers.first() {
    Ok(first) => first
    Err(WasEmpty) => 0  # WRONG - old error tag
}

# Right (new compiler)
match numbers.first() {
    Ok(first) => first
    Err(ListWasEmpty) => 0  # Correct - specific tag
}
```

### Numeric Parsing
```roc
# Wrong
match I64.from_str("42") {
    Ok(num) => num
    Err(ParseFailed) => 0  # WRONG - doesn't exist
}

# Right
match I64.from_str("42") {
    Ok(num) => num
    Err(BadNumStr) => 0  # Correct error tag
}
```

### Why?
More specific error tags let you distinguish between different error types in pattern matching.

---

## 8. Record Syntax

### Field Access
Records use dot notation for field access:

```roc
person = { name: "Alice", age: 30 }

name = person.name  # => "Alice"
age = person.age    # => 30
```

### Record Update
Create updated copies using spread syntax:

```roc
person = { name: "Alice", age: 30 }

# Create new record with updated age
older_person = { ..person, age: 31 }  # => { name: "Alice", age: 31 }
```

### Destructuring
```roc
# Destructure in match
match person {
    { name, age } => "Name: ${name}, Age: ${age.to_str()}"
}

# Destructure in assignment
{ name, age } = person

# Destructure in function parameters
get_name = |{ name }| name
get_name(person)  # => "Alice"
```

---

## 9. List Literals

### Empty Lists Need Type Annotation
```roc
# Empty list needs type annotation
empty : List(I64) = []

# Non-empty lists infer type
numbers = [1, 2, 3]  # List(I64)

# You can also annotate non-empty lists
bytes : List(U8) = [0, 1, 2]
```

### Why?
The compiler can't infer the type of an empty list - it could be `List(I64)`, `List(Str)`, `List(Bool)`, etc.

---

## 10. Function Calls and Returns

### All Functions Use Parentheses
```roc
# Correct - always use parentheses
result = my_func(arg1, arg2)

# Wrong - no Ruby-style standalone calls
# result = my_func arg1, arg2
```

### Return Statements
Use `return` for early returns, otherwise the last expression is returned implicitly:

```roc
calculate = |x|
    if x < 0 {
        return 0  # Early return
    }

    x * 2  # Implicit return
```

### Destructuring in Parameters
```roc
# Destructure tuples directly
add_pair = |(a, b)| a + b

# With explicit type annotation
add_pair_typed : (I64, I64) -> I64
add_pair_typed = |(a, b)| a + b

# Destructure records
get_name = |{ name }| name

person = { name: "Alice", age: 30 }
get_name(person)  # => "Alice"
```

---

## 11. Effectful Function Types

**OLD:** `->` for all functions
**NEW:** `->` for pure, `=>` for effectful

### Pure Functions
Use thin arrow `->`:

```roc
add : I64, I64 -> I64
add = |a, b| a + b
```

### Effectful Functions
Use thick arrow `=>`:

```roc
# Effectful function type
log_and_add! : I64, I64 => I64
log_and_add! = |a, b| {
    Stdout.line!("Adding ${a.to_str()} and ${b.to_str()}")
    a + b
}

# In app context
app [main!] { pf: platform "..." }

main! : List(Str) => Try({}, [..])
main! = |_args| {
    Stdout.line!("Hello!")
    Ok({})
}
```

### Why?
The `=>` makes side effects explicit in the type signature, improving code readability and reasoning.

---

## Summary: Key Changes from Old Compiler

| Old | New | Notes |
|-----|-----|-------|
| `List U8` | `List(U8)` | Parentheses required |
| `if/then/else` | `if/else` | No `then` keyword |
| `true`/`false` | `Bool.True`/`Bool.False` | Module prefix for creation |
| `Result(ok, err)` | `Try(ok, err)` | Different name |
| `Num.to_str(x)` | `Str.inspect(x)` or `x.to_str()` | Type-specific methods |
| `->` (effectful) | `=>` (effectful) | Explicit effect typing |
| `Err(WasEmpty)` | `Err(ListWasEmpty)` | More specific error tags |

---

## Best Practices

1. **Always verify** against `docs/Builtin.roc` - online docs may be outdated
2. **Use Try** for error handling - it's the standard pattern
3. **Leverage pattern matching** - more powerful than if/else chains
4. **Use `=>`** for effectful functions - makes side effects explicit
5. **Check type annotations** - they help catch gotchas at compile time

---

## Related Documentation

- [mini-tutorial-new-compiler.md](mini-tutorial-new-compiler.md) - Full tutorial from upstream
- [ROC_TUTORIAL_CONDENSED.md](ROC_TUTORIAL_CONDENSED.md) - Quick reference guide
- [MINI_TUTORIAL_AUGMENTS.md](MINI_TUTORIAL_AUGMENTS.md) - Supplementary deep dives
- [ROC_LANGREF_TUTORIAL.md](ROC_LANGREF_TUTORIAL.md) - Complete language reference
- [Builtin.roc](Builtin.roc) - All builtin functions reference
- [all_syntax_test.roc](all_syntax_test.roc) - Comprehensive syntax examples
