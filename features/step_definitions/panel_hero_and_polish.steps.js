const { Then } = require("@cucumber/cucumber")
const assert = require("node:assert/strict")
const Model = require("../../Model.js")

Then("the hero status for {int} total and {int} failed is {string} and not urgent", function(total, failed, expected) {
  const status = Model.heroStatus(total, failed)
  assert.equal(status.text, expected)
  assert.equal(status.urgent, false)
})

Then("the hero status for {int} total and {int} failed is {string} and urgent", function(total, failed, expected) {
  const status = Model.heroStatus(total, failed)
  assert.equal(status.text, expected)
  assert.equal(status.urgent, true)
})
