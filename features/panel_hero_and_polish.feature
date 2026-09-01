Feature: Panel hero header, spacing, and consistent state coloring
  As a desktop user
  I want the panel to look like the rest of Omarchy's own system panels
  So that it feels native, not bolted on

  # Three coordinated polish tasks landing together: task-fn8 (hero title +
  # icon, matching the real network/bluetooth panel convention: big icon +
  # bold title + small-caps live status line), task-x0j (spacing, using the
  # real named Style.spacing.* tokens instead of ad-hoc Style.space(6)
  # everywhere), task-mqw (state color applied consistently to the dot, name,
  # AND state label -- not just dot+label as before). The hero's status text
  # is the only new pure logic; spacing/color are QML-only, verified live.

  @automated
  Scenario: All services healthy shows a calm status line
    Then the hero status for 46 total and 0 failed is "46 services, all healthy" and not urgent

  @automated
  Scenario: One failed service uses singular wording and reads as urgent
    Then the hero status for 46 total and 1 failed is "1 service failed" and urgent

  @automated
  Scenario: Multiple failed services use plural wording and reads as urgent
    Then the hero status for 46 total and 3 failed is "3 services failed" and urgent

  @manual
  Scenario: The hero header shows a big icon, a bold title, and the live status
    Given the panel is open
    Then a large icon appears above the tab row, matching the bar's own icon
    And a bold title reads "Systemd Services"
    And a small caps status line below it shows the live hero status text
    And the status line is colored urgent only when a service is failed

  @manual
  Scenario: Row height and section spacing feel comfortable, not cramped
    Given the panel is open with many services listed
    Then each row is at least as tall as Style.spacing.popupRowHeight
    And there is more visual separation between major sections than between individual rows in the list

  @manual
  Scenario: State color applies consistently across the whole row
    Given a failed service is visible in the list
    Then its status dot, its name, and its state label all use the same urgent color, not just the dot and label
