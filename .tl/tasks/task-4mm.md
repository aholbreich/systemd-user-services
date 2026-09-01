---
id: task-4mm
title: Service polls systemctl and exposes live unit state
status: open
priority: medium
type: task
created_at: 2026-09-01T18:36:41Z
updated_at: 2026-09-01T18:36:41Z
created_by: claude-code
assignee: null
depends_on:
  - task-zw9
  - task-ts0
claim:
  actor: null
  claimed_at: null
  expires_at: null
  heartbeat_at: null
tags:
  - mvp
  - qml
references:
  - features/service_polls_and_exposes_units.feature
---

## Description

Service.qml: Timer + Process wiring that periodically runs systemctl --user list-units and exposes units/failedCount/lastError, with a watchdog for hung processes.
