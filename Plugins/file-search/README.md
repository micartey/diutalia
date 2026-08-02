# File Search Plugin

File search from the launcher.

## Requirements

This plugin requires [fd](https://github.com/sharkdp/fd#installation) to be installed.

## Usage

**Access from launcher:**

Type `>file` in the Diutalia launcher to activate file search.

**Toggle file search:**

```bash
diutalia-shell ipc call plugin:file-search toggle
```

**Search with pre-filled query:**

```bash
diutalia-shell ipc call plugin:file-search search "eko"
```
