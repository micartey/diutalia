import QtQuick

Item {
  id: root

  property url wallpaperSource: ""
  property real fillMode: 1
  property color fillColor: "black"
  property bool useSolidColor: false
  property color solidColor: "black"
  property real density: 100
  property real dropletSize: 1
  property real refraction: 0.7
  property real speed: 1
  property bool paused: false
  property bool continueBackgroundRainWhenPaused: false
  property real backgroundTime: 0
  property real time: 0
  property real windowTime: 0
  property real windowDropletSpeed: 1
  property real dropletLifetime: 3
  property real hitWindowPercentage: 35
  property real backgroundRain: 65
  property real glassStrength: 1.5
  property real parallax: 0
  property vector2d pointerOffset: Qt.vector2d(0, 0)
  readonly property int shaderStatus: glass.status
  readonly property string shaderLog: glass.log
  readonly property int wallpaperStatus: wallpaper.status

  Image {
    id: wallpaper
    source: root.wallpaperSource
    visible: false
    asynchronous: true
    cache: true
  }

  Rectangle {
    id: solidTexture
    width: 1
    height: 1
    color: root.solidColor
  }

  ShaderEffectSource {
    id: solidSource
    sourceItem: solidTexture
    hideSource: true
    visible: false
    textureSize: Qt.size(1, 1)
  }

  Timer {
    interval: 33
    repeat: true
    running: root.visible && ((!root.paused && (root.speed > 0 || root.windowDropletSpeed > 0)) || (root.paused && root.continueBackgroundRainWhenPaused && root.speed > 0 && root.backgroundRain > 0))
    property real previousTime: 0
    onRunningChanged: previousTime = Date.now()
    onTriggered: {
      const now = Date.now();
      const dt = Math.min(0.1, (now - previousTime) / 1000);
      if (!root.paused) {
        root.time += dt * root.speed;
        root.windowTime += dt * root.windowDropletSpeed;
      }
      if (!root.paused || root.continueBackgroundRainWhenPaused)
        root.backgroundTime += dt * root.speed;
      previousTime = now;
    }
  }

  ShaderEffect {
    id: glass
    anchors.fill: parent
    visible: root.useSolidColor || wallpaper.status === Image.Ready

    property variant source: root.useSolidColor ? solidSource : wallpaper
    property vector2d screenSize: Qt.vector2d(width, height)
    property vector2d imageDimensions: Qt.vector2d(Math.max(1, wallpaper.sourceSize.width), Math.max(1, wallpaper.sourceSize.height))
    property real fillMode: root.fillMode
    property color fillColor: root.fillColor
    property real isSolid: root.useSolidColor ? 1 : 0
    property color solidColor: root.solidColor
    property real density: root.density / 100
    property real dropletSize: root.dropletSize
    property real refraction: root.refraction
    property real time: root.time
    property real dropletLifetime: root.dropletLifetime
    property real hitWindowPercentage: root.hitWindowPercentage / 100
    property real backgroundRain: root.backgroundRain / 100
    property real glassStrength: root.glassStrength
    property real windowTime: root.windowTime
    property real backgroundTime: root.backgroundTime
    property vector2d parallaxOffset: Qt.vector2d(root.pointerOffset.x * root.parallax / 50, root.pointerOffset.y * root.parallax / 50)

    fragmentShader: Qt.resolvedUrl("shaders/wet-glass.frag.qsb")
  }
}
