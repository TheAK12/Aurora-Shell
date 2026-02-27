<h1 align="center">✨ QuickShell Dotfiles ✨</h1>

<p align="center">
  <em>A beautiful, modern, and highly aesthetic desktop shell configuration built with QuickShell and Qt6/QML for Wayland compositors (like Niri).</em>
</p>

---

## 🌟 Features

- **Modern Top Bar**: Clean Workspace Indicators, Clock, System Tray, and interactive Popups (Network, Media, Calendar).
- **Desktop Widgets**: macOS-style interactive widgets including:
  - Desktop Clock
  - Media Player (with cover art and controls)
  - System Monitor (CPU, RAM, Battery, Network)
  - Weather Widget
- **Control Center / Right Panel**: Quick toggles for Wi-Fi, Bluetooth, Volume, Brightness, and a Media Player.
- **Power Menu**: Sleek, animated overlay for Power Off, Reboot, Suspend, and Logout.
- **App Launcher**: Fast, stylized application launcher.
- **Dynamic OSD & Notifications**: Custom QuickShell-based On-Screen Displays and Notifications.
- **Extensible Scripting**: Backend driven by lightweight bash scripts using standard Linux utilities.

## 🛠️ Dependencies

Ensure you have the following installed on your system before proceeding:

- **[QuickShell](https://git.outfoxxed.me/outfoxxed/quickshell)** (The core shell framework)
- **Qt6**: `qt6-base`, `qt6-declarative`, `qt6-wayland`
- **Fonts**: A Nerd Font (e.g., *JetBrainsMono Nerd Font*, *Inter*) 
- **CLI Utilities**:
  - `playerctl` (Media player metadata & controls)
  - `pamixer` (Audio volume control)
  - `brightnessctl` (Screen brightness control)
  - `networkmanager` (`nmcli` for Wi-Fi integration)
  - `awk`, `grep`, `jq`, `curl`

## 🚀 Installation

For the easiest setup, simply run the interactive installation script included in this repository!

```bash
git clone https://github.com/yourusername/quickshell-dotfiles.git
cd quickshell-dotfiles
chmod +x install.sh
./install.sh
```

### Manual Installation

If you prefer to install it manually:

1. Backup your existing configuration:
   ```bash
   mv ~/.config/quickshell ~/.config/quickshell.bak
   ```
2. Copy this repository to your `.config` directory:
   ```bash
   cp -r . ~/.config/quickshell
   ```
3. Run QuickShell:
   ```bash
   quickshell
   ```
*(We recommend adding `quickshell` to your compositor's autostart script, e.g., in your `niri` config).*

## 🔮 Upcoming Features

- [ ] Interactive Bluetooth Module and pairing UI from the Control Center.
- [ ] Adaptive recoloring based on current wallpaper (Material You styling).
- [ ] Additional Desktop Widgets (Calendar, To-Do list).
- [ ] Improved Animations and Transitions for Waybar/QuickShell workspaces.
- [ ] GUI configuration tool for choosing themes and layouts.

---
<p align="center">Made with ❤️ for Linux Ricing</p>
