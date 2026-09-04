import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model

Item {
  id: root

  property var settings: ({})

  property var units: []
  property int failedCount: 0
  property bool refreshing: false
  property string lastError: ""
  // Separate from lastError (list-poll failures): an action error must
  // stay visible for a beat, not get silently wiped by the very next
  // successful poll -- discovered live, the delayedRefresh 400ms after
  // every action was clearing it in under half a second.
  property string lastActionError: ""

  readonly property int refreshIntervalSec: intSetting("refreshIntervalSec", 10, 5, 300)

  // Unit currently mid-action, so the row can disable its buttons instead
  // of racing a second command against the first.
  property string pendingUnit: ""
  property string pendingVerb: ""

  property string _listOutput: ""
  property string _listError: ""
  property string _actionOutput: ""
  property string _actionError: ""

  // Which unit's log panel is expanded, if any -- at most one at a time,
  // mirroring pendingUnit's single-in-flight-action convention.
  property string logUnit: ""
  property string logText: ""
  property bool logLoading: false
  property string logError: ""
  property string _logOutput: ""
  property string _logError: ""

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function intSetting(name, fallback, min, max) {
    var n = parseInt(String(setting(name, fallback)), 10)
    if (!isFinite(n)) n = fallback
    if (n < min) n = min
    if (n > max) n = max
    return n
  }

  function refresh() {
    if (listProcess.running) return
    _listOutput = ""
    _listError = ""
    refreshing = true
    listProcess.running = true
    if (!pollWatchdog.running) pollWatchdog.start()
  }

  function applyUnits(raw) {
    var parsed = Model.parseUnits(raw)
    if (!parsed.ok) {
      lastError = parsed.error
      return
    }
    units = parsed.units
    failedCount = Model.countFailed(parsed.units)
    lastError = ""
  }

  function startUnit(name) { runAction("start", name) }
  function stopUnit(name) { runAction("stop", name) }
  function restartUnit(name) { runAction("restart", name) }

  // A second click on the already-open row collapses it; clicking a
  // different row's logs button switches straight to that unit.
  function toggleLogs(name) {
    if (logUnit === name) {
      logUnit = ""
      logText = ""
      logError = ""
      return
    }
    fetchLogs(name)
  }

  function fetchLogs(name) {
    if (!name || logProcess.running) return
    logUnit = name
    logText = ""
    logError = ""
    _logOutput = ""
    _logError = ""
    logLoading = true
    logProcess.command = ["journalctl", "--user", "-u", name, "-n", "20", "--no-pager", "--output=short-iso"]
    logProcess.running = true
  }

  function runAction(verb, name) {
    if (!name || actionProcess.running) return
    pendingUnit = name
    pendingVerb = verb
    lastActionError = ""
    _actionOutput = ""
    _actionError = ""
    actionProcess.command = ["systemctl", "--user", verb, name]
    actionProcess.running = true
  }

  Timer {
    id: refreshTimer
    interval: root.refreshIntervalSec * 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Timer {
    // A hung systemctl (rare, but rather safe than a permanently stale badge)
    // shouldn't stop future polls from ever firing again.
    id: pollWatchdog
    interval: 15000
    repeat: false
    onTriggered: if (listProcess.running) listProcess.running = false
  }

  Timer {
    // Give systemd a beat to settle before re-polling, rather than racing
    // the refresh against the action's own state transition.
    id: delayedRefresh
    interval: 400
    repeat: false
    onTriggered: root.refresh()
  }

  Timer {
    // Mirrors the shipped tailscale plugin's actionStatusTimer convention:
    // an action error is a transient toast, not a permanent banner, but
    // it must survive at least the delayedRefresh 400ms after it or no one
    // would ever see it.
    id: actionErrorTimer
    interval: 6000
    repeat: false
    onTriggered: root.lastActionError = ""
  }

  Process {
    id: actionProcess
    running: false
    command: []
    stdout: StdioCollector { id: actionStdout; waitForEnd: true; onStreamFinished: root._actionOutput = text }
    stderr: StdioCollector { id: actionStderr; waitForEnd: true; onStreamFinished: root._actionError = text }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        var detail = actionStderr.text || root._actionError || actionStdout.text || root._actionOutput
        root.lastActionError = Model.actionErrorMessage(root.pendingVerb, root.pendingUnit, detail)
        actionErrorTimer.restart()
      }
      root.pendingUnit = ""
      root.pendingVerb = ""
      delayedRefresh.restart()
    }
  }

  Process {
    id: logProcess
    running: false
    command: []
    stdout: StdioCollector { id: logStdout; waitForEnd: true; onStreamFinished: root._logOutput = text }
    stderr: StdioCollector { id: logStderr; waitForEnd: true; onStreamFinished: root._logError = text }
    onExited: function(exitCode) {
      root.logLoading = false
      if (exitCode === 0) root.logText = Model.formatJournalOutput(logStdout.text || root._logOutput)
      else root.logError = (logStderr.text || root._logError || "journalctl failed").trim()
    }
  }

  Process {
    id: listProcess
    running: false
    command: ["systemctl", "--user", "list-units", "--type=service", "--all", "--output=json"]
    stdout: StdioCollector {
      id: listStdout
      waitForEnd: true
      onStreamFinished: root._listOutput = text
    }
    stderr: StdioCollector {
      id: listStderr
      waitForEnd: true
      onStreamFinished: root._listError = text
    }
    onExited: function(exitCode) {
      root.refreshing = false
      if (exitCode === 0) root.applyUnits(listStdout.text || root._listOutput)
      else root.lastError = (listStderr.text || root._listError || "systemctl list-units failed").trim()
    }
  }
}
