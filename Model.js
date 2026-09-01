// Pure helpers for parsing/sorting `systemctl --user list-units` JSON output.
// Kept side-effect free so it can be exercised without Quickshell/QML.

function parseUnits(raw) {
  var text = String(raw || "").trim()
  if (text === "") return { ok: true, units: [] }

  try {
    var parsed = JSON.parse(text)
  } catch (e) {
    return { ok: false, error: "Could not parse systemctl output: " + e.message }
  }

  if (!Array.isArray(parsed)) return { ok: false, error: "Unexpected systemctl output shape" }

  var units = parsed.map(function(entry) {
    return {
      name: String(entry.unit || ""),
      shortName: shortName(String(entry.unit || "")),
      load: String(entry.load || ""),
      activeState: String(entry.active || ""),
      subState: String(entry.sub || ""),
      description: String(entry.description || "")
    }
  }).filter(function(u) { return u.name !== "" })

  return { ok: true, units: sortUnits(units) }
}

function shortName(unitName) {
  return unitName.endsWith(".service") ? unitName.slice(0, -".service".length) : unitName
}

function isFailed(unit) {
  return !!unit && unit.activeState === "failed"
}

function isRunning(unit) {
  return !!unit && unit.activeState === "active"
}

function stateRank(unit) {
  if (isFailed(unit)) return 0
  if (isRunning(unit)) return 1
  return 2
}

function sortUnits(units) {
  return units.slice().sort(function(a, b) {
    var rankDiff = stateRank(a) - stateRank(b)
    if (rankDiff !== 0) return rankDiff
    return a.shortName.localeCompare(b.shortName)
  })
}

function countFailed(units) {
  return (units || []).filter(isFailed).length
}

function stateLabel(unit) {
  if (!unit) return ""
  if (!unit.subState || unit.subState === unit.activeState) return unit.activeState
  return unit.activeState + " (" + unit.subState + ")"
}

// Semantic tab taxonomy. systemd carries no category metadata for units,
// so this is a hand-curated keyword lookup against each unit's short name,
// grounded in a real Omarchy desktop's unit census (see README's
// "Category taxonomy" section for the full rationale) -- not a generic
// media/network/sync/dev/utilities guess, which doesn't fit what actually
// runs here (no sync agents, almost no network services, no dev tools).
// Order matters: first keyword match wins, most-specific categories first.
var CATEGORY_DEFINITIONS = [
  { key: "audio", label: "Audio", keywords: ["pipewire", "pulseaudio", "wireplumber"] },
  { key: "security", label: "Security", keywords: ["keyring", "gpg-agent", "dirmngr", "keyboxd", "p11-kit", "bt-agent"] },
  { key: "portals", label: "Portals", keywords: ["xdg-", "portal", "at-spi", "dbus-broker", "dbus-:", "dconf"] },
  { key: "session", label: "Session", keywords: ["wayland-session", "wayland-wm"] },
  { key: "filesystem", label: "Filesystem", keywords: ["gvfs"] },
  { key: "omarchy", label: "Omarchy", keywords: ["omarchy-"] },
  { key: "system", label: "System", keywords: ["systemd-"] }
]
var OTHER_CATEGORY = { key: "other", label: "Other" }

// Fixed tab order: All, every real category, Other last. Fixed (not
// derived from what's currently running) so the tab row doesn't jump
// around as services start/stop.
var CATEGORY_KEYS = ["all"].concat(CATEGORY_DEFINITIONS.map(function(d) { return d.key })).concat([OTHER_CATEGORY.key])

function categorize(unit) {
  if (!unit) return OTHER_CATEGORY.key
  var name = String(unit.shortName || "").toLowerCase()
  for (var i = 0; i < CATEGORY_DEFINITIONS.length; i++) {
    var def = CATEGORY_DEFINITIONS[i]
    for (var j = 0; j < def.keywords.length; j++) {
      if (name.indexOf(def.keywords[j]) !== -1) return def.key
    }
  }
  return OTHER_CATEGORY.key
}

function categoryLabel(key) {
  if (key === "all") return "All"
  var def = CATEGORY_DEFINITIONS.filter(function(d) { return d.key === key })[0]
  return def ? def.label : OTHER_CATEGORY.label
}

// Groups an already-sorted (failed-first) unit list into the fixed set of
// tabs, preserving each unit's relative order within its tab.
function groupUnitsByCategory(units) {
  var byKey = {}
  CATEGORY_KEYS.forEach(function(key) { byKey[key] = [] })

  ;(units || []).forEach(function(unit) {
    byKey.all.push(unit)
    byKey[categorize(unit)].push(unit)
  })

  return CATEGORY_KEYS.map(function(key) {
    return { key: key, label: categoryLabel(key), units: byKey[key], count: byKey[key].length }
  })
}

// Which action the row's toggle button represents right now. Restart is a
// separate, always-available button (not modeled here) since it's valid
// from any state.
function toggleAction(unit) {
  if (isRunning(unit)) return { verb: "stop", label: "Stop" }
  return { verb: "start", label: "Start" }
}

function actionErrorMessage(verb, unitName, detail) {
  var base = String(verb) + " " + String(unitName) + " failed"
  var trimmed = String(detail || "").trim()
  return trimmed ? base + ": " + trimmed : base
}

// Hero header's live status line (task-fn8). Separate from badgeState:
// the bar icon's tooltip is terse ("2 failed user services"), the hero
// line has room to also say how many are healthy when nothing's wrong.
function heroStatus(totalCount, failedCount) {
  if (failedCount > 0) {
    var noun = failedCount === 1 ? "service" : "services"
    return { text: failedCount + " " + noun + " failed", urgent: true }
  }
  return { text: totalCount + " services, all healthy", urgent: false }
}

function badgeState(failedCount) {
  if (failedCount <= 0) {
    return { icon: "⚙", badge: "", tooltip: "User services" }
  }
  var noun = failedCount === 1 ? "service" : "services"
  return {
    icon: "⚠",
    badge: String(failedCount),
    tooltip: failedCount + " failed user " + noun
  }
}

if (typeof module !== "undefined") {
  module.exports = {
    parseUnits: parseUnits,
    shortName: shortName,
    isFailed: isFailed,
    isRunning: isRunning,
    sortUnits: sortUnits,
    countFailed: countFailed,
    badgeState: badgeState,
    stateLabel: stateLabel,
    categorize: categorize,
    categoryLabel: categoryLabel,
    groupUnitsByCategory: groupUnitsByCategory,
    CATEGORY_KEYS: CATEGORY_KEYS,
    toggleAction: toggleAction,
    actionErrorMessage: actionErrorMessage,
    heroStatus: heroStatus
  }
}
