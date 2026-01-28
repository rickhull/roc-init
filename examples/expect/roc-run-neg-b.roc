# roc-run-neg-b.roc
#
# Negative test B: Block expect failure
#
# Run: roc examples/expect/roc-run-neg-b.roc

app [main!] { pf: platform "https://github.com/lukewilliamboswell/roc-platform-template-zig/releases/download/0.6/2BfGn4M9uWJNhDVeMghGeXNVDFijMfPsmmVeo6M4QjKX.tar.zst" }

import pf.Stdout

add : I64, I64 -> I64
add = |a, b| a + b

main! = |_args| {
    Stdout.line!("Test B: Block expect failure")

    expect {
        x = 5
        x == 999
    }

    Stdout.line!("This will not print")

    Ok({})
}
