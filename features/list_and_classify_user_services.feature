#Implemented 
@automated
Feature: List and classify systemd --user services
  As someone monitoring their session's services
  I want systemctl's unit list turned into a sorted, classified model
  So that failed units are always surfaced first, deterministically

  Background:
    Given the raw JSON output of "systemctl --user list-units --type=service --all --output=json"

  Scenario: A healthy service is classified as running
    Given a unit "sshd.service" with active state "active" and sub state "running"
    When the units are parsed
    Then the unit "sshd" is classified as running
    And it is not classified as failed

  Scenario: A crashed service is classified as failed
    Given a unit "backup.service" with active state "failed" and sub state "failed"
    When the units are parsed
    Then the unit "backup" is classified as failed

  Scenario: An inactive service is classified as neither running nor failed
    Given a unit "one-shot.service" with active state "inactive" and sub state "dead"
    When the units are parsed
    Then the unit "one-shot" is classified as inactive

  Scenario: Failed units sort before running units, which sort before the rest
    Given a unit "zzz-ok.service" with active state "active" and sub state "running"
    And a unit "aaa-broken.service" with active state "failed" and sub state "failed"
    And a unit "mmm-idle.service" with active state "inactive" and sub state "dead"
    When the units are parsed
    Then the sorted unit order is "aaa-broken, zzz-ok, mmm-idle"

  Scenario: Units in the same state sort alphabetically by short name
    Given a unit "bravo.service" with active state "failed" and sub state "failed"
    And a unit "alpha.service" with active state "failed" and sub state "failed"
    When the units are parsed
    Then the sorted unit order is "alpha, bravo"

  Scenario: The failed count matches only failed units
    Given a unit "a.service" with active state "failed" and sub state "failed"
    And a unit "b.service" with active state "failed" and sub state "failed"
    And a unit "c.service" with active state "active" and sub state "running"
    When the units are parsed
    Then the failed count is 2

  Scenario: The ".service" suffix is stripped for display
    Given a unit "sshd.service" with active state "active" and sub state "running"
    When the units are parsed
    Then the unit "sshd" has short name "sshd"

  Scenario: Empty output parses to an empty, non-failing list
    Given no units are listed
    When the units are parsed
    Then parsing succeeds
    And the failed count is 0

  Scenario: Malformed JSON is reported as a parse error, not a crash
    Given the raw output is not valid JSON
    When the units are parsed
    Then parsing fails with an error message
