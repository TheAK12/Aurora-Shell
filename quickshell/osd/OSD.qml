import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."

PanelWindow {
    id: osd

    anchors {
        bottom: true
        left: true
        right: true
    }

    margins {
        bottom: 80
    }

    implicitWidth: 280
    implicitHeight: 56
    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell-osd"
    exclusiveZone: 0
    visible: osdVisible

    property bool osdVisible: false
    property string osdType: "volume"  // "volume" or "brightness"
    property int osdValue: 0
    property bool osdMuted: false

    // Auto-hide timer
    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: osd.osdVisible = false
    }

    // Poll for changes (lightweight)
    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: osdPollProc.running = true
    }

    property int lastVolume: -1
    property int lastBrightness: -1

    Process {
        id: osdPollProc
        command: ["/home/amrit/.config/quickshell/scripts/sysinfo.sh", "--once"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var info = JSON.parse(data);
                    var vol = info.volume || 0;
                    var br = info.brightness || 100;
                    var muted = info.vol_mute || false;

                    // Detect volume change
                    if (osd.lastVolume >= 0 && vol !== osd.lastVolume) {
                        osd.osdType = "volume";
                        osd.osdValue = vol;
                        osd.osdMuted = muted;
                        osd.osdVisible = true;
                        hideTimer.restart();
                    }

                    // Detect brightness change
                    if (osd.lastBrightness >= 0 && br !== osd.lastBrightness) {
                        osd.osdType = "brightness";
                        osd.osdValue = br;
                        osd.osdMuted = false;
                        osd.osdVisible = true;
                        hideTimer.restart();
                    }

                    osd.lastVolume = vol;
                    osd.lastBrightness = br;
                } catch (e) {}
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 280
        height: 56
        radius: Theme.radiusXL
        color: Theme.popupBg
        border.width: 1
        border.color: Theme.panelBorder

        Row {
            anchors.centerIn: parent
            spacing: Theme.spacingLarge

            // Icon
            Text {
                text: osd.osdType === "volume"
                      ? (osd.osdMuted ? "󰖁" :
                         osd.osdValue > 66 ? "󰕾" :
                         osd.osdValue > 33 ? "󰖀" : "󰕿")
                      : (osd.osdValue > 66 ? "󰃠" :
                         osd.osdValue > 33 ? "󰃟" : "󰃞")
                color: osd.osdType === "volume" ? Theme.accent : Theme.yellow
                font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                font.pixelSize: Theme.fontLarge
                anchors.verticalCenter: parent.verticalCenter
            }

            // Progress bar
            Item {
                width: 160
                height: 8
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: parent.width
                    height: parent.height
                    radius: 4
                    color: Theme.surface0

                    Rectangle {
                        width: parent.width * (osd.osdValue / 100)
                        height: parent.height
                        radius: parent.radius

                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: osd.osdType === "volume" ? Theme.accent : Theme.yellow }
                            GradientStop { position: 1.0; color: osd.osdType === "volume" ? Theme.pink : Theme.peach }
                        }

                        Behavior on width {
                            NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }

            // Percentage
            Text {
                text: osd.osdValue + "%"
                color: Theme.text
                font.family: Theme.monoFont
                font.pixelSize: Theme.fontSmall
                width: 36
                horizontalAlignment: Text.AlignRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
