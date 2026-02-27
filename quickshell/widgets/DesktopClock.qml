import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: clockWidget

    anchors {
        bottom: true
        left: true
    }

    margins {
        left: 24
        bottom: 24
    }

    implicitWidth: 300
    implicitHeight: 180
    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Bottom
    WlrLayershell.namespace: "quickshell-widget"
    exclusiveZone: 0

    // ── Frosted Glass Card ──
    Rectangle {
        id: card
        anchors.fill: parent
        radius: Theme.radiusLarge
        color: Theme.widgetBg
        border.width: 1
        border.color: Theme.widgetBorder

        // Gradient accent strip at top
        Rectangle {
            width: parent.width
            height: 3
            radius: Theme.radiusLarge
            anchors.top: parent.top
            anchors.topMargin: 0
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Theme.accent }
                GradientStop { position: 0.5; color: Theme.accentAlt }
                GradientStop { position: 1.0; color: Theme.teal }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: Theme.spacing

            // ── Large Time ──
            Text {
                id: bigTime
                anchors.horizontalCenter: parent.horizontalCenter
                font.family: Theme.monoFont
                font.pixelSize: 52
                font.weight: Font.Light
                color: Theme.text

                property string timeStr: ""

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: {
                        var d = new Date();
                        var h = d.getHours();
                        var m = d.getMinutes();
                        var s = d.getSeconds();
                        bigTime.timeStr = (h < 10 ? "0" : "") + h + ":" +
                                         (m < 10 ? "0" : "") + m + ":" +
                                         (s < 10 ? "0" : "") + s;
                    }
                }

                text: timeStr
            }

            // ── Date ──
            Text {
                id: dateDisplay
                anchors.horizontalCenter: parent.horizontalCenter
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontMedium
                color: Theme.subtext0

                property string dateStr: ""

                Timer {
                    interval: 60000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: {
                        var d = new Date();
                        var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
                        var months = ["January", "February", "March", "April", "May", "June",
                                      "July", "August", "September", "October", "November", "December"];
                        dateDisplay.dateStr = days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate() + ", " + d.getFullYear();
                    }
                }

                text: dateStr
            }

            // ── Week progress bar ──
            Item {
                id: weekItem
                width: 260
                height: 20
                anchors.horizontalCenter: parent.horizontalCenter

                property real weekProgress: {
                    var d = new Date();
                    var day = d.getDay();
                    var hour = d.getHours();
                    return (day === 0 ? 7 : day) / 7 + hour / (7 * 24);
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 6
                    height: 4
                    radius: 2
                    color: Theme.surface0

                    Rectangle {
                        width: parent.width * weekItem.weekProgress
                        height: parent.height
                        radius: parent.radius
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Theme.accent }
                            GradientStop { position: 1.0; color: Theme.teal }
                        }

                        Behavior on width {
                            NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic }
                        }
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    text: "Week " + Math.ceil((new Date().getTime() - new Date(new Date().getFullYear(), 0, 1).getTime()) / (7 * 24 * 60 * 60 * 1000))
                    color: Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontTiny
                }
            }
        }
    }
}
