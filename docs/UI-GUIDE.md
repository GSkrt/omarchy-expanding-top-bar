# UI guide

How to work on the look of the bar. Written for someone who has not touched
this codebase before. Read [PROPOSAL.md](PROPOSAL.md) first for what we are
building; this file is about *how to work on it*.

How to get the code and send changes back (including what to do without write access) is in [CONTRIBUTING.md](../CONTRIBUTING.md).

## 0. Where the UI lives now

The group feature is implemented, so you can change the real thing instead of
building against a mock. Which file draws what:

| You want to change | File | Look for |
|---|---|---|
| The group designer window (drag and drop, cards, colors, icon picker) | `widgets/GroupDesigner.qml` | `Chip`, group `card`, `memberZones` |
| The settings dropdown (sliders, toggles) | `widgets/BarSettings.qml` | `SettingSlider`, `SettingToggle`, `PopupCard` |
| The group icon on the bar (glyph or SVG) | `widgets/GroupHandle.qml` | `svgSource`, `BarIconButton` |
| The group background pill and the drawer that opens beside the icon | `Bar.qml`, inside `ModuleSlot` | `groupDrawer`, `drawerPill` |
| Group colors, palette, bundled icon list, data helpers | `GroupModel.js` | `PALETTE`, `BUILTIN_ICONS` |
| Which groups exist, open/close behavior, status pop-out timing | `Bar.qml` | `groupedLayout`, `toggleGroup`, `notePeek` |

Settings are stored in `~/.config/omarchy/shell.json` under `bar`:

| Key | Default | Meaning |
|---|---|---|
| `groupingEnabled` | `false` | Turn the whole feature on |
| `groups` | `[]` | `{ id, label, icon, svg, color, quiet, members }` per group |
| `groupOpenOnHover` | `false` | `false`: click the group icon; `true`: open on hover |
| `groupAutoCloseMs` | `3000` | Click mode: close this long after the pointer leaves the bar (0 = never) |
| `groupCollapseDelayMs` | `250` | Hover mode: close delay |
| `groupAnimationMs` | `220` | Drawer open/close speed (separate from `hoverAnimationMs`) |
| `groupHighlight` | `0.3` | Strength of the group color background |
| `groupStatusPeek` | `true` | Icons pop out when their status changes |
| `groupPeekMs` | `4000` | How long a popped-out icon stays |

## 1. Editing by hand

Everything is plain QML. The workflow:

1. Edit a file from the table above.
2. Run `omarchy-restart-shell`. **A shell reload is not enough** for QML changes;
   a restart is. The bar blinks for a few seconds.
3. Read the log for errors:
   `quickshell log -p /usr/share/omarchy/shell -t 400 | grep -i expanding-top-bar`

**If the bar suddenly looks like the stock Omarchy bar**, your QML has an error
and the shell fell back to `omarchy.bar`. The log says why. The mistakes that did
this while building the feature:

- an `id` starting with a capital letter (`id: Foo`; ids must be lowercase first)
- an inline `component` that contains itself ("Inline components form a cycle")
- two handlers for the same signal in one object (`onActivePopoutChanged` twice;
  "Property value set multiple times")

Fix it, restart, and the bar comes back.

### Seeing a state you can't easily trigger

Open drawers, status pop-outs and the expanded bar need a pointer or a real
device change. To look at them without that, temporarily force the state in
`Bar.qml`, restart, screenshot, then **remove it again**:

```qml
property var openGroups: ({"new-group": true})            // drawer open
readonly property bool barExpanded: true                  // bar in hover state
```

and a throwaway `Timer { onTriggered: root.notePeek("group-id", "module.id") }`
for the status pop-out. Screenshots: `grim -g "1100,0 820x44" shot.png`.
`hyprctl` cursor moves do not reliably produce hover events in the shell, so don't
rely on them for hover testing.

### Things the bar code already guarantees (don't undo them)

- **Nothing shifts when a group opens.** The group icon has a fixed size and the
  drawer is drawn over its neighbours. That is deliberate: pushing neighbours aside
  made the icon you aimed at slide away from the pointer.
- **A closed drawer must be invisible**, not just clipped: hidden members still take
  clicks otherwise. That is `visible: slot.openT > 0.001` on the members item.
- **Scale is cancelled** (`k = 1 / slot.scale`) inside the drawer, so pills line up
  with their slot instead of stretching into neighbours when the bar is hovered.
- Status pop-out only looks at icon glyphs, images and `active`, never plain text, so
  clocks and temperatures don't count as news.

## 1b. Setup

You need Omarchy with `omarchy-shell` running (it is a Quickshell shell).

```bash
git clone https://github.com/GSkrt/omarchy-expanding-top-bar.git
cd omarchy-expanding-top-bar
git checkout develop
```

Then make Omarchy use your clone. The plugin lives in
`~/.config/omarchy/plugins/io.github.gskrt.expanding-top-bar/`. Gregor's copy is
a **symlink to the git checkout**, so edits show up in the running bar without
copying anything. Do the same:

```bash
omarchy plugin add https://github.com/GSkrt/omarchy-expanding-top-bar.git --enable
rm -rf ~/.config/omarchy/plugins/io.github.gskrt.expanding-top-bar
ln -s "$PWD" ~/.config/omarchy/plugins/io.github.gskrt.expanding-top-bar
```

Quickshell normally reloads QML when files change. If the bar does not pick up
an edit, restart the shell. A QML syntax error usually leaves the bar blank or
unchanged. Look at the shell's log output for the error before assuming your
change did nothing.

To go back to the stock bar:

```bash
omarchy plugin enable omarchy.bar
```

## 2. Workflow

- Branch from `develop`, not `master`. `master` is what users install.
- Small commits, small PRs against `develop`.
- Don't change version numbers or `manifest.json`. Releases are done by Gregor.

## 3. Map of the code

| File | What it is |
|---|---|
| `Bar.qml` | The whole bar (about 2250 lines). Start with the sections below, not a top-to-bottom read |
| `widgets/*.qml` | One file per bar widget, each with a `*.manifest.json` beside it |
| `indicators/*.qml` | Small status icons shown by the Indicators widget |
| `widgets/Indicators.qml` | Closest thing to what groups will be: hidden/revealed icons |
| `widgets/Tray.qml` | Hover-reveal drawer; another precedent |
| `BarModel.js` | Pure JS helpers for reading config (no UI) |

Useful places inside `Bar.qml`:

- `hoverProgress` (around line 572): one 0..1 value that drives every hover
  effect. **Use it, don't invent a second hover animation.**
- `ModuleList` / `ModuleSlot` (around lines 1805 and 1859): how each widget is
  placed, scaled and given room.
- `hoverGlow` inside `ModuleSlot`: the soft highlight pill behind a hovered icon.
  Reuse the idea for group highlights.

## 4. Rules that keep the animation smooth

These come from the README's "How the animation works" section. Short version:

1. **Scaling is visual only.** The bar scales each widget up on hover, but
   layout does not know. The slot reserves extra width separately. Don't set
   `scale` on a widget's root; it will fight the bar. Scale inner items if you
   must.
2. **Drive visuals from progress values** (`bar.hoverProgress`, and the
   `expandProgress` / `popProgress` described in the proposal). Don't start your
   own `NumberAnimation` for something that already has a progress value;
   independent animations drift apart and look like jitter.
3. **Never resize the bar window.** It is always as tall as the fully expanded
   bar, and only the drawn bar inside grows. Draw inside it.
4. **Round sizes to whole pixels** when layout is animating, or text blurs.
5. **Hover intent.** A widget counts as hovered after 40 ms of the pointer
   resting on it. Keep that delay, or neighbouring widgets will flip-flop as they
   resize under a stationary pointer.
6. **All four bar positions.** `bar.vertical` is true for left/right bars. Use
   `bar.vertical` to switch `Row`/`Column`, width/height. Test top and left at
   least.

## 5. Writing a new component

Bar widgets extend `BarWidget` (from `qs.Ui`). The smallest real example is
`widgets/Spacer.qml`; a single-icon widget is `widgets/Microphone.qml`.

```qml
import QtQuick
import qs.Ui

BarWidget {
  id: root
  moduleName: "my.widget"

  implicitWidth: vertical ? barSize : 28
  implicitHeight: vertical ? 28 : barSize

  BarIconButton {
    anchors.fill: parent
    bar: root.bar
    text: "󰒓"
    tooltipText: "Settings"
    onPressed: function(button) { /* open panel */ }
  }
}
```

Each widget also needs a manifest next to it (copy `widgets/Spacer.manifest.json`
and change the ids).

The bar injects these properties into widgets; use them instead of hardcoding:

- Colors: `bar.foreground`, `bar.background`, `bar.urgent`. They follow the
  Omarchy theme live, so **never hardcode colors**. For subtle fills, use
  `bar.foreground` at low opacity, as `hoverGlow` does.
- Font: `bar.fontFamily`. Icons are Nerd Font glyphs in `text:`.
- Size: `bar.barSize` (grows on hover), `bar.vertical`.
- Tooltips: `bar.showTooltip(target, text)` / `bar.hideTooltip(target)`.
- Popups: `bar.requestPopout(owner)` / `bar.releasePopout(owner)` (only one popup
  at a time).

`import qs.Commons` gives `Style` (spacing, corner radius) and `Color`. Prefer
`Style.space(n)` and `Style.cornerRadius` over magic numbers so it matches the
rest of Omarchy.

## 6. Changing the UI without the real bar

The logic exists, so most work can be done live (section 0). If you want to try a
component on its own first, keep it **dumb**: properties in, visuals out. A
timer that decides *when* something opens belongs in `Bar.qml`, not in a
component. If you need data that isn't there, add it to `GroupModel.js` and
mention it in [PROPOSAL.md](PROPOSAL.md) in the same PR.

## 7. Checklist before opening a PR

The full test pass is in [TESTING.md](TESTING.md); run the sections your change touches.


- [ ] Works on a top bar and on a left bar
- [ ] Works in a light and a dark theme (switch themes, no hardcoded colors)
- [ ] Hover in, hover out, and sweeping across without resting all look right
- [ ] No jitter when the pointer rests on a border between two widgets
- [ ] Animation length follows `bar.hoverAnimationDuration` (so `hoverAnimationMs: 0` makes it instant)
- [ ] No bar-window resizing, no layout changes outside your component
- [ ] A screenshot or short gif in the PR description

## 8. Style of the code

Match what's there: 2-space indent, no semicolons, `id: root` at the top of a
component, properties first, then functions, then child items. Comments explain
*why*, not what.
