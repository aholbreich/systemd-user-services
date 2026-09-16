const { Given, When, Then, After } = require("@cucumber/cucumber")
const assert = require("node:assert/strict")
const { execFileSync, spawnSync } = require("node:child_process")
const fs = require("node:fs")
const os = require("node:os")
const path = require("node:path")
const Model = require("../../Model.js")

function sessionEnv() {
  return {
    XDG_RUNTIME_DIR: process.env.XDG_RUNTIME_DIR,
    DBUS_SESSION_BUS_ADDRESS: process.env.DBUS_SESSION_BUS_ADDRESS
  }
}

function runArgv(argv) {
  return spawnSync(argv[0], argv.slice(1), { encoding: "utf8" })
}

Given("the raw list-unit-files JSON:", function(raw) {
  this.unitFilesRaw = raw
})

When("the unit files are parsed", function() {
  this.unitFiles = Model.parseUnitFiles(this.unitFilesRaw)
})

Then("parsing the unit files succeeds", function() {
  assert.ok(this.unitFiles.ok, this.unitFiles.error)
})

Then("parsing the unit files fails", function() {
  assert.equal(this.unitFiles.ok, false)
  assert.ok(this.unitFiles.error)
})

Then("the enablement state of {string} is {string}", function(unit, expected) {
  assert.equal(Model.enablementState(unit, this.unitFiles.states), expected)
})

Then("the autostart action for state {string} is toggleable {string} with verb {string} and on {string}", function(state, toggleable, verb, on) {
  const action = Model.autostartAction(state)
  assert.equal(action.toggleable, toggleable === "yes")
  assert.equal(action.verb, verb)
  assert.equal(action.on, on === "yes")
})

Then("the autostart label for state {string} is {string}", function(state, expected) {
  assert.equal(Model.autostartAction(state).label, expected)
})

When("the plugin's list-unit-files command runs on this machine", function() {
  const run = runArgv(Model.listUnitFilesCommand(sessionEnv()))
  assert.equal(run.status, 0, run.stderr)
  this.unitFiles = Model.parseUnitFiles(run.stdout)
})

Then("at least one unit file has state {string} or {string}", function(a, b) {
  const states = Object.values(this.unitFiles.states)
  assert.ok(states.includes(a) || states.includes(b), "states seen: " + [...new Set(states)].join(", "))
})

// A real unit file with [Install], so enable/disable have something to link.
// Never started: the scenario checks enable doesn't start it.
Given("a disposable unit with an [Install] section wanted by {string}", function(target) {
  this.autostartUnit = "oma-systemd-cucumber-autostart-" + process.pid + ".service"
  const dir = path.join(os.homedir(), ".config", "systemd", "user")
  fs.mkdirSync(dir, { recursive: true })
  this.autostartUnitFile = path.join(dir, this.autostartUnit)
  fs.writeFileSync(this.autostartUnitFile, "[Service]\nExecStart=/usr/bin/sleep infinity\n\n[Install]\nWantedBy=" + target + "\n")
  execFileSync("systemctl", ["--user", "daemon-reload"])
})

When("the plugin runs {string} on it", function(verb) {
  const run = runArgv(Model.actionCommand(verb, this.autostartUnit, sessionEnv()))
  assert.equal(run.status, 0, run.stderr)
})

function isEnabled(unit) {
  return spawnSync("systemctl", ["--user", "is-enabled", unit], { encoding: "utf8" }).stdout.trim()
}

Then("its enablement state becomes {string}", function(expected) {
  assert.equal(isEnabled(this.autostartUnit), expected)
  const run = runArgv(Model.listUnitFilesCommand(sessionEnv()))
  const parsed = Model.parseUnitFiles(run.stdout)
  assert.equal(Model.enablementState(this.autostartUnit, parsed.states), expected)
})

Then("it is still {string}", function(expected) {
  const state = spawnSync("systemctl", ["--user", "is-active", this.autostartUnit], { encoding: "utf8" }).stdout.trim()
  assert.equal(state, expected)
})

When("they are merged with the loaded unit {string} in state {string}", function(name, state) {
  const loaded = [{ name, shortName: Model.shortName(name), load: "loaded", activeState: state, subState: "running", description: "" }]
  this.merged = Model.mergeInstalledUnits(loaded, this.unitFiles.states)
})

Then("the merged list is {string}", function(expected) {
  assert.equal(this.merged.map(u => u.shortName).join(", "), expected)
})

Then("{string} is listed as {string}", function(name, label) {
  const unit = this.merged.find(u => u.name === name)
  assert.ok(unit, name + " missing")
  assert.equal(Model.stateLabel(unit), label)
})

Then("the plugin's merged unit list still contains it", function() {
  const list = runArgv(Model.listUnitsCommand(sessionEnv()))
  const files = runArgv(Model.listUnitFilesCommand(sessionEnv()))
  const units = Model.parseUnits(list.stdout).units
  const merged = Model.mergeInstalledUnits(units, Model.parseUnitFiles(files.stdout).states)
  assert.ok(merged.some(u => u.name === this.autostartUnit), "row for " + this.autostartUnit + " is gone")
})

After(function() {
  if (!this.autostartUnit) return
  try { execFileSync("systemctl", ["--user", "disable", this.autostartUnit], { stdio: "ignore" }) } catch (e) {}
  try { execFileSync("systemctl", ["--user", "stop", this.autostartUnit], { stdio: "ignore" }) } catch (e) {}
  try { fs.unlinkSync(this.autostartUnitFile) } catch (e) {}
  try { execFileSync("systemctl", ["--user", "daemon-reload"], { stdio: "ignore" }) } catch (e) {}
})
