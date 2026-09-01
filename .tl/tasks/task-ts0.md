---
id: task-ts0
title: List and classify systemd --user services
status: open
priority: medium
type: task
created_at: 2026-09-01T18:36:41Z
updated_at: 2026-09-01T18:36:41Z
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
