import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."

// Full-screen power menu overlay
PanelWindow {
    id: powerMenu

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell-power-menu"
    WlrLayershell.keyboardFocus: WlrLayershell.Exclusive
    exclusiveZone: 0

    visible: shell.powerMenuOpen

    readonly property string nf: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"

    // Confirm state: -1 = none, 0-4 = which button is pending confirmation
    property int confirmIdx: -1

    onVisibleChanged: {
        if (!visible) confirmIdx = -1
    }

    // ESC key to dismiss — must be on an Item child
    Item {
        anchors.fill: parent
        focus: powerMenu.visible
        Keys.onEscapePressed: {
            if (powerMenu.confirmIdx !== -1) powerMenu.confirmIdx = -1
            else shell.powerMenuOpen = false
        }
    }

    // ── Dim background ────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.72)
        opacity: powerMenu.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 250 } }

        // Click outside to dismiss
        MouseArea {
            anchors.fill: parent
            onClicked: { shell.powerMenuOpen = false }
        }
    }

    // ── Content ───────────────────────────────────────────────────
    Item {
        anchors.centerIn: parent
        width: 480
        height: btnCol.implicitHeight + 80

        opacity: powerMenu.visible ? 1 : 0
        scale: powerMenu.visible ? 1 : 0.88
        Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        Behavior on scale  { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

        // Eat clicks so background dismiss doesn't fire
        MouseArea { anchors.fill: parent }

        Column {
            id: btnCol
            anchors.centerIn: parent
            spacing: 16

            // Greeting
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Power"
                color: "#cdd6f4"
                font { family: nf; pixelSize: 28; weight: Font.Bold }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(new Date(), "dddd, MMMM d")
                color: "#6c7086"
                font { family: nf; pixelSize: 13 }
                bottomPadding: 8
            }

            // ── Button row ────────────────────────────────────────
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                Repeater {
                    model: [
                        { icon: "󰌾", label: "Lock",     color: "#89b4fa", cmd: ["loginctl", "lock-session"] },
                        { icon: "󰤄", label: "Suspend",  color: "#94e2d5", cmd: ["systemctl", "suspend"] },
                        { icon: "󰍃", label: "Logout",   color: "#f9e2af", cmd: ["niri", "msg", "action", "quit", "--skip-confirmation"] },
                        { icon: "󰜉", label: "Reboot",   color: "#fab387", cmd: ["systemctl", "reboot"] },
                        { icon: "󰐥", label: "Shutdown", color: "#f38ba8", cmd: ["systemctl", "poweroff"] }
                    ]

                    delegate: PowerButton {
                        icon:  modelData.icon
                        label: modelData.label
                        clr:   modelData.color
                        cmd:   modelData.cmd
                        idx:   index
                        confirmPending: powerMenu.confirmIdx === index
                        onRequestConfirm: powerMenu.confirmIdx = index
                        onCancelConfirm:  powerMenu.confirmIdx = -1
                    }
                }
            }

            // ESC hint
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Press  Esc  or click outside to cancel"
                color: "#45475a"
                font { family: nf; pixelSize: 10 }
                topPadding: 8
            }
        }
    }

    // ── Inline button component ───────────────────────────────────
    component PowerButton: Rectangle {
        id: pb
        property string icon
        property string label
        property color  clr
        property var    cmd
        property int    idx
        property bool   confirmPending: false
        signal requestConfirm()
        signal cancelConfirm()

        width: 76; height: 90; radius: 18
        color: pbM.containsMouse ? Qt.rgba(clr.r, clr.g, clr.b, 0.18)
                                 : Qt.rgba(0.12, 0.12, 0.18, 0.85)
        border.width: confirmPending ? 2 : 1
        border.color: confirmPending ? clr : Qt.rgba(1,1,1,0.08)

        scale: pbM.pressed ? 0.93 : 1
        Behavior on scale  { NumberAnimation { duration: 100 } }
        Behavior on color  { ColorAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Process { id: execProc; command: pb.cmd }

        Column {
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: confirmPending ? "?" : pb.icon
                color: pb.clr
                font { family: nf; pixelSize: confirmPending ? 24 : 28 }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: confirmPending ? "Confirm" : pb.label
                color: confirmPending ? pb.clr : "#a6adc8"
                font { family: nf; pixelSize: 10; weight: confirmPending ? Font.Bold : Font.Normal }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        MouseArea {
            id: pbM; anchors.fill: parent
            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (confirmPending) {
                    execProc.running = true
                    shell.powerMenuOpen = false
                } else {
                    pb.requestConfirm()
                }
            }
        }
    }
}
