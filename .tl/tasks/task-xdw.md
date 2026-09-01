---
id: task-xdw
title: Organize the service panel into semantic tabs (with research)
status: done
priority: medium
type: task
created_at: 2026-09-01T20:17:32Z
updated_at: 2026-09-01T20:49:01Z
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
  - ux
references:
  - features/organize_panel_into_semantic_tabs.feature
---

## Description

Research typical systemd --user services and common conventions to derive a useful semantic tab set (e.g. by purpose: media, network, sync, dev, utilities, or similar). Document the chosen groupings and the rationale — the research is part of this task. Then add a tabbed interface to the service panel (Panel.qml), each tab populated from the classified unit list (Model.js), with per-tab counts and empty states, preserving state indicators and failed-first ordering.

## Notes

- 2026-09-01T20:49:01Z [claude-code] note: Grilled the user first (real, non-rhetorical questions): no Tabs/TabBar component exists anywhere in the shell, and the task's example categories (media/network/sync/dev/utilities) don't fit this machine's real 46-unit census. User pointed me at two real shipped examples instead of letting me guess styling: the Network panel's DNS-provider pill row and the Agents panel's Claude Code/Codex provider switch. Both turned out to use the SAME real shared qs.Ui Button component (active/selected + bordered props), not stock QtQuick.Controls and not hand-rolled -- grepped both from the real installed shell source (/usr/share/omarchy/shell/plugins/panels/network/Panel.qml, .../agents/Panel.qml) rather than guessing, learning from the Color/Style token bugs in task-rhq. User then confirmed: real-data-grounded category taxonomy, and include an All tab (noted they may add filters as a separate dimension later -- kept categorization and any future filter concept structurally separate, didn't conflate them). Research (task's own explicit deliverable): derived 7 categories + Other from this machine's real systemctl --user census (documented in README's new 'Category taxonomy' section with the full keyword table and rationale). Cross-checked against real data: only 4/46 units (~9%) land in Other, so the taxonomy has real coverage, not just theoretical. Test-first: Model.js gets categorize(unit)/categoryLabel(key)/groupUnitsByCategory(units)/CATEGORY_KEYS. Wrote a Scenario Outline (20 examples, one per real unit->category mapping) plus 2 more automated scenarios (fixed-tab-set-even-at-zero, failed-first order preserved within a tab-filtered subset) -- all red (functions undefined) before implementing, all green after (37/37 total suite). Panel.qml: added a Flow (not the DNS pills' fixed-width Row -- 9 tabs vs their 2-4 would be illegibly narrow) of Repeater-generated Button{selected,bordered} tab pills above the existing row list, filtering the existing Repeater to root.currentTab.units instead of services.units. Reused the already-shipped Flickable/scroll fix from task-687 untouched. Live-verified thoroughly, having learned from two prior bugs: static gates clean AND restart+log-scan clean (zero runtime warnings) AND visual screenshot on the real 46-unit system -- tab counts exactly matched a separate CLI cross-check (Audio 5, Security 8, Portals 10, Session 5, Filesystem 4, Omarchy 6, System 4, Other 4, All 46). Went further than previous stories: temporarily changed the default selectedTabIndex (0->1) to prove tab-switching filtering actually works live (not just that the bar renders), confirmed the Audio tab shows exactly its 5 units with correct running/inactive color distinction preserved, then reverted the temp change and re-verified clean final state. Noticed and flagging for the user (not acted on): a SECOND concurrent agent session is active in this exact repo right now (visible via the 'pi' tool's sidebar as 'oma-systemd 2', separate from my own 'oma-systemd claude' session), creating its own tl tasks (zj1, b1z for GitHub repo + marketplace publishing; observed it about to create an 'Architecture review' task) using the same --actor claude-code I use. No file conflicts observed with my work, but worth the user's awareness for ledger/attribution clarity.
