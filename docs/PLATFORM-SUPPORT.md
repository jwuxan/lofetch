# Platform Support

## Supported Platforms

| Platform | Status |
|----------|--------|
| Linux (x86_64, ARM) | Fully supported |
| macOS (Intel, Apple Silicon) | Fully supported |
| Windows (WSL) | Fully supported |
| Windows (MINGW/MSYS/Cygwin) | Supported (some limitations) |

## Platform Detection

lofetch detects the platform via `uname -s` and checks for WSL via `/proc/version`:

- `Linux` + `/proc/version` contains "microsoft" → `windows_wsl`
- `Linux` → `linux`
- `Darwin` → `macos`
- `MINGW*|MSYS*|CYGWIN*` → `windows_mingw`

## Data Sources by Platform

| Data | Linux/WSL | macOS | MINGW |
|------|-----------|-------|-------|
| OS name | `/etc/os-release` | `sw_vers` | `cmd /c ver` |
| IP address | `hostname -I` | `ipconfig getifaddr en0` | `ipconfig` parse |
| CPU model | `/proc/cpuinfo` | `sysctl machdep.cpu.brand_string` | `PROCESSOR_IDENTIFIER` env |
| CPU cores | `nproc` / `/proc/cpuinfo` | `sysctl hw.ncpu` | `NUMBER_OF_PROCESSORS` env |
| CPU freq | `/proc/cpuinfo` MHz field | `sysctl hw.cpufrequency` or brand string | N/A |
| Hypervisor | `systemd-detect-virt` | `sysctl kern.hv_vmm_present` | N/A |
| Memory | `free -b` | `sysctl hw.memsize` + `vm_stat` | `wmic OS` |
| Disk | `df -k /` | `df -k /` | `df -k /` |
| Load avg | `uptime` | `uptime` | `uptime` |
| Last login | `last -1` | `last -1` | `last -1` |

## Known Quirks

- **macOS APFS**: `df` "Used" column reports volume snapshot usage, not actual used space. lofetch computes used = total - available instead.
- **Apple Silicon**: CPU frequency is not exposed via sysctl. lofetch falls back to parsing the brand string, or shows N/A.
- **MINGW**: Some features (hypervisor detection, CPU frequency) are unavailable.
- **WSL**: Reports as `windows_wsl` platform, uses Linux commands for data collection.

## CI Matrix

| Runner | Platform |
|--------|----------|
| `ubuntu-latest` | Linux |
| `macos-latest` | macOS |
