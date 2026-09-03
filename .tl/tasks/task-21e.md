---
id: task-21e
title: Hide Restart button when a service isn't running (Start already covers it)
status: open
priority: medium
type: task
created_at: 2026-09-03T23:01:59Z
updated_at: 2026-09-03T23:01:59Z
created_by: human
assignee: null
depends_on: []
claim:
  actor: null
  claimed_at: null
  expires_at: null
  heartbeat_at: null
tags:
  - ux
  - qml
references:
  - Panel.qml
  - Model.js
---

## Description

User feedback: a row's icon buttons should reflect only logically possible actions. Right now every row shows a toggle button (Start/Stop depending on state, via Model.toggleAction) PLUS an always-visible Restart button, regardless of state. Restart is only a distinct action from Start when the unit is currently active/running -- systemctl restart on an inactive or failed unit (nothing running to stop first) is mechanically identical to systemctl start, so showing both is two icons for one action. Fix: only show/enable the Restart button when Model.isRunning(unit) is true (i.e. exactly when the toggle button is showing Stop); hide it (or disable it, TBD which reads better -- probably hide, to actually reduce row clutter, not just gray it out) when the toggle is showing Start (covers both inactive and failed states -- no separate carve-out needed, both already fall on the Start side of toggleAction). Likely touches: Panel.qml's restartBtn (currently rendered unconditionally in the row delegate) and possibly Model.js if the visibility decision belongs there as pure logic (e.g. a Model.canRestart(unit) or folding it into toggleAction's return value) rather than inline QML, to keep it test-first per this project's convention (task-66g review: pure decision logic belongs in Model.js, testable via Gherkin, QML wiring stays manual).
