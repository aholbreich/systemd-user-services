Feature: Launch systemctl and journalctl without trusting the shell's environment
  As a user running third-party code inside my desktop shell
  I want the plugin to run only the packaged systemctl/journalctl binaries
  So that whatever happens to be on PATH can't run in their place

  @automated
  Scenario: Every command runs a pinned binary with a rebuilt environment
    Then the list, action and journal commands all start with "/usr/bin/env -i"
    And the list command runs "/usr/bin/systemctl"
    And the action command runs "/usr/bin/systemctl"
    And the journal command runs "/usr/bin/journalctl"

  @automated
  Scenario: Only the session runtime dir and bus address are passed through
    Given a session environment with XDG_RUNTIME_DIR, DBUS_SESSION_BUS_ADDRESS and LD_PRELOAD set
    Then the child environment is exactly PATH, LANG, XDG_RUNTIME_DIR and DBUS_SESSION_BUS_ADDRESS

  @automated
  Scenario: A fake systemctl earlier on PATH is never executed
    Given a fake "systemctl" that leaves a marker file, placed first on PATH
    When the list command runs with that PATH
    Then it succeeds with real systemctl JSON output
    And the fake "systemctl" never ran
