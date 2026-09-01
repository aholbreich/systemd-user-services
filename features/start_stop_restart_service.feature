Feature: Start, stop, and restart a user service from the panel
  As a desktop user
  I want to control a misbehaving service without opening a terminal
  So that I can recover from a failed service in one click

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
