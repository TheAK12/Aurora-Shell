import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."

PanelWindow {
    id: mediaWidget

    anchors {
        bottom: true
        right: true
    }

    margins {
        right: 24
        bottom: 24
    }

    implicitWidth: 340
    implicitHeight: 170
    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Bottom
    WlrLayershell.namespace: "quickshell-widget"
    exclusiveZone: 0

    property string playerStatus: "Stopped"
    property string trackTitle: "No media playing"
    property string trackArtist: ""
    property string trackAlbum: ""
    property int trackLength: 0
    property int trackPosition: 0

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: mediaProc.running = true
    }

    Process {
        id: mediaProc
        command: ["/home/amrit/.config/quickshell/scripts/mediaplayer.sh", "--once"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var info = JSON.parse(data);
                    mediaWidget.playerStatus = info.status || "Stopped";
                    mediaWidget.trackTitle = info.title || "No media playing";
                    mediaWidget.trackArtist = info.artist || "";
                    mediaWidget.trackAlbum = info.album || "";
                    mediaWidget.trackLength = info.length || 0;
                    mediaWidget.trackPosition = info.position || 0;
                } catch (e) {}
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusLarge
        color: Theme.widgetBg
        border.width: 1
        border.color: Theme.widgetBorder
        clip: true

        // Playing state gradient overlay
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            opacity: mediaWidget.playerStatus === "Playing" ? 0.08 : 0.03
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.accent }
                GradientStop { position: 1.0; color: "transparent" }
            }
            Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }
        }

        Column {
            anchors.fill: parent
            anchors.margins: Theme.widgetPadding
            spacing: Theme.spacing

            // ── Track Info ──
            Column {
                width: parent.width
                spacing: 3

                Text {
                    width: parent.width
                    text: mediaWidget.trackTitle
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontNormal
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    width: parent.width
                    text: mediaWidget.trackArtist + (mediaWidget.trackAlbum ? " • " + mediaWidget.trackAlbum : "")
                    color: Theme.subtext0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    visible: mediaWidget.trackArtist !== ""
                }
            }

            // ── Progress Bar ──
            Column {
                width: parent.width
                spacing: 4

                // Time labels
                Row {
                    width: parent.width

                    Text {
                        text: formatTime(mediaWidget.trackPosition)
                        color: Theme.overlay0
                        font.family: Theme.monoFont
                        font.pixelSize: Theme.fontTiny
                    }
                    Item { width: parent.width - posLabel.width - durLabel.width; height: 1 }
                    Text {
                        id: durLabel
                        text: formatTime(mediaWidget.trackLength)
                        color: Theme.overlay0
                        font.family: Theme.monoFont
                        font.pixelSize: Theme.fontTiny
                    }
                    Text {
                        id: posLabel
                        visible: false
                        text: formatTime(mediaWidget.trackPosition)
                        font.pixelSize: Theme.fontTiny
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Theme.surface0

                    Rectangle {
                        width: mediaWidget.trackLength > 0
                               ? parent.width * (mediaWidget.trackPosition / mediaWidget.trackLength)
                               : 0
                        height: parent.height
                        radius: parent.radius
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Theme.accent }
                            GradientStop { position: 1.0; color: Theme.pink }
                        }
                        Behavior on width {
                            NumberAnimation { duration: 800; easing.type: Easing.Linear }
                        }
                    }
                }
            }

            // ── Controls ──
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacingLarge * 2

                MediaButton {
                    iconText: "󰒮"
                    onClicked: prevProc.running = true
                }

                MediaButton {
                    iconText: mediaWidget.playerStatus === "Playing" ? "󰏤" : "󰐊"
                    isMain: true
                    onClicked: playProc.running = true
                }

                MediaButton {
                    iconText: "󰒭"
                    onClicked: nextProc.running = true
                }
            }
        }
    }

    function formatTime(seconds) {
        var m = Math.floor(seconds / 60);
        var s = Math.floor(seconds % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    Process { id: prevProc; command: ["playerctl", "previous"] }
    Process { id: playProc; command: ["playerctl", "play-pause"] }
    Process { id: nextProc; command: ["playerctl", "next"] }
}
