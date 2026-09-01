# Systemd User Services (Omarchy plugin)

List and control `systemctl --user` services from the Omarchy bar.

- Bar icon shows a warning badge with the count of failed user services.
- Click it to open a panel listing every user service, sorted failed → running → the rest.
- Start / Stop / Restart each unit inline.

## Scope (MVP)

- `systemctl --user` units only — no root/system-wide units, no privilege escalation.
- Read + control (start/stop/restart). No enable/disable, no log tailing, no
  notifications, no search/filter yet — see Roadmap.
- Polling-based refresh (default every 10s, configurable 5–300s), not D-Bus signals.

## Install

```sh
omarchy plugin add <this-repo-url> --enable
```

## Development

```sh
omarchy plugin clone io.github.aholbreich.systemd-user-services --edit
omarchy plugin validate ~/.config/omarchy/plugins/io.github.aholbreich.systemd-user-services
qmllint -I "$OMARCHY_PATH/shell" Panel.qml Service.qml
omarchy-shell shell rescanPlugins
qs log -p "$OMARCHY_PATH/shell" --tail 100
```

`Model.js` has no Quickshell dependency and can be exercised with plain Node
for quick unit-parsing checks.

## Roadmap ideas

- Enable/disable toggle (autostart) per unit.
- Inline `journalctl --user -u <unit> -n 20` tail per row.
- Notification (`notify-send`) when a unit transitions into `failed`.
- Search/filter box, group headers, restart confirmation for active units.
- Optional read-only view of system-wide (non-`--user`) units.
- Move refresh from polling to systemd's user D-Bus signals.
