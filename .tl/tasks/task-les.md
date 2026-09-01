---
id: task-les
title: Design how to present per-service information (source + UI)
status: open
priority: medium
type: task
created_at: 2026-09-01T20:55:45Z
updated_at: 2026-09-01T20:55:45Z
created_by: claude-code
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
  - research
---

## Description

Develop the concept for providing info about a service in the panel. Open questions the task must resolve: where the info comes from (systemctl --user show <unit> fields / unit Description / man pages / curated static source), whether standard services get hardcoded descriptions or a standard/Omarchy-provided source is preferred, and how it's shown — e.g. an "(i)" info icon with hover tooltip and/or click popup. Deliverable: a short design note with a recommendation, then implement it (or file a follow-up task if the implementation is large).
