import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."

PanelWindow {
    id: sysMonWidget

    anchors {
        bottom: true
        left: true
    }

    margins {
        left: 24
        bottom: 220
    }

    implicitWidth: 280
    implicitHeight: 180
    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Bottom
    WlrLayershell.namespace: "quickshell-widget"
    exclusiveZone: 0

    property int cpuUsage: 0
    property int ramUsage: 0
    property string ramUsed: "0.0"
    property string ramTotal: "0.0"

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: sysProc.running = true
    }

    Process {
        id: sysProc
        command: ["/home/amrit/.config/quickshell/scripts/sysinfo.sh", "--once"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var info = JSON.parse(data);
                    sysMonWidget.cpuUsage = info.cpu || 0;
                    sysMonWidget.ramUsage = info.ram_pct || 0;
                    sysMonWidget.ramUsed = info.ram_used || "0.0";
                    sysMonWidget.ramTotal = info.ram_total || "0.0";
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

        // Title
        Text {
            anchors.top: parent.top
            anchors.topMargin: Theme.widgetPadding
            anchors.horizontalCenter: parent.horizontalCenter
            text: "System Monitor"
            color: Theme.subtext0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            font.weight: Font.DemiBold
        }

        Row {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 10
            spacing: 30

            // CPU Ring
            Item {
                width: 80
                height: 80

                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.beginPath();
                        ctx.arc(width/2, height/2, 32, 0, Math.PI * 2);
                        ctx.strokeStyle = Theme.surface0;
                        ctx.lineWidth = 5;
                        ctx.stroke();
                    }
                    Component.onCompleted: requestPaint()
                }

                Canvas {
                    id: cpuCanvas
                    anchors.fill: parent
                    property real progress: sysMonWidget.cpuUsage / 100

                    onProgressChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        if (progress > 0) {
                            ctx.beginPath();
                            ctx.arc(width/2, height/2, 32,
                                    -Math.PI/2,
                                    -Math.PI/2 + Math.PI * 2 * progress);
                            ctx.strokeStyle = sysMonWidget.cpuUsage > 80 ? Theme.red :
                                              sysMonWidget.cpuUsage > 50 ? Theme.peach : Theme.accent;
                            ctx.lineWidth = 5;
                            ctx.lineCap = "round";
                            ctx.stroke();
                        }
                    }

                    Behavior on progress {
                        NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: -1

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: sysMonWidget.cpuUsage + "%"
                        color: Theme.text
                        font.family: Theme.monoFont
                        font.pixelSize: Theme.fontMedium
                        font.weight: Font.DemiBold
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "CPU"
                        color: Theme.overlay0
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontTiny
                    }
                }
            }

            // RAM Ring
            Item {
                width: 80
                height: 80

                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.beginPath();
                        ctx.arc(width/2, height/2, 32, 0, Math.PI * 2);
                        ctx.strokeStyle = Theme.surface0;
                        ctx.lineWidth = 5;
                        ctx.stroke();
                    }
                    Component.onCompleted: requestPaint()
                }

                Canvas {
                    id: ramCanvas
                    anchors.fill: parent
                    property real progress: sysMonWidget.ramUsage / 100

                    onProgressChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        if (progress > 0) {
                            ctx.beginPath();
                            ctx.arc(width/2, height/2, 32,
                                    -Math.PI/2,
                                    -Math.PI/2 + Math.PI * 2 * progress);
                            ctx.strokeStyle = sysMonWidget.ramUsage > 80 ? Theme.red :
                                              sysMonWidget.ramUsage > 50 ? Theme.peach : Theme.accentAlt;
                            ctx.lineWidth = 5;
                            ctx.lineCap = "round";
                            ctx.stroke();
                        }
                    }

                    Behavior on progress {
                        NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: -1

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: sysMonWidget.ramUsage + "%"
                        color: Theme.text
                        font.family: Theme.monoFont
                        font.pixelSize: Theme.fontMedium
                        font.weight: Font.DemiBold
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: sysMonWidget.ramUsed + "/" + sysMonWidget.ramTotal + "G"
                        color: Theme.overlay0
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                    }
                }
            }
        }
    }
}
