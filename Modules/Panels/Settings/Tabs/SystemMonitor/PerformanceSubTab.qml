import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.system.diutalia-performance-disable-wallpaper-label")
    description: I18n.tr("panels.system.diutalia-performance-disable-wallpaper-description")
    checked: !Settings.data.diutaliaPerformance.disableWallpaper
    defaultValue: !Settings.getDefaultValue("diutaliaPerformance.disableWallpaper")
    onToggled: checked => Settings.data.diutaliaPerformance.disableWallpaper = !checked
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.system.diutalia-performance-disable-desktop-widgets-label")
    description: I18n.tr("panels.system.diutalia-performance-disable-desktop-widgets-description")
    checked: !Settings.data.diutaliaPerformance.disableDesktopWidgets
    defaultValue: !Settings.getDefaultValue("diutaliaPerformance.disableDesktopWidgets")
    onToggled: checked => Settings.data.diutaliaPerformance.disableDesktopWidgets = !checked
  }
}
