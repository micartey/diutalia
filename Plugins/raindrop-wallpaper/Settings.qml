import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  property bool editEnabled: cfg.enabled ?? defaults.enabled ?? true
  property bool editPauseWhenWindowsPresent: cfg.pauseWhenWindowsPresent ?? defaults.pauseWhenWindowsPresent ?? true
  property bool editContinueBackgroundRainWhenPaused: cfg.continueBackgroundRainWhenPaused ?? defaults.continueBackgroundRainWhenPaused ?? false
  property int editDensity: cfg.density ?? defaults.density ?? 100
  property real editSpeed: cfg.speed ?? defaults.speed ?? 1
  property real editWindowDropletSpeed: cfg.windowDropletSpeed ?? defaults.windowDropletSpeed ?? 1
  property real editOpacity: cfg.opacity ?? defaults.opacity ?? 0.85
  property real editDropletSize: cfg.dropletSize ?? defaults.dropletSize ?? 1
  property real editRefraction: cfg.refraction ?? defaults.refraction ?? 0.7
  property real editDropletLifetime: cfg.dropletLifetime ?? defaults.dropletLifetime ?? 3
  property real editHitWindowPercentage: cfg.hitWindowPercentage ?? defaults.hitWindowPercentage ?? 35
  property real editBackgroundRain: cfg.backgroundRain ?? defaults.backgroundRain ?? 65
  property real editGlassStrength: cfg.glassStrength ?? defaults.glassStrength ?? 1.5
  property real editParallax: cfg.parallax ?? defaults.parallax ?? 0

  spacing: Style.marginL

  NToggle {
    label: pluginApi?.tr("settings.enabled.label")
    description: pluginApi?.tr("settings.enabled.description")
    checked: root.editEnabled
    onToggled: checked => root.editEnabled = checked
  }

  NToggle {
    label: pluginApi?.tr("settings.pauseWhenWindowsPresent.label")
    description: pluginApi?.tr("settings.pauseWhenWindowsPresent.description")
    checked: root.editPauseWhenWindowsPresent
    onToggled: checked => root.editPauseWhenWindowsPresent = checked
  }

  NToggle {
    label: pluginApi?.tr("settings.continueBackgroundRainWhenPaused.label")
    description: pluginApi?.tr("settings.continueBackgroundRainWhenPaused.description")
    checked: root.editContinueBackgroundRainWhenPaused
    enabled: root.editPauseWhenWindowsPresent
    onToggled: checked => root.editContinueBackgroundRainWhenPaused = checked
  }

  NValueSlider {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.density.label")
    description: pluginApi?.tr("settings.density.description")
    from: 10
    to: 300
    stepSize: 10
    value: root.editDensity
    text: root.editDensity.toString()
    onMoved: value => root.editDensity = Math.round(value)
  }

  NValueSlider {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.speed.label")
    description: pluginApi?.tr("settings.speed.description")
    from: 0
    to: 3
    stepSize: 0.1
    value: root.editSpeed
    text: root.editSpeed.toFixed(1) + "x"
    onMoved: value => root.editSpeed = value
  }

  NValueSlider {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.windowDropletSpeed.label")
    description: pluginApi?.tr("settings.windowDropletSpeed.description")
    from: 0
    to: 3
    stepSize: 0.1
    value: root.editWindowDropletSpeed
    text: root.editWindowDropletSpeed.toFixed(1) + "x"
    onMoved: value => root.editWindowDropletSpeed = value
  }

  NValueSlider {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.opacity.label")
    from: 0
    to: 1
    stepSize: 0.05
    value: root.editOpacity
    text: Math.round(root.editOpacity * 100) + "%"
    onMoved: value => root.editOpacity = value
  }

  NValueSlider {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.dropletSize.label")
    description: pluginApi?.tr("settings.dropletSize.description")
    from: 0.4
    to: 2.5
    stepSize: 0.05
    value: root.editDropletSize
    text: root.editDropletSize.toFixed(2) + "x"
    onMoved: value => root.editDropletSize = value
  }

  NValueSlider {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.refraction.label")
    description: pluginApi?.tr("settings.refraction.description")
    from: 0
    to: 1.5
    stepSize: 0.05
    value: root.editRefraction
    text: root.editRefraction.toFixed(2)
    onMoved: value => root.editRefraction = value
  }

  NValueSlider {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.glassStrength.label")
    description: pluginApi?.tr("settings.glassStrength.description")
    from: 0
    to: 3
    stepSize: 0.1
    value: root.editGlassStrength
    text: root.editGlassStrength.toFixed(1) + "x"
    onMoved: value => root.editGlassStrength = value
  }

  NValueSlider {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.parallax.label")
    description: pluginApi?.tr("settings.parallax.description")
    from: 0
    to: 10
    stepSize: 0.5
    value: root.editParallax
    text: root.editParallax.toFixed(1)
    onMoved: value => root.editParallax = value
  }

  NValueSlider {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.dropletLifetime.label")
    description: pluginApi?.tr("settings.dropletLifetime.description")
    from: 0.5
    to: 10
    stepSize: 0.5
    value: root.editDropletLifetime
    text: root.editDropletLifetime.toFixed(1) + "s"
    onMoved: value => root.editDropletLifetime = value
  }

  NValueSlider {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.hitWindowPercentage.label")
    description: pluginApi?.tr("settings.hitWindowPercentage.description")
    from: 0
    to: 100
    stepSize: 5
    value: root.editHitWindowPercentage
    text: Math.round(root.editHitWindowPercentage) + "%"
    onMoved: value => root.editHitWindowPercentage = value
  }

  NValueSlider {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.backgroundRain.label")
    description: pluginApi?.tr("settings.backgroundRain.description")
    from: 0
    to: 100
    stepSize: 5
    value: root.editBackgroundRain
    text: Math.round(root.editBackgroundRain) + "%"
    onMoved: value => root.editBackgroundRain = value
  }

  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.pluginSettings.enabled = editEnabled;
    pluginApi.pluginSettings.pauseWhenWindowsPresent = editPauseWhenWindowsPresent;
    pluginApi.pluginSettings.continueBackgroundRainWhenPaused = editContinueBackgroundRainWhenPaused;
    pluginApi.pluginSettings.density = editDensity;
    pluginApi.pluginSettings.speed = editSpeed;
    pluginApi.pluginSettings.windowDropletSpeed = editWindowDropletSpeed;
    pluginApi.pluginSettings.opacity = editOpacity;
    pluginApi.pluginSettings.dropletSize = editDropletSize;
    pluginApi.pluginSettings.refraction = editRefraction;
    pluginApi.pluginSettings.dropletLifetime = editDropletLifetime;
    pluginApi.pluginSettings.hitWindowPercentage = editHitWindowPercentage;
    pluginApi.pluginSettings.backgroundRain = editBackgroundRain;
    pluginApi.pluginSettings.glassStrength = editGlassStrength;
    pluginApi.pluginSettings.parallax = editParallax;
    pluginApi.saveSettings();
  }
}
