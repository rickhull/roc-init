# Exploratory testing: How does `expect` behave in different contexts?
#
# Run as program:  roc examples/explore_expect.roc
# Run with test:   roc test examples/explore_expect.roc

app [main!] { pf: platform "https://github.com/lukewilliamboswell/roc-platform-template-zig/releases/download/0.6/2BfGn4M9uWJNhDVeMghGeXNVDFijMfPsmmVeo6M4QjKX.tar.zst" }

import pf.Stdout

# Test 1: Top-level expect with pure function
add : I64, I64 -> I64
add = |a, b| a + b

expect add(2, 3) == 5

# Test 2: Top-level expect with list operations
expect List.len([1, 2, 3]) == 3

# Test 3: Attempting to call hosted function at top level
# This causes: COMPTIME CRASH - Cannot call function: compile-time error (ident_not_in_scope)
# Uncomment to verify:
# result = Stdout.line!("top-level")

# Test 3: In-function expect inside main!
main! = |_args| {
    result = add(10, 20)

    Stdout.line!("Running in-function expect...")
    expect result == 30

    Stdout.line!("All expects passed!")

    Ok({})
}
