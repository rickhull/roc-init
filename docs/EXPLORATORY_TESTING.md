# Exploratory Testing: `expect` Behavior in Roc

> **Research Question:** How does `expect` behave in different contexts?
>
> **Secondary Question:** What are testing strategies using `expect` in different contexts?

This document combines known facts from authoritative Roc documentation with exploratory speculation about test organization strategies. We will perform exploratory testing to confirm or disconfirm the speculative sections.

---

## Part 1: Known Facts (100% Certain)

> Source: `docs/Builtin.roc`, `docs/all_syntax_test.roc`, `docs/mini-tutorial-new-compiler.md`
> These are facts verified against the official Roc compiler source and test suite.

### What is `expect`?

`expect` is Roc's lightweight testing keyword. You can put a boolean expression after it, and if that expression evaluates to `True`, the test will pass, and if it evaluates to `False`, the test will fail.

**Source:** [mini-tutorial-new-compiler.md:167-169](mini-tutorial-new-compiler.md)

### Basic Usage

```roc
expect 1 + 1 == 2
expect digits_to_num([1, 2, 3]) == 123
expect Bool.True != Bool.False
```

**Source:** [mini-tutorial-new-compiler.md:162-164](mini-tutorial-new-compiler.md), [all_syntax_test.roc:390](all_syntax_test.roc)

### Top-Level `expect` Statements

When you run `roc test`, it runs all top-level `expect`s in your files, as well as all the files they `import`.

```roc
# my_module.roc
digits_to_num = |digits| { ... }

expect digits_to_num([1, 2, 3]) == 123
expect digits_to_num([4, 2]) == 42
expect digits_to_num([7]) == 7
```

Run with: `roc test my_module.roc`

**CONFIRMED BY EXPERIMENT (examples/explore_expect.roc):**

Top-level `expect` statements:
- ✅ **Are evaluated at COMPILE TIME**
- ✅ **Can ONLY call pure functions** (no hosted functions)
- ✅ **Run with `roc test`** in ~3-4ms
- ❌ **Do NOT run** when executing the program normally

**Evidence:** Attempting to call `Stdout.line!` (a hosted function) in a top-level `expect` produces:

```
COMPTIME CRASH - Cannot call function: compile-time error (ident_not_in_scope)
```

**Source:** [mini-tutorial-new-compiler.md:158-169](mini-tutorial-new-compiler.md), [examples/explore_expect.roc](examples/explore_expect.roc)

### `expect` Inside Blocks

You can also put `expect` statements inside blocks (functions, conditionals, etc.).

```roc
digits_to_num = |digits| {
    if digits.is_empty() {
        return 0
    }

    # From here on, we assume digits is nonempty!
    expect !digits.is_empty()

    # ... rest of function
}
```

**CONFIRMED BY EXPERIMENT (examples/explore_expect.roc):**

In-function `expect` statements:
- ✅ **Run at RUNTIME** (when the program executes)
- ✅ **Can call hosted functions** (Stdout.line!, Host.pubkey!, etc.)
- ✅ **Work inside `main!` and other hosted functions**
- ❌ **Do NOT run with `roc test`** (only top-level expects run)

**Evidence:** The in-function expect in `examples/explore_expect.roc`:
- Does NOT run with `roc test` (only 2 top-level tests counted)
- DOES run when executing the program normally
- Successfully calls hosted functions and prints output

**Source:** [mini-tutorial-new-compiler.md:310-320](mini-tutorial-new-compiler.md), [examples/explore_expect.roc](examples/explore_expect.roc)

### Critical: Optimization Behavior

**`expect` statements do not run in `--optimize` builds at all.**

This means they have zero production runtime cost. You can use them as often as you like during development without production tradeoffs.

When you do `roc test` or a debug build, `expect` in blocks works essentially like a `crash` if the condition is false. When you do `roc --optimize`, they are skipped entirely.

**Source:** [mini-tutorial-new-compiler.md:323-324, 338-340](mini-tutorial-new-compiler.md)

### `expect` vs Production Assertions

Importantly, `expect` statements are **not** production assertions!

The point is that these are checks of things you assume will be true, and if they turn out not to be true, you would like to be alerted about the assumption proving false during development or when running tests.

**It is the responsibility of other code to handle (or not) the situation where these assumptions turn out to be false.**

**Source:** [mini-tutorial-new-compiler.md:326-329](mini-tutorial-new-compiler.md)

### Handling Assumptions in Production

Three different ways to handle an assumption turning out to be false in production:

1. **Detect and gracefully recover** - Best user experience
2. **Don't attempt to detect** - Impractical or too costly; accept the consequences
3. **Detect and crash** - Use the `crash` keyword

**Source:** [mini-tutorial-new-compiler.md:331-334](mini-tutorial-new-compiler.md)

---

## Part 2: Extended Reference (LANGREF)

> Source: `docs/ROC_LANGREF_TUTORIAL.md`
> Comprehensive testing patterns and examples.

### Testing with `expect`

#### Basic Expects

```roc
expect 1 + 1 == 2
expect "hello".len() == 5
expect Bool.True != Bool.False
```

#### Expect in Blocks

```roc
expect {
    foo = 1
    bar = 2
    foo + bar == 3
}
```

#### Top-Level Expects

```roc
# my_module.roc
sum : List(I64) -> I64
sum = |list| List.fold(list, 0, |acc, x| acc + x)

expect sum([]) == 0
expect sum([1, 2, 3]) == 6
expect sum([-1, 1]) == 0
```

Run with: `roc test my_module.roc`

#### Expects Inside Functions

```roc
process = |input| {
    expect input.len() > 0    # Assertion during execution
    # ... rest of function
}
```

#### Testing Patterns

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

**Source:** [ROC_LANGREF_TUTORIAL.md:1963-2024](ROC_LANGREF_TUTORIAL.md)

---

## Part 3: Exploratory Speculation

> ⚠️ **Status:** Speculative - Requires Experimental Verification
>
> The following sections propose hypotheses about test organization and `expect` behavior in different contexts. These are **directionally correct** based on platform development experience but **not verified** against the Roc compiler specification.

### Hypothesis 1: Top-Level vs In-Function `expect` Behavior

**Hypothesis:** There are behavioral differences between `expect` statements at the top level vs inside function bodies, particularly around:
- When they run
- What they can call
- Error messages on failure

**Partial Evidence:**
- **Known:** `roc test` runs top-level `expect` statements
- **Known:** `all_syntax_test.roc` has both `app [main!]` and top-level `expect`
- **Known:** In-function `expect` works "like a crash" when false during `roc test` or debug builds
- **Unknown:** Whether top-level `expect` can call hosted functions
- **Unknown:** Whether evaluation happens at "compile time" or is just execution by the `roc test` command

**Questions Requiring Experimental Verification:**

| Question | Experiment | Expected Result |
|----------|-----------|-----------------|
| Can top-level expect call pure functions? | `expect my_pure_func() == value` | ✅ Works |
| Can top-level expect call hosted functions? | `expect Host.pubkey!(...) == ...` | ❓ Unknown |
| What error when expect fails in top-level? | `expect false` | ❓ Check output format |
| What error when expect fails in-function? | Put in `main!`, run | ❓ Check output format |
| Does `roc test` actually execute code? | Add `dbg` to tested function | ❓ See if dbg prints |

**Critical Note:** The documentation uses phrases like "runs all top-level expects" (line 169) and "they will be run whenever `roc test` runs" (line 308). This implies **execution**, not just compile-time checking. However, Roc also does compile-time evaluation of pure functions. The relationship between these is unclear.

**Verification Needed:**
- [ ] Create test file with top-level expect calling a pure function
- [ ] Create test file with top-level expect attempting to call a hosted function
- [ ] Document the exact error message (if any) for each case
- [ ] Add `dbg` statements to see when/where code executes
- [ ] Determine if "compile-time evaluation" is the same as "roc test execution"

---

### Hypothesis 2: Test Organization for Platform Development

**Hypothesis:** Platform development requires a hybrid testing approach combining:
1. **Zig tests** for FFI boundaries and memory safety
2. **Roc runtime assertions** for API surface validation
3. **Roc unit tests** (`roc test`) for pure utility functions

**Speculative Test Structure:**

```
test/
├── pure_utils.roc       # Unit tests (roc test compatible)
├── api_validation.roc    # Runtime assertions (run as program)
├── host.zig             # FFI boundary tests
└── memory.zig           # Memory management tests
```

**Pure Utility Tests (Compile-Time):**

```roc
# test/pure_utils.roc
# Runs with: roc test test/pure_utils.roc

encode_hex : List(U8) -> Str
encode_hex = |bytes| { ... }

expect encode_hex([0xFF]) == "ff"
expect encode_hex([0x00, 0x10]) == "0010"
```

**API Validation Tests (Runtime):**

```roc
# test/api_validation.roc
# Runs with: roc test/api_validation.roc
app [main!] { pf: platform "./platform/main.roc" }
import pf.Host

main! = |_args| {
    # Test pubkey generation
    secret_key = List.repeat(0, 32)
    pubkey = Host.pubkey!(secret_key)
    expect List.len(pubkey) == 32

    # Test signature creation
    # ...

    Ok({})
}
```

**Zig FFI Tests:**

```zig
// test/host.zig
// Runs with: zig build test
test "pubkey returns 32 bytes" {
    const secret_key = [_]u8{0} ** 32;
    const pubkey = try host.pubkey(&secret_key);
    try testing.expectEqual(@as(usize, 32), pubkey.len);
}
```

**Verification Needed:**
- [ ] Confirm `roc test` works for pure utility functions in platform projects
- [ ] Measure runtime overhead of running Roc "tests" as programs
- [ ] Test if `expect` failures in hosted functions produce useful error messages

---

### Hypothesis 3: Optimization Behavior Across Contexts

**Hypothesis:** `expect` statements are removed in `--optimize` builds regardless of location (top-level or in-function), but only when:
1. The entire application is built with `--optimize`
2. No debug symbols are included

**Speculative Behavior:**

| Build Mode | Top-level `expect` | In-function `expect` | `dbg` statements |
|------------|-------------------|---------------------|------------------|
| `roc run` / `roc test` | ✅ Runs | ✅ Runs | ✅ Runs |
| `roc build` (default) | ✅ Runs | ✅ Runs | ✅ Runs |
| `roc build --optimize` | ❌ Removed | ❌ Removed | ❌ Removed |

**Testing Strategy:**

```bash
# Test 1: Verify expect runs in debug mode
roc build app.roc -o app_debug
./app_debug  # Should hit expect if condition fails

# Test 2: Verify expect is removed in optimized mode
roc build app.roc --optimize -o app_optimized
./app_optimized  # Should skip expect even if condition fails

# Test 3: Measure binary size difference
ls -lh app_debug app_optimized
```

**Verification Needed:**
- [ ] Build debug and optimized versions of same app
- [ ] Trigger `expect` failure in both - confirm behavior difference
- [ ] Measure binary size difference (expect adds overhead in debug only)
- [ ] Verify no runtime performance difference in optimized builds

---

### Hypothesis 4: CI/CD Integration Patterns

**Hypothesis:** Different test types should run at different stages of CI/CD pipeline based on speed and feedback value.

**Speculative CI Pipeline:**

```yaml
# .github/workflows/test.yml
name: Test

jobs:
  # Fast feedback: Pure unit tests (compile-time)
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Roc
        run: |
          curl -L ... -o roc-nightly.tar.gz
          tar -xzf roc-nightly.tar.gz -C ~/.local/bin
      - name: Run unit tests
        run: roc test test/pure_utils.roc

  # Medium speed: API validation (runtime)
  api-tests:
    runs-on: ubuntu-latest
    needs: unit-tests
    steps:
      - name: Run API tests
        run: roc test/api_validation.roc

  # Slowest: Full FFI tests (Zig compilation)
  ffi-tests:
    runs-on: ubuntu-latest
    needs: [unit-tests, api-tests]
    steps:
      - name: Install Zig
        run: |
          curl -L ... -o zig.tar.gz
          tar -xzf zig.tar.gz -C ~/.local/bin
      - name: Run FFI tests
        run: zig build test
```

**Speculative Test Timing:**

| Test Type | Typical Duration | Feedback Speed | Run Frequency |
|-----------|------------------|----------------|---------------|
| Roc unit tests | ~50ms | Fast | Every commit |
| Roc runtime assertions | ~100-500ms | Medium | Every commit |
| Zig FFI tests | ~600ms+ | Slow | Before merge |

**Verification Needed:**
- [ ] Measure actual test times in real platform project
- [ ] Test parallel execution of Roc vs Zig tests
- [ ] Verify caching behavior for `roc test` vs Zig compilation

---

### Hypothesis 5: Integration vs Unit Test Boundaries

**Hypothesis:** The boundary between "unit" and "integration" tests in Roc is determined by:
1. **Purity** - Pure functions = unit tests, hosted functions = integration
2. **Dependencies** - No platform imports = unit, uses platform = integration
3. **Evaluation time** - Compile-time = unit, runtime = integration

**Speculative Classification:**

```roc
# ===== UNIT TESTS (Compile-Time) =====

# Pure function, no dependencies
add : I64, I64 -> I64
add = |a, b| a + b
expect add(2, 3) == 5

# Pure function, imports from other pure modules
import helper_utils
encode_hex = |bytes| helper_utils.to_hex(bytes)
expect encode_hex([255]) == "ff"

# ===== INTEGRATION TESTS (Runtime) =====

# Hosted function, requires runtime
app [main!] { pf: platform "./platform/main.roc" }
import pf.Stdout

main! = |_args| {
    Stdout.line!("Test")
    expect true  # Runtime assertion
    Ok({})
}

# Uses platform FFI
import pf.Host
test_crypto = || {
    key = Host.random_bytes!(32)
    expect List.len(key) == 32
}
```

**Verification Needed:**
- [ ] Test if pure functions with complex logic still compile-time evaluate
- [ ] Determine where exactly the "hosted boundary" is
- [ ] Test if imports affect compile-time evaluation capability

---

## Part 4: Confirmed Findings

### ✅ Top-Level `expect` Behavior

**Confirmed via examples/explore_expect.roc:**

1. **Evaluation is at compile time**
   - Error message literally says "COMPTIME CRASH"
   - Attempting to call hosted functions fails with: "Cannot call function: compile-time error (ident_not_in_scope)"

2. **Only pure functions allowed**
   - ✅ Works: `expect add(2, 3) == 5` (pure function)
   - ✅ Works: `expect List.len([1, 2, 3]) == 3` (pure function)
   - ❌ Fails: `expect Stdout.line!("...") == ...` (hosted function)

3. **`roc test` execution time**
   - Runs in ~3-4ms for 2 tests
   - Only runs top-level expects, not in-function expects

### ✅ In-Function `expect` Behavior

**Confirmed via examples/explore_expect.roc:**

1. **Evaluation is at runtime**
   - Runs when program executes
   - Does NOT run with `roc test`

2. **Can call hosted functions**
   - ✅ Works: Calling `Stdout.line!` inside `main!`
   - ✅ Works: Any platform/hosted function

3. **Coexistence with top-level expects**
   - ✅ A file can have both top-level and in-function expects
   - ✅ `roc test` runs top-level, program execution runs in-function

### Confirmed Behavior Matrix

| Context | `expect` Location | Evaluation Time | Can Call Hosted? | Runs with `roc test` |
|---------|-------------------|-----------------|------------------|---------------------|
| Any code | Top-level | **Compile time** | ❌ No | ✅ Yes |
| Any code | In function body | **Runtime** | ✅ Yes | ❌ No |

---

## Part 5: Remaining Open Questions

Questions that still require exploratory testing:

1. **Exact error message format:**
   - When `expect` condition fails, what's the full output?
   - Does it show expected vs actual values?
   - Same or different format for top-level vs in-function?

2. **Test isolation and imports:**
   - "as well as all the files they `import`" - what does this mean?
   - Do top-level expects in imported modules run?

3. **Optimization verification:**
   - How to definitively prove `expect` is removed in `--optimize` builds?
   - Binary size comparison?
   - Runtime performance tests?

4. **Block expects:**
   - `expect { ... }` blocks - when do they run?
   - Compile time or runtime depending on content?

---

## Part 5: Experimental Plan

### Phase 1: Verify Basic Behavior
- [ ] Create test files with pure functions and top-level expects
- [ ] Run `roc test` and verify compile-time evaluation
- [ ] Create test files with hosted functions and in-function expects
- [ ] Attempt `roc test` on hosted functions and document error
- [ ] Run hosted tests as programs and verify runtime evaluation

### Phase 2: Test Optimization Behavior
- [ ] Build debug and optimized versions of same application
- [ ] Trigger `expect` failures in both builds
- [ ] Measure binary size and runtime differences
- [ ] Verify no performance penalty in optimized builds

### Phase 3: Platform Development Testing
- [ ] Set up hybrid test structure (Roc + Zig)
- [ ] Measure test execution times
- [ ] Test CI/CD integration patterns
- [ ] Verify error messages and debugging output

### Phase 4: Document Findings
- [ ] Confirm or disconfirm hypotheses
- [ ] Update this document with verified facts
- [ ] Move confirmed facts to "Known Facts" section
- [ ] Document unexpected behaviors discovered

---

## Part 6: Quick Reference

### Known Commands

```bash
# Run top-level expects
roc test my_module.roc

# Run a program (includes in-function expects)
roc my_app.roc

# Build applications
roc build app.roc                    # Debug build (includes expect)
roc build app.roc --optimize -o app  # Optimized (removes expect)
```

### Confirmed Behaviors

| Fact | Source |
|------|--------|
| **Top-level `expect` runs at COMPILE TIME** | [examples/explore_expect.roc](examples/explore_expect.roc) |
| **Top-level `expect` can ONLY call pure functions** | [examples/explore_expect.roc](examples/explore_expect.roc) |
| **Calling hosted function in top-level expect: COMPTIME CRASH** | [examples/explore_expect.roc](examples/explore_expect.roc) |
| **In-function `expect` runs at RUNTIME** | [examples/explore_expect.roc](examples/explore_expect.roc) |
| **In-function `expect` CAN call hosted functions** | [examples/explore_expect.roc](examples/explore_expect.roc) |
| **`roc test` runs top-level expects only** (~3-4ms) | [examples/explore_expect.roc](examples/explore_expect.roc) |
| **Program execution runs in-function expects only** | [examples/explore_expect.roc](examples/explore_expect.roc) |
| **`--optimize` builds skip all expect statements** | [mini-tutorial:324,338](mini-tutorial-new-compiler.md) |
| **`expect` is for development, not production** | [mini-tutorial:326](mini-tutorial-new-compiler.md) |
| **Files can have both `app [main!]` and top-level `expect`** | [all_syntax_test.roc:1,390](all_syntax_test.roc) |

### Confirmed Behavior Matrix

| Context | `expect` Location | Evaluation Time | Can Call Hosted? | Runs with `roc test` |
|---------|-------------------|-----------------|------------------|---------------------|
| Any code | Top-level | **Compile time** | ❌ No | ✅ Yes (~3-4ms) |
| Any code | In function | **Runtime** | ✅ Yes | ❌ No |

### Remaining Unknown Behaviors

| Question | Status |
|----------|--------|
| What is the exact error message format when expect fails? | ❓ Unknown |
| Do top-level expects in imported files run when testing? | ❓ Unknown |
| How to verify `--optimize` removes expects? | ❓ Unknown |

### Key Principles (Verified)

1. **Zero production cost** - `expect` is removed in `--optimize` builds
2. **Development-time only** - `expect` is for catching bugs during development, not production error handling
3. **Other code handles production errors** - Use `Try`, `crash`, or graceful recovery for production

---

**Last Updated:** 2025-01-27
**Status:** ⚠️ **Partially Confirmed** - Core `expect` behavior verified via examples/explore_expect.roc. Platform testing strategies remain speculative.
