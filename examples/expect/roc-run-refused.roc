# roc-run-refused.roc
#
# Refused by `roc run`: Top-level expects with pure functions are SILENTLY IGNORED
#
# Run: roc examples/expect/roc-run-refused.roc
#
# This demonstrates that `roc run` IGNORES top-level expects (unlike `roc test`).
# The expect below is WRONG (1+2≠100) but `roc run` doesn't care.

app [main!] { pf: platform "https://github.com/lukewilliamboswell/roc-platform-template-zig/releases/download/0.6/2BfGn4M9uWJNhDVeMghGeXNVDFijMfPsmmVeo6M4QjKX.tar.zst" }

import pf.Stdout

add : I64, I64 -> I64
add = |a, b| a + b

# Top-level expect - SILENTLY IGNORED by `roc run`, CHECKED by `roc test`
# This is WRONG (should be 3, not 100) but roc run ignores it completely
expect add(1, 2) == 100

main! = |_args| {
    Stdout.line!("=== Refused: Top-level expects ignored by roc run ===")
    Stdout.line!("The expect 'add(1, 2) == 100' is WRONG, but roc run doesn't check it.")
    Stdout.line!("Try: roc test examples/expect/roc-run-refused.roc")
    Stdout.line!("Expected: FAIL - Top-level expects run with roc test")

    Ok({})
}
