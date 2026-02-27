import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

Item {
    id: clockRoot
    Layout.preferredWidth: clockPill.width
    Layout.preferredHeight: 32

    property string timeText: ""
    property string dateText: ""
    property bool showDate: false

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var d = new Date();
            var h = d.getHours();
            var m = d.getMinutes();
            var ampm = h >= 12 ? "PM" : "AM";
            h = h % 12;
            if (h === 0) h = 12;
            clockRoot.timeText = "󰅐  " + (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m + " " + ampm;

            var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
            var months = ["January", "February", "March", "April", "May", "June",
                          "July", "August", "September", "October", "November", "December"];
            clockRoot.dateText = "󰃶  " + days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate();
        }
    }

    // Teal pill matching Waybar #clock
    Rectangle {
        id: clockPill
        width: clockLabel.implicitWidth + 40
        height: 32
        radius: 10
        color: clockMouse.containsMouse ? "#89dceb" : "#94e2d5"  // sky on hover, teal default
        anchors.verticalCenter: parent.verticalCenter

        Behavior on color { ColorAnimation { duration: 250 } }

        Text {
            id: clockLabel
            anchors.centerIn: parent
            text: clockRoot.showDate ? clockRoot.dateText : clockRoot.timeText
            color: "#1e1e2e"
            font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
            font.pixelSize: 13
            font.weight: Font.Bold
        }

        MouseArea {
            id: clockMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: shell.togglePopup("clock")
        }
    }
}
