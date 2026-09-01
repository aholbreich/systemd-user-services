---
id: task-xdw
title: Organize the service panel into semantic tabs (with research)
status: open
priority: medium
type: task
created_at: 2026-09-01T20:17:32Z
updated_at: 2026-09-01T20:17:32Z
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
---

## Description

Research typical systemd --user services and common conventions to derive a useful semantic tab set (e.g. by purpose: media, network, sync, dev, utilities, or similar). Document the chosen groupings and the rationale — the research is part of this task. Then add a tabbed interface to the service panel (Panel.qml), each tab populated from the classified unit list (Model.js), with per-tab counts and empty states, preserving state indicators and failed-first ordering.
