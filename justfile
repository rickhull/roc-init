# Justfile for roc-init

# Configuration
install_root := env_var_or_default("HOME", "") + "/.local"

# Fetch latest Roc reference docs to docs/
fetch:
    #!/usr/bin/env bash
    set -e
    echo "Fetching Roc reference docs from GitHub..."

    # Fetch Builtin.roc
    curl -s https://raw.githubusercontent.com/roc-lang/roc/main/src/build/roc/Builtin.roc \
        -o docs/Builtin.roc
    echo "  ✓ docs/Builtin.roc"

    # Fetch all_syntax_test.roc
    curl -s https://raw.githubusercontent.com/roc-lang/roc/main/test/fx/all_syntax_test.roc \
        -o docs/all_syntax_test.roc
    echo "  ✓ docs/all_syntax_test.roc"

    echo ""
    echo "✓ Reference docs updated successfully!"
    echo "  - docs/Builtin.roc ($(wc -l < docs/Builtin.roc) lines)"
    echo "  - docs/all_syntax_test.roc ($(wc -l < docs/all_syntax_test.roc) lines)"
