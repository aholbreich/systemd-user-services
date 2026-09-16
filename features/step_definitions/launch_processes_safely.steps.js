const { Given, When, Then, After } = require("@cucumber/cucumber")
const assert = require("node:assert/strict")
const { spawnSync } = require("node:child_process")
const fs = require("node:fs")
const os = require("node:os")
const path = require("node:path")
const Model = require("../../Model.js")

function currentSessionEnv() {
  return {
    XDG_RUNTIME_DIR: process.env.XDG_RUNTIME_DIR,
    DBUS_SESSION_BUS_ADDRESS: process.env.DBUS_SESSION_BUS_ADDRESS
  }
}

function allCommands() {
  const env = currentSessionEnv()
  return {
    list: Model.listUnitsCommand(env),
    action: Model.actionCommand("restart", "x.service", env),
    journal: Model.journalCommand("x.service", env)
  }
}

// Index of the real binary in the argv, right after the NAME=value pairs.
function binaryOf(argv) {
  return argv.slice(2).find(a => !a.includes("="))
}

Then("the list, action and journal commands all start with {string}", function(prefix) {
  for (const argv of Object.values(allCommands())) {
    assert.deepEqual(argv.slice(0, 2), prefix.split(" "))
  }
})

Then("the {word} command runs {string}", function(which, binary) {
  assert.equal(binaryOf(allCommands()[which]), binary)
})

Given("a session environment with XDG_RUNTIME_DIR, DBUS_SESSION_BUS_ADDRESS and LD_PRELOAD set", function() {
  this.sessionEnv = {
    XDG_RUNTIME_DIR: "/run/user/1000",
    DBUS_SESSION_BUS_ADDRESS: "unix:path=/run/user/1000/bus",
    LD_PRELOAD: "/tmp/evil.so"
  }
})

Then("the child environment is exactly PATH, LANG, XDG_RUNTIME_DIR and DBUS_SESSION_BUS_ADDRESS", function() {
  assert.deepEqual(Model.minimalEnvironment(this.sessionEnv), [
    "PATH=/usr/bin",
    "LANG=C.UTF-8",
    "XDG_RUNTIME_DIR=/run/user/1000",
    "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
  ])
})

Given("a fake {string} that leaves a marker file, placed first on PATH", function(name) {
  this.fakeDir = fs.mkdtempSync(path.join(os.tmpdir(), "oma-systemd-fake-path-"))
  this.marker = path.join(this.fakeDir, "ran")
  const fake = path.join(this.fakeDir, name)
  fs.writeFileSync(fake, "#!/bin/sh\ntouch '" + this.marker + "'\necho '[]'\n")
  fs.chmodSync(fake, 0o755)
})

When("the list command runs with that PATH", function() {
  const argv = Model.listUnitsCommand(currentSessionEnv())
  this.run = spawnSync(argv[0], argv.slice(1), {
    encoding: "utf8",
    env: { ...process.env, PATH: this.fakeDir + ":" + process.env.PATH }
  })
})

Then("it succeeds with real systemctl JSON output", function() {
  assert.equal(this.run.status, 0, this.run.stderr)
  const parsed = Model.parseUnits(this.run.stdout)
  assert.ok(parsed.ok, parsed.error)
  assert.ok(parsed.units.length > 0, "expected the real user manager's units, not the fake's empty list")
})

Then("the fake {string} never ran", function(_name) {
  assert.equal(fs.existsSync(this.marker), false)
})

After(function() {
  if (this.fakeDir) fs.rmSync(this.fakeDir, { recursive: true, force: true })
})
