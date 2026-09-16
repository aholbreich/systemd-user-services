const { Given, When, Then, After } = require("@cucumber/cucumber")
const assert = require("node:assert/strict")
const { spawn, spawnSync } = require("node:child_process")
const fs = require("node:fs")
const os = require("node:os")
const path = require("node:path")
const Model = require("../../Model.js")

const SMALL_LIMITS = { stdout: 64, stderr: 64 }

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

// The real binary is whatever the innermost "setpriv --pdeathsig KILL" runs.
function binaryOf(argv) {
  return argv[argv.lastIndexOf("KILL") + 1]
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

Then("the {word} command is wrapped in {string}", function(which, wrapper) {
  const argv = allCommands()[which]
  const start = argv.indexOf("/usr/bin/timeout")
  assert.ok(start > 0, "no /usr/bin/timeout in " + argv.join(" "))
  assert.deepEqual(argv.slice(start, start + 3), wrapper.split(" "))
})

// Each hung test command writes the PIDs of its shell and background child
// to a file, so the test can check afterwards that none of them survived.
function hangingScript(pidFile, ignoreTerm) {
  return (ignoreTerm ? "trap '' TERM; " : "") +
    "/usr/bin/sleep 300 & echo $$ $! > '" + pidFile + "'; " +
    "while :; do /usr/bin/sleep 1; done"
}

function givenHanging(world, seconds, ignoreTerm) {
  world.tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "oma-systemd-hang-"))
  world.pidFile = path.join(world.tmpDir, "pids")
  world.argv = Model.boundedCommand(["/usr/bin/sh", "-c", hangingScript(world.pidFile, ignoreTerm)], currentSessionEnv(), seconds, SMALL_LIMITS)
}

Given("a bounded {int}s command that starts a background child and then hangs", function(seconds) {
  givenHanging(this, seconds, false)
})

Given("a bounded {int}s command that ignores TERM and hangs", function(seconds) {
  givenHanging(this, seconds, true)
})

Given("a bounded {int}s command that hangs in place", function(seconds) {
  this.tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "oma-systemd-hang-"))
  this.pidFile = path.join(this.tmpDir, "pids")
  const script = "echo $$ > '" + this.pidFile + "'; exec /usr/bin/sleep 300"
  this.argv = Model.boundedCommand(["/usr/bin/sh", "-c", script], currentSessionEnv(), seconds, SMALL_LIMITS)
})

When("it runs to completion", function() {
  const started = Date.now()
  this.run = spawnSync(this.argv[0], this.argv.slice(1), { encoding: "utf8", timeout: 20000 })
  this.elapsedMs = Date.now() - started
})

Then("it exits with {int} within {int} seconds", function(code, seconds) {
  assert.equal(this.run.status, code, this.run.stderr)
  assert.ok(this.elapsedMs < seconds * 1000, "took " + this.elapsedMs + "ms")
})

Then("it is killed by KILL within {int} seconds", function(seconds) {
  assert.equal(this.run.signal, "SIGKILL", "status " + this.run.status + ", stderr " + this.run.stderr)
  assert.ok(this.elapsedMs < seconds * 1000, "took " + this.elapsedMs + "ms")
})

function waitFor(predicate, ms) {
  const deadline = Date.now() + ms
  return new Promise((resolve) => {
    const tick = () => {
      if (predicate() || Date.now() > deadline) return resolve(predicate())
      setTimeout(tick, 50)
    }
    tick()
  })
}

function alive(pid) {
  try {
    // Zombies still answer kill(0); only count processes that aren't reaped yet
    // as dead if /proc says so.
    const stat = fs.readFileSync("/proc/" + pid + "/stat", "utf8")
    return !/^\d+ \(.*\) Z /.test(stat)
  } catch (e) {
    return false
  }
}

When("it is started and the launched process gets {word}", async function(signal) {
  this.child = spawn(this.argv[0], this.argv.slice(1), { stdio: "ignore" })
  this.exited = new Promise(resolve => this.child.on("exit", () => resolve(Date.now())))
  const ready = await waitFor(() => fs.existsSync(this.pidFile) && fs.readFileSync(this.pidFile, "utf8").trim() !== "", 3000)
  assert.ok(ready, "hanging command never started")
  this.signalledAt = Date.now()
  this.child.kill("SIG" + signal)
})

Then("it exits within {int} seconds", async function(seconds) {
  const exitedAt = await Promise.race([this.exited, new Promise(r => setTimeout(() => r(null), seconds * 1000))])
  assert.ok(exitedAt, "still running after " + seconds + "s")
})

Then("none of its processes are still alive", async function() {
  const pids = fs.readFileSync(this.pidFile, "utf8").trim().split(/\s+/).map(Number)
  assert.ok(pids.length > 0)
  const allGone = await waitFor(() => pids.every(pid => !alive(pid)), 3000)
  assert.ok(allGone, "still alive: " + pids.filter(alive).join(", "))
})

Then("the error text for a {word} exit {int} with stderr {string} is {string}", function(kind, code, stderr, expected) {
  const exitStatus = kind === "crash" ? 1 : 0
  const text = Model.processErrorText(code, exitStatus, stderr.replace(/\\n/g, "\n"), "systemctl list-units failed", Model.TIMEOUT_SEC.list)
  assert.equal(text, expected)
})

Then("the list command limits stdout to {int} and stderr to {int} bytes", function(out, err) {
  const argv = allCommands().list
  const i = argv.indexOf("limit-output")
  assert.ok(i > 0, "no output limiter in " + argv.join(" "))
  assert.deepEqual(argv.slice(i + 1, i + 3), [String(out), String(err)])
})

Then("the output limiter runs inside the timeout and outside the real binary", function() {
  for (const argv of Object.values(allCommands())) {
    const timeoutAt = argv.indexOf("/usr/bin/timeout")
    const bashAt = argv.indexOf("/usr/bin/bash")
    const binaryAt = argv.lastIndexOf("KILL") + 1
    assert.ok(timeoutAt < bashAt && bashAt < binaryAt, argv.join(" "))
  }
})

When("a command limited to {int} bytes of stdout and {int} of stderr runs {string}", function(out, err, script) {
  const argv = Model.boundedCommand(["/usr/bin/sh", "-c", script], currentSessionEnv(), 5, { stdout: out, stderr: err })
  const started = Date.now()
  this.run = spawnSync(argv[0], argv.slice(1), { encoding: "utf8", timeout: 20000 })
  this.elapsedMs = Date.now() - started
})

Then("it exits with {int}", function(code) {
  assert.equal(this.run.status, code, this.run.stderr)
})

Then("stdout is exactly {int} bytes", function(n) {
  assert.equal(Buffer.byteLength(this.run.stdout), n)
})

Then("stdout is {string}", function(expected) {
  assert.equal(this.run.stdout, expected)
})

Then("stderr is {string}", function(expected) {
  assert.equal(this.run.stderr.trim(), expected)
})

Then("stderr is at most {int} bytes", function(n) {
  assert.ok(Buffer.byteLength(this.run.stderr) <= n, Buffer.byteLength(this.run.stderr) + " bytes")
})

Then("it finished within {int} second(s)", function(seconds) {
  assert.ok(this.elapsedMs < seconds * 1000, "took " + this.elapsedMs + "ms")
})

After(function() {
  if (this.child && this.child.exitCode === null) this.child.kill("SIGKILL")
  if (this.fakeDir) fs.rmSync(this.fakeDir, { recursive: true, force: true })
  if (this.tmpDir) fs.rmSync(this.tmpDir, { recursive: true, force: true })
})
