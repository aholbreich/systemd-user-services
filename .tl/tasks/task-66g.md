---
id: task-66g
title: 'Senior engineer review: test coverage and alignment with specification'
status: done
priority: medium
type: task
created_at: 2026-09-01T20:49:20Z
updated_at: 2026-09-03T22:57:38Z
created_by: claude-code
assignee: null
depends_on: []
claim:
  actor: null
  claimed_at: null
  expires_at: null
  heartbeat_at: null
tags:
  - testing
  - spec
references:
  - features
  - cucumber.js
---

## Description

Review the test suite as a senior engineer. Assess coverage and alignment with the specification: do the cucumber feature files (features/*.feature) fully specify and cover the intended behavior (list/classify, polling, panel rendering, bar badge, start/stop/restart, plugin scaffold, semantic tabs)? Check for gaps (untested behaviors, missing scenarios, edge cases), dead or redundant specs, specs that drift from the implemented behavior, and step definitions that don't match the spec intent. Deliverable: a written review with prioritized findings and concrete fixes — implement missing tests and spec corrections directly, file follow-up tasks for anything larger.

## Notes

- 2026-09-03T22:57:35Z [claude-code] note: Reviewed all 7 feature files + step definitions against Model.js/Service.qml/Panel.qml. Read all 46-then-50 scenarios in full, not just the passing test count. FINDINGS (fixed directly): 1. [HIGH] Spec drift: panel_lists_services_by_state.feature's 'A long service list stays inside the panel and scrolls' scenario (@manual) still described the OLD whole-column-Flickable-capped-at-400 implementation from task-687, which task-5nm (this session, earlier) found was itself the root cause of a real regression (hero header eating the row list's height budget) and replaced with a bluetooth-style pattern (hero/tabs unscrolled, only the row list is a height-capped ListView). Updated the scenario text and comment to describe the current implementation and cite task-5nm. 2. [HIGH] Tautological test: organize_panel_into_semantic_tabs.feature's 'Filtering by category preserves the existing failed-first order' scenario fed groupUnitsByCategory a hand-ordered fixture (units already constructed in failed-first order) instead of running them through Model.sortUnits first, so it only proved grouping preserves whatever order it's given -- true by inspection, and would still pass even if the real sortUnits->groupUnitsByCategory integration were broken. Fixed by constructing the fixture out of order and routing it through the real Model.sortUnits (mirrors what Model.parseUnits does internally, same as Service.qml's actual pipeline). Verified this has teeth: temporarily bypassed the sortUnits call and confirmed the scenario fails with a clear diff, then restored it. 3. [MEDIUM] Fragile step: list_and_classify_user_services.steps.js's 'it is not classified as failed' step read this.result.units[length-1] (the LAST sorted unit) instead of looking up the named unit like every sibling step does -- worked only because that scenario happens to define exactly one unit. Parameterized the Gherkin step and step definition to look up by short name via the existing findUnit helper, matching the pattern used everywhere else in the file. 4. [MEDIUM] Coverage gap: 4 of CATEGORY_DEFINITIONS' keywords (security: dirmngr, keyboxd, p11-kit; portals: the bare 'dbus-:' prefix, distinct from 'dbus-broker') had zero test coverage in the Scenario Outline, despite the file's own README-documented convention that every taxonomy addition gets a row. Added the 4 missing Examples rows using real unit names from this machine's actual census. FILED AS FOLLOW-UP (task-o1l, low priority): categorize()'s own comment says 'first keyword match wins, most-specific categories first' but no scenario exercises that precedence with a name that could match two categories -- no real unit on a live census collides today, so this is latent-behavior coverage, not a live bug. NOTED, not actioned (both low-risk, no code change warranted): (a) service_polls_and_exposes_units.feature's 'real systemctl output' scenario shells out to the live machine and would throw rather than cleanly fail in an environment with no user systemd session (e.g. some CI containers) -- acceptable given this plugin's context always assumes a running Omarchy session, and the project's own testing strategy already documents running against the real machine. (b) Model.js's parsed-but-unused 'load' and 'description' fields are intentionally deferred to already-filed tasks (task-pyx's own notes, task-les) -- not a gap in THIS review's scope. Everything else checked out: no undefined/ambiguous steps (cucumber-js already resolves all 50 scenarios cleanly), no dead step definitions after the fixes above, @manual/@automated split is applied correctly and consistently (cucumber.js filters to @automated only, confirmed by reading the config), polling/watchdog logic is correctly left @manual (inherently Timer/Process-based, no extractable pure logic, consistent with the project's own documented testing strategy). Final: 50 scenarios / 134 steps, all passing; validate + qmllint both exit 0 (unaffected, no QML touched).
