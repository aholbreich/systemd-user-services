---
id: task-pyx
title: Add a status filter (All/Running/Stopped/Failed) combinable with category tabs
status: open
priority: medium
type: task
created_at: 2026-09-01T22:07:10Z
updated_at: 2026-09-01T22:07:10Z
created_by: claude-code
assignee: null
depends_on: []
claim:
  actor: null
  claimed_at: null
  expires_at: null
  heartbeat_at: null
tags:
  - mvp
  - qml
  - ux
references:
  - Model.js
  - Panel.qml
  - features/organize_panel_into_semantic_tabs.feature
---

## Description

Second compact button row directly under the existing category-tab row (same real qs.Ui Button component/pattern, not new UI vocabulary), filtering by activeState: All / Running / Stopped / Failed. Combines with the category tab as an AND condition (e.g. 'Audio' tab + 'Running' filter shows only running audio services) -- these are two independent, orthogonal dimensions, not mutually exclusive, per the user's explicit note on task-xdw that filters should be a separate axis from tabs.

Deliberately scoped to just activeState (data we already parse, no new systemctl query needed) -- NOT expanding to subState detail (activating/deactivating/reloading/auto-restart transient states, too fine-grained/rare to be worth a filter option), NOT load-state/masked filtering, NOT enable/disable (autostart) filtering, and NOT free-text search. Those were proposed alongside this as good follow-ups but are separate, larger-scoped ideas (load-state needs surfacing unit.load which we parse but never show; enable-state needs a second systemctl query (list-unit-files) and pairs naturally with the not-yet-built enable/disable toggle; search is its own UI element) -- file separate tasks for those if/when picked up, don't fold them into this one.

Test-first as usual: the filter predicate (does a unit match a given status filter) is pure logic, belongs in Model.js, testable via Gherkin/cucumber without Quickshell. The button row wiring stays QML/manual, same split as the category tabs work.
