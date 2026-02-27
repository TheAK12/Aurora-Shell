import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."

PanelWindow {
    id: clockPopup

    anchors { top: true; bottom: true; left: true; right: true }
    margins.top: 0

    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell-clock-popup"
    WlrLayershell.keyboardFocus: WlrLayershell.OnDemand
    exclusiveZone: 0

    // ── Animation state ───────────────────────────────────────────
    property bool animOpen: false
    visible: animOpen

    Connections {
        target: shell
        function onClockPopupOpenChanged() {
            if (shell.clockPopupOpen) {
                clockPopup.animOpen = true
                restartWpProc()  // refresh wallpaper list on every open
            } else {
                clockCloseTimer.restart()
            }
        }
    }
    Timer { id: clockCloseTimer; interval: 320; onTriggered: clockPopup.animOpen = false }

    // ── State ─────────────────────────────────────────────────────
    property var  currentDate: new Date()
    property int  viewMonth:   currentDate.getMonth()
    property int  viewYear:    currentDate.getFullYear()
    property int  activeTab:   0   // 0=calendar  1=wallpaper
    property var  wpList:      []

    Timer {
        interval: 1000; running: shell.clockPopupOpen; repeat: true; triggeredOnStart: true
        onTriggered: clockPopup.currentDate = new Date()
    }

    // ── Wallpaper lister ──────────────────────────────────────────
    function restartWpProc() {
        wpProc.running = false
        wpRestartTimer.restart()
    }

    Timer { id: wpRestartTimer; interval: 50; onTriggered: wpProc.running = true }

    Process {
        id: wpProc
        command: ["sh", "/home/amrit/.config/quickshell/scripts/wallpapers.sh"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                var raw = data.trim()
                if (!raw) return
                try {
                    var parsed = JSON.parse(raw)
                    if (parsed.length > 0) clockPopup.wpList = parsed
                } catch(e) { console.log("wp parse err:", e, "raw:", raw.substring(0,80)) }
            }
        }
        Component.onCompleted: restartWpProc()
    }

    // ── Calendar helpers ──────────────────────────────────────────
    function getDaysInMonth(m, y)  { return new Date(y, m+1, 0).getDate() }
    function getFirstDay(m, y)     { return new Date(y, m, 1).getDay() }
    function getMonthName(m) {
        return ["January","February","March","April","May","June",
                "July","August","September","October","November","December"][m]
    }
    function getDayName(d) {
        return ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"][d]
    }
    function generateCalDays() {
        var days = [], fDay = getFirstDay(viewMonth, viewYear)
        var inM  = getDaysInMonth(viewMonth, viewYear)
        var prevM= getDaysInMonth((viewMonth-1+12)%12, viewMonth===0?viewYear-1:viewYear)
        for (var i = fDay-1; i >= 0; i--) days.push({day:prevM-i, current:false, today:false})
        var td = currentDate.getDate()
        var isCur = viewMonth===currentDate.getMonth() && viewYear===currentDate.getFullYear()
        for (var d = 1; d <= inM; d++) days.push({day:d, current:true, today:isCur&&d===td})
        var rem = 42 - days.length
        for (var n = 1; n <= rem; n++) days.push({day:n, current:false, today:false})
        return days
    }

    readonly property string nf: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
    readonly property int cardW: 320

    // ── Outside-click dismiss ─────────────────────────────────────
    MouseArea { anchors.fill: parent; onClicked: shell.closeAllPopups() }

    // ── Content ───────────────────────────────────────────────────
    Item {
        id: popupAnchor
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        width: clockPopup.cardW
        height: popupCard.height
        clip: true

        Rectangle {
            id: popupCard
            width: parent.width
            radius: 14
            color: "#1e1e2e"
            border.width: 1
            border.color: Qt.rgba(0.796, 0.651, 0.969, 0.14)

            // Extend flat top to cover the rounded top corners
            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 14; color: parent.color; z: 1
            }

            // Slide animation
            y: shell.clockPopupOpen ? 0 : -popupCard.height
            Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

            // Height = inner content + bottom padding
            height: inner.implicitHeight + inner.anchors.topMargin + inner.anchors.bottomMargin

            // Eat clicks so they don't dismiss the popup
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: inner
                anchors {
                    top: parent.top; left: parent.left; right: parent.right
                    topMargin: 14; leftMargin: 14; rightMargin: 14; bottomMargin: 12
                }
                spacing: 8

                // ── Clock ────────────────────────────────────────
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    property int  h:    { var hr = clockPopup.currentDate.getHours()%12; return hr===0?12:hr }
                    property string ap: clockPopup.currentDate.getHours()>=12 ? "PM" : "AM"
                    text: (h<10?"0":"")+h+":"
                        +(clockPopup.currentDate.getMinutes()<10?"0":"")+clockPopup.currentDate.getMinutes()+":"
                        +(clockPopup.currentDate.getSeconds()<10?"0":"")+clockPopup.currentDate.getSeconds()+" "+ap
                    color: "#94e2d5"
                    font { family: nf; pixelSize: 22; weight: Font.Bold }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: clockPopup.getDayName(clockPopup.currentDate.getDay()) + ",  " +
                          clockPopup.getMonthName(clockPopup.currentDate.getMonth()) + " " +
                          clockPopup.currentDate.getDate() + ", " + clockPopup.currentDate.getFullYear()
                    color: "#a6adc8"
                    font { family: nf; pixelSize: 11 }
                }

                // ── Tab switcher ──────────────────────────────────
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 30

                    Rectangle {
                        anchors.fill: parent; radius: 10; color: "#313244"
                    }

                    // Two hardcoded tab buttons
                    Rectangle {
                        id: tabCal
                        x: 3; y: 3
                        width: (parent.width - 9) / 2; height: parent.height - 6
                        radius: 8
                        color: clockPopup.activeTab === 0 ? "#cba6f7" : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: "  Calendar"
                            color: clockPopup.activeTab === 0 ? "#1e1e2e" : "#a6adc8"
                            font { family: nf; pixelSize: 10; weight: Font.SemiBold }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: clockPopup.activeTab = 0
                        }
                    }

                    Rectangle {
                        id: tabWp
                        x: tabCal.x + tabCal.width + 3; y: 3
                        width: tabCal.width; height: tabCal.height
                        radius: 8
                        color: clockPopup.activeTab === 1 ? "#cba6f7" : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: "  Wallpaper"
                            color: clockPopup.activeTab === 1 ? "#1e1e2e" : "#a6adc8"
                            font { family: nf; pixelSize: 10; weight: Font.SemiBold }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: clockPopup.activeTab = 1
                        }
                    }
                }

                // ── CALENDAR TAB ──────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: clockPopup.activeTab === 0
                    Layout.preferredHeight: clockPopup.activeTab === 0 ? implicitHeight : 0
                    clip: true

                    // Month nav
                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "󰅁"; color: pmM.containsMouse ? "#cdd6f4" : "#a6adc8"
                            font { family: nf; pixelSize: 14 }
                            Behavior on color { ColorAnimation { duration: 150 } }
                            MouseArea {
                                id: pmM; anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (clockPopup.viewMonth===0) { clockPopup.viewMonth=11; clockPopup.viewYear-- }
                                    else clockPopup.viewMonth--
                                }
                            }
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: clockPopup.getMonthName(clockPopup.viewMonth) + "  " + clockPopup.viewYear
                            color: "#cba6f7"
                            font { family: nf; pixelSize: 12; weight: Font.Bold }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { clockPopup.viewMonth=clockPopup.currentDate.getMonth(); clockPopup.viewYear=clockPopup.currentDate.getFullYear() }
                            }
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "󰅂"; color: nmM.containsMouse ? "#cdd6f4" : "#a6adc8"
                            font { family: nf; pixelSize: 14 }
                            Behavior on color { ColorAnimation { duration: 150 } }
                            MouseArea {
                                id: nmM; anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (clockPopup.viewMonth===11) { clockPopup.viewMonth=0; clockPopup.viewYear++ }
                                    else clockPopup.viewMonth++
                                }
                            }
                        }
                    }

                    // Weekday headers
                    Row {
                        Layout.fillWidth: true
                        Repeater {
                            model: ["Su","Mo","Tu","We","Th","Fr","Sa"]
                            Text {
                                width: (clockPopup.cardW - 28) / 7
                                text: modelData; color: "#f9e2af"
                                font { family: nf; pixelSize: 9; weight: Font.Bold }
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    // Day grid
                    Grid {
                        Layout.fillWidth: true; columns: 7
                        Repeater {
                            model: clockPopup.generateCalDays()
                            Rectangle {
                                width: (clockPopup.cardW-28)/7; height: 26; radius: 13
                                color: modelData.today ? "#cba6f7"
                                     : cdM.containsMouse && modelData.current ? Qt.rgba(1,1,1,0.06) : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.day
                                    color: modelData.today ? "#1e1e2e" : modelData.current ? "#cdd6f4" : "#45475a"
                                    font { family: nf; pixelSize: 10; weight: modelData.today ? Font.Bold : Font.Normal }
                                }
                                MouseArea { id: cdM; anchors.fill: parent; hoverEnabled: true }
                            }
                        }
                    }
                }

                // ── WALLPAPER TAB ─────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: clockPopup.activeTab === 1
                    Layout.preferredHeight: clockPopup.activeTab === 1 ? implicitHeight : 0
                    clip: true

                    // Current wallpaper mini-preview
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 80
                        radius: 10; color: "#313244"; clip: true

                        Image {
                            anchors.fill: parent
                            source: Theme.wallpaperPath ? "file://" + Theme.wallpaperPath : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        Rectangle {
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                            height: 20; color: Qt.rgba(0,0,0,0.55)
                            Text {
                                anchors.centerIn: parent
                                text: "Current wallpaper"
                                color: "#cdd6f4"; font { family: nf; pixelSize: 9 }
                            }
                        }
                    }

                    // Wallpaper grid
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Math.min(wpFlow.implicitHeight + 12, 230)
                        clip: true; radius: 10; color: "#11111b"

                        // Empty state
                        Text {
                            anchors.centerIn: parent
                            visible: clockPopup.wpList.length === 0
                            text: "No wallpapers found in\n~/Pictures/wallpapers/"
                            color: "#585b70"; font { family: nf; pixelSize: 10 }
                            horizontalAlignment: Text.AlignHCenter
                        }

                        // Scrollable flow
                        Flickable {
                            anchors.fill: parent; anchors.margins: 6
                            contentHeight: wpFlow.implicitHeight
                            clip: true

                            Flow {
                                id: wpFlow
                                width: parent.width
                                spacing: 6

                                Repeater {
                                    model: clockPopup.wpList

                                    Rectangle {
                                        id: wpThumb
                                        property bool isActive: Theme.wallpaperPath === modelData.path
                                        width: (wpFlow.width - 6) / 2
                                        height: width * 0.6
                                        radius: 8; clip: true
                                        border.width: isActive ? 2 : 0
                                        border.color: "#cba6f7"
                                        Behavior on border.width { NumberAnimation { duration: 150 } }

                                        Image {
                                            anchors.fill: parent
                                            source: "file://" + modelData.path
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true; smooth: true
                                        }

                                        // Active checkmark badge
                                        Rectangle {
                                            visible: wpThumb.isActive
                                            width: 18; height: 18; radius: 9
                                            color: "#cba6f7"
                                            anchors { top: parent.top; right: parent.right; margins: 4 }
                                            Text {
                                                anchors.centerIn: parent
                                                text: ""
                                                color: "#1e1e2e"
                                                font { family: nf; pixelSize: 10 }
                                            }
                                        }

                                        // Hover overlay
                                        Rectangle {
                                            anchors.fill: parent; radius: parent.radius
                                            color: Qt.rgba(1,1,1, thumbM.containsMouse ? 0.1 : 0)
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }

                                        // Name label on hover
                                        Rectangle {
                                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                            height: 18; radius: 0
                                            color: Qt.rgba(0,0,0, thumbM.containsMouse ? 0.6 : 0)
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.name
                                                color: "#cdd6f4"
                                                font { family: nf; pixelSize: 8 }
                                                elide: Text.ElideMiddle
                                                width: parent.width - 8
                                                horizontalAlignment: Text.AlignHCenter
                                                visible: thumbM.containsMouse
                                            }
                                        }

                                        MouseArea {
                                            id: thumbM; anchors.fill: parent
                                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Theme.wallpaperPath = modelData.path
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Refresh button
                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 28; radius: 8
                        color: rfM.containsMouse ? "#45475a" : "#313244"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: "󰑓  Refresh"
                            color: "#a6adc8"; font { family: nf; pixelSize: 10 }
                        }
                        MouseArea {
                            id: rfM; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: restartWpProc()
                        }
                    }
                }

                // Bottom spacer
                Item { implicitHeight: 2; Layout.fillWidth: true }
            }
        }
    }
}
