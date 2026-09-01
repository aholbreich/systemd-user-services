---
id: task-6zg
title: Start, stop, and restart a user service from the panel
status: open
priority: medium
type: task
created_at: 2026-09-01T18:36:41Z
updated_at: 2026-09-01T18:36:41Z
created_by: claude-code
assignee: null
depends_on:
  - task-rhq
claim:
  actor: null
  claimed_at: null
  expires_at: null
  heartbeat_at: null
tags:
  - mvp
  - qml
references:
  - features/start_stop_restart_service.feature
---

## Description

Per-row Start/Stop/Restart buttons invoke systemctl --user start|stop|restart, disable while in flight, refresh after, and surface errors instead of failing silently.
