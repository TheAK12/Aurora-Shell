#!/bin/bash
# Lists desktop applications as JSON array
# Format: [{"name": "...", "exec": "...", "icon": "...", "comment": "..."}, ...]

apps="["
first=true

for desktop_file in /usr/share/applications/*.desktop ~/.local/share/applications/*.desktop; do
    [[ -f "$desktop_file" ]] || continue

    # Skip NoDisplay=true entries
    nodisplay=$(grep -m 1 "^NoDisplay=" "$desktop_file" 2>/dev/null | cut -d= -f2)
    [[ "$nodisplay" == "true" ]] && continue

    # Skip Hidden=true entries
    hidden=$(grep -m 1 "^Hidden=" "$desktop_file" 2>/dev/null | cut -d= -f2)
    [[ "$hidden" == "true" ]] && continue

    name=$(grep -m 1 "^Name=" "$desktop_file" 2>/dev/null | cut -d= -f2)
    exec_cmd=$(grep -m 1 "^Exec=" "$desktop_file" 2>/dev/null | cut -d= -f2 | sed 's/ %[fFuUdDnNickvm]//g')
    icon=$(grep -m 1 "^Icon=" "$desktop_file" 2>/dev/null | cut -d= -f2)
    comment=$(grep -m 1 "^Comment=" "$desktop_file" 2>/dev/null | cut -d= -f2)

    [[ -z "$name" ]] && continue

    # Escape JSON strings
    name=$(echo "$name" | sed 's/"/\\"/g')
    exec_cmd=$(echo "$exec_cmd" | sed 's/"/\\"/g')
    icon=$(echo "$icon" | sed 's/"/\\"/g')
    comment=$(echo "$comment" | sed 's/"/\\"/g')

    if $first; then
        first=false
    else
        apps+=","
    fi

    apps+="{\"name\":\"$name\",\"exec\":\"$exec_cmd\",\"icon\":\"$icon\",\"comment\":\"$comment\"}"
done

apps+="]"
echo "$apps"
