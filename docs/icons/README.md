# Group icons

First-draft SVG icons for bar groups, as a starting point for the UI
contributor. Open `preview.html` in a browser to see them large and at bar size.

| File | Group it suggests |
|---|---|
| `connectivity.svg` | wi-fi arcs |
| `audio.svg` | speaker with waves |
| `system.svg` | chip |
| `power.svg` | battery with bolt |
| `display.svg` | monitor |
| `notifications.svg` | bell |
| `tools.svg` | sliders |
| `cloud.svg` | cloud |
| `monitoring.svg` | activity pulse |
| `devices.svg` | bluetooth rune |
| `security.svg` | shield |
| `fitness.svg` | dumbbell |

## Using one

These are the original proposal. The working copies live in `icons/` at the
repo root, where the designer picks them up by name. See `icons/README.md` for
where to put new or improved icons.

## Drawing rules

- `viewBox="0 0 24 24"`, about 2 px of padding inside the edge.
- Stroke only: `stroke-width="1.75"`, round caps and joins, `fill="none"`
  (small dots may be filled).
- The bar draws icons at roughly 16 to 20 px, so check them small. Detail that
  disappears at 18 px should not be there.
- One metaphor per icon, readable in silhouette.
- Same visual weight across the set; put new ones in `preview.html` next to the
  old ones to compare.

## Known limit: theme color

These are drawn in a fixed light gray (`#d8dee9`) because an `Image` cannot
inherit the bar's foreground color, so on a light theme they will look wrong.
Tinting an SVG with the theme foreground in `widgets/GroupHandle.qml` is an open
item for the UI side.

## Not decided yet

Which predefined groups to ship, if any. These cover what the current bar
contains, plus a few likely ones (`cloud`, `security`, `fitness`).
