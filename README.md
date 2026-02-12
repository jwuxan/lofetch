# Lofetch

> A retro CRT-style system information display. One script. Zero dependencies. Every platform.

[![CI](https://github.com/jwuxan/lofetch/workflows/CI/badge.svg)](https://github.com/jwuxan/lofetch/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/bash-%3E%3D4.0-green.svg)](https://www.gnu.org/software/bash/)

## Preview

```
┌────────────────────────────────────────────────────┐
│                                                    │
│  ▐██▌   ▐████▌ ▐████▌ ▐████▌ ██████ ▐████▌ ██  ██  │
│  ▐██▌   ██▌ ██ ▐██▄▄  ▐██▄▄   ▐██▌  ▐██▌   ██████  │
│  ▐██▌   ██▌ ██ ▐██▀▀  ▐██▀▀   ▐██▌  ▐██▌   ██  ██  │
│  ▐████▌ ▐████▌ ▐██▌   ▐████▌  ▐██▌  ▐████▌ ██  ██  │
│                                                    │
│                  SYSTEM OVERVIEW                   │
│           v2.0.0 · 2026-02-13 · macos              │
├────────────────────────────────────────────────────┤
│ DISTRO       macOS 15.3                            │
│ RELEASE      Darwin 24.3.0                         │
├────────────────────────────────────────────────────┤
│ CPU          Apple M2 Pro                          │
│ TOPOLOGY     12c / 1s                              │
│ ...                                                │
└────────────────────────────────────────────────────┘
```

## Features

- **Cross-platform** — Linux, macOS, Windows (WSL & MINGW)
- **4 color themes** — CRT green, neon synthwave, minimal, plain
- **Zero dependencies** — just bash and standard system commands
- **Single file** — one script, copy it anywhere
- **JSON output** — pipe system info to your scripts
- **Modular sections** — show only the data you need
- **NO_COLOR compliant** — respects [no-color.org](https://no-color.org/) standard

## Quick Start

### Install via npm

```bash
# Global install
npm install -g lofetch

# Or run without installing
npx lofetch
```

### Install via Homebrew

```bash
brew tap jwuxan/lofetch https://github.com/jwuxan/lofetch
brew install lofetch
```

### Install via Git

```bash
git clone https://github.com/jwuxan/lofetch.git
cd lofetch
make install
```

### One-liner install

```bash
curl -sL https://raw.githubusercontent.com/jwuxan/lofetch/main/lofetch -o ~/.local/bin/lofetch && chmod +x ~/.local/bin/lofetch
```

See [INSTALL.md](INSTALL.md) for detailed installation instructions and troubleshooting.

## Usage

```bash
lofetch                          # Full CRT-style report
lofetch --theme neon             # Cyberpunk neon theme
lofetch --compact                # Compact single-line header
lofetch --modules os,cpu,mem     # Only show selected sections
lofetch --json                   # JSON output for scripting
lofetch --no-color               # Disable colors
lofetch --list-themes            # Show available themes
lofetch --list-modules           # Show available modules
NO_COLOR=1 lofetch               # Also disables colors
```

## Themes

| Theme | Description |
|-------|-------------|
| `crt` | Phosphor green CRT terminal (default) |
| `neon` | Cyberpunk neon synthwave |
| `minimal` | Clean understated monochrome |
| `plain` | No colors (for piping/logging) |

Set with `lofetch --theme <name>` or configure via `~/.config/lofetch/config`.

## Modules

| Module | Info |
|--------|------|
| `os` | Distro and kernel release |
| `cpu` | CPU model, topology, clock, load averages |
| `mem` | RAM utilization with progress bar |
| `disk` | Disk capacity with progress bar, ZFS status |
| `net` | Host, IPs, resolver, username |
| `session` | Last session and running time |

Filter with `lofetch --modules os,cpu,mem` or configure via `~/.config/lofetch/config`.

## Configuration

Create `~/.config/lofetch/config`:

```
theme=crt
modules=os,cpu,mem,disk,net,session
```

### Environment variables

- `LOFETCH_THEME` — set default theme
- `LOFETCH_CONFIG` — custom config file path
- `NO_COLOR` — disable all colors

### Priority chain

CLI flags > environment variables > config file > defaults

## JSON Output

Lofetch can output structured JSON for scripting and automation:

```bash
lofetch --json | jq .
```

See [docs/JSON-OUTPUT.md](docs/JSON-OUTPUT.md) for the full schema.

## Platform Support

Lofetch works on:

- Linux (all major distros)
- macOS (10.13+)
- Windows (WSL 1/2, MINGW, Git Bash)

See [docs/PLATFORM-SUPPORT.md](docs/PLATFORM-SUPPORT.md) for platform-specific details.

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for:

- Adding new themes
- Adding new modules
- Testing guidelines
- Code style

## Migrating from zfetch

If you're upgrading from the original `zfetch`:

1. Rename your config directory: `mv ~/.config/zfetch ~/.config/lofetch`
2. Update environment variables: `ZFETCH_THEME` → `LOFETCH_THEME`, `ZFETCH_CONFIG` → `LOFETCH_CONFIG`
3. Update your `$PATH` if you installed manually

The script is 100% compatible with existing configs — only the names changed.

## License

[MIT](LICENSE)
