const { Given, Then } = require("@cucumber/cucumber")
const assert = require("node:assert/strict")
const Model = require("../../Model.js")

Given("a unit with active state {string} and sub state {string}", function(activeState, subState) {
  this.rowUnit = { name: "x.service", shortName: "x", activeState: activeState, subState: subState }
})

Then("its row label is {string}", function(expected) {
  assert.equal(Model.stateLabel(this.rowUnit), expected)
})
