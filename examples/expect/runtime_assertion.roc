# runtime_assertion.roc
#
# Observes: in-function expects fire at runtime, even in optimized builds
#
# To verify:
#   roc build examples/expect/runtime_assertion.roc --opt=speed
#   ./runtime_assertion

app [main!] { pf: platform "https://github.com/lukewilliamboswell/roc-platform-template-zig/releases/download/0.6/2BfGn4M9uWJNhDVeMghGeXNVDFijMfPsmmVeo6M4QjKX.tar.zst" }

import pf.Stdout

main! = |_args| {
    Stdout.line!("Before expect")

    expect 1 == 999

    Stdout.line!("After expect - does not print")
    # If expect were optimized away, this would print

    Ok({})
}
