#!/usr/bin/env bash
# Lists wallpaper images from ~/Pictures/wallpapers and ~/Pictures as a ONE-LINE JSON array.
# Each SplitParser.onRead call will receive the complete JSON.

DIRS=("$HOME/Pictures/wallpapers" "$HOME/Pictures")

out="["
first=1

for dir in "${DIRS[@]}"; do
    [ -d "$dir" ] || continue
    while IFS= read -r -d '' f; do
        ext="${f##*.}"; ext="${ext,,}"
        case "$ext" in jpg|jpeg|png|webp|gif) ;;
            *) continue ;;
        esac
        name=$(basename "$f")
        safe_name="${name//\"/\\\"}"
        safe_path="${f//\"/\\\"}"
        [ $first -eq 0 ] && out="${out},"
        out="${out}{\"name\":\"${safe_name}\",\"path\":\"${safe_path}\"}"
        first=0
    done < <(find "$dir" -maxdepth 1 -type f -print0 2>/dev/null | sort -z)
done

out="${out}]"
printf '%s\n' "$out"
