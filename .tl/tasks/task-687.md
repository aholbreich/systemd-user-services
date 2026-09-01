---
id: task-687
title: Panel service list overflows the panel when there are many services
status: done
priority: high
type: bug
created_at: 2026-09-01T20:13:01Z
updated_at: 2026-09-01T20:19:12Z
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
references:
  - Panel.qml
---

## Description

The KeyboardPanel lists every systemctl --user unit in a plain Column with no scrolling (Panel.qml). contentHeight is clamped via fittedContentHeight(column.implicitHeight, Style.space(400)), so with enough services the rows extend beyond the panel's fitted height and get cut off / overflow the panel instead of scrolling. Fix the panel so long lists are contained: cap the panel height and make the list scrollable (e.g. wrap the Repeater in a Flickable/ScrollView with clip: true and a bounded max height), keeping the grouped/state layout intact. Verify with the 'panel lists services by state' behavior — a large unit count must stay inside the panel bounds.

## Notes

- 2026-09-01T20:19:12Z [claude-code] note: Root cause: the row Column had no clip/Flickable wrapper, so with 46 real units the content's implicitHeight far exceeded the KeyboardPanel's fitted/capped contentHeight (Style.space(400) via fittedContentHeight), and rows past that cap were simply invisible/cut off with no way to scroll to them. Fix: wrapped the whole Column in a Flickable (clip: true, boundsBehavior: StopAtBounds, flickableDirection: VerticalFlick, interactive: contentHeight > height, ScrollBar.vertical policy AsNeeded) -- this is not an invented pattern, it's copied from the shipped tailscale and bluetooth plugins' own long-list handling (verified by grepping their real source, learning from the Color/Style token mistake in task-rhq). Added import QtQuick.Controls for ScrollBar. Added a new @manual scenario to panel_lists_services_by_state.feature describing the expected contained/scrollable behavior, since this fix has no pure-logic component worth unit testing -- it's a QML layout fix. Verified: static gates clean (validate + qmllint exit 0), automated suite still 15/15 passed, live restart shows zero runtime warnings (learned from task-rhq to check this explicitly, not just trust static gates), and a full-panel screenshot with the real 46-unit list open shows the panel now visibly terminates at its own border instead of spilling content past the screen edge as it did before the fix.
