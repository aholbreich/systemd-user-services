Feature: Bar badge reflects failed service count
  As a desktop user glancing at the bar
  I want to see at a glance whether any user service has failed
  So that I don't have to open a terminal to notice a problem

  # The icon/badge/tooltip selection is pure decision logic (given a failed
  # count, what to show) and lives in Model.js as badgeState() specifically
  # so it's testable without Quickshell. Only the QML wiring and live-update
  # behavior below stay manual.

  @automated
  Scenario: No failed services shows a quiet icon
    Given no user services are in a failed state
    Then the bar shows the quiet gear icon with no badge
    And the tooltip reads "User services"

  @automated
  Scenario: One or more failed services shows a warning badge
    Given 2 user services are in a failed state
    Then the bar shows the warning icon with badge "2"
    And the tooltip reads "2 failed user services"

  @automated
  Scenario: Exactly one failed service uses singular tooltip wording
    Given 1 user service is in a failed state
    Then the tooltip reads "1 failed user service"

  @manual
  Scenario: A service failing while the bar is visible updates the badge live
    Given no user services are in a failed state
    When a running user service transitions to failed
    And the next refresh completes
    Then the bar badge updates to reflect the new failed count without a manual reload
