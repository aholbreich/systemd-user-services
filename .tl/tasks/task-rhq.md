---
id: task-rhq
title: Panel lists user services grouped by state
status: done
priority: medium
type: task
created_at: 2026-09-01T18:36:41Z
updated_at: 2026-09-01T20:05:16Z
created_by: claude-code
assignee: null
depends_on:
  - task-4mm
claim:
  actor: null
  claimed_at: null
  expires_at: null
  heartbeat_at: null
tags:
  - mvp
  - qml
references:
  - features/panel_lists_services_by_state.feature
---

## Description

Clicking the bar icon opens a panel listing all systemctl --user services sorted failed>running>rest, each with a state indicator and label. Empty state and error state included.

## Notes

- 2026-09-01T20:05:16Z [claude-code] note: Test-first: extracted stateLabel(unit) as a pure Model.js function with dedup logic (only show '(subState)' when it differs from activeState). Discovered via REAL live data (created a throwaway failing unit earlier) that a failed unit's active/sub are BOTH literally 'failed' -- without dedup this would render as the redundant 'failed (failed)'. Wrote 2 automated scenarios (dedup case + informative case), red then green. Implemented the row-list UI in Panel.qml: Column with an error banner, an empty-state message, and a Repeater over services.units (dot indicator + name + state label per row). Row order and 'failed sorts first' are inherited from Model.sortUnits, already covered by list_and_classify_user_services.feature -- not re-tested. Static gates (validate + qmllint) were clean, but a LIVE check caught two real runtime bugs static gates and qmllint could not: I had invented 'Color.error'/'Color.success' and 'Style.font.small' tokens that don't exist in the real qs.Commons design system (qmllint can't check qs.* property existence at all, since it can't resolve the module). Runtime log showed 'Unable to assign [undefined] to int' repeated once per row. Fixed by grepping the actual Commons/Color.qml and Commons/Style.qml source for real tokens: Color.urgent/foreground/muted (no error/success exist) and Style.font.bodySmall (no .small exists). Re-verified: log clean after the fix, and omarchy-shell shell summon + a full-panel screenshot shows the real 46-row list rendering correctly, including the dedup working live ('active (running)' / 'inactive (dead)', not the redundant form). Lesson worth keeping: qmllint's inability to resolve qs.* modules means it CANNOT catch invented-property bugs like this -- only a live restart + log check + visual screenshot catches them. Static gates passing is necessary but not sufficient for QML stories that touch qs.Commons/qs.Ui tokens.
