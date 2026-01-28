# roc-run-neg-c.roc
#
# Negative test C: Expect failure after successful expects
#
# Run: roc examples/roc-run-neg-c.roc

app [main!] { pf: platform "https://github.com/lukewilliamboswell/roc-platform-template-zig/releases/download/0.6/2BfGn4M9uWJNhDVeMghGeXNVDFijMfPsmmVeo6M4QjKX.tar.zst" }

import pf.Stdout

add : I64, I64 -> I64
add = |a, b| a + b

main! = |_args| {
    Stdout.line!("Test C: Expect failure after passing expects")

    # These pass
    expect add(1, 1) == 2
    Stdout.line!("✓ First expect passed")

    expect add(2, 2) == 4
    Stdout.line!("✓ Second expect passed")

    # This fails
    expect add(3, 3) == 999

    Stdout.line!("This will not print")

    Ok({})
}
