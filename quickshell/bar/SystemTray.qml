import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: trayRoot
    Layout.preferredWidth: trayRow.implicitWidth
    Layout.preferredHeight: 32

    // System data
    property int cpuPct: 0
    property int ramPct: 0
    property int volume: 0
    property bool volMute: false
    property int brightness: 100
    property int battery: 100
    property string batStatus: "Unknown"
    property string networkName: ""
    property bool networkConnected: false

    // Regular polling
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: trayProc.running = true
    }

    // Quick re-poll after user interaction (scroll etc.)
    Timer {
        id: quickPoll
        interval: 150
        repeat: false
        onTriggered: trayProc.running = true
    }

    function triggerQuickPoll() {
        quickPoll.running = false;
        quickPoll.running = true;
    }

    Process {
        id: trayProc
        command: ["/home/amrit/.config/quickshell/scripts/sysinfo.sh", "--once"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var info = JSON.parse(data);
                    trayRoot.cpuPct = info.cpu || 0;
                    trayRoot.ramPct = info.ram_pct || 0;
                    trayRoot.volume = info.volume || 0;
                    trayRoot.volMute = info.vol_mute || false;
                    trayRoot.brightness = info.brightness || 100;
                    trayRoot.battery = info.battery || 100;
                    trayRoot.batStatus = info.bat_status || "Unknown";
                    trayRoot.networkName = info.net_name || "Disconnected";
                    trayRoot.networkConnected = (info.net_type !== "none" && info.net_type !== undefined);
                } catch (e) {}
            }
        }
    }

    Row {
        id: trayRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        // ── Backlight pill (peach) ──
        Rectangle {
            width: blRow.implicitWidth + 28
            height: 32
            Behavior on width { NumberAnimation { duration: 150 } }
            radius: 10
            color: blMouse.containsMouse ? "#f9e2af" : "#fab387"
            Behavior on color { ColorAnimation { duration: 250 } }

            Row {
                id: blRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: trayRoot.brightness > 66 ? "󰃠" :
                          trayRoot.brightness > 33 ? "󰃟" : "󰃞"
                    color: "#1e1e2e"
                    font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: trayRoot.brightness + "%"
                    color: "#1e1e2e"
                    font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: blMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                property bool scrollEnabled: true
                onWheel: wheel => {
                    if (wheel.angleDelta.y > 0) {
                        trayRoot.brightness = Math.min(100, trayRoot.brightness + 2);
                        blUpProc.running = true;
                    } else {
                        trayRoot.brightness = Math.max(0, trayRoot.brightness - 2);
                        blDownProc.running = true;
                    }
                    trayRoot.triggerQuickPoll();
                }
            }
        }

        // ── Pulseaudio pill (peach / surface1 when muted) ──
        Rectangle {
            width: paRow.implicitWidth + 28
            height: 32
            Behavior on width { NumberAnimation { duration: 150 } }
            radius: 10
            color: trayRoot.volMute ? (paMouse.containsMouse ? "#585b70" : "#45475a")
                                    : (paMouse.containsMouse ? "#f9e2af" : "#fab387")
            Behavior on color { ColorAnimation { duration: 250 } }

            Row {
                id: paRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: trayRoot.volMute ? "󰸈" :
                          trayRoot.volume > 66 ? "󰕾" :
                          trayRoot.volume > 33 ? "󰖀" : "󰕿"
                    color: trayRoot.volMute ? "#cdd6f4" : "#1e1e2e"
                    font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: trayRoot.volMute ? "Muted" : trayRoot.volume + "%"
                    color: trayRoot.volMute ? "#cdd6f4" : "#1e1e2e"
                    font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: paMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        trayRoot.volMute = !trayRoot.volMute;
                        muteToggleProc.running = true;
                        trayRoot.triggerQuickPoll();
                    } else {
                        pavuProc.running = true;
                    }
                }
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onWheel: wheel => {
                    if (wheel.angleDelta.y > 0) {
                        trayRoot.volume = Math.min(100, trayRoot.volume + 5);
                        volUpProc.running = true;
                    } else {
                        trayRoot.volume = Math.max(0, trayRoot.volume - 5);
                        volDownProc.running = true;
                    }
                    trayRoot.triggerQuickPoll();
                }
            }
        }

        // ── Network pill (mauve) ──
        Rectangle {
            width: netRow.implicitWidth + 28
            height: 32
            radius: 10
            color: !trayRoot.networkConnected
                 ? (netMouse.containsMouse ? "#585b70" : "#45475a")
                 : (netMouse.containsMouse ? "#b4befe" : "#cba6f7")
            Behavior on color { ColorAnimation { duration: 250 } }

            Row {
                id: netRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: trayRoot.networkConnected ? "󰖩" : "󰖪"
                    color: trayRoot.networkConnected ? "#1e1e2e" : "#cdd6f4"
                    font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: netMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: shell.togglePopup("network")
            }
        }

        // ── CPU pill (sapphire) ──
        Rectangle {
            width: cpuRow.implicitWidth + 28
            height: 32
            Behavior on width { NumberAnimation { duration: 150 } }
            radius: 10
            color: trayRoot.cpuPct >= 90 ? "#f38ba8"
                 : trayRoot.cpuPct >= 70 ? "#f9e2af"
                 : (cpuMouse.containsMouse ? "#89dceb" : "#74c7ec")
            Behavior on color { ColorAnimation { duration: 250 } }

            Row {
                id: cpuRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "󰍛"
                    color: "#1e1e2e"
                    font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: trayRoot.cpuPct + "%"
                    color: "#1e1e2e"
                    font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: cpuMouse
                anchors.fill: parent
                hoverEnabled: true
            }
        }

        // ── Memory pill (blue) ──
        Rectangle {
            width: memRow.implicitWidth + 28
            height: 32
            Behavior on width { NumberAnimation { duration: 150 } }
            radius: 10
            color: trayRoot.ramPct >= 90 ? "#f38ba8"
                 : trayRoot.ramPct >= 70 ? "#f9e2af"
                 : (memMouse.containsMouse ? "#b4befe" : "#89b4fa")
            Behavior on color { ColorAnimation { duration: 250 } }

            Row {
                id: memRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "󰘚"
                    color: "#1e1e2e"
                    font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: trayRoot.ramPct + "%"
                    color: "#1e1e2e"
                    font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: memMouse
                anchors.fill: parent
                hoverEnabled: true
            }
        }

        // ── Battery pill (green) ──
        Rectangle {
            width: batRow.implicitWidth + 28
            height: 32
            radius: 10
            color: trayRoot.battery <= 15 ? "#f38ba8"
                 : trayRoot.battery <= 30 ? "#f9e2af"
                 : (batMouse.containsMouse ? "#94e2d5" : "#a6e3a1")
            Behavior on color { ColorAnimation { duration: 250 } }

            Row {
                id: batRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: trayRoot.batStatus === "Charging" ? "󱐋" :
                          trayRoot.batStatus === "Full" ? "󱟢" :
                          trayRoot.battery > 90 ? "󰁹" :
                          trayRoot.battery > 80 ? "󰂂" :
                          trayRoot.battery > 70 ? "󰂁" :
                          trayRoot.battery > 60 ? "󰂀" :
                          trayRoot.battery > 50 ? "󰁿" :
                          trayRoot.battery > 40 ? "󰁾" :
                          trayRoot.battery > 30 ? "󰁽" :
                          trayRoot.battery > 20 ? "󰁼" :
                          trayRoot.battery > 10 ? "󰁻" :
                          trayRoot.battery > 5  ? "󰁺" : "󰂎"
                    color: "#1e1e2e"
                    font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: trayRoot.batStatus === "Full" ? "Full"
                        : trayRoot.battery + "%"
                    color: "#1e1e2e"
                    font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: batMouse
                anchors.fill: parent
                hoverEnabled: true
            }
        }

        // ── Bell pill (purple) — opens notification history ──
        Rectangle {
            width: 34
            height: 32
            radius: 10
            color: bellPillM.containsMouse ? "#b4befe" : "#cba6f7"
            Behavior on color { ColorAnimation { duration: 250 } }

            Text {
                anchors.centerIn: parent
                text: shell.notifHistory.count > 0 ? "󰂚" : "󰂛"
                color: "#1e1e2e"
                font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                font.pixelSize: 14
            }

            // Unread badge
            Rectangle {
                visible: shell.notifHistory.count > 0
                width: 15; height: 15; radius: 8
                color: "#f38ba8"
                anchors { top: parent.top; right: parent.right; topMargin: 1; rightMargin: 1 }
                Text {
                    anchors.centerIn: parent
                    text: shell.notifHistory.count > 9 ? "9+" : shell.notifHistory.count
                    color: "#1e1e2e"
                    font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                    font.pixelSize: 7; font.weight: Font.Bold
                }
            }

            MouseArea {
                id: bellPillM
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: shell.notifHistoryOpen = !shell.notifHistoryOpen
            }
        }

        // ── Power pill (red) — opens PowerMenu overlay ──
        Rectangle {
            width: 34
            height: 32
            radius: 10
            color: pwrMouse.containsMouse ? "#eba0ac" : "#f38ba8"
            Behavior on color { ColorAnimation { duration: 250 } }

            Text {
                anchors.centerIn: parent
                text: "󰐥"
                color: "#1e1e2e"
                font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                font.pixelSize: 14
            }

            MouseArea {
                id: pwrMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: shell.powerMenuOpen = true
            }
        }
    }

    // ── Processes ──
    Process { id: muteToggleProc; command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"] }
    Process { id: pavuProc; command: ["pavucontrol"] }
    Process { id: volUpProc; command: ["pamixer", "-i", "5"] }
    Process { id: volDownProc; command: ["pamixer", "-d", "5"] }
    Process { id: blUpProc; command: ["brightnessctl", "set", "+2%"] }
    Process { id: blDownProc; command: ["brightnessctl", "set", "2%-"] }
    Process { id: nmEditorProc; command: ["nm-connection-editor"] }
}
