---
id: task-r3k
title: Fit category tabs into one or two rows
status: done
priority: medium
type: task
created_at: 2026-09-01T20:52:36Z
updated_at: 2026-09-01T20:56:19Z
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
  - features/organize_panel_into_semantic_tabs.feature
  - task-xdw
---

## Description

Follow-up to task-xdw: the 9-tab Flow currently wraps into 4 rows (each button shows 'Label (count)'), which looks busy. Redesign to fit in max 2 rows: drop the inline count from each tab button (label only), move the count to a PanelSectionHeader above the filtered row list instead (matches the real DNS-provider-panel convention: qs.Ui PanelSectionHeader, e.g. 'AUDIO (5)'), and lay tabs out in exactly two Row groups (not an unbounded Flow) so the row count is deterministic regardless of font metrics.

## Notes

- 2026-09-01T20:56:19Z [claude-code] note: Root cause of the busy 4-row look: each tab button carried its own count inline ('Label (count)'), which alone made a single-row-of-9 mathematically impossible (summed label width alone ~400px+ before padding/spacing) and a naive Flow wrap landed on 4 rows. Fix: moved counts out of tab buttons entirely into a PanelSectionHeader above the row list (real qs.Ui component, same one the shipped network panel uses for 'DNS PROVIDER') showing the SELECTED tab's count, e.g. 'AUDIO (5)' -- counts for other tabs are still available via each button's tooltipText. Switched tab buttons to label-only text, and replaced the unbounded Flow with two fixed Row groups (Math.ceil(tabs.length/2) split) so the row count is deterministic (2, always) rather than hoping wrapping lands there -- also switched selection tracking from index-based to key-based (selectedTabKey) since slicing an array into two Repeaters breaks a naive index==Repeater.index comparison. Found and fixed a real bug from my own first attempt at this: with 5 buttons in row 1 (All/Audio/Security/Portals/Session) and the panel still at its old 320-space width, Row (unlike Flow) doesn't wrap -- it just overflows, and the Flickable's clip:true silently cut off 'Session' to 'Se'. Caught via screenshot, not gates (validate+qmllint stayed clean throughout, as expected -- this class of layout bug is invisible to both). Fixed by widening the panel to 420 space units; re-screenshotted to confirm all 9 labels render in full across exactly 2 rows. Live-verified twice more: (1) the widened 2-row layout with all labels visible, (2) temporarily defaulted selectedTabKey to 'audio' to prove the new key-based click mechanism still works after the index->key refactor -- confirmed 'Audio' tab shows selected, header reads 'AUDIO (5)', correct 5 filtered rows with running/inactive coloring intact. Reverted both temporary changes, re-confirmed clean final state (geometry 30x26, zero log warnings).
