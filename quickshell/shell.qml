import QtQuick
import Quickshell
import Quickshell.Wayland
import "bar" as Bar
import "widgets" as Widgets
import "osd" as Osd
import "notifications" as Notifs
import "panels" as Panels
import "launcher" as Launcher
import "wallpaper" as Wp

ShellRoot {
    id: shell

    // ── Popup toggle state ────────────────────────────────────────
    property bool controlCenterOpen:  false
    property bool launcherOpen:       false
    property bool mediaPopupOpen:     false
    property bool clockPopupOpen:     false
    property bool networkPopupOpen:   false
    property bool powerMenuOpen:      false
    property bool notifHistoryOpen:   false
    property int  mediaPopupX:        200  // set dynamically by Bar.qml

    // ── Notification history shared model ────────────────────────
    ListModel { id: notifHistModel }
    property alias notifHistory: notifHistModel

    // ── Helper functions ─────────────────────────────────────────
    function closeAllPopups() {
        mediaPopupOpen   = false
        clockPopupOpen   = false
        networkPopupOpen = false
    }

    function togglePopup(name) {
        var wasOpen
        if (name === "media") {
            wasOpen = mediaPopupOpen
            closeAllPopups()
            mediaPopupOpen = !wasOpen
        } else if (name === "clock") {
            wasOpen = clockPopupOpen
            closeAllPopups()
            clockPopupOpen = !wasOpen
        } else if (name === "network") {
            wasOpen = networkPopupOpen
            closeAllPopups()
            networkPopupOpen = !wasOpen
        }
    }

    // Append a notification to the history log (called from NotificationPopup)
    function addToHistory(title, body, icon, urgency) {
        notifHistModel.insert(0, {
            "title":     title     || "Notification",
            "body":      body      || "",
            "icon":      icon      || "󰂚",
            "urgency":   urgency   || "normal",
            "timestamp": Qt.formatTime(new Date(), "hh:mm")
        })
        // Keep history at max 50 items
        while (notifHistModel.count > 50) notifHistModel.remove(notifHistModel.count - 1)
    }

    // ── Wallpaper (background layer) ──────────────────────────────
    Wp.Wallpaper { }

    // ── Top Bar ───────────────────────────────────────────────────
    Bar.Bar { }

    // ── Bar Popups ────────────────────────────────────────────────
    Bar.MediaPopup  { }
    Bar.ClockPopup  { }
    Bar.NetworkPopup { }

    // ── Desktop Widgets (right-side panel) ────────────────────────
    Widgets.RightPanel { }

    // ── OSD Overlay ───────────────────────────────────────────────
    Osd.OSD { }

    // ── Notifications ─────────────────────────────────────────────
    Notifs.NotificationPopup { }
    Notifs.NotificationHistory { }

    // ── Power Menu ────────────────────────────────────────────────
    Panels.PowerMenu { }

    // ── Control Center ────────────────────────────────────────────
    Panels.ControlCenter {
        id: controlCenter
        ccVisible: shell.controlCenterOpen
    }

    // ── App Launcher ──────────────────────────────────────────────
    Launcher.Launcher {
        id: appLauncher
        launcherVisible: shell.launcherOpen
    }
}
