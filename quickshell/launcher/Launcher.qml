import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."

PanelWindow {
    id: launcher

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    exclusiveZone: 0
    visible: launcherVisible
    focusable: true

    property bool launcherVisible: false
    property var allApps: []
    property var filteredApps: []
    property string searchQuery: ""

    // Load apps on first show
    onLauncherVisibleChanged: {
        if (launcherVisible) {
            searchQuery = "";
            if (allApps.length === 0) {
                loadAppsProc.running = true;
            } else {
                filterApps();
            }
        }
    }

    Process {
        id: loadAppsProc
        command: ["/home/amrit/.config/quickshell/scripts/apps.sh"]
        stdout: SplitParser {
            splitMarker: ""  // Read all at once
            onRead: data => {
                try {
                    launcher.allApps = JSON.parse(data);
                    launcher.filterApps();
                } catch (e) {
                    console.log("Failed to parse apps: " + e);
                }
            }
        }
    }

    function filterApps() {
        if (searchQuery === "") {
            filteredApps = allApps.slice(0, 30);
        } else {
            var q = searchQuery.toLowerCase();
            filteredApps = allApps.filter(function(app) {
                return app.name.toLowerCase().indexOf(q) >= 0 ||
                       (app.comment && app.comment.toLowerCase().indexOf(q) >= 0);
            }).slice(0, 30);
        }
    }

    // ── Backdrop ──
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)

        MouseArea {
            anchors.fill: parent
            onClicked: launcher.launcherVisible = false
        }
    }

    // ── Launcher Card ──
    Rectangle {
        id: launcherCard
        anchors.centerIn: parent
        width: 600
        height: 520
        radius: Theme.radiusXL
        color: Theme.popupBg
        border.width: 1
        border.color: Theme.panelBorder

        // Gradient top accent
        Rectangle {
            width: parent.width
            height: 3
            anchors.top: parent.top
            radius: Theme.radiusXL
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Theme.accent }
                GradientStop { position: 0.5; color: Theme.accentAlt }
                GradientStop { position: 1.0; color: Theme.teal }
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: Theme.widgetPadding
            anchors.topMargin: Theme.widgetPadding + 4
            spacing: Theme.spacingLarge

            // ── Search Bar ──
            Rectangle {
                width: parent.width
                height: 48
                radius: Theme.radiusMedium
                color: Theme.surface0
                border.width: 1
                border.color: searchInput.activeFocus ? Theme.accent : Theme.surface1

                Behavior on border.color {
                    ColorAnimation { duration: Theme.animFast }
                }

                Row {
                    anchors.fill: parent
                    anchors.margins: Theme.spacing
                    spacing: Theme.spacing

                    Text {
                        text: "󰍉"
                        color: Theme.overlay1
                        font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
                        font.pixelSize: Theme.fontLarge
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    TextInput {
                        id: searchInput
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 40
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontNormal
                        clip: true
                        focus: launcher.launcherVisible

                        onTextChanged: {
                            launcher.searchQuery = text;
                            launcher.filterApps();
                        }

                        // Placeholder
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Search applications..."
                            color: Theme.overlay0
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontNormal
                            visible: searchInput.text === ""
                        }
                    }
                }
            }

            // ── App Grid ──
            Flickable {
                width: parent.width
                height: parent.height - 70
                contentHeight: appGrid.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                GridLayout {
                    id: appGrid
                    width: parent.width
                    columns: 4
                    columnSpacing: Theme.spacing
                    rowSpacing: Theme.spacing

                    Repeater {
                        model: launcher.filteredApps

                        Rectangle {
                            id: appItem
                            Layout.preferredWidth: (appGrid.width - Theme.spacing * 3) / 4
                            Layout.preferredHeight: 100
                            radius: Theme.radiusMedium
                            color: appMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: Theme.animFast }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: Theme.spacingSmall

                                // App Icon (text-based fallback)
                                Rectangle {
                                    width: 48
                                    height: 48
                                    radius: Theme.radiusMedium
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: Qt.rgba(0.796, 0.651, 0.969, 0.1)
                                    border.width: 1
                                    border.color: Qt.rgba(0.796, 0.651, 0.969, 0.15)

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.name ? modelData.name.charAt(0).toUpperCase() : "?"
                                        color: Theme.accent
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontXL
                                        font.weight: Font.Bold
                                    }
                                }

                                // App name
                                Text {
                                    width: (appGrid.width - Theme.spacing * 3) / 4 - Theme.spacing * 2
                                    text: modelData.name || "Unknown"
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontTiny
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }

                            MouseArea {
                                id: appMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.exec) {
                                        launchProc.command = ["sh", "-c", modelData.exec + " &"];
                                        launchProc.running = true;
                                        launcher.launcherVisible = false;
                                    }
                                }
                            }

                            // Hover scale
                            scale: appMouse.containsMouse ? 1.05 : 1.0
                            Behavior on scale {
                                NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutBack }
                            }
                        }
                    }
                }
            }
        }
    }

    Process { id: launchProc; command: ["echo"] }
}
