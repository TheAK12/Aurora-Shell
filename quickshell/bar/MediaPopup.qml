import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."

PanelWindow {
    id: mediaPopup

    // Full-width, full-height overlay so outside clicks dismiss the popup
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    margins.top: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell-media-popup"
    WlrLayershell.keyboardFocus: WlrLayershell.OnDemand
    exclusiveZone: 0

    // ── Animation state ──────────────────────────────────────────
    // `animOpen` stays true during the close animation so the window
    // stays visible until slide-up finishes, then hides.
    property bool animOpen: false
    visible: animOpen

    // Watch shell state changes
    Connections {
        target: shell
        function onMediaPopupOpenChanged() {
            if (shell.mediaPopupOpen) {
                mediaPopup.animOpen = true
            } else {
                closeTimer.restart()
            }
        }
    }

    // Delay hide until slide-up animation finishes (320ms)
    Timer {
        id: closeTimer
        interval: 320
        onTriggered: mediaPopup.animOpen = false
    }

    property int popupHeight: 192

    // Media data
    property string title: ""
    property string artist: ""
    property string album: ""
    property string artUrl: ""
    property string status: "Stopped"
    property int position: 0
    property int length: 0

    Timer {
        interval: 1000
        running: shell.mediaPopupOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: mediaDetailProc.running = true
    }

    Process {
        id: mediaDetailProc
        command: ["/home/amrit/.config/quickshell/scripts/mediaplayer.sh", "--once"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var info = JSON.parse(data);
                    mediaPopup.title    = info.title   || "No media playing";
                    mediaPopup.artist   = info.artist  || "";
                    mediaPopup.album    = info.album   || "";
                    mediaPopup.artUrl   = info.artUrl  || "";
                    mediaPopup.status   = info.status  || "Stopped";
                    mediaPopup.position = info.position|| 0;
                    mediaPopup.length   = info.length  || 0;
                } catch (e) {}
            }
        }
    }

    function formatTime(secs) {
        var m = Math.floor(secs / 60), s = secs % 60;
        return (m<10?"0":"")+m+":"+(s<10?"0":"")+s;
    }

    // ── Full-screen transparent background — clicks outside dismiss ──
    MouseArea {
        anchors.fill: parent
        onClicked: shell.closeAllPopups()
    }

    // ── Popup content at correct x position ──────────────────────
    Item {
        x: shell.mediaPopupX
        y: 0
        width: 380
        height: mediaPopup.popupHeight
        clip: true

        Rectangle {
            id: slideContent
            width: parent.width
            height: parent.height
            radius: 14
            color: "#1e1e2e"

            // Flat top — overlay to square off top corners
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 14
                color: parent.color
            }

            // Slide: open → y=0, close → y=-height
            y: shell.mediaPopupOpen ? 0 : -height
            Behavior on y {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }

            // Eat clicks inside — prevent dismiss propagation
            MouseArea { anchors.fill: parent }

            RowLayout {
                anchors.fill: parent
                anchors.topMargin: 10
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                anchors.bottomMargin: 14
                spacing: 14

                // ── Album Art ──
                Rectangle {
                    Layout.preferredWidth: 110
                    Layout.preferredHeight: 110
                    Layout.alignment: Qt.AlignVCenter
                    radius: 12; color: "#313244"; clip: true

                    Image {
                        anchors.fill: parent
                        source: mediaPopup.artUrl
                        fillMode: Image.PreserveAspectCrop
                        visible: mediaPopup.artUrl !== ""
                        asynchronous: true
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "󰎆"; color: "#585b70"
                        font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"; font.pixelSize: 36
                        visible: mediaPopup.artUrl === ""
                    }
                }

                // ── Track Info + Controls ──
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        text: mediaPopup.title || "No media playing"
                        color: "#cdd6f4"
                        font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                        font.pixelSize: 13; font.weight: Font.Bold
                        elide: Text.ElideRight; maximumLineCount: 1
                    }
                    Text {
                        Layout.fillWidth: true
                        text: {
                            var p = [];
                            if (mediaPopup.artist) p.push(mediaPopup.artist);
                            if (mediaPopup.album)  p.push(mediaPopup.album);
                            return p.join(" — ") || "Unknown";
                        }
                        color: "#a6adc8"
                        font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                        font.pixelSize: 10; elide: Text.ElideRight; maximumLineCount: 1
                    }

                    Item { Layout.fillHeight: true }

                    // Progress bar
                    ColumnLayout { Layout.fillWidth: true; spacing: 3
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 4; radius: 2; color: "#313244"
                            Rectangle {
                                width: mediaPopup.length > 0 ? parent.width*(mediaPopup.position/mediaPopup.length) : 0
                                height: parent.height; radius: 2; color: "#f5c2e7"
                                Behavior on width { NumberAnimation { duration: 800 } }
                            }
                        }
                        RowLayout { Layout.fillWidth: true
                            Text { text: mediaPopup.formatTime(mediaPopup.position); color: "#585b70"; font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"; font.pixelSize: 9 }
                            Item { Layout.fillWidth: true }
                            Text { text: mediaPopup.formatTime(mediaPopup.length);   color: "#585b70"; font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"; font.pixelSize: 9 }
                        }
                    }

                    // Controls
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 16

                        Text {
                            text: "󰒟"
                            color: shM.containsMouse ? "#cdd6f4" : "#585b70"
                            font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                            font.pixelSize: 15
                            Behavior on color { ColorAnimation { duration: 150 } }
                            MouseArea {
                                id: shM; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: shuffleP.running = true
                            }
                        }

                        Text {
                            text: "󰒮"
                            color: prM.containsMouse ? "#cdd6f4" : "#a6adc8"
                            font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                            font.pixelSize: 18
                            Behavior on color { ColorAnimation { duration: 150 } }
                            MouseArea {
                                id: prM; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: prevP.running = true
                            }
                        }

                        Rectangle {
                            width: 34; height: 34; radius: 17
                            color: ppM.containsMouse ? "#f5c2e7" : "#cba6f7"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text {
                                anchors.centerIn: parent
                                text: mediaPopup.status === "Playing" ? "󰏤" : "󰐊"
                                color: "#1e1e2e"
                                font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                                font.pixelSize: 17
                            }
                            MouseArea {
                                id: ppM; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: playP.running = true
                            }
                        }

                        Text {
                            text: "󰒭"
                            color: nxM.containsMouse ? "#cdd6f4" : "#a6adc8"
                            font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                            font.pixelSize: 18
                            Behavior on color { ColorAnimation { duration: 150 } }
                            MouseArea {
                                id: nxM; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: nextP.running = true
                            }
                        }

                        Text {
                            text: "󰑖"
                            color: lpM.containsMouse ? "#cdd6f4" : "#585b70"
                            font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                            font.pixelSize: 15
                            Behavior on color { ColorAnimation { duration: 150 } }
                            MouseArea {
                                id: lpM; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: loopP.running = true
                            }
                        }
                    }
                }
            }
        }
    }

    Process { id: playP;    command: ["playerctl","play-pause"] }
    Process { id: prevP;    command: ["playerctl","previous"] }
    Process { id: nextP;    command: ["playerctl","next"] }
    Process { id: shuffleP; command: ["playerctl","shuffle","toggle"] }
    Process { id: loopP;    command: ["playerctl","loop","Track"] }
}
