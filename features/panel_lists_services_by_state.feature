Feature: Panel lists user services grouped by state
  As a desktop user
  I want to click the bar icon and see all my user services at a glance
  So that I can assess session health without a terminal

  # Row order is inherited from Model.sortUnits, already covered by
  # list_and_classify_user_services.feature -- not re-tested here.
  # Row-label text formatting IS new logic (see the @automated scenarios
  # below); the indicator color and actual click/open/close behavior stay
  # manual since they only exist once QML is rendered.

  @manual
  Scenario: Clicking the bar icon opens the panel
    When I left-click the bar icon
    Then the panel opens anchored under the icon

  @manual
  Scenario: Clicking again closes the panel
    Given the panel is open
    When I left-click the bar icon
    Then the panel closes

  @manual
  Scenario: Services are listed failed-first, then running, then the rest
    Given the session has a failed service "backup", a running service "sshd", and an inactive service "one-shot"
    When I open the panel
    Then the row order is "backup, sshd, one-shot"

  @manual
  Scenario: Each row shows a state indicator and a human-readable state label
    Given the session has a failed service "backup"
    When I open the panel
    Then the "backup" row shows a failed-color indicator
    And the row's state label includes "failed"

  @automated
  Scenario: A unit whose sub-state duplicates its active state is not shown redundantly
    Given a unit with active state "failed" and sub state "failed"
    Then its row label is "failed"

  @automated
  Scenario: A unit whose sub-state adds information shows both
    Given a unit with active state "active" and sub state "running"
    Then its row label is "active (running)"

  @manual
  Scenario: An empty session shows an explicit empty state, not a blank panel
    Given the session has no user services
    When I open the panel
    Then the panel shows "No user services found"

  @manual
  Scenario: A systemctl error is shown instead of silently showing stale/empty data
    Given the last refresh failed with an error
    When I open the panel
    Then the panel shows the error message

  @manual
  Scenario: A long service list stays inside the panel and scrolls instead of overflowing
    # Bug (task-687): the row Column had no clip/Flickable, so on a session
    # with many units the rows spilled past the panel's fitted height instead
    # of being contained. Fixed by wrapping the whole Column in a Flickable
    # (clip: true, ScrollBar.vertical AsNeeded), mirroring the shipped
    # tailscale/bluetooth panels' own long-list pattern exactly.
    Given the session has more user services than fit in the panel's capped height
    When I open the panel
    Then all rows stay within the panel's visible bounds
    And the list is scrollable to reach the rows below the fold
