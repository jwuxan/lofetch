#!/usr/bin/env bash
# Test suite for npm package structure and Homebrew formula
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── Test Helpers ─────────────────────────────────────────
PASSED=0
FAILED=0
TESTS=0

assert_file_exists() {
    TESTS=$((TESTS + 1))
    local file="$1"
    local desc="${2:-File $file should exist}"
    if [[ -f "$file" ]]; then
        printf "✓ %s\n" "$desc"
        PASSED=$((PASSED + 1))
    else
        printf "✗ %s (file not found)\n" "$desc"
        FAILED=$((FAILED + 1))
    fi
}

assert_json_valid() {
    TESTS=$((TESTS + 1))
    local file="$1"
    local desc="${2:-$file should be valid JSON}"
    if command -v node &>/dev/null; then
        if node -e "JSON.parse(require('fs').readFileSync('$file', 'utf8'))" 2>/dev/null; then
            printf "✓ %s\n" "$desc"
            PASSED=$((PASSED + 1))
        else
            printf "✗ %s\n" "$desc"
            FAILED=$((FAILED + 1))
        fi
    elif command -v python3 &>/dev/null; then
        if python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
            printf "✓ %s\n" "$desc"
            PASSED=$((PASSED + 1))
        else
            printf "✗ %s\n" "$desc"
            FAILED=$((FAILED + 1))
        fi
    else
        printf "⊘ %s (no JSON validator available)\n" "$desc"
        TESTS=$((TESTS - 1))
    fi
}

assert_json_field() {
    TESTS=$((TESTS + 1))
    local file="$1"
    local field="$2"
    local expected="$3"
    local desc="${4:-$file.$field should equal '$expected'}"

    local actual=""
    if command -v node &>/dev/null; then
        actual=$(node -e "console.log(require('./$file').$field)" 2>/dev/null || echo "")
    elif command -v python3 &>/dev/null; then
        actual=$(python3 -c "import json; print(json.load(open('$file'))['$field'])" 2>/dev/null || echo "")
    else
        printf "⊘ %s (no JSON parser available)\n" "$desc"
        TESTS=$((TESTS - 1))
        return
    fi

    if [[ "$actual" == "$expected" ]]; then
        printf "✓ %s\n" "$desc"
        PASSED=$((PASSED + 1))
    else
        printf "✗ %s (got '%s')\n" "$desc" "$actual"
        FAILED=$((FAILED + 1))
    fi
}

assert_executable() {
    TESTS=$((TESTS + 1))
    local file="$1"
    local desc="${2:-$file should be executable}"
    if [[ -x "$file" ]]; then
        printf "✓ %s\n" "$desc"
        PASSED=$((PASSED + 1))
    else
        printf "✗ %s\n" "$desc"
        FAILED=$((FAILED + 1))
    fi
}

assert_command_success() {
    TESTS=$((TESTS + 1))
    local desc="$1"
    shift
    if "$@" &>/dev/null; then
        printf "✓ %s\n" "$desc"
        PASSED=$((PASSED + 1))
    else
        printf "✗ %s\n" "$desc"
        FAILED=$((FAILED + 1))
    fi
}

assert_output_contains() {
    TESTS=$((TESTS + 1))
    local desc="$1"
    local expected="$2"
    shift 2
    local output
    output=$("$@" 2>&1 || true)
    if [[ "$output" == *"$expected"* ]]; then
        printf "✓ %s\n" "$desc"
        PASSED=$((PASSED + 1))
    else
        printf "✗ %s (output: %s)\n" "$desc" "$output"
        FAILED=$((FAILED + 1))
    fi
}

# ── Test Suite ───────────────────────────────────────────

printf "Testing npm package structure...\n\n"

# Test package.json existence and validity
assert_file_exists "package.json" "package.json exists"
assert_json_valid "package.json" "package.json is valid JSON"

# Test package.json fields
assert_json_field "package.json" "name" "lofetch" "package.json name field"
assert_json_field "package.json" "version" "2.0.0" "package.json version field"
assert_json_field "package.json" "license" "MIT" "package.json license field"

# Test bin file exists and is referenced correctly
assert_file_exists "lofetch" "lofetch script exists"
assert_executable "lofetch" "lofetch is executable"

# Test lofetch --version works
assert_output_contains "lofetch --version returns version" "2.0.0" ./lofetch --version

# Test lofetch --help works
assert_command_success "lofetch --help exits successfully" ./lofetch --help

# Test lofetch basic execution (should succeed even without full system info)
assert_command_success "lofetch runs successfully" ./lofetch

printf "\n"

# Test Homebrew formula
printf "Testing Homebrew formula...\n\n"
assert_file_exists "Formula/lofetch.rb" "Formula/lofetch.rb exists"

# Verify formula syntax (using Ruby)
if command -v ruby &>/dev/null; then
    assert_command_success "Formula syntax is valid Ruby" ruby -c Formula/lofetch.rb
else
    printf "⊘ Ruby not installed, skipping formula syntax validation\n"
fi

printf "\n"

# Test required files for distribution
printf "Testing distribution files...\n\n"
assert_file_exists "README.md" "README.md exists"
assert_file_exists "LICENSE" "LICENSE exists"
assert_file_exists "INSTALL.md" "INSTALL.md exists"
assert_file_exists "CHANGELOG.md" "CHANGELOG.md exists"

# ── Summary ──────────────────────────────────────────────
printf "\n"
printf "════════════════════════════════════════\n"
printf "Package Tests: %d passed, %d failed, %d total\n" "$PASSED" "$FAILED" "$TESTS"
printf "════════════════════════════════════════\n"

exit "$FAILED"
