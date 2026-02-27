import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// Background-layer window that displays the current wallpaper.
// Placed behind everything; updates instantly when Theme.wallpaperPath changes.
PanelWindow {
    id: wallpaperWindow

    anchors { top: true; bottom: true; left: true; right: true }
    color: "black"
    WlrLayershell.layer: WlrLayershell.Background
    WlrLayershell.namespace: "quickshell-wallpaper"
    exclusiveZone: 0

    Image {
        id: wpImage
        anchors.fill: parent
        source: "file://" + Theme.wallpaperPath
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false

        // Fade in when image changes
        opacity: 0
        onStatusChanged: {
            if (status === Image.Ready) fadeIn.start()
        }

        NumberAnimation on opacity {
            id: fadeIn
            from: 0; to: 1; duration: 600
            easing.type: Easing.OutCubic
        }
    }

    // Refetch when path changes
    Connections {
        target: Theme
        function onWallpaperPathChanged() {
            wpImage.opacity = 0;
            wpImage.source = "";
            wpImage.source = "file://" + Theme.wallpaperPath;
        }
    }
}
