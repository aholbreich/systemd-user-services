---
id: task-6zg
title: Start, stop, and restart a user service from the panel
status: done
priority: medium
type: task
created_at: 2026-09-01T18:36:41Z
updated_at: 2026-09-01T22:01:18Z
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

## Notes

- 2026-09-01T22:01:18Z [claude-code] note: Test-first: added toggleAction(unit) and actionErrorMessage(verb,name,detail) pure functions to Model.js, plus a Scenario Outline (3 states) and 2 error-formatting scenarios, all red before implementing, green after. UX design (asked to grill on this, but the user redirected to real shipped examples instead -- see task-xdw's history): two compact icon-only Button instances per row (real qs.Ui Button, iconText not text, tooltipText for clarity) -- a context-sensitive toggle (▶ start / ⏹ stop, whichever applies) plus an always-available restart (↻), both disabled while ANY action is in flight globally (services.pendingUnit !== ''), not just the affected row -- matches the actual single-flight constraint in Service.qml's runAction guard, avoids a dead click on other rows. Live-verified the REAL action wiring end-to-end, not just bash-level systemctl (no click-simulation tool available -- no wlrctl/ydotool on this system): created a real disposable persistent unit (~/.config/systemd/user/oma-systemd-live-test.service, not a systemd-run transient -- already learned that lesson from the cucumber step defs), temporarily wired Timers calling services.stopUnit/startUnit/restartUnit directly, confirmed via qs log + systemctl show that all three real actions executed correctly through the QML Process path with no overlap issues. Found and fixed a REAL bug via this live verification that no static gate or automated test could have caught: action errors were being silently wiped within ~400ms by the delayedRefresh's own successful poll (both shared one lastError property, and applyUnits() unconditionally clears it on any successful list refresh). A user would never actually see an action failure -- it flashed for under half a second. Fixed by splitting into lastError (list-poll) vs lastActionError (action failures), with its own ~6s auto-clear timer mirroring the shipped tailscale plugin's actionStatusTimer convention. Re-verified with precise timing checks (t+150ms/600ms/2000ms/6500ms) that the error now survives the refresh and clears on its own schedule -- confirmed both via log and a screenshot catching the banner live. Documented the bug and the new contract directly in the Gherkin scenario so a future refactor can't silently reintroduce it. All temporary verification code and the disposable test unit fully removed and reverted; final restart re-confirmed clean (geometry 30x26, zero log warnings, count back to the real 46). Updated README (feature list, Scope, Roadmap, refreshed panel-tabs.png screenshot to show the real action buttons) now that this is genuinely shipped, not aspirational.
