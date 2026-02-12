# Contributing to Lofetch

Thank you for your interest in contributing to lofetch! We welcome all types of contributions:

- Bug reports and feature requests
- New color themes
- New system information modules
- Documentation improvements
- Test coverage expansion
- Platform compatibility fixes

We're committed to maintaining a welcoming and inclusive community. All contributors are expected to engage respectfully and constructively.

## Getting Started

Clone the repository and verify your development environment:

```bash
git clone https://github.com/YOUR_USER/lofetch.git
cd lofetch
./lofetch                    # Run the tool
bash test_lofetch.sh         # Run tests (110 assertions, exit 0 = pass)
shellcheck lofetch           # Lint
```

There is no build step or install step required for development. The primary script is `lofetch`.

## Development Workflow

1. **Fork the repository** on GitHub
2. **Create a feature branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes** to the `lofetch` script
4. **Run the test suite** — all 110 assertions must pass:
   ```bash
   bash test_lofetch.sh
   ```
5. **Run shellcheck** — no new warnings allowed:
   ```bash
   shellcheck lofetch
   ```
6. **Commit your changes** with a descriptive message
7. **Submit a pull request** to the main repository

## Architecture Overview

lofetch is a single ~936-line bash script organized in sequential sections. Understanding the execution flow will help you contribute effectively.

### Execution Flow

**Entry point** (line 924):
```
parse_args → load_config → detect_color_support → apply_theme → render_report (or render_json)
```

Setting `LOFETCH_SOURCED=1` prevents execution, exporting all functions for testing.

### Key Architectural Layers

**Color system**:
- `detect_color_support()` sets `COLOR_LEVEL` (0-3)
- Theme functions (`apply_theme_crt/neon/minimal/plain`) set `C_*` color variables
- `apply_theme()` dispatches by name and clears all colors when `COLOR_LEVEL=0`

**Rendering**:
- `print_row`, `print_bar_row`, `print_centered`, border functions — all reference `C_*` variables
- `draw_bar` produces colorized gradient bars
- `draw_bar_plain` produces uncolored bars for width calculations

**Data collection**:
- `get_os_info`, `get_network_info`, `get_cpu_info`, `get_load_info`, `get_memory_info`, `get_disk_info`, `get_session_info`
- Each sets global variables and uses `case "$platform"` branching for platform-specific logic

**Module system**:
- `render_report()` iterates `ENABLED_MODULES` (comma-separated)
- Calls `render_<name>_section()` functions
- Separators between each module

**Config priority** (highest to lowest):
1. CLI flags (`_CLI_THEME`/`_CLI_MODULES` guard vars)
2. `LOFETCH_THEME` environment variable
3. Config file (`~/.config/lofetch/config`)
4. Defaults

### Platform Branching

| Data | Linux/WSL | macOS | MINGW |
|------|-----------|-------|-------|
| OS | `/etc/os-release` | `sw_vers` | `cmd /c ver` |
| IP | `hostname -I` | `ipconfig getifaddr en0` | `ipconfig` parse |
| CPU | `/proc/cpuinfo` | `sysctl machdep.cpu.*` | `PROCESSOR_IDENTIFIER` env |
| Memory | `free -b` | `sysctl hw.memsize` + `vm_stat` | `wmic OS` |
| Hypervisor | `systemd-detect-virt` | `sysctl kern.hv_vmm_present` | N/A |

## Adding a Theme

Themes define the color palette for the entire display. Follow these steps:

1. **Create a theme function** `apply_theme_<name>()` that sets all 12 `C_*` variables:
   - `C_RESET` — Reset all formatting
   - `C_BORDER` — Box border characters
   - `C_LABEL` — Field labels (e.g., "OS", "CPU")
   - `C_VALUE` — Field values
   - `C_HEADER` — Main header text
   - `C_SUBTITLE` — Subtitle text
   - `C_BAR_LOW` — Progress bar low range (0-33%)
   - `C_BAR_MED` — Progress bar medium range (34-66%)
   - `C_BAR_HI` — Progress bar high range (67-100%)
   - `C_BAR_EMPTY` — Progress bar empty portion
   - `C_DIM` — Dimmed text
   - `C_LOGO` — ASCII art logo

2. **CRITICAL: Use ANSI-C quoting syntax** — `$'\033[...]'` NOT `"\033[...]"`

   This is critical because `draw_bar` builds color codes into strings and outputs them via `printf "%s"`, which does NOT interpret `\033` escape sequences — it only passes through actual bytes. The `$'...'` form stores actual ESC bytes in the variable.

   Example:
   ```bash
   apply_theme_mytheme() {
       C_RESET=$'\033[0m'
       C_BORDER=$'\033[38;5;51m'
       C_LABEL=$'\033[38;5;117m'
       C_VALUE=$'\033[38;5;231m'
       # ... set remaining 8 variables
   }
   ```

3. **Register in `apply_theme()`** case statement:
   ```bash
   case "$theme" in
       crt) apply_theme_crt ;;
       neon) apply_theme_neon ;;
       minimal) apply_theme_minimal ;;
       plain) apply_theme_plain ;;
       mytheme) apply_theme_mytheme ;;  # Add your theme here
       *) echo "Unknown theme: $theme" >&2; exit 1 ;;
   esac
   ```

4. **Add to `list_themes()`** output so users can discover it:
   ```bash
   list_themes() {
       echo "crt neon minimal plain mytheme"
   }
   ```

5. **Add tests** in `test_lofetch.sh`:
   ```bash
   # Test theme applies correctly
   apply_theme "mytheme"
   assert_not_empty "mytheme sets C_BORDER" "$C_BORDER"
   assert_not_empty "mytheme sets C_LABEL" "$C_LABEL"
   ```

## Adding a Module

Modules are self-contained sections that display specific system information (OS, CPU, memory, etc.).

1. **Add `get_<name>_info()`** — Collect system data and set global variables:
   ```bash
   get_mymodule_info() {
       case "$platform" in
           Linux)
               MY_DATA=$(cat /proc/mydata)
               ;;
           Darwin)
               MY_DATA=$(sysctl -n hw.mydata)
               ;;
           MINGW*)
               MY_DATA=$(echo "$PROCESSOR_IDENTIFIER")
               ;;
       esac
   }
   ```

2. **Add `render_<name>_section()`** — Display the collected data:
   ```bash
   render_mymodule_section() {
       get_mymodule_info
       print_row "My Module" "$MY_DATA"
   }
   ```

3. **Add case in `render_report()` loop**:
   ```bash
   case "$module" in
       os) render_os_section ;;
       network) render_network_section ;;
       mymodule) render_mymodule_section ;;  # Add here
       # ... other modules
   esac
   ```

4. **Add JSON fields in `render_json()`**:
   ```bash
   render_json() {
       get_os_info
       get_network_info
       get_mymodule_info  # Collect data

       cat <<JSON
   {
     "os": "$os_name $os_version",
     "network": "$public_ip",
     "mymodule": "$MY_DATA",
     ...
   }
   JSON
   }
   ```

5. **Add to `DEFAULT_MODULES`** if it should be enabled by default:
   ```bash
   DEFAULT_MODULES="os,network,cpu,load,memory,disk,session,mymodule"
   ```

6. **Add tests** in `test_lofetch.sh`:
   ```bash
   # Test data collection
   get_mymodule_info
   assert_not_empty "mymodule collects data" "$MY_DATA"

   # Test rendering
   output=$(render_mymodule_section)
   assert_match "mymodule renders" "My Module" "$output"

   # Test JSON output
   json_output=$(env -u LOFETCH_SOURCED bash "$SCRIPT_DIR/lofetch" --json 2>&1)
   assert_match "JSON includes mymodule" '"mymodule":' "$json_output"
   ```

## Testing

The test suite (`test_lofetch.sh`) uses two approaches:

### 1. In-Process Testing
Sources `lofetch` with `LOFETCH_SOURCED=1` and calls functions directly. Used for unit testing individual functions:

```bash
# Source with LOFETCH_SOURCED=1 to prevent execution
export LOFETCH_SOURCED=1
source ./lofetch
set +e  # Disable errexit inherited from script

# Test a function
my_result=$(some_function "arg")
assert_eq "description" "expected" "$my_result"
```

### 2. Subprocess Testing
Runs `env -u LOFETCH_SOURCED bash lofetch <flags>` for CLI integration tests:

```bash
# Test CLI flags
output=$(env -u LOFETCH_SOURCED bash "$SCRIPT_DIR/lofetch" --theme neon 2>&1)
assert_match "neon theme applied" "pattern" "$output"
```

### Available Test Helpers

- `assert_eq "description" "expected" "actual"` — Exact string match
- `assert_match "description" "pattern" "text"` — Regex pattern match
- `assert_not_empty "description" "value"` — Value is not empty
- `assert_no_match "description" "pattern" "text"` — Pattern does NOT match
- `assert_exit_code "description" expected_code command args...` — Exit code match
- `assert_numeric "description" "value"` — Value is numeric

### Adding a Test

```bash
# In-process test example
my_result=$(some_function "arg")
assert_eq "function returns correct value" "expected" "$my_result"

# Subprocess test example
output=$(env -u LOFETCH_SOURCED bash "$SCRIPT_DIR/lofetch" --flag 2>&1)
assert_match "flag produces expected output" "pattern" "$output"
```

All tests run in one pass. The exit code equals the failure count (0 = all pass).

## Code Style

### Critical Implementation Details

**ANSI-C quoting for colors**:
Color variables MUST use `$'\033[...'` syntax (not `"\033[...]"`). The `$'...'` form stores actual ESC bytes in the variable. This is critical because `draw_bar` builds color codes into strings and outputs them via `printf "%s"`, which does NOT interpret `\033` escape sequences — it only passes through actual bytes.

**Unicode padding**:
`printf %-Ns` pads by byte count, not display columns. Since Unicode block chars (`█░▓▒`) are 3 bytes but 1 display column, all centering and padding for lines containing Unicode must be done manually with space loops (see `print_centered`, `print_ascii_logo`, `print_bar_row`).

**`set -euo pipefail` propagation**:
The main script uses `set -euo pipefail`. When sourced for testing, this propagates `errexit` to the test shell. The test suite must `set +e` after sourcing. Also, `while read` loops must end with `|| true` to prevent EOF from triggering errexit (see `load_config`).

**`LOFETCH_SOURCED` export**:
Tests export `LOFETCH_SOURCED=1` before sourcing. When launching subprocess tests (`bash "$SCRIPT_DIR/lofetch" --flag`), use `env -u LOFETCH_SOURCED` to prevent the inherited env var from suppressing execution.

### General Guidelines

- Use descriptive variable names
- Add comments for complex logic
- Follow existing code formatting conventions
- Maintain platform compatibility (Linux, macOS, Windows/WSL/MINGW)
- Keep functions focused and single-purpose

## Pull Request Process

1. **All 110 test assertions must pass**:
   ```bash
   bash test_lofetch.sh
   # Exit code should be 0
   ```

2. **shellcheck must produce no new warnings**:
   ```bash
   shellcheck lofetch
   ```

3. **CI validation**: Automated tests run on both `ubuntu-latest` and `macos-latest`

4. **Code review**: One approval required for merge

5. **Keep PRs focused**: One feature or fix per pull request. This makes review easier and speeds up the merge process.

6. **Write a clear PR description**:
   - What problem does this solve?
   - What changes were made?
   - How was it tested?
   - Any breaking changes?

## Questions or Issues?

- Open an issue on GitHub for bug reports or feature requests
- Include your OS, shell version, and terminal emulator in bug reports
- Provide reproduction steps for bugs

Thank you for contributing to lofetch!
