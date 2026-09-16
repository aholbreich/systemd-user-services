Feature: See and toggle whether a user service starts at login
  As a desktop user
  I want to see which of my services start automatically and switch that per service
  So that I can stop something from coming back every session, or make it come back

  # For a --user unit "enabled" means pulled in when the user session starts
  # (login), not at machine boot -- that would additionally need lingering.
  # Only "enabled" and "disabled" can be switched with enable/disable; the
  # other states are started some other way, so they get an explanation,
  # not a button. Enabling doesn't start the unit (no --now): running state
  # stays with Start/Stop.

  @automated
  Scenario: Unit file states are read from list-unit-files JSON
    Given the raw list-unit-files JSON:
      """
      [{"unit_file":"pipewire.service","state":"enabled","preset":"enabled"},
       {"unit_file":"dconf.service","state":"static","preset":null},
       {"unit_file":"wayland-session-bindpid@.service","state":"static","preset":null}]
      """
    When the unit files are parsed
    Then parsing the unit files succeeds
    And the enablement state of "pipewire.service" is "enabled"
    And the enablement state of "dconf.service" is "static"

  @automated
  Scenario: An instance unit takes its enablement from its template
    Given the raw list-unit-files JSON:
      """
      [{"unit_file":"wayland-session-bindpid@.service","state":"static","preset":null}]
      """
    When the unit files are parsed
    Then the enablement state of "wayland-session-bindpid@1102.service" is "static"

  @automated
  Scenario: A unit without a unit file has no enablement state
    Given the raw list-unit-files JSON:
      """
      []
      """
    When the unit files are parsed
    Then the enablement state of "gone.service" is ""

  @automated
  Scenario: Broken list-unit-files output is an error, not an empty map
    Given the raw list-unit-files JSON:
      """
      { not json
      """
    When the unit files are parsed
    Then parsing the unit files fails

  @automated
  Scenario: Installed services that systemd has unloaded are still listed
    Given the raw list-unit-files JSON:
      """
      [{"unit_file":"loaded.service","state":"enabled","preset":null},
       {"unit_file":"ibgateway.service","state":"disabled","preset":null},
       {"unit_file":"hyprsunset.service","state":"enabled","preset":null},
       {"unit_file":"dconf.service","state":"static","preset":null},
       {"unit_file":"wireplumber@.service","state":"disabled","preset":null}]
      """
    When the unit files are parsed
    And they are merged with the loaded unit "loaded.service" in state "active"
    Then the merged list is "loaded, hyprsunset, ibgateway"
    And "ibgateway.service" is listed as "inactive (dead)"

  @automated
  Scenario: Disabling a stopped service keeps it in the plugin's list
    Given a disposable unit with an [Install] section wanted by "default.target"
    When the plugin runs "enable" on it
    And the plugin runs "disable" on it
    Then the plugin's merged unit list still contains it

  @automated
  Scenario Outline: Only enabled and disabled units get a toggle
    Then the autostart action for state "<state>" is toggleable "<toggleable>" with verb "<verb>" and on "<on>"

    Examples:
      | state     | toggleable | verb    | on    |
      | enabled   | yes        | disable | yes   |
      | disabled  | yes        | enable  | no    |
      | static    | no         |         | no    |
      | generated | no         |         | no    |
      | transient | no         |         | no    |
      | masked    | no         |         | no    |
      |           | no         |         | no    |

  @automated
  Scenario: Non-toggleable states explain themselves
    Then the autostart label for state "static" is "No autostart setting: started by another unit, socket or D-Bus"
    And the autostart label for state "" is "Autostart state unknown"
    And the autostart label for state "something-new" is "Autostart: something-new"

  @automated
  Scenario: The real list-unit-files output on this machine parses
    When the plugin's list-unit-files command runs on this machine
    Then parsing the unit files succeeds
    And at least one unit file has state "enabled" or "disabled"

  @automated
  Scenario: Enable and disable change autostart but not the running state
    Given a disposable unit with an [Install] section wanted by "default.target"
    When the plugin runs "enable" on it
    Then its enablement state becomes "enabled"
    And it is still "inactive"
    When the plugin runs "disable" on it
    Then its enablement state becomes "disabled"

  @manual
  Scenario: The autostart button reflects and flips the state
    Given the "pipewire-pulse" row shows an enabled unit
    Then its power button is highlighted with tooltip "Starts at login · click to disable"
    When I click the power button
    Then the tooltip reads "Disabling…" until the command finishes
    And after the refresh the button is no longer highlighted
    And the service is still running

  @manual
  Scenario: Units without an autostart setting show a muted dot
    Given the "dconf" row shows a static unit
    Then its autostart slot shows a muted "·" with tooltip "No autostart setting: started by another unit, socket or D-Bus"
    And clicking it does nothing
