# Expanding Top Bar

An [Omarchy](https://omarchy.org/) shell bar plugin, cloned from the
built-in `omarchy.bar`, that grows thicker and scales up its widgets/icons
while the pointer is hovering over it, then animates back down when the
pointer leaves.

## What it changes vs. the stock bar

- The bar's thickness grows by ~10px on hover (this resizes the reserved
  screen space, so tiled windows shift slightly while hovering).
- Every widget/icon in the bar scales up ~15% on hover.
- Extra spacing opens up between widgets (and around the clock) on hover so
  the larger icons don't overlap their neighbors.

All three effects animate together over ~140ms.

No external dependencies — it only uses APIs already provided by
`omarchy-shell`.

## Known limitations

If you've ever mashed your face up against the monitor
trying to tell Omarchy's tiny bar icons apart — is that bluetooth or audio,
who can say — congratulations, you're exactly who this plugin was built for.
Hover away.

(Set `hoverExpand` to `0` in `shell.json` if you'd rather the bar just sit
there — see [Configuring](#configuring).)


## Install

```bash
omarchy plugin add https://github.com/GSkrt/omarchy-expanding-top-bar.git --enable
```

This clones the plugin into
`~/.config/omarchy/plugins/io.github.gskrt.expanding-top-bar/` and switches
your bar to it.

## Remove

To switch back to the stock bar and delete this plugin:

```bash
omarchy plugin enable omarchy.bar
omarchy plugin remove io.github.gskrt.expanding-top-bar
```

(Switch back to `omarchy.bar` first — removing the currently active bar
plugin out from under yourself isn't necessary, but doing it in this order
avoids a moment with no bar selected.)

## Configuring

Open `~/.config/omarchy/shell.json` and add (or edit) `hoverExpand` and
`hoverAnimationMs` under the top-level `bar` key. Both hot-reload on save —
no restart needed:

```json
{
  "bar": {
    "hoverExpand": 10,
    "hoverAnimationMs": 140
  }
}
```

If you installed with `omarchy plugin add --enable`, `shell.json` won't have
these keys yet — Omarchy never writes plugin defaults into your config file
(it's yours, no deep-merge), so the plugin just falls back to the defaults
shown above until you add them yourself.

**`hoverExpand`** (pixels, default `10`) is the one knob that controls the
whole grow effect. Everything else derives from it, so nothing drifts out of
sync:

- The bar grows thicker by exactly `hoverExpand` px on hover.
- Icons scale up by `1 + hoverExpand * 0.015` (10px → 1.15x, matching the default look).
- The gap opened up between widgets is `hoverExpand * 1.4` px (10px → 14px).

Set it to `0` to disable the grow effect entirely (the bar becomes static).
Larger values make a more dramatic hover effect; the growth is unbounded, so
very large values will look extreme.

**`hoverAnimationMs`** (milliseconds, default `140`) is how long the
grow/shrink transition takes when the pointer enters or leaves the bar.
Lower is snappier, higher is more of a slow reveal. Set it to `0` for an
instant, unanimated jump.

### Further tuning

The 1.5%-scale-per-px and 1.4px-gap-per-px ratios (the fixed relationship
between `hoverExpand` and the icon/spacing effects, rather than the overall
amount), and the easing curve, are constants in `Bar.qml` — search for
`hoverIconScale`, `hoverModuleGap`, and the `Behavior on` blocks next to
`hoverExpand` and `hoverAnimationDuration`.

---

Everything else below is unchanged from the original `omarchy.bar` this was
cloned from, and documents the bar engine itself.

---

This is the Quickshell implementation of the Omarchy status bar. It is
shipped as a first-party plugin of `omarchy-shell`, the long-running shell
host. The bar is mounted at startup and lives inside the shell for its
whole session.

- `manifest.json` declares the plugin (`kind: bar`) and points at `Bar.qml` as the entry point.
- `widgets/` holds simple first-party bar widgets with sibling manifests.
- The bar receives its config from the host shell as a `barConfig` property; the host loads it from `~/.config/omarchy/shell.json` (or `config/omarchy/shell.json` when the user has no file).
- `omarchy bar position` updates only the user shell.json file.

## Customizing

The bar config lives under the `bar:` key of `~/.config/omarchy/shell.json`. Once you customize anything via the bar gestures, `omarchy bar ...`, or by editing shell.json directly, your file is canonical — there is no deep-merge.

The bar is configured directly on the bar itself: drag empty bar space (or click-and-hold) to move the bar to another screen edge, double-left-click empty center-bar space to toggle transparency, and drag widgets to reorder them. The `omarchy bar position`, `omarchy bar transparent`, `omarchy bar move`, and `omarchy bar set` commands do the same from scripts. Enable or disable widgets with `omarchy plugin enable` and `omarchy plugin disable` (widget ids come from `omarchy plugin list`).

Example `shell.json` (bar subtree only shown):

```json
{
  "version": 1,
  "bar": {
    "position": "top",
    "transparent": false,
    "centerAnchor": "omarchy.clock",
    "layout": {
      "left": [
        { "id": "omarchy.menu" },
        { "id": "omarchy.spacer", "size": 12 },
        { "id": "omarchy.workspaces" }
      ],
      "center": [
        { "id": "omarchy.media" },
        { "id": "omarchy.clock", "format": "HH:mm" }
      ],
      "right": [
        { "id": "omarchy.audio" },
        { "id": "omarchy.power" }
      ]
    }
  }
}
```

`centerAnchor` pins one center module to the exact horizontal/vertical center and flanks others around it. Set to an empty string to disable anchoring (the center list is centered as a group).

## Module catalogue

### First-party interactive widgets

| Name | What it does | Interactions |
|---|---|---|
| `omarchy.menu` | Omarchy menu launcher | left = menu · right = terminal |
| `omarchy.workspaces` | Hyprland workspace switcher | left = focus workspace |
| `omarchy.clock` | Date/time label + popup with a month grid, ISO week numbers, and month stepping | left = popup · right = cycle label format · middle = timezone selector |
| `omarchy.media` | MPRIS now-playing — scrolling track + artist, cover-art popup | left = play/pause · middle = next · scroll = prev/next · right = popup |
| `omarchy.indicators` | Manual state indicators | left = indicator action |
| `omarchy.system-update` | Available update indicator | left = update |
| `omarchy.tray` | System tray | hover = reveal drawer · right on chevron = manage |
| `omarchy.weather` | Weather icon + popup with forecast | left = popup · right = full notification |
| `omarchy.microphone` | Mic icon + scroll volume | left = mute toggle · middle = audio panel · scroll = source volume |
| `omarchy.audio` | Volume icon + popup with master slider, output-device picker, per-app mixer | left = popup · right = mute · middle = popup · scroll = volume |
| `omarchy.network` | Wi-Fi/Ethernet icon + popup with Wi-Fi scan, signal, connect, DNS provider selection | left = popup |
| `omarchy.tailscale` | Tailscale status, connection switcher, machine browser, and copy actions | left = popup · right = toggle · middle = refresh |
| `omarchy.agents` | AI coding agent limits with pace, today, last week, and all-time model breakdown | left = panel · right = launch agent · middle = next subscription |
| `omarchy.power` | Battery/AC icon + popup with battery stats, power profiles, and system info | left = popup · right = toggle percentage |
| `omarchy.bluetooth` | Bluetooth icon + popup with device list, connect/disconnect, battery | left = popup · right = toggle radio |
| `omarchy.monitor` | Brightness and laptop display controls | left = popup |

The `omarchy.indicators` widget loads individual bar indicators from `indicators/`. Omit `items` (or set it to an empty array) to show all indicators in the default order, or set `items` to a subset such as `["Dnd", "Reminder", "NightLight"]`. Set `alwaysShow` to `true` to keep inactive indicators visible instead of revealing them only on hover. Multiple `omarchy.indicators` instances are allowed, so different sections can show different subsets.

## Orientation

All widgets work in `top`, `bottom`, `left`, and `right` positions. Popups anchor on the side opposite the bar edge, sliding into the workspace. Vertical bars use 28px width; widgets that show text fall back to compact icon-only forms (e.g. `media` hides its scrolling label).

## Custom user modules

The schema accepts arbitrary module ids that you provide. Set `type` to `command` for shell-driven output or `qml` for a custom QML widget. Both still go under `bar.layout.<section>` in `shell.json`.

Command module:

```json
{
  "version": 1,
  "bar": {
    "layout": {
      "right": [
        { "id": "omarchy.tray" },
        { "id": "vpn", "type": "command", "exec": "~/.config/omarchy/bar/scripts/vpn-status", "interval": 5, "tooltip": "VPN", "onClick": "nm-connection-editor" },
        { "id": "omarchy.audio" }
      ]
    }
  }
}
```

The command may print plain text or Waybar-style JSON, for example:

```json
{"text":"󰌆","tooltip":"Work VPN","class":"active"}
```

QML module:

```json
{
  "version": 1,
  "bar": {
    "layout": {
      "right": [
        { "id": "gpu", "type": "qml" },
        { "id": "omarchy.audio" }
      ]
    }
  }
}
```

Then create `~/.config/omarchy/bar/modules/gpu.qml`. If you want to store it elsewhere, add a `source` path.

Custom QML modules should be an `Item` with `implicitWidth` and `implicitHeight`. They may optionally define these properties, which the bar fills after loading:

```qml
import QtQuick

Item {
  property var bar
  property string moduleName
  property var settings

  implicitWidth: 28
  implicitHeight: bar ? bar.barSize : 26

  Text {
    anchors.centerIn: parent
    text: "GPU"
    color: bar ? bar.foreground : "white"
    font.family: bar ? bar.fontFamily : "monospace"
    font.pixelSize: 12
  }

  MouseArea {
    anchors.fill: parent
    onClicked: if (bar) bar.run("omarchy-launch-or-focus-tui btop")
  }
}
```

## Bar properties available to widgets

Widgets receive `bar` (the shell root), `moduleName` (string), and `settings` (object) injected at load time. The bar exposes:

- `bar.foreground`, `bar.background`, `bar.urgent` — theme colors (live-updated)
- `bar.fontFamily` — current monospace family
- `bar.position` — `"top" | "bottom" | "left" | "right"`
- `bar.vertical` — boolean shortcut
- `bar.barSize` — 26 horizontal / 28 vertical at rest (grows on hover in this fork)
- `bar.run(command)` — fire-and-forget bash exec
- `bar.shellQuote(value)` — safe shell-quote a string
- `bar.showTooltip(target, text)` / `bar.hideTooltip(target)` — shared tooltip popup
- `bar.requestPopout(owner)` / `bar.releasePopout(owner)` — one-popup-at-a-time coordinator

First-party bar widgets are manifest-backed just like third-party widgets.
Simple widgets carry sibling manifests such as `widgets/Workspaces.manifest.json`;
richer popup plugins live in feature directories such as `../panels/audio/`,
`../panels/network/`, and `../agents/`; and feature plugins such as
`omarchy.menu` and `omarchy.media` declare their bar-widget entry points in their own
`manifest.json`. Bar layout ids are namespaced, e.g. `omarchy.audio`,
`omarchy.network`, and `omarchy.clock`. Older UpperCamelCase ids such as
`AudioPanel` and `Clock` are migrated forward; new configs should use the
namespaced ids.

Third-party widgets ship as separate plugins under
`~/.config/omarchy/plugins/<plugin-id>/` with their own `manifest.json`
declaring `kinds: ["bar-widget"]` and a `barWidget` entry point. Rescan,
enable, and place third-party plugins with `omarchy-shell shell
rescanPlugins`, `omarchy plugin enable`, and `omarchy bar move`.

