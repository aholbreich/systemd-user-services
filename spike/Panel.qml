import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "io.github.aholbreich.systemd-user-services"

  readonly property var units: services.units
  readonly property int failedCount: services.failedCount
  readonly property string lastError: services.lastError

  readonly property string icon: failedCount > 0 ? "⚠" : "⚙"
  readonly property color iconColor: failedCount > 0
    ? Color.error
    : Qt.darker(root.barForeground, 1.4)

  function stateColor(unit) {
    if (Model.isFailed(unit)) return Color.error
    if (Model.isRunning(unit)) return Color.success
    return Qt.darker(root.barForeground, 1.4)
  }

  function stateLabel(unit) {
    return unit.subState ? unit.activeState + " (" + unit.subState + ")" : unit.activeState
  }

  Service {
    id: services
    settings: root.settings
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.icon + (root.failedCount > 0 ? " " + root.failedCount : "")
    tooltipText: root.failedCount > 0
      ? root.failedCount + " failed user service" + (root.failedCount === 1 ? "" : "s")
      : "User services"
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
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(480))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()

      Column {
        id: column
        width: parent.width
        spacing: Style.space(6)

        Text {
          width: parent.width
          visible: root.lastError !== ""
          text: root.lastError
          color: Color.error
          wrapMode: Text.WordWrap
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.small
        }

        Text {
          width: parent.width
          visible: root.units.length === 0 && root.lastError === ""
          text: "No user services found"
          color: Qt.darker(root.barForeground, 1.4)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.small
        }

        Repeater {
          model: root.units

          delegate: RowLayout {
            width: column.width
            spacing: Style.space(8)

            Rectangle {
              Layout.preferredWidth: Style.space(6)
              Layout.preferredHeight: Style.space(6)
              radius: width / 2
              color: root.stateColor(modelData)
            }

            Text {
              Layout.fillWidth: true
              text: modelData.shortName
              elide: Text.ElideRight
              color: root.barForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.body
            }

            Text {
              text: root.stateLabel(modelData)
              color: root.stateColor(modelData)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.small
            }

            Button {
              text: Model.isRunning(modelData) ? "Stop" : "Start"
              enabled: services.pendingUnit !== modelData.name
              onClicked: Model.isRunning(modelData)
                ? services.stopUnit(modelData.name)
                : services.startUnit(modelData.name)
            }

            Button {
              text: "Restart"
              enabled: services.pendingUnit !== modelData.name
              onClicked: services.restartUnit(modelData.name)
            }
          }
        }
      }
    }
  }
}
