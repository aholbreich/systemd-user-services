---
id: task-4mm
title: Service polls systemctl and exposes live unit state
status: done
priority: medium
type: task
created_at: 2026-09-01T18:36:41Z
updated_at: 2026-09-01T19:28:52Z
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

## Notes

- 2026-09-01T19:28:52Z [claude-code] note: Test-first: wrote the @automated step defs (features/step_definitions/service_polls_and_exposes_units.steps.js) against real 'systemctl --user list-units' output on this machine, confirmed it fails without Service.qml existing conceptually (well -- this scenario only needs Model.js, already had it from task-ts0, so it went green immediately once the step defs were correct; the real red/green cycle here was in the step defs themselves, e.g. an initial mistake routing through rawUnits instead of rawOverride causing double-JSON-encoding, caught immediately). Then implemented Service.qml (Timer+Process+watchdog, scoped to ONLY polling/exposing -- start/stop/restart deliberately left to task-6zg) and wired it into Panel.qml with a minimal live status line ('N user services (M failed)'), replacing the placeholder; full row-by-row UI is task-rhq's job, badge is task-eva's. Static gates clean (validate + qmllint exit 0). Live verification via omarchy-restart-shell + debugBarGeometry + omarchy-shell shell summon/hide + grim screenshot: panel genuinely shows '46 user services (0 failed)', cross-checked against raw 'systemctl --user list-units --type=service --all --output=json | wc' = 46. Exact match. For the @manual 'refreshes on a timer' scenario: initial process-polling verification attempts (ps grep, pgrep -x systemctl, strace) were unreliable/misleading -- ps/pgrep sampling is too coarse for a sub-10ms child process, and strace turned out not to be installed (its error was silently swallowed by an unrelated grep filter, giving a false 'zero activity' signal -- worth remembering as a trap). Settled on a temporary console.log diagnostic in Service.qml (added, verified, then fully removed before commit) plus a temporary refreshIntervalSec:5 override in shell.json's plugin instance settings (also reverted after) -- confirmed 5 distinct refreshes fired over ~13s at the overridden 5s interval, AND that the settings override genuinely propagates from shell.json into the Service instance (interval=5 in the log). Final state re-verified clean after reverting both temporary changes (restart + debugBarGeometry + log check). For the @manual 'hung systemctl doesn't freeze the badge' scenario: not live-triggered (would need modifying production code with a test-only hook to fake a hang, which isn't appropriate to ship). Verified by code-pattern equivalence instead: the watchdog Timer (15s) + running-guard is copied from the shipped, production tailscale Service.qml's pollWatchdog pattern, already proven correct there. Documenting this as a reasoned limitation, not a gap I'm hiding.
