# Screenshot Plugin

A simple screenshot plugin for Diutalia Shell that provides a button in the bar to quickly take screenshots. Automatically detects your compositor and uses the appropriate tool.

## Features

- **Quick Screenshot**: One-click screenshot button in the bar
- **Compositor Detection**: Automatically detects Hyprland, Sway, or Niri and uses the appropriate tool
- **Two Modes** (Hyprland only): Choose between region selection or direct full screen capture
- **Clipboard Integration**: Screenshots are automatically copied to clipboard
- **Silent Operation**: Runs silently without notifications

## Requirements

- **Hyprland**: 
  - **hyprshot** - The screenshot tool
    - Install via package manager: `hyprshot`
- **Niri**: 
  - Built-in screenshot functionality (no additional tools required)
- **Sway**:
  - **grimshot** - Screenshot helper script for wlroots compositors
    - Usually provided by `sway-contrib` or your distro's Sway extras package
- Diutalia 3.6.0 or later

## Installation

1. Copy this plugin to your Diutalia plugins directory:
   ```bash
   cp -r screenshot ~/.config/diutalia/plugins/
   ```

2. Add the widget to your bar through Diutalia settings

## Usage

### Bar Widget

- **Left Click**: Take a screenshot (mode depends on configuration)
- **Right Click**: Open plugin settings

### Configuration

**Hyprland and Sway**: Configure the screenshot mode through the settings panel:

- **Region Selection**: Opens a region selector to capture a specific area
- **Full Screen**: Captures the entire screen directly

**Niri**: Uses the built-in screenshot functionality (no configuration needed).

When clicked, the plugin will:
1. Detect your compositor (Hyprland, Sway, or Niri)
2. Use the appropriate tool:
   - **Hyprland**: `hyprshot` with the selected mode
  - **Sway**: `grimshot copy <area|screen|window>`
   - **Niri**: `niri msg action screenshot`
3. Copy the screenshot to clipboard
4. Run silently without notifications

### IPC Commands
Control the plugin via command line:
```bash
# Screenshot of screen
qs -c diutalia-shell ipc call plugin:screenshot takeScreenshot output

# Screenshot of window
qs -c diutalia-shell ipc call plugin:screenshot takeScreenshot window

# Screenshot of region
qs -c diutalia-shell ipc call plugin:screenshot takeScreenshot region
```

## License

MIT License
