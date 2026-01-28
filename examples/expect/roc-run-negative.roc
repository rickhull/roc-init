# roc-run-negative.roc
#
# Negative tests for `roc run` command (runtime behavior)
# All expects should FAIL to show runtime error message format
#
# Run: roc examples/expect/roc-run-negative.roc
#
# IMPORTANT: Runtime expect failures stop execution immediately.
# Only Test A will run. Test B will never execute.

app [main!] { pf: platform "https://github.com/lukewilliamboswell/roc-platform-template-zig/releases/download/0.6/2BfGn4M9uWJNhDVeMghGeXNVDFijMfPsmmVeo6M4QjKX.tar.zst" }

import pf.Stdout

# Pure function for testing
add : I64, I64 -> I64
add = |a, b| a + b

main! = |_args| {
    Stdout.line!("=== Runtime Expect Tests (Negative) ===")

    # ===== TEST A: Simple expect failure =====
    # This WILL RUN - execution stops here
    Stdout.line!("Test A: Simple expect failure")
    expect add(2, 3) == 999

    Stdout.line!("This will not print")

    # ===== TEST B: Block expect failure =====
    # This WILL NEVER RUN - execution stopped at Test A
    Stdout.line!("Test B: Block expect failure")
    expect {
        x = 5
        x == 999
    }

    Stdout.line!("This will not print")

    Ok({})
}
