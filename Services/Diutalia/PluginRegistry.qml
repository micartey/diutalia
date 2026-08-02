pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Singleton {
  id: root

  readonly property string pluginsDir: Quickshell.shellDir + "/Plugins"
  readonly property string pluginsFile: Settings.configDir + "plugins.json"
  readonly property string pluginSettingsDir: Settings.configDir + "plugins"

  readonly property int currentVersion: 2

  Component.onCompleted: {
    ensurePluginsFile();
  }

  // Signals
  signal pluginsChanged

  // In-memory plugin cache (populated by scanning disk)
  property var installedPlugins: ({}) // { pluginId: manifest }
  property var pluginStates: ({}) // { pluginId: { enabled: bool } }
  property var pluginLoadVersions: ({}) // { pluginId: versionNumber } - for cache busting

  // Track async loading
  property int pendingManifests: 0

  // File storage for enabled states.
  property FileView pluginsFileView: FileView {
    id: pluginsFileView
    path: root.pluginsFile

    adapter: JsonAdapter {
      id: adapter
      property int version: root.currentVersion
      property var states: ({})
    }

    onLoaded: {
      Logger.i("PluginRegistry", "Loaded plugin states from:", path);
      root.pluginStates = adapter.states || {};

      // Scan bundled plugin folder to discover manifests.
      scanPluginFolder();
    }

    onLoadFailed: function (error) {
      Logger.w("PluginRegistry", "Failed to load plugins.json, will create it:", error);
      // Initialize defaults and continue
      root.pluginStates = {};
      // Scan for installed plugins
      root.scanPluginFolder();
    }
  }

  function init() {
    Logger.d("PluginRegistry", "Initialized");
    // Force instantiation of PluginService to set up signal listener
    PluginService.initialized;
  }

  // Ensure plugins.json exists (create minimal one if it doesn't)
  function ensurePluginsFile() {
    var checkProcess = Qt.createQmlObject(`
      import QtQuick
      import Quickshell.Io
      Process {
        command: ["sh", "-c", "test -f '${root.pluginsFile}' || echo '{\\"version\\":${root.currentVersion},\\"states\\":{}}' > '${root.pluginsFile}'"]
      }
    `, root, "EnsurePluginsFile");

    checkProcess.exited.connect(function (exitCode) {
      if (exitCode === 0) {
        Logger.d("PluginRegistry", "Plugins file ensured:", root.pluginsFile);
      }
      checkProcess.destroy();
    });

    checkProcess.running = true;
  }

  // Scan bundled plugin folder to discover manifests.
  function scanPluginFolder() {
    Logger.i("PluginRegistry", "Scanning bundled plugin folder:", root.pluginsDir);

    var scanProcess = Qt.createQmlObject(`
      import QtQuick
      import Quickshell.Io
      Process {
        command: ["sh", "-c", "for d in '${root.pluginsDir}'/*/; do [ -d \\"$d\\" ] || continue; [ -f \\"$d/manifest.json\\" ] || continue; echo \\"@@PLUGIN@@$(basename \\"$d\\")\\" ; cat \\"$d/manifest.json\\" ; done"]
        stdout: StdioCollector {}
        running: true
      }
    `, root, "ScanAllPlugins");

    scanProcess.exited.connect(function (exitCode) {
      var output = String(scanProcess.stdout.text || "");
      var sections = output.split("@@PLUGIN@@");
      var loadedCount = 0;

      for (var i = 1; i < sections.length; i++) {
        var section = sections[i];
        var newlineIdx = section.indexOf('\n');
        if (newlineIdx === -1)
          continue;

        var pluginId = section.substring(0, newlineIdx).trim();
        var manifestJson = section.substring(newlineIdx + 1).trim();

        if (!pluginId || !manifestJson)
          continue;

        try {
          var manifest = JSON.parse(manifestJson);
          var validation = validateManifest(manifest);

          if (validation.valid) {
            manifest.compositeKey = pluginId;
            root.installedPlugins[pluginId] = manifest;
            Logger.i("PluginRegistry", "Loaded plugin:", pluginId, "-", manifest.name);

            if (!root.pluginStates[pluginId]) {
              root.pluginStates[pluginId] = {
                enabled: false
              };
            }
            loadedCount++;
          } else {
            Logger.e("PluginRegistry", "Invalid manifest for", pluginId + ":", validation.error);
          }
        } catch (e) {
          Logger.e("PluginRegistry", "Failed to parse manifest for", pluginId + ":", e.toString());
        }
      }

      Logger.i("PluginRegistry", "All bundled plugin manifests loaded. Total plugins:", loadedCount);
      root.pluginsChanged();
      scanProcess.destroy();
    });
  }

  // Load a single plugin's manifest from disk
  function loadPluginManifest(pluginId) {
    var manifestPath = root.pluginsDir + "/" + pluginId + "/manifest.json";

    var catProcess = Qt.createQmlObject(`
      import QtQuick
      import Quickshell.Io
      Process {
        command: ["cat", "${manifestPath}"]
        stdout: StdioCollector {}
        running: true
      }
    `, root, "LoadManifest_" + pluginId);

    catProcess.exited.connect(function (exitCode) {
      var output = String(catProcess.stdout.text || "");
      if (exitCode === 0 && output) {
        try {
          var manifest = JSON.parse(output);
          var validation = validateManifest(manifest);

          if (validation.valid) {
            manifest.compositeKey = pluginId;
            root.installedPlugins[pluginId] = manifest;
            Logger.i("PluginRegistry", "Loaded plugin:", pluginId, "-", manifest.name);

            // Ensure state exists (default to disabled)
            if (!root.pluginStates[pluginId]) {
              root.pluginStates[pluginId] = {
                enabled: false
              };
            }
          } else {
            Logger.e("PluginRegistry", "Invalid manifest for", pluginId + ":", validation.error);
          }
        } catch (e) {
          Logger.e("PluginRegistry", "Failed to parse manifest for", pluginId + ":", e.toString());
        }
      } else {
        Logger.d("PluginRegistry", "No manifest found for:", pluginId);
      }

      // Decrement pending count and emit signal when all are done
      root.pendingManifests--;
      Logger.d("PluginRegistry", "Pending manifests remaining:", root.pendingManifests);
      if (root.pendingManifests === 0) {
        var installedIds = Object.keys(root.installedPlugins);
        Logger.i("PluginRegistry", "All bundled plugin manifests loaded. Total plugins:", installedIds.length);
        Logger.d("PluginRegistry", "Installed plugin IDs:", JSON.stringify(installedIds));
        root.pluginsChanged();
      }

      catProcess.destroy();
    });
  }

  // Save registry to disk.
  function save() {
    adapter.version = root.currentVersion;
    adapter.states = root.pluginStates;

    Qt.callLater(() => {
                   pluginsFileView.writeAdapter();
                   Logger.d("PluginRegistry", "Plugin states saved");
                 });
  }

  // Enable/disable a plugin
  function setPluginEnabled(pluginId, enabled) {
    if (!root.installedPlugins[pluginId]) {
      Logger.w("PluginRegistry", "Cannot set state for non-existent plugin:", pluginId);
      return;
    }

    if (!root.pluginStates[pluginId]) {
      root.pluginStates[pluginId] = {
        enabled: enabled
      };
    } else {
      root.pluginStates[pluginId].enabled = enabled;
    }

    save();
    root.pluginsChanged();
    Logger.i("PluginRegistry", "Plugin", pluginId, enabled ? "enabled" : "disabled");
  }

  // Check if plugin is enabled
  function isPluginEnabled(pluginId) {
    return root.pluginStates[pluginId]?.enabled || false;
  }

  // Check if plugin is downloaded/installed
  function isPluginDownloaded(pluginId) {
    return pluginId in root.installedPlugins;
  }

  // Get plugin manifest from cache
  function getPluginManifest(pluginId) {
    return root.installedPlugins[pluginId] || null;
  }

  // Get ALL installed plugin IDs (discovered from disk)
  function getAllInstalledPluginIds() {
    return Object.keys(root.installedPlugins);
  }

  // Get enabled plugin IDs only
  function getEnabledPluginIds() {
    return Object.keys(root.pluginStates).filter(function (id) {
      return root.pluginStates[id].enabled === true;
    });
  }

  // Increment plugin load version (for cache busting when plugin is updated)
  function incrementPluginLoadVersion(pluginId) {
    var versions = Object.assign({}, root.pluginLoadVersions);
    versions[pluginId] = (versions[pluginId] || 0) + 1;
    root.pluginLoadVersions = versions;
    Logger.d("PluginRegistry", "Incremented load version for", pluginId, "to", versions[pluginId]);
    return versions[pluginId];
  }

  // Get plugin directory path
  function getPluginDir(pluginId) {
    return root.pluginsDir + "/" + pluginId;
  }

  // Get plugin settings file path
  function getPluginSettingsFile(pluginId) {
    return root.pluginSettingsDir + "/" + pluginId + "/settings.json";
  }

  // Validate manifest
  function validateManifest(manifest) {
    if (!manifest) {
      return {
        valid: false,
        error: "Manifest is null or undefined"
      };
    }

    var required = ["id", "name", "version", "author", "description"];
    for (var i = 0; i < required.length; i++) {
      if (!manifest[required[i]]) {
        return {
          valid: false,
          error: "Missing required field: " + required[i]
        };
      }
    }

    if (!manifest.entryPoints) {
      return {
        valid: false,
        error: "Missing 'entryPoints' field"
      };
    }

    // Check version format (simple x.y.z check)
    var versionRegex = /^\d+\.\d+\.\d+$/;
    if (!versionRegex.test(manifest.version)) {
      return {
        valid: false,
        error: "Invalid version format (must be x.y.z)"
      };
    }

    return {
      valid: true,
      error: null
    };
  }
}
