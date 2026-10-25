# Testing procedure

A manual test pass for the settings icon, icon groups, the designer and the
status pop-out. It takes about 45 minutes. Run it before a PR that touches
`Bar.qml`, `widgets/` or `GroupModel.js`, and after changing icons or the UI.

Tick each box. For anything that fails, note what you did, what you expected and
what happened (see "Reporting" at the end).

Not everything here has been verified by the author. Items marked **(unverified)**
have never been run, so a failure there is useful news, not a surprise.

## 0. Setup

```bash
git checkout develop && git pull
cp ~/.config/omarchy/shell.json ~/shell.json.backup     # your way back
omarchy-restart-shell                                   # a reload is not enough for QML
```

Handy while testing:

```bash
# errors from this plugin (run after every restart)
quickshell log -p /usr/share/omarchy/shell -t 800 | grep -a -i "expanding-top-bar\|failed to load\|cycle\|multiple times"

# what is stored (the settings and groups live under "bar")
jq '.bar | del(.layout)' ~/.config/omarchy/shell.json

# screenshot the right end of the bar
grim -g "1300,0 620x44" /tmp/shot.png
```

The log always shows one `pluginBarApiFor` TypeError right after a restart. That is
known and harmless as long as it does not repeat while you use the bar. Anything
else mentioning `expanding-top-bar` is a finding.

**If the bar turns into the stock Omarchy bar** (no hover growth, no gear), your QML
has an error and the shell fell back. The log says why; see `docs/UI-GUIDE.md`
section 1 for the usual causes. Fix it and restart.

To restore your config at the end:

```bash
cp ~/shell.json.backup ~/.config/omarchy/shell.json && omarchy-restart-shell
```

Test with a layout that has at least six right-hand icons you can reasonably
change the state of (see section 6 for which ones).

## 1. Smoke test

- [ ] Shell restarts, bar appears, log shows no errors from `expanding-top-bar`
- [ ] A gear icon is the last icon at the right end of the bar
- [ ] With grouping not enabled, the bar looks and behaves like the previous
      release: hover grows the bar and icons, nothing else is different except the gear
- [ ] Hover animation still follows `hoverAnimationMs`, and windows below the bar
      still shift once (not per frame) if `hoverShiftWindows` is true

## 2. The gear icon

- [ ] The gear is present however the layout is edited (remove all `right`
      entries from `shell.json` and restart: it is still there)
- [ ] It scales and highlights on hover like any other icon, with a tooltip
      "Bar settings"
- [ ] Left click opens a dropdown below it; clicking elsewhere closes it
- [ ] Opening it closes any other open bar popup (audio, network...) and vice versa
- [ ] **(unverified)** Dragging the gear, or dragging another icon onto it, does not
      break the bar or move the gear

## 3. Settings dropdown

Open the dropdown, then for each control: change it, then check the result on
the bar and in `shell.json`.

| Control | Key | What to check |
|---|---|---|
| Hover expand | `hoverExpand` | Bar grows by that many px; 0 disables growth |
| Animation | `hoverAnimationMs` | Faster/slower hover animation; 0 is instant |
| Icon boost | `hoverIconBoost` | Hovered icon magnifies more than the rest |
| Gap factor | `hoverGapFactor` | Gap between icons while hovered |
| Icon padding | `hoverIconPadding` | Neighbours step aside from the hovered icon |
| Hover highlight | `hoverHighlight` | Soft pill behind the hovered icon |
| Shift windows | `hoverShiftWindows` | Windows move (or not) when the bar grows |
| Stay expanded | `hoverHoldWhilePopup` | Bar stays grown while a popup is open |

- [ ] Each slider writes to `shell.json` on **release**, not continuously
- [ ] The bar updates without a restart
- [ ] Values survive a shell restart
- [ ] "Reset hover settings to defaults" removes those keys from `shell.json` and
      the bar returns to the plugin defaults
- [ ] Rapid changes (drag three sliders quickly) all land; none is lost
- [ ] `shell.json` stays valid JSON the whole time (`jq . ~/.config/omarchy/shell.json`)
- [ ] The dropdown fits on screen at your font scale and stays inside the monitor
- [ ] The group controls (toggle, sliders, button) are **not** shown until
      "Icon groups" is switched on

## 4. Group designer

Switch on "Icon groups" in the dropdown. A "Group icons…" button appears. Click it.

### Window

- [ ] A window opens. Record whether it **floats or tiles** under Hyprland
      (known open question)
- [ ] It is 980x680 by default and resizes down to 640x420, no further
- [ ] Closing it with the window manager and reopening it works
- [ ] The "Available" list scrolls when there are more icons than fit

### Icons in the Available list

- [ ] Every bar icon you have (system and plugins) is listed once, except
      spacers and the gear
- [ ] System Omarchy icons carry a small accent-colored dot; plugin icons do not
- [ ] Icons that are visible on the bar show their **real** icon; ones that are
      hidden at that moment (inactive indicator, hidden plugin) fall back to a
      generic glyph
- [ ] Wide widgets (clock, indicators) show as a wide chip, capped in width

### Drag and drop

- [ ] Drag a chip from Available onto an existing group: it joins that group and
      disappears from Available
- [ ] Drag a chip from one group to another: it moves, it is not copied
- [ ] Drag a chip from a group back onto Available: it leaves the group
- [ ] Drag a chip onto "Drop an icon here for a new group": a new group is created
      containing it
- [ ] "+ Empty group" creates an empty group
- [ ] Dropping a chip on nothing returns it to where it was
- [ ] While dragging, the chip is drawn above everything (not hidden behind cards)
- [ ] A module can never be in two groups at once
- [ ] **(unverified)** Dragging with a very long Available list scrolled down

### Group card

- [ ] Rename: edit the title, press Enter or click away; the new name is kept.
      Clearing it and leaving restores the old name
- [ ] Delete removes the group and its icons return to Available
- [ ] Glyph: paste a Nerd Font character in the small field next to the title;
      the bar shows it (when no SVG is set)
- [ ] Icon row: the first button is the glyph, then the 12 bundled icons. Clicking
      one sets it (highlighted), clicking the glyph button clears it
- [ ] SVG field: type a bundled name (`audio`) or a path (`~/icons/mine.svg`);
      the bar shows it. An empty field goes back to the glyph. A bad path shows
      nothing, and does not break the bar
- [ ] Color: swatches set the group color, "auto" clears it, a valid `#rrggbb`
      in the hex field sets it, an invalid value is rejected and the old one returns
- [ ] The stripe on the card shows the group's color
- [ ] Zones: "Pops out on status change" and "Quiet". Dragging a chip between them
      moves it; dragging from Available into a zone adds it there
- [ ] Every change appears on the real bar immediately, without a restart
- [ ] `jq '.bar.groups' ~/.config/omarchy/shell.json` matches what the designer shows

## 5. Groups on the bar

Create two groups with at least two icons each, one of them in the right section.
Close the designer.

### Closed state

- [ ] Each group is one icon with a rounded, colored background (its own color)
- [ ] Members are gone from their old positions and **nothing else on the bar moved**
- [ ] Opening and closing a group never shifts any other icon
- [ ] Group background strength follows "Group color strength" (0 removes it)
- [ ] The tooltip shows the group name

### Click mode (default)

- [ ] Hovering a group icon does **not** open it
- [ ] Clicking opens the drawer beside the icon; clicking the icon again closes it
- [ ] The drawer opens away from the bar's center for right-hand groups, towards the
      center for the others, with the member nearest the icon first
- [ ] The drawer is drawn over its neighbours, with an opaque base, in the group color
- [ ] Opening a second group closes the first
- [ ] **Hover-to-switch:** while one drawer is open, hovering another group's icon
      that is not covered by the open drawer switches to it. Hovering a closed
      group when nothing is open does nothing
- [ ] Moving the pointer off the bar closes the drawer after "Close after pointer
      leaves" (default 3 s); coming back before then cancels it; 0 means never
- [ ] A popup opened from a member (for example Bluetooth) keeps the drawer open
      until the popup closes, then the countdown starts
- [ ] Clicking a member inside an open drawer does what it does on the bar
      (opens its popup, toggles, and so on)
- [ ] **Closed drawers take no clicks.** With a right-hand group closed, clicking
      the icon to its left opens that icon, not a hidden member. (This was a real bug.)
- [ ] Opening and closing animates at "Group animation" speed, independent of the
      bar's hover animation. 0 is instant
- [ ] While the bar is hovered (icons scaled up), the group background and drawer
      are one smooth shape: no darker bands where parts overlap. (This was a real bug.)

### Hover mode

Switch on "Open groups on hover".

- [ ] Hovering a group icon opens it; leaving closes it after "Group closes after"
- [ ] Moving between the icon, its pill and its members does not close it
- [ ] Sweeping from one group to the next works
- [ ] Switching the mode closes any open drawer

### Layout rules

- [ ] The tray, the center anchor module and the gear can never be put in a group
      (add them in `shell.json` by hand: they are ignored)
- [ ] A module listed in two groups is only shown in the first
- [ ] A member id that is not in the layout is ignored, with no error
- [ ] A group whose members are all missing shows no icon
- [ ] A group's icon sits where its first member (left, center, then right) was
- [ ] Removing a module from the layout or disabling its plugin while it is in a
      group does not break the bar
- [ ] **(unverified)** Left or right bar position (`omarchy bar position left`):
      icons, drawer direction and pills all make sense. Put it back with
      `omarchy bar position top`
- [ ] **(unverified)** Two monitors: each bar has its own groups and drawers
- [ ] **(unverified)** Center-section groups

### Switching the feature off

- [ ] Turning "Icon groups" off restores every icon to its normal place and keeps
      the `groups` data in `shell.json`
- [ ] Removing `groupingEnabled` and `groups` entirely gives back the plain bar plus the gear

## 6. Status pop-out

Needs members whose icon actually changes. Good candidates and how to trigger them:

| Member | How to change it |
|---|---|
| Microphone | `wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle` |
| Bluetooth | `bluetoothctl power off` / `power on`, or connect/disconnect a device |
| Network | disconnect/reconnect Wi-Fi |
| Power | unplug or plug in the charger |
| Do Not Disturb or other indicators | toggle it in its own widget |

Put two or three of them in a group, close the drawer, and wait at least 10 seconds
after the restart (changes in the first 8 seconds are ignored on purpose).

- [ ] Changing a member's state makes **only that icon** slide out of the closed group
      in a small pill, beside the group icon
- [ ] It stays for "Status change stays out for" (default 4 s), then slides back
- [ ] Two changes at once pop out two icons; each leaves on its own timer
- [ ] If the drawer is opened (clicked) while an icon is popped out, the normal
      drawer wins and shows every member
- [ ] A clock, temperature or any widget that only changes its text does **not**
      pop out
- [ ] Moving an icon into the **Quiet** zone stops it popping out; moving it back
      restores it
- [ ] Turning "Pop out grouped icons when their status changes" off stops all pop-outs
- [ ] A duration of 0 disables pop-outs
- [ ] Icons that are **not** in a group are not affected
- [ ] The pop-out does not stay stuck, flicker, or trigger on every hover (watch
      for a minute with the pointer parked on the bar)
- [ ] CPU stays flat: `top -p $(pgrep -f "quickshell -n")` while idle with many
      grouped icons (it polls once a second per grouped icon)

## 7. Regression checks

- [ ] Drag-to-reorder of normal (ungrouped) icons still works
- [ ] Tooltips, scroll and middle/right click on normal icons still work
- [ ] Workspaces, tray and clock behave as before, with and without groups
- [ ] Popups from ungrouped icons still open under the right icon
- [ ] Changing a normal icon's own setting (for example `omarchy bar set
      omarchy.clock format HH:mm`) updates without rebuilding the bar
- [ ] `omarchy plugin enable omarchy.bar` then re-enabling this plugin works, and
      groups come back

## 8. Config robustness

Edit `~/.config/omarchy/shell.json` by hand for each case, then check the log
and the bar. Restore from your backup between cases.

- [ ] `"groupingEnabled": true` with no `groups` key: bar normal, no errors
- [ ] `"groups": "nonsense"` or a group with no `id`: ignored, no crash
- [ ] A group with an unknown `svg` name: falls back to showing nothing for the
      icon, but the group still works (note what you see)
- [ ] A group with an invalid `color` string: note what you see
- [ ] Negative or huge numbers for the `group*` and `hover*` keys: clamped or
      ignored, never a broken bar
- [ ] Invalid JSON in the file: the shell keeps running (it logs and uses defaults)

## 9. Icons

For new or changed files in `icons/`:

- [ ] Opens in a browser (`docs/icons/preview.html` style) and renders as expected
- [ ] `viewBox="0 0 24 24"`, stroke only, round caps, legible at about 18 px
- [ ] Name is lowercase, no dots or slashes, and is listed in `BUILTIN_ICONS`
- [ ] Shows in the designer's icon row, in the intended order
- [ ] Looks right on the bar at rest **and** while the bar is hovered
- [ ] Looks right inside the colored group background, for several colors
- [ ] Compared on a **light** theme (the icons are a fixed light gray today)

## 10. Reporting

For each failure, a short issue or PR comment:

```
Where:        (section and checkbox, e.g. 5 / Click mode / Hover-to-switch)
Did:          (exact steps, config involved)
Expected:
Got:          (screenshot or gif if visual)
Log:          (relevant lines from the quickshell log)
Setup:        (monitor count and scale, bar position, theme, widgets in the group)
```

Attach `jq '.bar | del(.layout)' ~/.config/omarchy/shell.json` if the failure
depends on settings. Never attach the whole `shell.json` without checking it for
tokens or personal data first.

## Known limits (not failures)

- The icons are a fixed light gray and ignore the theme color.
- An open drawer is drawn over the icons beside it, including other group icons,
  until it closes.
- Hover over a group icon is only used in hover mode, or to switch while another
  drawer is open.
- The status pop-out looks only at icon glyphs, images and `active` flags, so a
  widget that signals status only by text or color will not trigger it.
- The designer window may tile instead of float under Hyprland.
