Feature: Service polls systemctl and exposes live unit state
  As the plugin's background service
  I want to periodically refresh the unit list from real systemctl output
  So that the bar and panel always reflect the current session state

  @automated
  Scenario: Real systemctl --user output matches the shape Model.js expects
    Given the real output of "systemctl --user list-units --type=service --all --output=json" on this machine
    When the units are parsed
    Then parsing succeeds
    And every parsed unit has a name, a short name, an active state, and a sub state

  @manual
  Scenario: The service refreshes on a timer without user interaction
    Given the plugin is enabled with "refreshIntervalSec" set to 5
    When 6 seconds pass with no clicks
    Then the exposed unit list has been refreshed at least once
    And no duplicate or overlapping "systemctl list-units" processes are left running

  @manual
  Scenario: A hung systemctl call does not permanently freeze the badge
    Given a refresh is in flight
    When that refresh process does not exit within the watchdog window
    Then the watchdog kills the stuck process
    And the next scheduled refresh still runs
