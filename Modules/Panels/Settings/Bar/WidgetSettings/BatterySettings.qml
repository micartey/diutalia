import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.Hardware
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM

  // Properties to receive data from parent
  property var screen: null
  property var widgetData: null
  property var widgetMetadata: null

  signal settingsChanged(var settings)

  // Local state
  property string valueDisplayMode: widgetData.displayMode !== undefined ? widgetData.displayMode : widgetMetadata.displayMode
  property string valueDeviceNativePath: widgetData.deviceNativePath !== undefined ? widgetData.deviceNativePath : widgetMetadata.deviceNativePath
  property bool valueShowPowerProfiles: widgetData.showPowerProfiles !== undefined ? widgetData.showPowerProfiles : widgetMetadata.showPowerProfiles
  property bool valueShowDiutaliaPerformance: widgetData.showDiutaliaPerformance !== undefined ? widgetData.showDiutaliaPerformance : widgetMetadata.showDiutaliaPerformance
  property bool valueHideIfNotDetected: widgetData.hideIfNotDetected !== undefined ? widgetData.hideIfNotDetected : widgetMetadata.hideIfNotDetected
  property bool valueHideIfIdle: widgetData.hideIfIdle !== undefined ? widgetData.hideIfIdle : widgetMetadata.hideIfIdle
  property string valueColor0To20: widgetData.color0To20 !== undefined ? widgetData.color0To20 : widgetMetadata.color0To20
  property string valueColor20To40: widgetData.color20To40 !== undefined ? widgetData.color20To40 : widgetMetadata.color20To40
  property string valueColor40To60: widgetData.color40To60 !== undefined ? widgetData.color40To60 : widgetMetadata.color40To60
  property string valueColor60To80: widgetData.color60To80 !== undefined ? widgetData.color60To80 : widgetMetadata.color60To80
  property string valueColor80To100: widgetData.color80To100 !== undefined ? widgetData.color80To100 : widgetMetadata.color80To100
  readonly property var batteryColors: [
    { "key": "#2E7D32", "name": I18n.tr("bar.battery.color-green") },
    { "key": "#66BB6A", "name": I18n.tr("bar.battery.color-soft-green") },
    { "key": "#9EAD00", "name": I18n.tr("bar.battery.color-yellow-green") },
    { "key": "#FB8C00", "name": I18n.tr("bar.battery.color-soft-orange") },
    { "key": "#E65100", "name": I18n.tr("bar.battery.color-dark-orange") },
    { "key": "#EF5350", "name": I18n.tr("bar.battery.color-light-red") },
    { "key": "#D32F2F", "name": I18n.tr("bar.battery.color-red") }
  ]

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});
    if (widgetData && widgetData.id) {
      settings.id = widgetData.id;
    }
    settings.displayMode = valueDisplayMode;
    settings.showPowerProfiles = valueShowPowerProfiles;
    settings.showDiutaliaPerformance = valueShowDiutaliaPerformance;
    settings.hideIfNotDetected = valueHideIfNotDetected;
    settings.hideIfIdle = valueHideIfIdle;
    settings.deviceNativePath = valueDeviceNativePath;
    settings.color0To20 = valueColor0To20;
    settings.color20To40 = valueColor20To40;
    settings.color40To60 = valueColor40To60;
    settings.color60To80 = valueColor60To80;
    settings.color80To100 = valueColor80To100;
    settingsChanged(settings);
  }

  NComboBox {
    id: deviceComboBox
    Layout.fillWidth: true
    label: I18n.tr("bar.battery.device-label")
    description: I18n.tr("bar.battery.device-description")
    minimumWidth: 240
    model: BatteryService.deviceModel
    currentKey: root.valueDeviceNativePath
    onSelected: key => {
                  root.valueDeviceNativePath = key;
                  saveSettings();
                }
    defaultValue: widgetMetadata.deviceNativePath
  }

  NComboBox {
    Layout.fillWidth: true
    label: I18n.tr("common.display-mode")
    description: I18n.tr("bar.battery.display-mode-description")
    minimumWidth: 240
    model: [
      {
        "key": "graphic",
        "name": I18n.tr("bar.battery.display-mode-graphic")
      },
      {
        "key": "graphic-clean",
        "name": I18n.tr("bar.battery.display-mode-graphic-clean")
      },
      {
        "key": "icon-hover",
        "name": I18n.tr("bar.battery.display-mode-icon-hover")
      },
      {
        "key": "icon-always",
        "name": I18n.tr("bar.battery.display-mode-icon-always")
      },
      {
        "key": "icon-only",
        "name": I18n.tr("bar.battery.display-mode-icon-only")
      }
    ]
    currentKey: root.valueDisplayMode
    onSelected: key => {
                  root.valueDisplayMode = key;
                  saveSettings();
                }
    defaultValue: widgetMetadata.displayMode
  }

  NComboBox {
    Layout.fillWidth: true
    label: I18n.tr("bar.battery.color-0-to-20-label")
    model: batteryColors
    currentKey: valueColor0To20
    onSelected: key => {
                  valueColor0To20 = key;
                  saveSettings();
                }
    defaultValue: widgetMetadata.color0To20
  }

  NComboBox {
    Layout.fillWidth: true
    label: I18n.tr("bar.battery.color-20-to-40-label")
    model: batteryColors
    currentKey: valueColor20To40
    onSelected: key => {
                  valueColor20To40 = key;
                  saveSettings();
                }
    defaultValue: widgetMetadata.color20To40
  }

  NComboBox {
    Layout.fillWidth: true
    label: I18n.tr("bar.battery.color-40-to-60-label")
    model: batteryColors
    currentKey: valueColor40To60
    onSelected: key => {
                  valueColor40To60 = key;
                  saveSettings();
                }
    defaultValue: widgetMetadata.color40To60
  }

  NComboBox {
    Layout.fillWidth: true
    label: I18n.tr("bar.battery.color-60-to-80-label")
    model: batteryColors
    currentKey: valueColor60To80
    onSelected: key => {
                  valueColor60To80 = key;
                  saveSettings();
                }
    defaultValue: widgetMetadata.color60To80
  }

  NComboBox {
    Layout.fillWidth: true
    label: I18n.tr("bar.battery.color-80-to-100-label")
    model: batteryColors
    currentKey: valueColor80To100
    onSelected: key => {
                  valueColor80To100 = key;
                  saveSettings();
                }
    defaultValue: widgetMetadata.color80To100
  }

  NToggle {
    label: I18n.tr("bar.battery.hide-if-not-detected-label")
    description: I18n.tr("bar.battery.hide-if-not-detected-description")
    checked: valueHideIfNotDetected
    onToggled: checked => {
                 valueHideIfNotDetected = checked;
                 saveSettings();
               }
    defaultValue: widgetMetadata.hideIfNotDetected
  }

  NToggle {
    label: I18n.tr("bar.battery.hide-if-idle-label")
    description: I18n.tr("bar.battery.hide-if-idle-description")
    checked: valueHideIfIdle
    onToggled: checked => {
                 valueHideIfIdle = checked;
                 saveSettings();
               }
    defaultValue: widgetMetadata.hideIfIdle
  }

  NDivider {
    Layout.fillWidth: true
  }

  NToggle {
    label: I18n.tr("bar.battery.show-power-profile-label")
    description: I18n.tr("bar.battery.show-power-profile-description")
    checked: valueShowPowerProfiles
    onToggled: checked => {
                 valueShowPowerProfiles = checked;
                 saveSettings();
               }
    defaultValue: widgetMetadata.showPowerProfiles
  }

  NToggle {
    label: I18n.tr("bar.battery.show-diutalia-performance-label")
    description: I18n.tr("bar.battery.show-diutalia-performance-description")
    checked: valueShowDiutaliaPerformance
    onToggled: checked => {
                 valueShowDiutaliaPerformance = checked;
                 saveSettings();
               }
    defaultValue: widgetMetadata.showDiutaliaPerformance
  }
}
