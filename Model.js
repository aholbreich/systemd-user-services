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

// `journalctl` prints nothing (not even a trailing newline) for a unit with
// no log entries yet, which would otherwise render as a blank panel row --
// indistinguishable from "still loading".
function formatJournalOutput(raw) {
  var text = String(raw || "").trim()
  return text === "" ? "No log entries" : text
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

// `systemctl --user list-unit-files --output=json` gives the enablement state
// per unit file ("enabled", "disabled", "static", ...). list-units doesn't
// carry it, so the two lists are fetched separately and joined by name.
function parseUnitFiles(raw) {
  var text = String(raw || "").trim()
  if (text === "") return { ok: true, states: {} }

  try {
    var parsed = JSON.parse(text)
  } catch (e) {
    return { ok: false, error: "Could not parse systemctl unit files: " + e.message }
  }

  if (!Array.isArray(parsed)) return { ok: false, error: "Unexpected systemctl unit file output shape" }

  var states = {}
  parsed.forEach(function(entry) {
    var name = String(entry.unit_file || "")
    if (name !== "") states[name] = String(entry.state || "")
  })
  return { ok: true, states: states }
}

// Instances like "foo@1.service" have no unit file of their own; their
// enablement comes from the template "foo@.service".
function enablementState(unitName, states) {
  if (!states || !unitName) return ""
  if (states[unitName] !== undefined) return states[unitName]
  var at = unitName.indexOf("@")
  if (at > 0) {
    var dot = unitName.lastIndexOf(".")
    var template = unitName.slice(0, at + 1) + (dot > at ? unitName.slice(dot) : "")
    if (states[template] !== undefined) return states[template]
  }
  return ""
}

// For a user unit "enabled" means it's pulled in when the user session
// starts (login), not at machine boot. Only enabled/disabled can be flipped
// with enable/disable; everything else is started some other way, so the row
// explains that instead of offering a toggle. Deliberately no --now: Start
// and Stop stay the only buttons that change whether it's running.
var ENABLEMENT_EXPLANATIONS = {
  "static": "No autostart setting: started by another unit, socket or D-Bus",
  "indirect": "No autostart setting: enabled through another unit",
  "generated": "No autostart setting: generated (e.g. from an XDG autostart entry)",
  "transient": "No autostart setting: transient unit created at runtime",
  "alias": "No autostart setting: this name is an alias",
  "masked": "Masked: can't be started until unmasked",
  "linked": "Linked unit file",
  "enabled-runtime": "Starts at login until next reboot (enabled at runtime)"
}

function autostartAction(state) {
  if (state === "enabled") {
    return { toggleable: true, on: true, verb: "disable", label: "Starts at login · click to disable" }
  }
  if (state === "disabled") {
    return { toggleable: true, on: false, verb: "enable", label: "Doesn't start at login · click to enable" }
  }
  var explanation = ENABLEMENT_EXPLANATIONS[state]
  return {
    toggleable: false,
    on: state === "enabled-runtime",
    verb: "",
    label: explanation || (state ? "Autostart: " + state : "Autostart state unknown")
  }
}

// Every process the plugin launches is built here, never inline in QML.
// Binaries are pinned to their packaged paths and the environment is
// rebuilt from scratch, so a writable directory early in the shell's PATH
// can't swap in a different "systemctl".
var TRUSTED_BINARIES = {
  systemctl: "/usr/bin/systemctl",
  journalctl: "/usr/bin/journalctl"
}

// systemctl --user needs the session's runtime dir/bus to find the user
// manager; nothing else is passed through.
var PASSED_ENV_KEYS = ["XDG_RUNTIME_DIR", "DBUS_SESSION_BUS_ADDRESS"]

function minimalEnvironment(sessionEnv) {
  var vars = ["PATH=/usr/bin", "LANG=C.UTF-8"]
  PASSED_ENV_KEYS.forEach(function(key) {
    var value = sessionEnv ? sessionEnv[key] : undefined
    if (value !== undefined && value !== null && String(value) !== "") vars.push(key + "=" + String(value))
  })
  return vars
}

// Hard deadlines per process. /usr/bin/timeout runs the command in its own
// process group and signals the whole group: TERM at the deadline (or as
// soon as timeout itself gets TERM, which is what Quickshell sends when a
// Process is stopped), then KILL KILL_AFTER_SEC later if anything is still
// alive. timeout waits for its child, and Quickshell reaps timeout.
//
// If timeout itself is SIGKILLed (it can't forward that), the parent-death
// signals set with setpriv take over: timeout gets TERM if the shell goes
// away, and the command gets KILL if timeout goes away, so nothing outlives
// the process that started it. The same KILL-on-parent-death is set on the
// output-limiting bash in between (see LIMIT_OUTPUT_SCRIPT).
var TIMEOUT_SEC = { list: 10, action: 30, journal: 10 }
var KILL_AFTER_SEC = 2

// /usr/bin/timeout exits 124 when TERM was enough. When it has to fall back
// to KILL it re-raises KILL on itself, which Quickshell reports as a crash
// exit with exitCode 9 (a shell would show 137).
var CRASH_EXIT = 1

function timedOut(exitCode, exitStatus) {
  return exitCode === 124 || exitCode === 137 || (exitStatus === CRASH_EXIT && exitCode === 9)
}

function processErrorText(exitCode, exitStatus, stderrText, fallback, timeoutSec) {
  if (timedOut(exitCode, exitStatus)) return fallback + " (timed out after " + timeoutSec + "s)"
  var trimmed = String(stderrText || "").trim()
  return trimmed || fallback
}

// Byte ceilings per stream. The output is cut in the pipeline before it
// reaches Quickshell, so a StdioCollector never has to buffer more than
// this. Current list output is ~6 KB for ~50 units.
var OUTPUT_LIMITS = {
  list: { stdout: 1048576, stderr: 65536 },
  action: { stdout: 65536, stderr: 65536 },
  journal: { stdout: 262144, stderr: 65536 }
}

// Runs "$@" with stdout and stderr each passed through head -c. stdout goes
// through one extra byte first so going over the limit can be detected:
// the command then fails with "output exceeded N bytes" instead of handing
// back silently truncated JSON. pipefail keeps the command's own exit
// status, and `wait $!` makes sure the stderr reader has flushed before the
// script exits. The no-op TERM trap keeps bash waiting for the pipeline
// after timeout's TERM instead of exiting first; otherwise timeout would
// see its child gone and skip the KILL for anything that ignored TERM.
// Arguments are positional, never spliced into the script.
var LIMIT_OUTPUT_SCRIPT = [
  "out_max=$1 err_max=$2; shift 2",
  "set -o pipefail",
  "trap : TERM",
  "exec 3>&2",
  "{",
  "  \"$@\" | /usr/bin/head -c \"$((out_max + 1))\" | {",
  "    /usr/bin/head -c \"$out_max\"",
  "    if LC_ALL=C IFS= read -r -n 1 _; then",
  "      echo \"output exceeded $out_max bytes\" >&3",
  "      exit 1",
  "    fi",
  "  }",
  "} 2> >(/usr/bin/head -c \"$err_max\" >&2)",
  "status=$?",
  "wait $!",
  "exit $status"
].join("\n")

function boundedCommand(argv, sessionEnv, timeoutSec, limits) {
  return ["/usr/bin/env", "-i"]
    .concat(minimalEnvironment(sessionEnv))
    .concat(["/usr/bin/setpriv", "--pdeathsig", "TERM"])
    .concat(["/usr/bin/timeout", "--kill-after=" + KILL_AFTER_SEC + "s", timeoutSec + "s"])
    .concat(["/usr/bin/setpriv", "--pdeathsig", "KILL"])
    .concat(["/usr/bin/bash", "-c", LIMIT_OUTPUT_SCRIPT, "limit-output", String(limits.stdout), String(limits.stderr)])
    .concat(["/usr/bin/setpriv", "--pdeathsig", "KILL"])
    .concat(argv)
}

function processCommand(tool, args, sessionEnv, kind) {
  var binary = TRUSTED_BINARIES[tool]
  if (!binary) throw new Error("Unknown tool: " + tool)
  return boundedCommand([binary].concat(args), sessionEnv, TIMEOUT_SEC[kind], OUTPUT_LIMITS[kind])
}

function listUnitsCommand(sessionEnv) {
  return processCommand("systemctl", ["--user", "list-units", "--type=service", "--all", "--output=json"], sessionEnv, "list")
}

function listUnitFilesCommand(sessionEnv) {
  return processCommand("systemctl", ["--user", "list-unit-files", "--type=service", "--output=json"], sessionEnv, "list")
}

function actionCommand(verb, unitName, sessionEnv) {
  return processCommand("systemctl", ["--user", verb, unitName], sessionEnv, "action")
}

function journalCommand(unitName, sessionEnv) {
  return processCommand("journalctl", ["--user", "-u", unitName, "-n", "20", "--no-pager", "--output=short-iso"], sessionEnv, "journal")
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
    formatJournalOutput: formatJournalOutput,
    heroStatus: heroStatus,
    TRUSTED_BINARIES: TRUSTED_BINARIES,
    minimalEnvironment: minimalEnvironment,
    TIMEOUT_SEC: TIMEOUT_SEC,
    KILL_AFTER_SEC: KILL_AFTER_SEC,
    timedOut: timedOut,
    processErrorText: processErrorText,
    OUTPUT_LIMITS: OUTPUT_LIMITS,
    boundedCommand: boundedCommand,
    processCommand: processCommand,
    listUnitsCommand: listUnitsCommand,
    listUnitFilesCommand: listUnitFilesCommand,
    parseUnitFiles: parseUnitFiles,
    enablementState: enablementState,
    autostartAction: autostartAction,
    actionCommand: actionCommand,
    journalCommand: journalCommand
  }
}
