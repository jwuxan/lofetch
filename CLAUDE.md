# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

zfetch is a cross-platform system information display tool (neofetch-like) implemented as a single self-contained shell script (`zfetch`). It renders a retro CRT-style "ZFETCH / MACHINE REPORT" box with color themes, ASCII art logo, and gradient progress bars showing OS, network, CPU, memory, disk, and session info. Target platforms: Linux, macOS, Windows (Git Bash/MINGW, WSL).

## Commands

```bash
./zfetch                 # Run the tool
bash test_zfetch.sh      # Run the test suite (80+ assertions)
shellcheck zfetch        # Lint (if shellcheck installed)
make test                # Run tests via Makefile
make lint                # Lint via Makefile
make install             # Install to /usr/local/bin
make uninstall           # Remove from /usr/local/bin
```

No build step. Only requires bash and standard system commands.

## Architecture

`zfetch` is organized into these sequential sections:

1. **Constants** — `ZFETCH_VERSION`, `BOX_INNER_WIDTH=52`, `LABEL_WIDTH=13`, `BAR_WIDTH=22`, fill/empty Unicode chars, default modules
2. **Color Support Detection** — `detect_color_support()` checks `NO_COLOR`, `TERM=dumb`, `COLORTERM`, `tput colors`, sets `COLOR_LEVEL` (0-3)
3. **Color Variable System** — 4 theme functions (`apply_theme_crt/neon/minimal/plain`) setting `C_*` color variables using `$'\033'` ANSI-C quoting for actual ESC bytes. `apply_theme()` dispatches by name, `clear_all_colors()` zeros everything
4. **Rendering helpers** — `draw_bar` (colorized gradient bars), `draw_bar_plain` (for width calcs), `print_row`, `print_bar_row`, `print_centered`, border functions. All use `C_*` variables. Manual padding for Unicode (printf `%*s` counts bytes, not display columns)
5. **ASCII Art Header** — `print_ascii_logo()` renders Unicode block-char ZFETCH logo, `print_header()` switches between full/compact mode
6. **`detect_platform`** — returns `linux`, `macos`, `windows_wsl`, or `windows_mingw`
7. **Data collection** — `get_os_info`, `get_network_info`, `get_cpu_info`, `get_load_info`, `get_memory_info`, `get_disk_info`, `get_session_info`. Each sets global variables and uses `case "$platform"` branching
8. **Config File Support** — `load_config()` reads `$ZFETCH_CONFIG` or `~/.config/zfetch/config` (KEY=VALUE format)
9. **CLI Argument Parsing** — `parse_args()` via while/case loop. Supports `--help`, `--version`, `--theme`, `--modules`, `--json`, `--compact`, `--no-color`, `--list-themes`, `--list-modules`
10. **Module Rendering** — `render_os_section`, `render_net_section`, `render_cpu_section`, `render_mem_section`, `render_disk_section`, `render_session_section`
11. **JSON Output** — `render_json()` produces structured JSON via printf, `json_escape()` handles special chars
12. **`render_report`** — iterates `ENABLED_MODULES`, calls module renderers with separators
13. **Entry Point** — `ZFETCH_SOURCED=1` env var prevents execution when sourced (used by tests). Otherwise: parse_args → load_config → detect_color_support → apply_theme → render

**Key conventions:**
- All fields default to `"N/A"` when unavailable
- Memory is reported in GiB (binary), disk in GB (decimal)
- Float math uses `awk "BEGIN {...}"` (no bc dependency)
- `LC_NUMERIC=C` ensures consistent decimal parsing
- Color variables use `$'\033'` ANSI-C quoting (not `"\033"`) so ESC bytes are stored directly — critical for `printf %s` which doesn't interpret backslash escapes
- Priority chain: CLI flags > env vars > config file > defaults

## Testing

`test_zfetch.sh` sources `zfetch` with `ZFETCH_SOURCED=1`, then tests each function independently. Test helpers: `assert_eq`, `assert_match`, `assert_not_empty`, `assert_numeric`. Tests cover: constants, `draw_bar` edge cases, row/border formatting, platform detection, all `get_*` data population, CLI flags, color/no-color output, JSON validity, module filtering, theme loading, config parsing, and full output structural integrity.

## Platform Branching Reference

| Data | Linux/WSL | macOS | MINGW |
|------|-----------|-------|-------|
| OS | `/etc/os-release` | `sw_vers` | `cmd /c ver` |
| IP | `hostname -I` | `ipconfig getifaddr en0` | `ipconfig` parse |
| CPU | `/proc/cpuinfo` | `sysctl machdep.cpu.*` | `PROCESSOR_IDENTIFIER` env |
| Memory | `free -b` | `sysctl hw.memsize` + `vm_stat` | `wmic OS` |
| Hypervisor | `systemd-detect-virt` | `sysctl kern.hv_vmm_present` | N/A |
