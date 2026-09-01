---
id: task-fn8
title: Add a beautiful title and icons to the panel, matching Omarchy system panel conventions
status: done
priority: low
type: task
created_at: 2026-09-01T20:57:55Z
updated_at: 2026-09-01T22:21:10Z
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

## Notes

- 2026-09-01T22:21:10Z [claude-code] note: Researched the real network panel's hero convention before building anything (grepped the actual installed shell source): big icon (Style.font.display) + bold title (Style.font.title) + small-caps live status line (Style.font.caption, letterSpacing 1.2, uppercase) below it -- NOT one big all-caps line like the task's own example text ('SYSTEMD USER SERVICES') suggested. Followed the real convention over the task's literal wording. Grilled the user first: hero status live vs static (chose live -- '46 SERVICES, ALL HEALTHY' turning red '3 FAILED' on failures, mirrors network's dynamic caption) and whether to bundle with task-x0j/task-mqw now vs later (chose bundle, since the task explicitly asked to coordinate them). Test-first: Model.heroStatus(total, failed) is pure, testable -- 3 automated scenarios (0/1/N failed, singular/plural wording, urgent flag), red then green. Live-verified with a real screenshot showing the hero rendering correctly: gear icon, bold 'Systemd Services' title, dim '46 SERVICES, ALL HEALTHY' status line. First screenshot attempt actually failed for an unrelated reason -- blind-cropped a stale screen region and caught unrelated terminal scrollback instead of the panel (the desktop had changed: a new hostname label appeared in the bar, a concurrent session's sidebar entry disappeared) -- caught by looking at the FULL uncropped screenshot before trusting a blind crop again, not by assuming the plugin was broken.
