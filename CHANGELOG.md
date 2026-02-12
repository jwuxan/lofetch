# Changelog

## 2.0.0 (2026-02-13)

### Breaking Changes
- **All 21 display labels renamed** to differentiate from TR-100:
  - OS → DISTRO, KERNEL → RELEASE, HOSTNAME → HOST, MACHINE IP → LOCAL IP, CLIENT IP → REMOTE IP, DNS IP → RESOLVER, USER → USERNAME
  - PROCESSOR → CPU, CORES → TOPOLOGY, HYPERVISOR → VIRT, CPU FREQ → CLOCK, LOAD → AVG
  - MEMORY → RAM, USAGE → UTILIZATION, VOLUME → DISK, DISK USAGE → CAPACITY, ZFS HEALTH → ZFS STATUS
  - LAST LOGIN → LAST SESSION, UPTIME → RUNNING
- **Title renamed**: "MACHINE REPORT" → "SYSTEM OVERVIEW", compact header "LOFETCH REPORT" → "LOFETCH"
- **Default module order** changed from `os,net,cpu,mem,disk,session` to `os,cpu,mem,disk,net,session`
- **Data format strings changed**:
  - Cores: `"12 vCPU(s) / 1 Socket(s)"` → `"12c / 1s"`
  - Hypervisor: `"Bare Metal"` → `"Physical"`, `"Virtual Machine"` → `"VM"`
  - ZFS: `"HEALTH O.K."` → `"Healthy"`
  - Memory/disk: `"X/Y GiB [Z%]"` → `"X / Y GiB (Z%)"`
- **JSON key renames**: `cpu.cores` → `cpu.topology`, `cpu.hypervisor` → `cpu.virt`, `disk.zfs_health` → `disk.zfs_status`

### Removed
- Deleted legacy `report.sh` and `test_report.sh` files

## 1.1.0 (2026-02-13)

### Changed
- Rebranded from "zfetch" to "lofetch" — renamed binary, all environment variables (`ZFETCH_*` → `LOFETCH_*`), and config path (`~/.config/zfetch/` → `~/.config/lofetch/`)
- New ASCII art LOFETCH logo in report header

### Added
- Comprehensive open-source documentation: rewritten README, CONTRIBUTING.md, and docs/ directory (CONFIGURATION.md, THEMES.md, MODULES.md, PLATFORM-SUPPORT.md, JSON-OUTPUT.md)

### Migration from zfetch
- Rename `~/.config/zfetch/` to `~/.config/lofetch/`
- Update any scripts using `ZFETCH_*` environment variables to `LOFETCH_*`
- Replace `zfetch` with `lofetch` in your PATH

## 1.0.0 (2026-02-12)

### Added
- CRT phosphor green color theme (default)
- 4 built-in themes: `crt`, `neon`, `minimal`, `plain`
- ASCII art LOFETCH logo header
- Gradient progress bars with color-coded thresholds (green/yellow/red)
- CLI argument parsing (`--help`, `--version`, `--theme`, `--modules`, `--json`, `--compact`, `--no-color`)
- JSON output mode (`--json`)
- Module system with selectable sections (`--modules os,cpu,mem`)
- Compact mode (`--compact`) with single-line header
- Config file support (`~/.config/lofetch/config`)
- `NO_COLOR` environment variable support (https://no-color.org/)
- Terminal color capability auto-detection (truecolor/256/16/none)
- `install.sh` installer script
- Makefile with `install`, `uninstall`, `test`, `lint` targets
- GitHub Actions CI for Linux and macOS
- Expanded test suite (110 assertions)

### Changed
- Renamed `report.sh` to `lofetch`
- Widened box from 40 to 52 inner width
- Progress bars widened from 15 to 22 columns
- Label column widened from 11 to 13 characters

### Initial Features (pre-1.0)
- Cross-platform support: Linux, macOS, Windows (WSL, MINGW)
- System info: OS, kernel, network, CPU, memory, disk, session
- ZFS health detection
- Load average bars
- Single self-contained bash script, zero dependencies
