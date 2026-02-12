#!/usr/bin/env bash
set -euo pipefail
LC_NUMERIC=C
export LC_NUMERIC

# ══════════════════════════════════════════════════════════
# zfetch — cross-platform system info display
# ══════════════════════════════════════════════════════════

# ── Constants ────────────────────────────────────────────

ZFETCH_VERSION="1.0.0"
BOX_INNER_WIDTH=52
LABEL_WIDTH=13
BAR_WIDTH=22
FILL_CHAR="█"
EMPTY_CHAR="░"
SHADE_CHARS=("█" "▓" "▒" "░")
DEFAULT_MODULES="os,net,cpu,mem,disk,session"
COMPACT_MODE=0
JSON_MODE=0

# ── Color Support Detection ─────────────────────────────

detect_color_support() {
    # NO_COLOR standard: https://no-color.org/
    if [[ -n "${NO_COLOR:-}" ]]; then
        COLOR_LEVEL=0; return
    fi
    if [[ "${TERM:-}" == "dumb" ]]; then
        COLOR_LEVEL=0; return
    fi
    if [[ -n "${ZFETCH_NO_COLOR:-}" ]]; then
        COLOR_LEVEL=0; return
    fi
    # Check COLORTERM for truecolor
    if [[ "${COLORTERM:-}" == "truecolor" || "${COLORTERM:-}" == "24bit" ]]; then
        COLOR_LEVEL=3; return
    fi
    # Check tput for color count
    if command -v tput &>/dev/null; then
        local colors
        colors="$(tput colors 2>/dev/null || echo "0")"
        if [[ "$colors" -ge 256 ]] 2>/dev/null; then
            COLOR_LEVEL=2; return
        elif [[ "$colors" -ge 16 ]] 2>/dev/null; then
            COLOR_LEVEL=1; return
        fi
    fi
    # Default: assume 256-color if stdout is a terminal
    if [[ -t 1 ]]; then
        COLOR_LEVEL=2; return
    fi
    COLOR_LEVEL=0
}

# ── Color Variable System ───────────────────────────────

# Theme: CRT (default)
apply_theme_crt() {
    C_RESET=$'\033[0m'
    C_BORDER=$'\033[38;5;22m'
    C_LABEL=$'\033[1;38;5;46m'
    C_VALUE=$'\033[38;5;250m'
    C_HEADER=$'\033[1;38;5;46m'
    C_SUBTITLE=$'\033[38;5;34m'
    C_BAR_LOW=$'\033[38;5;46m'
    C_BAR_MED=$'\033[38;5;226m'
    C_BAR_HI=$'\033[38;5;196m'
    C_BAR_EMPTY=$'\033[38;5;236m'
    C_DIM=$'\033[2m'
    C_LOGO=$'\033[1;38;5;46m'
}

# Theme: Neon
apply_theme_neon() {
    C_RESET=$'\033[0m'
    C_BORDER=$'\033[38;5;93m'
    C_LABEL=$'\033[1;38;5;51m'
    C_VALUE=$'\033[38;5;255m'
    C_HEADER=$'\033[1;38;5;201m'
    C_SUBTITLE=$'\033[38;5;51m'
    C_BAR_LOW=$'\033[38;5;51m'
    C_BAR_MED=$'\033[38;5;201m'
    C_BAR_HI=$'\033[38;5;226m'
    C_BAR_EMPTY=$'\033[38;5;236m'
    C_DIM=$'\033[2m'
    C_LOGO=$'\033[1;38;5;201m'
}

# Theme: Minimal
apply_theme_minimal() {
    C_RESET=$'\033[0m'
    C_BORDER=$'\033[38;5;240m'
    C_LABEL=$'\033[1;38;5;255m'
    C_VALUE=$'\033[38;5;250m'
    C_HEADER=$'\033[1;38;5;255m'
    C_SUBTITLE=$'\033[38;5;245m'
    C_BAR_LOW=$'\033[38;5;255m'
    C_BAR_MED=$'\033[38;5;250m'
    C_BAR_HI=$'\033[38;5;196m'
    C_BAR_EMPTY=$'\033[38;5;236m'
    C_DIM=$'\033[2m'
    C_LOGO=$'\033[1;38;5;255m'
}

# Theme: Plain (no color)
apply_theme_plain() {
    C_RESET="" C_BORDER="" C_LABEL="" C_VALUE=""
    C_HEADER="" C_SUBTITLE="" C_BAR_LOW="" C_BAR_MED=""
    C_BAR_HI="" C_BAR_EMPTY="" C_DIM="" C_LOGO=""
}

clear_all_colors() {
    C_RESET="" C_BORDER="" C_LABEL="" C_VALUE=""
    C_HEADER="" C_SUBTITLE="" C_BAR_LOW="" C_BAR_MED=""
    C_BAR_HI="" C_BAR_EMPTY="" C_DIM="" C_LOGO=""
}

AVAILABLE_THEMES="crt neon minimal plain"
ZFETCH_THEME_NAME="${ZFETCH_THEME:-crt}"

apply_theme() {
    local name="${1:-crt}"
    case "$name" in
        crt)     apply_theme_crt ;;
        neon)    apply_theme_neon ;;
        minimal) apply_theme_minimal ;;
        plain)   apply_theme_plain ;;
        *)       apply_theme_crt ;;
    esac
    ZFETCH_THEME_NAME="$name"
    # If color is disabled, override everything
    if [[ "${COLOR_LEVEL:-0}" -eq 0 ]]; then
        clear_all_colors
    fi
}

# ── Rendering Helpers ────────────────────────────────────

draw_bar() {
    local pct="$1" width="$2"
    # Clamp to 0–100
    if (( pct > 100 )); then pct=100; fi
    if (( pct < 0 )); then pct=0; fi
    local filled
    filled=$(awk "BEGIN { printf \"%d\", ($pct / 100.0) * $width + 0.5 }")
    local empty=$(( width - filled ))

    # Pick bar color by threshold
    local bar_color="$C_BAR_LOW"
    if (( pct >= 85 )); then
        bar_color="$C_BAR_HI"
    elif (( pct >= 60 )); then
        bar_color="$C_BAR_MED"
    fi

    local bar=""
    local i
    # Gradient: filled chars with leading edge shading
    if (( filled > 0 )); then
        bar+="${bar_color}"
        for (( i = 0; i < filled - 1; i++ )); do bar+="█"; done
        # Leading edge gets gradient char
        if (( filled < width )); then
            bar+="▓"
        else
            bar+="█"
        fi
    fi
    # Empty portion
    if (( empty > 0 )); then
        bar+="${C_BAR_EMPTY}"
        for (( i = 0; i < empty; i++ )); do bar+="░"; done
    fi
    bar+="${C_RESET}"
    printf "%s" "$bar"
}

# Non-color draw_bar for width calculations (returns plain chars)
draw_bar_plain() {
    local pct="$1" width="$2"
    if (( pct > 100 )); then pct=100; fi
    if (( pct < 0 )); then pct=0; fi
    local filled
    filled=$(awk "BEGIN { printf \"%d\", ($pct / 100.0) * $width + 0.5 }")
    local empty=$(( width - filled ))
    local bar=""
    local i
    for (( i = 0; i < filled; i++ )); do bar+="█"; done
    for (( i = 0; i < empty; i++ )); do bar+="░"; done
    printf "%s" "$bar"
}

print_row() {
    local label="$1" value="$2"
    local val_width=$(( BOX_INNER_WIDTH - LABEL_WIDTH - 1 ))
    # Truncate value if too long
    value="${value:0:$val_width}"
    printf "${C_BORDER}│${C_RESET} ${C_LABEL}%-${LABEL_WIDTH}s${C_RESET}${C_VALUE}%-${val_width}s${C_RESET}${C_BORDER}│${C_RESET}\n" "$label" "$value"
}

print_bar_row() {
    local label="$1" bar="$2"
    local val_width=$(( BOX_INNER_WIDTH - LABEL_WIDTH - 1 ))
    # Unicode block chars are 3 bytes each but 1 display column.
    # printf pads by byte count, so we must pad manually.
    local pad_len=$(( val_width - BAR_WIDTH ))
    local pad=""
    local i
    for (( i = 0; i < pad_len; i++ )); do pad+=" "; done
    printf "${C_BORDER}│${C_RESET} ${C_LABEL}%-${LABEL_WIDTH}s${C_RESET}%s%s${C_BORDER}│${C_RESET}\n" "$label" "$bar" "$pad"
}

print_centered() {
    local text="$1"
    local color="${2:-$C_HEADER}"
    local text_len=${#text}
    local pad_total=$(( BOX_INNER_WIDTH - text_len ))
    local pad_left=$(( pad_total / 2 ))
    local pad_right=$(( pad_total - pad_left ))
    # Build padding manually (printf %*s uses byte width for Unicode)
    local lpad="" rpad="" i
    for (( i = 0; i < pad_left; i++ )); do lpad+=" "; done
    for (( i = 0; i < pad_right; i++ )); do rpad+=" "; done
    printf "%s│%s%s%s%s%s%s│%s\n" "$C_BORDER" "$C_RESET" "$lpad" "${color}${text}${C_RESET}" "$rpad" "" "$C_BORDER" "$C_RESET"
}

print_empty_row() {
    printf "${C_BORDER}│${C_RESET}%-${BOX_INNER_WIDTH}s${C_BORDER}│${C_RESET}\n" ""
}

print_top_border() {
    local line=""
    local i
    for (( i = 0; i < BOX_INNER_WIDTH; i++ )); do line+="─"; done
    printf "${C_BORDER}┌%s┐${C_RESET}\n" "$line"
}

print_bottom_border() {
    local line=""
    local i
    for (( i = 0; i < BOX_INNER_WIDTH; i++ )); do line+="─"; done
    printf "${C_BORDER}└%s┘${C_RESET}\n" "$line"
}

print_separator() {
    local line=""
    local i
    for (( i = 0; i < BOX_INNER_WIDTH; i++ )); do line+="─"; done
    printf "${C_BORDER}├%s┤${C_RESET}\n" "$line"
}

# ── Platform Detection ───────────────────────────────────

detect_platform() {
    local uname_s
    uname_s="$(uname -s)"
    case "$uname_s" in
        Linux*)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                printf "windows_wsl"
            else
                printf "linux"
            fi
            ;;
        Darwin*)
            printf "macos"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            printf "windows_mingw"
            ;;
        *)
            printf "linux"
            ;;
    esac
}

# ── Data Collection ──────────────────────────────────────

get_os_info() {
    local platform
    platform="$(detect_platform)"

    case "$platform" in
        linux|windows_wsl)
            if [[ -f /etc/os-release ]]; then
                OS_NAME="$(. /etc/os-release && echo "${PRETTY_NAME:-$NAME}")"
            else
                OS_NAME="$(uname -o 2>/dev/null || echo "Linux")"
            fi
            ;;
        macos)
            local name ver
            name="$(sw_vers -productName 2>/dev/null || echo "macOS")"
            ver="$(sw_vers -productVersion 2>/dev/null || echo "")"
            OS_NAME="$name $ver"
            ;;
        windows_mingw)
            OS_NAME="$(cmd.exe /c ver 2>/dev/null | tr -d '\r' | sed '/^$/d' || echo "Windows")"
            ;;
    esac
    OS_NAME="${OS_NAME:-N/A}"
    KERNEL_VERSION="$(uname -sr 2>/dev/null || echo "N/A")"
}

get_network_info() {
    local platform
    platform="$(detect_platform)"

    NET_HOSTNAME="$(hostname -f 2>/dev/null || hostname 2>/dev/null || echo "N/A")"
    NET_USER="$(whoami 2>/dev/null || echo "${USER:-N/A}")"

    case "$platform" in
        linux|windows_wsl)
            NET_MACHINE_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
            ;;
        macos)
            NET_MACHINE_IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "")"
            ;;
        windows_mingw)
            NET_MACHINE_IP="$(ipconfig 2>/dev/null | grep -m1 'IPv4' | awk -F: '{gsub(/ /,"",$2); print $2}' || echo "")"
            ;;
    esac
    NET_MACHINE_IP="${NET_MACHINE_IP:-N/A}"

    # Client IP — only meaningful on SSH sessions
    if [[ -n "${SSH_CLIENT:-}" ]]; then
        NET_CLIENT_IP="$(echo "$SSH_CLIENT" | awk '{print $1}')"
    else
        NET_CLIENT_IP="N/A"
    fi

    # DNS IP
    if [[ -f /etc/resolv.conf ]]; then
        NET_DNS_IP="$(awk '/^nameserver/{print $2; exit}' /etc/resolv.conf 2>/dev/null)"
    elif [[ "$platform" == "macos" ]]; then
        NET_DNS_IP="$(scutil --dns 2>/dev/null | awk '/nameserver\[0\]/{print $3; exit}')"
    fi
    NET_DNS_IP="${NET_DNS_IP:-N/A}"
}

get_cpu_info() {
    local platform
    platform="$(detect_platform)"

    case "$platform" in
        linux|windows_wsl)
            CPU_MODEL="$(awk -F: '/^model name/{gsub(/^[ \t]+/,"",$2); print $2; exit}' /proc/cpuinfo 2>/dev/null)"
            local cores sockets
            cores="$(nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo "1")"
            sockets="$(grep 'physical id' /proc/cpuinfo 2>/dev/null | sort -u | wc -l | tr -d ' ')"
            [[ "$sockets" -lt 1 ]] 2>/dev/null && sockets=1
            CPU_CORES="$cores vCPU(s) / $sockets Socket(s)"
            CPU_NPROC="$cores"

            # Hypervisor
            if command -v systemd-detect-virt &>/dev/null; then
                local virt
                virt="$(systemd-detect-virt 2>/dev/null || echo "none")"
                if [[ "$virt" == "none" ]]; then
                    CPU_HYPERVISOR="Bare Metal"
                else
                    CPU_HYPERVISOR="$virt"
                fi
            elif [[ -f /sys/class/dmi/id/sys_vendor ]]; then
                CPU_HYPERVISOR="$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "N/A")"
            else
                CPU_HYPERVISOR="N/A"
            fi

            # CPU Frequency
            local mhz
            mhz="$(awk -F: '/^cpu MHz/{gsub(/^[ \t]+/,"",$2); print $2; exit}' /proc/cpuinfo 2>/dev/null)"
            if [[ -n "$mhz" ]]; then
                CPU_FREQ="$(awk "BEGIN { printf \"%.2f GHz\", $mhz / 1000 }")"
            else
                CPU_FREQ="N/A"
            fi
            ;;
        macos)
            CPU_MODEL="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "N/A")"
            local cores packages
            cores="$(sysctl -n hw.ncpu 2>/dev/null || echo "1")"
            packages="$(sysctl -n hw.packages 2>/dev/null || echo "1")"
            CPU_CORES="$cores vCPU(s) / $packages Socket(s)"
            CPU_NPROC="$cores"

            local hv
            hv="$(sysctl -n kern.hv_vmm_present 2>/dev/null || echo "0")"
            if [[ "$hv" == "1" ]]; then
                CPU_HYPERVISOR="Virtual Machine"
            else
                CPU_HYPERVISOR="Bare Metal"
            fi

            local freq_hz
            freq_hz="$(sysctl -n hw.cpufrequency 2>/dev/null || echo "")"
            if [[ -n "$freq_hz" && "$freq_hz" != "0" ]]; then
                CPU_FREQ="$(awk "BEGIN { printf \"%.2f GHz\", $freq_hz / 1000000000 }")"
            else
                # Try parsing from brand string (Apple Silicon doesn't expose freq)
                local brand_ghz
                brand_ghz="$(echo "$CPU_MODEL" | grep -oE '[0-9]+\.[0-9]+ ?GHz' || echo "")"
                if [[ -n "$brand_ghz" ]]; then
                    CPU_FREQ="$brand_ghz"
                else
                    CPU_FREQ="N/A"
                fi
            fi
            ;;
        windows_mingw)
            CPU_MODEL="${PROCESSOR_IDENTIFIER:-N/A}"
            CPU_CORES="${NUMBER_OF_PROCESSORS:-1} vCPU(s) / 1 Socket(s)"
            CPU_NPROC="${NUMBER_OF_PROCESSORS:-1}"
            CPU_HYPERVISOR="N/A"
            CPU_FREQ="N/A"
            ;;
    esac

    CPU_MODEL="${CPU_MODEL:-N/A}"
    CPU_CORES="${CPU_CORES:-N/A}"
    CPU_NPROC="${CPU_NPROC:-1}"
    CPU_HYPERVISOR="${CPU_HYPERVISOR:-N/A}"
    CPU_FREQ="${CPU_FREQ:-N/A}"
}

get_load_info() {
    local raw
    raw="$(uptime 2>/dev/null || echo "")"
    if [[ -n "$raw" ]]; then
        # Extract load averages — works on Linux/macOS
        LOAD_1="$(echo "$raw" | awk -F'load average[s]?: ' '{print $2}' | awk -F'[, ]+' '{print $1}')"
        LOAD_5="$(echo "$raw" | awk -F'load average[s]?: ' '{print $2}' | awk -F'[, ]+' '{print $2}')"
        LOAD_15="$(echo "$raw" | awk -F'load average[s]?: ' '{print $2}' | awk -F'[, ]+' '{print $3}')"
    fi
    LOAD_1="${LOAD_1:-N/A}"
    LOAD_5="${LOAD_5:-N/A}"
    LOAD_15="${LOAD_15:-N/A}"
}

get_memory_info() {
    local platform
    platform="$(detect_platform)"

    local mem_total_bytes=0 mem_used_bytes=0

    case "$platform" in
        linux|windows_wsl)
            local mem_info
            mem_info="$(free -b 2>/dev/null || echo "")"
            if [[ -n "$mem_info" ]]; then
                mem_total_bytes="$(echo "$mem_info" | awk '/^Mem:/{print $2}')"
                local mem_available
                mem_available="$(echo "$mem_info" | awk '/^Mem:/{print $7}')"
                if [[ -z "$mem_available" || "$mem_available" == "0" ]]; then
                    # Fallback: used = total - free
                    local mem_free
                    mem_free="$(echo "$mem_info" | awk '/^Mem:/{print $4}')"
                    mem_used_bytes=$(( mem_total_bytes - mem_free ))
                else
                    mem_used_bytes=$(( mem_total_bytes - mem_available ))
                fi
            fi
            ;;
        macos)
            mem_total_bytes="$(sysctl -n hw.memsize 2>/dev/null || echo "0")"
            local page_size active inactive speculative wired
            page_size="$(vm_stat 2>/dev/null | awk '/page size/{print $8}' | tr -d '.')"
            page_size="${page_size:-4096}"
            active="$(vm_stat 2>/dev/null | awk '/Pages active/{print $NF}' | tr -d '.')"
            inactive="$(vm_stat 2>/dev/null | awk '/Pages inactive/{print $NF}' | tr -d '.')"
            speculative="$(vm_stat 2>/dev/null | awk '/Pages speculative/{print $NF}' | tr -d '.')"
            wired="$(vm_stat 2>/dev/null | awk '/Pages wired/{print $NF}' | tr -d '.')"
            active="${active:-0}"; inactive="${inactive:-0}"; speculative="${speculative:-0}"; wired="${wired:-0}"
            mem_used_bytes=$(( (active + wired + speculative) * page_size ))
            ;;
        windows_mingw)
            local total_kb free_kb
            total_kb="$(wmic OS get TotalVisibleMemorySize /value 2>/dev/null | grep '=' | awk -F= '{print $2}' | tr -d '\r')"
            free_kb="$(wmic OS get FreePhysicalMemory /value 2>/dev/null | grep '=' | awk -F= '{print $2}' | tr -d '\r')"
            mem_total_bytes=$(( ${total_kb:-0} * 1024 ))
            mem_used_bytes=$(( (${total_kb:-0} - ${free_kb:-0}) * 1024 ))
            ;;
    esac

    # Convert to GiB (binary)
    if [[ "$mem_total_bytes" -gt 0 ]] 2>/dev/null; then
        MEM_USED_H="$(awk "BEGIN { printf \"%.2f\", $mem_used_bytes / 1073741824 }")"
        MEM_TOTAL_H="$(awk "BEGIN { printf \"%.2f\", $mem_total_bytes / 1073741824 }")"
        MEM_PERCENT="$(awk "BEGIN { printf \"%.2f\", ($mem_used_bytes / $mem_total_bytes) * 100 }")"
        MEM_PERCENT_INT="$(awk "BEGIN { printf \"%d\", ($mem_used_bytes / $mem_total_bytes) * 100 + 0.5 }")"
    else
        MEM_USED_H="N/A"
        MEM_TOTAL_H="N/A"
        MEM_PERCENT="N/A"
        MEM_PERCENT_INT="0"
    fi
}

get_disk_info() {
    local df_out
    df_out="$(df -k / 2>/dev/null | awk 'NR==2')"

    if [[ -n "$df_out" ]]; then
        local total_kb avail_kb used_kb
        total_kb="$(echo "$df_out" | awk '{print $2}')"
        avail_kb="$(echo "$df_out" | awk '{print $4}')"
        # Compute used as total - available instead of df's "Used" column ($3),
        # which on macOS APFS only reports the specific volume snapshot usage.
        used_kb=$(( total_kb - avail_kb ))

        # Convert to GB (decimal, 1000-based, matches preview)
        local total_bytes=$(( total_kb * 1024 ))
        local used_bytes=$(( used_kb * 1024 ))

        DISK_USED_H="$(awk "BEGIN { printf \"%.2f\", $used_bytes / 1000000000 }")"
        DISK_TOTAL_H="$(awk "BEGIN { printf \"%.2f\", $total_bytes / 1000000000 }")"
        DISK_PERCENT="$(awk "BEGIN { printf \"%.2f\", ($used_bytes / $total_bytes) * 100 }")"
        DISK_PERCENT_INT="$(awk "BEGIN { printf \"%d\", ($used_bytes / $total_bytes) * 100 + 0.5 }")"
    else
        DISK_USED_H="N/A"
        DISK_TOTAL_H="N/A"
        DISK_PERCENT="N/A"
        DISK_PERCENT_INT="0"
    fi

    # ZFS health
    if command -v zpool &>/dev/null; then
        local zfs_status
        zfs_status="$(zpool status -x 2>/dev/null || echo "")"
        if [[ "$zfs_status" == *"all pools are healthy"* ]]; then
            ZFS_HEALTH="HEALTH O.K."
        elif [[ -n "$zfs_status" ]]; then
            ZFS_HEALTH="DEGRADED"
        else
            ZFS_HEALTH="N/A"
        fi
    else
        ZFS_HEALTH="N/A"
    fi
}

get_session_info() {
    local platform
    platform="$(detect_platform)"

    # Last login
    if command -v last &>/dev/null; then
        local last_line
        last_line="$(last -1 2>/dev/null | head -1 || echo "")"
        if [[ -n "$last_line" && "$last_line" != *"wtmp begins"* ]]; then
            # Extract timestamp — platform dependent format
            case "$platform" in
                macos)
                    LAST_LOGIN="$(echo "$last_line" | awk '{for(i=3;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/ *$//')"
                    ;;
                *)
                    LAST_LOGIN="$(echo "$last_line" | awk '{for(i=4;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/ *$//')"
                    ;;
            esac
            # Extract IP if present in last login
            LAST_LOGIN_IP="$(echo "$last_line" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")"
        fi
    fi
    LAST_LOGIN="${LAST_LOGIN:-N/A}"
    LAST_LOGIN_IP="${LAST_LOGIN_IP:-}"

    # Uptime
    get_uptime_info
}

get_uptime_info() {
    local raw
    raw="$(uptime 2>/dev/null || echo "")"
    if [[ -n "$raw" ]]; then
        # Try to extract the "up X days, Yh, Zm" portion
        # Different formats:
        #   Linux:  up 19 days, 8:20,  ...
        #   macOS:  up 5 days, 3:42,  ...
        #   macOS:  up 3:42, ...
        local up_part
        up_part="$(echo "$raw" | sed 's/.*up //' | sed 's/,*[[:space:]]*[0-9]* user.*//')"
        # Normalize to "Xd, Yh, Zm" format
        if echo "$up_part" | grep -qE '[0-9]+ day'; then
            local days hours mins
            days="$(echo "$up_part" | grep -oE '[0-9]+ day' | awk '{print $1}')"
            local time_part
            time_part="$(echo "$up_part" | sed 's/.*day[s]*, *//')"
            if echo "$time_part" | grep -q ':'; then
                hours="$(echo "$time_part" | awk -F: '{print $1}' | tr -d ' ')"
                mins="$(echo "$time_part" | awk -F: '{print $2}' | tr -d ' ,')"
            else
                hours="0"
                mins="$(echo "$time_part" | grep -oE '[0-9]+' | head -1)"
                mins="${mins:-0}"
            fi
            UPTIME_STR="${days}d, ${hours}h, ${mins}m"
        elif echo "$up_part" | grep -q ':'; then
            local hours mins
            hours="$(echo "$up_part" | awk -F: '{print $1}' | tr -d ' ')"
            mins="$(echo "$up_part" | awk -F: '{print $2}' | tr -d ' ,')"
            UPTIME_STR="0d, ${hours}h, ${mins}m"
        else
            UPTIME_STR="$up_part"
        fi
    fi
    UPTIME_STR="${UPTIME_STR:-N/A}"
}

# ── ASCII Art Header ─────────────────────────────────────

print_ascii_logo() {
    local logo_lines=(
        "▐███▀▀▀ ▐███▀▀▀ ▐███▀▀▀ ███████ ▐███▀▀▀ ██▌  ██▌"
        "  ▄██▀  ▐██▄▄   ▐██▄▄     ██▌   ▐██▌    ████████▌"
        "▄██▀    ▐██▀▀   ▐██▀▀     ██▌   ▐██▌    ██▌▀▀██▌ "
        "███████ ▐██▌    ▐███▄▄▄   ██▌   ▐███▄▄▄ ██▌  ██▌ "
    )
    local line
    for line in "${logo_lines[@]}"; do
        local text_len=${#line}
        local pad_total=$(( BOX_INNER_WIDTH - text_len ))
        local pad_left=$(( pad_total / 2 ))
        local pad_right=$(( pad_total - pad_left ))
        # Build padding manually (printf %*s uses byte width, not display width)
        local lpad="" rpad="" i
        for (( i = 0; i < pad_left; i++ )); do lpad+=" "; done
        for (( i = 0; i < pad_right; i++ )); do rpad+=" "; done
        printf "%s│%s%s%s%s%s│%s\n" "$C_BORDER" "$C_RESET" "$lpad${C_LOGO}${line}${C_RESET}" "" "$rpad" "$C_BORDER" "$C_RESET"
    done
}

print_header() {
    if [[ "$COMPACT_MODE" -eq 1 ]]; then
        print_centered "ZFETCH REPORT" "$C_HEADER"
    else
        print_empty_row
        print_ascii_logo
        print_empty_row
        print_centered "MACHINE REPORT" "$C_SUBTITLE"
        local platform
        platform="$(detect_platform)"
        local ts
        ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date '+%Y-%m-%d %H:%M' 2>/dev/null || echo '')"
        local info_line="v${ZFETCH_VERSION}"
        if [[ -n "$ts" ]]; then info_line+=" · $ts"; fi
        info_line+=" · $platform"
        print_centered "$info_line" "$C_DIM"
    fi
}

# ── Config File Support ──────────────────────────────────

load_config() {
    local config_file=""
    if [[ -n "${ZFETCH_CONFIG:-}" && -f "${ZFETCH_CONFIG}" ]]; then
        config_file="$ZFETCH_CONFIG"
    elif [[ -f "${HOME}/.config/zfetch/config" ]]; then
        config_file="${HOME}/.config/zfetch/config"
    fi
    [[ -z "$config_file" ]] && return 0

    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        key="$(echo "$key" | tr -d '[:space:]')"
        value="$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        case "$key" in
            theme)   [[ -z "${_CLI_THEME:-}" ]] && ZFETCH_THEME_NAME="$value" ;;
            modules) [[ -z "${_CLI_MODULES:-}" ]] && ENABLED_MODULES="$value" ;;
        esac
    done < "$config_file" || true
}

# ── CLI Argument Parsing ─────────────────────────────────

ENABLED_MODULES="$DEFAULT_MODULES"

show_help() {
    cat <<'HELPEOF'
Usage: zfetch [OPTIONS]

A retro CRT-style system information display.

Options:
  -h, --help          Show this help message
  -v, --version       Show version
  -t, --theme NAME    Set color theme (crt, neon, minimal, plain)
  -m, --modules LIST  Comma-separated modules (os,net,cpu,mem,disk,session)
  -j, --json          Output as JSON
  -c, --compact       Compact output (no ASCII art)
      --no-color      Disable colors
      --list-themes   List available themes
      --list-modules  List available modules
HELPEOF
}

show_version() {
    printf "zfetch %s\n" "$ZFETCH_VERSION"
}

list_themes() {
    detect_color_support
    printf "Available themes:\n"
    printf "  \033[1;38;5;46m██\033[0m crt      Phosphor green CRT terminal\n"
    printf "  \033[1;38;5;201m██\033[0m neon     Cyberpunk neon synthwave\n"
    printf "  \033[1;38;5;255m██\033[0m minimal  Clean understated monochrome\n"
    printf "     plain    No colors (for piping)\n"
}

list_modules() {
    printf "Available modules:\n"
    printf "  os       Operating system and kernel\n"
    printf "  net      Network info (hostname, IPs)\n"
    printf "  cpu      Processor, cores, load averages\n"
    printf "  mem      Memory usage\n"
    printf "  disk     Disk usage and ZFS health\n"
    printf "  session  Last login and uptime\n"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help; exit 0 ;;
            -v|--version)
                show_version; exit 0 ;;
            -t|--theme)
                shift; ZFETCH_THEME_NAME="${1:-crt}"; _CLI_THEME=1 ;;
            -m|--modules)
                shift; ENABLED_MODULES="${1:-$DEFAULT_MODULES}"; _CLI_MODULES=1 ;;
            -j|--json)
                JSON_MODE=1 ;;
            -c|--compact)
                COMPACT_MODE=1 ;;
            --no-color)
                ZFETCH_NO_COLOR=1 ;;
            --list-themes)
                list_themes; exit 0 ;;
            --list-modules)
                list_modules; exit 0 ;;
            *)
                printf "zfetch: unknown option '%s'\n" "$1" >&2
                printf "Try 'zfetch --help' for more information.\n" >&2
                exit 1 ;;
        esac
        shift
    done
}

# ── Module Rendering ─────────────────────────────────────

render_os_section() {
    print_row "OS" "$OS_NAME"
    print_row "KERNEL" "$KERNEL_VERSION"
}

render_net_section() {
    print_row "HOSTNAME" "$NET_HOSTNAME"
    print_row "MACHINE IP" "$NET_MACHINE_IP"
    print_row "CLIENT IP" "$NET_CLIENT_IP"
    print_row "DNS IP" "$NET_DNS_IP"
    print_row "USER" "$NET_USER"
}

render_cpu_section() {
    local nproc="${CPU_NPROC:-1}"
    local load1_pct=0 load5_pct=0 load15_pct=0
    if [[ "$LOAD_1" != "N/A" ]]; then
        load1_pct="$(awk "BEGIN { v=($LOAD_1 / $nproc) * 100; if(v>100) v=100; printf \"%d\", v + 0.5 }")"
        load5_pct="$(awk "BEGIN { v=($LOAD_5 / $nproc) * 100; if(v>100) v=100; printf \"%d\", v + 0.5 }")"
        load15_pct="$(awk "BEGIN { v=($LOAD_15 / $nproc) * 100; if(v>100) v=100; printf \"%d\", v + 0.5 }")"
    fi

    print_row "PROCESSOR" "$CPU_MODEL"
    print_row "CORES" "$CPU_CORES"
    print_row "HYPERVISOR" "$CPU_HYPERVISOR"
    print_row "CPU FREQ" "$CPU_FREQ"
    if [[ "$LOAD_1" != "N/A" ]]; then
        print_bar_row "LOAD 1m" "$(draw_bar "$load1_pct" "$BAR_WIDTH")"
        print_bar_row "LOAD 5m" "$(draw_bar "$load5_pct" "$BAR_WIDTH")"
        print_bar_row "LOAD 15m" "$(draw_bar "$load15_pct" "$BAR_WIDTH")"
    else
        print_row "LOAD" "N/A"
    fi
}

render_mem_section() {
    if [[ "$MEM_PERCENT" != "N/A" ]]; then
        print_row "MEMORY" "${MEM_USED_H}/${MEM_TOTAL_H} GiB [${MEM_PERCENT}%]"
        print_bar_row "USAGE" "$(draw_bar "$MEM_PERCENT_INT" "$BAR_WIDTH")"
    else
        print_row "MEMORY" "N/A"
    fi
}

render_disk_section() {
    if [[ "$DISK_PERCENT" != "N/A" ]]; then
        print_row "VOLUME" "${DISK_USED_H}/${DISK_TOTAL_H} GB [${DISK_PERCENT}%]"
        print_bar_row "DISK USAGE" "$(draw_bar "$DISK_PERCENT_INT" "$BAR_WIDTH")"
    else
        print_row "VOLUME" "N/A"
    fi
    print_row "ZFS HEALTH" "$ZFS_HEALTH"
}

render_session_section() {
    print_row "LAST LOGIN" "$LAST_LOGIN"
    if [[ -n "$LAST_LOGIN_IP" ]]; then
        print_row "" "$LAST_LOGIN_IP"
    fi
    print_row "UPTIME" "$UPTIME_STR"
}

# ── JSON Output ──────────────────────────────────────────

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

render_json() {
    get_os_info
    get_network_info
    get_cpu_info
    get_load_info
    get_memory_info
    get_disk_info
    get_session_info

    local platform
    platform="$(detect_platform)"
    local ts
    ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo '')"

    printf '{\n'
    printf '  "version": "%s",\n' "$ZFETCH_VERSION"
    printf '  "platform": "%s",\n' "$(json_escape "$platform")"
    printf '  "timestamp": "%s",\n' "$(json_escape "$ts")"
    printf '  "os": {\n'
    printf '    "name": "%s",\n' "$(json_escape "$OS_NAME")"
    printf '    "kernel": "%s"\n' "$(json_escape "$KERNEL_VERSION")"
    printf '  },\n'
    printf '  "network": {\n'
    printf '    "hostname": "%s",\n' "$(json_escape "$NET_HOSTNAME")"
    printf '    "machine_ip": "%s",\n' "$(json_escape "$NET_MACHINE_IP")"
    printf '    "client_ip": "%s",\n' "$(json_escape "$NET_CLIENT_IP")"
    printf '    "dns_ip": "%s",\n' "$(json_escape "$NET_DNS_IP")"
    printf '    "user": "%s"\n' "$(json_escape "$NET_USER")"
    printf '  },\n'
    printf '  "cpu": {\n'
    printf '    "model": "%s",\n' "$(json_escape "$CPU_MODEL")"
    printf '    "cores": "%s",\n' "$(json_escape "$CPU_CORES")"
    printf '    "freq": "%s",\n' "$(json_escape "$CPU_FREQ")"
    printf '    "hypervisor": "%s",\n' "$(json_escape "$CPU_HYPERVISOR")"
    printf '    "load_1": "%s",\n' "$(json_escape "$LOAD_1")"
    printf '    "load_5": "%s",\n' "$(json_escape "$LOAD_5")"
    printf '    "load_15": "%s"\n' "$(json_escape "$LOAD_15")"
    printf '  },\n'
    printf '  "memory": {\n'
    printf '    "used_gib": %s,\n' "${MEM_USED_H:-0}"
    printf '    "total_gib": %s,\n' "${MEM_TOTAL_H:-0}"
    printf '    "percent": %s\n' "${MEM_PERCENT:-0}"
    printf '  },\n'
    printf '  "disk": {\n'
    printf '    "used_gb": %s,\n' "${DISK_USED_H:-0}"
    printf '    "total_gb": %s,\n' "${DISK_TOTAL_H:-0}"
    printf '    "percent": %s,\n' "${DISK_PERCENT:-0}"
    printf '    "zfs_health": "%s"\n' "$(json_escape "$ZFS_HEALTH")"
    printf '  },\n'
    printf '  "session": {\n'
    printf '    "last_login": "%s",\n' "$(json_escape "$LAST_LOGIN")"
    printf '    "uptime": "%s"\n' "$(json_escape "$UPTIME_STR")"
    printf '  }\n'
    printf '}\n'
}

# ── Render Report ────────────────────────────────────────

render_report() {
    # Collect all data
    get_os_info
    get_network_info
    get_cpu_info
    get_load_info
    get_memory_info
    get_disk_info
    get_session_info

    # Parse modules
    local IFS=','
    local modules_arr=($ENABLED_MODULES)
    unset IFS

    # Build output
    print_top_border
    print_header

    local first=1
    local mod
    for mod in "${modules_arr[@]}"; do
        print_separator
        case "$mod" in
            os)      render_os_section ;;
            net)     render_net_section ;;
            cpu)     render_cpu_section ;;
            mem)     render_mem_section ;;
            disk)    render_disk_section ;;
            session) render_session_section ;;
        esac
    done

    print_bottom_border
}

# ── Entry Point ──────────────────────────────────────────

if [[ -z "${ZFETCH_SOURCED:-}" ]]; then
    parse_args "$@"
    load_config
    detect_color_support
    apply_theme "$ZFETCH_THEME_NAME"

    if [[ "$JSON_MODE" -eq 1 ]]; then
        render_json
    else
        render_report
    fi
fi
