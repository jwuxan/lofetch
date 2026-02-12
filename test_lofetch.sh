#!/usr/bin/env bash
# test_lofetch.sh — comprehensive test suite for lofetch
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

assert_no_match() {
    local label="$1" pattern="$2" actual="$3"
    if [[ ! "$actual" =~ $pattern ]]; then
        ((PASS++))
        printf "  ✓ %s\n" "$label"
    else
        ((FAIL++))
        printf "  ✗ %s\n    should NOT match: [%s]\n    actual:            [%s]\n" "$label" "$pattern" "$actual"
    fi
}

assert_exit_code() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        ((PASS++))
        printf "  ✓ %s\n" "$label"
    else
        ((FAIL++))
        printf "  ✗ %s (expected exit %s, got %s)\n" "$label" "$expected" "$actual"
    fi
}

# ── Source the script without running main ───────────────

export LOFETCH_SOURCED=1
source "$SCRIPT_DIR/lofetch"
set +e  # Disable errexit (lofetch's set -euo pipefail propagates when sourced)

# ── Test: Constants ──────────────────────────────────────

echo "=== Constants ==="

assert_eq "BOX_INNER_WIDTH is 52" "52" "$BOX_INNER_WIDTH"
assert_eq "LABEL_WIDTH is 13" "13" "$LABEL_WIDTH"
assert_eq "BAR_WIDTH is 38" "38" "$BAR_WIDTH"
assert_eq "FILL_CHAR is █" "█" "$FILL_CHAR"
assert_eq "EMPTY_CHAR is ░" "░" "$EMPTY_CHAR"
assert_eq "LOFETCH_VERSION is 2.0.0" "2.0.0" "$LOFETCH_VERSION"
assert_eq "DEFAULT_MODULES" "os,cpu,mem,disk,net,session" "$DEFAULT_MODULES"

# ── Test: draw_bar (plain for width tests) ───────────────

echo ""
echo "=== draw_bar_plain ==="

bar_50=$(draw_bar_plain 50 22)
assert_eq "draw_bar_plain 50 22 has 22 chars" "22" "${#bar_50}"

bar_0=$(draw_bar_plain 0 22)
assert_eq "draw_bar_plain 0 22 all empty" "░░░░░░░░░░░░░░░░░░░░░░" "$bar_0"

bar_100=$(draw_bar_plain 100 22)
assert_eq "draw_bar_plain 100 22 all filled" "██████████████████████" "$bar_100"

bar_33=$(draw_bar_plain 33 22)
assert_eq "draw_bar_plain 33 22 has 22 chars" "22" "${#bar_33}"

bar_over=$(draw_bar_plain 150 22)
assert_eq "draw_bar_plain 150 clamps to 100%" "██████████████████████" "$bar_over"

bar_neg=$(draw_bar_plain -5 22)
assert_eq "draw_bar_plain -5 clamps to 0%" "░░░░░░░░░░░░░░░░░░░░░░" "$bar_neg"

# ── Test: draw_bar (colored) ────────────────────────────

echo ""
echo "=== draw_bar (colored) ==="

# Initialize colors for bar tests
detect_color_support
apply_theme "crt"

cbar_50=$(draw_bar 50 22)
assert_not_empty "draw_bar 50 22 produces output" "$cbar_50"

# Low bar should contain green color code
cbar_low=$(draw_bar 30 22)
assert_match "draw_bar 30% contains green color" "38;5;46" "$cbar_low"

# Medium bar should contain yellow color code
cbar_med=$(draw_bar 70 22)
assert_match "draw_bar 70% contains yellow color" "38;5;226" "$cbar_med"

# High bar should contain red color code
cbar_hi=$(draw_bar 90 22)
assert_match "draw_bar 90% contains red color" "38;5;196" "$cbar_hi"

# ── Test: print_row (colorized) ─────────────────────────

echo ""
echo "=== print_row ==="

row=$(print_row "OS" "Debian 12.5")
assert_match "print_row contains label" "OS" "$row"
assert_match "print_row contains value" "Debian 12.5" "$row"

# ── Test: print_centered ─────────────────────────────────

echo ""
echo "=== print_centered ==="

# Clear colors for structural tests
clear_all_colors
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

# Verify border width (52 dashes)
dash_count=$(echo "$top" | grep -oE '─' | wc -l | tr -d ' ')
assert_eq "top border width matches BOX_INNER_WIDTH" "52" "$dash_count"

# ── Test: detect_platform ────────────────────────────────

echo ""
echo "=== Platform Detection ==="

platform=$(detect_platform)
assert_match "platform is valid" "^(linux|macos|windows_wsl|windows_mingw)$" "$platform"

# ── Test: Data collection populates variables ────────────

echo ""
echo "=== Data Collection ==="

get_os_info
assert_not_empty "OS_NAME is set" "${OS_NAME:-}"
assert_not_empty "KERNEL_VERSION is set" "${KERNEL_VERSION:-}"

get_network_info
assert_not_empty "NET_HOSTNAME is set" "${NET_HOSTNAME:-}"
assert_not_empty "NET_USER is set" "${NET_USER:-}"

get_cpu_info
assert_not_empty "CPU_MODEL is set" "${CPU_MODEL:-}"
assert_not_empty "CPU_CORES is set" "${CPU_CORES:-}"

get_load_info
assert_not_empty "LOAD_1 is set" "${LOAD_1:-}"
assert_not_empty "LOAD_5 is set" "${LOAD_5:-}"
assert_not_empty "LOAD_15 is set" "${LOAD_15:-}"

get_memory_info
assert_not_empty "MEM_USED_H is set" "${MEM_USED_H:-}"
assert_not_empty "MEM_TOTAL_H is set" "${MEM_TOTAL_H:-}"
assert_not_empty "MEM_PERCENT is set" "${MEM_PERCENT:-}"

get_disk_info
assert_not_empty "DISK_USED_H is set" "${DISK_USED_H:-}"
assert_not_empty "DISK_TOTAL_H is set" "${DISK_TOTAL_H:-}"
assert_not_empty "DISK_PERCENT is set" "${DISK_PERCENT:-}"

get_session_info
assert_not_empty "LAST_LOGIN is set" "${LAST_LOGIN:-}"
assert_not_empty "UPTIME_STR is set" "${UPTIME_STR:-}"

# ── Test: Color Support Detection ────────────────────────

echo ""
echo "=== Color Detection ==="

# NO_COLOR should disable colors
NO_COLOR=1 detect_color_support
assert_eq "NO_COLOR disables color" "0" "$COLOR_LEVEL"
unset NO_COLOR

# TERM=dumb should disable colors
TERM=dumb detect_color_support
assert_eq "TERM=dumb disables color" "0" "$COLOR_LEVEL"

# Restore for remaining tests
TERM="${TERM:-xterm-256color}"

# ── Test: Theme System ───────────────────────────────────

echo ""
echo "=== Theme System ==="

COLOR_LEVEL=2
apply_theme "crt"
assert_eq "CRT theme name" "crt" "$LOFETCH_THEME_NAME"
assert_not_empty "CRT C_BORDER set" "$C_BORDER"
assert_not_empty "CRT C_LABEL set" "$C_LABEL"
assert_not_empty "CRT C_BAR_LOW set" "$C_BAR_LOW"

apply_theme "neon"
assert_eq "Neon theme name" "neon" "$LOFETCH_THEME_NAME"
assert_match "Neon border uses purple" "38;5;93" "$C_BORDER"

apply_theme "minimal"
assert_eq "Minimal theme name" "minimal" "$LOFETCH_THEME_NAME"
assert_match "Minimal border uses gray" "38;5;240" "$C_BORDER"

apply_theme "plain"
assert_eq "Plain theme name" "plain" "$LOFETCH_THEME_NAME"
assert_eq "Plain C_BORDER is empty" "" "$C_BORDER"
assert_eq "Plain C_RESET is empty" "" "$C_RESET"

# Color disabled overrides theme
COLOR_LEVEL=0
apply_theme "crt"
assert_eq "Color disabled clears C_BORDER" "" "$C_BORDER"
assert_eq "Color disabled clears C_LABEL" "" "$C_LABEL"

# Restore
COLOR_LEVEL=2

# ── Test: CLI Flags ──────────────────────────────────────

echo ""
echo "=== CLI Flags ==="

# --help exits 0
help_out=$(env -u LOFETCH_SOURCED bash "$SCRIPT_DIR/lofetch" --help 2>&1)
help_rc=$?
assert_exit_code "--help exits 0" "0" "$help_rc"
assert_match "--help shows Usage" "Usage:" "$help_out"

# --version exits 0
ver_out=$(env -u LOFETCH_SOURCED bash "$SCRIPT_DIR/lofetch" --version 2>&1)
ver_rc=$?
assert_exit_code "--version exits 0" "0" "$ver_rc"
assert_match "--version shows version" "lofetch 2.0.0" "$ver_out"

# --list-themes exits 0
themes_out=$(env -u LOFETCH_SOURCED bash "$SCRIPT_DIR/lofetch" --list-themes 2>&1)
themes_rc=$?
assert_exit_code "--list-themes exits 0" "0" "$themes_rc"
assert_match "--list-themes shows crt" "crt" "$themes_out"
assert_match "--list-themes shows neon" "neon" "$themes_out"

# --list-modules exits 0
mods_out=$(env -u LOFETCH_SOURCED bash "$SCRIPT_DIR/lofetch" --list-modules 2>&1)
mods_rc=$?
assert_exit_code "--list-modules exits 0" "0" "$mods_rc"
assert_match "--list-modules shows os" "os" "$mods_out"
assert_match "--list-modules shows cpu" "cpu" "$mods_out"

# Unknown flag exits non-zero
unknown_out=$(env -u LOFETCH_SOURCED bash "$SCRIPT_DIR/lofetch" --bogus 2>&1)
unknown_rc=$?
assert_match "Unknown flag reports error" "unknown option" "$unknown_out"

# ── Test: No-Color Output ────────────────────────────────

echo ""
echo "=== No-Color Output ==="

nocolor_out=$(NO_COLOR=1 env -u LOFETCH_SOURCED bash "$SCRIPT_DIR/lofetch" --compact 2>&1)
# Should contain no ESC (0x1b) bytes
esc_byte=$'\033'
if [[ "$nocolor_out" != *"$esc_byte"* ]]; then
    ((PASS++)); printf "  ✓ NO_COLOR output has no ANSI escapes\n"
else
    ((FAIL++)); printf "  ✗ NO_COLOR output contains ANSI escapes\n"
fi

nocolor_flag_out=$(env -u LOFETCH_SOURCED bash "$SCRIPT_DIR/lofetch" --no-color --compact 2>&1)
if [[ "$nocolor_flag_out" != *"$esc_byte"* ]]; then
    ((PASS++)); printf "  ✓ --no-color output has no ANSI escapes\n"
else
    ((FAIL++)); printf "  ✗ --no-color output contains ANSI escapes\n"
fi

# ── Test: JSON Output ────────────────────────────────────

echo ""
echo "=== JSON Output ==="

json_out=$(env -u LOFETCH_SOURCED bash "$SCRIPT_DIR/lofetch" --json 2>&1)
json_rc=$?
assert_exit_code "--json exits 0" "0" "$json_rc"
assert_match "JSON has version field" '"version"' "$json_out"
assert_match "JSON has platform field" '"platform"' "$json_out"
assert_match "JSON has os object" '"os"' "$json_out"
assert_match "JSON has network object" '"network"' "$json_out"
assert_match "JSON has cpu object" '"cpu"' "$json_out"
assert_match "JSON has memory object" '"memory"' "$json_out"
assert_match "JSON has disk object" '"disk"' "$json_out"
assert_match "JSON has session object" '"session"' "$json_out"

# Validate JSON with python if available
if command -v python3 &>/dev/null; then
    if echo "$json_out" | python3 -m json.tool > /dev/null 2>&1; then
        ((PASS++)); printf "  ✓ JSON output is valid (python3 verified)\n"
    else
        ((FAIL++)); printf "  ✗ JSON output is invalid\n"
    fi
fi

# ── Test: Module Filtering ───────────────────────────────

echo ""
echo "=== Module Filtering ==="

mod_out=$(env -u LOFETCH_SOURCED bash "$SCRIPT_DIR/lofetch" --no-color --compact --modules os 2>&1)
assert_match "os module shows DISTRO" "DISTRO" "$mod_out"
assert_match "os module shows RELEASE" "RELEASE" "$mod_out"
assert_no_match "os-only hides HOST" "HOST" "$mod_out"
assert_no_match "os-only hides CPU" "CPU" "$mod_out"

mod_cpu_out=$(env -u LOFETCH_SOURCED bash "$SCRIPT_DIR/lofetch" --no-color --compact --modules cpu 2>&1)
assert_match "cpu module shows CPU" "CPU" "$mod_cpu_out"
assert_no_match "cpu-only hides HOST" "HOST" "$mod_cpu_out"

mod_multi=$(env -u LOFETCH_SOURCED bash "$SCRIPT_DIR/lofetch" --no-color --compact --modules os,mem 2>&1)
assert_match "os,mem shows DISTRO" "DISTRO" "$mod_multi"
assert_match "os,mem shows RAM" "RAM" "$mod_multi"
assert_no_match "os,mem hides HOST" "HOST" "$mod_multi"

# ── Test: Compact Mode ──────────────────────────────────

echo ""
echo "=== Compact Mode ==="

compact_out=$(env -u LOFETCH_SOURCED bash "$SCRIPT_DIR/lofetch" --no-color --compact 2>&1)
assert_match "compact shows LOFETCH" "LOFETCH" "$compact_out"
# Should NOT contain SYSTEM OVERVIEW (full header only)
assert_no_match "compact hides SYSTEM OVERVIEW" "SYSTEM OVERVIEW" "$compact_out"

# ── Test: Config File Parsing ────────────────────────────

echo ""
echo "=== Config File ==="

# Create a temporary config file
tmp_config=$(mktemp)
printf "theme=minimal\nmodules=os,mem\n" > "$tmp_config"

config_out=$(LOFETCH_CONFIG="$tmp_config" env -u LOFETCH_SOURCED bash "$SCRIPT_DIR/lofetch" --no-color --compact 2>&1)
# Config sets modules to os,mem, so should NOT see HOST (net module)
assert_no_match "config modules=os,mem hides HOST" "HOST" "$config_out"
assert_match "config shows DISTRO" "DISTRO" "$config_out"
assert_match "config shows RAM" "RAM" "$config_out"

# CLI flag overrides config
override_out=$(LOFETCH_CONFIG="$tmp_config" env -u LOFETCH_SOURCED bash "$SCRIPT_DIR/lofetch" --no-color --compact --modules os,cpu 2>&1)
assert_match "CLI --modules overrides config" "CPU" "$override_out"
assert_no_match "CLI override hides RAM" "RAM" "$override_out"

rm -f "$tmp_config"

# ── Test: Full Output Structure ──────────────────────────

echo ""
echo "=== Full Output Structure ==="

clear_all_colors
full_output=$(env -u LOFETCH_SOURCED bash "$SCRIPT_DIR/lofetch" --no-color 2>/dev/null || true)

if [[ -n "$full_output" ]]; then
    first_line=$(echo "$full_output" | head -1)
    assert_match "output starts with ┌" "^┌" "$first_line"

    last_line=$(echo "$full_output" | tail -1)
    assert_match "output ends with ┘" "┘$" "$last_line"

    assert_match "output contains SYSTEM OVERVIEW" "SYSTEM OVERVIEW" "$full_output"

    # Count separators (├...┤) — should have at least 6 section dividers
    sep_count=$(echo "$full_output" | grep -c "^├" || true)
    if [[ "$sep_count" -ge 6 ]]; then
        ((PASS++)); printf "  ✓ has ≥6 section separators (%d found)\n" "$sep_count"
    else
        ((FAIL++)); printf "  ✗ expected ≥6 separators, got %d\n" "$sep_count"
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

# ── Test: json_escape ────────────────────────────────────

echo ""
echo "=== json_escape ==="

assert_eq "json_escape plain text" "hello world" "$(json_escape "hello world")"
assert_eq "json_escape quotes" 'say \"hi\"' "$(json_escape 'say "hi"')"
assert_eq "json_escape backslash" 'a\\b' "$(json_escape 'a\b')"

# ── Summary ──────────────────────────────────────────────

echo ""
echo "════════════════════════════════════"
printf "Results: %d passed, %d failed\n" "$PASS" "$FAIL"
echo "════════════════════════════════════"

exit "$FAIL"
