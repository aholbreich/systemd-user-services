@manual
Feature: Panel lists user services grouped by state
  As a desktop user
  I want to click the bar icon and see all my user services at a glance
  So that I can assess session health without a terminal

  Scenario: Clicking the bar icon opens the panel
    When I left-click the bar icon
    Then the panel opens anchored under the icon

  Scenario: Clicking again closes the panel
    Given the panel is open
    When I left-click the bar icon
    Then the panel closes

  Scenario: Services are listed failed-first, then running, then the rest
    Given the session has a failed service "backup", a running service "sshd", and an inactive service "one-shot"
    When I open the panel
    Then the row order is "backup, sshd, one-shot"

  Scenario: Each row shows a state indicator and a human-readable state label
    Given the session has a failed service "backup"
    When I open the panel
    Then the "backup" row shows a failed-color indicator
    And the row's state label includes "failed"

  Scenario: An empty session shows an explicit empty state, not a blank panel
    Given the session has no user services
    When I open the panel
    Then the panel shows "No user services found"

  Scenario: A systemctl error is shown instead of silently showing stale/empty data
    Given the last refresh failed with an error
    When I open the panel
    Then the panel shows the error message
