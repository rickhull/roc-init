# Roc Tutorial - New Compiler Syntax

> ⚠️ **This tutorial covers the NEW Roc compiler (nightly)**
>
> The official Roc website (roc-lang.org) currently documents the OLD compiler with different syntax.
> Always verify syntax against `docs/Builtin.roc` and `docs/all_syntax_test.roc` in this repository.

## Table of Contents

1. [Basic Types](#basic-types)
2. [Numbers](#numbers)
3. [Strings](#strings)
4. [Lists](#lists)
5. [Tag Unions](#tag-unions)
6. [Pattern Matching](#pattern-matching)
7. [Try vs Old Result](#try-vs-old-result)
8. [Effectful Functions](#effectful-functions)
9. [Common Gotchas](#common-gotchas)
10. [Practical Examples](#practical-examples)

---

## Basic Types

### Bool

Booleans use `Bool.True` and `Bool.False` for creating values:

```roc
# Bool values (note the lowercase t/f)
is_active = Bool.True
is_disabled = Bool.False

# Bool operations
not_active = !is_active  # => Bool.False
both = is_active and is_disabled  # => Bool.False
either = is_active or is_disabled  # => Bool.True
```

### Pattern Matching on Bool

**Important:** In pattern matching, use bare `True` and `False` (capitalized):

```roc
# Pattern matching uses capitalized tag names
describe_bool = |b|
    match b {
        True => "it's true"
        False => "it's false"
    }

describe_bool(Bool.True)  # => "it's true"
```

**Gotcha:** Use `Bool.True`/`Bool.False` for **creating values**, but `True`/`False` (capitalized, no prefix) in **pattern matching**.

### if/else Expressions

The new compiler uses `if/else` expressions (NOT `if/then/else`):

```roc
# Every if must have an else branch
one_line = if num == 1 "One" else "NotOne"

# Multi-line format
result =
    if num == 2
        "Two"
    else
        "NotTwo"

# With curly braces (for multiple expressions)
with_curlies =
    if num == 5 {
        "Five"
    } else {
        "NotFive"
    }

# else if chains
classify =
    if num == 3
        "Three"
    else if num == 4
        "Four"
    else
        "Other"
```

**Gotcha:** No `if/then/else` exists. Always use `if/else`.

---

## Numbers

Roc has a rich number type system with specific sizes:

### Integer Types

```roc
# Unsigned integers
u8 : U8 = 255
u16 : U16 = 65535
u32 : U32 = 4294967295
u64 : U64 = 18446744073709551615
u128 : U128 = 340282366920938463463374607431768211455

# Signed integers
i8 : I8 = -128
i16 : I16 = -32768
i32 : I32 = -2147483648
i64 : I64 = -9223372036854775808
i128 : I128 = -170141183460469231731687303715884105728
```

### Number Literals

```roc
# Type inference (defaults to I64)
inferred = 42

# Explicit types
explicit_u8 : U8 = 42
explicit_i64 : I64 = -42

# Different bases
hex = 0xFF        # => 255
octal = 0o755     # => 493
binary = 0b1010   # => 10

# Decimals
decimal = 3.14    # Dec type
```

### Number Operations

```roc
# Arithmetic
sum = 10 + 5        # => 15
diff = 10 - 5       # => 5
prod = 10 * 5       # => 50
div = 10.0 / 5.0    # => 2.0 (F64 or Dec)
div_trunc = 10 // 3 # => 3 (truncated division)
rem = 10 % 3        # => 1 (remainder)
mod = -10 mod_by 3  # => 2 (modulo, different from rem for negatives)

# Comparisons
eq = 10 == 5        # => Bool.False
neq = 10 != 5       # => Bool.True
lt = 10 < 5         # => Bool.False
lteq = 10 <= 10     # => Bool.True
gt = 10 > 5         # => Bool.True
gteq = 10 >= 5      # => Bool.True

# Unary
negated = -42       # => -42
```

### Type Conversions

```roc
# Safe widening (never fails)
u8_to_u64 : U64 = u8.to_u64()
i8_to_i64 : I64 = i8.to_i64()

# Safe narrowing with Try
u64_to_u8 : Try(U8, [OutOfRange, ..]) = u64.to_u8_try()
i64_to_i8 : Try(I8, [OutOfRange, ..]) = i64.to_i8_try()

# Wrapping conversions (can wrap around)
u64_to_u8_wrapped : U8 = u64.to_u8_wrap()
i64_to_i8_wrapped : I8 = i64.to_i8_wrap()

# Using the result
match u64_to_u8 {
    Ok(value) => "Converted: ${value.to_str()}"
    Err(OutOfRange) => "Value too large for U8"
}
```

**Gotcha:** Numbers don't have a generic `to_str`. Use the specific type's method:
- `u8.to_str()`, `i64.to_str()`, etc.
- Or use `Str.inspect(value)` for any value

---

## Strings

Strings are UTF-8 encoded and immutable:

```roc
# String literals
greeting = "Hello, world!"

# Multiline strings
multiline =
    \\Line 1
    \\Line 2
    \\Line 3

# String interpolation (with ${})
name = "Alice"
greeting = "Hello, ${name}!"

# Unicode escape
with_unicode = "Euro sign: \u(20AC)"
```

### String Operations

```roc
# Concatenation
full = "Hello".concat(" ")  .concat("World")

# Checking contents
is_empty = "".is_empty()                 # => Bool.True
has_hello = "Hello World".contains("Hello")  # => Bool.True
starts_with_hi = "Hi there".starts_with("Hi")  # => Bool.True
ends_with_world = "Hello World".ends_with("World")  # => Bool.True

# Trimming
trimmed = "  spaces  ".trim()                # => "spaces"
left_trimmed = "  spaces".trim_start()       # => "spaces"
right_trimmed = "spaces  ".trim_end()        # => "spaces"

# Case conversion (ASCII only)
lower = "HELLO".with_ascii_lowercased()  # => "hello"
upper = "hello".with_ascii_uppercased()  # => "HELLO"

# Splitting and joining
parts = "a,b,c".split_on(",")            # => ["a", "b", "c"]
joined = ["a", "b", "c"].join_with(",")  # => "a,b,c"

# Length (UTF-8 bytes)
length = "hello".count_utf8_bytes()      # => 5
```

**Gotcha:** Use `Str.inspect(value)` to convert any value to a string for debugging. The old `Num.to_str` doesn't exist.

---

## Lists

### Type Application Syntax

**NEW:** Use `List(Type)` with parentheses:

```roc
# Correct syntax
numbers : List(I64) = [1, 2, 3]
bytes : List(U8) = [0, 1, 2]
strings : List(Str) = ["a", "b", "c"]

# WRONG - old syntax
# numbers : List I8 = [1, 2, 3]  # Don't do this!
```

### List Operations

```roc
# Basic operations
is_empty = [].is_empty()           # => Bool.True
length = [1, 2, 3].len()           # => 3
first_try = [1, 2, 3].first()      # => Ok(1)
empty_first = [].first()           # => Err(ListWasEmpty)

# Accessing elements
get_result = [1, 2, 3].get(1)      # => Ok(2)
out_of_bounds = [1, 2, 3].get(10)  # => Err(OutOfBounds)

# Combining lists
combined = [1, 2].concat([3, 4])   # => [1, 2, 3, 4]
appended = [1, 2].append(3)        # => [1, 2, 3]

# Taking and dropping
take_first = [1, 2, 3, 4].take_first(2)  # => [1, 2]
take_last = [1, 2, 3, 4].take_last(2)    # => [3, 4]
drop_first = [1, 2, 3, 4].drop_first(2)  # => [3, 4]
drop_last = [1, 2, 3, 4].drop_last(2)    # => [1, 2]

# Sublist
sub = [1, 2, 3, 4, 5].sublist({ start: 1, len: 3 })  # => [2, 3, 4]
```

### List Transformations

```roc
# Mapping
doubled = [1, 2, 3].map(|n| n * 2)  # => [2, 4, 6]

# Filtering
evens = [1, 2, 3, 4].keep_if(|n| n % 2 == 0)  # => [2, 4]
odds = [1, 2, 3, 4].drop_if(|n| n % 2 == 0)   # => [1, 3]

# Folding (reducing)
sum = [1, 2, 3, 4].fold(0, |acc, n| acc + n)  # => 10
product = [1, 2, 3, 4].fold(1, |acc, n| acc * n)  # => 24

# Checking
any_even = [1, 3, 5].any(|n| n % 2 == 0)  # => Bool.False
all_positive = [1, 2, 3].all(|n| n > 0)   # => Bool.True
count_evens = [1, 2, 3, 4].count_if(|n| n % 2 == 0)  # => 2

# Reverse fold
sum_rev = [1, 2, 3].fold_rev(0, |n, acc| acc + n)  # => 6
```

---

## Tag Unions

Tag unions represent enumerated types with optional data:

### Basic Tag Unions

```roc
# Define a tag union
Color = [Red, Green, Blue]

# Use tag values
favorite = Red

# Pattern match on tags
color_name = |color: Color|
    match color {
        Red => "red"
        Green => "green"
        Blue => "blue"
    }

color_name(Red)  # => "red"
```

**Note:** Using `=` creates a **type alias** (structural type). For custom equality or methods, use `:=` to create a **nominal type** (see Example 5 at the end of this tutorial).

### Tags with Data

```roc
# Tags can hold data
Result = [Success(Str), Error(Str), Pending]

result = Success("It worked!")

# Match with destructuring
describe = |result|
    match result {
        Success(msg) => "✓ ${msg}"
        Error(err) => "✗ ${err}"
        Pending => "..."
    }

describe(Success("Done"))  # => "✓ Done"
```

### Multiple Payloads

```roc
# Tags can have multiple fields
Person = [Name(Str, Str), Anonymous]

person = Name("Alice", "Smith")

describe_person = |person|
    match person {
        Name(first, last) => "Person: ${first} ${last}"
        Anonymous => "Anonymous"
    }
```

### Creating Tags: Local vs Module-Defined

**Important distinction** in how tags are created:

```roc
# Local type definition (using =)
Color = [Red, Green, Blue]

# Use bare tags for BOTH creating and matching
favorite = Red           # Creating - no prefix
match favorite {
    Red => "red"         # Matching - no prefix
}

# Module-defined type (like Try or Bool)
# Creating requires module prefix
result = Try.Ok(42)      # Need Try.Ok
is_valid = Bool.True     # Need Bool.True

# But pattern matching uses bare tags
match result {
    Ok(value) => "ok"    # No Try.Ok prefix
    Err(e) => "err"      # No Try.Err prefix
}

match is_valid {
    True => "yes"        # No Bool.True prefix
    False => "no"
}
```

**Rule of thumb:**
- Local types (`Color = [...]`): Bare tags everywhere
- Module types (`Try`, `Bool`): Module prefix to create, bare in patterns

### Open Tag Unions

Use `..` to indicate an extensible tag union:

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
is_primary(Blue)  # => Bool.False
```

### Type Aliases for Extensible Unions

```roc
# Define an extensible tag union type
Letters(others) : [A, B, ..others]

# Use the type alias with specific extensions
letter_to_str : Letters([C, D]) -> Str
letter_to_str = |letter|
    match letter {
        A => "A"
        B => "B"
        _ => "other"
    }

letter_to_str(C)  # => "other"
```

### Type Definitions: `=` vs `:=` vs `::`

Roc has three ways to define types, each with different semantics:

#### 1. Structural Type Alias (`=`)

Creates a type alias that can be freely substituted:

```roc
# Two type aliases with identical structure
MyResult = [Ok(Str), Err(Str)]
YourResult = [Ok(Str), Err(Str)]

# They are THE SAME type - can use interchangeably
use_my_result : MyResult -> Str
use_my_result = |result| result

use_your_result(MyResult)  # Works! They're identical
```

**Use when:** You want a convenient name for an existing type structure.

#### 2. Nominal Type (`:=`)

Creates a distinct type even if the structure is identical:

```roc
# Two wrapper types with identical structure
MyBytes := [Wrapped(List(U8))]
YourBytes := [Wrapped(List(U8))]

# They are DIFFERENT types - cannot use interchangeably
use_my_bytes : MyBytes -> List(U8)
use_my_bytes = |bytes| bytes

use_my_bytes(YourBytes)  # TYPE ERROR! MyBytes != YourBytes

# Construct with bare tag name
make_my_bytes : List(U8) -> MyBytes
make_my_bytes = |bytes| Wrapped(bytes)

# Unwrap via pattern matching
unwrap_my_bytes : MyBytes -> List(U8)
unwrap_my_bytes = |bytes|
    match bytes {
        Wrapped(b) => b
    }
```

**Key properties:**
- **Type safety:** Prevents mixing different wrapper types
- **Public:** Can be used from other modules that import it
- **Nominal:** Type identity is based on the name, not structure

**Use when:** You need wrapper types with compile-time type safety across modules.

#### 3. Opaque Type (`::`)

Creates a nominal type that's **module-private**:

```roc
# In module Crypto.roc
SecretKey :: List(U8)

# Can ONLY be used within Crypto.roc
# Other modules cannot see or construct SecretKey
```

**Key properties:**
- **Module-private:** Only visible in the module where it's defined
- **Nominal:** Distinct type like `:=`
- **Hidden:** Other modules cannot access the underlying representation

**Use when:** You want to hide implementation details from other modules.

### Comparison Table

| Syntax | Type System | Visibility | Use Case |
|--------|-------------|------------|----------|
| `=` | Structural | Public | Type aliases, interchangeable types |
| `:=` | Nominal | Public | Wrapper types with type safety |
| `::` | Nominal | Private | Implementation details to hide |

### Practical Example: Type-Safe IDs

Here's a complete example using `:=` for type-safe ID wrappers:

```roc
# Define distinct ID types
UserId := [UserId(I64)]
PostId := [PostId(I64)]
CommentId := [CommentId(I64)]

# Constructor with validation
make_user_id : I64 -> Try(UserId, [InvalidId])
make_user_id = |num|
    if num > 0 {
        Ok(UserId(num))
    } else {
        Err(InvalidId)
    }

# Use in functions (type-safe!)
get_user : UserId -> Str
get_user = |id|
    match id {
        UserId(num) => "User_${num.to_str()}"
    }

# Compiler prevents passing wrong ID type!
delete_post : PostId -> Bool
delete_post = |id| ...

# delete_post(UserId(123))  # TYPE ERROR! UserId != PostId
```

**Benefits:**
- ✓ Compiler prevents passing `UserId` where `PostId` expected
- ✓ Runtime validation in constructors
- ✓ No need to manually validate in every function
- ✓ Self-documenting code with descriptive types

---

## Pattern Matching

Pattern matching is one of Roc's most powerful features:

### Basic Matching

```roc
# Match on values
describe_number = |n|
    match n {
        0 => "zero"
        1 => "one"
        _ => "many"  # _ matches anything else
    }

describe_number(1)  # => "one"
```

### List Patterns

```roc
match_list = |lst|
    match lst {
        [] => "empty"
        [x] => "single: ${x.to_str()}"
        [1, 2, 3] => "one two three"
        [1, 2, ..] => "starts with 1, 2"
        [2, .., 1] => "starts with 2, ends with 1"
        [1, ..as tail] => "starts with 1, tail has ${List.len(tail)} elements"
        _ => "something else"
    }

match_list([1, 2, 3])  # => "one two three"
```

### Tuple Patterns

```roc
# Destructuring tuples
tuple = (42, "hello")

(num, str) = tuple  # num = 42, str = "hello"
```

### Record Patterns

```roc
person = { name: "Alice", age: 30 }

# Destructure fields
{ name, age } = person  # name = "Alice", age = 30

# Match on records
describe_person = |person|
    match person {
        { name: "Alice" } => "It's Alice!"
        { age: 25 } => "Someone is 25"
        _ => "Someone else"
    }
```

### Nested Patterns

```roc
# Match nested structures
data = [Ok(42), Err("oops")]

result = match data {
    [] => "empty list"
    [Ok(num), ..] => "First is OK: ${num.to_str()}"
    [Err(msg), ..] => "First is Err: ${msg}"
}

result  # => "First is OK: 42"
```

---

## Try vs Old Result

The NEW compiler uses `Try(ok, err)` instead of the old `Result`:

### Try Type Definition

```roc
Try(ok, err) := [Ok(ok), Err(err)]
```

**Note:** Try uses `:=` (nominal type) because it has custom methods like `map_ok`, `is_ok`, etc.

### Creating Try Values

```roc
# Success
success = Try.Ok(42)

# Error
error = Try.Err("something went wrong")
```

### Working with Try

```roc
# Check status
is_ok = Try.is_ok(success)        # => Bool.True
is_err = Try.is_err(error)        # => Bool.True

# Unwrap with fallback
value = Try.ok_or(success, 0)     # => 42
value2 = Try.ok_or(error, 0)      # => 0

# Get the error value (if any)
err_value = Try.err_or(error, "default")  # => "something went wrong"
```

### Pattern Matching Try

**Important:** Similar to Bool, use bare `Ok`/`Err` in pattern matching:

```roc
# Pattern matching uses bare tags
describe_try = |result|
    match result {
        Ok(value) => "Success: ${value.to_str()}"
        Err(msg) => "Error: ${msg}"
    }
```

**Creating vs matching:**
- `Try.Ok(value)` - creates a Try value (with module prefix)
- `Ok(value)` - matches in pattern (bare tag name)

### Mapping Try

```roc
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

```roc
# For effectful operations, use map_ok!
# The transform function can be effectful (uses => in signature)
result = Try.Ok(42)

# map_ok! is a builtin - just use it, don't redefine it
Try.map_ok!(result, |n| {
    Stdout.line!("Processing ${n.to_str()}")
    n * 2  # return the transformed value
})  # => Ok(84)
```

### Chaining Try Operations

```roc
# Combine multiple Try operations
parse_and_double = |str|
    num = I64.from_str(str)?  # Returns error if parsing fails
    Ok(num * 2)

# The ? operator returns the error immediately
# Equivalent to:
parse_and_double_manual = |str|
    num = I64.from_str(str)
    match num {
        Ok(n) => Ok(n * 2)
        Err(e) => Err(e)
    }
```

**Gotcha:** The `?` operator may not be fully implemented yet. Check `docs/all_syntax_test.roc` for current status.

---

## Effectful Functions

Functions that perform side effects are marked with `!`:

```roc
# Effectful function (note the !)
print_greeting! : Str => {}
print_greeting! = |name|
    Stdout.line!("Hello, ${name}!")

# Type signature uses => instead of ->
# main! = |_args| => { ... } indicates an effectful function
app [main!] { pf: platform "./platform/main.roc" }

main! = |_args| => {
    print_greeting!("World")
    Ok({})
}
```

### Effects in Type Signatures

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
```

---

## Common Gotchas

### 1. Type Application Syntax

**OLD:** `List U8` (space, no parentheses)
**NEW:** `List(U8)` (parentheses required)

```roc
# Correct
bytes : List(U8) = [0, 1, 2]

# Wrong
# bytes : List U8 = [0, 1, 2]
```

### 2. if/else vs if/then/else

**OLD:** `if/then/else` (doesn't exist in new compiler)
**NEW:** `if/else`

```roc
# Correct
result = if x > 0 "positive" else "non-positive"

# Wrong
# result = if x > 0 then "positive" else "non-positive"
```

### 3. Bool Values and Pattern Matching

**Creating values:** Use `Bool.True` and `Bool.False` (lowercase t/f, with namespace)

**Pattern matching:** Use bare `True` and `False` (capitalized, no namespace)

```roc
# Creating values
is_valid = Bool.True    # Correct
# is_valid = true       # Wrong

# Pattern matching
match is_valid {
    True => "yes"       # Correct - capitalized, no prefix
    False => "no"       # Correct
}
```

**Key distinction:**
- `Bool.True` = creates a Bool value (lowercase 't')
- `True` = matches the tag in pattern matching (capitalized)

### 4. Tag Creation: Local vs Module-Defined Types

**Local type definitions** use bare tags everywhere:

```roc
# Correct - local type
Color = [Red, Green, Blue]
favorite = Red        # Bare tag for creation
match favorite {
    Red => "red"       # Bare tag for match
}
```

**Module-defined types** need prefix to create, bare in patterns:

```roc
# Correct - module type
result = Try.Ok(42)    # Need Try.Ok to create
match result {
    Ok(v) => "ok"      # Bare Ok in match
}
```

### 5. String Conversion

**OLD:** `Num.to_str(42)` (doesn't exist)
**NEW:** `Str.inspect(42)` or specific type methods

```roc
# Correct
num_str = 42.to_str()         # For specific types
any_str = Str.inspect(42)     # For any value
list_str = Str.inspect([1, 2, 3])  # => "[1, 2, 3]"

# Wrong
# num_str = Num.to_str(42)
```

### 6. Record Field Access

Records use dot notation for field access:

```roc
person = { name: "Alice", age: 30 }

name = person.name  # => "Alice"
age = person.age    # => 30
```

### 7. Record Update Syntax

```roc
person = { name: "Alice", age: 30 }

# Create updated copy
older_person = { ..person, age: 31 }  # => { name: "Alice", age: 31 }
```

### 8. List Literals

```roc
# Empty list needs type annotation
empty : List(I64) = []

# Non-empty lists infer type
numbers = [1, 2, 3]  # List(I64)
```

### 9. Function Calls

```roc
# All functions are called with parentheses
result = my_func(arg1, arg2)

# No standalone parentheses like Ruby
# Not: result = my_func arg1, arg2
```

### 10. Return Statements

Use `return` for early returns, otherwise the last expression is returned:

```roc
calculate = |x|
    if x < 0 {
        return 0  # Early return
    }

    x * 2  # Implicit return
```

### 11. Destructuring in Function Parameters

```roc
# Destructure tuples directly (type inferred)
add_pair = |(a, b)| a + b

# With explicit type annotation - tuple type uses parentheses
add_pair_typed : (I64, I64) -> I64
add_pair_typed = |(a, b)| a + b

# Destructure records
get_name = |{ name }| name  # Extract just the name field

person = { name: "Alice", age: 30 }
get_name(person)  # => "Alice"
```

---

## Practical Examples

### Example 1: Command-Line Argument Parser

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

### Example 2: Simple Counter with State

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

### Example 3: Error Handling with Try

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

### Example 4: Working with Bytes

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

### Example 5: Custom Tag Union with Methods

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

---

## Summary

### Key Differences from Old Compiler

1. **Syntax:**
   - `List(U8)` instead of `List U8`
   - `if/else` instead of `if/then/else`
   - `Bool.True`/`Bool.False` instead of `true`/`false`
   - `=>` for effectful functions instead of `->`

2. **Types:**
   - `Try(ok, err)` instead of `Result`
   - Type application uses parentheses: `List(Type)`, `Dict(K, V)`

3. **Methods:**
   - Use `Str.inspect(value)` instead of `Num.to_str`
   - Specific numeric types have their own `to_str()` methods

4. **Pattern Matching:**
   - More expressive list patterns
   - Open tag unions with `..`
   - Extensible type aliases
   - **Module types:** Use bare tags in patterns (`Ok`, `True`), not `Try.Ok`/`Bool.True`
   - **Local types:** Use bare tags everywhere (creation and matching)

5. **Type Definitions:**
   - `=` for type aliases (structural types)
   - `:=` for nominal types (custom equality/methods)

### Best Practices

1. **Always verify against `docs/Builtin.roc`** - Online docs may be outdated
2. **Use Try for error handling** - It's the new standard
3. **Leverage pattern matching** - It's more powerful than if/else chains
4. **Use `=>` for effectful functions** - Makes side effects explicit
5. **Prefer `List(U8)` syntax** - The new compiler requires parentheses

### Learning Resources

- `docs/Builtin.roc` - Authoritative builtin reference
- `docs/all_syntax_test.roc` - Complete syntax examples
- Project examples in `examples/` directory
- Test files in `test/` directory for practical usage patterns

---

**Remember:** This tutorial covers the NEW Roc compiler. Always check the reference docs in this repository when in doubt!
