import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "../GroupModel.js" as Model

// Permanent settings icon at the end of the bar. Click for a dropdown with the
// basic hover settings and a button that opens the icon group designer.
//
// Mounted by Bar.qml itself (not through bar.layout), so it is always there.
// Settings are read from, and written back to, ~/.config/omarchy/shell.json
// under the `bar` key; the shell hot-reloads the file.
BarWidget {
  id: root
  moduleName: "expanding.settings"

  readonly property string configPath: Quickshell.env("HOME") + "/.config/omarchy/shell.json"

  property var barCfg: ({})
  property var layout: ({})
  property var groups: []

  readonly property color fg: Color.popups.text
  readonly property bool opened: popup.open

  implicitWidth: vertical ? barSize : button.implicitWidth
  implicitHeight: vertical ? button.implicitHeight : barSize

  function parseConfig(raw) {
    var parsed = null
    try { parsed = JSON.parse(raw) } catch (e) { return }
    if (!parsed || typeof parsed !== "object") return
    barCfg = parsed.bar && typeof parsed.bar === "object" ? parsed.bar : {}
    layout = barCfg.layout || {}
    groups = Model.normalize(barCfg.groups)
  }

  function numberOr(key, fallback) {
    return typeof barCfg[key] === "number" ? barCfg[key] : fallback
  }

  function flagOr(key, fallback) {
    return typeof barCfg[key] === "boolean" ? barCfg[key] : fallback
  }

  // Writes are queued so a quick succession of changes can't race on the file.
  property var writeQueue: []

  function writeKey(key, value) {
    var next = {}
    for (var k in barCfg) next[k] = barCfg[k]
    next[key] = value
    barCfg = next
    writeQueue = writeQueue.concat([{ key: key, json: JSON.stringify(value) }])
    pumpWrites()
  }

  function pumpWrites() {
    if (writer.running || writeQueue.length === 0) return
    var job = writeQueue[0]
    writeQueue = writeQueue.slice(1)
    var program = job.key === "" ? '.bar |= del(.[$v[]])' : '.bar[$k] = $v'
    writer.command = ["bash", "-c",
      'f="$HOME/.config/omarchy/shell.json"; [ -s "$f" ] || exit 1; ' +
      'tmp=$(mktemp) && jq -S --arg k "$1" --argjson v "$2" "$3" "$f" >"$tmp" ' +
      '&& mv "$tmp" "$f" && { omarchy-shell -q shell reloadConfig || true; }',
      "bar-settings", job.key, job.json, program]
    writer.running = true
  }

  // Drop keys from `bar` so they fall back to the plugin defaults.
  function resetKeys(keys) {
    var next = {}
    for (var k in barCfg) if (keys.indexOf(k) === -1) next[k] = barCfg[k]
    barCfg = next
    writeQueue = writeQueue.concat([{ key: "", json: JSON.stringify(keys) }])
    pumpWrites()
  }

  // Real icons: grab each module's widget as it is drawn on the bar, so
  // plugins we know nothing about show their own icon in the designer.
  // Modules not currently drawn (hidden, or inactive) keep the glyph fallback.
  property var iconImages: ({})
  property var iconGrabs: []

  function captureIcons() {
    if (!bar) return
    var ids = designer.moduleIds
    for (var i = 0; i < ids.length; i++) {
      var items = bar.moduleWidgets(ids[i])
      for (var j = 0; j < items.length; j++) {
        var item = items[j]
        if (!item || !item.visible || item.width <= 0 || item.height <= 0) continue
        grabIcon(ids[i], item)
        break
      }
    }
  }

  function grabIcon(id, item) {
    item.grabToImage(function(result) {
      // the result owns the image: keep a reference or it is collected
      iconGrabs = iconGrabs.concat([result])
      var next = {}
      for (var k in iconImages) next[k] = iconImages[k]
      next[id] = result.url.toString()
      iconImages = next
    }, Qt.size(Math.ceil(item.width * 2), Math.ceil(item.height * 2)))
  }

  function openDesigner() {
    popup.open = false
    captureIcons()
    designer.visible = true
  }

  function togglePopup() {
    popup.open = !popup.open
  }

  function close() { popup.open = false }

  FileView {
    id: configFile
    path: root.configPath
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.parseConfig(text())
  }

  Process {
    id: writer
    onRunningChanged: if (!running) root.pumpWrites()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰒓"
    tooltipText: "Bar settings"
    onPressed: function(b) { root.togglePopup() }
  }

  GroupDesigner {
    id: designer
    visible: false
    groups: root.groups
    iconImages: root.iconImages
    moduleIds: Model.layoutModuleIds(root.layout, ["omarchy.spacer", "expanding.settings"])
    onGroupsEdited: function(next) { root.writeKey("groups", next) }
  }

  PopupCard {
    id: popup

    anchorItem: button
    bar: root.bar
    owner: root
    contentWidth: Style.space(300)
    contentHeight: fittedContentHeight(content.implicitHeight)

    Column {
      id: content
      width: parent.width
      spacing: Style.spacing.lg

      Text {
        text: "Bar settings"
        color: root.fg
        font.family: Style.font.family
        font.pixelSize: Style.font.title
        font.bold: true
      }

      SettingSlider { label: "Hover expand"; unit: " px"; cfgKey: "hoverExpand"; fallback: 10; from: 0; to: 30; step: 1 }
      SettingSlider { label: "Animation"; unit: " ms"; cfgKey: "hoverAnimationMs"; fallback: 140; from: 0; to: 400; step: 10 }
      SettingSlider { label: "Icon boost"; unit: "x"; cfgKey: "hoverIconBoost"; fallback: 1; from: 1; to: 2; step: 0.05; decimals: 2 }
      SettingSlider { label: "Gap factor"; unit: ""; cfgKey: "hoverGapFactor"; fallback: 1.4; from: 0; to: 2; step: 0.1; decimals: 1 }
      SettingSlider { label: "Icon padding"; unit: " px"; cfgKey: "hoverIconPadding"; fallback: 0; from: 0; to: 20; step: 1 }
      SettingSlider { label: "Hover highlight"; unit: ""; cfgKey: "hoverHighlight"; fallback: 0; from: 0; to: 0.3; step: 0.01; decimals: 2 }

      SettingToggle { label: "Shift windows when expanded"; cfgKey: "hoverShiftWindows"; fallback: true }
      SettingToggle { label: "Stay expanded while a popup is open"; cfgKey: "hoverHoldWhilePopup"; fallback: true }

      Rectangle {
        width: parent.width
        height: 1
        color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.2)
      }

      // Off by default: with it off the bar behaves exactly as before.
      SettingToggle { label: "Icon groups (hover a group icon to expand it)"; cfgKey: "groupingEnabled"; fallback: false }

      SettingToggle {
        visible: root.flagOr("groupingEnabled", false)
        label: "Open groups on hover (off = click the icon)"; cfgKey: "groupOpenOnHover"; fallback: false
      }

      SettingToggle {
        visible: root.flagOr("groupingEnabled", false)
        label: "Pop out grouped icons when their status changes"; cfgKey: "groupStatusPeek"; fallback: true
      }

      SettingSlider {
        visible: root.flagOr("groupingEnabled", false) && root.flagOr("groupStatusPeek", true)
        label: "Status change stays out for"; unit: " ms"; cfgKey: "groupPeekMs"; fallback: 4000; from: 0; to: 15000; step: 500
      }

      SettingSlider {
        visible: root.flagOr("groupingEnabled", false)
        label: "Group animation"; unit: " ms"; cfgKey: "groupAnimationMs"; fallback: 220; from: 0; to: 600; step: 10
      }

      SettingSlider {
        visible: root.flagOr("groupingEnabled", false)
        label: "Group color strength"; unit: ""; cfgKey: "groupHighlight"; fallback: 0.3; from: 0; to: 0.6; step: 0.01; decimals: 2
      }

      SettingSlider {
        visible: root.flagOr("groupingEnabled", false) && !root.flagOr("groupOpenOnHover", false)
        label: "Close after pointer leaves (0 = never)"; unit: " ms"; cfgKey: "groupAutoCloseMs"; fallback: 3000; from: 0; to: 10000; step: 500
      }

      SettingSlider {
        visible: root.flagOr("groupingEnabled", false) && root.flagOr("groupOpenOnHover", false)
        label: "Group closes after"; unit: " ms"; cfgKey: "groupCollapseDelayMs"; fallback: 250; from: 0; to: 1000; step: 50
      }

      PanelButton {
        visible: root.flagOr("groupingEnabled", false)
        text: "Group icons…"
        onClicked: root.openDesigner()
      }

      PanelButton {
        text: "Reset hover settings to defaults"
        onClicked: root.resetKeys(["hoverExpand", "hoverAnimationMs", "hoverIconBoost", "hoverGapFactor",
          "hoverIconPadding", "hoverHighlight", "hoverShiftWindows", "hoverHoldWhilePopup"])
      }
    }
  }

  component PanelButton: Rectangle {
    id: panelButton

    property string text: ""
    signal clicked()

    width: parent.width
    height: visible ? Style.space(32) : 0
    radius: Style.cornerRadius
    color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, buttonMouse.containsMouse ? 0.16 : 0.08)

    Text {
      anchors.centerIn: parent
      text: panelButton.text
      color: root.fg
      font.family: Style.font.family
      font.pixelSize: Style.font.subtitle
    }

    MouseArea {
      id: buttonMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: panelButton.clicked()
    }
  }

  component SettingSlider: Item {
    id: row

    property string label: ""
    property string unit: ""
    property string cfgKey: ""
    property real fallback: 0
    property real from: 0
    property real to: 1
    property real step: 1
    property int decimals: 0

    readonly property real current: root.numberOr(cfgKey, fallback)

    width: parent.width
    height: sliderLabel.implicitHeight + slider.implicitHeight

    Text {
      id: sliderLabel
      text: row.label
      color: root.fg
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }

    Text {
      anchors.right: parent.right
      text: row.current.toFixed(row.decimals) + row.unit
      color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.7)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }

    PanelSlider {
      id: slider
      anchors.top: sliderLabel.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      bar: root.bar
      value: row.current
      minimum: row.from
      maximum: row.to
      step: row.step
      onReleased: function(v) {
        var snapped = Math.round(v / row.step) * row.step
        root.writeKey(row.cfgKey, Number(snapped.toFixed(4)))
      }
    }
  }

  component SettingToggle: Item {
    id: toggleRow

    property string label: ""
    property string cfgKey: ""
    property bool fallback: true

    width: parent.width
    height: Math.max(toggleLabel.implicitHeight, sw.height)

    Text {
      id: toggleLabel
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: parent.left
      anchors.right: sw.left
      anchors.rightMargin: 8
      text: toggleRow.label
      color: root.fg
      elide: Text.ElideRight
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }

    ToggleSwitch {
      id: sw
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      checked: root.flagOr(toggleRow.cfgKey, toggleRow.fallback)
      onToggled: root.writeKey(toggleRow.cfgKey, !checked)
    }
  }
}
