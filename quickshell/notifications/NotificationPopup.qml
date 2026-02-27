import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: notifPanel

    anchors {
        top: true
        right: true
    }

    margins {
        top: Theme.barHeight + Theme.spacing
        right: Theme.spacing
    }

    implicitWidth: 380
    implicitHeight: notifStack.implicitHeight + Theme.widgetPadding * 2
    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell-notifications"
    exclusiveZone: 0
    visible: notifModel.count > 0

    // Notification data model
    ListModel {
        id: notifModel
    }

    // Public function to add a notification
    function addNotification(title, body, icon, urgency) {
        notifModel.insert(0, {
            "title": title || "Notification",
            "body": body || "",
            "icon": icon || "󰂚",
            "urgency": urgency || "normal",
            "timestamp": new Date().toLocaleTimeString(Qt.locale(), "hh:mm"),
            "dismissing": false
        });

        // Also add to persistent history
        shell.addToHistory(title, body, icon, urgency);

        // Limit live stack to 5
        while (notifModel.count > 5) {
            notifModel.remove(notifModel.count - 1);
        }

        // Auto-dismiss after 5 seconds
        autoTimer.restart();
    }

    Timer {
        id: autoTimer
        interval: 5000
        onTriggered: {
            if (notifModel.count > 0) {
                notifModel.remove(notifModel.count - 1);
            }
        }
    }

    Component.onCompleted: {
        // Seed initial notification so user knows the shell is ready
        addNotification("Aurora Shell", "Your shell is ready.", "󰣇", "normal");
    }

    Column {
        id: notifStack
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.widgetPadding
        spacing: Theme.spacing

        Repeater {
            model: notifModel

            Rectangle {
                id: notifItem
                width: notifStack.width
                height: notifContent.implicitHeight + Theme.widgetPadding * 2
                radius: Theme.radiusMedium
                color: Theme.popupBg
                border.width: 1
                border.color: model.urgency === "critical" ? Qt.rgba(0.953, 0.545, 0.659, 0.3) :
                              Theme.panelBorder
                clip: true

                // Urgency accent strip
                Rectangle {
                    width: 3
                    height: parent.height
                    anchors.left: parent.left
                    color: model.urgency === "critical" ? Theme.red :
                           model.urgency === "low" ? Theme.surface2 : Theme.accent
                    radius: Theme.radiusMedium
                }

                Row {
                    id: notifContent
                    anchors.fill: parent
                    anchors.margins: Theme.widgetPadding
                    anchors.leftMargin: Theme.widgetPadding + 6
                    spacing: Theme.spacing

                    // Icon
                    Text {
                        text: model.icon
                        font.pixelSize: Theme.fontLarge
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 60

                        Row {
                            width: parent.width
                            spacing: Theme.spacing

                            Text {
                                text: model.title
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                width: parent.width - timestampText.width - Theme.spacing
                            }

                            Text {
                                id: timestampText
                                text: model.timestamp
                                color: Theme.overlay0
                                font.family: Theme.monoFont
                                font.pixelSize: Theme.fontTiny
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            text: model.body
                            color: Theme.subtext0
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            wrapMode: Text.WordWrap
                            width: parent.width
                            visible: model.body !== ""
                        }
                    }
                }

                // Dismiss button
                Text {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 8
                    text: "✕"
                    color: dismissMouse.containsMouse ? Theme.text : Theme.overlay0
                    font.pixelSize: Theme.fontSmall

                    MouseArea {
                        id: dismissMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: notifModel.remove(model.index)
                    }
                }

                // Slide-in animation
                opacity: 0
                x: 20
                Component.onCompleted: {
                    slideIn.start();
                    fadeIn.start();
                }

                NumberAnimation {
                    id: slideIn
                    target: notifItem
                    property: "x"
                    from: 20; to: 0
                    duration: Theme.animNormal
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    id: fadeIn
                    target: notifItem
                    property: "opacity"
                    from: 0; to: 1
                    duration: Theme.animNormal
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
