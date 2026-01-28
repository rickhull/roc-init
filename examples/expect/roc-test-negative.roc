# roc-test-negative.roc
#
# Negative tests for `roc test` command (compile-time behavior)
# All expects should FAIL to show error message format
#
# Run: roc test examples/expect/roc-test-negative.roc

app [main!] { pf: platform "https://github.com/lukewilliamboswell/roc-platform-template-zig/releases/download/0.6/2BfGn4M9uWJNhDVeMghGeXNVDFijMfPsmmVeo6M4QjKX.tar.zst" }

import pf.Stdout

# Pure function for testing
add : I64, I64 -> I64
add = |a, b| a + b

# Test 1: Simple expect that fails (wrong result)
expect add(2, 3) == 999

# Test 2: Block expect that fails
expect {
    x = 5
    x == 999
}

# Test 3: Another simple failure
expect add(10, 20) == 999
