import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// The icon that stands for a group on the bar. Bar.qml mounts it in front of
// the group's members and opens the group while the pointer is over it. The
// icon is a Nerd Font glyph, or the group's own SVG when `svg` is set.
BarWidget {
  id: root
  moduleName: "expanding.group"

  // Bar.qml opens or closes the group's drawer on this.
  signal toggleRequested()

  // Source of the group's SVG: a bundled icon by name, or a file path. Empty
  // means use the glyph.
  readonly property string svgSource: {
    var value = String(setting("svg", "")).trim()
    if (value === "") return ""
    if (value.indexOf("/") === -1 && value.indexOf(".") === -1)
      return Qt.resolvedUrl("../icons/" + value + ".svg").toString()
    var path = value.indexOf("~/") === 0 ? Quickshell.env("HOME") + value.slice(1) : value
    return "file://" + path
  }

  implicitWidth: vertical ? barSize : button.implicitWidth
  implicitHeight: vertical ? button.implicitHeight : barSize

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.svgSource === "" ? String(root.setting("icon", "󰉋")) : ""
    iconComponent: root.svgSource === "" ? null : svgIcon
    tooltipText: String(root.setting("label", ""))
    onPressed: function(b) { if (b === Qt.LeftButton) root.toggleRequested() }
  }

  Component {
    id: svgIcon

    Image {
      source: root.svgSource
      width: 64
      height: 64
      sourceSize: Qt.size(128, 128)
      fillMode: Image.PreserveAspectFit
      smooth: true
    }
  }
}
