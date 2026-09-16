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

  // Unit file name -> enablement state ("enabled", "disabled", "static", ...),
  // from a second poll alongside list-units. Kept separate from `units` so a
  // failure here only hides the autostart toggles, not the whole list.
  property var unitFileStates: ({})
  property var _loadedUnits: []
  property string unitFilesError: ""

  readonly property int refreshIntervalSec: intSetting("refreshIntervalSec", 10, 5, 300)

  // Unit currently mid-action, so the row can disable its buttons instead
  // of racing a second command against the first.
  property string pendingUnit: ""
  property string pendingVerb: ""

  property string _listOutput: ""
  property string _listError: ""
  property string _unitFilesOutput: ""
  property string _unitFilesError: ""
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

  // Read once from the shell's environment; Model.minimalEnvironment
  // decides what actually reaches the child processes.
  readonly property var sessionEnv: ({
    XDG_RUNTIME_DIR: Quickshell.env("XDG_RUNTIME_DIR"),
    DBUS_SESSION_BUS_ADDRESS: Quickshell.env("DBUS_SESSION_BUS_ADDRESS")
  })

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
    listProcess.command = Model.listUnitsCommand(sessionEnv)
    listProcess.running = true
    refreshUnitFiles()
  }

  function refreshUnitFiles() {
    if (unitFilesProcess.running) return
    _unitFilesOutput = ""
    _unitFilesError = ""
    unitFilesProcess.command = Model.listUnitFilesCommand(sessionEnv)
    unitFilesProcess.running = true
  }

  function applyUnits(raw) {
    var parsed = Model.parseUnits(raw)
    if (!parsed.ok) {
      lastError = parsed.error
      return
    }
    _loadedUnits = parsed.units
    mergeUnits()
    lastError = ""
  }

  // Loaded units plus installed-but-unloaded ones; rerun whenever either
  // poll brings new data.
  function mergeUnits() {
    units = Model.mergeInstalledUnits(_loadedUnits, unitFileStates)
    failedCount = Model.countFailed(units)
  }

  function startUnit(name) { runAction("start", name) }
  function stopUnit(name) { runAction("stop", name) }
  function restartUnit(name) { runAction("restart", name) }
  function enableUnit(name) { runAction("enable", name) }
  function disableUnit(name) { runAction("disable", name) }

  function applyUnitFiles(raw) {
    var parsed = Model.parseUnitFiles(raw)
    if (!parsed.ok) {
      unitFilesError = parsed.error
      return
    }
    unitFileStates = parsed.states
    unitFilesError = ""
    mergeUnits()
  }

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
    logProcess.command = Model.journalCommand(name, sessionEnv)
    logProcess.running = true
  }

  function runAction(verb, name) {
    if (!name || actionProcess.running) return
    pendingUnit = name
    pendingVerb = verb
    lastActionError = ""
    _actionOutput = ""
    _actionError = ""
    actionProcess.command = Model.actionCommand(verb, name, sessionEnv)
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
    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0 || exitStatus !== 0) {
        var detail = Model.timedOut(exitCode, exitStatus)
          ? "timed out after " + Model.TIMEOUT_SEC.action + "s"
          : actionStderr.text || root._actionError || actionStdout.text || root._actionOutput
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
    onExited: function(exitCode, exitStatus) {
      root.logLoading = false
      if (exitCode === 0 && exitStatus === 0) root.logText = Model.formatJournalOutput(logStdout.text || root._logOutput)
      else root.logError = Model.processErrorText(exitCode, exitStatus, logStderr.text || root._logError, "journalctl failed", Model.TIMEOUT_SEC.journal)
    }
  }

  Process {
    id: unitFilesProcess
    running: false
    command: []
    stdout: StdioCollector { id: unitFilesStdout; waitForEnd: true; onStreamFinished: root._unitFilesOutput = text }
    stderr: StdioCollector { id: unitFilesStderr; waitForEnd: true; onStreamFinished: root._unitFilesError = text }
    onExited: function(exitCode, exitStatus) {
      if (exitCode === 0 && exitStatus === 0) root.applyUnitFiles(unitFilesStdout.text || root._unitFilesOutput)
      else root.unitFilesError = Model.processErrorText(exitCode, exitStatus, unitFilesStderr.text || root._unitFilesError, "systemctl list-unit-files failed", Model.TIMEOUT_SEC.list)
    }
  }

  Process {
    id: listProcess
    running: false
    command: []
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
    onExited: function(exitCode, exitStatus) {
      root.refreshing = false
      if (exitCode === 0 && exitStatus === 0) root.applyUnits(listStdout.text || root._listOutput)
      else root.lastError = Model.processErrorText(exitCode, exitStatus, listStderr.text || root._listError, "systemctl list-units failed", Model.TIMEOUT_SEC.list)
    }
  }
}
