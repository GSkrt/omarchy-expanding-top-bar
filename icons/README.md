# Group icons

SVG icons for bar groups. Every `.svg` in this folder can be picked in the group
designer (gear icon, then "Group icons..."), and is stored by name in
`shell.json` under `bar.groups[].svg`.

The 12 icons here are **test drafts** (see `docs/icons/preview.html` to look at
them side by side). Replacing and improving them is the job.

## Where to put an icon

1. Save it as `icons/<name>.svg`. The name is lowercase, with dashes if needed
   (`smart-home.svg`), and has no dots or slashes: that is how the bar tells a
   bundled icon from a file path.
2. Add the name to `BUILTIN_ICONS` in `GroupModel.js` (repo root). The designer's
   icon row is built from that list, in that order.
3. Restart the shell (`omarchy-restart-shell`), open the designer and pick it.
   Check it small, on the bar, not just in a browser.

Replacing an existing icon is just overwriting its file; no code change.

## Drawing rules

- `viewBox="0 0 24 24"`, about 2 px padding inside the edge.
- Stroke only: `stroke-width="1.75"`, round caps and joins, `fill="none"`
  (a small dot may be filled).
- Drawn at about 16 to 20 px on the bar, so detail that disappears at 18 px
  should not be there.
- One idea per icon, readable by silhouette.
- Same visual weight across the whole set.

## Wanted

- Better versions of the 12 drafts: connectivity, audio, system, power, display,
  notifications, tools, cloud, monitoring, devices, security, fitness.
- New ones for likely groups: media, communication, files, development,
  smart-home, health. Suggest others if the bar suggests them.
- A proposal for **theme color**. The icons are a fixed light gray (`#d8dee9`)
  because an `Image` cannot pick up the bar's foreground color, so they look wrong
  on a light theme. Tinting them in `widgets/GroupHandle.qml` (for example with
  `MultiEffect` colorization) is open.

## Test your icon quickly

Without opening the designer, put the name in `~/.config/omarchy/shell.json`:

```json
"groups": [ { "id": "sport", "label": "Sport", "svg": "your-icon", "members": [ ... ] } ]
```
