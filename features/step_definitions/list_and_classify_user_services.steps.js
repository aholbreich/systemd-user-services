const { Given, When, Then, Before } = require("@cucumber/cucumber")
const assert = require("node:assert/strict")
const Model = require("../../Model.js")

Before(function() {
  this.rawUnits = []
  this.rawOverride = null
  this.result = null
})

Given("the raw JSON output of {string}", function(_command) {
  // Documents which real command this fixture stands in for; no setup needed.
})

Given("a unit {string} with active state {string} and sub state {string}", function(name, activeState, subState) {
  this.rawUnits.push({ unit: name, load: "loaded", active: activeState, sub: subState, description: name })
})

Given("no units are listed", function() {
  this.rawUnits = []
})

Given("the raw output is not valid JSON", function() {
  this.rawOverride = "{ this is not json "
})

When("the units are parsed", function() {
  const raw = this.rawOverride !== null ? this.rawOverride : JSON.stringify(this.rawUnits)
  this.result = Model.parseUnits(raw)
})

Then("parsing succeeds", function() {
  assert.equal(this.result.ok, true, this.result.error)
})

Then("parsing fails with an error message", function() {
  assert.equal(this.result.ok, false)
  assert.ok(this.result.error && this.result.error.length > 0)
})

function findUnit(result, shortName) {
  const unit = result.units.find(u => u.shortName === shortName)
  assert.ok(unit, `expected a parsed unit with short name "${shortName}"`)
  return unit
}

Then("the unit {string} is classified as running", function(shortName) {
  assert.equal(Model.isRunning(findUnit(this.result, shortName)), true)
})

Then("it is not classified as failed", function() {
  const lastUnit = this.result.units[this.result.units.length - 1]
  assert.equal(Model.isFailed(lastUnit), false)
})

Then("the unit {string} is classified as failed", function(shortName) {
  assert.equal(Model.isFailed(findUnit(this.result, shortName)), true)
})

Then("the unit {string} is classified as inactive", function(shortName) {
  const unit = findUnit(this.result, shortName)
  assert.equal(Model.isFailed(unit), false)
  assert.equal(Model.isRunning(unit), false)
})

Then("the sorted unit order is {string}", function(expectedCsv) {
  const expected = expectedCsv.split(",").map(s => s.trim())
  const actual = this.result.units.map(u => u.shortName)
  assert.deepEqual(actual, expected)
})

Then("the failed count is {int}", function(expected) {
  assert.equal(Model.countFailed(this.result.units), expected)
})

Then("the unit {string} has short name {string}", function(fullMatch, expectedShort) {
  const unit = findUnit(this.result, expectedShort)
  assert.equal(unit.shortName, expectedShort)
})
