import QtQuick
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
    contentWidth: panel.fittedContentWidth(Style.space(280))
    contentHeight: panel.fittedContentHeight(placeholder.implicitHeight, Style.space(200))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()

      Text {
        // Placeholder pending task-rhq (row-by-row list) / task-eva (badge);
        // this story (task-4mm) only needs to prove the service polls and
        // exposes live state, so surface it minimally rather than not at all.
        id: placeholder
        width: parent.width
        text: services.lastError !== ""
          ? "Error: " + services.lastError
          : services.units.length + " user services (" + services.failedCount + " failed)"
        wrapMode: Text.WordWrap
        color: root.barForeground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.body
      }
    }
  }
}
