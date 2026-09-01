const { Given, When, Then, After } = require("@cucumber/cucumber")
const assert = require("node:assert/strict")
const { execFileSync } = require("node:child_process")
const fs = require("node:fs")
const os = require("node:os")
const path = require("node:path")
const Model = require("../../Model.js")

// systemd-run --no-block creates a TRANSIENT unit: once it stops, systemd
// garbage-collects the unit definition entirely, so a later `start` fails
// with "not found" -- discovered by running this scenario for real, not
// guessed. A real (temporary) unit file is required to stop/start/restart
// the same unit repeatedly, like a normal persistent service.
Given("a disposable {string} unit created only for this test", function(_context) {
  this.unit = "oma-systemd-cucumber-test-" + process.pid + ".service"
  const dir = path.join(os.homedir(), ".config", "systemd", "user")
  fs.mkdirSync(dir, { recursive: true })
  this._unitFile = path.join(dir, this.unit)
  fs.writeFileSync(this._unitFile, "[Service]\nExecStart=/usr/bin/sleep infinity\n")
  execFileSync("systemctl", ["--user", "daemon-reload"])
  execFileSync("systemctl", ["--user", "start", this.unit])
  this._cleanup = () => {
    try { execFileSync("systemctl", ["--user", "stop", this.unit]) } catch (e) {}
    try { fs.unlinkSync(this._unitFile) } catch (e) {}
    try { execFileSync("systemctl", ["--user", "daemon-reload"]) } catch (e) {}
    try { execFileSync("systemctl", ["--user", "reset-failed", this.unit]) } catch (e) {}
  }
})

function unitActiveState(unit) {
  try {
    return execFileSync("systemctl", ["--user", "show", unit, "--property=ActiveState", "--value"], { encoding: "utf8" }).trim()
  } catch (e) {
    return "unknown"
  }
}

function unitStartTimestamp(unit) {
  // Monotonic microsecond-resolution clock, not the human-readable wall-clock
  // timestamp (second resolution) -- a fast restart can land in the same
  // wall-clock second, which made this flaky when discovered against the
  // real disposable unit.
  return execFileSync("systemctl", ["--user", "show", unit, "--property=ActiveEnterTimestampMonotonic", "--value"], { encoding: "utf8" }).trim()
}

When("I run {string}", function(command) {
  const parts = command.replace("<unit>", this.unit).split(" ")
  this._beforeTimestamp = this._lastTimestamp
  execFileSync(parts[0], parts.slice(1))
  this._lastTimestamp = unitStartTimestamp(this.unit)
})

Then("the unit's active state becomes {string}", function(expected) {
  assert.equal(unitActiveState(this.unit), expected)
})

Then("its start timestamp changes", function() {
  assert.notEqual(this._lastTimestamp, this._beforeTimestamp)
})

After(function() {
  if (this._cleanup) this._cleanup()
})

Given("a unit with active state {string}", function(state) {
  this.toggleUnit = { name: "x.service", shortName: "x", activeState: state, subState: state }
})

Then("its toggle action is {string} labelled {string}", function(verb, label) {
  const action = Model.toggleAction(this.toggleUnit)
  assert.equal(action.verb, verb)
  assert.equal(action.label, label)
})

Then("the action error for {string} on {string} with detail {string} is {string}", function(verb, unit, detail, expected) {
  assert.equal(Model.actionErrorMessage(verb, unit, detail), expected)
})
