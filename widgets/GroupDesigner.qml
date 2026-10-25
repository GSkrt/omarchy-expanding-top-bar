import QtQuick
import Quickshell
import qs.Commons
import "../GroupModel.js" as Model

// Floating window for building icon groups by drag and drop. It only edits the
// groups list it is given and reports the result through groupsEdited(); it
// knows nothing about shell.json.
FloatingWindow {
  id: win

  property var groups: []
  property var moduleIds: []
  // moduleId -> image url of that widget as drawn on the bar (see BarSettings)
  property var iconImages: ({})
  signal groupsEdited(var groups)

  // which panel the dragged chip comes from, so that panel paints on top
  property string dragPanel: ""

  readonly property color fg: Color.popups.text
  readonly property color bg: Color.popups.background
  readonly property color accent: Color.accent

  title: "Group bar icons"
  color: bg
  implicitWidth: 980
  implicitHeight: 680
  minimumSize: Qt.size(640, 420)

  readonly property var ungrouped: moduleIds.filter(function(id) { return Model.groupOf(groups, id) === "" })

  function apply(next) {
    groups = next
    groupsEdited(next)
  }

  function labelFor(id) { return Model.labelFor(id) }
  function iconFor(id) { return Model.iconFor(id) }

  component Chip: Item {
    id: chip

    property string moduleId: ""
    property string panel: ""

    width: body.width
    height: 30

    Rectangle {
      id: body

      property string moduleId: chip.moduleId

      readonly property string image: win.iconImages[chip.moduleId] || ""
      readonly property real iconWidth: image !== ""
        ? Math.min(110, chipImage.implicitHeight > 0 ? chipImage.implicitWidth * 20 / chipImage.implicitHeight : 20)
        : chipIcon.implicitWidth

      width: iconWidth + chipText.implicitWidth + 32
      height: parent.height
      radius: height / 2
      color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, mouse.pressed ? 0.22 : mouse.containsMouse ? 0.16 : 0.10)
      border.width: 1
      border.color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, 0.25)
      Behavior on color { ColorAnimation { duration: 90 } }

      Drag.active: mouse.drag.active
      Drag.source: body
      Drag.hotSpot.x: width / 2
      Drag.hotSpot.y: height / 2

      Image {
        id: chipImage
        visible: body.image !== ""
        anchors.left: parent.left
        anchors.leftMargin: 11
        anchors.verticalCenter: parent.verticalCenter
        source: body.image
        height: 20
        width: body.iconWidth
        fillMode: Image.PreserveAspectFit
        smooth: true
      }

      Text {
        id: chipIcon
        visible: body.image === ""
        anchors.left: parent.left
        anchors.leftMargin: 11
        anchors.verticalCenter: parent.verticalCenter
        text: win.iconFor(chip.moduleId)
        color: win.fg
        font.family: Style.font.family
        font.pixelSize: Style.font.title
      }

      // marks system Omarchy icons, to tell them apart from plugins
      Rectangle {
        visible: Model.isSystem(chip.moduleId)
        width: 7
        height: 7
        radius: 3.5
        color: win.accent
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 2
        anchors.topMargin: 2
      }

      Text {
        id: chipText
        anchors.left: parent.left
        anchors.leftMargin: 11 + body.iconWidth + 8
        anchors.verticalCenter: parent.verticalCenter
        text: win.labelFor(chip.moduleId)
        color: win.fg
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }

      MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        drag.target: body
        onPressed: win.dragPanel = chip.panel
        onReleased: {
          body.Drag.drop()
          body.x = 0
          body.y = 0
          win.dragPanel = ""
        }
      }
    }
  }

  component SmallButton: Rectangle {
    id: btn

    property string text: ""
    signal clicked()

    width: btnText.implicitWidth + 20
    height: 28
    radius: height / 2
    color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, btnMouse.containsMouse ? 0.18 : 0.08)
    border.width: 1
    border.color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, 0.25)

    Text {
      id: btnText
      anchors.centerIn: parent
      text: btn.text
      color: win.fg
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }

    MouseArea {
      id: btnMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: btn.clicked()
    }
  }

  Item {
    anchors.fill: parent
    anchors.margins: 20

    Text {
      id: heading
      text: "Drag icons into groups"
      color: win.fg
      font.family: Style.font.family
      font.pixelSize: Style.font.title
      font.bold: true
    }

    Text {
      id: hint
      anchors.top: heading.bottom
      anchors.topMargin: 4
      text: "Drop an icon on a group to add it, back on the left to remove it, or on the empty box to start a new group. Saved automatically.  A dot marks system Omarchy icons."
      color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, 0.7)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      width: parent.width
      wrapMode: Text.WordWrap
    }

    // Available (ungrouped) icons
    Rectangle {
      id: available

      anchors.left: parent.left
      anchors.top: hint.bottom
      anchors.topMargin: 16
      anchors.bottom: parent.bottom
      width: Math.max(260, Math.round(parent.width * 0.34))
      radius: Style.cornerRadius
      color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, availableDrop.containsDrag ? 0.14 : 0.05)
      border.width: 1
      border.color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, availableDrop.containsDrag ? 0.5 : 0.2)
      z: win.dragPanel === "available" ? 10 : 0

      DropArea {
        id: availableDrop
        anchors.fill: parent
        onDropped: function(drop) {
          if (drop.source && drop.source.moduleId !== undefined)
            win.apply(Model.removeFromGroup(win.groups, drop.source.moduleId))
        }
      }

      Text {
        id: availableTitle
        x: 12
        y: 10
        text: "Available"
        color: win.fg
        font.family: Style.font.family
        font.pixelSize: Style.font.subtitle
        font.bold: true
      }

      Flickable {
        anchors.top: availableTitle.bottom
        anchors.topMargin: 10
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        contentWidth: width
        contentHeight: availableFlow.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        interactive: win.dragPanel === ""

        Flow {
          id: availableFlow
          width: parent.width
          spacing: 8

          Repeater {
            model: win.ungrouped
            Chip {
              required property string modelData
              moduleId: modelData
              panel: "available"
            }
          }
        }
      }

      Text {
        visible: win.ungrouped.length === 0
        anchors.centerIn: parent
        text: "Every icon is in a group"
        color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, 0.5)
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }

    // Groups
    Item {
      id: groupsArea

      anchors.left: available.right
      anchors.leftMargin: 16
      anchors.right: parent.right
      anchors.top: available.top
      anchors.bottom: parent.bottom
      z: win.dragPanel === "groups" ? 10 : 0

      Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: groupsColumn.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        interactive: win.dragPanel === ""

        Column {
          id: groupsColumn
          width: flick.width
          spacing: 12

          Repeater {
            model: win.groups

            Rectangle {
              id: card

              required property var modelData
              required property int index
              readonly property string groupId: modelData.id

              width: groupsColumn.width
              readonly property color groupColor: Model.resolveColor(modelData, index)
              height: 152 + memberZones.implicitHeight + 14
              radius: Style.cornerRadius
              color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, cardDrop.containsDrag ? 0.14 : 0.05)
              border.width: 1
              border.color: cardDrop.containsDrag ? win.accent : Qt.rgba(win.fg.r, win.fg.g, win.fg.b, 0.2)

              DropArea {
                id: cardDrop
                anchors.fill: parent
                onDropped: function(drop) {
                  if (drop.source && drop.source.moduleId !== undefined)
                    win.apply(Model.addToGroup(win.groups, card.groupId, drop.source.moduleId))
                }
              }

              // stripe in the group's drawer color
              Rectangle {
                width: 4
                radius: 2
                color: card.groupColor
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 6
              }

              // the group's glyph; paste any Nerd Font character
              TextInput {
                id: iconText
                x: 12
                y: 10
                width: 28
                text: card.modelData.icon
                color: win.fg
                selectionColor: win.accent
                font.family: Style.font.family
                font.pixelSize: Style.font.title
                maximumLength: 4
                onEditingFinished: {
                  var glyph = text.trim()
                  if (glyph !== "" && glyph !== card.modelData.icon)
                    win.apply(Model.setGroupIcon(win.groups, card.groupId, glyph))
                  else text = card.modelData.icon
                }
              }

              TextInput {
                id: nameInput
                anchors.left: iconText.right
                anchors.leftMargin: 8
                anchors.verticalCenter: iconText.verticalCenter
                width: card.width - 160
                text: card.modelData.label
                color: win.fg
                selectionColor: win.accent
                font.family: Style.font.family
                font.pixelSize: Style.font.subtitle
                font.bold: true
                clip: true
                onEditingFinished: {
                  var name = text.trim()
                  if (name !== "" && name !== card.modelData.label)
                    win.apply(Model.renameGroup(win.groups, card.groupId, name))
                  else text = card.modelData.label
                }
              }

              SmallButton {
                anchors.right: parent.right
                anchors.rightMargin: 10
                y: 8
                text: "Delete"
                onClicked: win.apply(Model.deleteGroup(win.groups, card.groupId))
              }

              // optional custom SVG, shown on the bar instead of the glyph
              Text {
                id: svgLabel
                x: 12
                y: 46
                text: "SVG"
                color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, 0.7)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }

              Rectangle {
                anchors.left: svgLabel.right
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.rightMargin: 12
                y: 40
                height: 26
                radius: 6
                color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, 0.06)
                border.width: 1
                border.color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, svgInput.activeFocus ? 0.5 : 0.2)

                TextInput {
                  id: svgInput
                  anchors.fill: parent
                  anchors.leftMargin: 8
                  anchors.rightMargin: 8
                  verticalAlignment: TextInput.AlignVCenter
                  text: card.modelData.svg
                  color: win.fg
                  selectionColor: win.accent
                  font.family: Style.font.family
                  font.pixelSize: Style.font.caption
                  clip: true
                  onEditingFinished: {
                    if (text.trim() !== card.modelData.svg)
                      win.apply(Model.setGroupSvg(win.groups, card.groupId, text))
                  }

                  Text {
                    visible: svgInput.text === "" && !svgInput.activeFocus
                    anchors.verticalCenter: parent.verticalCenter
                    text: "bundled name or ~/path/to/icon.svg (empty = glyph)"
                    color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, 0.4)
                    font: svgInput.font
                  }
                }
              }

              // pick one of the bundled icons, or the glyph
              Text {
                id: iconLabel
                x: 12
                y: 80
                text: "Icon"
                color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, 0.7)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }

              Row {
                anchors.left: iconLabel.right
                anchors.leftMargin: 8
                y: 74
                spacing: 4

                Rectangle {
                  width: 28
                  height: 28
                  radius: 6
                  color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, card.modelData.svg === "" ? 0.2 : 0.06)
                  border.width: 1
                  border.color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, card.modelData.svg === "" ? 0.7 : 0.2)
                  Text {
                    anchors.centerIn: parent
                    text: card.modelData.icon
                    color: win.fg
                    font.family: Style.font.family
                    font.pixelSize: Style.font.title
                  }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.apply(Model.setGroupSvg(win.groups, card.groupId, ""))
                  }
                }

                Repeater {
                  model: Model.BUILTIN_ICONS
                  Rectangle {
                    required property string modelData
                    width: 28
                    height: 28
                    radius: 6
                    color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, card.modelData.svg === modelData ? 0.2 : 0.06)
                    border.width: 1
                    border.color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, card.modelData.svg === modelData ? 0.7 : 0.2)
                    Image {
                      anchors.centerIn: parent
                      width: 18
                      height: 18
                      source: Qt.resolvedUrl("../icons/" + parent.modelData + ".svg")
                      sourceSize: Qt.size(36, 36)
                      fillMode: Image.PreserveAspectFit
                    }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: win.apply(Model.setGroupSvg(win.groups, card.groupId, parent.modelData))
                    }
                  }
                }
              }

              // drawer color: pick one, or "auto" for the palette color
              Text {
                id: colorLabel
                x: 12
                y: 114
                text: "Color"
                color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, 0.7)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }

              Row {
                anchors.left: colorLabel.right
                anchors.leftMargin: 8
                y: 110
                spacing: 6

                Rectangle {
                  width: 24
                  height: 24
                  radius: 12
                  color: "transparent"
                  border.width: 1
                  border.color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, card.modelData.color === "" ? 0.9 : 0.35)
                  Text {
                    anchors.centerIn: parent
                    text: "auto"
                    color: win.fg
                    font.family: Style.font.family
                    font.pixelSize: 8
                  }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.apply(Model.setGroupColor(win.groups, card.groupId, ""))
                  }
                }

                Repeater {
                  model: Model.PALETTE
                  Rectangle {
                    required property string modelData
                    width: 24
                    height: 24
                    radius: 12
                    color: modelData
                    border.width: card.modelData.color === modelData ? 2 : 0
                    border.color: win.fg
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: win.apply(Model.setGroupColor(win.groups, card.groupId, parent.modelData))
                    }
                  }
                }

                Rectangle {
                  width: 78
                  height: 24
                  radius: 6
                  color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, 0.06)
                  border.width: 1
                  border.color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, hexInput.activeFocus ? 0.5 : 0.2)

                  TextInput {
                    id: hexInput
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    text: card.modelData.color
                    color: win.fg
                    selectionColor: win.accent
                    font.family: Style.font.family
                    font.pixelSize: Style.font.caption
                    maximumLength: 7
                    onEditingFinished: {
                      var v = text.trim()
                      if (/^#[0-9a-fA-F]{6}$/.test(v)) win.apply(Model.setGroupColor(win.groups, card.groupId, v))
                      else text = card.modelData.color
                    }

                    Text {
                      visible: hexInput.text === "" && !hexInput.activeFocus
                      anchors.verticalCenter: parent.verticalCenter
                      text: "#rrggbb"
                      color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, 0.4)
                      font: hexInput.font
                    }
                  }
                }
              }

              // Two zones: icons that pop out when their status changes, and
              // quiet ones. An icon is in exactly one of them.
              Column {
                id: memberZones
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 152
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Repeater {
                  model: [
                    { quiet: false, title: "Pops out on status change", hint: "Drop icons you want status updates from" },
                    { quiet: true, title: "Quiet", hint: "Drop icons that don't need status updates" }
                  ]

                  Rectangle {
                    id: zone

                    required property var modelData
                    readonly property var zoneMembers: card.modelData.members.filter(function(m) {
                      return (card.modelData.quiet.indexOf(m) !== -1) === zone.modelData.quiet
                    })

                    width: memberZones.width
                    height: 26 + Math.max(zoneFlow.implicitHeight, 26) + 10
                    radius: 8
                    color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, zoneDrop.containsDrag ? 0.12 : 0.03)
                    border.width: 1
                    border.color: zoneDrop.containsDrag ? win.accent : Qt.rgba(win.fg.r, win.fg.g, win.fg.b, 0.12)

                    DropArea {
                      id: zoneDrop
                      anchors.fill: parent
                      onDropped: function(drop) {
                        if (!drop.source || drop.source.moduleId === undefined) return
                        var id = drop.source.moduleId
                        var moved = Model.addToGroup(win.groups, card.groupId, id)
                        win.apply(Model.setQuiet(moved, card.groupId, id, zone.modelData.quiet))
                      }
                    }

                    Text {
                      x: 10
                      y: 6
                      text: zone.modelData.title
                      color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, 0.7)
                      font.family: Style.font.family
                      font.pixelSize: Style.font.caption
                    }

                    Text {
                      visible: zone.zoneMembers.length === 0
                      x: 10
                      y: 30
                      text: zone.modelData.hint
                      color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, 0.4)
                      font.family: Style.font.family
                      font.pixelSize: Style.font.caption
                    }

                    Flow {
                      id: zoneFlow
                      x: 10
                      y: 26
                      width: parent.width - 20
                      spacing: 8

                      Repeater {
                        model: zone.zoneMembers
                        Chip {
                          required property string modelData
                          moduleId: modelData
                          panel: "groups"
                        }
                      }
                    }
                  }
                }
              }
            }
          }

          // Drop here to start a new group from the dragged icon
          Rectangle {
            id: newGroup

            width: groupsColumn.width
            height: 64
            radius: Style.cornerRadius
            color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, newDrop.containsDrag ? 0.14 : 0.0)
            border.width: 1
            border.color: newDrop.containsDrag ? win.accent : Qt.rgba(win.fg.r, win.fg.g, win.fg.b, 0.25)

            DropArea {
              id: newDrop
              anchors.fill: parent
              onDropped: function(drop) {
                if (!drop.source || drop.source.moduleId === undefined) return
                var made = Model.createGroup(win.groups, "New group")
                var id = made[made.length - 1].id
                win.apply(Model.addToGroup(made, id, drop.source.moduleId))
              }
            }

            Text {
              anchors.centerIn: parent
              text: "Drop an icon here for a new group"
              color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, 0.6)
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
          }

          SmallButton {
            text: "+ Empty group"
            onClicked: win.apply(Model.createGroup(win.groups, "New group"))
          }
        }
      }
    }
  }
}
