# TODO

Details: [testing](docs/TESTING.md) · [proposal](docs/PROPOSAL.md) · [UI guide](docs/UI-GUIDE.md) · [UI draft](docs/UI-DRAFT.md)

## Settings icon

- [x] Add a permanent settings icon at the right end of the bar (always there, independent of `bar.layout`)
- [x] Clicking it opens a dropdown with the basic bar settings (hover expand, animation, icon boost, gap, padding, highlight, shift windows, hold while popup)
- [x] Dropdown button opens a separate floating window for grouping icons
- [ ] Settings panel for the rest of the bar behavior (position, transparency, group timeouts)

## Group designer window (floating)

- [x] Drag icons from "Available" into groups, between groups, or back out
- [x] Drop on empty space to create a new group; rename and delete groups
- [x] Groups are saved to `bar.groups` in `shell.json`
- [ ] Reorder icons inside a group
- [x] Group icon: glyph or custom SVG path per group, stored in `bar.groups` in `shell.json`
- [ ] Make the window float reliably under Hyprland (verify, add a window rule if needed)
- [x] Render groups on the bar: group icon, members expand on hover (opt-in via `groupingEnabled`)
- [ ] Status-change pop-out from a collapsed group

## Icon grouping (collaboration with @AkshatPaji)

- [ ] Allow grouping icons by a common denominator (e.g. category/type)
- [ ] Create a drag / drop designer for grouping icons
- [ ] Grouped icons collapse; hovering over the group expands it
- [ ] Make the grouping criteria configurable via the settings panel

## Status-change reveal

- [ ] When an icon's status changes (shows a new status), it pops out of its group, even if the group is collapsed
- [ ] After a predefined time, it goes back into the group and hides
- [ ] Make the timeout configurable in settings
- [ ] Animate the pop-out and return



## Icons and polish (for the UI contributor)

- [ ] Better group icons than the 12 test drafts, plus new ones (see `icons/README.md`)
- [ ] Theme-aware SVG tint (icons are a fixed light gray today)
- [ ] Review the designer window layout (icon row, color row, Status/Quiet zones)
- [ ] Decide whether an open drawer may cover other group icons (alternative: open away from them)
- [ ] Run the full pass in `docs/TESTING.md` and report the **(unverified)** items
