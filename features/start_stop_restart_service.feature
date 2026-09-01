Feature: Start, stop, and restart a user service from the panel
  As a desktop user
  I want to control a misbehaving service without opening a terminal
  So that I can recover from a failed service in one click

  # UX: one compact icon toggle button (Start/Stop, whichever applies to the
  # unit's current state) plus one always-available Restart button per row,
  # both icon-only with a tooltip (Button's real tooltipText) rather than
  # full text labels -- keeps 46 rows scannable. Which verb the toggle
  # represents, and how an action-failure message reads, are pure decisions
  # worth testing without Quickshell.

  @automated
  Scenario Outline: The toggle button represents Start or Stop based on current state
    Given a unit with active state "<state>"
    Then its toggle action is "<verb>" labelled "<label>"

    Examples:
      | state    | verb  | label |
      | active   | stop  | Stop  |
      | failed   | start | Start |
      | inactive | start | Start |

  @automated
  Scenario: An action failure message names the unit and the action
    Then the action error for "stop" on "backup" with detail "Unit not loaded." is "stop backup failed: Unit not loaded."

  @automated
  Scenario: An action failure message is still readable with no detail text
    Then the action error for "start" on "missing" with detail "" is "start missing failed"

  @automated
  Scenario: The exact start/stop/restart command shapes work against a real disposable unit
    Given a disposable "systemctl --user" unit created only for this test
    When I run "systemctl --user stop <unit>"
    Then the unit's active state becomes "inactive"
    When I run "systemctl --user start <unit>"
    Then the unit's active state becomes "active"
    When I run "systemctl --user restart <unit>"
    Then the unit's active state becomes "active"
    And its start timestamp changes

  @manual
  Scenario: Stopping a running service via its row button
    Given the "sshd" row shows an active service
    When I click "Stop" on the "sshd" row
    Then "systemctl --user stop sshd" is invoked
    And the row updates to show it is no longer active after the next refresh

  @manual
  Scenario: Starting a stopped service via its row button
    Given the "sshd" row shows an inactive service
    When I click "Start" on the "sshd" row
    Then "systemctl --user start sshd" is invoked
    And the row updates to show it is active after the next refresh

  @manual
  Scenario: Restarting a failed service via its row button
    Given the "backup" row shows a failed service
    When I click "Restart" on the "backup" row
    Then "systemctl --user restart backup" is invoked
    And the row updates after the next refresh

  @manual
  Scenario: Buttons are disabled while an action is in flight for that row
    Given I have just clicked "Restart" on the "backup" row
    And the restart has not yet completed
    Then the "backup" row's action buttons are disabled
    And clicking them again has no effect

  @manual
  Scenario: A failed action surfaces an error instead of failing silently
    Given "systemctl --user start missing.service" would fail because the unit does not exist
    When I click "Start" on that row
    Then an error message naming the unit and the action is shown
    # Bug found live (task-6zg): the delayedRefresh 400ms after every action
    # unconditionally cleared lastError on its next successful poll, so the
    # message flashed for well under half a second -- effectively invisible.
    # Action errors are now tracked separately (lastActionError) from list-
    # poll errors (lastError) and auto-clear on their own ~6s timer instead.
    And the error message is still visible several seconds later, not cleared by the very next background refresh
