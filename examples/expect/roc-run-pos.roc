# roc-run-pos.roc
#
# Positive tests for `roc run` command (runtime behavior)
# All expects should PASS
#
# Run: roc examples/roc-run-pos.roc

app [main!] { pf: platform "https://github.com/lukewilliamboswell/roc-platform-template-zig/releases/download/0.6/2BfGn4M9uWJNhDVeMghGeXNVDFijMfPsmmVeo6M4QjKX.tar.zst" }

import pf.Stdout

# Pure function for testing
add : I64, I64 -> I64
add = |a, b| a + b

main! = |_args| {
    Stdout.line!("=== Runtime Expect Tests (Positive) ===")

    # Test 1: Simple expect with pure function
    expect add(2, 3) == 5
    Stdout.line!("✓ Test 1: Simple expect with pure function")

    # Test 2: Simple expect with hosted function
    _output = Stdout.line!("Test 2: Calling hosted function")
    expect Bool.True
    Stdout.line!("✓ Test 2: Simple expect with hosted function")

    # Test 3: Block expect with pure function
    expect {
        result = add(10, 20)
        result == 30
    }
    Stdout.line!("✓ Test 3: Block expect with pure function")

    # Test 4: Block expect with hosted function
    expect {
        _msg = Stdout.line!("Test 4: Hosted in block")
        Bool.True
    }
    Stdout.line!("✓ Test 4: Block expect with hosted function")

    # Test 5: Multiple expects in sequence
    expect add(1, 1) == 2
    expect add(2, 2) == 4
    expect add(3, 3) == 6
    Stdout.line!("✓ Test 5: Multiple expects in sequence")

    Stdout.line!("")
    Stdout.line!("=== All tests passed! ===")

    Ok({})
}
