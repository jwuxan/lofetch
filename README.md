# zfetch

> A retro CRT-style system information display. One script. Zero dependencies. Every platform.

```
┌────────────────────────────────────────────────────┐
│                                                    │
│  ▐███▀▀▀ ▐███▀▀▀ ▐███▀▀▀ ███████ ▐███▀▀▀ ██▌  ██▌  │
│    ▄██▀  ▐██▄▄   ▐██▄▄     ██▌   ▐██▌    ████████▌  │
│  ▄██▀    ▐██▀▀   ▐██▀▀     ██▌   ▐██▌    ██▌▀▀██▌   │
│  ███████ ▐██▌    ▐███▄▄▄   ██▌   ▐███▄▄▄ ██▌  ██▌   │
│                                                    │
│                   MACHINE REPORT                   │
│           v1.0.0 · 2026-02-12 · macos              │
├────────────────────────────────────────────────────┤
│ OS           macOS 15.3                            │
│ KERNEL       Darwin 24.3.0                         │
├────────────────────────────────────────────────────┤
│ HOSTNAME     workstation.local                     │
│ MACHINE IP   192.168.1.42                          │
│ ...                                                │
└────────────────────────────────────────────────────┘
```

## Features

- **Cross-platform** — Linux, macOS, Windows (WSL & MINGW)
- **4 color themes** — CRT green, neon synthwave, minimal, plain
- **Zero dependencies** — just bash and standard system commands
- **Single file** — one script, copy it anywhere
- **JSON output** — pipe system info to your scripts
- **Modular** — show only the sections you need
- **NO_COLOR compliant** — respects [no-color.org](https://no-color.org/) standard

## Install

### Quick install

```bash
# Clone and install
git clone https://github.com/YOUR_USER/zfetch.git
cd zfetch
sudo make install
```

### Manual

```bash
# Copy the script anywhere on your PATH
curl -sL https://raw.githubusercontent.com/YOUR_USER/zfetch/main/zfetch -o ~/.local/bin/zfetch
chmod +x ~/.local/bin/zfetch
```

## Usage

```bash
zfetch                          # Full CRT-style report
zfetch --theme neon             # Cyberpunk neon theme
zfetch --compact                # Compact single-line header
zfetch --modules os,cpu,mem     # Only show selected sections
zfetch --json                   # JSON output for scripting
zfetch --no-color               # Disable colors
zfetch --list-themes            # Show available themes
zfetch --list-modules           # Show available modules
NO_COLOR=1 zfetch               # Also disables colors
```

## Themes

| Theme | Description |
|-------|-------------|
| `crt` | Phosphor green CRT terminal (default) |
| `neon` | Cyberpunk neon synthwave |
| `minimal` | Clean understated monochrome |
| `plain` | No colors (for piping/logging) |

## Modules

| Module | Info |
|--------|------|
| `os` | Operating system and kernel version |
| `net` | Hostname, IPs, DNS, user |
| `cpu` | Processor model, cores, frequency, load averages |
| `mem` | Memory usage with progress bar |
| `disk` | Disk usage with progress bar, ZFS health |
| `session` | Last login and uptime |

## Configuration

Create `~/.config/zfetch/config`:

```
theme=crt
modules=os,cpu,mem,disk
```

Priority: CLI flags > environment variables > config file > defaults.

Environment variables:
- `ZFETCH_THEME` — set default theme
- `ZFETCH_CONFIG` — custom config file path
- `NO_COLOR` — disable all colors

## Contributing

### Adding a theme

Each theme is a bash function `apply_theme_<name>()` that sets `C_*` color variables. See existing themes in `zfetch` for the pattern.

### Adding a module

1. Create a `get_<name>_info()` data collection function
2. Create a `render_<name>_section()` rendering function
3. Add the module name to the `render_report()` case statement
4. Add corresponding JSON fields in `render_json()`
5. Add tests in `test_zfetch.sh`

## License

[MIT](LICENSE)
