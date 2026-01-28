# Justfile for roc-init

# Configuration
install_root := env_var_or_default("HOME", "") + "/.local"
curl_cmd := "curl -L -s -S"
skill_name := "roc-language"

# Unit Tasks (no dependencies, no invocations)
# ---
# fetch-docs     - Fetch Roc reference docs with ETag cache
# install-rocgist - Install ~/.local/bin/rocgist
# install-skill   - Install {{skill_name}} skill (to ~/.claude or .claude)
# prune-roc       - Keep latest 3 Roc nightly cache entries
# tools-fetch     - Verify curl is available
# tools-rust      - Verify rustc and cargo are available

# Workflow Tasks (have dependencies or invocations)
# ---
# basic-cli      - Build basic-cli platform (tools-rust)
# check-nightly  - Check if installed Roc nightly is latest (tools-install)
# fetch-roc      - Fetch roc-nightly to cache/ (tools-install)
# install-roc    - Install roc to ~/.local (tools-install fetch-roc)
# tools-install  - Verify jq is available (tools-fetch)
# update-docs    - Fetch docs and install to user skill (fetch-docs install-skill)


#
# Unit Tasks
# ==========


# Fetch latest Roc reference docs to docs/ using ETag caching
fetch-docs:
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

    etag_file="$cache_dir/mini-tutorial-new-compiler.md.etag"
    status=$({{curl_cmd}} https://raw.githubusercontent.com/roc-lang/roc/main/docs/mini-tutorial-new-compiler.md \
        -o docs/mini-tutorial-new-compiler.md \
        --etag-save "$etag_file" \
        --etag-compare "$etag_file" \
        -w "%{http_code}")
    if [ "$status" = "200" ] || [ "$status" = "304" ]; then
        echo "  ✓ docs/mini-tutorial-new-compiler.md ($status)"
    else
        echo "  ✗ Failed to fetch mini-tutorial-new-compiler.md (HTTP $status)"
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
    echo "  - docs/mini-tutorial-new-compiler.md ($(wc -l < docs/mini-tutorial-new-compiler.md) lines)"

# Install {{skill_name}} skill to user-level (~/.claude/skills/) or in-repo (.claude/skills/)
# Usage: just install-skill [LOCATION]
#   LOCATION (optional): ~, local, project, or repo (default: ~)
install-skill location="~":
    #!/usr/bin/env bash
    set -e

    if [[ "{{location}}" == "local" ]] || [[ "{{location}}" == "project" ]] || [[ "{{location}}" == "repo" ]]; then
        dest=".claude"
        echo "Installing {{skill_name}} skill in-repo..."
    else
        dest="{{location}}/.claude"
        echo "Installing {{skill_name}} skill to {{location}}/.claude..."
    fi

    skill_dir="$dest/skills/{{skill_name}}"
    refs_dir="$skill_dir/references"

    mkdir -p "$refs_dir"

    # Copy skill definition
    cp SKILL.md "$skill_dir/"

    # Copy documentation files from docs/ to references/
    cp docs/mini-tutorial-new-compiler.md "$refs_dir/"
    cp docs/GOTCHAS.md "$refs_dir/"
    cp docs/MINI_TUTORIAL_AUGMENTS.md "$refs_dir/"
    cp docs/Builtin.roc "$refs_dir/"
    cp docs/all_syntax_test.roc "$refs_dir/"
    cp docs/ROC_LANGREF_TUTORIAL.md "$refs_dir/"

    echo "  ✓ Installed to $skill_dir/"

# Install ~/.local/bin/rocgist wrapper
install-rocgist:
    #!/usr/bin/env bash
    set -e

    # Ensure roc is available
    if ! command -v roc &> /dev/null; then
        echo "Error: roc not found in PATH"
        echo "  Try: just install-roc"
        exit 1
    fi

    # Ensure gh is available
    if ! command -v gh &> /dev/null; then
        echo "Error: gh (GitHub CLI) not found in PATH"
        exit 1
    fi

    mkdir -p {{install_root}}/bin
    cp tools/rocgist {{install_root}}/bin/
    chmod +x {{install_root}}/bin/rocgist
    echo "[OK] Installed {{install_root}}/bin/rocgist"
    echo ""
    echo "Ensure {{install_root}}/bin is in your PATH:"
    echo "  export PATH=\"{{install_root}}/bin:\$PATH\""

# Prune Roc nightly cache to 3 most recent entries
prune-roc:
    #!/usr/bin/env bash
    set -e
    cache_dir="cache/roc-nightly"
    if [ ! -d "$cache_dir" ]; then
        exit 0
    fi
    stale_dirs=$(ls -dt "$cache_dir"/nightly-* 2>/dev/null | tail -n +4)
    if [ -z "$stale_dirs" ]; then
        exit 0
    fi
    echo "$stale_dirs" | while read -r dir; do
        rm -rf "$dir"
    done

# fail unless curl is available
tools-fetch:
    #!/usr/bin/env bash
    if ! command -v curl &> /dev/null; then
        echo "Missing: curl"
        exit 1
    fi

# fail unless rustc and cargo are available
tools-rust:
    #!/usr/bin/env bash
    if ! command -v rustc &> /dev/null; then
        echo "Missing: rustc"
        exit 1
    fi
    if ! command -v cargo &> /dev/null; then
        echo "Missing: cargo"
        exit 1
    fi


#
# Workflow Tasks
# ==============


# Build basic-cli platform from source
basic-cli: tools-rust
    #!/usr/bin/env bash
    set -e

    basic_cli_dir="../basic-cli"

    # Check if basic-cli directory exists
    if [ ! -d "$basic_cli_dir" ]; then
        # Try gh CLI first, fall back to SSH
        if command -v gh; then
            gh repo clone roc-lang/basic-cli "$basic_cli_dir"
        else
            git clone git@github.com:roc-lang/basic-cli "$basic_cli_dir"
        fi
    fi

    cd "$basic_cli_dir"

    # Check if we're on the migrate-zig-compiler branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    if [ "$current_branch" != "migrate-zig-compiler" ]; then
        echo "Checking out migrate-zig-compiler branch..."
        git checkout migrate-zig-compiler
        git pull
    fi

    # Check if build.sh exists
    if [ ! -f "./build.sh" ]; then
        echo "Error: build.sh not found in $basic_cli_dir"
        exit 1
    fi

    echo "Building basic-cli platform..."
    ./build.sh

# Check if we have the latest Roc nightly
check-nightly: tools-install
    #!/usr/bin/env bash
    set -e

    # Get latest release info from GitHub API
    release_info=$({{curl_cmd}} https://api.github.com/repos/roc-lang/nightlies/releases/latest)
    tag_name=$(echo "$release_info" | jq -r '.tag_name')

    if [ -z "$tag_name" ] || [ "$tag_name" = "null" ]; then
        echo "Error: Could not fetch latest release info"
        exit 1
    fi

    echo "Latest nightly: $tag_name"

    # Check if roc is installed
    if ! command -v roc &> /dev/null; then
        echo "[X] Roc not installed"
        exit 1
    fi

    current_version=$(roc version 2>&1 | head -1)
    # Extract commit hash from tag (format: nightly-2026-January-15-41b76c3)
    latest_commit=$(echo "$tag_name" | sed 's/.*-//')

    if echo "$current_version" | grep -q "$latest_commit"; then
        echo "[OK] Roc $tag_name already installed"
        echo "  Current: $current_version"
        exit 0
    else
        echo "[X] Update available"
        echo "  Current: $current_version"
        echo "  Latest:  $tag_name"
        exit 1
    fi


# Fetch latest Roc nightly into cache/
fetch-roc: tools-install
    #!/usr/bin/env bash
    set -e
    cache_dir="cache/roc-nightly"
    mkdir -p "$cache_dir"

    # Get latest release info from GitHub API
    release_info=$({{curl_cmd}} https://api.github.com/repos/roc-lang/nightlies/releases/latest)
    tag_name=$(echo "$release_info" | jq -r '.tag_name')

    if [ -z "$tag_name" ] || [ "$tag_name" = "null" ]; then
        echo "Error: Could not fetch latest release info"
        exit 1
    fi

    # Detect platform/arch for filename (best-effort, fail fast if unknown)
    os_name=$(uname -s)
    arch_name=$(uname -m)
    case "$os_name" in
        Linux) platform="linux" ;;
        Darwin) platform="macos" ;;
        *) echo "Error: Unsupported OS '$os_name' for Roc nightly install"; exit 1 ;;
    esac
    case "$arch_name" in
        x86_64|amd64) arch="x86_64" ;;
        arm64|aarch64) arch="arm64" ;;
        *) echo "Error: Unsupported arch '$arch_name' for Roc nightly install"; exit 1 ;;
    esac

    # Roc uses 'apple_silicon' instead of 'arm64' for macOS ARM builds
    if [ "$platform" = "macos" ] && [ "$arch" = "arm64" ]; then
        arch="apple_silicon"
    fi

    # Extract date from tag (format: nightly-2026-January-15-41b76c3)
    date_part=$(echo "$tag_name" | sed 's/nightly-//' | cut -d'-' -f1-3)
    commit=$(echo "$tag_name" | sed 's/.*-//')

    # Construct filename (format: roc_nightly-linux_x86_64-2026-01-15-41b76c3.tar.gz)
    # Need to convert January -> 01, parse the date
    month=$(echo "$date_part" | cut -d'-' -f2)
    case "$month" in
        January) month_num="01" ;;
        February) month_num="02" ;;
        March) month_num="03" ;;
        April) month_num="04" ;;
        May) month_num="05" ;;
        June) month_num="06" ;;
        July) month_num="07" ;;
        August) month_num="08" ;;
        September) month_num="09" ;;
        October) month_num="10" ;;
        November) month_num="11" ;;
        December) month_num="12" ;;
        *) echo "Error: Unrecognized month '$month' in tag '$tag_name'"; exit 1 ;;
    esac

    year=$(echo "$date_part" | cut -d'-' -f1)
    day=$(echo "$date_part" | cut -d'-' -f3)
    numeric_date="$year-$month_num-$day"

    filename="roc_nightly-${platform}_${arch}-$numeric_date-$commit.tar.gz"
    download_url="https://github.com/roc-lang/nightlies/releases/download/$tag_name/$filename"
    tag_dir="$cache_dir/$tag_name"
    tarball="$tag_dir/$filename"

    if [ -f "$tarball" ]; then
        # Validate cached tarball is actually a gzip file (try gzip -t first, more portable)
        if ! gzip -t "$tarball" 2>/dev/null; then
            echo "Warning: Cached tarball is corrupted, re-downloading..."
            rm -f "$tarball"
        else
            echo "[OK] Cached: $tarball"
        fi
    fi

    if [ ! -f "$tarball" ]; then
        echo "Downloading $filename..."
        mkdir -p "$tag_dir"
        {{curl_cmd}} "$download_url" -o "$tarball"

        # Validate download succeeded
        if ! gzip -t "$tarball" 2>/dev/null; then
            echo "Error: Download failed - file is not a valid gzip archive"
            echo "  URL: $download_url"
            echo "  This may indicate the file doesn't exist for your platform"
            rm -f "$tarball"
            exit 1
        fi
    fi

    echo "$tag_name" > "$cache_dir/LATEST"
    echo "[OK] Cached nightly: $tag_name"

# Fetch and install latest Roc nightly (skips if already up-to-date)
install-roc: tools-install fetch-roc
    #!/usr/bin/env bash
    set -e

    # Check if we already have the latest version (exit early if so)
    check_output=$(just check-nightly 2>&1 || true)
    if echo "$check_output" | grep -q "[OK] Roc"; then
        echo "$check_output" | grep "[OK] Roc"
        exit 0
    fi

    cache_dir="cache/roc-nightly"
    tag_name="${1:-}"
    if [ -z "$tag_name" ]; then
        if [ ! -f "$cache_dir/LATEST" ]; then
            just fetch-roc
        fi
        tag_name=$(cat "$cache_dir/LATEST")
    fi

    tag_dir="$cache_dir/$tag_name"
    tarball=$(ls "$tag_dir"/*.tar.gz 2>/dev/null | head -1)
    if [ -z "$tarball" ]; then
        echo "Error: No cached nightly for tag '$tag_name'"
        echo "  Run: just fetch-roc"
        exit 1
    fi

    echo "Installing $tag_name..."
    tmpdir=$(mktemp -d -t roc-install 2>/dev/null || mktemp -d /tmp/roc-install.XXXXXX)
    trap 'rm -rf "$tmpdir"' EXIT

    echo "Extracting to {{install_root}}/bin..."
    mkdir -p {{install_root}}/bin
    tar -xzf "$tarball" -C "$tmpdir"

    # Find the extracted directory (should be roc_nightly-linux_x86_64-DATE-HASH)
    extracted_dir=$(find "$tmpdir" -maxdepth 1 -type d -name "roc_nightly-*" | head -1)

    if [ -z "$extracted_dir" ]; then
        echo "Error: Could not find extracted directory"
        exit 1
    fi

    # Copy binaries
    cp "$extracted_dir/roc" {{install_root}}/bin/

    # Copy darwin sysroot if present (required for macOS linking)
    if [ -d "$extracted_dir/darwin" ]; then
        rm -rf {{install_root}}/bin/darwin
        cp -r "$extracted_dir/darwin" {{install_root}}/bin/
    fi

    # Cleanup
    echo "[OK] Roc nightly installed to {{install_root}}/bin/roc"
    echo ""
    echo "Ensure {{install_root}}/bin is in your PATH:"
    echo "  export PATH=\"{{install_root}}/bin:\$PATH\""
    echo ""
    {{install_root}}/bin/roc version
    just prune-roc

# fail unless jq is available
tools-install: tools-fetch
    #!/usr/bin/env bash
    if ! command -v jq &> /dev/null; then
        echo "Missing: jq"
        exit 1
    fi

# Fetch docs and install to user skill
update-docs: fetch-docs install-skill
