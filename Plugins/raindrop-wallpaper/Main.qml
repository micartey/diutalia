import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Services.Power
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property bool rainEnabled: cfg.enabled ?? defaults.enabled ?? true
  readonly property int density: Math.max(10, Math.min(300, cfg.density ?? defaults.density ?? 100))
  readonly property real speed: Math.max(0, Math.min(3, cfg.speed ?? defaults.speed ?? 1))
  readonly property real windowDropletSpeed: Math.max(0, Math.min(3, cfg.windowDropletSpeed ?? defaults.windowDropletSpeed ?? 1))
  readonly property real rainOpacity: Math.max(0, Math.min(1, cfg.opacity ?? defaults.opacity ?? 0.85))
  readonly property real dropletSize: Math.max(0.4, Math.min(2.5, cfg.dropletSize ?? defaults.dropletSize ?? 1))
  readonly property real refraction: Math.max(0, Math.min(1.5, cfg.refraction ?? defaults.refraction ?? 0.7))
  readonly property real dropletLifetime: Math.max(0.5, Math.min(10, cfg.dropletLifetime ?? defaults.dropletLifetime ?? 3))
  readonly property real hitWindowPercentage: Math.max(0, Math.min(100, cfg.hitWindowPercentage ?? defaults.hitWindowPercentage ?? 35))
  readonly property real backgroundRain: Math.max(0, Math.min(100, cfg.backgroundRain ?? defaults.backgroundRain ?? 65))
  readonly property real glassStrength: Math.max(0, Math.min(3, cfg.glassStrength ?? defaults.glassStrength ?? 1.5))

  IpcHandler {
    target: "plugin:raindrop-wallpaper"

    function toggle() {
      if (!root.pluginApi)
        return;
      root.pluginApi.pluginSettings.enabled = !root.rainEnabled;
      root.pluginApi.saveSettings();
    }
  }

  Variants {
    model: Quickshell.screens

    delegate: Loader {
      id: screenLoader
      required property ShellScreen modelData

      active: root.pluginApi !== null && root.rainEnabled && root.rainOpacity > 0 && Settings.data.wallpaper.enabled && !PowerProfileService.diutaliaPerformanceMode && !PanelService.lockScreen?.active

      sourceComponent: PanelWindow {
        id: window
        property string wallpaperPath: WallpaperService.isInitialized ? WallpaperService.getWallpaper(screenLoader.modelData.name) : ""

        Connections {
          target: WallpaperService
          function onWallpaperChanged(screenName, path) {
            if (screenName === window.screen.name)
              window.wallpaperPath = path;
          }
          function onIsInitializedChanged() {
            if (WallpaperService.isInitialized)
              window.wallpaperPath = WallpaperService.getWallpaper(window.screen.name);
          }
        }

        screen: screenLoader.modelData
        color: "transparent"
        mask: Region {}
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "diutalia-raindrop-" + screen.name

        anchors {
          top: true
          bottom: true
          left: true
          right: true
        }

        WetGlass {
          anchors.fill: parent
          wallpaperSource: WallpaperService.isSolidColorPath(window.wallpaperPath) ? "" : window.wallpaperPath
          useSolidColor: Settings.data.wallpaper.useSolidColor || WallpaperService.isSolidColorPath(window.wallpaperPath)
          solidColor: WallpaperService.isSolidColorPath(window.wallpaperPath) ? WallpaperService.getSolidColor(window.wallpaperPath) : Settings.data.wallpaper.solidColor
          fillMode: WallpaperService.getFillModeUniform()
          fillColor: Settings.data.wallpaper.fillColor
          density: root.density
          speed: root.speed
          windowDropletSpeed: root.windowDropletSpeed
          opacity: root.rainOpacity
          dropletSize: root.dropletSize
          refraction: root.refraction
          dropletLifetime: root.dropletLifetime
          hitWindowPercentage: root.hitWindowPercentage
          backgroundRain: root.backgroundRain
          glassStrength: root.glassStrength
        }
      }
    }
  }
}
