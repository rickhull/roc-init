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

**Source:** [mini-tutorial-new-compiler.md:158-169](mini-tutorial-new-compiler.md)

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

**Source:** [mini-tutorial-new-compiler.md:310-320](mini-tutorial-new-compiler.md)

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

### Hypothesis 1: Compile-Time vs Runtime Evaluation

**Hypothesis:** Top-level `expect` statements are evaluated at compile time when possible, but `expect` inside hosted functions (`main!`, platform functions) requires runtime evaluation.

**Rationale:**
- Roc performs constant folding and compile-time evaluation of pure functions
- Hosted functions (marked with `!`) perform I/O and require runtime
- Platform functions are all hosted

**Speculative Behavior Matrix:**

| Context | `expect` Location | Evaluation Time | Can Use `roc test` |
|---------|-------------------|-----------------|-------------------|
| Pure function | Top-level | Compile-time | ✅ Yes |
| Pure function | Inside function body | Compile-time (if constant) | ✅ Yes |
| Hosted function (`main!`) | Inside function body | Runtime | ❌ No |
| Platform call | Inside `main!` | Runtime | ❌ No |

**Testing Strategy:**
```bash
# Pure functions - compile-time evaluation
roc test pure_functions.roc

# Hosted functions - must run as program
roc test_hosted.roc
```

**Verification Needed:**
- [ ] Confirm error message when using `roc test` with hosted functions
- [ ] Verify top-level expects are truly compile-time (no runtime execution)
- [ ] Test if `roc build --optimize` removes all `expect` statements

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

## Part 4: Open Questions

Questions that require exploratory testing to answer:

1. **Exact error message:** What is the precise error when running `roc test` on a file with hosted functions?
2. **Constant folding limits:** How complex can a pure function be before Roc stops compile-time evaluation?
3. **Platform testing:** Can `roc test` work at all in a platform project, or are all tests runtime?
4. **Expect failure output:** What information do `expect` failures provide in runtime vs compile-time contexts?
5. **Optimization verification:** How can we definitively prove `expect` is removed in `--optimize` builds?
6. **Test isolation:** Do top-level expects in imported files run when testing a specific file?
7. **dbg vs expect:** Does `dbg` have the same optimization behavior as `expect`?

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

### Commands

```bash
# Unit tests (pure functions, compile-time)
roc test test/pure_utils.roc

# Runtime tests (hosted functions)
roc test/api_validation.roc

# Build applications
roc build app.roc                    # Debug build (includes expect)
roc build app.roc --optimize -o app  # Optimized (removes expect)

# Platform tests
zig build test                       # Run Zig FFI tests
```

### Decision Tree

```
Need to test a function?
│
├─ Is it pure (no `!` in signature)?
│  └─ YES → Use top-level `expect`, run with `roc test`
│
└─ Is it hosted (has `!` in signature)?
   └─ YES → Use in-function `expect`, run as program
```

### Key Principles

1. **Purity determines testability** - Only pure functions can use `roc test`
2. **Zero production cost** - `expect` is removed in `--optimize` builds
3. **Development-time only** - `expect` is for catching bugs during development, not production error handling
4. **Hosted = Runtime** - Platform functions always require runtime evaluation

---

**Last Updated:** 2025-01-27
**Status:** Exploratory - Speculative sections require experimental verification
