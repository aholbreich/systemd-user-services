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

  readonly property int refreshIntervalSec: intSetting("refreshIntervalSec", 10, 5, 300)

  property string _listOutput: ""
  property string _listError: ""

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
