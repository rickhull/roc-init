# Roc Language Tutorial (New Zig Compiler)

This tutorial covers the Roc programming language as implemented in the new Zig-based compiler. It is based on the official language reference (`langref/`) and verified syntax patterns.

> **Note:** The language reference is work-in-progress. Sections marked **[WIP]** have limited documentation and are supplemented from verified syntax examples.

---

## Table of Contents

### Part 1: Core Language

1. [Expressions and Values](#expressions-and-values)
2. [Statements](#statements)
3. [Types and Type Annotations](#types-and-type-annotations)
4. [Tag Unions](#tag-unions)
5. [Records and Tuples](#records-and-tuples)
6. [Functions](#functions)
7. [Conditionals](#conditionals)
8. [Pattern Matching](#pattern-matching)
9. [Loops](#loops)
10. [Operators](#operators)
11. [Modules and Imports](#modules-and-imports)
12. [Builtin Types Reference](#builtin-types-reference)

### Part 2: Comprehensive Language Reference

13. [Static Dispatch & Methods](#static-dispatch--methods)
14. [Advanced Pattern Matching](#advanced-pattern-matching)
15. [Advanced Record Operations](#advanced-record-operations)
16. [Control Flow: break](#control-flow-break)
17. [Comments & Documentation](#comments--documentation)
18. [Subscript Operator](#subscript-operator)
19. [Nominal Types: Associated Items](#nominal-types-associated-items)
20. [Comprehensive Builtin Reference](#comprehensive-builtin-reference)
21. [Platform & Application Structure](#platform--application-structure)
22. [Advanced Imports](#advanced-imports)
23. [Type System Deep Dive](#type-system-deep-dive)
24. [Memory Model & Performance](#memory-model--performance)
25. [Error Handling Patterns](#error-handling-patterns)
26. [Testing with expect](#testing-with-expect)
27. [Debugging with dbg](#debugging-with-dbg)

### Appendices

- [Old vs New Syntax](#old-vs-new-syntax)
- [Quick Reference](#quick-reference)
- [Gotchas and Tips](#appendix-gotchas-and-tips)

---

## Expressions and Values

An expression is something that evaluates to a value. You can wrap expressions in parentheses without changing what they do.

### Types of Expressions

All expression types in Roc:

```roc
# String literals
"foo"
"Hello, ${name}!"    # String interpolation

# Number literals
1
2.34
0.123e4
0x5        # Hexadecimal
0o5        # Octal
0b0101     # Binary

# List literals
[1, 2, 3]
[]
["foo", "bar"]

# Record literals
{ x: 1, y: 2 }
{}
{ x, y, ..other_record }    # Record update

# Tag literals
Foo
Foo(bar)
Foo(4, 2)    # Multiple payloads

# Tuple literals
(a, b, "foo")

# Function literals (lambdas)
|a, b| a + b
|| c + d

# Lookups
blah
$blah       # Mutable variable lookup
blah!       # Effectful lookup

# Calls
blah(arg)
foo.bar(baz)    # Method call

# Operator applications
a + b
!x

# Block expressions
{ foo() }
```

### Values

A Roc value is a semantically immutable piece of data. Roc has no concept of reference equality or pointers - memory addresses are implementation details that don't affect program behavior.

### Reference Counting

Heap-allocated values (strings, lists, boxes, recursive tag unions) are automatically reference-counted atomically for thread-safety.

Stack-allocated values (numbers, records, tuples, non-recursive tag unions) are not reference counted.

### Opportunistic Mutation

Roc uses the Perceus "functional-but-in-place" reference counting system:
- Operations on unique values (refcount = 1) update in place
- Operations on shared values (refcount > 1) clone first, then update

```roc
# If `my_list` is unique, this updates in place
# If shared, it clones first
new_list = List.set(my_list, 0, new_value)
```

### Block Expressions

A block expression has optional statements before a final expression. It has its own scope.

```roc
x = if foo {
    temp = compute_something()
    temp + 1
} else {
    x
}
```

> **Note:** `{ x, y }` is a record with two fields. `{ x }` is always a block expression (not a single-field record). This design choice prioritizes the common case of blocks in conditional branches like `else { x }` over the rare case of single-field records.
>
> **Creating single-field records:** Use the explicit field syntax `{ x: x }` or `{ x: some_value }`:
> ```roc
> # Block expression - evaluates to the value of x
> result = { x }
>
> # Single-field record - creates a record with field "x"
> record = { x: x }
> ```

### Evaluation

Roc uses strict evaluation (not lazy like Haskell). When possible, the compiler evaluates expressions at compile-time.

---

## Statements

Statements run when encountered and do not evaluate to a value.

### Assignment (`=`)

```roc
name = "Alice"
count = 42
```

#### Assignment Order

Inside expressions, assignments can only reference earlier names:

```roc
# Error: z not yet defined
foo({
    y = z + 1    # Error!
    z = 5
    z + 1
})
```

At module top-level, assignments can reference each other regardless of order:

```roc
x = y + 1
y = 5
```

#### Assignment Cycles

Cyclic references are only allowed if all assignments are functions:

```roc
# Error: cyclic non-function assignment
x = y + 1
y = x + 1

# OK: all functions
x = |arg| if arg >= 1 { y(arg + 1) } else { 0 }
y = |arg| if arg <= 9 { x(arg + 1) } else { 0 }
```

### Reassignment with `var` and `$`

To reassign a name, declare it with `var` and use the `$` prefix:

```roc
var $foo = 0
$foo = 1
$foo = $foo + 1
```

Without `var`, reassignment causes a shadowing error:

```roc
foo = 0
foo = 1    # Error: shadowing
```

### `import`

Import types from modules:

```roc
import pf.Stdout
import pf.Stdout as StdoutAlias    # With alias
```

### `dbg`

Debug logging (side effect allowed outside effectful functions):

```roc
dbg_keyword = || {
    foo = 42
    dbg foo    # Prints debug info
    foo
}
```

### `expect`

Test assertions:

```roc
expect sum == 15
expect Bool.True != Bool.False
```

Top-level expects run with `roc test file.roc`.

### `return`

Exit a function early with a value:

```roc
my_func = |arg| {
    if arg == 0 {
        return 0
    }
    arg - 1
}
```

### `break`

Exit a loop early:

```roc
# break exits the loop immediately
result = {
    var $found = False
    for item in items {
        if item == target {
            $found = True
            break
        }
    }
    $found
}
```

See [Control Flow: break](#control-flow-break) for detailed examples.

### `crash`

Crash the application with a message:

```roc
if some_condition {
    crash "There is no way this program could possibly continue."
}
```

What happens after crash is platform-defined.

### Block Statements

A block statement has statements but no final expression:

```roc
if foo {
    bar = compute()
    return bar
}
```

---

## Types and Type Annotations

### Type Annotations

```roc
name : Str
name = "Alice"

count : I64
count = 42

number_operators : I64, I64 -> _    # _ infers return type
```

### Numeric Types

| Type | Description |
|------|-------------|
| `U8`, `U16`, `U32`, `U64`, `U128` | Unsigned integers |
| `I8`, `I16`, `I32`, `I64`, `I128` | Signed integers |
| `F32`, `F64` | Floating point |
| `Dec` | Fixed-point decimal |

Number literals with explicit types:

```roc
number_literals = {
    explicit_u8: 5,      # Type inferred from annotation
    explicit_i64: 5,
    explicit_dec: 5.0,
    hex: 0x5,
    octal: 0o5,
    binary: 0b0101,
}
```

### Type Variables

Use lowercase names for generic types:

```roc
type_var : List(a) -> List(a)
type_var = |lst| lst
```

### Type Aliases

```roc
Letters(others) : [A, B, ..others]
```

### Where Clauses

Constrain types to those with specific methods:

```roc
stringify : a -> Str where [a.to_str : a -> Str]
stringify = |value| value.to_str()
```

---

## Tag Unions

A tag union is a tagged union (sum type).

### Tags

A tag names one alternative. Tags can have payloads:

```roc
x = Foo           # No payload
y = Foo(4)        # Single payload
z = Foo(4, 2)     # Multiple payloads
```

At runtime, `Foo(4, 2)` and `Foo((4, 2))` compile to the same thing.

### Structural Tag Unions (`=`)

Structural unions don't need declaration and are extensible:

```roc
color : [Purple, Green]
color = if some_condition {
    Purple
} else {
    Green
}
```

#### Type Parameters for Extension

```roc
add_blue : [Red, Green, ..others], Bool -> [Red, Green, Blue, ..others]
add_blue = |color, green_to_blue| match color {
    Red => Red
    Green => if green_to_blue { Blue } else { Green }
    other => other
}
```

#### Open Tag Unions with `..`

Accept any tag union containing at least certain tags:

```roc
to_str : [Red, Green, .._others] -> Str
to_str = |color| match color {
    Red => "red"
    Green => "green"
    _ => "other"
}

# Anonymous open union (equivalent to .._)
process : [Count(U32), Custom(Str), ..] -> Str
```

#### Closed Tag Unions (`..[]`)

Prevent extension (rarely needed, mainly for platform authors):

```roc
to_color : Str -> [Red, Green, Blue, Other, ..[]]
```

#### Limitations

Structural tag unions cannot be recursive. Use nominal tag unions for recursion.

### Nominal Tag Unions (`:=`)

Nominal unions must be named and are not extensible. They are defined with the `:=` operator and can have associated methods defined in a `.{ }` block:

```roc
Bool := [False, True].{
    not : Bool -> Bool
    not = |bool| match bool {
        Bool.True => Bool.False
        Bool.False => Bool.True
    }
}

Try(ok, err) := [Ok(ok), Err(err)].{
    is_ok : Try(_ok, _err) -> Bool
    map_ok : Try(a, err), (a -> b) -> Try(b, err)
    # ... more methods
}
```

The `.{ }` block after the tag union definition contains associated methods. This syntax:
- Defines methods that can be called on values of this type
- Methods are accessed via dot notation: `my_bool.not()`
- The first parameter of each method typically receives `self` (the value being operated on)

Nominal unions:
- Can be recursive
- Can always be sent across host boundary
- Have associated methods defined in `.{ }`

### Opaque Types (`::`)

Opaque types hide their implementation. The `::` operator creates a type where the internal representation is hidden from external modules:

```roc
Username :: Str

# To create: Username("Bob")
# External code cannot see that Username wraps a Str
```

### Nominal Type with Methods

```roc
Animal := [Dog(Str), Cat(Str)].{
    is_eq = |a, b| match (a, b) {
        (Dog(name1), Dog(name2)) => name1 == name2
        (Cat(name1), Cat(name2)) => name1 == name2
        _ => Bool.False
    }
}
```

---

## Records and Tuples

### Structural Records

```roc
person = { name: "Alice", age: 30 }

# Field access
person.name

# Shorthand when variable name matches field
name = "Bob"
rec = { name, age: 25 }    # Same as { name: name, age: 25 }
```

### Record Update

```roc
record_update_2 : { name : Str, age : I64 } -> { name : Str, age : I64 }
record_update_2 = |person| {
    { ..person, age: 31 }
}
```

### Destructuring Records

```roc
rec = { x: 1, y: "hello" }
{ x, y } = rec
# Now x = 1, y = "hello"
```

### Tuples

Tuples can contain multiple types:

```roc
tuple_demo = ("Roc", 1)
```

### Destructuring Tuples

```roc
tup = ("Roc", 1)
(str, num) = tup
# Now str = "Roc", num = 1
```

---

## Functions

### Lambda Syntax

Functions use `|args| body` syntax:

```roc
add = |a, b| a + b

# No arguments
get_zero = || 0

# With block body
complex = |x| {
    temp = x * 2
    temp + 1
}
```

### Type Signatures

Pure functions use `->`:

```roc
add : I64, I64 -> I64
add = |a, b| a + b
```

### Effectful Functions

Effectful functions:
- Have names ending with `!`
- Use `=>` in type signatures
- Can perform side effects

```roc
effect_demo! : Str => {}
effect_demo! = |msg|
    Stdout.line!(msg)

main! = || {
    Stdout.line!("Hello, world!")
}
```

### Calling Methods

Use dot notation for method calls:

```roc
"One".concat(" Two")
my_list.len()
number.to_str()
```

### Arrow Operator for Non-Methods

Use `->` to call functions as if they were methods:

```roc
my_concat = Str.concat
"Three"->my_concat(" Four")
```

### Recursive Functions

Functions can call themselves:

```roc
x = |arg| if arg >= 1 { y(arg + 1) } else { 0 }
y = |arg| if arg <= 9 { x(arg + 1) } else { 0 }
```

### Placeholder for Unimplemented Functions

Use `...` as a placeholder that crashes if called:

```roc
implement_me_later = |_str| ...
```

---

## Conditionals

### `if`/`else`

Every `if` must have an `else` branch:

```roc
# One-line (without braces, condition followed directly by then-value)
one_line_if = if num == 1 "One" else "NotOne"

# Multi-line without braces
two_line_if =
    if num == 2
        "Two"
    else
        "NotTwo"

# With braces
with_curlies =
    if num == 5 {
        "Five"
    } else {
        "NotFive"
    }
```

### `else if`

```roc
if num == 3
    "Three"
else if num == 4
    "Four"
else
    "Other"
```

### Boolean Operators

Use `and` and `or` keywords (not `&&` or `||`):

```roc
bool_and_keyword: a and b,
bool_or_keyword: a or b,
not_a: !a,
```

---

## Pattern Matching

### `match` Expression

```roc
simple_match : [Red, Green, Blue] -> Str
simple_match = |color| {
    match color {
        Red => "The color is red."
        Green => "The color is green."
        Blue => "The color is blue."
    }
}
```

### List Patterns

```roc
match_list_patterns : List(U64) -> U64
match_list_patterns = |lst| {
    match lst {
        [] => 0
        [x] => x
        [1, 2, 3] => 6
        [1, 2, ..] => 66
        [2, .., 1] => 88
        [1, .. as tail] => 77 + tail.len()
        [_head, 5] => 55
        _ => 100
    }
}
```

### Tag Union Patterns

```roc
match_tag_union_advanced : Try({}, [StdoutErr(Str), Other]) -> Str
match_tag_union_advanced = |try|
    match try {
        Ok(_) => "Success"
        Err(StdoutErr(err)) => "StdoutErr: ${Str.inspect(err)}"
        Err(_) => "Unknown error"
    }
```

### Tuple Patterns

```roc
match (a, b) {
    (Dog(name1), Dog(name2)) => name1 == name2
    (Cat(name1), Cat(name2)) => name1 == name2
    _ => Bool.False
}
```

### Multi-Payload Tags

```roc
multi_payload_tag : [Foo(I64, Str), Bar] -> Str
multi_payload_tag = |tag| match tag {
    Foo(num, name) => "Foo with ${num.to_str()} and ${name}"
    Bar => "Just Bar"
}
```

### Catch-all Pattern (`_`)

```roc
color_to_str : [Red, Green, ..] -> Str
color_to_str = |color| match color {
    Red => "red"
    Green => "green"
    _ => "other color"
}
```

---

## Loops

### `for` Loops

```roc
for_loop = |num_list| {
    var $sum = 0

    for num in num_list {
        $sum = $sum + num
    }

    $sum
}
```

### `while` Loops

```roc
is_eq = |self, other| {
    if self.len() != other.len() {
        return False
    }

    var $index = 0

    while $index < self.len() {
        if list_get_unsafe(self, $index) != list_get_unsafe(other, $index) {
            return False
        }
        $index = $index + 1
    }

    True
}
```

### Mutation in Loops

Use `var` and `$` prefix for mutable variables:

```roc
repeat : a, U64 -> List(a)
repeat = |item, n| {
    var $list = List.with_capacity(n)
    var $count = 0
    while $count < n {
        $list = List.append($list, item)
        $count = $count + 1
    }
    $list
}
```

---

## Operators

### Arithmetic Operators

```roc
{
    sum: a + b,
    diff: a - b,
    prod: a * b,
    div: a_f64 / b_f64,      # Float division
    div_trunc: a // b,        # Integer division
    rem: a % b,               # Remainder
}
```

### Comparison Operators

```roc
{
    eq: a == b,
    neq: a != b,
    lt: a < b,
    lteq: a <= b,
    gt: a > b,
    gteq: a >= b,
}
```

### Unary Operators

```roc
neg: -a,       # Negation
not_a: !a,     # Boolean not
```

### `?` Operator (Try Unwrap)

The `?` operator unwraps `Ok` values or early returns `Err`:

```roc
question_postfix = |strings| {
    first_str = strings.first()?
    first_num = I64.from_str(first_str)?
    Ok(first_num + 1)
}
```

### `??` Operator (Default Value)

The `??` operator provides a default value when the left side is `Err`:

```roc
# If result is Err, use 0 as the default
value = fallible_operation() ?? 0
```

---

## Modules and Imports

### Application Header

```roc
app [main!] { pf: platform "./platform/main.roc" }

import pf.Stdout
```

### Import Variants

```roc
import pf.Stdout                      # Basic import
import pf.Stdout as StdoutAlias       # With alias
# import "../../README.md" as readme : Str    # File import (TODO)
```

### Module Types **[WIP]**

- **Type Modules**: Export types
- **Package Modules**: Group related modules
- **Platform Modules**: Define platform interface
- **Application Modules**: Entry point with `main!`

---

## Builtin Types Reference

### Str

```roc
Str.is_empty : Str -> Bool
Str.concat : Str, Str -> Str
Str.contains : Str, Str -> Bool
Str.trim : Str -> Str
Str.starts_with : Str, Str -> Bool
Str.ends_with : Str, Str -> Bool
Str.repeat : Str, U64 -> Str
Str.count_utf8_bytes : Str -> U64
Str.to_utf8 : Str -> List(U8)
Str.from_utf8 : List(U8) -> Try(Str, [BadUtf8(...), ..])
Str.split_on : Str, Str -> List(Str)
Str.join_with : List(Str), Str -> Str
Str.inspect : _val -> Str    # Debug representation
```

### Multiline Strings

Multiline strings use `\\` at the start of each line. In Roc source code, you write a single backslash:

```roc
multiline_str : U64 -> Str
multiline_str = |number|
    \Line 1
    \Line 2
    \Line ${number.to_str()}
```

> **Note:** When this documentation is rendered in markdown, `\\` appears as `\` due to markdown escaping. In actual Roc source files, use a single `\` character at the start of each line.

### String Interpolation

```roc
"Hello, ${name}!"
"StdoutErr: ${Str.inspect(err)}"
```

### Unicode Escape

```roc
"Unicode escape sequence: \u(00A0)"
```

### List

```roc
List.len : List(item) -> U64
List.is_empty : List(item) -> Bool
List.concat : List(item), List(item) -> List(item)
List.append : List(a), a -> List(a)
List.first : List(item) -> Try(item, [ListWasEmpty, ..])
List.last : List(item) -> Try(item, [ListWasEmpty, ..])
List.get : List(item), U64 -> Try(item, [OutOfBounds, ..])
List.map : List(a), (a -> b) -> List(b)
List.keep_if : List(a), (a -> Bool) -> List(a)
List.drop_if : List(a), (a -> Bool) -> List(a)
List.fold : List(item), state, (state, item -> state) -> state
List.any : List(a), (a -> Bool) -> Bool
List.all : List(a), (a -> Bool) -> Bool
List.contains : List(a), a -> Bool where [a.is_eq : a, a -> Bool]
List.sort_with : List(item), (item, item -> [LT, EQ, GT]) -> List(item)
List.sublist : List(a), { start : U64, len : U64 } -> List(a)
List.take_first : List(a), U64 -> List(a)
List.take_last : List(a), U64 -> List(a)
List.drop_first : List(a), U64 -> List(a)
List.drop_last : List(a), U64 -> List(a)
List.repeat : a, U64 -> List(a)
List.single : item -> List(item)
```

### Bool

```roc
Bool := [False, True]
Bool.not : Bool -> Bool
Bool.True
Bool.False
```

### Try (Result Type)

```roc
Try(ok, err) := [Ok(ok), Err(err)]
Try.is_ok : Try(_ok, _err) -> Bool
Try.is_err : Try(_ok, _err) -> Bool
Try.ok_or : Try(ok, _err), ok -> ok
Try.err_or : Try(_ok, err), err -> err
Try.map_ok : Try(a, err), (a -> b) -> Try(b, err)
Try.map_err : Try(ok, a), (a -> b) -> Try(ok, b)
```

### Box

```roc
Box.box : item -> Box(item)
Box.unbox : Box(item) -> item
```

### Numeric Methods (all types)

```roc
# Common to all numeric types
to_str : NumType -> Str
is_zero : NumType -> Bool
is_eq : NumType, NumType -> Bool
is_gt, is_gte, is_lt, is_lte : NumType, NumType -> Bool
plus, minus, times : NumType, NumType -> NumType
div_by, div_trunc_by, rem_by, mod_by : NumType, NumType -> NumType
from_str : Str -> Try(NumType, [BadNumStr, ..])

# Signed types only
negate : SignedNum -> SignedNum
abs : SignedNum -> SignedNum
is_negative, is_positive : SignedNum -> Bool

# Range methods
to : NumType, NumType -> List(NumType)      # Inclusive
until : NumType, NumType -> List(NumType)   # Exclusive
```

---

# Part 2: Comprehensive Language Reference

The following sections provide in-depth coverage of features introduced above and additional advanced topics.

---

## Static Dispatch & Methods

Roc uses static dispatch for ad-hoc polymorphism. Unlike dynamic dispatch (which uses runtime information), static dispatch resolves method calls at compile time with zero runtime overhead.

### Method Syntax

Methods are called using dot notation:

```roc
"hello".len()
my_list.first()
number.to_str()
```

### Defining Methods on Nominal Types

Methods are defined in the `.{ }` block when declaring a nominal type:

```roc
Container := [Box(Str)].{
    get_value : Container -> Str
    get_value = |Container.Box(s)| s

    transform : Container, (Str -> Str) -> Container
    transform = |Container.Box(s), fn| Container.Box(fn(s))
}

# Using the methods
container = Container.Box("hello")
value = container.get_value()              # "hello"
transformed = container.transform(|s| "${s} world")
```

### Where Clauses for Generic Functions

Use `where` clauses to constrain type variables to types with specific methods:

```roc
# Accept any type that has a get_value method returning Str
extract : a -> Str where [a.get_value : a -> Str]
extract = |x| x.get_value()

# Accept any type with a transform method
modify : a, (Str -> Str) -> a where [a.transform : a, (Str -> Str) -> a]
modify = |x, fn| x.transform(fn)
```

### Multiple Where Constraints

```roc
# Type must have both to_str and from_str methods
round_trip : a -> Try(a, err) where [
    a.to_str : a -> Str,
    a.from_str : Str -> Try(a, err),
]
round_trip = |value| {
    str = value.to_str()
    a.from_str(str)
}
```

### Arrow Operator for Non-Methods

The `->` operator lets you call any function as if it were a method:

```roc
my_func = |x, y| x + y

# Instead of: my_func(10, 5)
result = 10->my_func(5)

# Chaining with arrow operator
static_dispatch_style = some_fn(arg)?.method()?.next_method()
```

### Method Pattern Matching

Methods can pattern match on the nominal type's constructor:

```roc
Basic := [Val(Str)].{
    to_str : Basic -> Str
    to_str = |Basic.Val(s)| s

    to_str2 : Basic -> Str
    to_str2 = |test| test.to_str()
}
```

---

## Advanced Pattern Matching

### Pattern Alternatives

Multiple patterns can match the same branch using `|`:

```roc
Color : [Red, Green, Blue, Yellow, Orange, Purple]

kind : Color -> Str
kind = |color| match color {
    Red | Green | Blue => "primary"
    Yellow | Orange | Purple => "secondary"
}
```

### Nested Destructuring

Patterns can be deeply nested:

```roc
match data {
    Container({ items: [First(x), .. as rest] }) => x + List.len(rest)
    Container({ items: [] }) => 0
    Wrapper([Tag(value), Other(y)]) => value + y
    Simple(x) => x
}
```

### List Rest Patterns

Capture remaining elements with `.. as name`:

```roc
match list {
    [] => "empty"
    [only] => "single: ${only.to_str()}"
    [first, second] => "pair"
    [first, second, .. as rest] => "many: ${rest.len().to_str()} more"
    [first, .., last] => "first and last"
}
```

### Record Patterns with Rest

```roc
match record {
    { foo: 1, bar: 2, ..rest } => process(rest)
    { foo: x, bar: y } => x + y
}
```

### Alternatives in Nested Patterns

```roc
match list {
    [1, 2 | 5, 3] => "matches [1,2,3] or [1,5,3]"
    [1, 2 | 5, 3, .. as rest] => "with rest"
}

match record {
    { foo: 1, bar: 2 | 7 } => "bar is 2 or 7"
}
```

### Underscore Patterns

Use `_` for values you don't need:

```roc
match pair {
    (_, 0) => "second is zero"
    (0, _) => "first is zero"
    (x, _) => "first is ${x.to_str()}"
}
```

Named underscores document ignored values:

```roc
match result {
    Ok(_value) => "success (value ignored)"
    Err(_error) => "failure (error ignored)"
}
```

### Boolean Patterns

```roc
match flag {
    True => "yes"
    False => "no"
}
```

### Literal Patterns

```roc
match num {
    0 => "zero"
    1 => "one"
    3.14 => "pi"
    3.14 | 6.28 => "pi or tau"
    _ => "other"
}

match str {
    "foo" => "got foo"
    "foo" | "bar" => "foo or bar"
    _ => "other"
}
```

---

## Advanced Record Operations

### Record Spread for Updates

Create a new record with some fields changed:

```roc
original = { x: 1, y: 2, z: 3 }
updated = { ..original, x: 10 }
# updated = { x: 10, y: 2, z: 3 }
```

### Multiple Field Updates

```roc
person = { name: "Alice", age: 30, city: "NYC" }
moved_and_older = { ..person, age: 31, city: "LA" }
```

### Rest Pattern in Destructuring

Capture remaining fields:

```roc
{ name, ..rest } = { name: "Alice", age: 30, city: "NYC" }
# name = "Alice"
# rest = { age: 30, city: "NYC" }
```

### Field Punning

When a variable has the same name as a field:

```roc
name = "Bob"
age = 25
person = { name, age }    # Same as { name: name, age: age }
```

### Record Types in Signatures

```roc
get_name : { name : Str, age : I64 } -> Str
get_name = |person| person.name

# With type alias
Person : { name : Str, age : I64 }

get_name2 : Person -> Str
get_name2 = |person| person.name
```

---

## Control Flow: break

### `break` in For Loops

Exit a loop early when a condition is met:

```roc
find_first_negative : List(I64) -> Try(I64, [NotFound])
find_first_negative = |numbers| {
    var $result = Err(NotFound)
    for n in numbers {
        if n < 0 {
            $result = Ok(n)
            break
        }
    }
    $result
}
```

### `break` in While Loops

```roc
result : Bool
result = {
    var $foo = True
    while (True) {
        break
        $foo = False    # Never executed
    }
    $foo
}

expect result == True
```

### Practical Example: Early Exit

```roc
result : Bool
result = {
    var $all_true = True
    for b in [True, True, False, True, True, True] {
        if b == False {
            $all_true = False
            break
        } else {
            {}
        }
    }
    $all_true
}

expect result == False
```

> **Note:** The `continue` keyword does not exist in the current Roc compiler. Use early `return` or restructure your loop logic as alternatives.

---

## Comments & Documentation

### Single-Line Comments

Comments start with `#`:

```roc
# This is a comment
x = 42  # Inline comment
```

### Comments in Multiline Expressions

Comments can appear in many places:

```roc
match_time = |
    a, # After arg
    b,
| # After args
    match a {
        Blue | Green | Red => {
            x = 12
            x
        }
    }
```

### Comments in Records and Lists

```roc
record = {
    foo: 123, # Comment after field
    bar: "Hello",
}

list = [
    1, # First
    2, # Second
    3, # Third
]
```

### Comments in Imports

```roc
import # Comment after import keyword
    pf # Comment after qualifier
        .Stdout # Comment after ident
        exposing [ # Comment after exposing open
            line!, # Comment after exposed item
        ] # Comment after exposing close
```

### Module Comments

A comment at the start of a file documents the module:

```roc
# This is a module comment!
app [main!] { pf: platform "..." }
```

---

## Subscript Operator

### List Indexing

Access list elements by index:

```roc
list = [10, 20, 30, 40]
second = list[1]    # 20
```

### Bounds Checking

Out-of-bounds access returns an error through the `Try` type:

```roc
# Safe access with Try
element = List.get(list, 10)  # Err(OutOfBounds)

# Subscript operator behavior may vary
# Check current implementation for exact semantics
```

---

## Nominal Types: Associated Items

### Associated Type Aliases

Define type aliases within a nominal type:

```roc
Container(item) := [Box(item)].{
    Item : item    # Associated type alias

    get : Container(item) -> item
    get = |Container.Box(x)| x
}
```

### Nested Nominal Types

Types can be defined within other types:

```roc
Outer := [Inner(Inner)].{
    Inner := [Value(Str)]
}
```

### Scope Resolution

Access associated items using dot notation:

```roc
val = Container.Box("hello")
item = val.get()
```

---

## Comprehensive Builtin Reference

### Str (Extended)

```roc
# Basic operations
Str.is_empty : Str -> Bool
Str.concat : Str, Str -> Str
Str.len : Str -> U64                    # UTF-8 byte count

# Searching
Str.contains : Str, Str -> Bool
Str.starts_with : Str, Str -> Bool
Str.ends_with : Str, Str -> Bool

# Modification
Str.trim : Str -> Str
Str.trim_start : Str -> Str
Str.trim_end : Str -> Str
Str.to_uppercase : Str -> Str
Str.to_lowercase : Str -> Str

# Splitting and joining
Str.split_on : Str, Str -> List(Str)
Str.join_with : List(Str), Str -> Str

# Repetition
Str.repeat : Str, U64 -> Str

# Conversion
Str.to_utf8 : Str -> List(U8)
Str.from_utf8 : List(U8) -> Try(Str, [BadUtf8, ..])
Str.count_utf8_bytes : Str -> U64

# Debug
Str.inspect : a -> Str                  # Any value to debug string
```

### List (Extended)

```roc
# Size operations
List.len : List(a) -> U64
List.is_empty : List(a) -> Bool
List.with_capacity : U64 -> List(a)

# Access
List.first : List(a) -> Try(a, [ListWasEmpty])
List.last : List(a) -> Try(a, [ListWasEmpty])
List.get : List(a), U64 -> Try(a, [OutOfBounds])

# Modification
List.set : List(a), U64, a -> List(a)
List.append : List(a), a -> List(a)
List.prepend : List(a), a -> List(a)
List.concat : List(a), List(a) -> List(a)
List.reverse : List(a) -> List(a)
List.swap : List(a), U64, U64 -> List(a)

# Slicing
List.take_first : List(a), U64 -> List(a)
List.take_last : List(a), U64 -> List(a)
List.drop_first : List(a), U64 -> List(a)
List.drop_last : List(a), U64 -> List(a)
List.sublist : List(a), { start : U64, len : U64 } -> List(a)
List.split_at : List(a), U64 -> (List(a), List(a))

# Transformation
List.map : List(a), (a -> b) -> List(b)
List.map_with_index : List(a), (a, U64 -> b) -> List(b)

# Filtering
List.keep_if : List(a), (a -> Bool) -> List(a)
List.drop_if : List(a), (a -> Bool) -> List(a)

# Searching
List.find : List(a), (a -> Bool) -> Try(a, [NotFound])
List.find_index : List(a), (a -> Bool) -> Try(U64, [NotFound])
List.contains : List(a), a -> Bool where [a.is_eq : a, a -> Bool]
List.any : List(a), (a -> Bool) -> Bool
List.all : List(a), (a -> Bool) -> Bool

# Folding
List.fold : List(a), state, (state, a -> state) -> state
List.fold_right : List(a), state, (state, a -> state) -> state

# Sorting
List.sort_with : List(a), (a, a -> [LT, EQ, GT]) -> List(a)
List.sort_asc : List(a) -> List(a) where [a.compare : a, a -> [LT, EQ, GT]]
List.sort_desc : List(a) -> List(a) where [a.compare : a, a -> [LT, EQ, GT]]

# Combining
List.zip : List(a), List(b) -> List((a, b))
List.unzip : List((a, b)) -> (List(a), List(b))
List.intersperse : List(a), a -> List(a)
List.join : List(List(a)) -> List(a)

# Generation
List.range : U64, U64 -> List(U64)
List.repeat : a, U64 -> List(a)
List.single : a -> List(a)
```

### Numeric Types (Extended)

```roc
# Basic arithmetic
plus : Num, Num -> Num
minus : Num, Num -> Num
times : Num, Num -> Num
div_by : Num, Num -> Num
div_trunc_by : Int, Int -> Int
rem_by : Int, Int -> Int
mod_by : Int, Int -> Int

# Checked arithmetic (returns Try on overflow)
add_checked : Num, Num -> Try(Num, [Overflow])
sub_checked : Num, Num -> Try(Num, [Overflow])
mul_checked : Num, Num -> Try(Num, [Overflow])

# Wrapping arithmetic (wraps on overflow)
add_wrap : Int, Int -> Int
sub_wrap : Int, Int -> Int
mul_wrap : Int, Int -> Int

# Saturating arithmetic (clamps to min/max)
add_saturating : Int, Int -> Int
sub_saturating : Int, Int -> Int

# Comparison
is_eq : Num, Num -> Bool
is_gt : Num, Num -> Bool
is_gte : Num, Num -> Bool
is_lt : Num, Num -> Bool
is_lte : Num, Num -> Bool

# Utilities
min : Num, Num -> Num
max : Num, Num -> Num
clamp : Num, Num, Num -> Num    # clamp(value, low, high)
abs : SignedNum -> SignedNum
negate : SignedNum -> SignedNum

# Bit operations (integers only)
bitwise_and : Int, Int -> Int
bitwise_or : Int, Int -> Int
bitwise_xor : Int, Int -> Int
bitwise_not : Int -> Int
shift_left : Int, U8 -> Int
shift_right : Int, U8 -> Int

# Conversion
to_str : Num -> Str
from_str : Str -> Try(Num, [BadNumStr])
is_zero : Num -> Bool
is_positive : SignedNum -> Bool
is_negative : SignedNum -> Bool

# Ranges
to : Int, Int -> List(Int)      # Inclusive: 1.to(5) = [1,2,3,4,5]
until : Int, Int -> List(Int)   # Exclusive: 1.until(5) = [1,2,3,4]
```

### Dec (Decimal)

Fixed-point decimal for financial calculations:

```roc
Dec.from_str : Str -> Try(Dec, [BadDecStr])
Dec.to_str : Dec -> Str

# Rounding
Dec.round : Dec -> Dec
Dec.floor : Dec -> Dec
Dec.ceiling : Dec -> Dec
Dec.truncate : Dec -> Dec
```

---

## Platform & Application Structure

### Application Header

```roc
app [main!] { pf: platform "./platform/main.roc" }
```

Components:
- `app`: Declares this as an application module
- `[main!]`: List of exposed values (the entry point)
- `{ pf: platform "..." }`: Platform specification with alias

### Exposing Multiple Values

```roc
app [main!, helper, Config] { pf: platform "..." }
```

### Module Header Types

1. **Application (`app`)**: Entry point with `main!`
   ```roc
   app [main!] { pf: platform "..." }
   ```

2. **Module (`module`)**: Reusable library code
   ```roc
   module [public_fn, PublicType]
   ```

3. **Package (`package`)**: Collection of modules
   ```roc
   package [Module1, Module2]
   ```

4. **Platform (`platform`)**: Defines host interface
   ```roc
   platform "name" requires {} { main! : {} => {} }
   ```

5. **Hosted (`hosted`)**: Platform-provided functions
   ```roc
   hosted [line!, write!]
   ```

### Headerless Application Modules

Simple scripts can omit the header if they only use standard features.

---

## Advanced Imports

### Basic Import

```roc
import pf.Stdout
```

### Import with Alias

```roc
import pf.Stdout as IO
import BadName as GoodName
```

### Exposing Specific Items

```roc
import pf.Stdout exposing [line!, write!]
```

### Exposing with Aliases

```roc
import pkg.Something exposing [func as function, Type as ValueCategory]
```

### Wildcard Exposing

Expose all constructors of a type:

```roc
import pkg.Something exposing [Custom.*]
```

### Multi-line Import Formatting

```roc
import
    pf
        .Stdout
        exposing [
            line!,
            write!,
        ]
```

### Import Order

Imports typically come after the module header:

```roc
app [main!] { pf: platform "..." }

import pf.Stdout
import pf.Stdin
```

---

## Type System Deep Dive

### Roc's Type System

- **Rank-1 polymorphism**: No higher-kinded types
- **Hindley-Milner inference**: Types are inferred automatically
- **No subtyping**: Types must match exactly (with some exceptions for tag unions)

### Parameterized Type Aliases

```roc
Map(k, v) : List((k, v))

Maybe(a) : [Some(a), None]

Tree(a) := [Leaf(a), Branch(Tree(a), Tree(a))]
```

### Type Inference Behavior

Roc infers types when possible:

```roc
# Type inferred as: List(I64) -> I64
sum = |list| List.fold(list, 0, |acc, x| acc + x)
```

### The `_` Type Hole

Use `_` to let the compiler infer part of a type:

```roc
process : List(_) -> U64
process = |list| list.len()
```

### Rigid vs Flexible Type Variables

**Rigid** (from annotations): Must be exactly that type
```roc
identity : a -> a    # 'a' is rigid
identity = |x| x
```

**Flexible** (from inference): Can be unified with other types

### Recursive Types

Only nominal types can be recursive:

```roc
# This works (nominal)
LinkedList(a) := [Nil, Cons(a, LinkedList(a))]

# This would NOT work (structural can't be recursive)
# BadList : [Nil, Cons(a, BadList)]  # Error!
```

---

## Memory Model & Performance

### Reference Counting

Roc uses atomic reference counting for thread-safe memory management:

- **Heap-allocated**: Strings, Lists, Boxes, recursive tag unions
- **Stack-allocated**: Numbers, records, tuples, non-recursive tag unions

### Opportunistic Mutation (Perceus)

The Perceus system enables "functional but in place" updates:

```roc
# When my_list has refcount = 1:
#   List.set mutates in place (fast)
#
# When my_list has refcount > 1:
#   List.set clones first, then mutates (safe)

new_list = List.set(my_list, 0, new_value)
```

### No Reference Cycles

By design, Roc cannot express reference cycles:

```roc
# This is impossible in Roc:
# a = { other: b }
# b = { other: a }  # Cannot create cycle
```

This eliminates the need for:
- Cycle-detecting garbage collectors
- Weak references
- Manual cycle breaking

### Performance Implications

1. **Unique values are fast**: Operations on values with refcount=1 are O(1) updates
2. **Sharing has cost**: First mutation after sharing requires a clone
3. **Stack allocation is free**: No heap allocation for simple values

### When Values Are Cloned

```roc
x = [1, 2, 3]
y = x                    # x is now shared (refcount = 2)
z = List.append(x, 4)    # x is cloned because shared
w = List.append(z, 5)    # z is unique, mutated in place
```

---

## Error Handling Patterns

### The `Try` Type

```roc
Try(ok, err) := [Ok(ok), Err(err)]
```

### Basic Pattern Matching

```roc
handle_result : Try(I64, Str) -> Str
handle_result = |result| match result {
    Ok(value) => "Got: ${value.to_str()}"
    Err(message) => "Error: ${message}"
}
```

### The `?` Operator

Unwrap `Ok` or early return `Err`:

```roc
process_data! : Str => Try(I64, [ParseError, NetworkError])
process_data! = |input| {
    parsed = parse(input)?           # Returns early if Err
    validated = validate(parsed)?    # Returns early if Err
    result = compute(validated)?     # Returns early if Err
    Ok(result)
}
```

### The `??` Operator

Provide a default value for `Err`:

```roc
value = risky_operation() ?? default_value

# Chaining
value = first_try() ?? second_try() ?? fallback
```

### Chaining with Methods

```roc
result = input
    .parse_int()?
    .map_ok(|n| n * 2)
    .map_err(|_| CustomError)
```

### Combining Multiple Fallible Operations

```roc
complex_operation = |input| {
    a = step1(input)?
    b = step2(a)?
    c = step3(b)?
    Ok(combine(a, b, c))
}
```

### Try Methods

```roc
Try.is_ok : Try(ok, err) -> Bool
Try.is_err : Try(ok, err) -> Bool
Try.ok_or : Try(ok, err), ok -> ok
Try.err_or : Try(ok, err), err -> err
Try.map_ok : Try(a, err), (a -> b) -> Try(b, err)
Try.map_err : Try(ok, a), (a -> b) -> Try(ok, b)
```

---

## Testing with expect

### Basic Expects

```roc
expect 1 + 1 == 2
expect "hello".len() == 5
expect Bool.True != Bool.False
```

### Expect in Blocks

```roc
expect {
    foo = 1
    bar = 2
    foo + bar == 3
}
```

### Top-Level Expects

Expects at the top level run with `roc test`:

```roc
# my_module.roc
sum : List(I64) -> I64
sum = |list| List.fold(list, 0, |acc, x| acc + x)

expect sum([]) == 0
expect sum([1, 2, 3]) == 6
expect sum([-1, 1]) == 0
```

Run with:
```bash
roc test my_module.roc
```

### Expects Inside Functions

```roc
process = |input| {
    expect input.len() > 0    # Assertion during execution
    # ... rest of function
}
```

### Testing Patterns

```roc
# Test a specific case
expect {
    input = [1, 2, 3]
    result = process(input)
    result == expected_output
}

# Test edge cases
expect process([]) == default_value
expect process([single]) == single
```

---

## Debugging with dbg

### Basic Usage

```roc
my_func = |x| {
    dbg x           # Prints: [my_file.roc:3] x = <value>
    x + 1
}
```

### dbg in Expressions

```roc
result = dbg compute_something()    # Prints and returns the value
```

### dbg as Function Argument

```roc
some_func(
    dbg 42,    # Prints 42, then passes it to some_func
)
```

### dbg in Lists

```roc
list = [
    dbg first_value,
    second_value,
    dbg third_value,
]
```

### dbg Output Format

Output includes:
- File name and line number
- Expression being debugged
- The value

```
[my_module.roc:15] my_variable = { x: 1, y: 2 }
```

### dbg Restrictions

- Cannot be used at the top level of a module
- Allowed inside functions (even pure ones)
- Output format is platform-dependent

### Debugging Complex Values

```roc
debug_state = |state| {
    dbg state.counter
    dbg state.items.len()
    dbg state.is_valid
    state
}
```

---

## Old vs New Syntax

| Concept | Old Syntax | New Syntax |
|---------|------------|------------|
| Lambda | `\a, b -> a + b` | `\|a, b\| a + b` |
| If/else | `if cond then x else y` | `if cond { x } else { y }` or `if cond x else y` |
| Pattern match | `when x is` | `match x {` |
| Boolean and | `&&` | `and` |
| Boolean or | `\|\|` | `or` |
| Boolean not | `!x` | `!x` (same) |
| Type definition | `Foo : [A, B]` | `Foo := [A, B]` (nominal) |
| Type alias | `Foo : [A, B]` | `Foo : [A, B]` (structural) |
| Opaque type | `Foo := Str` | `Foo :: Str` |
| Record update | `{ rec & field: value }` | `{ ..rec, field: value }` |
| Pipeline | `x \|> f \|> g` | `x.f().g()` (method syntax) |
| Walk/fold | `List.walk` | `List.fold` |
| Result type | `Result ok err` | `Try(ok, err)` |

---

## Quick Reference

### Function Definition

```roc
# Pure function
my_func : ArgType -> ReturnType
my_func = |arg| expression

# Effectful function
my_func! : ArgType => ReturnType
my_func! = |arg| effectful_expression
```

### Common Patterns

```roc
# Early return
if condition {
    return early_value
}

# Mutable variable
var $counter = 0
$counter = $counter + 1

# For loop with accumulator
var $result = initial
for item in collection {
    $result = update($result, item)
}

# Match with alternatives
match color {
    Red | Green | Blue => "primary"
    _ => "other"
}
```

### Error Handling

```roc
# Using match
match result {
    Ok(value) => process(value)
    Err(error) => handle(error)
}

# Using methods
result.ok_or(default_value)
result.map_ok(|v| transform(v))

# Using ? for early return
value = fallible_operation()?
```

---

## Appendix: Gotchas and Tips

1. **Every `if` needs `else`**: Unlike some languages, `if` without `else` is not valid.

2. **Use `and`/`or` not `&&`/`||`**: Boolean operators are keywords.

3. **Lambda syntax is `|args|`**: Not `\args ->`.

4. **Mutable variables need `var` and `$`**: Both are required.

5. **Single-field records**: `{ x }` is a block, not a record. Use `{ x: x }` for single-field records.

6. **Method calls**: Use `.method()` syntax. The old `|>` pipeline is gone.

7. **Tag union extensibility**:
   - `[A, B]` is closed structural
   - `[A, B, ..]` or `[A, B, ..others]` is open
   - `[A, B, ..[]]` explicitly prevents extension

8. **Nominal vs Structural**:
   - `=` defines structural types (anonymous, can be extended)
   - `:=` defines nominal types (named, fixed, can have methods)
   - `::` defines opaque types (hidden implementation)

9. **Result type is `Try`**: Not `Result`. Use `Try(ok, err)`.

10. **Functions ending in `!`**: Must be effectful and use `=>` in signatures.

11. **The `.{ }` block**: When defining nominal types, methods go in `.{ }` after the type definition.

12. **Where clauses**: Use `where [type.method : ...]` to constrain generic types.

13. **`break` exits loops**: Works in both `for` and `while` loops.

14. **Comments use `#`**: Not `//` or `/* */`.

15. **No null**: Use `Try` or `[Some(a), None]` for optional values.
