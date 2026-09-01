import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "kiryuuki.oma-chroma"
  ipcTarget: "kiryuuki.oma-chroma"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property color contentSubtle: Qt.rgba(contentForeground.r, contentForeground.g, contentForeground.b, 0.65)

  property var chromaData: hostWidget && hostWidget.chromaState ? hostWidget.chromaState : ({
    version: 1,
    currentTheme: "Solitude",
    currentCursor: "Bibata-Modern-Ice",
    currentCursorSize: 24,
    currentWallpaper: "Default",
    randomizeWallpaper: true,
    selectedThemes: [],
    selectedCursors: [],
    customSources: [],
    themes: [],
    cursors: [],
    userInstalled: [],
    themeSources: [],
    cursorSources: []
  })

  // 0: Themes, 1: Cursors, 2: Randomizer, 3: Themes Store, 4: Cursors Store, 5: Installed
  property int activeTab: 2
  property int selectedIndex: 0
  
  // Dedicated Pagination state for each tab (10 items per page)
  property int themePage: 0
  property int cursorPage: 0
  property int storePage: 0
  readonly property int itemsPerPage: 10
  
  property string statusNotice: ""
  property string activeActionId: ""
  property bool isActionRunning: false
  
  // Custom Source inputs & edit mode
  property string customCursorSourceInput: ""
  property string customCursorSourceNameInput: ""
  property string editingCursorSourceId: ""
  readonly property var customCursorSourcesList: (root.chromaData && root.chromaData.customCursorSources) ? root.chromaData.customCursorSources : []
  property string customSourceInput: ""
  property string customSourceNameInput: ""
  property string customTimerHoursInput: ""
  readonly property real currentTimerHours: (root.chromaData && root.chromaData.timerHours !== undefined) ? root.chromaData.timerHours : 0
  property string editingSourceId: ""

  readonly property var visibleThemes: (root.chromaData && root.chromaData.themes) ? root.chromaData.themes : []
  readonly property var visibleCursors: (root.chromaData && root.chromaData.cursors) ? root.chromaData.cursors : []
  readonly property var userInstalledList: (root.chromaData && root.chromaData.userInstalled) ? root.chromaData.userInstalled : []
  readonly property var themeSourcesList: (root.chromaData && root.chromaData.themeSources) ? root.chromaData.themeSources : []
  readonly property var cursorSourcesList: (root.chromaData && root.chromaData.cursorSources) ? root.chromaData.cursorSources : []
  readonly property var customSourcesList: (root.chromaData && root.chromaData.customSources) ? root.chromaData.customSources : []

  // Calculated pagination slices
  readonly property int totalThemePages: Math.max(1, Math.ceil(root.visibleThemes.length / root.itemsPerPage))
  readonly property var pagedThemes: {
    var s = root.themePage * root.itemsPerPage
    return root.visibleThemes.slice(s, s + root.itemsPerPage)
  }

  readonly property int totalCursorPages: Math.max(1, Math.ceil(root.visibleCursors.length / root.itemsPerPage))
  readonly property var pagedCursors: {
    var s = root.cursorPage * root.itemsPerPage
    return root.visibleCursors.slice(s, s + root.itemsPerPage)
  }

  readonly property int totalStorePages: Math.max(1, Math.ceil(root.themeSourcesList.length / root.itemsPerPage))
  readonly property var pagedThemeSources: {
    var s = root.storePage * root.itemsPerPage
    return root.themeSourcesList.slice(s, s + root.itemsPerPage)
  }

  function open() { refresh(); root.controller.show() }
  function close() { root.controller.hide() }
  function toggle() { if (root.opened) close(); else open(); }
  function refresh() {
    if (hostWidget && hostWidget.refresh) hostWidget.refresh()
  }

  onOpenedChanged: {
    if (root.opened) {
      keyCatcher.forceActiveFocus()
      root.selectedIndex = 0
      root.refresh()
    }
  }

  function applyTheme(name) {
    if (!name || root.isActionRunning) return
    root.isActionRunning = true
    root.activeActionId = "theme:" + name
    root.statusNotice = "Applying " + name + "..."
    noticeTimer.restart()
    actionProcess.command = [
      "/usr/bin/python3",
      (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/kiryuuki.oma-chroma/scripts/chroma_engine.py",
      "--set-theme",
      name
    ]
    actionProcess.running = true
  }

  function applyCursor(id, size) {
    if (!id || root.isActionRunning) return
    var sz = size || (root.chromaData ? root.chromaData.currentCursorSize : 24)
    root.isActionRunning = true
    root.activeActionId = "cursor:" + id
    root.statusNotice = "Setting " + id + " (" + sz + "px)..."
    noticeTimer.restart()
    actionProcess.command = [
      "/usr/bin/python3",
      (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/kiryuuki.oma-chroma/scripts/chroma_engine.py",
      "--set-cursor",
      id,
      "--cursor-size",
      String(sz)
    ]
    actionProcess.running = true
  }

  function setCursorSizeOnly(sz) {
    var cur = (root.chromaData && root.chromaData.currentCursor) ? root.chromaData.currentCursor : "default"
    root.applyCursor(cur, sz)
  }

    function setRandomizerTimer(h) {
    var val = parseFloat(h) || 0
    if (root.chromaData) root.chromaData.timerHours = val
    root.statusNotice = val > 0 ? ("Auto-roll scheduled every " + val + "h") : "Auto-roll disabled"
    noticeTimer.restart()
    actionProcess.command = [
      "/usr/bin/python3",
      (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/kiryuuki.oma-chroma/scripts/chroma_engine.py",
      "--set-timer",
      String(val)
    ]
    actionProcess.running = true
  }

function triggerRandomize(mode) {
    if (root.isActionRunning) return
    root.isActionRunning = true
    root.activeActionId = "rand:" + mode
    root.statusNotice = "Shuffling " + mode + "..."
    noticeTimer.restart()
    actionProcess.command = [
      "/usr/bin/python3",
      (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/kiryuuki.oma-chroma/scripts/chroma_engine.py",
      "--randomize",
      mode
    ]
    actionProcess.running = true
  }

  function nextWallpaper() {
    if (root.isActionRunning) return
    root.isActionRunning = true
    root.statusNotice = "Cycling wallpaper..."
    noticeTimer.restart()
    actionProcess.command = [
      "/usr/bin/python3",
      (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/kiryuuki.oma-chroma/scripts/chroma_engine.py",
      "--next-wallpaper"
    ]
    actionProcess.running = true
  }

  function restartShell() {
    root.statusNotice = "Restarting shell..."
    noticeTimer.restart()
    actionProcess.command = [
      "/usr/bin/python3",
      (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/kiryuuki.oma-chroma/scripts/chroma_engine.py",
      "--restart-shell"
    ]
    actionProcess.running = true
  }

  function downloadThemeSource(item) {
    if (!item || root.isActionRunning) return
    root.isActionRunning = true
    root.activeActionId = "dl:" + item.id
    root.statusNotice = "Downloading " + item.name + "..."
    noticeTimer.restart()
    actionProcess.command = [
      "/usr/bin/python3",
      (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/kiryuuki.oma-chroma/scripts/chroma_engine.py",
      "--install-theme",
      item.url
    ]
    actionProcess.running = true
  }

  function downloadCursorSource(item) {
    if (!item || !item.url || root.isActionRunning) return
    root.isActionRunning = true
    root.activeActionId = "dl:" + item.id
    root.statusNotice = "Downloading " + item.name + "..."
    noticeTimer.restart()
    actionProcess.command = [
      "/usr/bin/python3",
      (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/kiryuuki.oma-chroma/scripts/chroma_engine.py",
      "--install-cursor",
      item.url
    ]
    actionProcess.running = true
  }

  function removeItem(type, id) {
    if (!id || root.isActionRunning) return
    root.isActionRunning = true
    root.activeActionId = "rm:" + id
    root.statusNotice = "Removing " + id + "..."
    noticeTimer.restart()
    actionProcess.command = [
      "/usr/bin/python3",
      (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/kiryuuki.oma-chroma/scripts/chroma_engine.py",
      "--remove-item",
      type,
      id
    ]
    actionProcess.running = true
  }

  function toggleThemeSelection(id) {
    if (!id) return
    if (root.chromaData && root.chromaData.selectedThemes) {
      var arr = root.chromaData.selectedThemes.slice()
      var idx = arr.indexOf(id)
      if (idx >= 0) arr.splice(idx, 1)
      else arr.push(id)
      root.chromaData.selectedThemes = arr
    }
    actionProcess.command = [
      "/usr/bin/python3",
      (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/kiryuuki.oma-chroma/scripts/chroma_engine.py",
      "--toggle-theme-selection",
      id
    ]
    actionProcess.running = true
  }

  function toggleCursorSelection(id) {
    if (!id) return
    if (root.chromaData && root.chromaData.selectedCursors) {
      var arr = root.chromaData.selectedCursors.slice()
      var idx = arr.indexOf(id)
      if (idx >= 0) arr.splice(idx, 1)
      else arr.push(id)
      root.chromaData.selectedCursors = arr
    }
    actionProcess.command = [
      "/usr/bin/python3",
      (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/kiryuuki.oma-chroma/scripts/chroma_engine.py",
      "--toggle-cursor-selection",
      id
    ]
    actionProcess.running = true
  }

  // --- CURSOR SOURCE MANAGEMENT (ADD / EDIT / DELETE) ---
  function addOrSaveCustomCursorSource() {
    var raw = root.customCursorSourceInput.trim()
    if (!raw) return
    
    if (root.editingCursorSourceId) {
      var sName = root.customCursorSourceNameInput.trim() || "Custom Cursor Pack"
      root.statusNotice = "Updating cursor source..."
      noticeTimer.restart()
      actionProcess.command = [
        "/usr/bin/python3",
        (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/kiryuuki.oma-chroma/scripts/chroma_engine.py",
        "--edit-cursor-source",
        root.editingCursorSourceId,
        sName,
        raw
      ]
      actionProcess.running = true
      root.editingCursorSourceId = ""
      root.customCursorSourceInput = ""
      root.customCursorSourceNameInput = ""
    } else {
      var urls = raw.split(/[\n,]+/).map(function(u) { return u.trim() }).filter(function(u) { return u.length > 0 })
      var defName = root.customCursorSourceNameInput.trim()
      root.statusNotice = "Adding " + urls.length + " cursor source(s)..."
      noticeTimer.restart()
      
      for (var i = 0; i < urls.length; i++) {
        var u = urls[i]
        var name = (urls.length === 1 && defName) ? defName : u.split("/").pop().replace(".tar.xz", "").replace(".tar.gz", "").replace(".zip", "")
        actionProcess.command = [
          "/usr/bin/python3",
          (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/kiryuuki.oma-chroma/scripts/chroma_engine.py",
          "--add-cursor-source",
          name,
          u
        ]
        actionProcess.running = true
      }
      root.customCursorSourceInput = ""
      root.customCursorSourceNameInput = ""
    }
  }

  function deleteCustomCursorSource(srcId) {
    if (!srcId) return
    root.statusNotice = "Deleting cursor source..."
    noticeTimer.restart()
    actionProcess.command = [
      "/usr/bin/python3",
      (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/kiryuuki.oma-chroma/scripts/chroma_engine.py",
      "--delete-cursor-source",
      srcId
    ]
    actionProcess.running = true
  }

  function startEditCursorSource(src) {
    if (!src) return
    root.editingCursorSourceId = src.id
    root.customCursorSourceNameInput = src.name
    root.customCursorSourceInput = src.url
  }

  function cancelEditCursorSource() {
    root.editingCursorSourceId = ""
    root.customCursorSourceNameInput = ""
    root.customCursorSourceInput = ""
  }

  // --- SOURCE MANAGEMENT (ADD / EDIT / DELETE) ---
  function addOrSaveCustomSource() {
    var raw = root.customSourceInput.trim()
    if (!raw) return
    
    if (root.editingSourceId) {
      var sName = root.customSourceNameInput.trim() || "Custom Theme"
      root.statusNotice = "Updating source..."
      noticeTimer.restart()
      actionProcess.command = [
        "/usr/bin/python3",
        (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/kiryuuki.oma-chroma/scripts/chroma_engine.py",
        "--edit-source",
        root.editingSourceId,
        sName,
        raw
      ]
      actionProcess.running = true
      root.editingSourceId = ""
      root.customSourceInput = ""
      root.customSourceNameInput = ""
    } else {
      var urls = raw.split(/[\n,]+/).map(function(u) { return u.trim() }).filter(function(u) { return u.length > 0 })
      var defName = root.customSourceNameInput.trim()
      root.statusNotice = "Adding " + urls.length + " source(s)..."
      noticeTimer.restart()
      
      for (var i = 0; i < urls.length; i++) {
        var u = urls[i]
        var name = (urls.length === 1 && defName) ? defName : u.split("/").pop().replace(".git", "")
        actionProcess.command = [
          "/usr/bin/python3",
          (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/kiryuuki.oma-chroma/scripts/chroma_engine.py",
          "--add-source",
          name,
          u
        ]
        actionProcess.running = true
      }
      root.customSourceInput = ""
      root.customSourceNameInput = ""
    }
  }

  function deleteCustomSource(srcId) {
    if (!srcId) return
    root.statusNotice = "Deleting source..."
    noticeTimer.restart()
    actionProcess.command = [
      "/usr/bin/python3",
      (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/kiryuuki.oma-chroma/scripts/chroma_engine.py",
      "--delete-source",
      srcId
    ]
    actionProcess.running = true
  }

  function startEditSource(src) {
    if (!src) return
    root.editingSourceId = src.id
    root.customSourceNameInput = src.name
    root.customSourceInput = src.url
  }

  function cancelEditSource() {
    root.editingSourceId = ""
    root.customSourceNameInput = ""
    root.customSourceInput = ""
  }

  Process {
    id: actionProcess
    onExited: function(code) {
      root.isActionRunning = false
      root.activeActionId = ""
      root.refresh()
    }
  }

  Timer {
    id: noticeTimer
    interval: 3500
    repeat: false
    onTriggered: root.statusNotice = ""
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(980))
    contentHeight: panel.fittedContentHeight(mainColumn.implicitHeight, Style.space(860))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: customHoursInput.activeFocus || sourceNameInput.activeFocus || sourceUrlInput.activeFocus || cursorSourceNameInput.activeFocus || cursorSourceUrlInput.activeFocus
      onCloseRequested: root.close()
      onMoveRequested: function(dx, dy) {
        if (dy !== 0) {
          var count = (root.activeTab === 0) ? root.pagedThemes.length : ((root.activeTab === 1) ? root.pagedCursors.length : 0)
          if (count > 0) {
            root.selectedIndex = Math.max(0, Math.min(count - 1, root.selectedIndex + dy))
          }
        }
      }
      onActivateRequested: {
        if (root.activeTab === 0 && root.pagedThemes[root.selectedIndex]) {
          root.applyTheme(root.pagedThemes[root.selectedIndex].name)
        } else if (root.activeTab === 1 && root.pagedCursors[root.selectedIndex]) {
          root.applyCursor(root.pagedCursors[root.selectedIndex].id)
        }
      }
      onReturnRequested: onActivateRequested()
      onTextKey: function(t) {
        if (t === "r" || t === "R") root.refresh()
        else if (t === "1") { root.activeTab = 0; root.selectedIndex = 0 }
        else if (t === "2") { root.activeTab = 1; root.selectedIndex = 0 }
        else if (t === "3") { root.activeTab = 2; root.selectedIndex = 0 }
        else if (t === "4") { root.activeTab = 3; root.selectedIndex = 0 }
        else if (t === "5") { root.activeTab = 4; root.selectedIndex = 0 }
        else if (t === "6") { root.activeTab = 5; root.selectedIndex = 0 }
        else if (t === "t" || t === "T") root.triggerRandomize("theme")
        else if (t === "c" || t === "C") root.triggerRandomize("cursor")
        else if (t === "w" || t === "W") root.nextWallpaper()
        else if (t === " ") root.triggerRandomize("combo")
        else if (t === "n" || t === "N" || t === "]" || t === ">") {
          if (root.activeTab === 0 && root.themePage < root.totalThemePages - 1) root.themePage++
          else if (root.activeTab === 1 && root.cursorPage < root.totalCursorPages - 1) root.cursorPage++
          else if (root.activeTab === 3 && root.storePage < root.totalStorePages - 1) root.storePage++
        }
        else if (t === "p" || t === "P" || t === "[" || t === "<") {
          if (root.activeTab === 0 && root.themePage > 0) root.themePage--
          else if (root.activeTab === 1 && root.cursorPage > 0) root.cursorPage--
          else if (root.activeTab === 3 && root.storePage > 0) root.storePage--
        }
      }

      Flickable {
        id: scrollArea
        anchors.fill: parent
        contentWidth: mainColumn.width
        contentHeight: mainColumn.implicitHeight + Style.space(24)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: mainColumn
          width: scrollArea.width
          spacing: Style.space(12)
          topPadding: Style.space(12)
          bottomPadding: Style.space(12)
          leftPadding: Style.space(14)
          rightPadding: Style.space(14)

          readonly property real innerWidth: width - (leftPadding + rightPadding)

          // --- 1. HEADER ---
          RowLayout {
            width: mainColumn.innerWidth

            Row {
              spacing: Style.space(10)
              Layout.alignment: Qt.AlignVCenter

              Text {
                textFormat: Text.PlainText
                text: "󰔎"
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.title + 4
                color: Color.accent
                anchors.verticalCenter: parent.verticalCenter
              }

              Column {
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                Text {
                  textFormat: Text.PlainText
                  text: "OMACHROMA: THEMES & CURSORS HUB"
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                  color: root.contentForeground
                }

                Text {
                  textFormat: Text.PlainText
                  text: "Active Theme: " + (root.chromaData.currentTheme || "Solitude") +
                        "  ·  Cursor: " + (root.chromaData.currentCursor || "Bibata") +
                        " (" + (root.chromaData.currentCursorSize || 24) + "px)"
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.caption
                  color: root.contentSubtle
                }
              }
            }

            Item { Layout.fillWidth: true }

            Row {
              spacing: Style.space(8)
              Layout.alignment: Qt.AlignVCenter

              Text {
                textFormat: Text.PlainText
                text: root.statusNotice ? root.statusNotice : ""
                font.family: root.contentFontFamily
                font.pixelSize: 11
                color: Color.accent
                anchors.verticalCenter: parent.verticalCenter
                visible: root.statusNotice !== ""
              }

              // Next Wallpaper Button
              BorderSurface {
                implicitWidth: Style.space(90)
                implicitHeight: Style.space(28)
                radius: Style.cornerRadius
                color: bgMouse.pressed ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.35) : Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.12)
                borderSpec: Border.controlSpec("normal", Color.accent, Color.accent)

                Row {
                  anchors.centerIn: parent
                  spacing: Style.space(4)
                  Text {
                    textFormat: Text.PlainText
                    text: "󰸉"
                    font.family: root.contentFontFamily
                    font.pixelSize: 11
                    color: Color.accent
                  }
                  Text {
                    textFormat: Text.PlainText
                    text: "Wall (w)"
                    font.family: root.contentFontFamily
                    font.pixelSize: 10
                    font.bold: true
                    color: Color.accent
                  }
                }

                MouseArea {
                  id: bgMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.nextWallpaper()
                }
              }

              // Restart Shell Button
              BorderSurface {
                implicitWidth: Style.space(90)
                implicitHeight: Style.space(28)
                radius: Style.cornerRadius
                color: restartMouse.pressed ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.35) : Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.12)
                borderSpec: Border.controlSpec("normal", Color.accent, Color.accent)

                Row {
                  anchors.centerIn: parent
                  spacing: Style.space(4)
                  Text {
                    textFormat: Text.PlainText
                    text: "󰑐"
                    font.family: root.contentFontFamily
                    font.pixelSize: 11
                    color: Color.accent
                  }
                  Text {
                    textFormat: Text.PlainText
                    text: "Restart"
                    font.family: root.contentFontFamily
                    font.pixelSize: 10
                    font.bold: true
                    color: Color.accent
                  }
                }

                MouseArea {
                  id: restartMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.restartShell()
                }
              }
            }
          }

          // --- 2. TAB CONTROLS ---
          Row {
            width: mainColumn.innerWidth
            spacing: Style.space(6)

            Repeater {
              model: [
                { id: 0, name: "Themes (" + root.visibleThemes.length + ")", icon: "󰔎" },
                { id: 1, name: "Cursors (" + root.visibleCursors.length + ")", icon: "󰍛" },
                { id: 2, name: "Randomizer", icon: "󰒝" },
                { id: 3, name: "Themes Store (" + root.themeSourcesList.length + ")", icon: "󰔎" },
                { id: 4, name: "Cursors Store (" + root.cursorSourcesList.length + ")", icon: "󰍛" },
                { id: 5, name: "Installed (" + root.userInstalledList.length + ")", icon: "󰉍" }
              ]

              delegate: BorderSurface {
                required property var modelData
                readonly property bool isCurrent: root.activeTab === modelData.id

                implicitWidth: (mainColumn.innerWidth - (Style.space(6) * 5)) / 6
                implicitHeight: Style.space(32)
                radius: Style.cornerRadius
                color: isCurrent ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.22) : Style.hoverFillFor(root.contentForeground, root.contentForeground)
                borderSpec: Border.controlSpec(isCurrent ? "selected" : "normal", isCurrent ? Color.accent : Qt.darker(root.contentForeground, 2.5), Color.accent)

                Row {
                  anchors.centerIn: parent
                  spacing: Style.space(4)

                  Text {
                    textFormat: Text.PlainText
                    text: modelData.icon
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.caption
                    color: isCurrent ? Color.accent : root.contentSubtle
                  }

                  Text {
                    textFormat: Text.PlainText
                    text: modelData.name
                    font.family: root.contentFontFamily
                    font.pixelSize: 10
                    font.bold: isCurrent
                    color: isCurrent ? Color.accent : root.contentForeground
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.activeTab = modelData.id
                    root.selectedIndex = 0
                  }
                }
              }
            }
          }

          // --- TAB 0: INSTALLED THEMES GALLERY (Paginated 10 per page) ---
          Column {
            width: mainColumn.innerWidth
            spacing: Style.space(8)
            visible: root.activeTab === 0

            RowLayout {
              width: mainColumn.innerWidth

              Text {
                textFormat: Text.PlainText
                text: "INSTALLED DESKTOP THEMES (PAGE " + (root.themePage + 1) + " OF " + root.totalThemePages + " · " + root.visibleThemes.length + " TOTAL)"
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                color: root.contentSubtle
              }

              Item { Layout.fillWidth: true }

              Row {
                spacing: Style.space(6)
                visible: root.totalThemePages > 1

                BorderSurface {
                  implicitWidth: Style.space(80)
                  implicitHeight: Style.space(26)
                  radius: Style.cornerRadius
                  color: (root.themePage > 0) ? (prevThemeMouse.pressed ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.3) : Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.12)) : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.04)
                  borderSpec: Border.controlSpec("normal", (root.themePage > 0) ? Color.accent : Qt.darker(root.contentForeground, 3.0), Color.accent)

                  Text {
                    anchors.centerIn: parent
                    textFormat: Text.PlainText
                    text: "◀ Prev (p)"
                    font.family: root.contentFontFamily
                    font.pixelSize: 10
                    font.bold: true
                    color: (root.themePage > 0) ? Color.accent : root.contentSubtle
                  }

                  MouseArea {
                    id: prevThemeMouse
                    anchors.fill: parent
                    hoverEnabled: root.themePage > 0
                    cursorShape: (root.themePage > 0) ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                      if (root.themePage > 0) root.themePage--
                    }
                  }
                }

                BorderSurface {
                  implicitWidth: Style.space(80)
                  implicitHeight: Style.space(26)
                  radius: Style.cornerRadius
                  color: (root.themePage < root.totalThemePages - 1) ? (nextThemeMouse.pressed ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.3) : Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.12)) : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.04)
                  borderSpec: Border.controlSpec("normal", (root.themePage < root.totalThemePages - 1) ? Color.accent : Qt.darker(root.contentForeground, 3.0), Color.accent)

                  Text {
                    anchors.centerIn: parent
                    textFormat: Text.PlainText
                    text: "Next (n) ▶"
                    font.family: root.contentFontFamily
                    font.pixelSize: 10
                    font.bold: true
                    color: (root.themePage < root.totalThemePages - 1) ? Color.accent : root.contentSubtle
                  }

                  MouseArea {
                    id: nextThemeMouse
                    anchors.fill: parent
                    hoverEnabled: root.themePage < root.totalThemePages - 1
                    cursorShape: (root.themePage < root.totalThemePages - 1) ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                      if (root.themePage < root.totalThemePages - 1) root.themePage++
                    }
                  }
                }
              }
            }

            GridLayout {
              width: mainColumn.innerWidth
              columns: 2
              rowSpacing: Style.space(8)
              columnSpacing: Style.space(8)

              Repeater {
                model: root.pagedThemes

                delegate: BorderSurface {
                  required property var modelData
                  required property int index
                  readonly property bool isCurrent: root.chromaData.currentTheme === modelData.name
                  readonly property bool isBusy: root.isActionRunning && root.activeActionId === ("theme:" + modelData.name)

                  Layout.fillWidth: true
                  implicitHeight: Style.space(96)
                  radius: Style.cornerRadius
                  color: isCurrent
                    ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.18)
                    : (cardMouse.containsMouse ? Style.hoverFillFor(root.contentForeground, root.contentForeground) : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.03))
                  borderSpec: Border.controlSpec(isCurrent ? "selected" : "normal", isCurrent ? Color.accent : Qt.darker(root.contentForeground, 2.6), Color.accent)

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: Style.space(10)
                    spacing: Style.space(10)

                    Rectangle {
                      implicitWidth: Style.space(110)
                      implicitHeight: Style.space(76)
                      radius: Style.cornerRadius - 1
                      clip: true
                      color: Qt.rgba(0,0,0,0.4)
                      border.width: 1
                      border.color: Qt.darker(root.contentForeground, 2.5)

                      Image {
                        anchors.fill: parent
                        source: modelData.thumbnail ? ("file://" + modelData.thumbnail) : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: modelData.thumbnail !== ""
                      }

                      Text {
                        anchors.centerIn: parent
                        textFormat: Text.PlainText
                        text: "󰸉"
                        font.family: root.contentFontFamily
                        font.pixelSize: Style.font.title
                        color: root.contentSubtle
                        visible: !modelData.thumbnail
                      }
                    }

                    Item {
                      Layout.fillWidth: true
                      Layout.fillHeight: true

                      Column {
                        anchors.fill: parent
                        spacing: Style.space(3)

                        Row {
                          width: parent.width
                          spacing: Style.space(6)
                          Text {
                            textFormat: Text.PlainText
                            text: modelData.name
                            font.family: root.contentFontFamily
                            font.pixelSize: Style.font.caption + 1
                            font.bold: true
                            color: isCurrent ? Color.accent : root.contentForeground
                            elide: Text.ElideRight
                            maximumLineCount: 1
                          }
                          Text {
                            textFormat: Text.PlainText
                            text: "󰸉 " + modelData.wallpaperCount + " walls"
                            font.family: root.contentFontFamily
                            font.pixelSize: 10
                            color: Color.accent
                            anchors.verticalCenter: parent.verticalCenter
                          }
                        }

                        Row {
                          spacing: 5
                          Repeater {
                            model: [
                              modelData.colors.accent || "#7aa2f7",
                              modelData.colors.background || "#1a1b26",
                              modelData.colors.foreground || "#a9b1d6",
                              modelData.colors.green || "#9ece6a",
                              modelData.colors.red || "#f7768e"
                            ]
                            delegate: Rectangle {
                              required property string modelData
                              width: 16
                              height: 16
                              radius: 3
                              color: modelData
                              border.width: 1
                              border.color: Qt.rgba(0,0,0,0.35)
                            }
                          }
                        }

                        Text {
                          width: parent.width
                          textFormat: Text.PlainText
                          text: modelData.isUser ? "User Theme · " + modelData.path : "System Theme"
                          font.family: "Monospace"
                          font.pixelSize: 9
                          color: root.contentSubtle
                          elide: Text.ElideMiddle
                          maximumLineCount: 1
                        }
                      }
                    }

                    BorderSurface {
                      implicitWidth: Style.space(68)
                      implicitHeight: Style.space(28)
                      radius: Style.cornerRadius
                      color: isCurrent ? Color.accent : (applyMouse.containsMouse ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.2) : "transparent")
                      borderSpec: Border.controlSpec("normal", Color.accent, Color.accent)

                      Text {
                        anchors.centerIn: parent
                        textFormat: Text.PlainText
                        text: isBusy ? "Applying..." : (isCurrent ? "Active" : "Apply")
                        font.family: root.contentFontFamily
                        font.pixelSize: 10
                        font.bold: true
                        color: isCurrent ? Qt.darker(Color.accent, 3.0) : Color.accent
                      }

                      MouseArea {
                        id: applyMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.applyTheme(modelData.name)
                      }
                    }
                  }

                  MouseArea {
                    id: cardMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.applyTheme(modelData.name)
                  }
                }
              }
            }
          }

          // --- TAB 1: CURSORS GALLERY (Paginated 10 per page) ---
          Column {
            width: mainColumn.innerWidth
            spacing: Style.space(8)
            visible: root.activeTab === 1

            RowLayout {
              width: mainColumn.innerWidth
              Text {
                textFormat: Text.PlainText
                text: "INSTALLED CURSORS (PAGE " + (root.cursorPage + 1) + " OF " + root.totalCursorPages + " · " + root.visibleCursors.length + " TOTAL)"
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                color: root.contentSubtle
              }

              Item { Layout.fillWidth: true }

              Text {
                textFormat: Text.PlainText
                text: "CURSOR SIZE: "
                font.family: root.contentFontFamily
                font.pixelSize: 10
                font.bold: true
                color: root.contentSubtle
              }

              Row {
                spacing: 4
                Repeater {
                  model: [16, 20, 24, 28, 32, 48]
                  delegate: BorderSurface {
                    required property int modelData
                    readonly property bool isSelected: (root.chromaData.currentCursorSize || 24) === modelData
                    implicitWidth: Style.space(30)
                    implicitHeight: Style.space(24)
                    radius: Style.cornerRadius
                    color: isSelected ? Color.accent : "transparent"
                    borderSpec: Border.controlSpec("normal", isSelected ? Color.accent : Qt.darker(root.contentForeground, 2.5), Color.accent)

                    Text {
                      anchors.centerIn: parent
                      textFormat: Text.PlainText
                      text: String(modelData)
                      font.family: "Monospace"
                      font.pixelSize: 10
                      font.bold: true
                      color: isSelected ? Qt.darker(Color.accent, 3.0) : root.contentForeground
                    }

                    MouseArea {
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.setCursorSizeOnly(modelData)
                    }
                  }
                }
              }

              Row {
                spacing: Style.space(4)
                visible: root.totalCursorPages > 1

                BorderSurface {
                  implicitWidth: Style.space(70)
                  implicitHeight: Style.space(24)
                  radius: Style.cornerRadius
                  color: (root.cursorPage > 0) ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.15) : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.04)
                  borderSpec: Border.controlSpec("normal", (root.cursorPage > 0) ? Color.accent : Qt.darker(root.contentForeground, 3.0), Color.accent)

                  Text {
                    anchors.centerIn: parent
                    textFormat: Text.PlainText
                    text: "◀ Prev"
                    font.family: root.contentFontFamily
                    font.pixelSize: 9
                    font.bold: true
                    color: (root.cursorPage > 0) ? Color.accent : root.contentSubtle
                  }

                  MouseArea {
                    anchors.fill: parent
                    hoverEnabled: root.cursorPage > 0
                    cursorShape: (root.cursorPage > 0) ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                      if (root.cursorPage > 0) root.cursorPage--
                    }
                  }
                }

                BorderSurface {
                  implicitWidth: Style.space(70)
                  implicitHeight: Style.space(24)
                  radius: Style.cornerRadius
                  color: (root.cursorPage < root.totalCursorPages - 1) ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.15) : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.04)
                  borderSpec: Border.controlSpec("normal", (root.cursorPage < root.totalCursorPages - 1) ? Color.accent : Qt.darker(root.contentForeground, 3.0), Color.accent)

                  Text {
                    anchors.centerIn: parent
                    textFormat: Text.PlainText
                    text: "Next ▶"
                    font.family: root.contentFontFamily
                    font.pixelSize: 9
                    font.bold: true
                    color: (root.cursorPage < root.totalCursorPages - 1) ? Color.accent : root.contentSubtle
                  }

                  MouseArea {
                    anchors.fill: parent
                    hoverEnabled: root.cursorPage < root.totalCursorPages - 1
                    cursorShape: (root.cursorPage < root.totalCursorPages - 1) ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                      if (root.cursorPage < root.totalCursorPages - 1) root.cursorPage++
                    }
                  }
                }
              }
            }

            GridLayout {
              width: mainColumn.innerWidth
              columns: 2
              rowSpacing: Style.space(8)
              columnSpacing: Style.space(8)

              Repeater {
                model: root.pagedCursors

                delegate: BorderSurface {
                  required property var modelData
                  required property int index
                  readonly property bool isCurrent: root.chromaData.currentCursor === modelData.id
                  readonly property bool isBusy: root.isActionRunning && root.activeActionId === ("cursor:" + modelData.id)

                  Layout.fillWidth: true
                  implicitHeight: Style.space(62)
                  radius: Style.cornerRadius
                  color: isCurrent
                    ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.18)
                    : (cursorMouse.containsMouse ? Style.hoverFillFor(root.contentForeground, root.contentForeground) : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.03))
                  borderSpec: Border.controlSpec(isCurrent ? "selected" : "normal", isCurrent ? Color.accent : Qt.darker(root.contentForeground, 2.6), Color.accent)

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: Style.space(10)
                    spacing: Style.space(8)

                    Text {
                      textFormat: Text.PlainText
                      text: "󰍛"
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.title
                      color: isCurrent ? Color.accent : root.contentForeground
                    }

                    Item {
                      Layout.fillWidth: true
                      Layout.fillHeight: true

                      Column {
                        anchors.fill: parent
                        spacing: 2

                        Text {
                          width: parent.width
                          textFormat: Text.PlainText
                          text: modelData.name
                          font.family: root.contentFontFamily
                          font.pixelSize: Style.font.caption + 1
                          font.bold: true
                          color: isCurrent ? Color.accent : root.contentForeground
                          elide: Text.ElideRight
                          maximumLineCount: 1
                        }

                        Text {
                          width: parent.width
                          textFormat: Text.PlainText
                          text: "ID: " + modelData.id + " · " + (modelData.isUser ? "User" : "System")
                          font.family: "Monospace"
                          font.pixelSize: 9
                          color: root.contentSubtle
                          elide: Text.ElideRight
                          maximumLineCount: 1
                        }
                      }
                    }

                    BorderSurface {
                      implicitWidth: Style.space(68)
                      implicitHeight: Style.space(28)
                      radius: Style.cornerRadius
                      color: isCurrent ? Color.accent : (curApplyMouse.containsMouse ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.2) : "transparent")
                      borderSpec: Border.controlSpec("normal", Color.accent, Color.accent)

                      Text {
                        anchors.centerIn: parent
                        textFormat: Text.PlainText
                        text: isBusy ? "Setting..." : (isCurrent ? "Active" : "Apply")
                        font.family: root.contentFontFamily
                        font.pixelSize: 10
                        font.bold: true
                        color: isCurrent ? Qt.darker(Color.accent, 3.0) : Color.accent
                      }

                      MouseArea {
                        id: curApplyMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.applyCursor(modelData.id)
                      }
                    }
                  }

                  MouseArea {
                    id: cursorMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.applyCursor(modelData.id)
                  }
                }
              }
            }
          }

                    // --- TAB 2: RANDOMIZER, TIMER CONTROLS & CHECKLISTS ---
          Column {
            width: mainColumn.innerWidth
            spacing: Style.space(10)
            visible: root.activeTab === 2

            // Top Action Card
            BorderSurface {
              width: mainColumn.innerWidth
              implicitHeight: Style.space(68)
              radius: Style.cornerRadius
              color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.12)
              borderSpec: Border.controlSpec("normal", Color.accent, Color.accent)

              RowLayout {
                anchors.fill: parent
                anchors.margins: Style.space(12)

                Column {
                  spacing: 2
                  Text {
                    textFormat: Text.PlainText
                    text: "MANUAL ROLL CONTROLS"
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                    color: Color.accent
                  }
                  Text {
                    textFormat: Text.PlainText
                    text: "Instant randomized styling from your selected pool."
                    font.family: root.contentFontFamily
                    font.pixelSize: 10
                    color: root.contentForeground
                  }
                }

                Item { Layout.fillWidth: true }

                Row {
                  spacing: Style.space(8)
                  BorderSurface {
                    implicitWidth: Style.space(100)
                    implicitHeight: Style.space(28)
                    radius: Style.cornerRadius
                    color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.25)
                    borderSpec: Border.controlSpec("normal", Color.accent, Color.accent)
                    Text {
                      anchors.centerIn: parent
                      textFormat: Text.PlainText
                      text: "Theme (t)"
                      font.family: root.contentFontFamily
                      font.pixelSize: 10
                      font.bold: true
                      color: Color.accent
                    }
                    MouseArea {
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.triggerRandomize("theme")
                    }
                  }

                  BorderSurface {
                    implicitWidth: Style.space(100)
                    implicitHeight: Style.space(28)
                    radius: Style.cornerRadius
                    color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.25)
                    borderSpec: Border.controlSpec("normal", Color.accent, Color.accent)
                    Text {
                      anchors.centerIn: parent
                      textFormat: Text.PlainText
                      text: "Cursor (c)"
                      font.family: root.contentFontFamily
                      font.pixelSize: 10
                      font.bold: true
                      color: Color.accent
                    }
                    MouseArea {
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.triggerRandomize("cursor")
                    }
                  }

                  BorderSurface {
                    implicitWidth: Style.space(100)
                    implicitHeight: Style.space(28)
                    radius: Style.cornerRadius
                    color: Color.accent
                    borderSpec: Border.controlSpec("normal", Color.accent, Color.accent)
                    Text {
                      anchors.centerIn: parent
                      textFormat: Text.PlainText
                      text: "Combo (Space)"
                      font.family: root.contentFontFamily
                      font.pixelSize: 10
                      font.bold: true
                      color: Qt.darker(Color.accent, 3.0)
                    }
                    MouseArea {
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.triggerRandomize("combo")
                    }
                  }
                }
              }
            }

            // AUTOMATED RANDOMIZER TIMER CONTROLS CARD
            BorderSurface {
              width: mainColumn.innerWidth
              implicitHeight: Style.space(64)
              radius: Style.cornerRadius
              color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.04)
              borderSpec: Border.controlSpec("normal", root.currentTimerHours > 0 ? Color.accent : Qt.darker(root.contentForeground, 2.6), Color.accent)

              RowLayout {
                anchors.fill: parent
                anchors.margins: Style.space(10)
                spacing: Style.space(8)

                Row {
                  spacing: Style.space(6)
                  Layout.alignment: Qt.AlignVCenter
                  Text {
                    textFormat: Text.PlainText
                    text: "󱑂"
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.body
                    color: root.currentTimerHours > 0 ? Color.accent : root.contentSubtle
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  Column {
                    spacing: 1
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                      textFormat: Text.PlainText
                      text: "AUTOMATED RANDOMIZER TIMER"
                      font.family: root.contentFontFamily
                      font.pixelSize: 10
                      font.bold: true
                      color: root.currentTimerHours > 0 ? Color.accent : root.contentForeground
                    }
                    Text {
                      textFormat: Text.PlainText
                      text: root.currentTimerHours > 0 ? ("Active: Auto-rolls styling every " + root.currentTimerHours + " hour(s)") : "Status: Off (Manual rolls only)"
                      font.family: root.contentFontFamily
                      font.pixelSize: 9
                      color: root.contentSubtle
                    }
                  }
                }

                Item { Layout.fillWidth: true }

                // Timer Preset Buttons: Off, 1h, 12h, 24h
                Row {
                  spacing: Style.space(4)
                  Layout.alignment: Qt.AlignVCenter

                  Repeater {
                    model: [
                      { label: "Off", hours: 0 },
                      { label: "1h", hours: 1 },
                      { label: "12h", hours: 12 },
                      { label: "24h", hours: 24 }
                    ]

                    delegate: BorderSurface {
                      required property var modelData
                      readonly property bool isSelected: Math.abs(root.currentTimerHours - modelData.hours) < 0.01

                      implicitWidth: Style.space(42)
                      implicitHeight: Style.space(26)
                      radius: Style.cornerRadius
                      color: isSelected ? Color.accent : (presetMouse.containsMouse ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.15) : "transparent")
                      borderSpec: Border.controlSpec("normal", isSelected ? Color.accent : Qt.darker(root.contentForeground, 2.5), Color.accent)

                      Text {
                        anchors.centerIn: parent
                        textFormat: Text.PlainText
                        text: modelData.label
                        font.family: root.contentFontFamily
                        font.pixelSize: 10
                        font.bold: isSelected
                        color: isSelected ? Qt.darker(Color.accent, 3.0) : root.contentForeground
                      }

                      MouseArea {
                        id: presetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setRandomizerTimer(modelData.hours)
                      }
                    }
                  }

                  // Custom Hours Input Box
                  Rectangle {
                    implicitWidth: Style.space(62)
                    height: Style.space(26)
                    radius: Style.cornerRadius
                    color: Qt.rgba(0,0,0,0.3)
                    border.width: 1
                    border.color: (root.currentTimerHours > 0 && [1,12,24].indexOf(root.currentTimerHours) === -1) ? Color.accent : Qt.darker(root.contentForeground, 2.5)

                    TextInput {
                      id: customHoursInput
                      anchors.fill: parent
                      anchors.margins: 4
                      clip: true
                      color: root.contentForeground
                      font.family: "Monospace"
                      font.pixelSize: 10
                      text: root.customTimerHoursInput
                      onTextChanged: root.customTimerHoursInput = text
                      onAccepted: {
                        if (text.trim()) root.setRandomizerTimer(text.trim())
                      }

                      Text {
                        anchors.fill: parent
                        textFormat: Text.PlainText
                        text: "Hrs..."
                        color: root.contentSubtle
                        visible: !customHoursInput.text && !customHoursInput.activeFocus
                      }
                    }
                  }

                  // Set Custom Button
                  BorderSurface {
                    implicitWidth: Style.space(46)
                    implicitHeight: Style.space(26)
                    radius: Style.cornerRadius
                    color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.22)
                    borderSpec: Border.controlSpec("normal", Color.accent, Color.accent)

                    Text {
                      anchors.centerIn: parent
                      textFormat: Text.PlainText
                      text: "Set"
                      font.family: root.contentFontFamily
                      font.pixelSize: 10
                      font.bold: true
                      color: Color.accent
                    }

                    MouseArea {
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        if (root.customTimerHoursInput.trim()) {
                          root.setRandomizerTimer(root.customTimerHoursInput.trim())
                        }
                      }
                    }
                  }
                }
              }
            }

            // Themes Checklist
            Column {
              width: mainColumn.innerWidth
              spacing: Style.space(6)

              Text {
                textFormat: Text.PlainText
                text: "THEMES INCLUDED IN RANDOM POOL (CLICK TO TOGGLE)"
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                color: root.contentSubtle
              }

              GridLayout {
                width: mainColumn.innerWidth
                columns: 3
                rowSpacing: 6
                columnSpacing: 6

                Repeater {
                  model: root.visibleThemes

                  delegate: BorderSurface {
                    required property var modelData
                    readonly property bool isChecked: (root.chromaData.selectedThemes || []).indexOf(modelData.id) >= 0

                    Layout.fillWidth: true
                    implicitHeight: Style.space(34)
                    radius: Style.cornerRadius
                    color: isChecked ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.16) : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.02)
                    borderSpec: Border.controlSpec("normal", isChecked ? Color.accent : Qt.darker(root.contentForeground, 2.8), Color.accent)

                    Row {
                      anchors.fill: parent
                      anchors.margins: Style.space(8)
                      spacing: Style.space(8)

                      Text {
                        textFormat: Text.PlainText
                        text: isChecked ? "󰄬" : "󰄱"
                        font.family: root.contentFontFamily
                        font.pixelSize: 13
                        font.bold: true
                        color: isChecked ? Color.accent : root.contentSubtle
                        anchors.verticalCenter: parent.verticalCenter
                      }
                      Text {
                        textFormat: Text.PlainText
                        text: modelData.name
                        font.family: root.contentFontFamily
                        font.pixelSize: 11
                        font.bold: isChecked
                        color: isChecked ? Color.accent : root.contentForeground
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        maximumLineCount: 1
                      }
                    }

                    MouseArea {
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.toggleThemeSelection(modelData.id)
                    }
                  }
                }
              }
            }

            // Cursors Checklist
            Column {
              width: mainColumn.innerWidth
              spacing: Style.space(6)

              Text {
                textFormat: Text.PlainText
                text: "CURSORS INCLUDED IN RANDOM POOL (CLICK TO TOGGLE)"
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                color: root.contentSubtle
              }

              GridLayout {
                width: mainColumn.innerWidth
                columns: 3
                rowSpacing: 6
                columnSpacing: 6

                Repeater {
                  model: root.visibleCursors

                  delegate: BorderSurface {
                    required property var modelData
                    readonly property bool isChecked: (root.chromaData.selectedCursors || []).indexOf(modelData.id) >= 0

                    Layout.fillWidth: true
                    implicitHeight: Style.space(34)
                    radius: Style.cornerRadius
                    color: isChecked ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.16) : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.02)
                    borderSpec: Border.controlSpec("normal", isChecked ? Color.accent : Qt.darker(root.contentForeground, 2.8), Color.accent)

                    Row {
                      anchors.fill: parent
                      anchors.margins: Style.space(8)
                      spacing: Style.space(8)

                      Text {
                        textFormat: Text.PlainText
                        text: isChecked ? "󰄬" : "󰄱"
                        font.family: root.contentFontFamily
                        font.pixelSize: 13
                        font.bold: true
                        color: isChecked ? Color.accent : root.contentSubtle
                        anchors.verticalCenter: parent.verticalCenter
                      }
                      Text {
                        textFormat: Text.PlainText
                        text: modelData.name
                        font.family: root.contentFontFamily
                        font.pixelSize: 11
                        font.bold: isChecked
                        color: isChecked ? Color.accent : root.contentForeground
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        maximumLineCount: 1
                      }
                    }

                    MouseArea {
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.toggleCursorSelection(modelData.id)
                    }
                  }
                }
              }
            }
          }

          // --- TAB 3: THEMES STORE & SOURCE MANAGER ---
          Column {
            width: mainColumn.innerWidth
            spacing: Style.space(10)
            visible: root.activeTab === 3

            // CUSTOM SOURCE REPOSITORY MANAGEMENT BOX
            BorderSurface {
              width: mainColumn.innerWidth
              implicitHeight: Style.space(root.customSourcesList.length > 0 ? 120 : 84)
              radius: Style.cornerRadius
              color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.04)
              borderSpec: Border.controlSpec("normal", root.editingSourceId ? Color.accent : Qt.darker(root.contentForeground, 2.5), Color.accent)

              Column {
                anchors.fill: parent
                anchors.margins: Style.space(10)
                spacing: Style.space(6)

                RowLayout {
                  width: parent.width
                  Text {
                    textFormat: Text.PlainText
                    text: root.editingSourceId ? "EDIT SOURCE REPOSITORY" : "ADD CUSTOM GITHUB SOURCE(S) OR DIRECT REPOSITORY"
                    font.family: root.contentFontFamily
                    font.pixelSize: 10
                    font.bold: true
                    color: root.editingSourceId ? Color.accent : root.contentSubtle
                  }
                  Item { Layout.fillWidth: true }
                  Text {
                    textFormat: Text.PlainText
                    text: "(Supports single link, multiple links separated by comma, or instant install)"
                    font.family: root.contentFontFamily
                    font.pixelSize: 9
                    color: root.contentSubtle
                  }
                }

                RowLayout {
                  width: parent.width
                  spacing: Style.space(6)

                  // Optional Name Input
                  Rectangle {
                    implicitWidth: Style.space(170)
                    height: Style.space(28)
                    radius: Style.cornerRadius
                    color: Qt.rgba(0,0,0,0.3)
                    border.width: 1
                    border.color: Qt.darker(root.contentForeground, 2.5)

                    TextInput {
                      id: sourceNameInput
                      anchors.fill: parent
                      anchors.margins: 5
                      clip: true
                      color: root.contentForeground
                      font.family: "Monospace"
                      font.pixelSize: 10
                      text: root.customSourceNameInput
                      onTextChanged: root.customSourceNameInput = text

                      Text {
                        anchors.fill: parent
                        textFormat: Text.PlainText
                        text: "Name (optional)"
                        color: root.contentSubtle
                        visible: !sourceNameInput.text && !sourceNameInput.activeFocus
                      }
                    }
                  }

                  // URL Input
                  Rectangle {
                    Layout.fillWidth: true
                    height: Style.space(28)
                    radius: Style.cornerRadius
                    color: Qt.rgba(0,0,0,0.3)
                    border.width: 1
                    border.color: root.editingSourceId ? Color.accent : Qt.darker(root.contentForeground, 2.5)

                    TextInput {
                      id: sourceUrlInput
                      anchors.fill: parent
                      anchors.margins: 5
                      clip: true
                      color: root.contentForeground
                      font.family: "Monospace"
                      font.pixelSize: 10
                      text: root.customSourceInput
                      onTextChanged: root.customSourceInput = text

                      Text {
                        anchors.fill: parent
                        textFormat: Text.PlainText
                        text: "https://github.com/owner/repo..."
                        color: root.contentSubtle
                        visible: !sourceUrlInput.text && !sourceUrlInput.activeFocus
                      }
                    }
                  }

                  // Action Buttons: Add Source / Save Edit
                  BorderSurface {
                    implicitWidth: Style.space(90)
                    implicitHeight: Style.space(28)
                    radius: Style.cornerRadius
                    color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.25)
                    borderSpec: Border.controlSpec("normal", Color.accent, Color.accent)

                    Text {
                      anchors.centerIn: parent
                      textFormat: Text.PlainText
                      text: root.editingSourceId ? "Save Edit" : "Add Source"
                      font.family: root.contentFontFamily
                      font.pixelSize: 10
                      font.bold: true
                      color: Color.accent
                    }

                    MouseArea {
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.addOrSaveCustomSource()
                    }
                  }

                  // Direct Install Now Button
                  BorderSurface {
                    implicitWidth: Style.space(85)
                    implicitHeight: Style.space(28)
                    radius: Style.cornerRadius
                    color: directDlMouse.containsMouse ? Color.accent : "transparent"
                    borderSpec: Border.controlSpec("normal", Color.accent, Color.accent)

                    Text {
                      anchors.centerIn: parent
                      textFormat: Text.PlainText
                      text: "Install Now"
                      font.family: root.contentFontFamily
                      font.pixelSize: 10
                      font.bold: true
                      color: directDlMouse.containsMouse ? Qt.darker(Color.accent, 3.0) : Color.accent
                    }

                    MouseArea {
                      id: directDlMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        if (!root.customSourceInput.trim()) return
                        root.downloadThemeSource({
                          id: "direct-" + Date.now(),
                          name: root.customSourceNameInput.trim() || "Direct Theme Repo",
                          url: root.customSourceInput.trim()
                        })
                        root.customSourceInput = ""
                        root.customSourceNameInput = ""
                      }
                    }
                  }

                  // Cancel Edit Button
                  BorderSurface {
                    implicitWidth: Style.space(60)
                    implicitHeight: Style.space(28)
                    radius: Style.cornerRadius
                    visible: root.editingSourceId !== ""
                    color: "transparent"
                    borderSpec: Border.controlSpec("normal", Qt.darker(root.contentForeground, 2.5), Color.accent)

                    Text {
                      anchors.centerIn: parent
                      textFormat: Text.PlainText
                      text: "Cancel"
                      font.family: root.contentFontFamily
                      font.pixelSize: 10
                      color: root.contentSubtle
                    }

                    MouseArea {
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.cancelEditSource()
                    }
                  }
                }

                // Configured Custom Sources Strip
                RowLayout {
                  width: parent.width
                  visible: root.customSourcesList.length > 0
                  spacing: Style.space(6)

                  Text {
                    textFormat: Text.PlainText
                    text: "CUSTOM SOURCES (" + root.customSourcesList.length + "):"
                    font.family: root.contentFontFamily
                    font.pixelSize: 9
                    font.bold: true
                    color: Color.accent
                  }

                  Repeater {
                    model: root.customSourcesList

                    delegate: BorderSurface {
                      required property var modelData
                      implicitHeight: Style.space(24)
                      implicitWidth: Math.min(220, sourceLabel.implicitWidth + 50)
                      radius: Style.cornerRadius
                      color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.06)
                      borderSpec: Border.controlSpec("normal", Qt.darker(root.contentForeground, 2.6), Color.accent)

                      Row {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 4

                        Text {
                          id: sourceLabel
                          textFormat: Text.PlainText
                          text: modelData.name
                          font.family: root.contentFontFamily
                          font.pixelSize: 9
                          color: root.contentForeground
                          elide: Text.ElideRight
                          width: parent.width - 36
                          anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                          textFormat: Text.PlainText
                          text: "󰏫"
                          font.family: root.contentFontFamily
                          font.pixelSize: 11
                          color: Color.accent
                          anchors.verticalCenter: parent.verticalCenter
                          MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.startEditSource(modelData)
                          }
                        }

                        Text {
                          textFormat: Text.PlainText
                          text: "󰅖"
                          font.family: root.contentFontFamily
                          font.pixelSize: 11
                          color: "#ef4444"
                          anchors.verticalCenter: parent.verticalCenter
                          MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.deleteCustomSource(modelData.id)
                          }
                        }
                      }
                    }
                  }
                  Item { Layout.fillWidth: true }
                }
              }
            }

            // Pagination Controls Header
            RowLayout {
              width: mainColumn.innerWidth

              Text {
                textFormat: Text.PlainText
                text: "COMMUNITY THEMES STORE (PAGE " + (root.storePage + 1) + " OF " + root.totalStorePages + " · " + root.themeSourcesList.length + " TOTAL)"
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                color: root.contentSubtle
              }

              Item { Layout.fillWidth: true }

              Row {
                spacing: Style.space(6)

                // Prev Page Button
                BorderSurface {
                  implicitWidth: Style.space(80)
                  implicitHeight: Style.space(26)
                  radius: Style.cornerRadius
                  color: (root.storePage > 0) ? (prevPageMouse.pressed ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.3) : Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.12)) : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.04)
                  borderSpec: Border.controlSpec("normal", (root.storePage > 0) ? Color.accent : Qt.darker(root.contentForeground, 3.0), Color.accent)

                  Text {
                    anchors.centerIn: parent
                    textFormat: Text.PlainText
                    text: "◀ Prev (p)"
                    font.family: root.contentFontFamily
                    font.pixelSize: 10
                    font.bold: true
                    color: (root.storePage > 0) ? Color.accent : root.contentSubtle
                  }

                  MouseArea {
                    id: prevPageMouse
                    anchors.fill: parent
                    hoverEnabled: root.storePage > 0
                    cursorShape: (root.storePage > 0) ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                      if (root.storePage > 0) root.storePage--
                    }
                  }
                }

                // Next Page Button
                BorderSurface {
                  implicitWidth: Style.space(80)
                  implicitHeight: Style.space(26)
                  radius: Style.cornerRadius
                  color: (root.storePage < root.totalStorePages - 1) ? (nextPageMouse.pressed ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.3) : Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.12)) : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.04)
                  borderSpec: Border.controlSpec("normal", (root.storePage < root.totalStorePages - 1) ? Color.accent : Qt.darker(root.contentForeground, 3.0), Color.accent)

                  Text {
                    anchors.centerIn: parent
                    textFormat: Text.PlainText
                    text: "Next (n) ▶"
                    font.family: root.contentFontFamily
                    font.pixelSize: 10
                    font.bold: true
                    color: (root.storePage < root.totalStorePages - 1) ? Color.accent : root.contentSubtle
                  }

                  MouseArea {
                    id: nextPageMouse
                    anchors.fill: parent
                    hoverEnabled: root.storePage < root.totalStorePages - 1
                    cursorShape: (root.storePage < root.totalStorePages - 1) ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                      if (root.storePage < root.totalStorePages - 1) root.storePage++
                    }
                  }
                }
              }
            }

            GridLayout {
              width: mainColumn.innerWidth
              columns: 2
              rowSpacing: Style.space(8)
              columnSpacing: Style.space(8)

              Repeater {
                model: root.pagedThemeSources

                delegate: BorderSurface {
                  required property var modelData
                  readonly property bool isBusy: root.isActionRunning && root.activeActionId === ("dl:" + modelData.id)

                  Layout.fillWidth: true
                  implicitHeight: Style.space(104)
                  radius: Style.cornerRadius
                  color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.03)
                  borderSpec: Border.controlSpec("normal", modelData.isCustomSource ? Color.accent : Qt.darker(root.contentForeground, 2.6), Color.accent)

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: Style.space(10)
                    spacing: Style.space(10)

                    // Wallpaper Thumbnail Container with local disk caching
                    Rectangle {
                      implicitWidth: Style.space(110)
                      implicitHeight: Style.space(84)
                      radius: Style.cornerRadius - 1
                      clip: true
                      color: Qt.rgba(0,0,0,0.4)
                      border.width: 1
                      border.color: Qt.darker(root.contentForeground, 2.5)

                      Image {
                        anchors.fill: parent
                        source: modelData.wallpaperUrl || modelData.remoteUrl || ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                      }
                    }

                    Item {
                      Layout.fillWidth: true
                      Layout.fillHeight: true

                      Column {
                        anchors.fill: parent
                        spacing: Style.space(3)

                        Row {
                          width: parent.width
                          spacing: Style.space(6)
                          Text {
                            textFormat: Text.PlainText
                            text: modelData.name
                            font.family: root.contentFontFamily
                            font.pixelSize: Style.font.caption + 1
                            font.bold: true
                            color: root.contentForeground
                            elide: Text.ElideRight
                            maximumLineCount: 1
                          }
                          Text {
                            textFormat: Text.PlainText
                            text: "by @" + modelData.author + " · " + (modelData.category || "Theme")
                            font.family: root.contentFontFamily
                            font.pixelSize: 9
                            color: modelData.isCustomSource ? Color.accent : root.contentSubtle
                          }
                        }

                        // 5 Color Swatches
                        Row {
                          spacing: 4
                          Repeater {
                            model: [
                              modelData.colors.accent,
                              modelData.colors.background,
                              modelData.colors.foreground,
                              modelData.colors.green,
                              modelData.colors.red
                            ]
                            delegate: Rectangle {
                              required property string modelData
                              width: 14
                              height: 14
                              radius: 3
                              color: modelData
                              border.width: 1
                              border.color: Qt.rgba(0,0,0,0.4)
                            }
                          }
                        }

                        Text {
                          width: parent.width
                          textFormat: Text.PlainText
                          text: modelData.description
                          font.family: root.contentFontFamily
                          font.pixelSize: 9
                          color: root.contentSubtle
                          elide: Text.ElideRight
                          maximumLineCount: 2
                          wrapMode: Text.WordWrap
                        }
                      }
                    }

                    BorderSurface {
                      implicitWidth: Style.space(76)
                      implicitHeight: Style.space(28)
                      radius: Style.cornerRadius
                      color: modelData.installed ? Qt.rgba(0.65, 0.89, 0.63, 0.18) : (dlThemeMouse.containsMouse ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.25) : "transparent")
                      borderSpec: Border.controlSpec("normal", modelData.installed ? "#10b981" : Color.accent, Color.accent)

                      Text {
                        anchors.centerIn: parent
                        textFormat: Text.PlainText
                        text: isBusy ? "Fetching..." : (modelData.installed ? "Installed" : "Download")
                        font.family: root.contentFontFamily
                        font.pixelSize: 10
                        font.bold: true
                        color: modelData.installed ? "#10b981" : Color.accent
                      }

                      MouseArea {
                        id: dlThemeMouse
                        anchors.fill: parent
                        hoverEnabled: !modelData.installed && !isBusy
                        cursorShape: (modelData.installed || isBusy) ? Qt.ArrowCursor : Qt.PointingHandCursor
                        onClicked: {
                          if (!modelData.installed && !isBusy) root.downloadThemeSource(modelData)
                        }
                      }
                    }
                  }
                }
              }
            }
          }

          // --- TAB 4: CURSORS STORE & SOURCE MANAGER ---
          Column {
            width: mainColumn.innerWidth
            spacing: Style.space(10)
            visible: root.activeTab === 4

            // CUSTOM CURSOR SOURCE REPOSITORY MANAGEMENT BOX
            BorderSurface {
              width: mainColumn.innerWidth
              implicitHeight: Style.space(root.customCursorSourcesList.length > 0 ? 120 : 84)
              radius: Style.cornerRadius
              color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.04)
              borderSpec: Border.controlSpec("normal", root.editingCursorSourceId ? Color.accent : Qt.darker(root.contentForeground, 2.5), Color.accent)

              Column {
                anchors.fill: parent
                anchors.margins: Style.space(10)
                spacing: Style.space(6)

                RowLayout {
                  width: parent.width
                  Text {
                    textFormat: Text.PlainText
                    text: root.editingCursorSourceId ? "EDIT CURSOR SOURCE ARCHIVE" : "ADD CUSTOM CURSOR ARCHIVE(S) OR DIRECT RELEASE LINK"
                    font.family: root.contentFontFamily
                    font.pixelSize: 10
                    font.bold: true
                    color: root.editingCursorSourceId ? Color.accent : root.contentSubtle
                  }
                  Item { Layout.fillWidth: true }
                  Text {
                    textFormat: Text.PlainText
                    text: "(Supports .tar.xz, .tar.gz, .zip, comma-separated multiple links, or instant install)"
                    font.family: root.contentFontFamily
                    font.pixelSize: 9
                    color: root.contentSubtle
                  }
                }

                RowLayout {
                  width: parent.width
                  spacing: Style.space(6)

                  // Optional Cursor Pack Name Input
                  Rectangle {
                    implicitWidth: Style.space(170)
                    height: Style.space(28)
                    radius: Style.cornerRadius
                    color: Qt.rgba(0,0,0,0.3)
                    border.width: 1
                    border.color: Qt.darker(root.contentForeground, 2.5)

                    TextInput {
                      id: cursorSourceNameInput
                      anchors.fill: parent
                      anchors.margins: 5
                      clip: true
                      color: root.contentForeground
                      font.family: "Monospace"
                      font.pixelSize: 10
                      text: root.customCursorSourceNameInput
                      onTextChanged: root.customCursorSourceNameInput = text

                      Text {
                        anchors.fill: parent
                        textFormat: Text.PlainText
                        text: "Pack Name (optional)"
                        color: root.contentSubtle
                        visible: !cursorSourceNameInput.text && !cursorSourceNameInput.activeFocus
                      }
                    }
                  }

                  // URL Input
                  Rectangle {
                    Layout.fillWidth: true
                    height: Style.space(28)
                    radius: Style.cornerRadius
                    color: Qt.rgba(0,0,0,0.3)
                    border.width: 1
                    border.color: root.editingCursorSourceId ? Color.accent : Qt.darker(root.contentForeground, 2.5)

                    TextInput {
                      id: cursorSourceUrlInput
                      anchors.fill: parent
                      anchors.margins: 5
                      clip: true
                      color: root.contentForeground
                      font.family: "Monospace"
                      font.pixelSize: 10
                      text: root.customCursorSourceInput
                      onTextChanged: root.customCursorSourceInput = text

                      Text {
                        anchors.fill: parent
                        textFormat: Text.PlainText
                        text: "https://github.com/user/repo/releases/download/.../cursors.tar.xz"
                        color: root.contentSubtle
                        visible: !cursorSourceUrlInput.text && !cursorSourceUrlInput.activeFocus
                      }
                    }
                  }

                  // Action Buttons: Add Source / Save Edit
                  BorderSurface {
                    implicitWidth: Style.space(90)
                    implicitHeight: Style.space(28)
                    radius: Style.cornerRadius
                    color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.25)
                    borderSpec: Border.controlSpec("normal", Color.accent, Color.accent)

                    Text {
                      anchors.centerIn: parent
                      textFormat: Text.PlainText
                      text: root.editingCursorSourceId ? "Save Edit" : "Add Source"
                      font.family: root.contentFontFamily
                      font.pixelSize: 10
                      font.bold: true
                      color: Color.accent
                    }

                    MouseArea {
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.addOrSaveCustomCursorSource()
                    }
                  }

                  // Direct Install Now Button
                  BorderSurface {
                    implicitWidth: Style.space(85)
                    implicitHeight: Style.space(28)
                    radius: Style.cornerRadius
                    color: directCurDlMouse.containsMouse ? Color.accent : "transparent"
                    borderSpec: Border.controlSpec("normal", Color.accent, Color.accent)

                    Text {
                      anchors.centerIn: parent
                      textFormat: Text.PlainText
                      text: "Install Now"
                      font.family: root.contentFontFamily
                      font.pixelSize: 10
                      font.bold: true
                      color: directCurDlMouse.containsMouse ? Qt.darker(Color.accent, 3.0) : Color.accent
                    }

                    MouseArea {
                      id: directCurDlMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        if (!root.customCursorSourceInput.trim()) return
                        root.downloadCursorSource({
                          id: "direct-cur-" + Date.now(),
                          name: root.customCursorSourceNameInput.trim() || "Direct Cursor Archive",
                          url: root.customCursorSourceInput.trim()
                        })
                        root.customCursorSourceInput = ""
                        root.customCursorSourceNameInput = ""
                      }
                    }
                  }

                  // Cancel Edit Button
                  BorderSurface {
                    implicitWidth: Style.space(60)
                    implicitHeight: Style.space(28)
                    radius: Style.cornerRadius
                    visible: root.editingCursorSourceId !== ""
                    color: "transparent"
                    borderSpec: Border.controlSpec("normal", Qt.darker(root.contentForeground, 2.5), Color.accent)

                    Text {
                      anchors.centerIn: parent
                      textFormat: Text.PlainText
                      text: "Cancel"
                      font.family: root.contentFontFamily
                      font.pixelSize: 10
                      color: root.contentSubtle
                    }

                    MouseArea {
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.cancelEditCursorSource()
                    }
                  }
                }

                // Configured Custom Cursor Sources Strip
                RowLayout {
                  width: parent.width
                  visible: root.customCursorSourcesList.length > 0
                  spacing: Style.space(6)

                  Text {
                    textFormat: Text.PlainText
                    text: "CUSTOM SOURCES (" + root.customCursorSourcesList.length + "):"
                    font.family: root.contentFontFamily
                    font.pixelSize: 9
                    font.bold: true
                    color: Color.accent
                  }

                  Repeater {
                    model: root.customCursorSourcesList

                    delegate: BorderSurface {
                      required property var modelData
                      implicitHeight: Style.space(24)
                      implicitWidth: Math.min(220, curSourceLabel.implicitWidth + 50)
                      radius: Style.cornerRadius
                      color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.06)
                      borderSpec: Border.controlSpec("normal", Qt.darker(root.contentForeground, 2.6), Color.accent)

                      Row {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 4

                        Text {
                          id: curSourceLabel
                          textFormat: Text.PlainText
                          text: modelData.name
                          font.family: root.contentFontFamily
                          font.pixelSize: 9
                          color: root.contentForeground
                          elide: Text.ElideRight
                          width: parent.width - 36
                          anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                          textFormat: Text.PlainText
                          text: "󰏫"
                          font.family: root.contentFontFamily
                          font.pixelSize: 11
                          color: Color.accent
                          anchors.verticalCenter: parent.verticalCenter
                          MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.startEditCursorSource(modelData)
                          }
                        }

                        Text {
                          textFormat: Text.PlainText
                          text: "󰅖"
                          font.family: root.contentFontFamily
                          font.pixelSize: 11
                          color: "#ef4444"
                          anchors.verticalCenter: parent.verticalCenter
                          MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.deleteCustomCursorSource(modelData.id)
                          }
                        }
                      }
                    }
                  }
                  Item { Layout.fillWidth: true }
                }
              }
            }

            Text {
              textFormat: Text.PlainText
              text: "COMMUNITY & CUSTOM CURSOR PACKS (" + root.cursorSourcesList.length + ")"
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              color: root.contentSubtle
            }

            Repeater {
              model: root.cursorSourcesList

              delegate: BorderSurface {
                required property var modelData
                readonly property bool isBusy: root.isActionRunning && root.activeActionId === ("dl:" + modelData.id)

                width: mainColumn.innerWidth
                implicitHeight: Style.space(56)
                radius: Style.cornerRadius
                color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.03)
                borderSpec: Border.controlSpec("normal", modelData.isCustomSource ? Color.accent : Qt.darker(root.contentForeground, 2.6), Color.accent)

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: Style.space(10)
                  spacing: Style.space(10)

                  Text {
                    textFormat: Text.PlainText
                    text: "󰍛"
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.title
                    color: Color.accent
                  }

                  Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Column {
                      anchors.fill: parent
                      spacing: 2

                      Row {
                        width: parent.width
                        spacing: Style.space(6)
                        Text {
                          textFormat: Text.PlainText
                          text: modelData.name
                          font.family: root.contentFontFamily
                          font.pixelSize: Style.font.caption + 1
                          font.bold: true
                          color: root.contentForeground
                          elide: Text.ElideRight
                          maximumLineCount: 1
                        }
                        Text {
                          textFormat: Text.PlainText
                          text: "by @" + modelData.author + " · " + (modelData.style ? modelData.style.toUpperCase() : "CURSOR")
                          font.family: root.contentFontFamily
                          font.pixelSize: 10
                          color: modelData.isCustomSource ? Color.accent : root.contentSubtle
                        }
                      }

                      Text {
                        width: parent.width
                        textFormat: Text.PlainText
                        text: modelData.description
                        font.family: root.contentFontFamily
                        font.pixelSize: 10
                        color: root.contentSubtle
                        elide: Text.ElideRight
                        maximumLineCount: 1
                      }
                    }
                  }

                  BorderSurface {
                    implicitWidth: Style.space(88)
                    implicitHeight: Style.space(28)
                    radius: Style.cornerRadius
                    color: modelData.installed ? Qt.rgba(0.65, 0.89, 0.63, 0.18) : (dlCurMouse.containsMouse ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.25) : "transparent")
                    borderSpec: Border.controlSpec("normal", modelData.installed ? "#10b981" : Color.accent, Color.accent)

                    Text {
                      anchors.centerIn: parent
                      textFormat: Text.PlainText
                      text: isBusy ? "Fetching..." : (modelData.installed ? "Installed" : "Download")
                      font.family: root.contentFontFamily
                      font.pixelSize: 10
                      font.bold: true
                      color: modelData.installed ? "#10b981" : Color.accent
                    }

                    MouseArea {
                      id: dlCurMouse
                      anchors.fill: parent
                      hoverEnabled: !modelData.installed && !isBusy
                      cursorShape: (modelData.installed || isBusy) ? Qt.ArrowCursor : Qt.PointingHandCursor
                      onClicked: {
                        if (!modelData.installed && !isBusy) root.downloadCursorSource(modelData)
                      }
                    }
                  }
                }
              }
            }
          }

          // --- TAB 5: INSTALLED & REMOVAL MANAGER ---
          Column {
            width: mainColumn.innerWidth
            spacing: Style.space(10)
            visible: root.activeTab === 5

            Text {
              textFormat: Text.PlainText
              text: "USER-DOWNLOADED THEMES & CURSORS (" + root.userInstalledList.length + ")"
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              color: root.contentSubtle
            }

            Text {
              width: mainColumn.innerWidth
              textFormat: Text.PlainText
              text: root.userInstalledList.length === 0 ? "No user-downloaded themes or cursors found. Download packs from Theme Store or Cursor Store to manage them here." : "Remove custom downloads to free disk space or clean up your styling library."
              font.family: root.contentFontFamily
              font.pixelSize: 11
              color: root.contentSubtle
            }

            Repeater {
              model: root.userInstalledList

              delegate: BorderSurface {
                required property var modelData
                readonly property bool isBusy: root.isActionRunning && root.activeActionId === ("rm:" + modelData.id)

                width: mainColumn.innerWidth
                implicitHeight: Style.space(50)
                radius: Style.cornerRadius
                color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.03)
                borderSpec: Border.controlSpec("normal", Qt.darker(root.contentForeground, 2.6), Color.accent)

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: Style.space(10)
                  spacing: Style.space(8)

                  Text {
                    textFormat: Text.PlainText
                    text: modelData.type === "cursor" ? "󰍛" : "󰔎"
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.body
                    color: Color.accent
                  }

                  Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Column {
                      anchors.fill: parent
                      spacing: 2

                      Text {
                        width: parent.width
                        textFormat: Text.PlainText
                        text: modelData.name + " (" + modelData.type.toUpperCase() + ")"
                        font.family: root.contentFontFamily
                        font.pixelSize: Style.font.caption + 1
                        font.bold: true
                        color: root.contentForeground
                        elide: Text.ElideRight
                        maximumLineCount: 1
                      }

                      Text {
                        width: parent.width
                        textFormat: Text.PlainText
                        text: "Path: " + modelData.path
                        font.family: "Monospace"
                        font.pixelSize: 9
                        color: root.contentSubtle
                        elide: Text.ElideMiddle
                        maximumLineCount: 1
                      }
                    }
                  }

                  BorderSurface {
                    implicitWidth: Style.space(70)
                    implicitHeight: Style.space(26)
                    radius: Style.cornerRadius
                    color: rmMouse.containsMouse ? Qt.rgba(0.94, 0.27, 0.27, 0.25) : "transparent"
                    borderSpec: Border.controlSpec("normal", "#ef4444", "#ef4444")

                    Text {
                      anchors.centerIn: parent
                      textFormat: Text.PlainText
                      text: isBusy ? "Deleting..." : "Remove"
                      font.family: root.contentFontFamily
                      font.pixelSize: 10
                      font.bold: true
                      color: "#ef4444"
                    }

                    MouseArea {
                      id: rmMouse
                      anchors.fill: parent
                      hoverEnabled: !isBusy
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.removeItem(modelData.type, modelData.id)
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
