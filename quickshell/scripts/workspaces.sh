#!/bin/bash
# Outputs niri workspace info as a JSON line on each change
# Format: {"workspaces": [{"id": N, "name": "...", "is_active": bool, "is_focused": bool, "output": "..."}]}

get_workspaces() {
    niri msg -j workspaces 2>/dev/null || echo '[]'
}

# Initial output
echo "{\"workspaces\": $(get_workspaces)}"

# Listen for workspace changes via niri event stream
niri msg event-stream 2>/dev/null | while IFS= read -r event; do
    case "$event" in
        *"WorkspacesChanged"*|*"WorkspaceActivated"*|*"WorkspaceFocused"*)
            echo "{\"workspaces\": $(get_workspaces)}"
            ;;
    esac
done
