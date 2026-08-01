import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.Noctalia
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null

  readonly property var geometryPlaceholder: panelContainer

  property var panelScreen: pluginApi?.panelOpenScreen
  property real contentPreferredHeight: panelScreen ? Math.round(panelScreen.height * 0.95) : Math.round(700 * Style.uiScaleRatio)
  property real contentPreferredWidth: Math.round(contentPreferredHeight * 16 / 9)

  readonly property bool allowAttach: true

  anchors.fill: parent

  // Shared selection state
  property string selectedPluginId: ""

  // ── Auto-select first plugin of the active tab ──
  function _isInstalledSelection(id) {
    if (!id) return false
    var ids = PluginRegistry.getAllInstalledPluginIds() || []
    for (var i = 0; i < ids.length; i++) {
      if (ids[i] === id) return true
    }
    return false
  }

  function _autoSelectForTab(idx) {
    if (_isInstalledSelection(root.selectedPluginId)) return
    var ids = PluginRegistry.getAllInstalledPluginIds() || []
    if (ids.length > 0) {
      root.selectedPluginId = ids[0]
    }
  }

  Component.onCompleted: Qt.callLater(function () { root._autoSelectForTab(subTabBar.currentIndex) })

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    RowLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: 0

      // ── Left column: plugin list ──
      Item {
        Layout.preferredWidth: Math.round(360 * Style.uiScaleRatio)
        Layout.maximumWidth: Math.round(360 * Style.uiScaleRatio)
        Layout.fillHeight: true

        ColumnLayout {
          anchors.fill: parent
          spacing: 0

          NTabBar {
            id: subTabBar
            Layout.fillWidth: true
            Layout.bottomMargin: Style.marginM
            distributeEvenly: true
            currentIndex: 0
            onCurrentIndexChanged: root._autoSelectForTab(currentIndex)

            NTabButton {
              text: pluginApi?.tr("panel.tab-installed")
              tabIndex: 0
              checked: subTabBar.currentIndex === 0
            }
          }

          StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: subTabBar.currentIndex

            // ── Installed tab ──
            NScrollView {
              id: installedScrollView
              horizontalPolicy: ScrollBar.AlwaysOff
              gradientColor: Color.mSurface

              Item {
                width: installedScrollView.availableWidth
                implicitWidth: installedScrollView.availableWidth
                implicitHeight: installedContent.implicitHeight

                InstalledTabContent {
                  id: installedContent
                  width: parent.width
                  pluginApi: root.pluginApi
                  selectedPluginId: root.selectedPluginId
                  onPluginSelected: id => {
                    root.selectedPluginId = id
                  }
                }
              }
            }

          }
        }
      }

      // Vertical divider
      NDivider {
        vertical: true
        Layout.fillHeight: true
        Layout.leftMargin: Style.marginM
        Layout.rightMargin: Style.marginM
      }

      // ── Right column: README viewer ──
      PluginsReadmeView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        pluginApi: root.pluginApi
        selectedPluginId: root.selectedPluginId
      }
    }
  }
}
