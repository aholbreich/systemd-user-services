---
id: task-ts0
title: List and classify systemd --user services
status: done
priority: medium
type: task
created_at: 2026-09-01T18:36:41Z
updated_at: 2026-09-01T18:38:45Z
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
  - logic
references:
  - features/list_and_classify_user_services.feature
---

## Description

Pure Model.js logic: parse 'systemctl --user list-units --output=json', classify failed/running/inactive, sort failed-first, count failed. Fully automated via cucumber-js.

## Notes

- 2026-09-01T18:38:45Z [claude-code] note: Red->green via cucumber-js. Wrote features/step_definitions/list_and_classify_user_services.steps.js first (all steps failed: Model.js didn't exist at root), then implemented Model.js at root (adapted from spike/Model.js, unchanged logic). 9/9 scenarios pass in isolation (npx cucumber-js features/list_and_classify_user_services.feature). Fixed two issues found along the way: (1) a step function arity bug of my own steps file, (2) cucumber.js's default 'paths' key was overriding CLI-scoped feature-file args, so removed it. Full 'npx cucumber-js' run across all features: 9 passed, 2 correctly undefined (belong to later unclaimed stories task-4mm/task-6zg).
