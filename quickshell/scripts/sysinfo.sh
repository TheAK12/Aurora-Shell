#!/bin/bash
# Outputs system info as JSON, one line every 2 seconds (or once if --once flag)

get_cpu() {
    # Read CPU usage from /proc/stat
    local cpu_line
    cpu_line=$(head -1 /proc/stat)
    local user nice system idle iowait irq softirq
    read -r _ user nice system idle iowait irq softirq _ <<< "$cpu_line"
    local total=$((user + nice + system + idle + iowait + irq + softirq))
    local idle_val=$idle
    echo "$total $idle_val"
}

get_sysinfo() {
    # CPU
    local cpu_pct=0
    if [[ -f /tmp/.qs_cpu_prev ]]; then
        read -r prev_total prev_idle < /tmp/.qs_cpu_prev
        read -r curr_total curr_idle <<< "$(get_cpu)"
        local diff_total=$((curr_total - prev_total))
        local diff_idle=$((curr_idle - prev_idle))
        if [[ $diff_total -gt 0 ]]; then
            cpu_pct=$(( (diff_total - diff_idle) * 100 / diff_total ))
        fi
        echo "$curr_total $curr_idle" > /tmp/.qs_cpu_prev
    else
        get_cpu > /tmp/.qs_cpu_prev
        cpu_pct=0
    fi

    # RAM
    local mem_total mem_avail mem_pct
    mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    mem_avail=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    mem_pct=$(( (mem_total - mem_avail) * 100 / mem_total ))
    local mem_used_gb=$(awk "BEGIN {printf \"%.1f\", ($mem_total - $mem_avail) / 1048576}")
    local mem_total_gb=$(awk "BEGIN {printf \"%.1f\", $mem_total / 1048576}")

    # Battery
    local bat_pct=100
    local bat_status="Full"
    if [[ -d /sys/class/power_supply/BAT0 ]]; then
        bat_pct=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 100)
        bat_status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "Unknown")
    elif [[ -d /sys/class/power_supply/BAT1 ]]; then
        bat_pct=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo 100)
        bat_status=$(cat /sys/class/power_supply/BAT1/status 2>/dev/null || echo "Unknown")
    fi

    # Volume
    local vol vol_mute
    vol=$(pamixer --get-volume 2>/dev/null || echo 50)
    vol_mute=$(pamixer --get-mute 2>/dev/null || echo false)

    # Brightness
    local brightness=100
    if command -v brightnessctl &>/dev/null; then
        local cur_br max_br
        cur_br=$(brightnessctl get 2>/dev/null || echo 100)
        max_br=$(brightnessctl max 2>/dev/null || echo 100)
        if [[ $max_br -gt 0 ]]; then
            brightness=$((cur_br * 100 / max_br))
        fi
    fi

    # Network
    local net_name="Disconnected"
    local net_type="none"
    if command -v nmcli &>/dev/null; then
        local wifi_name
        wifi_name=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)
        if [[ -n "$wifi_name" ]]; then
            net_name="$wifi_name"
            net_type="wifi"
        elif nmcli -t -f TYPE,STATE con show --active 2>/dev/null | grep -q "ethernet:activated"; then
            net_name="Ethernet"
            net_type="ethernet"
        fi
    fi

    cat <<EOF
{"cpu":$cpu_pct,"ram_pct":$mem_pct,"ram_used":"$mem_used_gb","ram_total":"$mem_total_gb","battery":$bat_pct,"bat_status":"$bat_status","volume":$vol,"vol_mute":$vol_mute,"brightness":$brightness,"net_name":"$net_name","net_type":"$net_type"}
EOF
}

if [[ "$1" == "--once" ]]; then
    get_sysinfo
else
    while true; do
        get_sysinfo
        sleep 2
    done
fi
