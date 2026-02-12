# Modules

## Built-in Modules

| Module | Displays |
|--------|----------|
| `os` | Operating system name, kernel version |
| `net` | Hostname, machine IP, client IP, DNS IP, user |
| `cpu` | Processor model, cores/sockets, hypervisor, frequency, load averages (1/5/15m bars) |
| `mem` | Memory usage (used/total GiB), percentage, progress bar |
| `disk` | Disk usage (used/total GB), percentage, progress bar, ZFS health |
| `session` | Last login (with IP if SSH), uptime |

Default: all six modules in order `os,net,cpu,mem,disk,session`.

## Usage

```bash
lofetch --modules os,cpu,mem        # Only show selected modules
lofetch --modules os                # Single module
lofetch --list-modules              # Show available modules
```

Module order in the output matches the order specified.

## Configuration

In config file:

```
modules=os,cpu,mem,disk
```

## Creating a Module

1. **Data collection**: Add `get_<name>_info()` that sets global variables
2. **Rendering**: Add `render_<name>_section()` that calls `print_row` and/or `print_bar_row`
3. **Registration**: Add case in `render_report()` loop
4. **JSON**: Add fields in `render_json()`
5. **Tests**: Add assertions in `test_lofetch.sh`

### Data Collection Pattern

```bash
get_example_info() {
    local platform
    platform="$(detect_platform)"
    case "$platform" in
        linux|windows_wsl)
            EXAMPLE_VALUE="linux-specific-command"
            ;;
        macos)
            EXAMPLE_VALUE="macos-specific-command"
            ;;
        windows_mingw)
            EXAMPLE_VALUE="windows-specific-command"
            ;;
    esac
    EXAMPLE_VALUE="${EXAMPLE_VALUE:-N/A}"
}
```

### Rendering Pattern

```bash
render_example_section() {
    print_row "LABEL" "$EXAMPLE_VALUE"
    # For progress bars:
    # print_bar_row "USAGE" "$(draw_bar "$PERCENT_INT" "$BAR_WIDTH")"
}
```
