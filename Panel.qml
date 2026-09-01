import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "io.github.aholbreich.systemd-user-services"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Service {
    id: services
    settings: root.settings
  }

  readonly property var badge: Model.badgeState(services.failedCount)
  readonly property var tabs: Model.groupUnitsByCategory(services.units)
  property int selectedTabIndex: 0
  readonly property var currentTab: tabs[Math.min(selectedTabIndex, tabs.length - 1)]

  function rowColor(unit) {
    if (Model.isFailed(unit)) return Color.urgent
    if (Model.isRunning(unit)) return Color.foreground
    return Color.muted
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.badge.icon + (root.badge.badge !== "" ? " " + root.badge.badge : "")
    tooltipText: root.badge.tooltip
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(320))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(400))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()

      // Bug (task-687): an unclipped Column let long service lists overflow
      // the panel's fitted height instead of being contained. Wrapping the
      // whole Column in a Flickable mirrors the shipped tailscale/bluetooth
      // panels' own pattern for long lists.
      Flickable {
        id: panelFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: column
          width: panelFlick.width
          spacing: Style.space(6)

          Text {
            width: parent.width
            visible: services.lastError !== ""
            text: "Error: " + services.lastError
            wrapMode: Text.WordWrap
            color: Color.urgent
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.bodySmall
          }

          // Fixed tab set (task-xdw): same key set every time, even at 0,
          // so the row doesn't reflow as services start/stop. Flow (not a
          // fixed-width Row like the DNS-provider pills) because there are
          // 9 tabs here vs. the shipped examples' 2-4 -- they'd be
          // illegibly narrow forced into one even-width row.
          Flow {
            width: parent.width
            spacing: Style.space(6)

            Repeater {
              model: root.tabs

              Button {
                required property var modelData
                required property int index

                text: modelData.label + " (" + modelData.count + ")"
                selected: index === root.selectedTabIndex
                bordered: true
                foreground: root.barForeground
                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                fontSize: Style.font.bodySmall
                verticalPadding: Style.spacing.controlPaddingY
                onClicked: root.selectedTabIndex = index
              }
            }
          }

          Text {
            width: parent.width
            visible: services.lastError === "" && root.currentTab.units.length === 0
            text: root.currentTab.key === "all" ? "No user services found" : "No services in " + root.currentTab.label
            color: Color.muted
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.bodySmall
          }

          Repeater {
            model: root.currentTab.units

            delegate: Item {
              width: column.width
              height: Math.max(dot.height, nameText.implicitHeight, stateText.implicitHeight) + Style.space(4)

              Rectangle {
                id: dot
                width: Style.space(6)
                height: Style.space(6)
                radius: width / 2
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: root.rowColor(modelData)
              }

              Text {
                id: stateText
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Model.stateLabel(modelData)
                color: root.rowColor(modelData)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.bodySmall
              }

              Text {
                id: nameText
                anchors.left: dot.right
                anchors.leftMargin: Style.space(6)
                anchors.right: stateText.left
                anchors.rightMargin: Style.space(6)
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: modelData.shortName
                color: root.barForeground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.body
              }
            }
          }
        }
      }
    }
  }
}
