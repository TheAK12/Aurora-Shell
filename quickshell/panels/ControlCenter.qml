import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."

PanelWindow {
    id: controlCenter

    anchors {
        top: true
        right: true
    }

    margins {
        top: Theme.barHeight + Theme.spacing
        right: Theme.spacing
    }

    implicitWidth: 360
    implicitHeight: ccContent.implicitHeight + Theme.widgetPadding * 2
    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell-controlcenter"
    exclusiveZone: 0
    visible: ccVisible

    property bool ccVisible: false

    // System state
    property int volume: 50
    property bool volMute: false
    property int brightness: 100
    property int battery: 100
    property string batStatus: "Unknown"
    property string netName: "Disconnected"
    property string netType: "none"

    // Poll system info
    Timer {
        interval: 2000
        running: controlCenter.ccVisible
        repeat: true
        triggeredOnStart: true
        onTriggered: ccSysProc.running = true
    }

    Process {
        id: ccSysProc
        command: ["/home/amrit/.config/quickshell/scripts/sysinfo.sh", "--once"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var info = JSON.parse(data);
                    controlCenter.volume = info.volume || 0;
                    controlCenter.volMute = info.vol_mute || false;
                    controlCenter.brightness = info.brightness || 100;
                    controlCenter.battery = info.battery || 100;
                    controlCenter.batStatus = info.bat_status || "Unknown";
                    controlCenter.netName = info.net_name || "Disconnected";
                    controlCenter.netType = info.net_type || "none";
                } catch (e) {}
            }
        }
    }

    Rectangle {
        id: ccCard
        anchors.fill: parent
        radius: Theme.radiusLarge
        color: Theme.popupBg
        border.width: 1
        border.color: Theme.panelBorder

        // Gradient accent at top
        Rectangle {
            width: parent.width
            height: 3
            anchors.top: parent.top
            radius: Theme.radiusLarge
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Theme.accent }
                GradientStop { position: 0.5; color: Theme.accentAlt }
                GradientStop { position: 1.0; color: Theme.teal }
            }
        }

        Column {
            id: ccContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.widgetPadding
            anchors.topMargin: Theme.widgetPadding + 4
            spacing: Theme.spacingLarge

            // ── Header ──
            Row {
                width: parent.width
                spacing: Theme.spacing

                Text {
                    text: "Quick Settings"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontMedium
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item { width: 1; Layout.fillWidth: true; height: 1 }
            }

            // ── Volume Slider ──
            Column {
                width: parent.width
                spacing: Theme.spacingSmall

                Row {
                    spacing: Theme.spacing

                    Text {
                        text: controlCenter.volMute ? "󰖁" : "󰕾"
                        color: controlCenter.volMute ? Theme.surface2 : Theme.accent
                        font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                        font.pixelSize: Theme.fontLarge
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                muteProc.running = true;
                            }
                        }
                    }

                    Text {
                        text: "Volume"
                        color: Theme.subtext1
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item { width: 1; height: 1 }

                    Text {
                        text: controlCenter.volume + "%"
                        color: Theme.subtext0
                        font.family: Theme.monoFont
                        font.pixelSize: Theme.fontSmall
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Slider track
                Item {
                    width: parent.width
                    height: 24

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 6
                        radius: 3
                        color: Theme.surface0

                        Rectangle {
                            width: parent.width * (controlCenter.volume / 100)
                            height: parent.height
                            radius: parent.radius
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Theme.accent }
                                GradientStop { position: 1.0; color: Theme.pink }
                            }

                            Behavior on width {
                                NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
                            }
                        }

                        // Knob
                        Rectangle {
                            x: parent.width * (controlCenter.volume / 100) - width / 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            height: 16
                            radius: 8
                            color: Theme.text
                            border.width: 2
                            border.color: Theme.accent

                            Behavior on x {
                                NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            var newVol = Math.round(mouse.x / parent.width * 100);
                            newVol = Math.max(0, Math.min(100, newVol));
                            volSetProc.command = ["pamixer", "--set-volume", "" + newVol];
                            volSetProc.running = true;
                            controlCenter.volume = newVol;
                        }
                    }
                }
            }

            // ── Brightness Slider ──
            Column {
                width: parent.width
                spacing: Theme.spacingSmall

                Row {
                    spacing: Theme.spacing

                    Text {
                        text: "󰃟"
                        color: Theme.yellow
                        font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                        font.pixelSize: Theme.fontLarge
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Brightness"
                        color: Theme.subtext1
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item { width: 1; height: 1 }

                    Text {
                        text: controlCenter.brightness + "%"
                        color: Theme.subtext0
                        font.family: Theme.monoFont
                        font.pixelSize: Theme.fontSmall
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Item {
                    width: parent.width
                    height: 24

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 6
                        radius: 3
                        color: Theme.surface0

                        Rectangle {
                            width: parent.width * (controlCenter.brightness / 100)
                            height: parent.height
                            radius: parent.radius
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Theme.yellow }
                                GradientStop { position: 1.0; color: Theme.peach }
                            }

                            Behavior on width {
                                NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
                            }
                        }

                        Rectangle {
                            x: parent.width * (controlCenter.brightness / 100) - width / 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            height: 16
                            radius: 8
                            color: Theme.text
                            border.width: 2
                            border.color: Theme.yellow

                            Behavior on x {
                                NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            var newBr = Math.round(mouse.x / parent.width * 100);
                            newBr = Math.max(5, Math.min(100, newBr));
                            brSetProc.command = ["brightnessctl", "set", newBr + "%"];
                            brSetProc.running = true;
                            controlCenter.brightness = newBr;
                        }
                    }
                }
            }

            // ── Separator ──
            Rectangle {
                width: parent.width
                height: 1
                color: Theme.surface0
            }

            // ── Info Cards Row ──
            Row {
                width: parent.width
                spacing: Theme.spacing

                // Network card
                Rectangle {
                    width: (parent.width - Theme.spacing) / 2
                    height: 64
                    radius: Theme.radiusMedium
                    color: Theme.surface0

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: controlCenter.netType === "wifi" ? "󰤨" :
                                  controlCenter.netType === "ethernet" ? "󰈁" : "󰤭"
                            color: controlCenter.netType !== "none" ? Theme.accentAlt : Theme.overlay0
                            font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                            font.pixelSize: Theme.fontLarge
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: controlCenter.netName
                            color: Theme.subtext0
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontTiny
                            width: parent.parent.width - 16
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                // Battery card
                Rectangle {
                    width: (parent.width - Theme.spacing) / 2
                    height: 64
                    radius: Theme.radiusMedium
                    color: Theme.surface0

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: controlCenter.batStatus === "Charging" ? "󰂄" :
                                  controlCenter.battery > 80 ? "󰁹" :
                                  controlCenter.battery > 60 ? "󰂀" :
                                  controlCenter.battery > 40 ? "󰁾" :
                                  controlCenter.battery > 20 ? "󰁼" : "󰁺"
                            color: controlCenter.battery <= 20 ? Theme.red :
                                   controlCenter.batStatus === "Charging" ? Theme.green : Theme.text
                            font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                            font.pixelSize: Theme.fontLarge
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: controlCenter.battery + "% • " + controlCenter.batStatus
                            color: Theme.subtext0
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontTiny
                        }
                    }
                }
            }

            // ── Quick Toggles ──
            Row {
                width: parent.width
                spacing: Theme.spacing

                // DND Toggle
                QuickToggle {
                    label: "Do Not Disturb"
                    iconText: "󰂛"
                    activeColor: Theme.red
                }

                // Night Light Toggle
                QuickToggle {
                    label: "Night Light"
                    iconText: "󰖔"
                    activeColor: Theme.yellow
                }
            }
        }
    }

    // Process helpers
    Process { id: muteProc; command: ["pamixer", "-t"] }
    Process { id: volSetProc; command: ["echo"] }
    Process { id: brSetProc; command: ["echo"] }
}
