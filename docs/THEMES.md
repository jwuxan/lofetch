# Themes

## Built-in Themes

| Theme | Description |
|-------|-------------|
| `crt` | Phosphor green CRT terminal (default) |
| `neon` | Cyberpunk neon synthwave |
| `minimal` | Clean understated monochrome |
| `plain` | No colors (for piping/logging) |

## Usage

```bash
lofetch --theme neon
LOFETCH_THEME=minimal lofetch
```

## Color Variables

Each theme sets 12 `C_*` variables:

| Variable | Controls |
|----------|----------|
| `C_RESET` | ANSI reset sequence |
| `C_BORDER` | Box border characters |
| `C_LABEL` | Row labels (OS, KERNEL, etc.) |
| `C_VALUE` | Row values |
| `C_HEADER` | Header text color |
| `C_SUBTITLE` | Subtitle text color |
| `C_BAR_LOW` | Progress bar (0-59%) |
| `C_BAR_MED` | Progress bar (60-84%) |
| `C_BAR_HI` | Progress bar (85-100%) |
| `C_BAR_EMPTY` | Empty portion of bar |
| `C_DIM` | Dimmed/muted text |
| `C_LOGO` | ASCII art logo |

## Creating a Custom Theme

1. Add function `apply_theme_<name>()` in `lofetch`
2. Set all 12 variables using `$'\033[...]'` ANSI-C quoting
3. Register in `apply_theme()`'s case statement
4. Add to `list_themes()` output

### Why ANSI-C Quoting?

Color variables MUST use `$'\033[...]'` syntax, not `"\033[...]"`. The `$'...'` form stores actual ESC bytes in the variable. The `draw_bar` function builds color codes into strings and outputs them via `printf "%s"`, which does NOT interpret `\033` escape sequences — it only passes through literal bytes.

### No-Color Behavior

When `COLOR_LEVEL=0` (set by `NO_COLOR`, `LOFETCH_NO_COLOR`, `TERM=dumb`, or non-terminal output), `apply_theme()` clears all `C_*` variables to empty strings, regardless of theme.
