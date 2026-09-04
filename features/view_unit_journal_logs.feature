Feature: View recent journal logs for a unit from the panel
  As a desktop user
  I want to peek at a service's recent log lines without opening a terminal
  So that I can diagnose why it failed without leaving the panel

  # UX: a third icon-only row button ("Logs"), matching the existing
  # Start/Stop/Restart convention -- toggles an inline, read-only log panel
  # below that row rather than opening a separate window. At most one row's
  # logs are expanded at a time, mirroring the single-in-flight-action
  # convention pendingUnit already uses.

  @automated
  Scenario: Empty journal output is shown as a friendly message
    Then the formatted journal output for "" is "No log entries"

  @automated
  Scenario: Journal output is trimmed of surrounding whitespace
    Then the formatted journal output for "  Sep 04 10:00:00 host svc[123]: hello  " is "Sep 04 10:00:00 host svc[123]: hello"

  @automated
  Scenario: The real "journalctl --user -u <unit> -n 20" command shape works against a disposable unit
    Given a disposable "systemctl --user" unit created only for this test
    When I run "systemctl --user restart <unit>"
    Then "journalctl --user -u <unit> -n 20 --no-pager" exits successfully

  @manual
  Scenario: Opening a row's logs
    Given the "sshd" row shows an active service
    When I click "Logs" on the "sshd" row
    Then "journalctl --user -u sshd -n 20 --no-pager" is invoked
    And the last 20 log lines for "sshd" appear below the row

  @manual
  Scenario: Closing logs by clicking the button again
    Given the "sshd" row's logs are open
    When I click "Logs" on the "sshd" row again
    Then the log panel below the "sshd" row disappears

  @manual
  Scenario: Opening a different row's logs closes the previous one
    Given the "sshd" row's logs are open
    When I click "Logs" on the "backup" row
    Then the log panel below the "sshd" row disappears
    And the log panel below the "backup" row appears

  @manual
  Scenario: A unit with no log entries shows a friendly empty message
    Given "journalctl --user -u fresh-unit -n 20 --no-pager" produces no output
    When I click "Logs" on the "fresh-unit" row
    Then the log panel shows "No log entries"

  @manual
  Scenario: A journalctl failure surfaces an error instead of an empty panel
    Given "journalctl --user -u missing -n 20 --no-pager" would fail because the unit does not exist
    When I click "Logs" on the "missing" row
    Then the log panel shows an error naming what went wrong

  @manual
  Scenario: Right-clicking Logs opens the full history in a real terminal
    Given the "sshd" row shows an active service
    When I right-click "Logs" on the "sshd" row
    Then a terminal opens running "journalctl --user -u sshd"
    And the inline log panel does not open
