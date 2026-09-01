@manual
Feature: Plugin scaffold validates and loads
  As a plugin developer
  I want the minimal plugin skeleton to pass Omarchy's own validators and appear in the bar
  So that every later story builds on a foundation the shell actually accepts

  Background:
    Given a manifest.json declaring kind "bar-widget" with entry point "Panel.qml"
    And a minimal Panel.qml that renders a static icon and no data yet

  Scenario: Manifest and QML pass static validation
    When I run "omarchy plugin validate <plugin-folder>"
    Then the command exits 0 with no schema errors
    When I run "qmllint -I $OMARCHY_PATH/shell Panel.qml"
    Then qmllint reports no errors

  Scenario: The plugin loads into the live bar
    Given the plugin is enabled via "omarchy plugin enable io.github.aholbreich.systemd-user-services"
    And "omarchy-restart-shell" has been run to force a fresh compile
    Then no errors related to this plugin appear in "qs log -p $OMARCHY_PATH/shell --tail 100"
    And "omarchy-shell shell debugBarGeometry" reports width > 0 and height > 0 for this plugin's id
    And a screenshot (grim) shows a visible icon in the bar's right section
    # A clean log and "enabled: true" are NOT sufficient proof of visibility:
    # a widget with no implicitWidth/implicitHeight mounts silently at 0x0.
    # This bit us for real during task-zw9 — verify geometry and pixels, not just logs.
