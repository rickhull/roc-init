app [main!] { pf: platform "https://github.com/lukewilliamboswell/roc-platform-template-rust/releases/download/0.1/H8GgQfvW5hwgAwbwRJ1Whmq3CAX3A5dGbZWHefB6NXtN.tar.zst" }

import pf.Stdout

main! = |_args| {
    Stdout.line!("Hello, World!")
    Ok({})
}
