# roc-test-positive.roc
#
# Positive tests for `roc test` command (compile-time behavior)
# All expects should PASS
#
# Run: roc test examples/expect/roc-test-positive.roc

app [main!] { pf: platform "https://github.com/lukewilliamboswell/roc-platform-template-zig/releases/download/0.6/2BfGn4M9uWJNhDVeMghGeXNVDFijMfPsmmVeo6M4QjKX.tar.zst" }

import pf.Stdout

# Pure functions for testing
add : I64, I64 -> I64
add = |a, b| a + b

double : I64 -> I64
double = |x| x * 2

# Test 1: Simple expect with pure function (top-level)
expect add(2, 3) == 5

# Test 2: Another simple expect
expect double(21) == 42

# Test 3: Block expect with pure function (top-level)
expect {
    result = add(10, 20)
    result == 30
}

# Test 4: Block expect with multiple operations
expect {
    x = 5
    y = 10
    add(x, y) == 15
}

# Test 5: Block expect with nested function calls
expect {
    input = 7
    doubled = double(input)
    add(doubled, 1) == 15
}

# Test 6: List operations in expect
expect List.len([1, 2, 3, 4, 5]) == 5

# Test 7: Block expect with list operations
expect {
    numbers = [1, 2, 3]
    sum = List.fold(numbers, 0, |acc, x| acc + x)
    sum == 6
}

# Note: main! exists but is NOT run by roc test
main! = |_args| {
    Stdout.line!("This main! is NOT executed by roc test")
    Ok({})
}
