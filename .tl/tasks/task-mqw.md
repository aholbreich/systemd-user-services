---
id: task-mqw
title: Color-code service states in the panel
status: done
priority: low
type: task
created_at: 2026-09-01T20:17:32Z
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
---

## Description

Strengthen state coloring beyond the current rowColor mapping (urgent=failed, foreground=running, muted=inactive): apply distinct colors consistently to the status dot, name, state label, and (once tabs land) tab badges; check contrast on both light and dark themes. Color ideas should be proposed for review rather than assumed final — they may be challenged or refined during implementation.

## Notes

- 2026-09-01T22:21:10Z [claude-code] note: Scope check first: task's own description mentions 'tab badges' which no longer exist -- task-r3k already moved tab counts off the buttons into the header/tooltip, so that part of the original ask is moot, noted rather than silently ignored. Extended the existing rowColor() (urgent=failed/foreground=running/muted=other, already applied to the dot and state label) to the row's name text too, which was previously always plain root.barForeground regardless of state. Did NOT invent new colors (e.g. a 'success' green) -- confirmed earlier in this project that this theme genuinely has no such token; 'running' just means full-brightness foreground by design. Live-verified on a real inactive row (omarchy-migrate-notify): name and state label now both render in the same muted gray, visibly distinct from the bright running rows above it in the same screenshot.
