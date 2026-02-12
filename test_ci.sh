#!/usr/bin/env bash
# test_ci.sh — validate GitHub Actions workflow structure
# TDD: this test is written BEFORE the workflows, so it should fail initially.
set -uo pipefail

PASS=0
FAIL=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKFLOWS="$SCRIPT_DIR/.github/workflows"

# ── Helpers ──────────────────────────────────────────────

assert_file_exists() {
    local label="$1" path="$2"
    if [[ -f "$path" ]]; then
        ((PASS++)); printf "  ✓ %s\n" "$label"
    else
        ((FAIL++)); printf "  ✗ %s (not found: %s)\n" "$label" "$path"
    fi
}

assert_file_contains() {
    local label="$1" path="$2" pattern="$3"
    if [[ -f "$path" ]] && grep -qE "$pattern" "$path"; then
        ((PASS++)); printf "  ✓ %s\n" "$label"
    else
        ((FAIL++)); printf "  ✗ %s (pattern not found: %s)\n" "$label" "$pattern"
    fi
}

assert_file_not_contains() {
    local label="$1" path="$2" pattern="$3"
    if [[ -f "$path" ]] && ! grep -qE "$pattern" "$path"; then
        ((PASS++)); printf "  ✓ %s\n" "$label"
    else
        ((FAIL++)); printf "  ✗ %s (pattern should NOT be present: %s)\n" "$label" "$pattern"
    fi
}

assert_yaml_valid() {
    local label="$1" path="$2"
    if [[ ! -f "$path" ]]; then
        ((FAIL++)); printf "  ✗ %s (file missing)\n" "$label"
        return
    fi
    # Basic YAML validity: no tabs for indentation, has 'name:' key
    if grep -qP '^\t' "$path" 2>/dev/null; then
        ((FAIL++)); printf "  ✗ %s (contains tab indentation)\n" "$label"
    elif grep -qE '^name:' "$path"; then
        ((PASS++)); printf "  ✓ %s\n" "$label"
    else
        ((FAIL++)); printf "  ✗ %s (missing 'name:' key)\n" "$label"
    fi
}

# ── Test: Workflow Files Exist ───────────────────────────

echo "=== Workflow Files Exist ==="

assert_file_exists "ci.yml exists" "$WORKFLOWS/ci.yml"
assert_file_exists "release.yml exists" "$WORKFLOWS/release.yml"
assert_file_exists "pr-title.yml exists" "$WORKFLOWS/pr-title.yml"
assert_file_exists "stale.yml exists" "$WORKFLOWS/stale.yml"
assert_file_exists "dependabot.yml exists" "$SCRIPT_DIR/.github/dependabot.yml"

# ── Test: ci.yml Structure ───────────────────────────────

echo ""
echo "=== ci.yml Structure ==="

CI="$WORKFLOWS/ci.yml"
assert_yaml_valid "ci.yml is valid YAML" "$CI"
assert_file_contains "ci.yml triggers on push" "$CI" "push:"
assert_file_contains "ci.yml triggers on pull_request" "$CI" "pull_request:"
assert_file_contains "ci.yml has schedule trigger" "$CI" "schedule:"
assert_file_contains "ci.yml has cron expression" "$CI" "cron:"
assert_file_contains "ci.yml has lint job" "$CI" "lint:"
assert_file_contains "ci.yml has test job" "$CI" "test:"
assert_file_contains "ci.yml has bash-compat job" "$CI" "bash-compat:"
assert_file_contains "ci.yml has version-check job" "$CI" "version-check:"
assert_file_contains "ci.yml has security job" "$CI" "security:"
assert_file_contains "ci.yml uses ubuntu-latest" "$CI" "ubuntu-latest"
assert_file_contains "ci.yml uses macos-latest" "$CI" "macos-latest"
assert_file_contains "ci.yml runs test_lofetch.sh" "$CI" "test_lofetch.sh"
assert_file_contains "ci.yml runs test_package.sh" "$CI" "test_package.sh"
assert_file_contains "ci.yml runs shellcheck" "$CI" "[Ss]hell[Cc]heck|shellcheck"
assert_file_contains "ci.yml uploads artifacts" "$CI" "upload-artifact"
assert_file_contains "ci.yml uses checkout@v4" "$CI" "actions/checkout@v4"
assert_file_contains "ci.yml has bash 4 test" "$CI" "bash:4|4\\.4"
assert_file_contains "ci.yml has bash 5 test" "$CI" "bash:5|5\\.[02]"
assert_file_contains "ci.yml uses gitleaks" "$CI" "gitleaks"
assert_file_contains "ci.yml uploads SARIF" "$CI" "sarif|SARIF"

# ── Test: release.yml Structure ──────────────────────────

echo ""
echo "=== release.yml Structure ==="

REL="$WORKFLOWS/release.yml"
assert_yaml_valid "release.yml is valid YAML" "$REL"
assert_file_contains "release.yml triggers on tag push" "$REL" "tags:"
assert_file_contains "release.yml has v* pattern" "$REL" "v\\*|'v\\*'"
assert_file_contains "release.yml has test job" "$REL" "test:"
assert_file_contains "release.yml has npm publish" "$REL" "npm publish"
assert_file_contains "release.yml has provenance" "$REL" "provenance"
assert_file_contains "release.yml has github release" "$REL" "create-release|softprops|release"
assert_file_contains "release.yml has id-token permission" "$REL" "id-token:"
assert_file_contains "release.yml uses setup-node" "$REL" "setup-node"

# ── Test: pr-title.yml Structure ─────────────────────────

echo ""
echo "=== pr-title.yml Structure ==="

PR="$WORKFLOWS/pr-title.yml"
assert_yaml_valid "pr-title.yml is valid YAML" "$PR"
assert_file_contains "pr-title.yml triggers on PR" "$PR" "pull_request"
assert_file_contains "pr-title.yml checks conventional commits" "$PR" "feat|fix|docs|chore|refactor|test|ci|style|perf|build"

# ── Test: stale.yml Structure ────────────────────────────

echo ""
echo "=== stale.yml Structure ==="

STALE="$WORKFLOWS/stale.yml"
assert_yaml_valid "stale.yml is valid YAML" "$STALE"
assert_file_contains "stale.yml has schedule trigger" "$STALE" "schedule:"
assert_file_contains "stale.yml uses stale action" "$STALE" "stale"
assert_file_contains "stale.yml has 30 day config" "$STALE" "30"

# ── Test: dependabot.yml Structure ───────────────────────

echo ""
echo "=== dependabot.yml Structure ==="

DEPBOT="$SCRIPT_DIR/.github/dependabot.yml"
assert_file_contains "dependabot.yml has version" "$DEPBOT" "version: 2"
assert_file_contains "dependabot.yml has github-actions ecosystem" "$DEPBOT" "github-actions"
assert_file_contains "dependabot.yml has weekly interval" "$DEPBOT" "weekly"

# ── Test: Version Consistency (runtime check) ────────────

echo ""
echo "=== Version Consistency ==="

LOFETCH_SCRIPT="$SCRIPT_DIR/lofetch"
PKG_JSON="$SCRIPT_DIR/package.json"
FORMULA="$SCRIPT_DIR/Formula/lofetch.rb"

# Extract versions from each source
script_ver=""
if [[ -f "$LOFETCH_SCRIPT" ]]; then
    script_ver=$(grep -oP 'LOFETCH_VERSION="\K[^"]+' "$LOFETCH_SCRIPT" 2>/dev/null || \
                 grep -oE 'LOFETCH_VERSION="[^"]+"' "$LOFETCH_SCRIPT" | sed 's/LOFETCH_VERSION="//;s/"//')
fi

pkg_ver=""
if [[ -f "$PKG_JSON" ]] && command -v python3 &>/dev/null; then
    pkg_ver=$(python3 -c "import json; print(json.load(open('$PKG_JSON'))['version'])" 2>/dev/null)
fi

formula_ver=""
if [[ -f "$FORMULA" ]]; then
    formula_ver=$(grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' "$FORMULA" | head -1 | sed 's/^v//')
fi

if [[ -n "$script_ver" && -n "$pkg_ver" && "$script_ver" == "$pkg_ver" ]]; then
    ((PASS++)); printf "  ✓ lofetch (%s) matches package.json (%s)\n" "$script_ver" "$pkg_ver"
else
    ((FAIL++)); printf "  ✗ version mismatch: lofetch=%s package.json=%s\n" "$script_ver" "$pkg_ver"
fi

if [[ -n "$script_ver" && -n "$formula_ver" && "$script_ver" == "$formula_ver" ]]; then
    ((PASS++)); printf "  ✓ lofetch (%s) matches Formula (%s)\n" "$script_ver" "$formula_ver"
else
    ((FAIL++)); printf "  ✗ version mismatch: lofetch=%s Formula=%s\n" "$script_ver" "$formula_ver"
fi

# ── Summary ──────────────────────────────────────────────

echo ""
echo "════════════════════════════════════"
printf "CI Validation: %d passed, %d failed\n" "$PASS" "$FAIL"
echo "════════════════════════════════════"

exit "$FAIL"
