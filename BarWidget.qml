import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "kiryuuki.oma-chroma"

  readonly property string stateDir: (Quickshell.env("HOME") || "") + "/.local/state/omarchy/chroma"
  readonly property string stateFilePath: stateDir + "/status.json"

  property var chromaState: ({
    version: 1,
    currentTheme: "Solitude",
    currentCursor: "default",
    currentCursorSize: 24,
    timerHours: 0,
    timerMode: "combo",
    selectedThemes: [],
    selectedCursors: [],
    themes: [],
    cursors: [],
    sources: [],
    customSources: [],
    customCursorSources: []
  })

  readonly property string currentThemeName: (chromaState && chromaState.currentTheme) ? chromaState.currentTheme : "Solitude"
  readonly property real activeTimerHours: (chromaState && chromaState.timerHours !== undefined) ? chromaState.timerHours : 0
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
    if ("chromaData" in target) target.chromaData = root.chromaState
  }

  function togglePanel() {
    if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
  }

  function open() {
    if (panelLoader.item && panelLoader.item.open) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item && panelLoader.item.close) panelLoader.item.close()
  }

  function refresh() {
    if (!pollProcess.running) {
      pollProcess.running = true
    }
  }

  function triggerRandomize(mode) {
    pollProcess.command = [
      "/usr/bin/python3",
      (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/kiryuuki.oma-chroma/scripts/chroma_engine.py",
      "--randomize",
      mode || "combo"
    ]
    pollProcess.running = true
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  FileView {
    id: stateFile
    path: root.stateFilePath
    watchChanges: true
    printErrors: false
    onLoaded: {
      try {
        var parsed = JSON.parse(text())
        if (parsed && typeof parsed === "object") {
          root.chromaState = parsed
          root.injectPanel()
        }
      } catch (e) {}
    }
    onFileChanged: reload()
  }

  Process {
    id: pollProcess
    command: ["/usr/bin/python3", (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/kiryuuki.oma-chroma/scripts/chroma_engine.py", "--poll"]
    onExited: function(code) {
      stateFile.reload()
      root.injectPanel()
    }
  }

  Process {
    id: checkTimerProcess
    onExited: function(code) {
      stateFile.reload()
      root.injectPanel()
    }
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

  Timer {
    id: initialPollTimer
    interval: 300
    running: true
    repeat: false
    onTriggered: root.refresh()
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  IpcHandler {
    target: "kiryuuki.oma-chroma"

    function refresh(): void { root.refresh() }
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.togglePanel() }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰔎"
    foreground: root.opened ? Color.accent : (root.bar ? root.bar.barForeground : Color.foreground)
    slotSize: Style.bar.statusSlot
    tooltipText: "OmaChroma: " + root.currentThemeName + " · " + root.chromaState.currentCursor + " (" + root.chromaState.currentCursorSize + "px)"

    onPressed: function(b) {
      if (!root.bar) return
      if (b === Qt.MiddleButton) root.refresh()
      else root.togglePanel()
    }
  }
}
