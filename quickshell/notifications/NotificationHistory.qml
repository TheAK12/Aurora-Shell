import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: histPanel

    anchors { top: true; bottom: true; right: true }
    margins { top: 0; right: 0 }

    implicitWidth: 400
    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell-notif-history"
    WlrLayershell.keyboardFocus: WlrLayershell.OnDemand
    exclusiveZone: 0

    property bool animOpen: false
    visible: animOpen

    Connections {
        target: shell
        function onNotifHistoryOpenChanged() {
            if (shell.notifHistoryOpen) histPanel.animOpen = true
            else closeTimer.restart()
        }
    }
    Timer { id: closeTimer; interval: 320; onTriggered: histPanel.animOpen = false }

    // Outside click dismiss
    MouseArea { anchors.fill: parent; onClicked: shell.notifHistoryOpen = false }

    readonly property string nf: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"

    // ── Panel ─────────────────────────────────────────────────────
    Rectangle {
        id: panel
        anchors.right: parent.right
        anchors.rightMargin: 6
        width: 390
        radius: 16
        color: "#1a1a2e"
        border.width: 1
        border.color: Qt.rgba(0.796, 0.651, 0.969, 0.18)
        clip: true

        // Square off top
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 16; color: parent.color; z: 2
        }

        // Slide animation
        y: shell.notifHistoryOpen ? 0 : -panel.height
        Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

        implicitHeight: Math.min(mainCol.implicitHeight + 16, 640)

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: mainCol
            anchors {
                top: parent.top; left: parent.left; right: parent.right
                topMargin: 14; leftMargin: 14; rightMargin: 14; bottomMargin: 8
            }
            spacing: 0

            // ── Header bar ──────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true

                // Bell + title
                Row {
                    spacing: 8
                    Text {
                        text: "󰂚"
                        color: "#cba6f7"
                        font { family: nf; pixelSize: 18 }
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            text: "Notifications"
                            color: "#cdd6f4"
                            font { family: nf; pixelSize: 14; weight: Font.Bold }
                        }
                        Text {
                            text: shell.notifHistory.count > 0
                                ? shell.notifHistory.count + " notification" + (shell.notifHistory.count > 1 ? "s" : "")
                                : "All clear"
                            color: "#6c7086"
                            font { family: nf; pixelSize: 10 }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Clear all button
                Rectangle {
                    visible: shell.notifHistory.count > 0
                    implicitWidth: caInner.implicitWidth + 20
                    implicitHeight: 26; radius: 13
                    color: caM.containsMouse ? "#45475a" : "#313244"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        id: caInner
                        anchors.centerIn: parent
                        text: "Clear all"
                        color: caM.containsMouse ? "#cdd6f4" : "#6c7086"
                        font { family: nf; pixelSize: 10 }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    MouseArea {
                        id: caM; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: shell.notifHistory.clear()
                    }
                }
            }

            // ── Divider ─────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true; Layout.topMargin: 10; Layout.bottomMargin: 10
                height: 1; color: "#252535"
            }

            // ── Empty state ──────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: 120
                visible: shell.notifHistory.count === 0

                Column {
                    anchors.centerIn: parent
                    spacing: 10

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 56; height: 56; radius: 28
                        color: "#252535"
                        Text {
                            anchors.centerIn: parent
                            text: "󰂛"
                            color: "#45475a"
                            font { family: nf; pixelSize: 30 }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No notifications"
                        color: "#45475a"; font { family: nf; pixelSize: 12 }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "You're all caught up!"
                        color: "#313244"; font { family: nf; pixelSize: 10 }
                    }
                }
            }

            // ── Notification list ────────────────────────────────
            Flickable {
                id: notifFlick
                Layout.fillWidth: true
                implicitHeight: Math.min(listCol.implicitHeight, 440)
                contentHeight: listCol.implicitHeight
                clip: true
                visible: shell.notifHistory.count > 0

                // Manual scroll indicator
                Rectangle {
                    visible: notifFlick.contentHeight > notifFlick.height
                    anchors { right: parent.right; rightMargin: 2 }
                    width: 3; radius: 2
                    color: "#45475a"
                    height: notifFlick.height * (notifFlick.height / Math.max(notifFlick.contentHeight, 1))
                    y: notifFlick.contentY * (notifFlick.height / Math.max(notifFlick.contentHeight, 1))
                }

                Column {
                    id: listCol
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: shell.notifHistory

                        Rectangle {
                            id: notifCard
                            width: listCol.width
                            height: cardInner.implicitHeight + 22
                            radius: 12
                            color: cardHover.containsMouse ? "#22223a" : "#16162a"
                            border.width: 1
                            border.color: urgencyColor(model.urgency, 0.2)
                            clip: true
                            Behavior on color { ColorAnimation { duration: 120 } }

                            function urgencyColor(u, alpha) {
                                if (u === "critical") return Qt.rgba(0.953, 0.545, 0.659, alpha)
                                if (u === "low")      return Qt.rgba(0.345, 0.357, 0.439, alpha)
                                return Qt.rgba(0.796, 0.651, 0.969, alpha)
                            }

                            // Left accent stripe
                            Rectangle {
                                width: 3; height: parent.height
                                anchors.left: parent.left
                                radius: 2
                                color: model.urgency === "critical" ? "#f38ba8"
                                     : model.urgency === "low"      ? "#585b70" : "#cba6f7"
                            }

                            RowLayout {
                                id: cardInner
                                anchors {
                                    left: parent.left; right: parent.right; top: parent.top
                                    leftMargin: 16; rightMargin: 12; topMargin: 11; bottomMargin: 11
                                }
                                spacing: 10

                                // Icon circle
                                Rectangle {
                                    width: 36; height: 36; radius: 18
                                    color: notifCard.urgencyColor(model.urgency, 0.15)
                                    Layout.alignment: Qt.AlignTop

                                    Text {
                                        anchors.centerIn: parent
                                        text: model.icon || "󰂚"
                                        color: model.urgency === "critical" ? "#f38ba8"
                                             : model.urgency === "low"      ? "#a6adc8" : "#cba6f7"
                                        font { family: nf; pixelSize: 18 }
                                    }
                                }

                                // Content
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            Layout.fillWidth: true
                                            text: model.title || "Notification"
                                            color: "#e0e0f0"
                                            font { family: nf; pixelSize: 12; weight: Font.DemiBold }
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: model.timestamp || ""
                                            color: "#45475a"
                                            font { family: nf; pixelSize: 9 }
                                        }

                                        // Dismiss
                                        Rectangle {
                                            width: 18; height: 18; radius: 9
                                            color: dmHov.containsMouse ? "#45475a" : "transparent"
                                            Behavior on color { ColorAnimation { duration: 100 } }
                                            Text {
                                                anchors.centerIn: parent
                                                text: "✕"
                                                color: dmHov.containsMouse ? "#cdd6f4" : "#45475a"
                                                font { family: nf; pixelSize: 9 }
                                                Behavior on color { ColorAnimation { duration: 100 } }
                                            }
                                            MouseArea {
                                                id: dmHov; anchors.fill: parent
                                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: shell.notifHistory.remove(index)
                                            }
                                        }
                                    }

                                    // Body text
                                    Text {
                                        Layout.fillWidth: true
                                        text: model.body || ""
                                        visible: (model.body || "") !== ""
                                        color: "#7f849c"
                                        font { family: nf; pixelSize: 11 }
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 3
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            MouseArea { id: cardHover; anchors.fill: parent; hoverEnabled: true }
                        }
                    }
                }
            }

            Item { implicitHeight: 4; Layout.fillWidth: true }
        }
    }
}
