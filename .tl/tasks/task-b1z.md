---
id: task-b1z
title: Publish the plugin to the Omarchy plugin marketplace (plugins.omarchy.org)
status: open
priority: medium
type: task
created_at: 2026-09-01T20:42:34Z
updated_at: 2026-09-01T20:42:34Z
created_by: claude-code
assignee: null
depends_on:
  - task-zj1
claim:
  actor: null
  claimed_at: null
  expires_at: null
  heartbeat_at: null
tags:
  - release
  - meta
---

## Description

Get the plugin listed on https://plugins.omarchy.org/. How the marketplace is populated is part of this task — the known path: it's a GitHub Pages site backed by github.com/omacom/omarchy-plugin-marketplace; the publish guide (https://plugins.omarchy.org/publish.html) requires a public GitHub repo with valid manifest.json, README + license, and safe install/removal, then submission via the issue form (repo link, category, tags) where automated validation checks the current commit before a maintainer approves the listing. Execute that flow: verify the repo satisfies the checklist, submit the issue with repo link + category + tags, and follow up until the listing is approved and visible on the marketplace. Depends on the repo from task 1.
