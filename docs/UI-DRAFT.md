# UI draft

A first sketch, meant to be improved. Everything here is a starting point for
the UI contributor, not a spec. If you have a better idea, change this file.

Principles:

- **Quiet at rest.** The idle bar should look like today's bar, just with fewer
  icons.
- **Follows the theme.** One foreground color, opacity for hierarchy. No accent
  colors except `bar.urgent` for things that need attention.
- **Same motion language as the hover effect:** about 140 ms, ease-out cubic,
  driven by progress values.

## 1. The bar, idle and hovered

```
idle     [ 1 2 3 ]        [ 12:30 ]       [ ◉ ] [ 󰂯 ] [ 󰕾 ] [ ⚙ ]
                                           ^ group  ^ loose icons ^ settings

hovered  [ 1 2 3 ]        [ 12:30 ]      [ 󰛳 󰂯 󰖩 ] [ 󰕾 ] [ ⚙ ]
                                           ^ group expanded in place
```

Collapsed groups are as wide as one icon. Expanding pushes neighbours aside
using the same reserved-room mechanism the bar already uses.

## 2. Group icon

Collapsed look: pick one, try each and judge by eye.

```
A) single glyph        B) stack of members      C) glyph + count
   [ 󰛳 ]                  [ 󰛳󰂯 ]                    [ 󰛳 ³]
```

Suggested default: **A**, with a small dot in the corner when any member is
non-idle. It is the quietest, and the dot gives a cue for B/C-style information.

Expanded look: members slide out from the group icon and the group icon fades
to a thin separator, so the members read as normal bar icons.

```
collapsed   [ 󰛳 ]
expanding   [ 󰛳 󰂯 ]          members slide out, staggered ~20 ms each
expanded    [ │ 󰛳 󰂯 󰖩 │ ]    group glyph becomes a faint bracket/pill
```

A faint rounded pill behind the open group (foreground at about 8% opacity, same
idea as `hoverGlow`) shows where the group starts and ends.

## 3. Status pop-out

When a member changes status, it leaves the group and sits next to it.

```
before   [ 󰛳 ]  [ 󰕾 ]
event    [ 󰛳 ] [ 󰂯! ] [ 󰕾 ]      Bluetooth connected: icon pops out
~4 s     [ 󰛳 ]  [ 󰕾 ]            tucks back into the group
```

Ideas, from subtle to loud:

- The icon slides out and scales up slightly (overshoot about 1.1, then settles).
- A short ring pulse behind it, once.
- Optional tiny text next to it ("connected") while it is out. Keep to one
  short word.
- Use `bar.urgent` only for genuinely bad states (disconnected, muted mic when
  live) and not for "something changed".

The pop-out must never feel like a notification popup. It is a bar-level glance.

## 4. Settings icon and panel

The settings icon is the last item on the bar: a plain gear glyph, with the
same hover behavior as any icon.

Clicking opens a popup panel, using the same popup mechanism as the audio and
network panels (see `bar.requestPopout`).

```
┌─ Bar settings ───────────────────────┐
│                                      │
│  Groups                              │
│  ┌────────────────────────────────┐  │
│  │ 󰛳 Connectivity            [edit] │  │
│  │    network · bluetooth · ...   │  │
│  ├────────────────────────────────┤  │
│  │ + New group                    │  │
│  └────────────────────────────────┘  │
│                                      │
│  Pop-out stays for     [ 4.0 s ─●─ ] │
│  Group closes after    [ 0.25 s ●─ ] │
│                                      │
│  Hover effect                        │
│  Expand                [ 10 px ─●─ ] │
│  Animation             [ 140 ms ─● ] │
│                                      │
└──────────────────────────────────────┘
```

Notes:

- Sliders for numbers (with the value shown), toggles for booleans. No free-text
  numeric fields unless needed.
- Changes apply live (the config hot-reloads), so no Apply button. Show the
  effect as the slider moves.
- Group editing: a member list with checkboxes or drag-to-add; group icon chosen
  from a small glyph picker.
- Panel width about 320 px; it is a popup, not a window. The drag and drop group
  designer (section 5) needs more room and may need its own wider view.

## 5. Group designer (drag and drop)

A tab or section inside the settings panel. Left: every module that can be
grouped, as chips. Right: the groups.

```
┌─ Groups ─────────────────────────────────────────┐
│                                                  │
│  Available            Groups                     │
│  ┌──────────────┐     ┌────────────────────────┐ │
│  │ [󰕾 Audio   ] │     │ 󰛳 Connectivity     [✎][×]│ │
│  │ [󰍬 Mic     ] │ ──▶ │  [󰖩 Network][󰂯 Bluetooth]│ │
│  │ [󰂛 DND     ] │     │  ┈┈┈ drop here ┈┈┈      │ │
│  └──────────────┘     ├────────────────────────┤ │
│                       │ 󰒓 System            [✎][×]│ │
│                       │  [󰁹 Power][󰚰 Updates]   │ │
│                       ├────────────────────────┤ │
│                       │  + drop here for a new │ │
│                       │    group               │ │
│                       └────────────────────────┘ │
└──────────────────────────────────────────────────┘
```

Interaction ideas:

- Picking a chip up lifts it (slight scale and shadow) and leaves a faint
  placeholder behind.
- Valid drop targets highlight (foreground at ~10% opacity); the insertion point
  inside a group shows as a thin line.
- Dropping outside any target returns the chip with a short ease-out animation.
- Chips already in a group show in the group, not in "Available".
- Changes apply to the live bar as you drop, so the result is visible straight
  away on the bar behind the panel.
- Keyboard fallback: select a chip, then arrow keys and Enter to move it.

Reference for dragging in this code base: widgets on the bar can already be
dragged to reorder (search `barDragSource` in `Bar.qml`). Look at how it draws a
ghost and finds the drop target before building your own.

## 6. Open design questions

- Does the designer live in the settings popup, or as its own larger window?
  A popup of about 320 px is tight for two columns.

- Does the group glyph disappear when expanded, or stay as a handle?
- Should a popped-out icon keep its group pill, or float free?
- One pop-out slot at a time, or several at once? (Proposal assumes several.)
- Vertical bars: expand downward, or sideways into the workspace like popups?
- Should the settings gear only appear on hover to keep the idle bar clean?

## 7. Tools

Just sketch in this file, in Figma, or straight in QML, whichever is fastest.
Screenshots and gifs in the PR are enough for review. If you prefer drawing it,
put the image in `docs/img/` and link it here.
