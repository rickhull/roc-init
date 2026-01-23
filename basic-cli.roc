app [main!] { pf: platform "../basic-cli/platform/main.roc" }

import pf.Stdout

main! = |_args| {
    Stdout.line!("Hello, World!")
    Ok({})
}
