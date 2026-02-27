import QtQuick
import ".."

// Quick toggle button for control center
Item {
    id: toggle
    width: (parent.width - Theme.spacing) / 2
    height: 48

    property string label: ""
    property string iconText: ""
    property bool active: false
    property color activeColor: Theme.accent

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMedium
        color: toggle.active ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.15) : Theme.surface0
        border.width: toggle.active ? 1 : 0
        border.color: Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.3)

        Behavior on color {
            ColorAnimation { duration: Theme.animNormal }
        }

        Row {
            anchors.centerIn: parent
            spacing: Theme.spacing

            Text {
                text: toggle.iconText
                color: toggle.active ? toggle.activeColor : Theme.overlay1
                font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                font.pixelSize: Theme.fontMedium
                anchors.verticalCenter: parent.verticalCenter

                Behavior on color {
                    ColorAnimation { duration: Theme.animNormal }
                }
            }

            Text {
                text: toggle.label
                color: toggle.active ? Theme.text : Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    MouseArea {
        id: toggleMouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: toggle.active = !toggle.active
    }

    scale: toggleMouse.pressed ? 0.95 : 1.0
    Behavior on scale {
        NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutBack }
    }
}
