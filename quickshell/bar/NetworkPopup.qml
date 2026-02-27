import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."

PanelWindow {
    id: netPopup

    anchors { top: true; bottom: true; left: true; right: true }
    margins.top: 0

    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "quickshell-network-popup"
    WlrLayershell.keyboardFocus: WlrLayershell.OnDemand
    exclusiveZone: 0

    property bool animOpen: false
    visible: animOpen

    Connections {
        target: shell
        function onNetworkPopupOpenChanged() {
            if (shell.networkPopupOpen) {
                netPopup.animOpen = true
            } else {
                netCloseTimer.restart()
            }
        }
    }

    Timer { id: netCloseTimer; interval: 320; onTriggered: netPopup.animOpen = false }

    property int popupHeight: 360

    property var wifiNetworks: []
    property string currentSsid: ""
    property var btDevices: []
    property bool btPowered: false

    Timer {
        interval: 3000; running: shell.networkPopupOpen; repeat: true; triggeredOnStart: true
        onTriggered: { wifiProc.running = true; btProc.running = true }
    }

    Process {
        id: wifiProc
        command: ["sh", "-c", "nmcli -t -f SSID,SIGNAL,SECURITY,IN-USE dev wifi list 2>/dev/null | head -15"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                var lines = data.trim().split("\n"), networks = [], current = "";
                for (var i = 0; i < lines.length; i++) {
                    var p = lines[i].split(":");
                    if (p.length >= 3) {
                        var ssid=p[0]||"", signal=parseInt(p[1])||0, security=p[2]||"", inUse=p[3]==="*";
                        if (!ssid) continue;
                        if (inUse) current = ssid;
                        networks.push({ssid:ssid,signal:signal,security:security,connected:inUse});
                    }
                }
                netPopup.wifiNetworks = networks;
                netPopup.currentSsid  = current;
            }
        }
    }

    Process {
        id: btProc
        command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep 'Powered:' | awk '{print $2}'; bluetoothctl devices Connected 2>/dev/null"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                var lines = data.trim().split("\n");
                if (lines.length > 0) netPopup.btPowered = lines[0].trim() === "yes";
                var devs = [];
                for (var i = 1; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.startsWith("Device ")) {
                        var p = line.substring(7).split(" ");
                        devs.push({name:p.slice(1).join(" ")||"Unknown", mac:p[0]||""});
                    }
                }
                netPopup.btDevices = devs;
            }
        }
    }

    function wifiIcon(sig) {
        if (sig>75) return "󰤨"; if (sig>50) return "󰤥"; if (sig>25) return "󰤢"; return "󰤟";
    }

    // ── Outside click dismiss ──
    MouseArea { anchors.fill: parent; onClicked: shell.closeAllPopups() }

    // ── Content anchored to right ──
    Item {
        anchors.right: parent.right
        anchors.rightMargin: 100
        y: 0
        width: 310
        height: netPopup.popupHeight
        clip: true

        Rectangle {
            id: netSlide
            width: parent.width; height: parent.height
            radius: 14; color: "#1e1e2e"

            Rectangle { anchors.top:parent.top; anchors.left:parent.left; anchors.right:parent.right; height:14; color:parent.color }

            y: shell.networkPopupOpen ? 0 : -height
            Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 10; anchors.leftMargin: 14; anchors.rightMargin: 14; anchors.bottomMargin: 12
                spacing: 10

                // WiFi header
                RowLayout {
                    Layout.fillWidth: true
                    Text { text:"󰖩"; color:"#cba6f7"; font.family:"JetBrainsMono Nerd Font, JetBrains Mono, monospace"; font.pixelSize:16 }
                    Text { text:"Wi-Fi"; color:"#cdd6f4"; font.family:"JetBrainsMono Nerd Font, JetBrains Mono, monospace"; font.pixelSize:13; font.weight:Font.Bold }
                    Item { Layout.fillWidth: true }
                    Text { text:netPopup.currentSsid||"Disconnected"; color:"#a6adc8"; font.family:"JetBrainsMono Nerd Font, JetBrains Mono, monospace"; font.pixelSize:10 }
                }

                // WiFi list
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight:Math.min(wifiList.contentHeight+8,150)
                    radius:10; color:"#313244"; clip:true
                    ListView {
                        id: wifiList; anchors.fill:parent; anchors.margins:4; model:netPopup.wifiNetworks; spacing:2; interactive:contentHeight>height
                        delegate: Rectangle {
                            width:wifiList.width; height:30; radius:8
                            color:modelData.connected?Qt.rgba(0.796,0.651,0.969,0.12):wfM.containsMouse?Qt.rgba(1,1,1,0.04):"transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            RowLayout { anchors.fill:parent; anchors.leftMargin:8; anchors.rightMargin:8; spacing:6
                                Text { text:netPopup.wifiIcon(modelData.signal); color:modelData.connected?"#cba6f7":"#585b70"; font.family:"JetBrainsMono Nerd Font, JetBrains Mono, monospace"; font.pixelSize:13 }
                                Text { Layout.fillWidth:true; text:modelData.ssid; color:modelData.connected?"#cdd6f4":"#a6adc8"; font.family:"JetBrainsMono Nerd Font, JetBrains Mono, monospace"; font.pixelSize:11; font.weight:modelData.connected?Font.Bold:Font.Normal; elide:Text.ElideRight }
                                Text { text:modelData.security!=""?"󰌾":""; color:"#585b70"; font.family:"JetBrainsMono Nerd Font, JetBrains Mono, monospace"; font.pixelSize:11; visible:modelData.security!="" }
                                Text { text:modelData.signal+"%"; color:"#585b70"; font.family:"JetBrainsMono Nerd Font, JetBrains Mono, monospace"; font.pixelSize:9 }
                            }
                            MouseArea { id:wfM; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor; onClicked:{ if(!modelData.connected){wifiConnP.command=["nmcli","device","wifi","connect",modelData.ssid];wifiConnP.running=true;} } }
                        }
                    }
                }

                Rectangle { Layout.fillWidth:true; Layout.preferredHeight:1; color:"#313244" }

                // Bluetooth header + toggle
                RowLayout {
                    Layout.fillWidth: true
                    Text { text:"󰂯"; color:"#b4befe"; font.family:"JetBrainsMono Nerd Font, JetBrains Mono, monospace"; font.pixelSize:16 }
                    Text { text:"Bluetooth"; color:"#cdd6f4"; font.family:"JetBrainsMono Nerd Font, JetBrains Mono, monospace"; font.pixelSize:13; font.weight:Font.Bold }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width:36; height:20; radius:10
                        color:netPopup.btPowered?"#cba6f7":"#45475a"
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Rectangle { width:16; height:16; radius:8; color:"#cdd6f4"; y:2; x:netPopup.btPowered?parent.width-width-2:2; Behavior on x{NumberAnimation{duration:200;easing.type:Easing.OutCubic}} }
                        MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked:{ btToggleP.command=["bluetoothctl","power",netPopup.btPowered?"off":"on"]; btToggleP.running=true; netPopup.btPowered=!netPopup.btPowered; } }
                    }
                }

                // BT devices
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight:btCol.implicitHeight+12; Layout.minimumHeight:36
                    radius:10; color:"#313244"
                    ColumnLayout { id:btCol; anchors.fill:parent; anchors.margins:8; spacing:4
                        Repeater { model:netPopup.btDevices
                            RowLayout { Layout.fillWidth:true; spacing:6
                                Text { text:"󰂱"; color:"#b4befe"; font.family:"JetBrainsMono Nerd Font, JetBrains Mono, monospace"; font.pixelSize:13 }
                                Text { Layout.fillWidth:true; text:modelData.name; color:"#cdd6f4"; font.family:"JetBrainsMono Nerd Font, JetBrains Mono, monospace"; font.pixelSize:10; elide:Text.ElideRight }
                                Text { text:"Connected"; color:"#a6e3a1"; font.family:"JetBrainsMono Nerd Font, JetBrains Mono, monospace"; font.pixelSize:9 }
                            }
                        }
                        Text { Layout.alignment:Qt.AlignHCenter; visible:netPopup.btDevices.length===0; text:netPopup.btPowered?"No devices connected":"Bluetooth is off"; color:"#585b70"; font.family:"JetBrainsMono Nerd Font, JetBrains Mono, monospace"; font.pixelSize:10 }
                    }
                }

                // Quick actions
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 30; radius: 8
                        color: sbM.containsMouse ? "#45475a" : "#313244"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: "󰒓  Settings"; color: "#cdd6f4"
                            font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"; font.pixelSize: 10
                        }
                        MouseArea {
                            id: sbM; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor; onClicked: nmEdP.running = true
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 30; radius: 8
                        color: bbM.containsMouse ? "#45475a" : "#313244"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: "󰂯  Bluetooth"; color: "#cdd6f4"
                            font.family: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"; font.pixelSize: 10
                        }
                        MouseArea {
                            id: bbM; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor; onClicked: blumanP.running = true
                        }
                    }
                }
            }
        }
    }

    Process { id:wifiConnP; command:["echo"] }
    Process { id:btToggleP; command:["echo"] }
    Process { id:nmEdP;     command:["nm-connection-editor"] }
    Process { id:blumanP;   command:["blueman-manager"] }
}
