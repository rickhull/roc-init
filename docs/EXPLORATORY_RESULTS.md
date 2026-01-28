# Exploratory Testing Results: `expect` Behavior in Roc

> **Experimental Verification:** 2025-01-27
>
> All findings confirmed via test files in `examples/expect/`

---

## Executive Summary

We performed exploratory testing to answer: **How does `expect` behave in different contexts?**

### Key Findings

| Context | Location | Evaluation Time | Can Call Hosted? | Runs With |
|---------|----------|-----------------|------------------|-----------|
| Any code | Top-level | **Compile time** | ❌ No | `roc test` |
| Any code | In function | **Runtime** | ✅ Yes | `roc run` |

**Critical Difference:** Top-level `expect` = compile-time unit tests. In-function `expect` = runtime assertions.

---

## Test Files

| File | Command | Purpose | Tests |
|------|---------|---------|-------|
| `examples/expect/roc-test-positive.roc` | `roc test` | Compile-time, all pass | 7 tests ✅ |
| `examples/expect/roc-test-negative.roc` | `roc test` | Compile-time, show errors | 3 failures ❌ |
| `examples/expect/roc-test-refused.roc` | `roc test` | In-function expects ignored | 0 tests ⏭️ |
| `examples/expect/roc-run-positive.roc` | `roc run` | Runtime, all pass | 6 tests ✅ (incl. top-level hosted expect) |
| `examples/expect/roc-run-negative.roc` | `roc run` | Runtime, show errors | Stops at first ❌ |
| `examples/expect/roc-run-negative-skipped.roc` | `roc run` | Runtime: skipped test | Block failure (run in isolation) ⏭️ |
| `examples/expect/roc-run-refused.roc` | `roc run` | Runtime: refused | Top-level pure expects ignored 🤔 |
| `examples/expect/runtime_assertion.roc` | `build --opt` | Optimized builds | Expect still fires ⚠️ (opt not implemented) |

---

## Finding 1: Top-Level `expect` (Compile-Time)

### Behavior
- ✅ Evaluated at **compile time** (not runtime)
- ✅ Can **ONLY call pure functions**
- ✅ Run with `roc test` command (~3-8ms for multiple tests)
- ❌ Does NOT run when executing program with `roc run`
- ❌ Cannot call hosted functions (COMPTIME CRASH if attempted)

### Evidence Files
- `examples/expect/roc-test-positive.roc` - 7 passing tests
- `examples/expect/roc-test-negative.roc` - 3 failing tests
- `examples/expect/roc-test-refused.roc` - shows `roc test` ignores in-function expects (0 tests)

### Error Message Format (Compile-Time Failures)

```
Ran 3 test(s): 0 passed, 3 failed in 2.9ms
FAIL: examples/expect/roc-test-negative.roc:17
FAIL: examples/expect/roc-test-negative.roc:20
FAIL: examples/expect/roc-test-negative.roc:26
```

**Characteristics:**
- Minimal format: `FAIL: filename:line`
- No expected vs actual values
- No expression text shown
- All failures reported in summary
- Fast execution (~3-8ms)

### What Works

```roc
# Pure function calls
expect add(2, 3) == 5

# Block expects with pure functions
expect {
    x = 5
    y = 10
    add(x, y) == 15
}

# List operations
expect List.len([1, 2, 3]) == 3

# Multiple expects in sequence
expect test1() == result1
expect test2() == result2
expect test3() == result3
```

### What Fails

```roc
# Calling hosted function at top level
expect Stdout.line!("test") == ...  # COMPTIME CRASH

# Storing result of hosted function
result = Stdout.line!("test")       # COMPTIME CRASH
```

**Error:**
```
COMPTIME CRASH - Cannot call function: compile-time error (ident_not_in_scope)
```

---

## Finding 2: In-Function `expect` (Runtime)

### Behavior
- ✅ Evaluated at **runtime** (during program execution)
- ✅ **Can call hosted functions**
- ✅ Run with `roc run` command
- ❌ Does NOT run with `roc test`
- ⚠️ **Stops execution immediately on failure** (crash behavior)

### Evidence Files
- `examples/expect/roc-run-positive.roc` - 6 passing tests (including top-level hosted expect)
- `examples/expect/roc-run-negative.roc` - shows crash behavior (stops at Test A)
- `examples/expect/roc-run-negative-skipped.roc` - Test B run in isolation (block failure)
- `examples/expect/roc-run-refused.roc` - top-level pure expects ignored by `roc run`

### Error Message Format (Runtime Failures)

**Simple expect failure:**
```
Test A: Simple expect failure
expect failed: add(2, 3) == 999

Roc crashed: add(2, 3) == 999
```

**Block expect failure:**
```
Test B: Block expect failure
expect failed: {
        x = 5
        x == 999
    }

Roc crashed: {
        x = 5
        x == 999
    }
```

**Characteristics:**
- Shows `expect failed:` with full expression
- Shows `Roc crashed:` with same expression
- Multi-line blocks shown in full
- **Execution stops immediately** (no further tests run)
- More detailed than compile-time errors

### What Works

```roc
main! = |_args| {
    # Pure function calls
    expect add(2, 3) == 5

    # Hosted function calls
    _output = Stdout.line!("test")
    expect Bool.True

    # Block expects with hosted functions
    expect {
        _msg = Stdout.line!("test")
        Bool.True
    }

    # Multiple expects in sequence
    expect test1() == result1
    expect test2() == result2

    Ok({})
}
```

### Critical Behavior: Failure Stops Execution

Runtime expects stop immediately on failure. This is why `roc-run-negative.roc` only runs Test A.

**Result:** Subsequent tests (B, C) never execute when an earlier expect fails.

### The "Weirdo": Top-Level Pure Expects Ignored

**Weirdo #1: Silent Ignoring**
```roc
# At top level of file
expect add(1, 2) == 100  # Wrong! Should fail...
```

| Command | Behavior |
|---------|----------|
| `roc test` | ✅ Correctly FAILS |
| `roc run` | ❌ Silently IGNORED, program runs |

**Note:** Top-level expects with **hosted functions** fail with `roc test` (cannot evaluate at compile time) but work with `roc run`.
Only pure function expects at top level are ignored by `roc run`.

**Evidence File:** `examples/expect/roc-run-refused.roc`

### Complete Asymmetry: `roc test` vs `roc run`

The two commands run **completely disjoint sets** of expects:

| Expect location | Function type | `roc test` | `roc run` |
|-----------------|---------------|------------|-----------|
| Top-level | Pure | ✅ Runs | ❌ Ignores |
| Top-level | Hosted | ❌ Fails (un Evaluatable) | ✅ Runs |
| In-function | Pure | ❌ Ignores | ✅ Runs |
| In-function | Hosted | ❌ Ignores | ✅ Runs |

**Key insight:** There is no overlap - `roc test` only runs top-level pure expects. Everything else is either ignored or fails.

---

## Finding 3: Block `expect` Behavior

### Top-Level Block Expects

```roc
# Works at compile time
expect {
    x = 5
    y = 10
    add(x, y) == 15
}
```

- ✅ Evaluated at compile time
- ✅ Can call pure functions
- ❌ Cannot call hosted functions (COMPTIME CRASH)
- ✅ Last expression determines pass/fail

### In-Function Block Expects

```roc
main! = |_args| {
    # Works at runtime
    expect {
        _msg = Stdout.line!("test")
        Bool.True
    }

    Ok({})
}
```

- ✅ Evaluated at runtime
- ✅ Can call hosted functions
- ✅ Last expression determines pass/fail

---

## Finding 4: Test Execution Summary

### `roc test` (Compile-Time)

```
All (7) tests passed in 8.0 ms
```

- Runs **only top-level expects**
- Executes at compile time
- Pure functions only
- Very fast (~3-8ms)
- All tests run (report all failures)
- Continues after failures

### `roc run` (Runtime)

```
=== Runtime Expect Tests (Positive) ===
✓ Test 1: Simple expect with pure function
✓ Test 2: Simple expect with hosted function
✓ Test 3: Block expect with pure function
✓ Test 4: Block expect with hosted function
✓ Test 5: Multiple expects in sequence
```

- Runs **only in-function expects**
- Executes at runtime
- Can call hosted functions
- Slower (program execution time)
- **Stops at first failure** (crash behavior)
- Manual test output needed

---

## Decision Tree: When to Use What

```
Need to test something?
│
├─ Is it a pure function (no `!` in signature)?
│  └─ YES → Use top-level `expect`, run with `roc test`
│           ✅ Fast (~3-8ms)
│           ✅ All tests run
│           ✅ Compile-time evaluation
│           ❌ Cannot test hosted functions
│
└─ Is it a hosted function (has `!` in signature)?
   └─ YES → Use in-function `expect`, run with `roc run`
            ✅ Can test hosted functions
            ✅ Runtime evaluation
            ✅ Full expression in errors
            ❌ Stops at first failure
            ❌ Slower (program execution)
```

---

## Verified Behaviors

| Fact | Evidence |
|------|----------|
| Top-level `expect` = compile time | `roc-test-positive.roc` runs in 8ms |
| Top-level `expect` = pure functions only | Attempting `Stdout.line!` causes COMPTIME CRASH |
| In-function `expect` = runtime | `roc-run-positive.roc` executes and prints |
| In-function `expect` can call hosted | `roc-run-positive.roc` calls `Stdout.line!` successfully |
| `roc test` only runs top-level expects | `roc-test-positive.roc` has `main!` but it's not executed |
| `roc run` only runs in-function expects | `roc-run-positive.roc` top-level expects not counted |
| Compile-time error format = minimal | `roc-test-negative.roc` shows only file:line |
| Runtime error format = detailed | `roc-run-neg-*.roc` shows full expressions |
| Runtime failures stop execution | `roc-run-negative.roc` stops at Test A, B/C never run |
| Block expects work both ways | Both test files use block expects successfully |

---

## Comparison: Compile-Time vs Runtime

| Aspect | Compile-Time (`roc test`) | Runtime (`roc run`) |
|--------|---------------------------|---------------------|
| **Location** | Top-level | In function body |
| **Function types** | Pure only | Pure + hosted |
| **Speed** | Very fast (~3-8ms) | Program execution time |
| **All tests run?** | ✅ Yes | ❌ No (stops at failure) |
| **Error detail** | Minimal (file:line) | Full expression shown |
| **Use case** | Unit tests | Integration/runtime assertions |
| **Can test FFI?** | ❌ No | ✅ Yes |
| **Optimization** | Removed in `--optimize` (when implemented) | Removed in `--optimize` (when implemented) |

---

## Practical Implications

### For Pure Functions

**Use:** Top-level `expect` with `roc test`

```roc
# my_module.roc
add : I64, I64 -> I64
add = |a, b| a + b

expect add(2, 3) == 5
expect add(-1, 1) == 0
expect add(0, 0) == 0
```

Run: `roc test my_module.roc`

### For Hosted Functions (Platform Code)

**Use:** In-function `expect` with `roc run`

```roc
# test/platform.roc
app [main!] { pf: platform "./platform/main.roc" }
import pf.Host

main! = |_args| {
    # Test pubkey generation
    secret = List.repeat(0, 32)
    pubkey = Host.pubkey!(secret)
    expect List.len(pubkey) == 32

    # Test signature
    # ...

    Ok({})
}
```

Run: `roc test/platform.roc`

### For Platform Development

**Hybrid approach:**

1. **Pure utility functions** → Top-level expects, `roc test`
2. **Platform API** → In-function expects, `roc run`
3. **FFI internals** → Zig tests, `zig build test`

---

## Remaining Questions

### Not Yet Tested

1. **Import behavior**
   - "as well as all the files they `import`" - what does this mean?
   - Do top-level expects in imported modules run?
   - Circular imports?

3. **Performance**
   - Exact timing for different test loads
   - Caching behavior

4. **Platform-specific**
   - Can `roc test` work at all in platform projects?
   - Are there file structure constraints?

---

## Conclusions

1. **Complete asymmetry:** `roc test` runs top-level pure expects only; `roc run` runs in-function expects (pure or hosted)
2. **No overlap:** The two commands test completely disjoint code - nothing is tested by both
3. **Different error formats:** Minimal at compile-time (file:line), detailed at runtime (full expression)
4. **Failure behavior:** Compile-time continues and reports all failures; runtime crashes immediately
5. **Optimization not yet implemented:** Runtime expects still fire in `--opt` builds (new compiler optimization pending)

**Recommendation:** Use `roc test` for pure function unit tests, use in-function expects for runtime/integration testing of hosted functions.

---

**Test Files:** `examples/expect/roc-{test,run}-{pos,neg}.roc`
**Last Updated:** 2025-01-27
**Status:** ✅ Core behavior confirmed
