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
    And "omarchy-shell shell rescanPlugins" has been run
    Then a static icon for this plugin appears in the bar
    And no errors related to this plugin appear in "qs log -p $OMARCHY_PATH/shell --tail 100"
