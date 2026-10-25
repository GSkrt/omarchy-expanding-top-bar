# TODO

Start here: [contributing](CONTRIBUTING.md) · Details: [testing](docs/TESTING.md) · [proposal](docs/PROPOSAL.md) · [UI guide](docs/UI-GUIDE.md) · [UI draft](docs/UI-DRAFT.md)

`[x]` means built. Not everything built has been run by a person; what hasn't is
listed under "Needs testing" at the bottom.

## Settings icon

- [x] Permanent settings icon at the right end of the bar (always there, independent of `bar.layout`)
- [x] Clicking it opens a dropdown with the basic bar settings (hover expand, animation, icon boost, gap, padding, highlight, shift windows, hold while popup)
- [x] Group settings in the dropdown (groups on/off, open on hover, auto-close, animation speed, color strength, status pop-out, timeouts)
- [x] "Reset hover settings to defaults" button
- [x] Dropdown button opens a separate floating window for grouping icons
- [ ] Bar position and transparency in the dropdown

## Group designer window (floating)

- [x] Drag icons from "Available" into groups, between groups, or back out
- [x] Drop on empty space to create a new group; rename and delete groups
- [x] Groups are saved to `bar.groups` in `shell.json`
- [x] Real icons on the chips (captured from the bar), system icons flagged with a dot
- [x] Per group: glyph or SVG (bundled icon picker, or any path), background color (palette or hex)
- [x] Per group: "Pops out on status change" and "Quiet" zones
- [x] Window is larger and resizable, and the Available list scrolls
- [ ] Reorder icons inside a group
- [ ] Make the window float reliably under Hyprland (verify, add a window rule if needed)

## Groups on the bar

- [x] A group is one fixed-size icon with its own colored background; nothing on the bar moves when it opens
- [x] Members open in a drawer over the neighbouring icons (opens away from the bar center)
- [x] Click the group icon to open and close (default), or open on hover (option)
- [x] Hover another group's icon while one is open to switch to it
- [x] Auto-close after the pointer has left the bar (configurable, 0 = never)
- [x] Drawer speed is separate from the bar's hover animation
- [x] Everything is opt-in: with `groupingEnabled` off the bar is unchanged apart from the gear
- [ ] Group icons by a common denominator automatically (category/type). Today groups are made by hand only
- [ ] Decide whether an open drawer may cover other group icons (alternative: open away from them)

## Status-change reveal

- [x] When a grouped icon's status changes (its glyph, image or active flag), it pops out of its closed group
- [x] After a predefined time it goes back into the group and hides (default 4 s)
- [x] Timeout configurable in settings, and the whole feature can be switched off
- [x] Animated pop-out and return
- [x] Per-icon opt-out via the Quiet zone
- [ ] Detect status changes in widgets that only change text or color (nothing does today)

## Icons and polish (for the UI contributor)

- [ ] Better group icons than the 12 test drafts, plus new ones (see `icons/README.md`)
- [ ] Theme-aware SVG tint (icons are a fixed light gray today)
- [ ] Review the designer window layout (icon row, color row, Status/Quiet zones)

## Needs testing

Built, but never run by a person. See `docs/TESTING.md`, where these are marked **(unverified)**:

- [ ] A real status change in a grouped widget (Bluetooth, mic mute, DND). Only a simulated one has been seen
- [ ] The real click and hover paths for opening, switching and auto-closing groups
- [ ] The designer window: drag and drop, icon row, colors, zones
- [ ] Left/right bar position, two monitors, center-section groups
- [ ] Dragging the gear, or dropping an icon onto it
- [ ] Run the full pass in `docs/TESTING.md` and report what fails
