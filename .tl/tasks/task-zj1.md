---
id: task-zj1
title: Create attractive GitHub repository with README and usage docs
status: done
priority: medium
type: task
created_at: 2026-09-01T20:42:34Z
updated_at: 2026-09-01T21:12:00Z
created_by: claude-code
assignee: null
depends_on: []
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

The plugin has no git remote yet, though it's ready as a repo (manifest.json, LICENSE, README, cucumber features, .tl). Create a public GitHub repository matching the manifest identity (io.github.aholbreich.systemd-user-services, author Alexander Holbreich), push the code, and make it attractive: polish the README with a usage description (what it does, install via omarchy plugin add <url> --enable, config options, screenshots or placeholder captures, scope + roadmap), structured as a proper Omarchy plugin repo per the marketplace publish guide (public repo, valid manifest.json at root, README + license, safe install/removal).

## Notes

- 2026-09-01T21:12:00Z [claude-code] note: Public repo created by the user at git@github.com:aholbreich/systemd-user-services.git, matching the manifest identity io.github.aholbreich.systemd-user-services exactly (repo name = the id's final segment, owner = the id's github-user segment). Before linking/pushing: confirmed with the user on two judgment calls that determine what becomes permanently public (git history) -- removed the superseded spike/ folder, kept .tl/ (candid process notes, nothing sensitive). Fixed a real accuracy problem while polishing: the README claimed Start/Stop/Restart already worked, in both the feature list and Scope section -- it doesn't yet (task-6zg still open); corrected to describe the plugin as view/monitor-only today. Added real grim-captured screenshots (docs/bar-icon.png, docs/panel-tabs.png) and a Configuration section documenting refreshIntervalSec. Mid-task, the user gave an explicit, sharp correction: strip the Co-Authored-By/Claude-Session trailer from every commit and never add it again. Rewrote all 11 commits' messages with git filter-branch --msg-filter (verified via git log --all --format=%B that zero trailer text remained, including deleting the filter-branch backup ref which still held the old trailer'd history, then reflog expire + gc --prune=now), before the first push -- avoided ever force-pushing a history containing it. Saved this as a durable memory so it's not repeated. Remote's own auto-init only had a single trivial 'Initial commit' (LICENSE only) from GitHub's repo-creation flow -- inspected it before overwriting, confirmed it was safe/trivial, renamed local master->main to match GitHub's convention, force-pushed (flagged clearly to the user as a force-push, not silent) over that stub. Filled in the real install URL in the README post-push (was a <this-repo-url> placeholder). Not yet done: gh CLI itself still isn't authenticated (git push used SSH directly, which worked) -- task-b1z (marketplace submission via GitHub issue form) will need gh auth or manual web submission. Repo is live: https://github.com/aholbreich/systemd-user-services
