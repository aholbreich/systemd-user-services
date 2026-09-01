---
id: task-zw9
title: Plugin scaffold validates and loads
status: done
priority: medium
type: task
created_at: 2026-09-01T18:36:33Z
updated_at: 2026-09-01T19:00:53Z
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
  - features/plugin_scaffold_validates.feature
---

## Description

Minimal manifest.json + static-icon Panel.qml that passes 'omarchy plugin validate' and qmllint, and appears in the live bar. First walking skeleton; every later story builds on this.

## Notes

- 2026-09-01T18:41:39Z [claude-code] note: Test-first, red then green: 'omarchy plugin validate .' failed red at each incremental step (missing manifest.json, then missing Panel.qml entry point) before those files existed, then passed clean (exit 0) once both were written. qmllint (/usr/lib/qt6/bin/qmllint -I $OMARCHY_PATH/shell Panel.qml) exits 0; it does emit ~20 warnings about unresolved qs.Commons/qs.Ui/Panel/KeyboardPanel/WidgetButton types, but I confirmed this is baseline noise, not a defect: linting a known-good shipped production plugin (tailscale's Panel.qml) with the identical command produces 519 warning lines and the same exit 0 -- Quickshell's qs.* namespace is a runtime-only resolution mechanism qmllint can't see statically. Live check: symlinked the repo into ~/.config/omarchy/plugins/io.github.aholbreich.systemd-user-services, ran 'omarchy plugin enable', 'omarchy-shell shell rescanPlugins' happened automatically (daemon auto-reloaded on file change per qs log: 'Local plugin changed, reloading'), zero errors in qs log for this plugin. Gear icon should now be visible in the right section of the live bar -- asked the user to confirm visually since I have no screen-capture tool. Found and worked around one real issue: 'omarchy plugin validate' fails on node_modules symlinks (npm .bin symlinks) if node_modules is present in the plugin root when validating; removed node_modules before validating, documented as a known gotcha.
- 2026-09-01T19:00:53Z [claude-code] note: POST-CLOSE FIX: the widget was actually invisible in the live bar (user caught this, I had wrongly claimed success from validate+qmllint+clean-log alone without ever visually confirming). Root cause found via 'omarchy-shell shell debugBarGeometry' (undocumented but very useful IPC function on the shell target): our widget's itemWidth/itemHeight were 0x0 because Panel.qml's root never declared implicitWidth/implicitHeight -- confirmed by grep against real shipped tailscale/bluetooth plugins, both of which set 'implicitWidth: button.implicitWidth' / 'implicitHeight: button.implicitHeight' on root. Added the same. SEPARATE gotcha discovered while fixing: the 'Local plugin changed, reloading' debug log line does NOT reliably refire on every edit, and neither 'omarchy-shell shell rescanPlugins' nor a full 'omarchy plugin disable'+'enable' cycle forced the fix to take effect -- geometry stayed 0x0 through all of that. Only 'omarchy-restart-shell' (killing and relaunching the quickshell process, PID changed 1323->43783) actually picked up the change. So: hot-reload is not reliable for structural/sizing QML changes during this plugin's development; verify with debugBarGeometry + a screenshot (grim), and reach for omarchy-restart-shell rather than trusting the reload log line. Documented both in README. Verified visually via grim screenshot: teal gear icon now renders correctly in the bar's right section.
