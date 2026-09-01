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
    stateLabel: stateLabel
  }
}
