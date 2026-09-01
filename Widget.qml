import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Item {
  id: root
  implicitWidth: pillSurface.implicitWidth
  implicitHeight: bar ? bar.height : 30

  property var pluginItem: null
  property var bar: null
  readonly property var chromaState: stateFileView.value || ({})

  function refresh() {
    stateReader.running = true
  }

  function setTimer(hours) {
    timerProcess.command = [
      "/usr/bin/python3",
      (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/kiryuuki.oma-chroma/scripts/chroma_engine.py",
      "--set-timer",
      String(hours)
    ]
    timerProcess.running = true
  }

  function triggerRandomize(mode) {
    timerProcess.command = [
      "/usr/bin/python3",
      (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/kiryuuki.oma-chroma/scripts/chroma_engine.py",
      "--randomize",
      mode || "combo"
    ]
    timerProcess.running = true
  }

  // Periodic Timer Tick: Checks every 60s if background timer interval elapsed
  Timer {
    id: backgroundSchedulerTimer
    interval: 60000
    running: true
    repeat: true
    onTriggered: {
      var th = (root.chromaState && root.chromaState.timerHours) ? root.chromaState.timerHours : 0
      if (th > 0) {
        checkTimerProcess.command = [
          "/usr/bin/python3",
          (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/kiryuuki.oma-chroma/scripts/chroma_engine.py",
          "--check-timer"
        ]
        checkTimerProcess.running = true
      }
    }
  }

  Process {
    id: checkTimerProcess
    onExited: function(code) {
      root.refresh()
    }
  }

  Process {
    id: timerProcess
    onExited: function(code) {
      root.refresh()
    }
  }

  Process {
    id: stateReader
    command: [
      "/usr/bin/python3",
      (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/kiryuuki.oma-chroma/scripts/chroma_engine.py",
      "--poll"
    ]
    running: true
  }

  FileView {
    id: stateFileView
    path: (Quickshell.env("HOME") || "") + "/.local/state/omarchy/chroma/status.json"
    watchChanges: true
    parser: JsonParser {}
  }

  readonly property string currentThemeName: (chromaState && chromaState.currentTheme) ? chromaState.currentTheme : "Solitude"
  readonly property string currentCursorName: (chromaState && chromaState.currentCursor) ? chromaState.currentCursor : "Bibata"
  readonly property var activeTimerHours: (chromaState && chromaState.timerHours) ? chromaState.timerHours : 0

  BorderSurface {
    id: pillSurface
    anchors.verticalCenter: parent.verticalCenter
    implicitHeight: Math.max(22, (bar ? bar.height : 30) - Style.space(6))
    implicitWidth: pillRow.implicitWidth + Style.space(12)
    radius: Style.cornerRadius
    color: mouseArea.containsMouse
      ? Style.hoverFillFor(bar ? bar.foreground : Color.foreground, bar ? bar.foreground : Color.foreground)
      : "transparent"
    borderSpec: Border.controlSpec(
      mouseArea.containsMouse ? "hover" : "normal",
      activeTimerHours > 0 ? Color.accent : (bar ? Qt.darker(bar.foreground, 2.5) : Color.border),
      Color.accent
    )

    Row {
      id: pillRow
      anchors.centerIn: parent
      spacing: Style.space(5)

      Text {
        textFormat: Text.PlainText
        text: "󰔎"
        font.family: bar ? bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        color: Color.accent
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        textFormat: Text.PlainText
        text: currentThemeName
        font.family: bar ? bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
        color: bar ? bar.foreground : Color.foreground
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        maximumLineCount: 1
      }

      // Active Timer Badge Indicator
      Rectangle {
        visible: activeTimerHours > 0
        implicitWidth: timerBadgeText.implicitWidth + 8
        implicitHeight: 14
        radius: 4
        color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.25)
        border.width: 1
        border.color: Color.accent
        anchors.verticalCenter: parent.verticalCenter

        Text {
          id: timerBadgeText
          anchors.centerIn: parent
          textFormat: Text.PlainText
          text: "󱑂 " + activeTimerHours + "h"
          font.family: "Monospace"
          font.pixelSize: 8
          font.bold: true
          color: Color.accent
        }
      }
    }

    MouseArea {
      id: mouseArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) {
          root.triggerRandomize("combo")
        } else {
          PanelManager.openPanel("kiryuuki.oma-chroma", root, { hostWidget: root })
        }
      }
    }
  }
}
