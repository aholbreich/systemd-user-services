const { Then } = require("@cucumber/cucumber")
const assert = require("node:assert/strict")
const { execFileSync } = require("node:child_process")
const Model = require("../../Model.js")

Then("the formatted journal output for {string} is {string}", function(raw, expected) {
  assert.equal(Model.formatJournalOutput(raw), expected)
})

Then("{string} exits successfully", function(command) {
  const parts = command.replace("<unit>", this.unit).split(" ")
  execFileSync(parts[0], parts.slice(1))
})
