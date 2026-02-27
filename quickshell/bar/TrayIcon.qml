import QtQuick
import ".."

// Reusable tray icon button with hover/tooltip
Item {
    id: trayIcon
    width: 28
    height: 28

    property string iconText: ""
    property string tooltipText: ""
    property color iconColor: Theme.text
    property alias containsMouse: mouseArea.containsMouse

    signal clicked()

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }
    }

    Text {
        anchors.centerIn: parent
        text: trayIcon.iconText
        color: trayIcon.iconColor
        font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
        font.pixelSize: Theme.fontMedium

        Behavior on color {
            ColorAnimation { duration: Theme.animNormal }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: trayIcon.clicked()
    }

    // Tooltip
    Rectangle {
        id: tooltip
        visible: mouseArea.containsMouse && trayIcon.tooltipText.length > 0
        width: tooltipText.implicitWidth + Theme.spacing * 2
        height: tooltipText.implicitHeight + Theme.spacing
        x: (parent.width - width) / 2
        y: parent.height + 8
        radius: Theme.radiusSmall
        color: Theme.popupBg
        border.width: 1
        border.color: Theme.panelBorder
        z: 100

        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: trayIcon.tooltipText
            color: Theme.subtext1
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontTiny
        }

        opacity: mouseArea.containsMouse ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Theme.animFast }
        }
    }

    // Hover scale
    scale: mouseArea.containsMouse ? 1.1 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: Theme.animFast
            easing.type: Easing.OutBack
        }
    }
}
