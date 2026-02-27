#!/bin/bash
# QuickShell Dotfiles Interactive Installer

# --- Aesthetics (Colors & Formatting) ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

print_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
  ____        _      _    ____  _          _ _ 
 / __ \      (_)    | |  / ___|| |__   ___| | |
| |  | |_   _ _  ___| | _\___ \| '_ \ / _ \ | |
| |__| | | | | |/ __| |/ /___) | | | |  __/ | |
 \___\_\\__,_|_|\___|_|\_\____/|_| |_|\___|_|_|
                                               
EOF
    echo -e "${NC}${MAGENTA}${BOLD}      Dotfiles Interactive Installer${NC}"
    echo -e "${CYAN}==============================================${NC}\n"
}

step() { echo -e "${BLUE}${BOLD}[*]${NC} $1"; }
success() { echo -e "${GREEN}${BOLD}[✔]${NC} $1"; }
warning() { echo -e "${YELLOW}${BOLD}[!]${NC} $1"; }
error() { echo -e "${RED}${BOLD}[x]${NC} $1"; exit 1; }
prompt() { echo -en "${CYAN}${BOLD}[?]${NC} $1 [Y/n] "; }

# --- Initialization ---
print_header

# --- Requirements Check ---
step "Checking dependencies..."
DEPS=("playerctl" "pamixer" "brightnessctl" "nmcli" "qt6ct" "awk" "grep")
MISSING_DEPS=()

for dep in "${DEPS[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
        MISSING_DEPS+=("$dep")
    fi
done

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    warning "The following dependencies are missing:"
    for dep in "${MISSING_DEPS[@]}"; do
        echo -e "  - ${YELLOW}$dep${NC}"
    done
    echo ""
    prompt "Do you want to continue anyway? (Some features may not work)"
    read -r response
    if [[ "$response" =~ ^([nN][oO]|[nN])$ ]]; then
        error "Installation aborted. Please install dependencies and try again."
    fi
else
    success "All CLI dependencies found!"
fi

# --- QuickShell Check ---
if ! command -v quickshell &> /dev/null; then
    warning "QuickShell executable not found in PATH."
    echo -e "You need to compile and install QuickShell manually."
    echo -e "Visit: ${CYAN}https://git.outfoxxed.me/outfoxxed/quickshell${NC}"
fi

echo ""

# --- Backup Existing Config ---
CONFIG_DIR="$HOME/.config/quickshell"
SCRIPT_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

if [ -d "$CONFIG_DIR" ]; then
    # Check if we are running the script from inside the target directory
    if [ "$SCRIPT_DIR" == "$(realpath "$CONFIG_DIR")" ]; then
        success "You are running this script directly from $CONFIG_DIR."
        echo -e "Nothing to copy, but dependencies are checked!"
        INSTALL_COPY=false
    else
        warning "An existing QuickShell configuration was found at $CONFIG_DIR"
        prompt "Do you want to back it up and install the new one?"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY]|"")$ ]]; then
            BACKUP_DIR="${CONFIG_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
            mv "$CONFIG_DIR" "$BACKUP_DIR"
            success "Backed up existing config to $BACKUP_DIR"
            INSTALL_COPY=true
        else
            error "Installation aborted by user."
        fi
    fi
else
    INSTALL_COPY=true
fi

# --- Install Files ---
if [ "$INSTALL_COPY" = true ]; then
    step "Installing dotfiles to $CONFIG_DIR..."
    mkdir -p "$CONFIG_DIR"
    cp -r "$SCRIPT_DIR/"* "$CONFIG_DIR/"
    success "Dotfiles installed successfully!"
fi

# --- Make Scripts Executable ---
step "Setting execute permissions on scripts..."
if [ -d "$CONFIG_DIR/scripts" ]; then
    chmod +x "$CONFIG_DIR"/scripts/* 2>/dev/null || true
    success "Permissions updated."
else
    warning "No scripts directory found."
fi

# --- Finish ---
echo ""
echo -e "${GREEN}${BOLD}==============================================${NC}"
echo -e "${GREEN}${BOLD}     Installation Completed Successfully!     ${NC}"
echo -e "${GREEN}${BOLD}==============================================${NC}"
echo ""
echo -e "To start the shell, run: ${CYAN}quickshell${NC}"
echo -e "Or add it to your Wayland compositor's autostart file (e.g. Niri)."
echo ""
