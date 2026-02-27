import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."

PanelWindow {
    id: bar

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 48
    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Top
    WlrLayershell.namespace: "quickshell-bar"
    exclusiveZone: 46

    // Media state
    property string mediaTitle: ""
    property string mediaArtist: ""
    property string mediaStatus: "Stopped"
    property string mediaPlayerIcon: "󰎆"

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: barMediaProc.running = true
    }

    Process {
        id: barMediaProc
        command: ["/home/amrit/.config/quickshell/scripts/mediaplayer.sh", "--once"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var info = JSON.parse(data);
                    bar.mediaStatus = info.status || "Stopped";
                    bar.mediaTitle = info.title || "";
                    bar.mediaArtist = info.artist || "";
                } catch (e) {}
            }
        }
    }

    // ── Main bar background — solid dark, no border ──
    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 14
        color: "#1e1e2e"

        // ── Full layout ──
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 0

            // ═══ LEFT ═══
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                spacing: 6

                // ── Logo pill ──
                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 32
                    radius: 10
                    color: logoMouse.containsMouse ? "#45475a" : "#313244"
                    Behavior on color {
                        ColorAnimation {
                            duration: 250
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰣇"
                        color: "#cba6f7"
                        font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                        font.pixelSize: 15
                    }

                    MouseArea {
                        id: logoMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: shell.launcherOpen = !shell.launcherOpen
                    }
                }

                // ── Workspace pills ──
                WorkspaceIndicator {}

                // ── MPRIS pill ──
                Rectangle {
                    id: mprisPill
                    Layout.preferredHeight: 32
                    Layout.preferredWidth: mprisContent.implicitWidth + 28
                    Layout.maximumWidth: 350
                    radius: 10
                    color: mprisMouse.containsMouse ? "#b4befe" : "#f5c2e7"
                    visible: bar.mediaTitle !== "" && bar.mediaStatus !== "Stopped"
                    Behavior on color {
                        ColorAnimation {
                            duration: 250
                        }
                    }

                    // Track position for popup alignment
                    onXChanged: updatePopupPos()
                    onVisibleChanged: updatePopupPos()
                    Component.onCompleted: updatePopupPos()
                    function updatePopupPos() {
                        if (visible) {
                            var pos = mprisPill.mapToItem(null, 0, 0);
                            shell.mediaPopupX = Math.max(0, pos.x);
                        }
                    }

                    Row {
                        id: mprisContent
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: bar.mediaStatus === "Playing" ? "󰎆" : "󰏤"
                            color: "#1e1e2e"
                            font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                            font.pixelSize: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: bar.mediaTitle
                            color: "#1e1e2e"
                            font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            width: Math.min(implicitWidth, 280)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: mprisMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: shell.togglePopup("media")
                    }
                }
            }

            // ═══ CENTER ═══
            Item {
                Layout.fillWidth: true
            }

            Clock {
                Layout.alignment: Qt.AlignCenter
            }

            Item {
                Layout.fillWidth: true
            }

            // ═══ RIGHT ═══
            SystemTray {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
        }
    }

    Process {
        id: barPlayProc
        command: ["playerctl", "play-pause"]
    }
}
