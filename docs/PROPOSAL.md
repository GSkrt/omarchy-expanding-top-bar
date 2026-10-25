# Proposal: settings, icon groups, status pop-out

Status: **draft**. Nothing here is implemented yet. Open questions are at the
bottom; please argue with anything in this file.

Companion docs:

- [UI-GUIDE.md](UI-GUIDE.md): how to work on the QML/UI side
- [UI-DRAFT.md](UI-DRAFT.md): first sketch of how it should look

## Goal

The bar already grows and magnifies on hover. Three things are missing:

1. A **settings icon** at the end of the bar, to configure the bar's behavior
   without hand-editing `~/.config/omarchy/shell.json`.
2. **Icon groups.** Icons that share something (a category, a purpose) collapse
   into one group icon. Hovering the group expands it.
3. **Status pop-out.** When an icon in a group shows a new status, it pops out of
   its group so you notice it, stays visible for a predefined time, then tucks
   back in.

## Behavior

### Grouping

- A group has an id, a label, a group icon and a list of member modules
  (the same module ids used in `bar.layout`, e.g. `omarchy.bluetooth`).
- Collapsed: the group shows as one icon (or a compact stack of its members).
- Hover over the group: it expands and reveals its members in place.
- Pointer leaves: it collapses after a short delay (`groupCollapseDelayMs`).
- Groups are optional. A module that is in no group behaves exactly as today.

### Status pop-out

- "Status change" means a member's state changed in a way worth showing, for
  example Bluetooth connected, mic went live, DND toggled.
- The changed icon pops out of its group (visible even though the group is
  collapsed), then returns after `revealTimeoutMs`.
- If a second icon changes meanwhile, it pops out too; each icon has its own
  timer.
- If the user hovers the group while an icon is popped out, normal hover
  expansion wins and the pop-out timer is cancelled.

### Group designer (drag and drop)

- Part of the settings panel: a visual editor for groups, so nobody has to
  write the `groups` JSON by hand.
- Shows all available bar modules as draggable chips, and the groups as drop
  targets. Drag a chip into a group to add it, out of a group to remove it,
  within a group to reorder.
- Dropping a chip on empty space creates a new group; groups can be renamed,
  given an icon, and deleted.
- Edits change the `groups` config live, so the real bar shows the result as you
  drag (the config hot-reloads).
- A module can be in at most one group.
- Split: the UI contributor builds the drag and drop interaction and the look;
  Gregor provides the model it edits (`addToGroup`, `removeFromGroup`,
  `moveWithinGroup`, `createGroup`, `renameGroup`, `deleteGroup`).

### Settings

- Settings icon sits at the very end of the bar and opens a panel.
- The panel contains the group designer above and edits `revealTimeoutMs`,
  `groupCollapseDelayMs`, and (later) the existing `hover*` options from the
  README.
- Values are written to `shell.json` under `bar` so the existing hot-reload keeps
  working.

## Ownership

| Area | Owner | Files (planned) |
|---|---|---|
| Data model, grouping rules, status-change detection, timers, config read/write | Gregor | `GroupModel.js`, changes in `Bar.qml` (`ModuleList`/`ModuleSlot`), `widgets/Settings.qml` logic |
| Visuals: group icon, expanded/collapsed look, pop-out look, animations, settings icon and panel layout | UI contributor | new `ui/` QML components, styling of the above |

The rule of thumb: **logic produces state, UI renders state.** UI components
should not decide *when* something expands or pops out; they receive that as
properties and decide *how it looks*.

## Contract between logic and UI

This is the interface the UI is built against, so it can be mocked before the
logic exists. Property names are a proposal and can change; change them in this
file when they do.

### Config (`shell.json`, under `bar`)

```json
{
  "bar": {
    "groups": [
      {
        "id": "connectivity",
        "label": "Connectivity",
        "icon": "󰛳",
        "members": ["omarchy.network", "omarchy.bluetooth", "omarchy.tailscale"]
      }
    ],
    "revealTimeoutMs": 4000,
    "groupCollapseDelayMs": 250
  }
}
```

### State a group component receives

| Property | Type | Meaning |
|---|---|---|
| `groupId`, `label`, `icon` | string | From config |
| `members` | list | Member modules, in order |
| `expanded` | bool | Group is open because of hover |
| `expandProgress` | real 0..1 | Animated value for expand/collapse; drive visuals from this, don't run a second animation |
| `poppedOut` | list of module ids | Members currently popped out because of a status change |
| `hasPoppedOut` | bool | Convenience: `poppedOut.length > 0` |

### State a member icon receives

| Property | Type | Meaning |
|---|---|---|
| `inGroup` | bool | Rendered inside a group |
| `groupExpanded` | bool | Its group is open |
| `popped` | bool | This icon is currently popped out |
| `popProgress` | real 0..1 | Animated pop-out amount (0 tucked in, 1 fully out) |

### Settings panel

The panel reads and writes through one object exposing the config keys above
(`groups`, `revealTimeoutMs`, `groupCollapseDelayMs`) plus `save()`. Until the
real one exists, mock it with a plain JS object in a test QML file.

The group designer additionally needs:

| Member | Meaning |
|---|---|
| `availableModules` | List of `{ id, label, icon }` for every module that can be grouped |
| `groupOf(moduleId)` | Group id the module is in, or `""` |
| `createGroup(label)`, `renameGroup(id, label)`, `setGroupIcon(id, icon)`, `deleteGroup(id)` | Group edits |
| `addToGroup(groupId, moduleId, index)` | Add or move a module into a group at a position (removes it from its old group) |
| `removeFromGroup(moduleId)` | Take a module out of its group |

## Implementation notes

- `Bar.qml` already has the hover machinery: one `hoverProgress` drives bar
  thickness, icon scale, and reserved room. Groups must reuse it so their size
  changes stay in step with the rest of the bar.
- `widgets/Indicators.qml` already implements "inactive icons hidden, active ones
  shown, reveal on hover" with a clipped width animation. It is the closest
  existing precedent for a group and is worth reading first.
- `widgets/Tray.qml` has a hover-reveal drawer, another precedent.
- Status-change detection: indicators already expose an `active` property.
  Other widgets do not have a common signal yet. Proposal: widgets may declare
  an optional `statusChanged()` signal (or a `statusKey` property) and the group
  logic connects to it when present. Widgets without it simply never pop out.
- Layout: a group is one slot in `ModuleList`. Expanding it changes its
  `implicitWidth`, and the existing slot code already reserves room for that.

## Phases

1. **Mockups.** UI contributor builds the group, pop-out and settings visuals
   against a mocked model. No changes to `Bar.qml` needed.
2. **Model.** Gregor implements `GroupModel.js` and wires it into `Bar.qml`.
3. **Integration.** Replace the mocks with the real model; tune animations.
4. **Settings and designer.** Panel and drag/drop group designer write config;
   hot-reload verified.
5. **Release.** Bump `manifest.json`, update the README, merge `develop` into
   `master`.

## Open questions

- How are groups chosen by default: manual only, or suggested by category?
- Which widgets get a status-change signal first? Suggestion: Bluetooth,
  microphone, network, indicators.
- Default for `revealTimeoutMs`?
- Collapsed group look: single icon, stack of mini icons, or icon plus count badge?
- Vertical bars (left/right): every widget must work in all four positions, so
  groups must too.
- Should groups be reorderable by drag, like normal widgets?
