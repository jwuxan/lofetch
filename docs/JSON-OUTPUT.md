# JSON Output

## Usage

```bash
lofetch --json
lofetch --json | jq .
lofetch --json | jq '.memory.percent'
```

## Schema

```json
{
  "version": "2.0.0",
  "platform": "macos",
  "timestamp": "2026-02-13T12:00:00Z",
  "os": {
    "name": "macOS 15.3",
    "kernel": "Darwin 24.3.0"
  },
  "network": {
    "hostname": "workstation.local",
    "machine_ip": "192.168.1.42",
    "client_ip": "N/A",
    "dns_ip": "192.168.1.1",
    "user": "jwu"
  },
  "cpu": {
    "model": "Apple M2 Pro",
    "topology": "12c / 1s",
    "freq": "N/A",
    "virt": "Physical",
    "load_1": "2.45",
    "load_5": "3.12",
    "load_15": "2.89"
  },
  "memory": {
    "used_gib": 12.45,
    "total_gib": 32.00,
    "percent": 38.91
  },
  "disk": {
    "used_gb": 234.56,
    "total_gb": 994.66,
    "percent": 23.58,
    "zfs_status": "N/A"
  },
  "session": {
    "last_login": "console Thu Feb 13 08:30",
    "uptime": "5d, 3h, 42m"
  }
}
```

## Field Reference

| Field | Type | Description |
|-------|------|-------------|
| `version` | string | lofetch version |
| `platform` | string | Detected platform (`linux`, `macos`, `windows_wsl`, `windows_mingw`) |
| `timestamp` | string | ISO 8601 UTC timestamp |
| `os.name` | string | OS name and version |
| `os.kernel` | string | Kernel name and version |
| `network.hostname` | string | Fully qualified hostname |
| `network.machine_ip` | string | Primary IP address |
| `network.client_ip` | string | SSH client IP or "N/A" |
| `network.dns_ip` | string | Primary DNS server |
| `network.user` | string | Current user |
| `cpu.model` | string | CPU model name |
| `cpu.topology` | string | Core count and socket count |
| `cpu.freq` | string | CPU frequency or "N/A" |
| `cpu.virt` | string | Virtualization type, "Physical", or "N/A" |
| `cpu.load_1` | string | 1-minute load average |
| `cpu.load_5` | string | 5-minute load average |
| `cpu.load_15` | string | 15-minute load average |
| `memory.used_gib` | number | Used memory in GiB |
| `memory.total_gib` | number | Total memory in GiB |
| `memory.percent` | number | Memory usage percentage |
| `disk.used_gb` | number | Used disk in GB (decimal) |
| `disk.total_gb` | number | Total disk in GB (decimal) |
| `disk.percent` | number | Disk usage percentage |
| `disk.zfs_status` | string | "Healthy", "DEGRADED", or "N/A" |
| `session.last_login` | string | Last login info |
| `session.uptime` | string | System uptime |

## Examples

```bash
# Get memory percentage
lofetch --json | jq '.memory.percent'

# Get OS name
lofetch --json | jq -r '.os.name'

# Check if disk usage is high
lofetch --json | jq '.disk.percent > 80'

# Pretty-print all network info
lofetch --json | jq '.network'
```
