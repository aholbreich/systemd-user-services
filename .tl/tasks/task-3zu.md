---
id: task-3zu
title: Explore detaching the panel into an Omarchy focus view (Super+O)
status: open
priority: low
type: task
created_at: 2026-09-01T20:55:45Z
updated_at: 2026-09-03T22:30:39Z
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

Explore rendering the service list as a detached, focused view similar to what omarchy opens with [Super]+O, rather than only the small bar-attached keyboard panel. Investigate how the focus view is invoked and what plugin APIs omarchy exposes for it; propose the minimal change to support a full-size focused service view (natural home for the tab/UX work landing later).

## Notes

- 2026-09-03T22:30:39Z [claude-code] note: Investigated live before pursuing: the task's own premise is wrong. Checked hyprctl binds -j directly -- Super+O is bound to "Pop window out (float & pin)" (window management), not any panel/gallery/focus-view opener. There is no such Omarchy hotkey. What Omarchy does have is a kind:"panel" plugin type (separate Item-based open()/close() entry point, distinct from our bar-widget's KeyboardPanel) -- real examples: omarchy.dev-gallery, omarchy.disk-speedtest, omarchy.osd, omarchy.speedtest, omarchy.wifiqr. But none of those are reachable through any shared, discoverable UI: each is summoned via a bespoke trigger (a CLI script, a hardware key event), and the Omarchy menu's own QML does not auto-list installed panel plugins. Building this for us would need a second manifest entry point + QML file, plus an "expand" button in our existing popup that shells out to omarchy-shell shell summon on ourselves (Process is already used this way for systemctl calls in Service.qml, so the idiom exists, but it's unusual for a plugin to summon itself). There's also no forcing need yet -- nothing on the roadmap requires more room than the 420px popup, especially after the task-5nm row-list fix. Recommendation: deprioritized, not pursuing now; revisit only if a concrete future feature needs more canvas than the popup can give.
