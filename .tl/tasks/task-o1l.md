---
id: task-o1l
title: Test keyword-precedence when a unit name could match two category keywords
status: open
priority: low
type: task
created_at: 2026-09-03T22:57:10Z
updated_at: 2026-09-03T22:57:10Z
created_by: claude-code
assignee: null
depends_on: []
claim:
  actor: null
  claimed_at: null
  expires_at: null
  heartbeat_at: null
tags:
  - testing
  - spec
references:
  - Model.js
  - features/organize_panel_into_semantic_tabs.feature
---

## Description

From the task-66g senior-engineer test review: categorize()'s own code comment states 'Order matters: first keyword match wins, most-specific categories first' (Model.js CATEGORY_DEFINITIONS), but no scenario actually exercises that precedence rule with a synthetic unit name that could match two categories' keywords (e.g. a hypothetical name containing both a security keyword like gpg-agent and a portals keyword like portal). Every current Examples row happens to match exactly one category, so this behavior is asserted in a comment but never proven by a test. Low priority: no real unit name on a live Omarchy census actually collides across categories today, so this is a latent-behavior test, not a live bug. Add one Scenario Outline row (or a dedicated scenario) with a deliberately colliding synthetic short name asserting which category wins, when picked up.
