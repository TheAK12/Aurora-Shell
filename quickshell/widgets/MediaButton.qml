import QtQuick
import ".."

// Reusable media control button
Item {
    id: btn
    width: isMain ? 40 : 32
    height: isMain ? 40 : 32

    property string iconText: ""
    property bool isMain: false

    signal clicked()

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: isMain ? (mouseArea.containsMouse ? Qt.rgba(0.796, 0.651, 0.969, 0.25) : Qt.rgba(0.796, 0.651, 0.969, 0.15))
                      : (mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent")

        border.width: isMain ? 1 : 0
        border.color: Qt.rgba(0.796, 0.651, 0.969, 0.3)

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }
    }

    Text {
        anchors.centerIn: parent
        text: btn.iconText
        color: isMain ? Theme.accent : Theme.subtext1
        font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
        font.pixelSize: isMain ? Theme.fontLarge : Theme.fontMedium
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }

    scale: mouseArea.pressed ? 0.9 : (mouseArea.containsMouse ? 1.1 : 1.0)
    Behavior on scale {
        NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutBack }
    }
}
