# roc-run-neg.roc
#
# Negative tests for `roc run` command (runtime behavior)
# All expects should FAIL to show runtime error message format
#
# Run: roc examples/expect/roc-run-neg.roc
#
# IMPORTANT: Runtime expect failures stop execution immediately.
# Only Test A will run. Tests B and C will never execute.
#
# Test C: "The weirdos" - tests that are refused/rejected rather than failing

app [main!] { pf: platform "https://github.com/lukewilliamboswell/roc-platform-template-zig/releases/download/0.6/2BfGn4M9uWJNhDVeMghGeXNVDFijMfPsmmVeo6M4QjKX.tar.zst" }

import pf.Stdout

# Pure function for testing
add : I64, I64 -> I64
add = |a, b| a + b

# WEIRDO #1: Top-level expect - SILENTLY IGNORED by `roc run`
# This would FAIL with `roc test` but is COMPLETELY IGNORED with `roc run`
expect add(1, 2) == 999  # Wrong! But roc run doesn't care

# WEIRDO #2: Calling hosted function at top level - COMPTIME CRASH
# Uncomment to see compiler crash:
# expect Stdout.line!("test") == Bool.True

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

    # ===== TEST C: The "weirdos" =====
    # This WILL NEVER RUN - execution stopped at Test A
    # See roc-run-neg-c.roc for standalone version
    Stdout.line!("Test C: The weirdos (refused/rejected tests)")

    # Weirdo #1: Top-level expects are silently ignored by roc run
    # (defined at top of file, outside main!)

    # Weirdo #2: Hosted functions at top level cause COMPTIME CRASH
    # (would crash compiler before program runs)

    Stdout.line!("This will not print")

    Ok({})
}
