# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

zfetch is a cross-platform system information display tool (neofetch-like) — a single self-contained bash script with zero dependencies. It renders a CRT-style box with ASCII art logo, color themes, gradient progress bars, and system info (OS, network, CPU, memory, disk, session). Targets Linux, macOS, Windows (WSL, MINGW).

## Commands

```bash
./zfetch                           # Run the tool
bash test_zfetch.sh                # Run full test suite (110 assertions)
shellcheck zfetch                  # Lint
make test                          # Alias for test suite
make lint                          # Alias for shellcheck
```

There is no build step or install step required for development. The primary script is `zfetch`. The legacy `report.sh` and `test_report.sh` are older copies kept for backward compatibility.

The test suite has no per-test granularity — it runs all assertions in one pass. The exit code equals the failure count (0 = all pass). CI runs on both `ubuntu-latest` and `macos-latest`.

## Architecture

`zfetch` is a single ~936-line bash script organized in sequential sections. The execution flow is:

**Entry point** (line 924): `parse_args` → `load_config` → `detect_color_support` → `apply_theme` → `render_report` (or `render_json`). Setting `ZFETCH_SOURCED=1` prevents execution, exporting all functions for testing.

**Key architectural layers:**

- **Color system**: `detect_color_support()` sets `COLOR_LEVEL` (0-3). Four theme functions (`apply_theme_crt/neon/minimal/plain`) set `C_*` color variables. `apply_theme()` dispatches by name and clears all colors when `COLOR_LEVEL=0`.
- **Rendering**: `print_row`, `print_bar_row`, `print_centered`, border functions — all reference `C_*` variables. `draw_bar` produces colorized gradient bars; `draw_bar_plain` produces uncolored bars for width calculations.
- **Data collection**: `get_os_info`, `get_network_info`, `get_cpu_info`, `get_load_info`, `get_memory_info`, `get_disk_info`, `get_session_info` — each sets global variables and uses `case "$platform"` branching.
- **Module system**: `render_report()` iterates `ENABLED_MODULES` (comma-separated), calling `render_<name>_section()` functions. Separators between each module.
- **Config priority**: CLI flags (`_CLI_THEME`/`_CLI_MODULES` guard vars) > `ZFETCH_THEME` env var > config file (`~/.config/zfetch/config`) > defaults.

## Critical Implementation Details

**ANSI-C quoting for colors**: Color variables MUST use `$'\033[...'` syntax (not `"\033[...]"`). The `$'...'` form stores actual ESC bytes in the variable. This is critical because `draw_bar` builds color codes into strings and outputs them via `printf "%s"`, which does NOT interpret `\033` escape sequences — it only passes through actual bytes.

**Unicode padding**: `printf %-Ns` pads by byte count, not display columns. Since Unicode block chars (`█░▓▒`) are 3 bytes but 1 display column, all centering and padding for lines containing Unicode must be done manually with space loops (see `print_centered`, `print_ascii_logo`, `print_bar_row`).

**`set -euo pipefail` propagation**: The main script uses `set -euo pipefail`. When sourced for testing, this propagates `errexit` to the test shell. The test suite must `set +e` after sourcing. Also, `while read` loops must end with `|| true` to prevent EOF from triggering errexit (see `load_config`).

**`ZFETCH_SOURCED` export**: Tests export `ZFETCH_SOURCED=1` before sourcing. When launching subprocess tests (`bash "$SCRIPT_DIR/zfetch" --flag`), use `env -u ZFETCH_SOURCED` to prevent the inherited env var from suppressing execution.

## Testing

`test_zfetch.sh` uses two testing approaches:
1. **In-process**: Sources `zfetch` and calls functions directly (constants, bar rendering, themes, data collection, color detection)
2. **Subprocess**: Runs `env -u ZFETCH_SOURCED bash zfetch <flags>` to test CLI flags, JSON output, module filtering, config file parsing, no-color output

Test helpers: `assert_eq`, `assert_match`, `assert_not_empty`, `assert_no_match`, `assert_exit_code`, `assert_numeric`.

## Platform Branching

| Data | Linux/WSL | macOS | MINGW |
|------|-----------|-------|-------|
| OS | `/etc/os-release` | `sw_vers` | `cmd /c ver` |
| IP | `hostname -I` | `ipconfig getifaddr en0` | `ipconfig` parse |
| CPU | `/proc/cpuinfo` | `sysctl machdep.cpu.*` | `PROCESSOR_IDENTIFIER` env |
| Memory | `free -b` | `sysctl hw.memsize` + `vm_stat` | `wmic OS` |
| Hypervisor | `systemd-detect-virt` | `sysctl kern.hv_vmm_present` | N/A |

## Adding a Theme

Add a function `apply_theme_<name>()` that sets all 12 `C_*` variables using `$'\033[...]'` syntax. Register it in `apply_theme()`'s case statement.

## Adding a Module

1. Add `get_<name>_info()` — sets global variables
2. Add `render_<name>_section()` — calls `print_row`/`print_bar_row`
3. Add case in `render_report()` loop
4. Add JSON fields in `render_json()`
5. Add tests in `test_zfetch.sh`
