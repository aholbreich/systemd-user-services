const { Given, Then } = require("@cucumber/cucumber")
const assert = require("node:assert/strict")
const { execFileSync } = require("node:child_process")

// "When the units are parsed" and "Then parsing succeeds" are already
// registered by list_and_classify_user_services.steps.js and apply here
// unchanged (both operate on `this.rawUnits` / `this.result`).

Given("the real output of {string} on this machine", function(command) {
  const parts = command.split(" ")
  // Route through rawOverride (not rawUnits): "the units are parsed" step
  // JSON.stringifies rawUnits, which would double-encode this already-JSON text.
  this.rawOverride = execFileSync(parts[0], parts.slice(1), { encoding: "utf8" })
})

Then("every parsed unit has a name, a short name, an active state, and a sub state", function() {
  assert.ok(this.result.units.length > 0, "expected at least one real user service on this machine")
  for (const unit of this.result.units) {
    assert.ok(unit.name, "unit missing name")
    assert.ok(unit.shortName, "unit missing shortName")
    assert.ok(unit.activeState, `unit ${unit.name} missing activeState`)
    assert.ok(unit.subState, `unit ${unit.name} missing subState`)
  }
})
