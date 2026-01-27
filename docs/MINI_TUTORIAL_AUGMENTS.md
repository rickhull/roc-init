# Mini Tutorial Augments

This document augments `mini-tutorial-new-compiler.md` with additional details and clarifications based on the current Roc compiler implementation. These topics complement the mini-tutorial with deeper dives into specific areas.

## Table of Contents

1. [Local vs Module Tag Creation](#local-vs-module-tag-creation)
2. [Open/Extensible Tag Unions](#opnextensible-tag-unions)
3. [Multiple Payloads](#multiple-payloads)
4. [Nested Patterns](#nested-patterns)
5. [Number Literals](#number-literals)
6. [List Transformations](#list-transformations)
7. [Try Mapping and Chaining](#try-mapping-and-chaining)
8. [Signed-Only Numeric Methods](#signed-only-numeric-methods)
9. [The `main!` Return Type Convention](#-the-main-return-type-convention)
10. [Type Definition Variants: `=` vs `:=` vs `::`](#type-definition-variants--vs--)
11. [List Pattern Matching Details](#list-pattern-matching-details)
12. [Common Conversion Gotchas](#common-conversion-gotchas)
13. [Practical Examples](#practical-examples)
14. [Key Changes from Old Compiler](#key-changes-from-old-compiler)

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

## Open/Extensible Tag Unions

### The `..` Syntax for Extensibility

Tag unions can be **open** or **closed**. Use `..` to indicate an extensible tag union that accepts additional tags beyond those explicitly listed:

```roc
# This function accepts any tag union containing at least Red and Green
is_primary : [Red, Green, ..] -> Bool
is_primary = |color|
    match color {
        Red => Bool.True
        Green => Bool.True
        _ => Bool.False
    }

# Can pass Blue even though it's not explicitly listed
Color = [Red, Green, Blue]
is_primary(Blue)  # => Bool.False
```

### Type Aliases for Extensible Unions

You can create polymorphic type aliases for extensible unions:

```roc
# Define an extensible tag union type parameter
Letters(others) : [A, B, ..others]

# Use the type alias with specific extensions
letter_to_str : Letters([C, D]) -> Str
letter_to_str = |letter|
    match letter {
        A => "A"
        B => "B"
        _ => "other"  # Matches C or D
    }

letter_to_str(C)  # => "other"
```

### Why Use Extensible Unions?

Extensible unions enable:
- **Polymorphism** - Functions work with multiple related tag types
- **Forward compatibility** - Add new tags without breaking existing code
- **Flexible APIs** - Accept extensions in user code

### Closed vs Open

```roc
# Closed - only accepts exactly these three colors
ClosedColor = [Red, Green, Blue]

# Open - accepts these plus any others
OpenColor = [Red, Green, Blue, ..]
```

---

## Multiple Payloads

### Tags with Multiple Fields

Tags can hold multiple values (not just one):

```roc
# Tags can have multiple fields
Person = [Name(Str, Str), Anonymous]

person = Name("Alice", "Smith")

describe_person = |person|
    match person {
        Name(first, last) => "Person: ${first} ${last}"
        Anonymous => "Anonymous"
    }

describe_person(person)  # => "Person: Alice Smith"
```

### Practical Use Cases

Multiple payloads are useful when:
- A tag naturally carries related data (first/last name, x/y coordinates)
- You want to keep related values together
- You're modeling tuples as tagged unions

```roc
# Example: 2D coordinates
Point = [Coord2D(I64, I64), Coord3D(I64, I64, I64)]

origin = Coord2D(0, 0)

describe = |point|
    match point {
        Coord2D(x, y) => "2D: (${x.to_str()}, ${y.to_str()})"
        Coord3D(x, y, z) => "3D: (${x.to_str()}, ${y.to_str()}, ${z.to_str()})"
    }
```

---

## Nested Patterns

### Matching Nested Structures

You can destructure nested structures directly in patterns:

```roc
# Match nested Try values in a list
data = [Ok(42), Err("oops")]

result = match data {
    [] => "empty list"
    [Ok(num), ..] => "First is OK: ${num.to_str()}"
    [Err(msg), ..] => "First is Err: ${msg}"
}

result  # => "First is OK: 42"
```

### Deep Nesting

Patterns can nest arbitrarily deep:

```roc
# Nested records and tags
Info = [Info({ name: Str, age: I64 }), Missing]

person = Info({ name: "Alice", age: 30 })

extract = |info|
    match info {
        Info({ name, .. }) => "Name: ${name}"  # Only extract name, ignore rest
        Missing => "No info"
    }

extract(person)  # => "Name: Alice"
```

### Nested List Patterns

```roc
# Match lists within lists
matrix = [[1, 2], [3, 4]]

result = match matrix {
    [[a, b], [c, d]] => "${a.to_str()}, ${b.to_str()}, ${c.to_str()}, ${d.to_str()}"
    _ => "other"
}

result  # => "1, 2, 3, 4"
```

---

## Number Literals

### Literal Formats

Roc supports multiple number literal formats:

```roc
# Type inference (defaults to I64)
inferred = 42

# Explicit types
explicit_u8 : U8 = 42
explicit_i64 : I64 = -42

# Different bases
hex = 0xFF        # => 255 (hexadecimal)
octal = 0o755     # => 493 (octal)
binary = 0b1010   # => 10 (binary)

# Decimals
decimal = 3.14    # Dec type (fixed-point decimal)
```

### Underscore Separators

For readability, you can use underscores in number literals:

```roc
# Large numbers
million = 1_000_000
binary_bytes = 0b1010_1100

# Separators work in any position
phone = 555_1234
```

### Number Type Defaults

- **Integers**: Default to `I64` (signed 64-bit)
- **Decimals**: Default to `Dec` (128-bit fixed-point)
- **Floats**: Use `F32` or `F64` explicitly if needed

```roc
# These are I64 by default
small = 42
big = 9_223_372_036_854_775_807  # Still I64

# Explicit float types
float32 : F32 = 3.14
float64 : F64 = 3.14159
```

---

## List Transformations

### Mapping

Transform each element in a list:

```roc
# Double each number
doubled = [1, 2, 3].map(|n| n * 2)  # => [2, 4, 6]

# Convert numbers to strings
strings = [1, 2, 3].map(|n| n.to_str())  # => ["1", "2", "3"]
```

### Filtering

Keep or drop elements based on a condition:

```roc
# Keep evens
evens = [1, 2, 3, 4].keep_if(|n| n % 2 == 0)  # => [2, 4]

# Drop evens (keep odds)
odds = [1, 2, 3, 4].drop_if(|n| n % 2 == 0)   # => [1, 3]
```

### Folding (Reducing)

Combine all elements into a single value:

```roc
# Sum
sum = [1, 2, 3, 4].fold(0, |acc, n| acc + n)  # => 10

# Product
product = [1, 2, 3, 4].fold(1, |acc, n| acc * n)  # => 24

# Concatenate strings
joined = ["a", "b", "c"].fold("", |acc, s| acc + s)  # => "abc"
```

### Checking and Counting

```roc
# Any element satisfies condition?
any_even = [1, 3, 5].any(|n| n % 2 == 0)  # => Bool.False

# All elements satisfy condition?
all_positive = [1, 2, 3].all(|n| n > 0)   # => Bool.True

# Count matching elements
count_evens = [1, 2, 3, 4].count_if(|n| n % 2 == 0)  # => 2
```

### Reverse Fold

Fold from right to left:

```roc
# Right-to-left fold
sum_rev = [1, 2, 3].fold_rev(0, |n, acc| acc + n)  # => 6

# Note the parameter order: (element, accumulator)
# Compare to regular fold: (accumulator, element)
```

### Chaining Transformations

Transformations can be chained:

```roc
# Pipeline: double -> keep evens -> sum
result = [1, 2, 3, 4, 5]
    .map(|n| n * 2)           # => [2, 4, 6, 8, 10]
    .keep_if(|n| n % 4 == 0)  # => [4, 8]
    .fold(0, |acc, n| acc + n)  # => 12
```

---

## Try Mapping and Chaining

### Mapping Try Values

Transform the success or error values:

```roc
success = Try.Ok(42)
error = Try.Err("something went wrong")

# Transform the Ok value
doubled = Try.map_ok(success, |n| n * 2)  # => Ok(84)

# Mapping errors preserves errors
mapped_err = Try.map_ok(error, |n| n * 2)  # => Err("something went wrong")

# Transform the Err value
with_msg = Try.map_err(error, |e| "Error: ${e}")  # => Err("Error: something went wrong")

# Mapping errors preserves success
mapped_ok = Try.map_err(success, |e| "Error: ${e}")  # => Ok(42)
```

### Effectful Mapping

For transformations with side effects, use `map_ok!`:

```roc
# map_ok! is effectful - can do I/O in the transform
result = Try.Ok(42)

Try.map_ok!(result, |n| {
    Stdout.line!("Processing ${n.to_str()}")
    n * 2  # return the transformed value
})  # => Ok(84), prints "Processing 42"
```

### Chaining with `?` Operator

The `?` operator early-returns on `Err`, making chains clean:

```roc
# Chain multiple fallible operations
parse_and_double = |str|
    num = I64.from_str(str)?  # Returns Err if parsing fails
    doubled = num * 2
    Ok(doubled)

# The ? operator returns the error immediately
# Equivalent manual version:
parse_and_double_manual = |str|
    num = I64.from_str(str)
    match num {
        Ok(n) => Ok(n * 2)
        Err(e) => Err(e)  # Early return on error
    }
```

### Combining Multiple Try Operations

```roc
# Validate and process user input
process_input = |name_str, age_str|
    name = if Str.is_empty(name_str) {
        Err("Name cannot be empty")
    } else {
        Ok(name_str)
    }

    age = I64.from_str(age_str)?

    if age < 0 {
        Err("Age cannot be negative")
    } else if age > 150 {
        Err("Age seems unrealistic")
    } else {
        Ok({ name: name, age: age })
    }

# Usage
match process_input("Alice", "30") {
    Ok(user) => "User: ${user.name}"
    Err(msg) => "Error: ${msg}"
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

## Practical Examples

This section provides complete working examples that demonstrate common Roc patterns and best practices.

### Example 1: Command-Line Argument Parser

Demonstrates tag unions, pattern matching, and list spread operator:

```roc
app [main!] { pf: platform "./platform/main.roc" }

import pf.Stdout

Args = [Help, Version(Str), Build(Str)]

parse_args : List(Str) -> Args
parse_args = |args|
    match args {
        [] => Help
        ["--help", ..] => Help
        ["--version", ..] => Version("1.0.0")
        ["--build", dir, ..] => Build(dir)
        _ => Help
    }

main! = |_args| => {
    parsed = parse_args(_args)

    result = match parsed {
        Help => {
            Stdout.line!("Usage: app [--help] [--version] [--build <dir>]")
            Ok({})
        }
        Version(v) => {
            Stdout.line!("Version ${v}")
            Ok({})
        }
        Build(dir) => {
            Stdout.line!("Building in ${dir}")
            Ok({})
        }
    }

    result
}
```

**Key concepts:**
- Tag unions for command-line options
- Pattern matching with `..` for variable arguments
- Effectful function with `=>`

### Example 2: Simple Counter with State

Demonstrates `for` loops and mutable variables (`var`):

```roc
app [main!] { pf: platform "./platform/main.roc" }

import pf.Stdout

# Use for loops for mutable state
count_sum = |numbers|
    var $sum = 0

    for num in numbers {
        $sum = $sum + num
    }

    $sum

main! = |_args| => {
    numbers = [1, 2, 3, 4, 5]
    sum = count_sum(numbers)

    Stdout.line!("Sum: ${sum.to_str()}")

    expect sum == 15

    Ok({})
}
```

**Key concepts:**
- `var` with `$` prefix for mutable state
- `for` loops for iteration
- `expect` for testing

### Example 3: Error Handling with Try

Demonstrates custom error tags and Try usage:

```roc
app [main!] { pf: platform "./platform/main.roc" }

import pf.Stdout

# Function that returns Try
safe_divide : I64, I64 -> Try(I64, [DivByZero, ..])
safe_divide = |a, b|
    if b == 0 {
        Err(DivByZero)
    } else {
        Ok(a // b)
    }

# Process list with error handling
process_numbers = |pairs|
    List.map(pairs, |(a, b)| {
        result = safe_divide(a, b)

        match result {
            Ok(value) => "✓ ${value.to_str()}"
            Err(DivByZero) => "✗ Division by zero"
        }
    })

main! = |_args| => {
    pairs = [(10, 2), (5, 0), (8, 4)]
    results = process_numbers(pairs)

    for result in results {
        Stdout.line!(result)
    }

    Ok({})
}
```

**Key concepts:**
- Custom error tags in Try type
- Pattern matching on Try results
- List.map with tuples
- `for` loops for side effects

### Example 4: Working with Bytes

Demonstrates UTF-8 encoding/decoding:

```roc
app [main!] { pf: platform "./platform/main.roc" }

import pf.Stdout

# Convert string to bytes
to_bytes : Str -> List(U8)
to_bytes = |str|
    str.to_utf8()

# Convert bytes to string (lossy)
from_bytes : List(U8) -> Str
from_bytes = |bytes|
    Str.from_utf8_lossy(bytes)

main! = |_args| => {
    original = "Hello"
    bytes = to_bytes(original)

    Stdout.line!("Bytes: ${Str.inspect(bytes)}")

    recovered = from_bytes(bytes)

    Stdout.line!("Recovered: ${recovered}")

    expect recovered == original

    Ok({})
}
```

**Key concepts:**
- String to bytes conversion with `to_utf8()`
- Bytes to string with `from_utf8_lossy()`
- Using `Str.inspect()` for debugging lists

### Example 5: Custom Tag Union with Methods

Demonstrates nominal types (`:=`) with custom methods:

```roc
app [main!] { pf: platform "./platform/main.roc" }

import pf.Stdout

# Define a tag union with custom equality
Animal := [Dog(Str), Cat(Str)].{
    is_eq = |a, b|
        match (a, b) {
            (Dog(name1), Dog(name2)) => name1 == name2
            (Cat(name1), Cat(name2)) => name1 == name2
            _ => Bool.False
        }
}

# Use the custom type
main! = |_args| => {
    dog1 = Dog("Fido")
    dog2 = Dog("Fido")
    dog3 = Dog("Rex")
    cat = Cat("Whiskers")

    # Custom equality works
    Stdout.line!("dog1 == dog2: ${dog1 == dog2}")  # => true
    Stdout.line!("dog1 == dog3: ${dog1 == dog3}")  # => false
    Stdout.line!("dog1 == cat: ${dog1 == cat}")     # => false

    Ok({})
}
```

**Key concepts:**
- Nominal types with `:=`
- Custom methods in `.{ }` block
- Method calls with dot notation
- Using custom equality (`==` calls `is_eq`)

---

## Key Changes from Old Compiler

### Syntax Migration Table

| Old | New | Notes |
|-----|-----|-------|
| `List U8` | `List(U8)` | Parentheses required |
| `if/then/else` | `if/else` | No `then` keyword |
| `true`/`false` | `Bool.True`/`Bool.False` | Module prefix for creation |
| `Result` | `Try(ok, err)` | Different name |
| `Num.to_str` | `Str.inspect` or `num.to_str()` | Type-specific methods |
| `->` (effectful) | `=>` (effectful) | Explicit effect typing |
| `WasEmpty` | `ListWasEmpty` | More specific error tags |
| `ParseFailed` | `BadNumStr` | More specific error tags |

### Type System Changes

- **Type application**: Uses parentheses: `List(Str)`, `Dict(K, V)`
- **Tag creation**: Module types need prefix to create, bare in patterns
- **Effectful functions**: Use `=>` in type signatures instead of `->`
- **Try vs Result**: `Try(ok, err)` replaces `Result(ok, err)`

### Best Practices

1. **Always verify** against `docs/Builtin.roc` - online docs may be outdated
2. **Use Try** for error handling - it's the standard pattern
3. **Leverage pattern matching** - more powerful than if/else chains
4. **Use `=>`** for effectful functions - makes side effects explicit
5. **Prefer `fold` over `for` loops** when you don't need mutable state
6. **Use nominal types (`:=`)** for type-safe wrappers (IDs, domains)
7. **Use `Str.inspect()`** for debugging any value

---

## Summary

This document covered:

1. ✅ **Local vs module tag creation** - When to use prefixes
2. ✅ **Open/extensible tag unions** - The `..` syntax for polymorphism
3. ✅ **Multiple payloads** - Tags with multiple fields
4. ✅ **Nested patterns** - Matching nested structures
5. ✅ **Number literals** - Different bases and formats
6. ✅ **List transformations** - map, keep_if, drop_if, fold
7. ✅ **Try mapping and chaining** - Advanced Try operations
8. ✅ **Signed-only methods** - `negate` and `abs` only on signed types
9. ✅ **`main!` return type** - Why `Ok({})` is the convention
10. ✅ **Type definition variants** - `=`, `:=`, and `::`
11. ✅ **List pattern matching** - How `..` works
12. ✅ **Common conversion gotchas** - String conversion best practices
13. ✅ **Practical examples** - 5 complete working applications
14. ✅ **Key changes from old compiler** - Migration reference

For complete reference:
- `docs/Builtin.roc` - All builtin functions
- `docs/all_syntax_test.roc` - Comprehensive syntax examples
- `mini-tutorial-new-compiler.md` - Full tutorial (primary learning path)
- `GOTCHAS.md` - Common pitfalls and how to avoid them

