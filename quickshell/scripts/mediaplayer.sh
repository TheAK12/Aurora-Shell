#!/bin/bash
# Outputs MPRIS media player metadata as JSON, updates on change

get_metadata() {
    local status title artist album arturl length position
    status=$(playerctl status 2>/dev/null || echo "Stopped")
    title=$(playerctl metadata title 2>/dev/null || echo "")
    artist=$(playerctl metadata artist 2>/dev/null || echo "")
    album=$(playerctl metadata album 2>/dev/null || echo "")
    arturl=$(playerctl metadata mpris:artUrl 2>/dev/null || echo "")
    length=$(playerctl metadata mpris:length 2>/dev/null || echo "0")
    position=$(playerctl position 2>/dev/null || echo "0")

    # Convert microseconds to seconds
    local length_s=$(awk "BEGIN {printf \"%.0f\", $length / 1000000}" 2>/dev/null || echo "0")
    local position_s=$(awk "BEGIN {printf \"%.0f\", $position}" 2>/dev/null || echo "0")

    cat <<EOF
{"status":"$status","title":"$title","artist":"$artist","album":"$album","artUrl":"$arturl","length":$length_s,"position":$position_s}
EOF
}

if [[ "$1" == "--once" ]]; then
    get_metadata
else
    # Output initial state
    get_metadata
    # Follow playerctl events
    playerctl --follow status 2>/dev/null | while IFS= read -r _; do
        get_metadata
    done
fi
