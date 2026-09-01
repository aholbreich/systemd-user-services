const { Given, Then } = require("@cucumber/cucumber")
const assert = require("node:assert/strict")
const Model = require("../../Model.js")

Given("no user services are in a failed state", function() {
  this.badge = Model.badgeState(0)
})

Given("{int} user services are in a failed state", function(count) {
  this.badge = Model.badgeState(count)
})

Given("{int} user service is in a failed state", function(count) {
  this.badge = Model.badgeState(count)
})

Then("the bar shows the quiet gear icon with no badge", function() {
  assert.equal(this.badge.icon, "⚙")
  assert.equal(this.badge.badge, "")
})

Then("the bar shows the warning icon with badge {string}", function(expected) {
  assert.equal(this.badge.icon, "⚠")
  assert.equal(this.badge.badge, expected)
})

Then("the tooltip reads {string}", function(expected) {
  assert.equal(this.badge.tooltip, expected)
})
