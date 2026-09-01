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

This repo doubles as a working checkout: the plugin loads straight from it
via a symlink, no `omarchy plugin clone` needed while developing locally.

```sh
ln -s "$(pwd)" ~/.config/omarchy/plugins/io.github.aholbreich.systemd-user-services
omarchy plugin enable io.github.aholbreich.systemd-user-services
# the shell daemon auto-reloads on file change; watch for errors:
qs log -p "$OMARCHY_PATH/shell" --tail 100

# static checks (must be run with node_modules absent — see gotcha below):
rm -rf node_modules
omarchy plugin validate .
/usr/lib/qt6/bin/qmllint -I "$OMARCHY_PATH/shell" Panel.qml Service.qml
npm install   # restore node_modules for the automated suite below

# automated BDD suite (pure-logic stories only — see Testing strategy):
npm test
```

**Gotcha:** `omarchy plugin validate` walks the whole plugin folder looking
for disallowed symlinks, and npm's `node_modules/.bin/*` are symlinks — so
validate fails while `node_modules` is present. A real user's `git clone`
never has `node_modules`, so this only bites local dev; `rm -rf node_modules`
before validating, `npm install` again before running tests.

**qmllint warning noise is expected.** Quickshell's `qs.*` import namespace
(`qs.Commons`, `qs.Ui`, and shell-provided types like `Panel`/`WidgetButton`)
is resolved at runtime by Quickshell itself, not statically by `qmllint` —
even Omarchy's own first-party plugins produce hundreds of `unresolved-type`
/ `unqualified` warnings under the exact command above. Judge by **exit
code**, not warning count, when checking whether qmllint is "clean".

## Testing strategy

- **Automated (`npm test`, cucumber-js + Gherkin):** anything expressible as
  pure logic without Quickshell — currently `Model.js`'s parsing/sorting/
  classification. Feature files are tagged `@automated`.
- **Manual/live (`@manual` tagged scenarios in the same `.feature` files):**
  anything that only exists once QML is actually rendered by the running
  shell (bar icon, panel layout, click handling) — there is no headless
  Quickshell test runner. These scenarios are the acceptance checklist to
  walk through against the real bar (symlinked in as above) after each
  story lands.
- **Static gates on every story regardless of the split above:**
  `omarchy plugin validate .` and `qmllint` must both exit 0.

`Model.js` has no Quickshell dependency and can be exercised with plain Node
for quick unit-parsing checks.

## Roadmap ideas

- Enable/disable toggle (autostart) per unit.
- Inline `journalctl --user -u <unit> -n 20` tail per row.
- Notification (`notify-send`) when a unit transitions into `failed`.
- Search/filter box, group headers, restart confirmation for active units.
- Optional read-only view of system-wide (non-`--user`) units.
- Move refresh from polling to systemd's user D-Bus signals.
