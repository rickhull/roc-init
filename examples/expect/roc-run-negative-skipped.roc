# roc-run-negative-skipped.roc
#
# Demonstrates: Test that WOULD fail, but is SKIPPED due to earlier failure
#
# Run: roc examples/expect/roc-run-negative-skipped.roc
#
# In roc-run-negative.roc, this test (Test B) never runs because execution
# stops at Test A's failure. This file runs Test B in isolation to show
# what a block expect failure looks like.

app [main!] { pf: platform "https://github.com/lukewilliamboswell/roc-platform-template-zig/releases/download/0.6/2BfGn4M9uWJNhDVeMghGeXNVDFijMfPsmmVeo6M4QjKX.tar.zst" }

import pf.Stdout

add : I64, I64 -> I64
add = |a, b| a + b

main! = |_args| {
    Stdout.line!("Test B: Block expect failure (skipped in master file)")

    expect {
        x = 5
        x == 999
    }

    Stdout.line!("This will not print")

    Ok({})
}
