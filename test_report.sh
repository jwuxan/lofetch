#!/usr/bin/env bash
# test_report.sh — TDD test suite for report.sh
set -uo pipefail

PASS=0
FAIL=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Helpers ──────────────────────────────────────────────

assert_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        ((PASS++))
        printf "  ✓ %s\n" "$label"
    else
        ((FAIL++))
        printf "  ✗ %s\n    expected: [%s]\n    actual:   [%s]\n" "$label" "$expected" "$actual"
    fi
}

assert_match() {
    local label="$1" pattern="$2" actual="$3"
    if [[ "$actual" =~ $pattern ]]; then
        ((PASS++))
        printf "  ✓ %s\n" "$label"
    else
        ((FAIL++))
        printf "  ✗ %s\n    pattern:  [%s]\n    actual:   [%s]\n" "$label" "$pattern" "$actual"
    fi
}

assert_not_empty() {
    local label="$1" actual="$2"
    if [[ -n "$actual" ]]; then
        ((PASS++))
        printf "  ✓ %s\n" "$label"
    else
        ((FAIL++))
        printf "  ✗ %s (was empty)\n" "$label"
    fi
}

assert_numeric() {
    local label="$1" actual="$2"
    if [[ "$actual" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        ((PASS++))
        printf "  ✓ %s\n" "$label"
    else
        ((FAIL++))
        printf "  ✗ %s (not numeric: [%s])\n" "$label" "$actual"
    fi
}

# ── Source the script without running main ───────────────

# We set LOFETCH_SOURCED=1 so report.sh exports functions but doesn't run main
export LOFETCH_SOURCED=1
source "$SCRIPT_DIR/report.sh"

# ── Test: Constants ──────────────────────────────────────

echo "=== Constants ==="

assert_eq "BOX_INNER_WIDTH is 40" "40" "$BOX_INNER_WIDTH"
assert_eq "LABEL_WIDTH is 11" "11" "$LABEL_WIDTH"
assert_eq "BAR_WIDTH is 15" "15" "$BAR_WIDTH"
assert_eq "FILL_CHAR is █" "█" "$FILL_CHAR"
assert_eq "EMPTY_CHAR is ░" "░" "$EMPTY_CHAR"

# ── Test: draw_bar ───────────────────────────────────────

echo ""
echo "=== draw_bar ==="

# draw_bar <percentage> <width> → should produce filled + empty blocks
bar_50=$(draw_bar 50 20)
# 50% of 20 = 10 filled, 10 empty
assert_eq "draw_bar 50 20 has 20 chars total" "20" "${#bar_50}"
assert_eq "draw_bar 50 20 value" "██████████░░░░░░░░░░" "$bar_50"

bar_0=$(draw_bar 0 20)
assert_eq "draw_bar 0 20 all empty" "░░░░░░░░░░░░░░░░░░░░" "$bar_0"

bar_100=$(draw_bar 100 20)
assert_eq "draw_bar 100 20 all filled" "████████████████████" "$bar_100"

bar_33=$(draw_bar 33 20)
# 33% of 20 ≈ 6.6 → round to 7
expected_33="███████░░░░░░░░░░░░░"
assert_eq "draw_bar 33 20 rounds correctly" "$expected_33" "$bar_33"

# Over 100 should clamp
bar_over=$(draw_bar 150 20)
assert_eq "draw_bar 150 clamps to 100%" "████████████████████" "$bar_over"

# ── Test: print_row ──────────────────────────────────────

echo ""
echo "=== print_row ==="

# print_row <label> <value> → should produce "│ LABEL         value ... │"
row=$(print_row "OS" "Debian 12.5")
# Should start with "│ " and end with " │"
assert_match "print_row starts with │" "^│ " "$row"
assert_match "print_row ends with │$" " │$" "$row"
assert_match "print_row contains label" "OS" "$row"
assert_match "print_row contains value" "Debian 12.5" "$row"

# Measure total visible width (accounting for Unicode box chars = 1 col each)
# Total should be BOX_INNER_WIDTH + 2 (for the two │ border chars)
row_len=${#row}
# Note: this is byte length, but for our ASCII content + 2 Unicode border chars it works
# We'll check it contains the right structure

# ── Test: print_centered ─────────────────────────────────

echo ""
echo "=== print_centered ==="

centered=$(print_centered "HELLO")
assert_match "print_centered starts with │" "^│" "$centered"
assert_match "print_centered ends with │$" "│$" "$centered"
assert_match "print_centered contains text" "HELLO" "$centered"

# ── Test: borders ────────────────────────────────────────

echo ""
echo "=== Borders ==="

top=$(print_top_border)
assert_match "top border starts with ┌" "^┌" "$top"
assert_match "top border ends with ┐$" "┐$" "$top"
assert_match "top border has ─" "─" "$top"

bottom=$(print_bottom_border)
assert_match "bottom border starts with └" "^└" "$bottom"
assert_match "bottom border ends with ┘$" "┘$" "$bottom"

sep=$(print_separator)
assert_match "separator starts with ├" "^├" "$sep"
assert_match "separator ends with ┤$" "┤$" "$sep"

# ── Test: detect_platform ────────────────────────────────

echo ""
echo "=== Platform Detection ==="

platform=$(detect_platform)
assert_match "platform is valid" "^(linux|macos|windows_wsl|windows_mingw)$" "$platform"

# ── Test: Data collection populates variables ────────────

echo ""
echo "=== Data Collection ==="

# OS info
get_os_info
assert_not_empty "OS_NAME is set" "${OS_NAME:-}"
assert_not_empty "KERNEL_VERSION is set" "${KERNEL_VERSION:-}"

# Network info
get_network_info
assert_not_empty "NET_HOSTNAME is set" "${NET_HOSTNAME:-}"
assert_not_empty "NET_USER is set" "${NET_USER:-}"

# CPU info
get_cpu_info
assert_not_empty "CPU_MODEL is set" "${CPU_MODEL:-}"
assert_not_empty "CPU_CORES is set" "${CPU_CORES:-}"

# Load info
get_load_info
assert_not_empty "LOAD_1 is set" "${LOAD_1:-}"
assert_not_empty "LOAD_5 is set" "${LOAD_5:-}"
assert_not_empty "LOAD_15 is set" "${LOAD_15:-}"

# Memory info
get_memory_info
assert_not_empty "MEM_USED_H is set" "${MEM_USED_H:-}"
assert_not_empty "MEM_TOTAL_H is set" "${MEM_TOTAL_H:-}"
assert_not_empty "MEM_PERCENT is set" "${MEM_PERCENT:-}"

# Disk info
get_disk_info
assert_not_empty "DISK_USED_H is set" "${DISK_USED_H:-}"
assert_not_empty "DISK_TOTAL_H is set" "${DISK_TOTAL_H:-}"
assert_not_empty "DISK_PERCENT is set" "${DISK_PERCENT:-}"

# Session info
get_session_info
assert_not_empty "LAST_LOGIN is set" "${LAST_LOGIN:-}"
assert_not_empty "UPTIME_STR is set" "${UPTIME_STR:-}"

# ── Test: Full output structure ──────────────────────────

echo ""
echo "=== Full Output Structure ==="

# Run the full render (unset LOFETCH_SOURCED temporarily)
full_output=$(LOFETCH_SOURCED="" render_report 2>/dev/null || true)

if [[ -n "$full_output" ]]; then
    # First line should be top border
    first_line=$(echo "$full_output" | head -1)
    assert_match "output starts with ┌" "^┌" "$first_line"

    # Last line should be bottom border
    last_line=$(echo "$full_output" | tail -1)
    assert_match "output ends with ┘" "┘$" "$last_line"

    # Should contain merged compact header
    assert_match "output contains LOFETCH REPORT" "LOFETCH REPORT" "$full_output"

    # Count separators (├...┤) — should have at least 5 section dividers
    sep_count=$(echo "$full_output" | grep -c "^├" || true)
    if [[ "$sep_count" -ge 5 ]]; then
        ((PASS++)); printf "  ✓ has ≥5 section separators (%d found)\n" "$sep_count"
    else
        ((FAIL++)); printf "  ✗ expected ≥5 separators, got %d\n" "$sep_count"
    fi

    # Every content line should start with │ and end with │
    bad_lines=0
    while IFS= read -r line; do
        if [[ "$line" != "┌"* && "$line" != "└"* && "$line" != "├"* ]]; then
            if [[ "$line" != "│"* || "$line" != *"│" ]]; then
                ((bad_lines++))
            fi
        fi
    done <<< "$full_output"
    if [[ "$bad_lines" -eq 0 ]]; then
        ((PASS++)); printf "  ✓ all content lines properly bordered\n"
    else
        ((FAIL++)); printf "  ✗ %d lines with broken borders\n" "$bad_lines"
    fi
else
    ((FAIL++)); printf "  ✗ render_report produced no output\n"
fi

# ── Test: Compact layout properties ──────────────────

echo ""
echo "=== Compact Layout ==="

if [[ -n "$full_output" ]]; then
    # No empty padding rows at all (compact mode removes them)
    empty_row_count=0
    while IFS= read -r line; do
        # An "empty row" is │ followed by only spaces and │
        if [[ "$line" =~ ^│[[:space:]]+│$ ]]; then
            ((empty_row_count++))
        fi
    done <<< "$full_output"
    if [[ "$empty_row_count" -eq 0 ]]; then
        ((PASS++)); printf "  ✓ no empty padding rows (compact)\n"
    else
        ((FAIL++)); printf "  ✗ found %d empty padding rows, expected 0\n" "$empty_row_count"
    fi

    # Header is single line "LOFETCH REPORT" (not split across two lines)
    header_count=$(echo "$full_output" | grep -c "LOFETCH" || true)
    if [[ "$header_count" -eq 1 ]]; then
        ((PASS++)); printf "  ✓ header is single merged line\n"
    else
        ((FAIL++)); printf "  ✗ expected 1 header line with LOFETCH, got %d\n" "$header_count"
    fi

    # Verify line width: all lines should be BOX_INNER_WIDTH + 2 = 42 display columns
    # (Check byte length of ASCII-only lines as a proxy — border/separator lines)
    top_line=$(echo "$full_output" | head -1)
    # The top border is ┌ + 40×─ + ┐, each char is 3 bytes for box drawing
    # Just verify it contains exactly BOX_INNER_WIDTH ─ chars
    dash_count=$(echo "$top_line" | grep -oE '─' | wc -l | tr -d ' ')
    assert_eq "top border width matches BOX_INNER_WIDTH" "40" "$dash_count"
fi

# ── Summary ──────────────────────────────────────────────

echo ""
echo "════════════════════════════════════"
printf "Results: %d passed, %d failed\n" "$PASS" "$FAIL"
echo "════════════════════════════════════"

exit "$FAIL"
