pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Singleton {
  id: root

  property string supporterDataFile: Settings.cacheDir + "supporters.json"
  property bool isInitialized: false

  readonly property alias data: adapter

  property var supporters: []
  property var cachedAvatars: ({}) // username -> file:// path
  property bool avatarsCached: false

  FileView {
    id: supporterDataFileView
    path: supporterDataFile
    printErrors: false
    watchChanges: false

    onLoaded: {
      if (!root.isInitialized) {
        root.isInitialized = true;
        loadFromCache();
      }
    }
    onLoadFailed: function (error) {
      root.isInitialized = true;
    }

    JsonAdapter {
      id: adapter
      property var supporters: []
      property real timestamp: 0
    }
  }

  function init() {
    Logger.i("Supporter", "Service started");
  }

  function loadFromCache() {
    Logger.i("Supporter", "Using cached supporter data");

    if (data.supporters && data.supporters.length > 0) {
      root.supporters = data.supporters;
      Logger.d("Supporter", "Loaded", data.supporters.length, "supporters from cache");
    }

  }

  function saveData() {
    data.timestamp = Time.timestamp;
    Quickshell.execDetached(["mkdir", "-p", Settings.cacheDir]);

    try {
      supporterDataFileView.writeAdapter();
      Logger.d("Supporter", "Cache file written successfully");
    } catch (error) {
      Logger.e("Supporter", "Failed to write cache file:", error);
    }
  }

  function getAvatarPath(username) {
    return cachedAvatars[username] || "";
  }

  function cacheAvatars() {
    if (supporters.length === 0)
      return;

    avatarsCached = true;

    for (var i = 0; i < supporters.length; i++) {
      var supporter = supporters[i];
      var username = supporter.github_username;

      // Only cache avatars for supporters with GitHub accounts
      if (!username)
        continue;

      var avatarUrl = "https://github.com/" + username + ".png?size=256";

      (function (uname, url) {
        ImageCacheService.getCircularAvatar(url, "supporter_" + uname, function (cachedPath, success) {
          if (success) {
            cachedAvatars[uname] = "file://" + cachedPath;
            cachedAvatarsChanged();
          }
        });
      })(username, avatarUrl);
    }
  }

  onSupportersChanged: {
    if (supporters.length > 0 && !avatarsCached && ImageCacheService.initialized) {
      Qt.callLater(cacheAvatars);
    }
  }

  Connections {
    target: ImageCacheService
    function onInitializedChanged() {
      if (ImageCacheService.initialized && supporters.length > 0 && !avatarsCached) {
        Qt.callLater(cacheAvatars);
      }
    }
  }

}
