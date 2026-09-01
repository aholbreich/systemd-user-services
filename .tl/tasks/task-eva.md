---
id: task-eva
title: Bar badge reflects failed service count
status: done
priority: medium
type: task
created_at: 2026-09-01T18:36:41Z
updated_at: 2026-09-01T19:59:44Z
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
  - features/bar_badge_reflects_failed_count.feature
---

## Description

Panel.qml bar icon shows a warning badge with failed count, quiet gear icon otherwise, correct singular/plural tooltip.

## Notes

- 2026-09-01T19:59:44Z [claude-code] note: Test-first: extracted the icon/badge/tooltip decision as a pure Model.badgeState(failedCount) function (feature file re-tagged: 3 scenarios moved from @manual to @automated since this logic doesn't need Quickshell). Wrote step defs, ran red (badgeState undefined), implemented, green (3/3). Wired Panel.qml's WidgetButton text/tooltipText to Model.badgeState(services.failedCount), replacing the previously-static '⚙'/'User services'. Static gates clean (validate + qmllint exit 0). Live verification went further than a code read: staged a REAL throwaway failing unit ('systemd-run --user --unit=oma-systemd-test-failure --no-block /bin/false', a transient unit, nothing persisted) to exercise the actual warning path end-to-end rather than trusting the static-icon logic alone. Confirmed via debugBarGeometry (width 30->39, consistent with '⚠ 1' vs '⚙') and a grim screenshot: real warning triangle + '1' badge rendered. Cleaned up the unit (stop + reset-failed), then -- without any restart -- waited past the next poll cycle (~11s) and confirmed via debugBarGeometry (width back to 30) and a second screenshot that the badge reverted to the quiet gear icon on its own. This also directly proves the @manual 'live update without reload' scenario as a side effect of testing the warning path for real, so I'm marking that scenario verified too, not just the 3 automated ones.
