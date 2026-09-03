const { Given, When, Then } = require("@cucumber/cucumber")
const assert = require("node:assert/strict")
const Model = require("../../Model.js")

function makeUnit(name, activeState, subState) {
  return {
    name: name,
    shortName: Model.shortName(name),
    activeState: activeState || "active",
    subState: subState || "running"
  }
}

Given("a unit named {string}", function(name) {
  this.categorizeUnit = makeUnit(name)
})

Then("it is categorized as {string}", function(expected) {
  assert.equal(Model.categorize(this.categorizeUnit), expected)
})

Given("a session with {int} audio services and 0 services in every other category", function(count) {
  this.tabUnits = []
  for (var i = 0; i < count; i++) this.tabUnits.push(makeUnit("pipewire-" + i + ".service"))
})

Given("a failed audio service {string}, a running audio service {string}, and a failed security service {string}, listed out of order", function(a, b, c) {
  // Constructed running-before-failed, then run through the real
  // Model.sortUnits (the same function Model.parseUnits calls internally)
  // -- so this actually proves failed-first order survives the pipeline,
  // rather than merely preserving whatever order the fixture was listed in.
  var unsorted = [
    makeUnit(b + ".service", "active", "running"),
    makeUnit(a + ".service", "failed", "failed"),
    makeUnit(c + ".service", "failed", "failed")
  ]
  this.tabUnits = Model.sortUnits(unsorted)
})

When("the units are grouped into tabs", function() {
  this.tabs = Model.groupUnitsByCategory(this.tabUnits)
})

function findTab(tabs, key) {
  var tab = tabs.find(function(t) { return t.key === key })
  assert.ok(tab, `expected a "${key}" tab`)
  return tab
}

Then("the {string} tab count is {int}", function(key, expected) {
  assert.equal(findTab(this.tabs, key).count, expected)
})

Then("every fixed category key is present in the tab list", function() {
  var keys = this.tabs.map(function(t) { return t.key })
  for (var i = 0; i < Model.CATEGORY_KEYS.length; i++) {
    assert.ok(keys.indexOf(Model.CATEGORY_KEYS[i]) !== -1, `missing tab for category "${Model.CATEGORY_KEYS[i]}"`)
  }
})

Then("the {string} tab's units in order are {string}", function(key, expectedCsv) {
  var expected = expectedCsv.split(",").map(function(s) { return s.trim() })
  var actual = findTab(this.tabs, key).units.map(function(u) { return u.shortName })
  assert.deepEqual(actual, expected)
})
