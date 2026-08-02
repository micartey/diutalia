import QtQuick

QtObject {
  function migrate(adapter, logger, rawJson) {
    logger.i("Settings", "Skipping retired color scheme migration");
    return true;
  }
}
