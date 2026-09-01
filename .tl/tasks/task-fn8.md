---
id: task-fn8
title: Add a beautiful title and icons to the panel, matching Omarchy system panel conventions
status: open
priority: low
type: task
created_at: 2026-09-01T20:57:55Z
updated_at: 2026-09-01T20:57:55Z
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
  - Panel.qml
---

## Description

The shipped Omarchy system panels (e.g. the network panel) always carry a polished title, and icons where appropriate — this panel should too. Currently the header (PanelSectionHeader in Panel.qml) only shows the active tab label + count; there is no panel-level title or icons. Study the conventions of the Omarchy system panels (title wording, capitalization, icon usage, spacing) and add a matching title bar — e.g. "SYSTEMD USER SERVICES" with a status/gear icon — while keeping the tab row and existing header intact. Coordinate with task-x0j (padding) and task-mqw (colors) so the three polish items land coherently.
