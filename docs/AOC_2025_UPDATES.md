# AOC 2025 Document Updates Needed

This document records issues found in `docs/roc-advent-2025.md` by comparing it against the authoritative Roc compiler references (Builtin.roc, all_syntax_test.roc, and ROC_LANGREF_TUTORIAL.md).

## Analysis Method

The `roc-advent-2025.md` document was an early introduction to the new Zig-based Roc compiler, written in haste for Advent of Code 2025. This analysis identifies areas where the current Roc implementation has drifted from that early document.

**Authoritative references used:**
- `docs/Builtin.roc` - Complete builtin functions reference
- `docs/all_syntax_test.roc` - Comprehensive syntax examples
- ROC_LANGREF_TUTORIAL.md - Full tutorial from compiler source

---

## Issues Found

### 1. Error Tag Names Have Changed (Lines 476-503)

**Status:** Code-breaking

**Issue:** The document uses `WasEmpty` as the error tag for `List.first()`:

```ruby
match numbers.first() {
    Ok(first) => first + 1
    Err(WasEmpty) => 0
}
```

**Current reality:** The error tag is `ListWasEmpty`, not `WasEmpty`:

```roc
List.first : List(item) -> Try(item, [ListWasEmpty, ..])
```

**Impact:** Code copied from the document will not compile.

**Similarly**, the error from `Str.from_utf8` is `BadUtf8` (with optional payload), and numeric `from_str` returns `Err(BadNumStr)`.

**Corrected example:**
```roc
number = match numbers.first() {
    Ok(first) => first + 1
    Err(ListWasEmpty) => 0
}
```

---

### 2. Bool Creation vs Pattern Matching (Throughout)

**Status:** Documentation gap

**Issue:** The document doesn't explicitly clarify the distinction between:
- **Creating** Bool values: Requires `Bool.True` / `Bool.False` (with prefix)
- **Pattern matching** on Bool: Use bare `True` / `False` (no prefix)

**The rule:**
```roc
# Creating values - use the prefix
is_active = Bool.True    # Correct
is_active = True         # Wrong (unless True is a local tag)

# Pattern matching - bare tags
match is_active {
    True => "yes"       # Correct - no prefix needed
    False => "no"
}
```

**Why this matters:** This distinction applies to all module types vs local types. The document shows bare `True`/`False` in examples (lines 389-391) but doesn't explain when to use the prefix.

**General rule:** Local types use bare tags everywhere. Module types need prefix to create, bare tags in patterns.

---

### 3. Missing `??` Operator (Not mentioned)

**Status:** Incomplete documentation

**Issue:** The advent document describes the `?` operator for early returns, but does not mention the `??` operator for default values.

**Current reality:** The `??` operator provides a default value when the left side is `Err`:

```roc
# If result is Err, use 0 as the default
value = fallible_operation() ?? 0

# Can chain
value = first_try() ?? second_try() ?? fallback
```

**Impact:** Users are unaware of a useful ergonomic feature.

---

### 4. Signed-Only Methods Not Noted (Line 145)

**Status:** Edge case not documented

**Issue:** The document shows:

```ruby
Stdout.line!("Answer: ${((numerator / denominator) + 1).negate().to_str()}")
```

The `.negate()` method is shown, but `negate` is only available on **signed** numeric types (I8, I16, I32, I64, I128). If `numerator` is unsigned (U8, U16, U32, U64, U128), this would fail to compile.

**Impact:** Users copying this example with unsigned types will get confusing type errors.

---

### 5. Tag Creation Rules for Local vs Module Types (Lines 453-466)

**Status:** Documentation gap

**Issue:** The document shows:

```ruby
birds_or_numbers = [Bird("eagle"), Number(1)]
```

But doesn't explain when you need a module prefix. For `Try`, you write `Try.Ok(value)` (needs prefix), but for `Bird` you write just `Bird("eagle")` (no prefix).

**The rule:**
- **Local type definitions** (defined in current module): Use bare tags everywhere
  ```roc
  Color = [Red, Green, Blue]
  fav = Red                # Bare for creation
  match fav { Red => "red" }  # Bare in match
  ```

- **Module types** (imported or from stdlib): Need prefix to create, bare in match
  ```roc
  result = Try.Ok(42)      # Need Try.Ok to create
  match result {
      Ok(v) => "ok"        # Bare Ok in match
      Err(e) => "err"
  }
  ```

**Impact:** Users may be confused about when to use prefixes.

---

### 6. main! Return Type Clarity (Line 26)

**Status:** Minor documentation gap

**Issue:** The document shows:

```ruby
main! = |_args| {
    Stdout.line!("Hello, World!")
    Ok({})
}
```

This returns `Ok({})` where `{}` is an empty record. The document doesn't explicitly state that `main!` must return a `Try` type, nor why an empty record is used (vs `Ok(())` or similar).

**Current understanding:** `main!` must return `Try(something, error)`. The empty record `{}` is a placeholder since the return value isn't used.

---

### 7. List Pattern Matching Syntax (Lines 428-434)

**Status:** Minor formatting inconsistency

**Issue:** The document shows:

```ruby
points = match animals {
    ["bird", "crab", "lizard"] => 10
    ["bird", "crab", ..] => 5
    ["bird", ..] => 1
    [first, second, "lizard" ..] => count_points(first, second)
    _ => 0
}
```

The pattern `[first, second, "lizard" ..]` is missing the comma before `..`. Should be `[first, second, "lizard", ..]` or more likely `[first, second, .., "lizard"]` to match "lizard" at the end.

**Corrected:**
```roc
match animals {
    ["bird", "crab", "lizard"] => 10
    ["bird", "crab", ..] => 5
    ["bird", ..] => 1
    [first, second, ..] => count_points(first, second)
    _ => 0
}
```

---

## Summary Table

| Issue | Severity | Lines | Fix Type |
|-------|----------|-------|----------|
| `WasEmpty` → `ListWasEmpty` | Code-breaking | 476-503 | Change code examples |
| Bool creation vs matching | Documentation | Throughout | Add explanation |
| Missing `??` operator | Incomplete | N/A | Add section |
| `negate()` on signed types | Edge case | 145 | Add note |
| Local vs module tag rules | Documentation | 453-466 | Add explanation |
| main! return type | Minor | 26 | Clarify |
| List pattern syntax | Minor | 428-434 | Fix typo |

---

## What's Still Accurate

The following aspects of `roc-advent-2025.md` remain correct and match the current compiler:

- ✅ `if/else` syntax (no `then` keyword)
- ✅ Type application syntax: `List(Str)` with parentheses
- ✅ `for` loops with `var` and `$` prefix
- ✅ `fold` for functional-style accumulation
- ✅ Block expressions and statements
- ✅ `return` and `crash` keywords
- ✅ `expect` for testing
- ✅ `dbg` for debugging
- ✅ Record update syntax: `{ ..record, field: value }`
- ✅ Method calling: `list.len()`, `str.concat()`
- ✅ The `?` operator for Try unwrapping
- ✅ Effectful functions use `=>` in type signatures
- ✅ Function type annotations: `I64, I64 -> I64`

---

## Recommendations

1. **High priority:** Update the `WasEmpty` examples to use `ListWasEmpty` for code correctness
2. **Medium priority:** Add a section explaining local vs module tag creation rules
3. **Medium priority:** Document the `??` operator
4. **Low priority:** Add notes about signed-only methods like `negate()`, `abs()`
5. **Low priority:** Clarify the main! return type convention

---

*Analysis performed using Roc compiler references from:*
- `docs/Builtin.roc` (fetched from new compiler source)
- `docs/all_syntax_test.roc` (comprehensive syntax tests)
- `ROC_LANGREF_TUTORIAL.md` (full language reference)
