---
id: task-b1z
title: Publish the plugin to the Omarchy plugin marketplace (plugins.omarchy.org)
status: open
priority: medium
type: task
created_at: 2026-09-01T20:42:34Z
updated_at: 2026-09-03T22:40:42Z
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

## Notes

- 2026-09-03T22:40:36Z [claude-code] note: Verified repo against the real submit-plugin.yml template (fetched from omacom/omarchy-plugin-marketplace) before submitting. Found and fixed one real gap: the checklist requires both install AND removal instructions, but README only had install -- added an Uninstall section (omarchy plugin remove <id>) in commit c97d0af, pushed to origin/main along with the task-5nm/task-y14 fixes (commit c97d0af, pushing 3cc97fc..c97d0af). Confirmed repo is public, MIT-licensed, no existing/duplicate submission for this repo in the marketplace's issue tracker (searched by repo name and by author). Submitted via gh issue create (user authenticated gh mid-session): https://github.com/omacom/omarchy-plugin-marketplace/issues/4688 -- category System, tags Bar/Quickshell/System, all 5 checklist boxes checked (all honestly true at submission time). Could not self-apply the 'submission' label -- external contributors lack triage permission on that repo; the marketplace's own automation presumably applies validation labels after its bot runs, based on the pattern seen in other open submissions (validated, needs-fixes, security-review-required, etc). Noted for awareness, not a blocker: two existing closed/listed plugins in the marketplace overlap in scope (oSystemd, Background Services) -- not addressed, just flagged. Leaving task open pending review; still need to follow up until approved/listed per the task's own scope.
