import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."

PanelWindow {
    id: weatherWidget

    anchors {
        bottom: true
        right: true
    }

    margins {
        right: 24
        bottom: 200
    }

    implicitWidth: 340
    implicitHeight: 160
    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Bottom
    WlrLayershell.namespace: "quickshell-widget"
    exclusiveZone: 0

    property string temperature: "--"
    property string condition: "Loading..."
    property string location: ""
    property string feelsLike: "--"
    property string humidity: "--"
    property string windSpeed: "--"
    property string weatherIcon: "☁"

    // Fetch weather every 10 minutes
    Timer {
        interval: 600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherProc.running = true
    }

    Process {
        id: weatherProc
        command: ["sh", "-c", "curl -sf 'wttr.in/?format=j1' 2>/dev/null"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    var w = JSON.parse(data);
                    var current = w.current_condition[0];
                    weatherWidget.temperature = current.temp_C || "--";
                    weatherWidget.feelsLike = current.FeelsLikeC || "--";
                    weatherWidget.humidity = current.humidity || "--";
                    weatherWidget.windSpeed = current.windspeedKmph || "--";
                    weatherWidget.condition = current.weatherDesc[0].value || "Unknown";
                    weatherWidget.location = w.nearest_area[0].areaName[0].value || "";

                    var code = parseInt(current.weatherCode);
                    if (code === 113) weatherWidget.weatherIcon = "☀";
                    else if (code === 116) weatherWidget.weatherIcon = "⛅";
                    else if (code <= 122) weatherWidget.weatherIcon = "☁";
                    else if (code <= 182) weatherWidget.weatherIcon = "🌧";
                    else if (code <= 232) weatherWidget.weatherIcon = "🌩";
                    else if (code <= 260) weatherWidget.weatherIcon = "🌫";
                    else if (code <= 302) weatherWidget.weatherIcon = "🌦";
                    else if (code <= 356) weatherWidget.weatherIcon = "🌧";
                    else if (code <= 395) weatherWidget.weatherIcon = "❄";
                    else weatherWidget.weatherIcon = "☁";
                } catch (e) {
                    weatherWidget.condition = "Unavailable";
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusLarge
        color: Theme.widgetBg
        border.width: 1
        border.color: Theme.widgetBorder

        Row {
            anchors.fill: parent
            anchors.margins: Theme.widgetPadding
            spacing: Theme.spacingLarge

            // ── Weather Icon + Temp ──
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                width: 90

                Text {
                    text: weatherWidget.weatherIcon
                    font.pixelSize: 42
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: weatherWidget.temperature + "°C"
                    color: Theme.text
                    font.family: Theme.monoFont
                    font.pixelSize: Theme.fontXL
                    font.weight: Font.DemiBold
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // ── Details ──
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingSmall
                width: parent.width - 110 - Theme.spacingLarge

                Text {
                    text: weatherWidget.condition
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontNormal
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: weatherWidget.location
                    color: Theme.subtext0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    elide: Text.ElideRight
                    width: parent.width
                }

                Row {
                    spacing: Theme.spacingLarge

                    Row {
                        spacing: 4
                        Text { text: "🌡"; font.pixelSize: Theme.fontSmall }
                        Text {
                            text: weatherWidget.feelsLike + "°"
                            color: Theme.subtext0
                            font.family: Theme.monoFont
                            font.pixelSize: Theme.fontSmall
                        }
                    }

                    Row {
                        spacing: 4
                        Text { text: "💧"; font.pixelSize: Theme.fontSmall }
                        Text {
                            text: weatherWidget.humidity + "%"
                            color: Theme.subtext0
                            font.family: Theme.monoFont
                            font.pixelSize: Theme.fontSmall
                        }
                    }

                    Row {
                        spacing: 4
                        Text { text: "💨"; font.pixelSize: Theme.fontSmall }
                        Text {
                            text: weatherWidget.windSpeed + "km/h"
                            color: Theme.subtext0
                            font.family: Theme.monoFont
                            font.pixelSize: Theme.fontSmall
                        }
                    }
                }
            }
        }
    }
}
