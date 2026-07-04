import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Scope {
  id: root
  //Theme
  property color colBg: "#1a1b26"
  property color colMuted: "#444b6a"
  property color colCyan: "#0db9d7"
  property color colBlue: "#7aa2f7"
  property color colYellow: "#e0af68"
  property string fontFamily: "JetBrains Mono NF"
  property int fontSize: 16

  //SystemInfo
  property int cpuUsage: 0
  property var lastCpuIdle: 0
  property var lastCpuTotal: 0
  property int memUsage: 0
  property int battery: 0
  property string batteryStatus: "discharging"
  property int volume: 0
  property bool muted: false
  property bool ethernetConnected: false
  property bool wifiConnected: false

  function getBatteryIcon() {
    if (batteryStatus == "charging") {
      return "󰂄"
    }

    if (batteryStatus == "fully-charged") {
      return "󱈏"
    }

    switch (true) {
      case battery <= 10:
      return "󰂃"
      case battery <= 20:
      return "󰁻"
      case battery <= 30:
      return "󰁼"
      case battery <= 40:
      return "󰁽"
      case battery <= 50:
      return "󰁾"
      case battery <= 60:
      return "󰁿"
      case battery <= 70:
      return "󰂀"
      case battery <= 80:
      return "󰂁"
      case battery <= 90:
      return "󰂂"
      case battery <= 100:
      return "󱈏"
      default:
      return "󱉞"
    }
  }

  Variants {
    model: Quickshell.screens;

    PanelWindow {

      required property var modelData

      screen: modelData

      anchors.top: true
      anchors.left: true
      anchors.right: true
      implicitHeight: 30
      color: root.colBg

      RowLayout {
        anchors.fill: parent

        anchors.margins: 8

        Repeater {
          model: 10

          Text {

            property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
            property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)

            text: index + 1
            color: isActive ? root.colCyan : (ws ? root.colBlue : root.colMuted)
            font { family:root.fontFamily; pixelSize: root.fontSize; bold: true }

            MouseArea {
              anchors.fill: parent
              onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${index+1} })`)
            }
          }
        }

        Item { Layout.fillWidth: true }

        Text {
          property var activeWindow: Hyprland.toplevels.values.find(t => t.activated || t.focused)

          text: activeWindow ? activeWindow.title : "None"
          color: "white"
          font { family: root.fontFamily; pixelSize: 14; bold:true }
        }

        Item { Layout.fillWidth: true }

        Text {
          text: "CPU: " + cpuUsage + "%"
          color: root.colYellow
          font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
        }

        Rectangle { width: 1; height: 16; color: root.colMuted }

        Text {
          text: "Mem: " + memUsage + "%"
          color: root.colCyan
          font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
        }

        Rectangle { width: 1; height: 16; color: root.colMuted }

        Text {
          id: clock
          text: Qt.formatDateTime(new Date(), "ddd, MMM dd - HH:mm")
          color: root.colBlue
          font { family: root.fontFamily; pixelSize: 14; bold: true }

          Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd, MMM dd - HH:mm")
          }
        }

        Rectangle {
          width: 40
          height: 16
          color: "gray"
          radius: 5

          Text {
            anchors.centerIn: parent
            text: root.ethernetConnected ? "" : root.wifiConnected ? "󰖩" : "󰖪"
            color: "white"
            font { family: root.fontFamily; pixelSize: 14; bold:true }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onEntered: {
              parent.color = "darkgray"
            }

            onExited: {
              parent.color = "gray"
            }

            onClicked: Quickshell.execDetached(["orbit", "toggle", "top-right"])
          }
        }

        Rectangle {
          width: 70
          height: 16
          color: "gray"
          radius: 5

          Text {
            anchors.centerIn: parent
            text: root.volume + "% " + (root.muted ? "󰝟" : "󰕾")
            color: "white"
            font { family: root.fontFamily; pixelSize: 14; bold: true }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onEntered: {
              parent.color = "darkgray"
            }

            onExited: {
              parent.color = "gray"
            }
            onClicked: mouse => {
              if (mouse.button === Qt.LeftButton) {
                Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
              } else {
                Quickshell.execDetached(["pavucontrol"])
              }
            }

            onWheel: (wheel) => {
              var delta = wheel.angleDelta.y

              if (delta > 0) {
                if (root.volume < 100) {
                  Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", "1%+"])
                }
              } else {
                Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "1%-"])
              }

              wheel.accepted = true;
            }
          }
        }

        Rectangle {
          width: 70
          height: 16
          color: "gray"
          radius: 5

          Text {
            anchors.centerIn: parent
            text:  battery + "% " + root.getBatteryIcon()
            color: "white"
            font { family: root.fontFamily; pixelSize: 14; bold: true }
          }
        }

      }
    }
  }

  Process {
    id: cpuProc
    command: ["sh", "-c", "head -1 /proc/stat"]

    stdout: SplitParser {
      onRead: data => {
        var p = data.trim().split(/\s+/)

        var idle = parseInt(p[4]) + parseInt(p[5])
        var total = p.slice(1,8).reduce((a,b) => a + parseInt(b),0)
        if (lastCpuTotal > 0) {
          cpuUsage = Math.round(100 * (1 - (idle - lastCpuIdle) / (total - lastCpuTotal)))
        }
        lastCpuTotal = total
        lastCpuIdle = idle
      }
    }

    Component.onCompleted: running = true
  }

  Process {
    id: memProc
    command: ["sh", "-c", "free | grep Mem"]
    stdout: SplitParser {
      onRead: data => {
        var parts = data.trim().split(/\s+/)
        var total = parseInt(parts[1]) || 1
        var used = parseInt(parts[2]) || 0
        memUsage = Math.round(100 * used / total)
      }
    }

    Component.onCompleted: running = true
  }

  Process {
    id: batteryProc
    command: ["sh", "-c", "upower -i /org/freedesktop/UPower/devices/battery_BAT1 | grep -E 'state|percentage' | paste -s -d' '"]
    stdout: SplitParser {
      onRead: data => {
        var parts = data.trim().split(/\s+/)
        var batteryAmount = parts[3].slice(0,-1)
        battery = parseInt(batteryAmount)
        batteryStatus = parts[1]
      }
    }

    Component.onCompleted: running = true
  }

  Process {
    id: volumeMonitor
    command: ["pactl", "subscribe"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        if (data.includes("sink")) {
          volumeProc.running = true
        }
      }
    }
  }

  Process {
    id: volumeProc
    command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
    stdout: SplitParser {
      onRead: data => {
        var parts = data.trim().split(/\s+/)
        var volume = parseFloat(parts[1]) * 100

        root.muted = parts.length > 2 ? true : false

        root.volume = Math.floor(volume)
      }
    }

    Component.onCompleted: running = true
  }

  Process {
    id: networkMonitor
    command: ["sh", "-c", "nmcli monitor"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        root.wifiConnected = false;
        root.ethernetConnected = false;
        networkProc.running = true
      }
    }
  }

  Process {
    id: networkProc
    command: ["sh", "-c", "nmcli -t -f DEVICE,TYPE,STATE device status | grep -E 'wifi:|ethernet:'"]
    stdout: SplitParser {
      onRead: data => {
        var parts = data.trim().split(":")

        var type = parts[1]
        var status = parts[2]

        if (type === "wifi" && !root.wifiConnected && status === "connected") {
          root.wifiConnected = true
        }

        if (type === "ethernet" && !root.ethernetConnected && status === "connected") {
          root.ethernetConnected = true
        }

      }
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: {
      cpuProc.running = true
      memProc.running = true
      batteryProc.running = true
    }
  }
}
