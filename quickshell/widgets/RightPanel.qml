import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."

PanelWindow {
    id: rightPanel

    anchors {
        top: true
        right: true
    }

    margins {
        top: 10    // bar exclusiveZone:46 already keeps us below bar
        right: 14
    }

    implicitWidth: 320
    implicitHeight: panelCol.implicitHeight + 14
    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Bottom
    WlrLayershell.namespace: "quickshell-right-panel"
    exclusiveZone: 0

    // ── Shared Data ──────────────────────────────────────────────────

    // Clock
    property var now: new Date()
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: rightPanel.now = new Date()
    }

    // Sysinfo
    property int cpuPct: 0
    property int ramPct: 0
    property string ramUsed: "0"
    property string ramTotal: "0"
    property int diskPct: 0
    property string diskUsed: "0"
    property string diskTotal: "0"

    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: sysProc.running = true
    }
    Process {
        id: sysProc
        command: ["/home/amrit/.config/quickshell/scripts/sysinfo.sh", "--once"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var d = JSON.parse(data);
                    rightPanel.cpuPct  = d.cpu       || 0;
                    rightPanel.ramPct  = d.ram_pct   || 0;
                    rightPanel.ramUsed = d.ram_used  || "0";
                    rightPanel.ramTotal= d.ram_total || "0";
                } catch(e) {}
            }
        }
    }

    // Disk
    Timer {
        interval: 30000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: diskProc.running = true
    }
    Process {
        id: diskProc
        command: ["sh","-c","df -h / | awk 'NR==2{printf \"{\\\"pct\\\":%d,\\\"used\\\":\\\"%s\\\",\\\"total\\\":\\\"%s\\\"}\",$5,$3,$2}'| tr -d '%'"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var d = JSON.parse(data);
                    rightPanel.diskPct  = d.pct   || 0;
                    rightPanel.diskUsed = d.used  || "0";
                    rightPanel.diskTotal= d.total || "0";
                } catch(e) {}
            }
        }
    }

    // Battery + Volume
    property int batPct: 0
    property string batStatus: "Discharging"
    property int volPct: 0
    property bool volMuted: false

    // Battery + Volume — poll fast for responsiveness
    Timer {
        interval: 500; running: true; repeat: true; triggeredOnStart: true
        onTriggered: batVolProc.running = true
    }
    Process {
        id: batVolProc
        command: ["sh", "-c", [
            "bat=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo 0);",
            "status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null || echo Discharging);",
            "vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null);",
            "volpct=$(echo $vol | awk '{printf \"%.0f\",$2*100}');",
            "muted=$(echo $vol | grep -q MUTED && echo true || echo false);",
            "printf '{\"bat\":%d,\"status\":\"%s\",\"vol\":%d,\"muted\":%s}\\n' $bat \"$status\" $volpct $muted"
        ].join(" ")]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var d = JSON.parse(data);
                    rightPanel.batPct    = d.bat    || 0;
                    rightPanel.batStatus = d.status || "Discharging";
                    rightPanel.volPct    = d.vol    || 0;
                    rightPanel.volMuted  = d.muted  || false;
                } catch(e) {}
            }
        }
    }

    // Uptime
    property string uptimeText: "0m"
    Timer {
        interval: 60000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: uptimeProc.running = true
    }
    Process {
        id: uptimeProc
        command: ["sh", "-c", "uptime -p | sed 's/up //;s/ hours\\?/h/;s/ minutes\\?/m/;s/ days\\?/d/;s/, / /g'"]
        stdout: SplitParser {
            onRead: data => { rightPanel.uptimeText = data.trim() || "0m"; }
        }
    }

    // Media
    property string mediaStatus: "Stopped"
    property string mediaTitle: ""
    property string mediaArtist: ""
    property string mediaArtUrl: ""
    property int mediaPos: 0
    property int mediaLen: 0

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: mediaProc.running = true
    }
    Process {
        id: mediaProc
        command: ["/home/amrit/.config/quickshell/scripts/mediaplayer.sh", "--once"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var d = JSON.parse(data);
                    rightPanel.mediaStatus = d.status  || "Stopped";
                    rightPanel.mediaTitle  = d.title   || "";
                    rightPanel.mediaArtist = d.artist  || "";
                    rightPanel.mediaArtUrl = d.artUrl  || "";
                    rightPanel.mediaPos    = d.position|| 0;
                    rightPanel.mediaLen    = d.length  || 0;
                } catch(e) {}
            }
        }
    }

    // Calendar
    property int calViewMonth: (new Date()).getMonth()
    property int calViewYear:  (new Date()).getFullYear()

    // ── Helpers ─────────────────────────────────────────────────────

    function fmtTime(s) {
        var m = Math.floor(s/60); var ss = s%60;
        return (m<10?"0":"")+m+":"+(ss<10?"0":"")+ss;
    }

    function batIcon() {
        if (batStatus === "Charging") return "󰂄";
        if (batPct > 80) return "󰁹"; if (batPct > 60) return "󰂀";
        if (batPct > 40) return "󰁾"; if (batPct > 20) return "󰁼"; return "󰂎";
    }

    function volIcon() {
        if (volMuted) return "󰖁";
        if (volPct > 50) return "󰕾"; if (volPct > 0) return "󰖀"; return "󰕿";
    }

    function monthName(m) {
        return ["January","February","March","April","May","June","July",
                "August","September","October","November","December"][m];
    }

    function calDays() {
        var days = [];
        var firstDay = new Date(calViewYear, calViewMonth, 1).getDay();
        var inMonth  = new Date(calViewYear, calViewMonth+1, 0).getDate();
        var prevDays = new Date(calViewYear, calViewMonth, 0).getDate();
        for (var i = firstDay-1; i >= 0; i--) days.push({d:prevDays-i, cur:false, today:false});
        var today = now.getDate();
        var isCur = calViewMonth === now.getMonth() && calViewYear === now.getFullYear();
        for (var d = 1; d <= inMonth; d++) days.push({d:d, cur:true, today:isCur&&d===today});
        var rem = 42 - days.length;
        for (var n = 1; n <= rem; n++) days.push({d:n, cur:false, today:false});
        return days;
    }

    // ── Card helper properties ───────────────────────────────────────
    readonly property color cardBg:     "#1e1e2e"
    readonly property color cardBorder: Qt.rgba(0.796, 0.651, 0.969, 0.12)
    readonly property color surf0:      "#313244"
    readonly property color surf1:      "#45475a"
    readonly property string mono: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
    readonly property string sans: "Inter, Segoe UI, sans-serif"

    // ── Main column ─────────────────────────────────────────────────
    ColumnLayout {
        id: panelCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

        // ═══════════════════════════════════════════════════════════
        // 1. CLOCK CARD
        // ═══════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: clockCol.implicitHeight + 32
            radius: 16
            color: cardBg
            border.width: 1
            border.color: cardBorder

            // Gradient accent strip
            Rectangle {
                width: parent.width * 0.6
                height: 3
                radius: 2
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#cba6f7" }
                    GradientStop { position: 0.5; color: "#89b4fa" }
                    GradientStop { position: 1.0; color: "#94e2d5" }
                }
            }

            ColumnLayout {
                id: clockCol
                anchors.centerIn: parent
                spacing: 4

                // Big HH:MM
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 0

                    Text {
                        property int h: { var hr = now.getHours(); return hr === 0 ? 0 : hr; }
                        text: (h < 10 ? "0" : "") + h
                        color: "#cdd6f4"
                        font.family: mono
                        font.pixelSize: 52
                        font.weight: Font.Bold
                        Behavior on text { PropertyAnimation { duration: 200 } }
                    }

                    // Blinking colon
                    Text {
                        text: ":"
                        color: now.getSeconds() % 2 === 0 ? "#cba6f7" : Qt.rgba(0.796, 0.651, 0.969, 0.3)
                        font.family: mono
                        font.pixelSize: 48
                        font.weight: Font.Bold
                        anchors.baseline: undefined
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }

                    Text {
                        property int mn: now.getMinutes()
                        text: (mn < 10 ? "0" : "") + mn
                        color: "#cdd6f4"
                        font.family: mono
                        font.pixelSize: 52
                        font.weight: Font.Bold
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"][now.getDay()]
                    color: "#94e2d5"
                    font.family: sans
                    font.pixelSize: 15
                    font.weight: Font.SemiBold
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: monthName(now.getMonth()) + " " + now.getDate() + ", " + now.getFullYear()
                    color: "#a6adc8"
                    font.family: sans
                    font.pixelSize: 12
                }

                // Week progress bar
                Item {
                    Layout.preferredWidth: 260
                    Layout.preferredHeight: 18
                    Layout.alignment: Qt.AlignHCenter

                    property real wp: {
                        var day = now.getDay() === 0 ? 7 : now.getDay();
                        return day / 7 + now.getHours() / (7 * 24);
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 3
                        radius: 2
                        color: surf0

                        Rectangle {
                            width: parent.width * parent.parent.wp
                            height: parent.height; radius: 2
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#cba6f7" }
                                GradientStop { position: 1.0; color: "#94e2d5" }
                            }
                            Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
                        }
                    }
                    Text {
                        anchors.right: parent.right; anchors.top: parent.top
                        text: "Week " + Math.ceil((now - new Date(now.getFullYear(),0,1))/(7*24*3600*1000))
                        color: "#585b70"; font.family: sans; font.pixelSize: 9
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════
        // 2. BATTERY + VOLUME CARD
        // ═══════════════════════════════════════════════════════════
        Rectangle {
            id: batVolCard
            Layout.fillWidth: true
            implicitHeight: 100
            radius: 16
            color: cardBg
            border.width: 1
            border.color: cardBorder

            Row {
                anchors.fill: parent
                anchors.topMargin: 12
                anchors.bottomMargin: 12

                // ── Battery ──────────────────────────────────────
                Item {
                    width: parent.width / 2
                    height: parent.height

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: batIcon()
                            color: batStatus === "Charging" ? "#a6e3a1"
                                 : batPct > 20 ? "#a6e3a1" : "#f38ba8"
                            font.family: mono
                            font.pixelSize: 26
                            Behavior on color { ColorAnimation { duration: 500 } }
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: batPct + "%"
                            color: "#cdd6f4"
                            font.family: mono
                            font.pixelSize: 20
                            font.weight: Font.Bold
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: batStatus === "Charging" ? "Charging"
                                : batStatus === "Full" ? "Full" : "Battery"
                            color: "#6c7086"
                            font.family: sans
                            font.pixelSize: 10
                        }
                    }
                }

                // Vertical divider
                Rectangle {
                    width: 1
                    height: parent.height * 0.6
                    anchors.verticalCenter: parent.verticalCenter
                    color: cardBorder
                }

                // ── Volume ───────────────────────────────────────
                Item {
                    width: parent.width / 2 - 1
                    height: parent.height

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: volIcon()
                            color: volMuted ? "#f38ba8" : "#89b4fa"
                            font.family: mono
                            font.pixelSize: 26
                            Behavior on color { ColorAnimation { duration: 300 } }
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: volMuted ? "Muted" : volPct + "%"
                            color: "#cdd6f4"
                            font.family: mono
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            Behavior on text { PropertyAnimation { duration: 200 } }
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Volume"
                            color: "#6c7086"
                            font.family: sans
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════
        // 3. SYSTEM MONITOR CARD
        // ═══════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: sysCol.implicitHeight + 32
            radius: 16
            color: cardBg
            border.width: 1
            border.color: cardBorder

            ColumnLayout {
                id: sysCol
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                // Title
                Text {
                    text: "SYSTEM MONITOR"
                    color: "#6c7086"
                    font.family: sans
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }

                // CPU bar
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    RowLayout {
                        Layout.fillWidth: true
                        Row {
                            spacing: 6
                            Text { text: "󰍛"; color: "#89b4fa"; font.family: mono; font.pixelSize: 13 }
                            Text { text: "CPU"; color: "#bac2de"; font.family: sans; font.pixelSize: 12; font.weight: Font.SemiBold }
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: cpuPct + "%"
                            color: cpuPct > 80 ? "#f38ba8" : cpuPct > 50 ? "#fab387" : "#cdd6f4"
                            font.family: mono; font.pixelSize: 11; font.weight: Font.DemiBold
                            Behavior on color { ColorAnimation { duration: 500 } }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true; height: 7; radius: 4; color: surf0
                        Rectangle {
                            width: parent.width * (cpuPct / 100)
                            height: parent.height; radius: parent.radius
                            color: cpuPct>80?"#f38ba8":cpuPct>50?"#fab387":"#89b4fa"
                            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 500 } }
                        }
                    }
                }

                // RAM bar
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    RowLayout {
                        Layout.fillWidth: true
                        Row {
                            spacing: 6
                            Text { text: "󰘚"; color: "#cba6f7"; font.family: mono; font.pixelSize: 13 }
                            Text { text: "RAM"; color: "#bac2de"; font.family: sans; font.pixelSize: 12; font.weight: Font.SemiBold }
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: ramUsed + "/" + ramTotal + "G"
                            color: "#cdd6f4"; font.family: mono; font.pixelSize: 11; font.weight: Font.DemiBold
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true; height: 7; radius: 4; color: surf0
                        Rectangle {
                            width: parent.width * (ramPct / 100)
                            height: parent.height; radius: parent.radius
                            color: ramPct>80?"#f38ba8":ramPct>50?"#fab387":"#cba6f7"
                            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 500 } }
                        }
                    }
                }

                // Disk bar
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    RowLayout {
                        Layout.fillWidth: true
                        Row {
                            spacing: 6
                            Text { text: "󰋊"; color: "#a6e3a1"; font.family: mono; font.pixelSize: 13 }
                            Text { text: "Disk"; color: "#bac2de"; font.family: sans; font.pixelSize: 12; font.weight: Font.SemiBold }
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: diskUsed + "/" + diskTotal
                            color: "#cdd6f4"; font.family: mono; font.pixelSize: 11; font.weight: Font.DemiBold
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true; height: 7; radius: 4; color: surf0
                        Rectangle {
                            width: parent.width * (diskPct / 100)
                            height: parent.height; radius: parent.radius
                            color: diskPct>80?"#f38ba8":diskPct>50?"#fab387":"#a6e3a1"
                            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 500 } }
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════
        // 4. UPTIME CARD
        // ═══════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 60
            radius: 16
            color: cardBg
            border.width: 1
            border.color: cardBorder

            Row {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰅐"
                    color: "#fab387"
                    font.family: mono
                    font.pixelSize: 22
                }

                ColumnLayout {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        text: "UPTIME"
                        color: "#6c7086"
                        font.family: sans
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }

                    Text {
                        id: uptimeLabel
                        text: uptimeText
                        color: "#cdd6f4"
                        font.family: mono
                        font.pixelSize: 16
                        font.weight: Font.Bold

                        Behavior on text {
                            SequentialAnimation {
                                PropertyAnimation { target: uptimeLabel; property: "opacity"; to: 0; duration: 150 }
                                PropertyAction {}
                                PropertyAnimation { target: uptimeLabel; property: "opacity"; to: 1; duration: 150 }
                            }
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════
        // 5. CALENDAR CARD
        // ═══════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: calCol.implicitHeight + 32
            radius: 16
            color: cardBg
            border.width: 1
            border.color: cardBorder

            ColumnLayout {
                id: calCol
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                // Title
                Text {
                    text: "CALENDAR"
                    color: "#6c7086"
                    font.family: sans; font.pixelSize: 10; font.weight: Font.Bold
                }

                // Month nav
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "󰅁"; color: pmMouse.containsMouse ? "#cdd6f4" : "#a6adc8"
                        font.family: mono; font.pixelSize: 14
                        Behavior on color { ColorAnimation { duration: 150 } }
                        MouseArea { id: pmMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (calViewMonth===0){calViewMonth=11;calViewYear--;} else calViewMonth--;
                            }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: monthName(calViewMonth) + "  " + calViewYear
                        color: "#cba6f7"; font.family: sans; font.pixelSize: 12; font.weight: Font.Bold
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { calViewMonth=now.getMonth(); calViewYear=now.getFullYear(); }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "󰅂"; color: nmMouse.containsMouse ? "#cdd6f4" : "#a6adc8"
                        font.family: mono; font.pixelSize: 14
                        Behavior on color { ColorAnimation { duration: 150 } }
                        MouseArea { id: nmMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (calViewMonth===11){calViewMonth=0;calViewYear++;} else calViewMonth++;
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
                            width: (320 - 32) / 7
                            text: modelData; color: "#f9e2af"
                            font.family: sans; font.pixelSize: 9; font.weight: Font.Bold
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                // Day grid
                Grid {
                    Layout.fillWidth: true
                    columns: 7

                    Repeater {
                        model: calDays()
                        Rectangle {
                            width: (320 - 32) / 7; height: 26; radius: 13
                            color: modelData.today ? "#cba6f7"
                                 : dayMouse.containsMouse && modelData.cur ? Qt.rgba(1,1,1,0.07) : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.d
                                color: modelData.today ? "#1e1e2e"
                                     : modelData.cur  ? "#cdd6f4" : "#45475a"
                                font.family: mono; font.pixelSize: 10
                                font.weight: modelData.today ? Font.Bold : Font.Normal
                            }
                            MouseArea { id: dayMouse; anchors.fill: parent; hoverEnabled: true }
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════
        // 6. MEDIA PLAYER CARD
        // ═══════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: mediaCol.implicitHeight + 32
            radius: 16
            color: cardBg
            border.width: 1
            border.color: cardBorder
            clip: true

            // Subtle glow when playing
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                opacity: mediaStatus === "Playing" ? 0.07 : 0
                color: "#f5c2e7"
                Behavior on opacity { NumberAnimation { duration: 600 } }
            }

            ColumnLayout {
                id: mediaCol
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                // Title
                Text {
                    text: "NOW PLAYING"
                    color: "#6c7086"
                    font.family: sans; font.pixelSize: 10; font.weight: Font.Bold
                }

                // Album art + info row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // Album art
                    Rectangle {
                        Layout.preferredWidth: 60
                        Layout.preferredHeight: 60
                        radius: 10
                        color: surf0
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: mediaArtUrl
                            fillMode: Image.PreserveAspectCrop
                            visible: mediaArtUrl !== ""
                            asynchronous: true
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "󰎆"; color: "#45475a"
                            font.family: mono; font.pixelSize: 24
                            visible: mediaArtUrl === ""
                        }
                    }

                    // Track info
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 3

                        Text {
                            Layout.fillWidth: true
                            text: mediaTitle || "Nothing playing"
                            color: "#cdd6f4"
                            font.family: sans; font.pixelSize: 13; font.weight: Font.Bold
                            elide: Text.ElideRight; maximumLineCount: 1
                            Behavior on text {
                                SequentialAnimation {
                                    PropertyAnimation { property: "opacity"; to: 0; duration: 150 }
                                    PropertyAction {}
                                    PropertyAnimation { property: "opacity"; to: 1; duration: 150 }
                                }
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: mediaArtist || "Unknown artist"
                            color: "#a6adc8"
                            font.family: sans; font.pixelSize: 11
                            elide: Text.ElideRight; maximumLineCount: 1
                        }

                        // Status badge
                        Rectangle {
                            height: 18; radius: 9
                            width: statusLbl.implicitWidth + 16
                            color: mediaStatus === "Playing" ? Qt.rgba(0.965, 0.762, 0.906, 0.15) : Qt.rgba(1,1,1,0.04)
                            Behavior on color { ColorAnimation { duration: 300 } }

                            Text {
                                id: statusLbl
                                anchors.centerIn: parent
                                text: mediaStatus === "Playing" ? "● Playing" : mediaStatus === "Paused" ? "⏸ Paused" : "■ Stopped"
                                color: mediaStatus === "Playing" ? "#f5c2e7" : "#585b70"
                                font.family: sans; font.pixelSize: 9; font.weight: Font.SemiBold
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                        }
                    }
                }

                // Progress bar
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 3

                    Rectangle {
                        Layout.fillWidth: true; height: 4; radius: 2; color: surf0

                        Rectangle {
                            width: mediaLen > 0 ? parent.width * (mediaPos / mediaLen) : 0
                            height: parent.height; radius: 2
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#cba6f7" }
                                GradientStop { position: 1.0; color: "#f5c2e7" }
                            }
                            Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.Linear } }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: fmtTime(mediaPos); color: "#585b70"; font.family: mono; font.pixelSize: 9 }
                        Item { Layout.fillWidth: true }
                        Text { text: fmtTime(mediaLen); color: "#585b70"; font.family: mono; font.pixelSize: 9 }
                    }
                }

                // Controls
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 24

                    Text {
                        text: "󰒮"
                        color: prM.containsMouse ? "#cdd6f4" : "#a6adc8"
                        font.family: mono; font.pixelSize: 20
                        Behavior on color { ColorAnimation { duration: 150 } }
                        scale: prM.pressed ? 0.85 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        MouseArea { id: prM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: prevP.running = true }
                    }

                    Rectangle {
                        width: 40; height: 40; radius: 20
                        color: ppM.containsMouse ? "#ddb6f2" : "#cba6f7"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        scale: ppM.pressed ? 0.88 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: mediaStatus === "Playing" ? "󰏤" : "󰐊"
                            color: "#1e1e2e"; font.family: mono; font.pixelSize: 18
                        }
                        MouseArea { id: ppM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: playP.running = true }
                    }

                    Text {
                        text: "󰒭"
                        color: nxM.containsMouse ? "#cdd6f4" : "#a6adc8"
                        font.family: mono; font.pixelSize: 20
                        Behavior on color { ColorAnimation { duration: 150 } }
                        scale: nxM.pressed ? 0.85 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        MouseArea { id: nxM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: nextP.running = true }
                    }
                }
            }
        }
    }

    // Processes
    Process { id: prevP; command: ["playerctl", "previous"] }
    Process { id: playP; command: ["playerctl", "play-pause"] }
    Process { id: nextP; command: ["playerctl", "next"] }
}
