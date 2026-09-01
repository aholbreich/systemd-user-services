---
id: task-rhq
title: Panel lists user services grouped by state
status: open
priority: medium
type: task
created_at: 2026-09-01T18:36:41Z
updated_at: 2026-09-01T18:36:41Z
created_by: claude-code
assignee: null
depends_on:
  - task-4mm
claim:
  actor: null
  claimed_at: null
  expires_at: null
  heartbeat_at: null
tags:
  - mvp
  - qml
references:
  - features/panel_lists_services_by_state.feature
---

## Description

Clicking the bar icon opens a panel listing all systemctl --user services sorted failed>running>rest, each with a state indicator and label. Empty state and error state included.
