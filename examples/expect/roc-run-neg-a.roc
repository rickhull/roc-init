# roc-run-neg-a.roc
#
# Negative test A: Simple expect failure
#
# Run: roc examples/expect/roc-run-neg-a.roc

app [main!] { pf: platform "https://github.com/lukewilliamboswell/roc-platform-template-zig/releases/download/0.6/2BfGn4M9uWJNhDVeMghGeXNVDFijMfPsmmVeo6M4QjKX.tar.zst" }

import pf.Stdout

add : I64, I64 -> I64
add = |a, b| a + b

main! = |_args| {
    Stdout.line!("Test A: Simple expect failure")

    expect add(2, 3) == 999

    Stdout.line!("This will not print")

    Ok({})
}
