import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Power
import qs.Widgets

NIconButtonHot {
  property ShellScreen screen

  icon: PowerProfileService.diutaliaPerformanceMode ? "rocket" : "rocket-off"
  tooltipText: I18n.tr("tooltips.diutalia-performance-enabled")
  hot: PowerProfileService.diutaliaPerformanceMode
  onClicked: PowerProfileService.toggleDiutaliaPerformance()
}
