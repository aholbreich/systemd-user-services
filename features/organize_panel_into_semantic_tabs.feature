Feature: Organize the service panel into semantic tabs
  As a desktop user with many systemd --user services
  I want them grouped into a small set of meaningful tabs
  So that I can scan a category instead of one long flat list

  # systemd carries no semantic category metadata, so this taxonomy is a
  # hand-curated keyword lookup against each unit's short name -- grounded
  # in the real unit census on this machine (see README's "Category
  # taxonomy" section for the full rationale and keyword table), not the
  # generic media/network/sync/dev/utilities examples from the original
  # task description, which don't fit what actually runs on an Omarchy
  # desktop (no sync agents, barely any network services, no dev tools).
  #
  # Tabs are a FIXED set (All + every category, even ones currently at 0),
  # so the tab row doesn't jump around as services start/stop -- each shows
  # its own empty state rather than disappearing.

  @automated
  Scenario Outline: A unit is categorized by keyword match against its short name
    Given a unit named "<unit>"
    Then it is categorized as "<category>"

    Examples:
      | unit                                          | category   |
      | pipewire.service                               | audio      |
      | wireplumber.service                             | audio      |
      | pulseaudio.service                              | audio      |
      | gnome-keyring-daemon.service                    | security   |
      | gpg-agent.service                                | security   |
      | bt-agent.service                                 | security   |
      | xdg-desktop-portal.service                       | portals    |
      | xdg-desktop-portal-hyprland.service              | portals    |
      | at-spi-dbus-bus.service                          | portals    |
      | dbus-broker.service                              | portals    |
      | dconf.service                                    | portals    |
      | wayland-wm@hyprland.desktop.service              | session    |
      | wayland-session-waitenv.service                  | session    |
      | gvfs-daemon.service                              | filesystem |
      | gvfs-udisks2-volume-monitor.service              | filesystem |
      | omarchy-sleep-lock.service                        | omarchy    |
      | omarchy-crash-watch.service                       | omarchy    |
      | systemd-oomd.service                             | system     |
      | ibgateway.service                                | other      |
      | voxtype.service                                  | other      |

  @automated
  Scenario: Every fixed category is represented with a count, even at zero
    Given a session with 2 audio services and 0 services in every other category
    When the units are grouped into tabs
    Then the "audio" tab count is 2
    And the "security" tab count is 0
    And every fixed category key is present in the tab list

  @automated
  Scenario: Filtering by category preserves the existing failed-first order
    Given a failed audio service "pipewire", a running audio service "wireplumber", and a failed security service "gpg-agent"
    When the units are grouped into tabs
    Then the "audio" tab's units in order are "pipewire, wireplumber"

  @manual
  Scenario: Clicking a tab shows only that category's services
    Given the panel is open on the "All" tab
    When I click the "Audio" tab
    Then only audio-category rows are shown
    And the "Audio" tab button is visually selected

  @manual
  Scenario: The All tab always shows every service unfiltered
    Given some services are miscategorized or unknown
    When I click the "All" tab
    Then every service is visible regardless of category

  @manual
  Scenario: An empty category shows its own empty state
    Given the "security" tab has 0 services
    When I click the "security" tab
    Then the panel shows an empty-state message for that category
