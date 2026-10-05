import QtQuick
import QtQuick.Window
import "../" as Rain

Window {
  id: window
  width: 960
  height: 540
  visible: true
  property string outputDirectory: Qt.application.arguments[Qt.application.arguments.length - 1]
  property int stage: 0

  Canvas {
    id: pattern
    anchors.fill: parent
    onPaint: {
      const ctx = getContext("2d");
      for (let y = 0; y < height; y += 16) {
        for (let x = 0; x < width; x += 16) {
          ctx.fillStyle = ((x + y) / 16) % 2 === 0 ? "#246a96" : "#e8a953";
          ctx.fillRect(x, y, 16, 16);
        }
      }
    }
  }

  Rain.WetGlass {
    id: glass
    anchors.fill: parent
    density: 300
    dropletSize: 2
    hitWindowPercentage: 100
    backgroundRain: 0
    opacity: 1
    speed: 0
    windowDropletSpeed: 0
    glassStrength: 0
    refraction: 0
  }

  Canvas {
    id: verification
    width: window.width
    height: window.height
    visible: false
    property string path: ""
    property var baselinePixels: null
    onImageLoaded: {
      const ctx = getContext("2d");
      ctx.clearRect(0, 0, width, height);
      ctx.drawImage(path, 0, 0);
      const pixels = ctx.getImageData(0, 0, width, height).data;
      if (window.stage === 1) {
        const visited = new Uint8Array(width * height);
        let measured = 0;
        let round = 0;
        for (let start = 0; start < visited.length; start++) {
          if (visited[start] || pixels[start * 4 + 3] < 200)
            continue;
          const queue = [start];
          visited[start] = 1;
          let minX = width;
          let maxX = 0;
          let minY = height;
          let maxY = 0;
          for (let q = 0; q < queue.length; q++) {
            const p = queue[q];
            const x = p % width;
            const y = Math.floor(p / width);
            minX = Math.min(minX, x);
            maxX = Math.max(maxX, x);
            minY = Math.min(minY, y);
            maxY = Math.max(maxY, y);
            for (const n of [p - 1, p + 1, p - width, p + width]) {
              if (n < 0 || n >= visited.length || visited[n] || pixels[n * 4 + 3] < 200)
                continue;
              if (Math.abs(n % width - x) + Math.abs(Math.floor(n / width) - y) !== 1)
                continue;
              visited[n] = 1;
              queue.push(n);
            }
          }
          if (queue.length < 50 || minX === 0 || minY === 0 || maxX === width - 1 || maxY === height - 1)
            continue;
          measured++;
          if (Math.abs((maxX - minX) - (maxY - minY)) <= 2)
            round++;
        }
        // Allow overlapping beads while requiring most isolated shapes to stay round.
        if (measured < 10 || round < measured * 0.75) {
          Qt.exit(12);
          return;
        }
        baselinePixels = Array.from(pixels);
        glass.refraction = 1;
      } else {
        let covered = 0;
        let changed = 0;
        let white = 0;
        for (let i = 0; i < pixels.length; i += 4) {
          if (pixels[i + 3] < 200)
            continue;
          covered++;
          if (Math.abs(pixels[i] - baselinePixels[i]) + Math.abs(pixels[i + 1] - baselinePixels[i + 1]) + Math.abs(pixels[i + 2] - baselinePixels[i + 2]) > 50)
            changed++;
          if (pixels[i] > 245 && pixels[i + 1] > 245 && pixels[i + 2] > 245)
            white++;
        }
        if (covered < 1000 || changed < covered * 0.2) {
          Qt.exit(10);
          return;
        }
        if (window.stage === 3) {
          if (white > covered * 0.05) {
            Qt.exit(11);
            return;
          }
          Qt.quit();
          return;
        }
        glass.glassStrength = 3;
      }
      window.stage++;
      stepTimer.restart();
    }
  }

  Timer {
    id: stepTimer
    interval: 750
    running: true
    onTriggered: {
      if (window.stage === 0) {
        pattern.grabToImage(result => {
          const path = window.outputDirectory + "/refraction-pattern.png";
          if (!result.saveToFile(path)) {
            Qt.exit(1);
            return;
          }
          glass.wallpaperSource = "file://" + path;
          window.stage++;
          stepTimer.restart();
        });
        return;
      }
      if (glass.wallpaperStatus !== Image.Ready || glass.shaderStatus !== ShaderEffect.Compiled) {
        Qt.exit(2);
        return;
      }
      if (window.stage === 3) {
        window.contentItem.grabToImage(result => {
          if (!result.saveToFile(window.outputDirectory + "/refraction-preview.png"))
            Qt.exit(3);
        });
      }
      glass.grabToImage(result => {
        const path = window.outputDirectory + "/refraction-" + window.stage + ".png";
        if (!result.saveToFile(path)) {
          Qt.exit(4);
          return;
        }
        verification.path = "file://" + path;
        verification.loadImage(verification.path);
      });
    }
  }

  Timer {
    interval: 15000
    running: true
    onTriggered: Qt.exit(5)
  }
}
