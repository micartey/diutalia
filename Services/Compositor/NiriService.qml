import QtQuick
import Quickshell
import qs.Commons

Item {
  id: root

  property ListModel workspaces: ListModel {}
  property var windows: []
  property int focusedWindowIndex: -1
  property bool overviewActive: false
  property var keyboardLayouts: []
  property var outputCache: ({})
  property var workspaceCache: ({})

  signal workspaceChanged
  signal activeWindowChanged
  signal windowListChanged
  signal displayScalesChanged

  function initialize() {
    Logger.i("NiriService", "Using niri msg action backend");
  }

  function dispatch(args) {
    Quickshell.execDetached(["niri", "msg", "action"].concat(args));
  }

  function switchToWorkspace(workspace) {
    dispatch(["focus-workspace", workspace.idx.toString()]);
  }

  function scrollWorkspaceContent(direction) {
    dispatch([direction < 0 ? "focus-column-left" : "focus-column-right"]);
  }

  function focusWindow(window) {
    dispatch(["focus-window", "--id", window.id.toString()]);
  }

  function closeWindow(window) {
    dispatch(["close-window", "--id", window.id.toString()]);
  }

  function turnOffMonitors() {
    dispatch(["power-off-monitors"]);
  }

  function turnOnMonitors() {
    dispatch(["power-on-monitors"]);
  }

  function logout() {
    dispatch(["quit", "--skip-confirmation"]);
  }

  function cycleKeyboardLayout() {
    dispatch(["switch-layout", "next"]);
  }

  function getFocusedScreen() {
    return null;
  }

  function spawn(command) {
    dispatch(["spawn", "--"].concat(command));
  }
}
