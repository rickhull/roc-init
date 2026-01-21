# Justfile for roc-init

# Configuration
install_root := env_var_or_default("HOME", "") + "/.local"
curl_cmd := "curl -L -s -S"

# Fetch latest Roc reference docs to docs/ using ETag caching
fetch:
    #!/usr/bin/env bash
    set -e
    cache_dir="cache/roc-docs"
    mkdir -p "$cache_dir" docs
    etag_file="$cache_dir/Builtin.roc.etag"

    echo "Fetching Roc reference docs from GitHub..."

    status=$({{curl_cmd}} https://raw.githubusercontent.com/roc-lang/roc/main/src/build/roc/Builtin.roc \
        -o docs/Builtin.roc \
        --etag-save "$etag_file" \
        --etag-compare "$etag_file" \
        -w "%{http_code}")
    if [ "$status" = "200" ] || [ "$status" = "304" ]; then
        echo "  ✓ docs/Builtin.roc ($status)"
    else
        echo "  ✗ Failed to fetch Builtin.roc (HTTP $status)"
        exit 1
    fi

    etag_file="$cache_dir/all_syntax_test.roc.etag"
    status=$({{curl_cmd}} https://raw.githubusercontent.com/roc-lang/roc/main/test/fx/all_syntax_test.roc \
        -o docs/all_syntax_test.roc \
        --etag-save "$etag_file" \
        --etag-compare "$etag_file" \
        -w "%{http_code}")
    if [ "$status" = "200" ] || [ "$status" = "304" ]; then
        echo "  ✓ docs/all_syntax_test.roc ($status)"
    else
        echo "  ✗ Failed to fetch all_syntax_test.roc (HTTP $status)"
        exit 1
    fi

    echo ""
    if [ "$status" = "304" ]; then
        echo "✓ Reference docs already up-to-date (cached)"
    else
        echo "✓ Reference docs updated successfully!"
    fi
    echo "  - docs/Builtin.roc ($(wc -l < docs/Builtin.roc) lines)"
    echo "  - docs/all_syntax_test.roc ($(wc -l < docs/all_syntax_test.roc) lines)"
