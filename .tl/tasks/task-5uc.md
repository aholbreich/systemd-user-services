---
id: task-5uc
title: 'Architecture review: modularisation, domain cut, simplification'
status: open
priority: medium
type: task
created_at: 2026-09-01T20:47:40Z
updated_at: 2026-09-01T20:47:40Z
created_by: claude-code
assignee: null
depends_on: []
claim:
  actor: null
  claimed_at: null
  expires_at: null
  heartbeat_at: null
tags:
  - architecture
  - refactor
references:
  - Panel.qml
  - Service.qml
  - Model.js
  - manifest.json
---

## Description

Review the codebase as an experienced software architect. Assess modularisation and the domain cut: separation between QML views (Panel.qml, Service.qml), pure logic (Model.js), the plugin scaffold (manifest.json, entryPoints), and feature specs (cucumber). Critically challenge the current architecture and try to improve it, preferring simpler designs where possible (fewer layers, clearer responsibilities, less ceremony). Deliverable: a written review with concrete, prioritized recommendations; implement agreed low-risk changes directly and file follow-up tasks for larger refactors.
