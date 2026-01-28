# roc-run-neg-c.roc
#
# Negative test C: The "weirdos" - tests that are refused/rejected
#
# Run: roc examples/expect/roc-run-neg-c.roc
#
# These demonstrate edge cases where expects don't behave as expected:
# 1. Top-level expects are SILENTLY IGNORED by `roc run`
# 2. Calling hosted functions at top level causes COMPTIME CRASH

app [main!] { pf: platform "https://github.com/lukewilliamboswell/roc-platform-template-zig/releases/download/0.6/2BfGn4M9uWJNhDVeMghGeXNVDFijMfPsmmVeo6M4QjKX.tar.zst" }

import pf.Stdout

add : I64, I64 -> I64
add = |a, b| a + b

# WEIRDO #1: Top-level expect - SILENTLY IGNORED by `roc run`
# This will PASS with `roc test` but be COMPLETELY IGNORED with `roc run`
expect add(1, 2) == 100  # Should fail, but roc run doesn't care

# WEIRDO #2: Calling hosted function at top level - COMPTIME CRASH
# Uncomment to see: COMPTIME CRASH - Cannot call function
# expect Stdout.line!("test") == Bool.True

main! = |_args| {
    Stdout.line!("=== C: The Weirdos ===")
    Stdout.line!("Weirdo #1: Top-level expect with wrong value")
    Stdout.line!("  Expected: COMPILE-TIME FAILURE (roc test)")
    Stdout.line!("  Actual: SILENTLY IGNORED (roc run)")
    Stdout.line!("  The top-level 'expect add(1, 2) == 100' was never checked!")

    Stdout.line!("")
    Stdout.line!("Weirdo #2: Hosted function at top level")
    Stdout.line!("  Expected: COMPILE-TIME CRASH")
    Stdout.line!("  (Commented out - see file to test)")

    Ok({})
}
