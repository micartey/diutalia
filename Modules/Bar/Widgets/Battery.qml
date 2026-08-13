import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Services.Hardware
import qs.Services.Networking
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property ShellScreen screen

  // Widget properties passed from Bar.qml for per-instance settings
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId] ?? {}
  // Explicit screenName property ensures reactive binding when screen changes
  readonly property string screenName: screen ? screen.name : ""
  property var widgetSettings: {
    if (section && sectionWidgetIndex >= 0 && screenName) {
      var widgets = Settings.getBarWidgetsForScreen(screenName)[section];
      if (widgets && sectionWidgetIndex < widgets.length) {
        return widgets[sectionWidgetIndex];
      }
    }
    return {};
  }

  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)

  readonly property string displayMode: widgetSettings.displayMode !== undefined ? widgetSettings.displayMode : widgetMetadata.displayMode
  readonly property bool useGraphicMode: displayMode === "graphic" || displayMode === "graphic-clean"

  readonly property bool hideIfNotDetected: widgetSettings.hideIfNotDetected !== undefined ? widgetSettings.hideIfNotDetected : widgetMetadata.hideIfNotDetected
  readonly property bool hideIfIdle: widgetSettings.hideIfIdle !== undefined ? widgetSettings.hideIfIdle : widgetMetadata.hideIfIdle
  readonly property color color0To20: Qt.color(widgetSettings.color0To20 !== undefined ? widgetSettings.color0To20 : widgetMetadata.color0To20)
  readonly property color color20To40: Qt.color(widgetSettings.color20To40 !== undefined ? widgetSettings.color20To40 : widgetMetadata.color20To40)
  readonly property color color40To60: Qt.color(widgetSettings.color40To60 !== undefined ? widgetSettings.color40To60 : widgetMetadata.color40To60)
  readonly property color color60To80: Qt.color(widgetSettings.color60To80 !== undefined ? widgetSettings.color60To80 : widgetMetadata.color60To80)
  readonly property color color80To100: Qt.color(widgetSettings.color80To100 !== undefined ? widgetSettings.color80To100 : widgetMetadata.color80To100)

  // Check if selected device is actually present/connected
  readonly property bool isReady: BatteryService.isDeviceReady(selectedDevice)
  readonly property bool isPresent: BatteryService.isDevicePresent(selectedDevice)
  readonly property real percent: isReady ? BatteryService.getPercentage(selectedDevice) : -1
  readonly property bool isCharging: isReady ? BatteryService.isCharging(selectedDevice) : false
  readonly property bool isPluggedIn: isReady ? BatteryService.isPluggedIn(selectedDevice) : false
  readonly property bool isLowBattery: isReady ? BatteryService.isLowBattery(selectedDevice) : false
  readonly property bool isCriticalBattery: isReady ? BatteryService.isCriticalBattery(selectedDevice) : false
  readonly property color batteryColor: {
    if (percent <= 20)
      return color0To20;
    if (percent <= 40)
      return color20To40;
    if (percent <= 60)
      return color40To60;
    if (percent <= 80)
      return color60To80;
    return color80To100;
  }
  readonly property bool hasBatteryColor: isReady

  // Visibility: show if hideIfNotDetected is false, or if battery is ready
  readonly property bool shouldShow: !hideIfNotDetected || (isReady && (hideIfIdle ? !isPluggedIn : true))
  readonly property string deviceNativePath: widgetSettings.deviceNativePath !== undefined ? widgetSettings.deviceNativePath : widgetMetadata.deviceNativePath
  readonly property var selectedDevice: BatteryService.isDevicePresent(BatteryService.findDevice(deviceNativePath)) ? BatteryService.findDevice(deviceNativePath) : null

  readonly property var tooltipContent: {
    if (!isReady || !isPresent) {
      return I18n.tr("battery.no-battery-detected");
    }

    let rows = [];
    const isInternal = selectedDevice.isLaptopBattery;
    if (isInternal) {
      // Show charge percentage
      rows.push([I18n.tr("battery.battery-level"), `${percent}%`]);

      let timeText = BatteryService.getTimeRemainingText(selectedDevice);
      if (timeText) {
        const colonIdx = timeText.indexOf(":");
        if (colonIdx >= 0) {
          rows.push([timeText.substring(0, colonIdx).trim(), timeText.substring(colonIdx + 1).trim()]);
        } else {
          rows.push([timeText, ""]);
        }
      }

      let rateText = BatteryService.getRateText(selectedDevice);
      if (!isPluggedIn && rateText) {
        const colonIdx = rateText.indexOf(":");
        if (colonIdx >= 0) {
          rows.push([rateText.substring(0, colonIdx).trim(), rateText.substring(colonIdx + 1).trim()]);
        } else {
          rows.push([rateText, ""]);
        }
      }

      // Show battery health if supported (check actual battery, not DisplayDevice)
      let healthDevice = selectedDevice.healthSupported ? selectedDevice : (BatteryService.laptopBatteries.length > 0 ? BatteryService.laptopBatteries[0] : null);
      if (healthDevice && healthDevice.healthSupported) {
        rows.push([I18n.tr("battery.battery-health"), `${Math.round(healthDevice.healthPercentage)}%`]);
      }
    } else if (selectedDevice) {
      // External / Peripheral Device (Phone, Keyboard, Mouse, Gamepad, Headphone etc.)
      let name = BatteryService.getDeviceName(selectedDevice);
      rows.push([name, `${percent}%`]);
    }

    // If we are showing the main laptop battery, append external devices
    if (isInternal) {
      var external = BatteryService.bluetoothBatteries;
      if (external.length > 0) {
        if (rows.length > 0) {
          rows.push(["---", "---"]); // Separator
        }
        for (var j = 0; j < external.length; j++) {
          var dev = external[j];
          var dName = BatteryService.getDeviceName(dev);
          var dPct = BatteryService.getPercentage(dev);
          rows.push([dName, `${dPct}%`]);
        }
      }
    }

    return rows;
  }

  visible: shouldShow
  opacity: shouldShow ? 1.0 : 0.0

  implicitWidth: useGraphicMode ? capsule.width : pill.width
  implicitHeight: useGraphicMode ? capsule.height : pill.height

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": I18n.tr("actions.widget-settings"),
        "action": "widget-settings",
        "icon": "settings"
      },
    ]

    onTriggered: action => {
                   contextMenu.close();
                   PanelService.closeContextMenu(screen);

                   if (action === "widget-settings") {
                     BarService.openWidgetSettings(screen, section, sectionWidgetIndex, widgetId, widgetSettings);
                   }
                 }
  }

  // ==================== GRAPHIC MODE ====================

  // Capsule background (graphic mode only)
  Rectangle {
    id: capsule
    visible: root.useGraphicMode
    anchors.centerIn: nBattery
    width: root.isBarVertical ? root.capsuleHeight : nBattery.width + Style.margin2S
    height: root.isBarVertical ? nBattery.height + Style.margin2S : root.capsuleHeight
    radius: Math.min(Style.radiusL, width / 2)
    color: graphicMouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    Behavior on color {
      enabled: !Color.isTransitioning
      ColorAnimation {
        duration: Style.animationFast
        easing.type: Easing.InOutQuad
      }
    }
  }

  NBattery {
    id: nBattery
    visible: root.useGraphicMode
    anchors.centerIn: parent
    baseSize: (Style.getBarHeightForScreen(root.screenName) / root.capsuleHeight) * Style.fontSizeXXS
    showPercentageText: root.displayMode !== "graphic-clean"
    vertical: root.isBarVertical
    percentage: root.percent
    ready: root.isReady
    charging: root.isCharging
    pluggedIn: root.isPluggedIn
    low: root.isLowBattery
    critical: root.isCriticalBattery
    baseColor: root.hasBatteryColor ? root.batteryColor : (graphicMouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface)
    lowColor: root.hasBatteryColor ? root.batteryColor : Color.mError
    chargingColor: root.hasBatteryColor ? root.batteryColor : Color.mPrimary
    textColor: root.hasBatteryColor ? (0.2126 * root.batteryColor.r + 0.7152 * root.batteryColor.g + 0.0722 * root.batteryColor.b > 0.5 ? "black" : "white") : (graphicMouseArea.containsMouse ? Color.mHover : Color.mSurface)
  }

  MouseArea {
    id: graphicMouseArea
    visible: root.useGraphicMode
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onEntered: {
      if (!getBatteryPanel()?.isPanelOpen && root.tooltipContent) {
        TooltipService.show(root, root.tooltipContent, BarService.getTooltipDirection(root.screen?.name));
        tooltipRefreshTimer.start();
      }
    }
    onExited: {
      tooltipRefreshTimer.stop();
      TooltipService.hide();
    }
    onClicked: mouse => {
                 TooltipService.hide();
                 if (mouse.button === Qt.RightButton) {
                   PanelService.showContextMenu(contextMenu, nBattery, screen);
                 } else {
                   toggleBatteryPanel();
                 }
               }
  }

  Timer {
    id: tooltipRefreshTimer
    interval: 1000
    repeat: true
    onTriggered: {
      if (graphicMouseArea.containsMouse) {
        TooltipService.updateText(root.tooltipContent);
      }
    }
  }

  // ==================== ICON MODE ====================

  BarPill {
    id: pill
    visible: !root.useGraphicMode
    screen: root.screen
    oppositeDirection: BarService.getPillDirection(root)
    icon: BatteryService.getIcon(root.percent, root.isCharging, root.isPluggedIn, root.isReady)
    text: root.isReady ? root.percent : "-"
    suffix: "%"
    autoHide: false
    forceOpen: root.isReady && root.displayMode === "icon-always"
    forceClose: root.displayMode === "icon-only" || !root.isReady
    customBackgroundColor: root.isCharging ? Color.mPrimary : ((root.isLowBattery || root.isCriticalBattery) ? Color.mError : "transparent")
    customTextIconColor: root.hasBatteryColor ? root.batteryColor : (root.isCharging ? Color.mOnPrimary : ((root.isLowBattery || root.isCriticalBattery) ? Color.mOnError : "transparent"))
    tooltipText: !getBatteryPanel()?.isPanelOpen ? root.tooltipContent : ""
    onClicked: toggleBatteryPanel()
    onRightClicked: PanelService.showContextMenu(contextMenu, pill, screen)
  }

  // ==================== SHARED ====================

  function getBatteryPanel() {
    var panel = PanelService.getPanel("batteryPanel", screen);
    if (panel) {
      panel.panelID = {
        showPowerProfiles: widgetSettings.showPowerProfiles !== undefined ? widgetSettings.showPowerProfiles : widgetMetadata.showPowerProfiles,
        showDiutaliaPerformance: widgetSettings.showDiutaliaPerformance !== undefined ? widgetSettings.showDiutaliaPerformance : widgetMetadata.showDiutaliaPerformance
      };
    }
    return panel;
  }

  function toggleBatteryPanel() {
    getBatteryPanel()?.toggle(root);
  }
}
