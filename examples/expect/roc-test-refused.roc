# roc-test-refused.roc
#
# Refused by `roc test`: In-function expects are COMPLETELY IGNORED
#
# Run: roc test examples/expect/roc-test-refused.roc
# Run: roc run examples/expect/roc-test-refused.roc
#
# This demonstrates that `roc test` IGNORES in-function expects (unlike `roc run`).
# All expects below are in main!, so roc test returns 0 tests.

app [main!] { pf: platform "https://github.com/lukewilliamboswell/roc-platform-template-zig/releases/download/0.6/2BfGn4M9uWJNhDVeMghGeXNVDFijMfPsmmVeo6M4QjKX.tar.zst" }

import pf.Stdout

add : I64, I64 -> I64
add = |a, b| a + b

# NO top-level expects here - only in-function expects below

main! = |_args| {
    Stdout.line!("=== Refused: In-function expects ignored by roc test ===")

    # These expects are IGNORED by roc test, RUN by roc run
    expect add(1, 2) == 3
    Stdout.line!("✓ Test 1 passed (roc run only)")

    expect add(5, 10) == 15
    Stdout.line!("✓ Test 2 passed (roc run only)")

    Stdout.line!("Try: roc test examples/expect/roc-test-refused.roc")
    Stdout.line!("Expected: Ran 0 test(s) - in-function expects ignored")

    Ok({})
}
