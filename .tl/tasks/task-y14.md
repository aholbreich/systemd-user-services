---
id: task-y14
title: All tab reads as a peer category instead of the absence of a filter
status: done
priority: medium
type: task
created_at: 2026-09-03T22:20:21Z
updated_at: 2026-09-03T22:20:24Z
created_by: human
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
references:
  - Panel.qml
---

## Description

User feedback: the All tab was styled identically (bordered pill) to the real semantic categories (Audio, Security, Portals, ...), implying it's a peer category when it's actually the absence of a filter. Fixed by making TabButton's bordered prop false for the All tab specifically (bordered: modelData.key !== "all"), so it renders as plain text at rest while the real categories keep their bordered pill look; selected/hover states are untouched since Button's own state machine already applies the selected fill/border regardless of the bordered prop. Verified live in both the idle and selected states via screenshot (temporarily defaulting selectedTabKey to another tab to see All's idle look, then reverted).
