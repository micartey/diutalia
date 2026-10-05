import QtQuick
import QtQuick.Window
import "../" as Rain
import "../WindowPresence.js" as WindowPresence

Window {
  id: window
  width: 960
  height: 540
  visible: true
  color: "#60736b"
  property string outputDirectory: Qt.application.arguments[Qt.application.arguments.length - 1]
  property int stage: 0
  property real glassChecksum: -1
  property real stoppedWindowTime: 0
  property real pausedTime: 0
  property real pausedWindowTime: 0
  property real pausedBackgroundTime: 0

  function advance() {
    stage++;
    stepTimer.restart();
  }

  function capture(name) {
    glass.grabToImage(result => {
      const path = window.outputDirectory + "/wet-glass-" + name + ".png";
      if (!result.saveToFile(path)) {
        Qt.exit(2);
        return;
      }
      verification.mode = name;
      verification.imagePath = "file://" + path;
      verification.loadImage(verification.imagePath);
    });
  }

  Canvas {
    id: verification
    width: window.width
    height: window.height
    visible: false
    property string imagePath: ""
    property string mode: ""

    onImageLoaded: {
      const ctx = getContext("2d");
      ctx.clearRect(0, 0, width, height);
      ctx.drawImage(imagePath, 0, 0);
      const pixels = ctx.getImageData(0, 0, width, height).data;
      let covered = 0;
      let checksum = 0;
      let purplePixels = 0;
      let bluePixels = 0;
      let whitePixels = 0;
      for (let i = 0; i < pixels.length; i += 4) {
        if (pixels[i + 3] > 0)
          covered++;
        if (pixels[i + 3] > 100) {
          if (pixels[i] > pixels[i + 1] + 10 && pixels[i + 2] > pixels[i] + 10)
            purplePixels++;
          if (pixels[i + 1] > pixels[i] + 8 && pixels[i + 2] > pixels[i] + 15)
            bluePixels++;
          if (pixels[i] > 210 && pixels[i + 1] > 210 && pixels[i + 2] > 210)
            whitePixels++;
        }
        checksum = (checksum + (pixels[i] * 3 + pixels[i + 1] * 5 + pixels[i + 2] * 7 + pixels[i + 3]) * (i % 251 + 1)) >>> 0;
      }
      if (mode === "empty") {
        Qt.exit(covered === 0 ? 0 : 7);
        return;
      }
      if (covered < 1000 || covered >= width * height - 1000) {
        Qt.exit(8);
        return;
      }
      if (mode === "glass")
        window.glassChecksum = checksum;
      if ((mode === "refreshed" || mode === "untinted") && checksum === window.glassChecksum) {
        Qt.exit(9);
        return;
      }
      if (mode === "solid" && (purplePixels < 5 || bluePixels < 5 || whitePixels < 5)) {
        Qt.exit(10);
        return;
      }
      if (mode === "combined")
        glass.windowDropletSpeed = 2;
      window.advance();
    }
  }

  Image {
    anchors.fill: parent
    source: "../../../Assets/Wallpaper/diutalia.png"
    fillMode: Image.PreserveAspectCrop
  }

  Rain.WetGlass {
    id: glass
    anchors.fill: parent
    wallpaperSource: Qt.resolvedUrl("../../../Assets/Wallpaper/diutalia.png")
    density: 140
    dropletSize: 1.3
    opacity: 0.9
    speed: 0
    windowDropletSpeed: 0
  }

  Timer {
    id: stepTimer
    interval: 750
    running: true
    onTriggered: {
      switch (window.stage) {
      case 0:
        const outputs = WindowPresence.occupiedOutputs(
          [{ id: 1, output: "DP-1", isActive: true }], [{ workspaceId: 1 }], false);
        if (outputs["DP-1"] !== true) {
          Qt.exit(15);
          return;
        }
        if (glass.shaderStatus !== ShaderEffect.Compiled || glass.wallpaperStatus !== Image.Ready || glass.time !== 0) {
          Qt.exit(1);
          return;
        }
        window.contentItem.grabToImage(result => {
          if (!result.saveToFile(window.outputDirectory + "/wet-glass-preview.png"))
            Qt.exit(3);
        });
        window.capture("combined");
        break;
      case 1:
        if (glass.time !== 0 || glass.windowTime <= 0) {
          Qt.exit(4);
          return;
        }
        glass.windowDropletSpeed = 0;
        window.stoppedWindowTime = glass.windowTime;
        glass.speed = 3;
        glass.useSolidColor = true;
        glass.solidColor = "#777777";
        glass.wallpaperSource = "";
        window.advance();
        break;
      case 2:
        window.capture("solid");
        break;
      case 3:
        if (glass.time <= 0 || glass.windowTime !== window.stoppedWindowTime) {
          Qt.exit(11);
          return;
        }
        glass.useSolidColor = false;
        glass.wallpaperSource = Qt.resolvedUrl("../../../Assets/Wallpaper/diutalia.png");
        glass.speed = 0;
        glass.hitWindowPercentage = 0;
        glass.backgroundRain = 100;
        window.advance();
        break;
      case 4:
        window.capture("background");
        break;
      case 5:
        glass.hitWindowPercentage = 100;
        glass.backgroundRain = 0;
        glass.dropletLifetime = 0.5;
        glass.time = 0;
        glass.windowTime = 0;
        window.advance();
        break;
      case 6:
        window.capture("glass");
        break;
      case 7:
        glass.glassStrength = 0;
        window.advance();
        break;
      case 8:
        window.capture("untinted");
        break;
      case 9:
        glass.glassStrength = 3;
        glass.time = 5;
        window.advance();
        break;
      case 10:
        window.capture("refreshed");
        break;
      case 11:
        glass.speed = 1;
        glass.windowDropletSpeed = 1;
        glass.paused = true;
        window.pausedTime = glass.time;
        window.pausedWindowTime = glass.windowTime;
        window.pausedBackgroundTime = glass.backgroundTime;
        window.advance();
        break;
      case 12:
        if (glass.time !== window.pausedTime || glass.windowTime !== window.pausedWindowTime || glass.backgroundTime !== window.pausedBackgroundTime) {
          Qt.exit(12);
          return;
        }
        glass.continueBackgroundRainWhenPaused = true;
        glass.backgroundRain = 65;
        window.advance();
        break;
      case 13:
        if (glass.time !== window.pausedTime || glass.windowTime !== window.pausedWindowTime || glass.backgroundTime <= window.pausedBackgroundTime) {
          Qt.exit(13);
          return;
        }
        glass.paused = false;
        window.advance();
        break;
      case 14:
        if (glass.time <= window.pausedTime || glass.windowTime <= window.pausedWindowTime) {
          Qt.exit(14);
          return;
        }
        glass.speed = 0;
        glass.windowDropletSpeed = 0;
        glass.hitWindowPercentage = 0;
        glass.backgroundRain = 0;
        window.advance();
        break;
      case 15:
        window.capture("empty");
        break;
      }
    }
  }

  Timer {
    interval: 20000
    running: true
    onTriggered: Qt.exit(6)
  }
}
