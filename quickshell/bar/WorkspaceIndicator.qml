import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: wsRoot
    Layout.preferredWidth: wsPill.width
    Layout.preferredHeight: 32

    property var workspaces: []
    property int focusedIdx: -1   // sorted array index of the focused workspace

    Timer {
        interval: 250
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: wsProc.running = true
    }

    Process {
        id: wsProc
        command: ["sh", "-c", "niri msg -j workspaces 2>/dev/null"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    var list = JSON.parse(data);
                    // Sort by idx so workspaces always appear in order
                    list.sort(function(a, b) { return a.idx - b.idx; });
                    wsRoot.workspaces = list;
                    wsRoot.focusedIdx = -1;
                    for (var i = 0; i < list.length; i++) {
                        if (list[i].is_focused) {
                            wsRoot.focusedIdx = i;
                            break;
                        }
                    }
                } catch (e) {}
            }
        }
    }

    // Outer pill container
    Rectangle {
        id: wsPill
        width: wsRow.implicitWidth + 8
        height: 32
        radius: 10
        color: "#313244"
        anchors.verticalCenter: parent.verticalCenter
        clip: true

        // ── Gliding active indicator ──
        Rectangle {
            id: activeIndicator
            width: 28
            height: 24
            radius: 20
            color: "#cba6f7"
            y: (parent.height - height) / 2
            visible: wsRoot.focusedIdx >= 0

            // Position = left padding + (index * (buttonWidth + spacing))
            x: wsRoot.focusedIdx >= 0
               ? 4 + wsRoot.focusedIdx * (28 + 4)
               : 0

            Behavior on x {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }
        }

        Row {
            id: wsRow
            anchors.centerIn: parent
            spacing: 4

            Repeater {
                model: wsRoot.workspaces

                Item {
                    width: 28
                    height: 24

                    property bool isFocused: modelData.is_focused || false
                    property int wsIdx: modelData.idx || (index + 1)

                    // Hover highlight (only for non-focused)
                    Rectangle {
                        anchors.fill: parent
                        radius: 20
                        color: wsBtnMouse.containsMouse && !parent.isFocused
                               ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: parent.wsIdx
                        color: parent.isFocused ? "#1e1e2e"
                             : wsBtnMouse.containsMouse ? "#cdd6f4"
                             : "#a6adc8"
                        font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                        font.pixelSize: 12
                        font.weight: parent.isFocused ? Font.Bold : Font.DemiBold

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: wsBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            wsSwitchProc.command = ["niri", "msg", "action", "focus-workspace", "" + parent.wsIdx];
                            wsSwitchProc.running = true;
                        }
                    }
                }
            }
        }
    }

    Process { id: wsSwitchProc; command: ["echo"] }
}
