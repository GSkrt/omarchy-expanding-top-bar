.pragma library

// Pure helpers for icon groups. Every function takes the groups array and
// returns a new one, so callers can assign the result without mutating shared
// state. A group is { id, label, icon, members: [moduleId, ...] } and a module
// can be in at most one group.

var DEFAULT_ICON = "󰉋"

function normalize(raw) {
  if (!Array.isArray(raw)) return []
  var seen = {}
  var groups = []
  for (var i = 0; i < raw.length; i++) {
    var g = raw[i]
    if (!g || typeof g !== "object" || typeof g.id !== "string" || g.id === "") continue
    var members = []
    var list = Array.isArray(g.members) ? g.members : []
    for (var j = 0; j < list.length; j++) {
      var id = String(list[j])
      if (id === "" || seen[id]) continue
      seen[id] = true
      members.push(id)
    }
    groups.push({
      id: g.id,
      label: typeof g.label === "string" && g.label !== "" ? g.label : g.id,
      icon: typeof g.icon === "string" && g.icon !== "" ? g.icon : DEFAULT_ICON,
      svg: typeof g.svg === "string" ? g.svg : "",
      color: typeof g.color === "string" ? g.color : "",
      // members that do not pop out when their status changes; the rest do
      quiet: (Array.isArray(g.quiet) ? g.quiet : []).map(String).filter(function(m) { return members.indexOf(m) !== -1 }),
      members: members
    })
  }
  return groups
}

function groupOf(groups, moduleId) {
  for (var i = 0; i < groups.length; i++) {
    if (groups[i].members.indexOf(moduleId) !== -1) return groups[i].id
  }
  return ""
}

function uniqueId(groups, label) {
  var base = String(label || "group").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "") || "group"
  var id = base
  var n = 2
  while (groups.some(function(g) { return g.id === id })) id = base + "-" + n++
  return id
}

function createGroup(groups, label) {
  var name = label || "New group"
  var next = normalize(groups)
  next.push({ id: uniqueId(next, name), label: name, icon: DEFAULT_ICON, svg: "", color: "", quiet: [], members: [] })
  return next
}

function renameGroup(groups, groupId, label) {
  return normalize(groups).map(function(g) {
    if (g.id === groupId && label !== "") g.label = label
    return g
  })
}

function setGroupIcon(groups, groupId, icon) {
  return normalize(groups).map(function(g) {
    if (g.id === groupId && icon !== "") g.icon = icon
    return g
  })
}

// An SVG path (absolute, or starting with ~/) replaces the glyph on the bar;
// an empty path goes back to the glyph.
function setGroupSvg(groups, groupId, path) {
  return normalize(groups).map(function(g) {
    if (g.id === groupId) g.svg = String(path || "").trim()
    return g
  })
}

// A group with no color of its own takes one from the palette, by position.
var PALETTE = ["#4f9cf9", "#e5733f", "#4fc08d", "#c76be0", "#e0b341", "#e05a7a", "#3fc1c9", "#8d9bff"]

function resolveColor(group, index) {
  return group.color !== "" ? group.color : PALETTE[index % PALETTE.length]
}

function setGroupColor(groups, groupId, color) {
  return normalize(groups).map(function(g) {
    if (g.id === groupId) g.color = String(color || "")
    return g
  })
}

function deleteGroup(groups, groupId) {
  return normalize(groups).filter(function(g) { return g.id !== groupId })
}

function removeFromGroup(groups, moduleId) {
  return normalize(groups).map(function(g) {
    g.members = g.members.filter(function(m) { return m !== moduleId })
    g.quiet = g.quiet.filter(function(m) { return m !== moduleId })
    return g
  })
}

// Mark a member of a group as quiet (no status pop-out) or watched again.
function setQuiet(groups, groupId, moduleId, quiet) {
  return normalize(groups).map(function(g) {
    if (g.id !== groupId || g.members.indexOf(moduleId) === -1) return g
    g.quiet = g.quiet.filter(function(m) { return m !== moduleId })
    if (quiet) g.quiet.push(moduleId)
    return g
  })
}

// Add (or move) a module into a group; index defaults to the end.
function addToGroup(groups, groupId, moduleId, index) {
  var next = removeFromGroup(groups, moduleId)
  for (var i = 0; i < next.length; i++) {
    if (next[i].id !== groupId) continue
    var at = index === undefined || index < 0 || index > next[i].members.length ? next[i].members.length : index
    next[i].members.splice(at, 0, moduleId)
  }
  return next
}

// Groupable modules from a bar layout: every id in every section, once.
function layoutModuleIds(layout, exclude) {
  var ids = []
  if (!layout || typeof layout !== "object") return ids
  for (var section in layout) {
    var entries = layout[section]
    if (!Array.isArray(entries)) continue
    for (var i = 0; i < entries.length; i++) {
      var e = entries[i]
      var id = typeof e === "string" ? e : (e && typeof e.id === "string" ? e.id : "")
      if (id !== "" && ids.indexOf(id) === -1 && exclude.indexOf(id) === -1) ids.push(id)
    }
  }
  return ids
}

function labelFor(moduleId) {
  var tail = String(moduleId).split(".").pop()
  return tail.charAt(0).toUpperCase() + tail.slice(1).replace(/-/g, " ")
}

// Nerd Font glyph per known module. Widgets pick their glyph in their own
// code (often from live state), so there is no single source to read it from;
// this is the representative one. Unknown modules get GENERIC_ICON.
var GENERIC_ICON = "󰕮"

var MODULE_ICONS = {
  "omarchy.menu": "󰍜",
  "omarchy.workspaces": "󰕰",
  "omarchy.clock": "󰥔",
  "omarchy.weather": "󰖐",
  "omarchy.elsewhen": "󰇧",
  "omarchy.media": "󰎆",
  "omarchy.indicators": "󰂛",
  "omarchy.system-update": "󰚰",
  "omarchy.keyboard-layout": "󰌌",
  "omarchy.tray": "󰀻",
  "omarchy.agents": "󱚣",
  "omarchy.bluetooth": "󰂯",
  "omarchy.network": "󰖩",
  "omarchy.audio": "󰕾",
  "omarchy.microphone": "󰍬",
  "omarchy.power": "󰁹",
  "omarchy.monitor": "󰍹",
  "omarchy.tailscale": "󰖂",
  "omarchy.active-window": "󰖯"
}

function iconFor(moduleId) {
  return MODULE_ICONS[moduleId] || GENERIC_ICON
}

// System icons are the ones Omarchy ships; everything else is a user plugin.
function isSystem(moduleId) {
  return String(moduleId).indexOf("omarchy.") === 0
}

// Icons that ship in icons/. A group's `svg` may be one of these names, or a
// path (absolute or ~/...) to an SVG of its own.
var BUILTIN_ICONS = ["connectivity", "audio", "system", "power", "display", "notifications",
  "tools", "cloud", "monitoring", "devices", "security", "fitness"]
