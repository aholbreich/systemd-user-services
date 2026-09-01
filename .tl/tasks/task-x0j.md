---
id: task-x0j
title: Polish panel spacing and padding
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

Improve the service panel's vertical rhythm and padding: consistent Style.space() insets around the content, comfortable row height, better header/empty-state spacing. Coordinate with the scrollable-list fix in task-687 so spacing survives the overflow restructure.

## Notes

- 2026-09-01T22:21:10Z [claude-code] note: Replaced ad-hoc Style.space(6) everywhere with the real named Style.spacing.* tokens (panelGap=14 between major sections, sm/md within the tab-button block, rowGap=8 between list rows, popupRowHeight=28 as the row-height floor) -- these are real tokens grepped from Commons/Style.qml, not invented. Also fixed a real pre-existing bug found while touching this: the error/empty-state Text banners kept their layout space even when invisible (Column doesn't collapse hidden children by default), leaving a phantom gap when there was no error -- added height: visible ? implicitHeight : 0 to collapse them properly. No pure logic here, QML-only, verified live via the same screenshot as task-fn8 (visibly more breathing room between hero/tabs/header/list than between individual rows).
