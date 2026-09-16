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

  @automated
  Scenario: Every command has a hard timeout with a KILL fallback
    Then the list command is wrapped in "/usr/bin/timeout --kill-after=2s 10s"
    And the action command is wrapped in "/usr/bin/timeout --kill-after=2s 30s"
    And the journal command is wrapped in "/usr/bin/timeout --kill-after=2s 10s"

  @automated
  Scenario: A hung command and everything it started are terminated at the deadline
    Given a bounded 1s command that starts a background child and then hangs
    When it runs to completion
    Then it exits with 124 within 3 seconds
    And none of its processes are still alive

  @automated
  Scenario: A command that ignores TERM is killed after the grace period
    Given a bounded 1s command that ignores TERM and hangs
    When it runs to completion
    Then it is killed by KILL within 5 seconds
    And none of its processes are still alive

  @automated
  Scenario: Stopping the process from the shell cleans up the whole tree
    Given a bounded 30s command that starts a background child and then hangs
    When it is started and the launched process gets TERM
    Then it exits within 3 seconds
    And none of its processes are still alive

  @automated
  Scenario: The command doesn't survive if the timeout process is SIGKILLed
    Given a bounded 30s command that hangs in place
    When it is started and the launched process gets KILL
    Then none of its processes are still alive

  @automated
  Scenario: A timeout is reported as a timeout, not as an empty error
    Then the error text for a normal exit 124 with stderr "" is "systemctl list-units failed (timed out after 10s)"
    And the error text for a crash exit 9 with stderr "" is "systemctl list-units failed (timed out after 10s)"
    And the error text for a normal exit 1 with stderr "Unit x not found.\n" is "Unit x not found."
    And the error text for a normal exit 1 with stderr "" is "systemctl list-units failed"

  @automated
  Scenario: Output is capped per stream before it reaches the shell
    Then the list command limits stdout to 1048576 and stderr to 65536 bytes
    And the output limiter runs inside the timeout and outside the real binary

  @automated
  Scenario: Output that fits the limit comes through unchanged
    When a command limited to 10 bytes of stdout and 10 of stderr runs "printf 0123456789"
    Then it exits with 0
    And stdout is "0123456789"

  @automated
  Scenario: One byte over the stdout limit is an error, not silently truncated output
    When a command limited to 10 bytes of stdout and 64 of stderr runs "printf 01234567890"
    Then it exits with 1
    And stdout is exactly 10 bytes
    And stderr is "output exceeded 10 bytes"

  @automated
  Scenario: stderr is capped too
    When a command limited to 64 bytes of stdout and 16 of stderr runs "yes error >&2"
    Then stderr is at most 16 bytes
    And it finished within 2 seconds

  @automated
  Scenario: A command that floods stdout is stopped instead of buffered
    When a command limited to 64 bytes of stdout and 64 of stderr runs "yes"
    Then it exits with 1
    And stdout is exactly 64 bytes
    And it finished within 2 seconds

  @automated
  Scenario: The command's own exit status and stderr still come through
    When a command limited to 64 bytes of stdout and 64 of stderr runs "echo 'Unit x.service not found.' >&2; exit 5"
    Then it exits with 5
    And stderr is "Unit x.service not found."
