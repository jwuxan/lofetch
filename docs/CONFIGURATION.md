# Configuration

## Config File

- **Location**: `~/.config/lofetch/config`
- **Override**: Set `LOFETCH_CONFIG` env var to use a custom path
- **Format**: `key=value`, one per line. Lines starting with `#` are comments.

## Supported Keys

| Key | Values | Default |
|-----|--------|---------|
| `theme` | `crt`, `neon`, `minimal`, `plain` | `crt` |
| `modules` | Comma-separated: `os,net,cpu,mem,disk,session` | all six |

## Environment Variables

| Variable | Description |
|----------|-------------|
| `LOFETCH_THEME` | Set default theme |
| `LOFETCH_CONFIG` | Custom config file path |
| `LOFETCH_NO_COLOR` | Disable colors (any non-empty value) |
| `NO_COLOR` | Standard no-color ([no-color.org](https://no-color.org/)) |

## Priority Chain

CLI flags > environment variables > config file > built-in defaults

The `--theme` and `--modules` CLI flags always win. If not set, `LOFETCH_THEME` env is checked. If not set, the config file is read. If nothing is configured, defaults apply.

## Example Config

```
# ~/.config/lofetch/config
theme=neon
modules=os,cpu,mem,disk
```
