---
id: task-5nm
title: 'Bug: All tab only shows ~5 of 46 services without obvious way to see the rest'
status: open
priority: high
type: task
created_at: 2026-09-01T22:28:17Z
updated_at: 2026-09-01T22:28:17Z
created_by: claude-code
assignee: null
depends_on: []
claim:
  actor: null
  claimed_at: null
  expires_at: null
  heartbeat_at: null
tags:
  - bug
references:
  - Panel.qml
---

## Description

Reported by the user: selecting the All tab doesn't show all services. Investigated before filing, not taking the report at face value:

CONFIRMED not a data bug: Model.groupUnitsByCategory against the real live 46-unit systemctl output returns count 46 for the 'all' key, and the panel's own header correctly reads 'ALL (46)'. Model.js is correct (verified independently via node, outside Quickshell).

CONFIRMED via screenshot (fresh shell restart, so selectedTabKey was at its true default 'all', not left on some other tab from prior interaction): only 5 rows are visible in the panel's fixed-height viewport before you'd need to scroll -- at-spi-dbus-bus, dbus-:1.22-org.a11y.atspi.Re..., dbus-broker, dconf, gnome-keyring-daemon. This is a real regression: before the hero header landed (task-fn8/x0j/mqw), roughly 9 rows were visible in the same panel. The KeyboardPanel height cap (Panel.qml's contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(400))) was never increased when the hero header + extra Style.spacing.panelGap section gaps were added on top of it, so the same fixed ~400-unit budget now has much less left over for the row list.

NOT YET CONFIRMED (no click/scroll-simulation tool available in this environment -- no wlrctl/ydotool/wtype-with-scroll): whether the Flickable actually scrolls to reveal the remaining 41 rows at all. No scrollbar thumb was visible in a static screenshot, but that alone isn't proof of breakage -- ScrollBar.policy: AsNeeded auto-hides when not actively scrolling/hovering in many Qt styles, so its absence in a static shot is expected either way. This needs to be tested by an actual scroll gesture (the user scrolling for real, or finding/adding a way to simulate one) before concluding whether this is 'just fewer rows visible, scroll still works' (an annoying but working regression) or 'scroll itself is broken' (a more serious bug).

Likely fix direction once confirmed: raise the height cap (Style.space(400) -> something larger) to restore more visible rows, and/or verify+fix the Flickable/ScrollBar wiring if scrolling itself turns out not to work.
