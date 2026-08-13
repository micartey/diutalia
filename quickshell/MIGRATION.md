# Quickshell Fork Findings and Migration Notes

Status: 2026-08-13

This document explains why Diutalia currently builds the bundled `quickshell/`
source, which downstream changes are required by shell code, and what must change
before replacing it with upstream Quickshell.

Repository paths below are relative to Diutalia repository root.

## Summary

Diutalia cannot currently replace its bundled Quickshell with an unmodified
upstream package. Shell QML directly uses several APIs absent from upstream:

- `PwAudioSpectrum`
- inverted `Region` corners through `CornerState`
- `Quickshell.DWL`
- `flushWaylandState()`

Diutalia also applies a PipeWire channel-map patch while packaging Quickshell.

`ext-background-effect-v1` was an original reason for the fork, but current
upstream Quickshell now includes that protocol and its `BackgroundEffect` QML
API. Background blur alone therefore no longer requires the fork.

Long-term recommendation: pin upstream Quickshell and maintain a small, explicit
patch series instead of keeping a full source copy. Moving to completely stock
Quickshell first requires removing or replacing every dependency listed below.

## Comparison Scope

Findings were checked against:

- bundled source in `quickshell/`, reporting project version `0.0.12`
- archived `noctalia-dev/noctalia-qs` fork, tip `606adedb`
- upstream `quickshell-mirror/quickshell`, tip `28771c7c`

Those remote revisions describe comparison state on date above and will become
stale. Bundled source does not record an exact source revision and is not equal
to archived fork tip. Some later `noctalia-qs` fixes are missing locally. Any
migration must compare actual bundled files, not assume archived fork history is
fully present.

At comparison time, archived fork and upstream had diverged from merge base
`92b336c8`: fork was 39 commits ahead and 52 commits behind upstream.

## Required Downstream APIs

### PipeWire Audio Spectrum

Diutalia creates `PwAudioSpectrum` in:

- `Services/Media/SpectrumService.qml:40`

Implementation lives in:

- `quickshell/src/services/pipewire/spectrum.cpp`
- `quickshell/src/services/pipewire/spectrum.hpp`
- `quickshell/src/services/pipewire/CMakeLists.txt`

This type captures PipeWire audio, calculates FFT bands, and feeds visualizers
used by bar widgets, media cards, lock screen, desktop widgets, and plugins.
Current upstream Quickshell has no `PwAudioSpectrum` type or spectrum source.

Impact of stock upstream: `SpectrumService.qml` fails to instantiate, breaking
all features depending on `SpectrumService`.

Migration choices:

1. Upstream `PwAudioSpectrum` and wait for a release containing it.
2. Carry spectrum implementation as a downstream patch.
3. Move spectrum capture to a separate helper such as Cava and rewrite
   `SpectrumService.qml`.
4. Remove built-in visualizer support.

### Inverted Region Corners

Bundled Quickshell replaces upstream per-corner radius overrides with corner
states:

- `CornerState.Flat`
- `CornerState.Normal`
- `CornerState.InvertX`
- `CornerState.InvertY`
- `Region.topLeftCorner`
- `Region.topRightCorner`
- `Region.bottomLeftCorner`
- `Region.bottomRightCorner`

Implementation lives in:

- `quickshell/src/core/region.hpp:48`
- `quickshell/src/core/region.cpp`

Diutalia uses these properties for precise blur regions in:

- `Modules/MainScreen/MainScreen.qml:213`
- `Modules/MainScreen/MainScreen.qml:244`
- `Modules/Panels/Launcher/LauncherOverlayWindow.qml:53`

Current upstream supports normal rounded corners with independent corner radii,
but not inverted arcs or `CornerState`.

Impact of stock upstream: QML reports unknown properties/types. Replacing values
with normal radii would load, but blur masks would no longer follow Diutalia's
inverted visual geometry.

Migration choices:

1. Upstream generalized inverted-corner support.
2. Carry current `Region` changes as a downstream patch.
3. Rewrite blur masks as combinations of standard `Region` primitives.
4. Accept simpler normal-corner blur masks.

### DWL/Mango Integration

Bundled Quickshell adds `Quickshell.DWL`, implementing
`dwl-ipc-unstable-v2`. Diutalia uses it in:

- `Services/Compositor/MangoService.qml:3`
- `Services/Compositor/MangoService.qml:63`
- `Services/Compositor/MangoService.qml:337`

Implementation lives in:

- `quickshell/src/wayland/dwl/`

Current upstream has no `Quickshell.DWL` module.

Impact of stock upstream: `MangoService.qml` cannot import or instantiate. Since
`CompositorService.qml` declares `MangoService` as a component, missing import
may affect shell loading even when another compositor is active.

Migration choices:

1. Upstream DWL module.
2. Carry module as a downstream patch.
3. Replace module with an external Mango/DWL IPC helper.
4. Remove Mango support and references before switching.

Bundled source also contains `Quickshell.Niri`, but current
`Services/Compositor/NiriService.qml` uses `niri msg` and does not import that
module. Fork Niri module appears removable after confirming no plugin or dynamic
component imports it.

### Explicit Wayland State Flush

Bundled Quickshell adds:

- `ProxyWindowBase.requestUpdate()`
- `ProxiedWindow.flushWaylandState()`

Implementation lives in:

- `quickshell/src/window/proxywindow.hpp:153`
- `quickshell/src/window/proxywindow.cpp:514`
- `quickshell/src/window/proxywindow.cpp:659`

Diutalia calls it in:

- `Modules/MainScreen/SmartPanel.qml:296`
- `Modules/MainScreen/SmartPanel.qml:325`

Calls force pending double-buffered Wayland state, especially blur-region
changes, to commit when render loop has stopped receiving frame callbacks.

Current upstream exposes `updatesEnabled`, but not `requestUpdate()` or
`flushWaylandState()`.

Impact of stock upstream: `Window.window?.flushWaylandState()` still attempts to
call missing method when `Window.window` exists, causing a runtime error. Removing
calls risks stale blur after panels close, particularly after launching an app.

Migration choices:

1. Upstream a supported window update/commit API.
2. Carry current methods as a downstream patch.
3. Rework panel closing so another render update reliably commits blur state.

### PipeWire Default Channel Map

Outer flake applies an additional patch in:

- `flake.nix:47`

Patch fills default channel layouts when `pw-pulse` reports volumes without
`SPA_PROP_channelMap`. This keeps channel and volume lists aligned for mono,
stereo, and common surround layouts.

This change is not stored directly in `quickshell/`; Nix applies it during build.
Switching Quickshell source without preserving or revalidating patch can regress
audio controls on affected PipeWire setups.

Migration requirement: test patch against chosen upstream revision, check for an
equivalent upstream fix, then either retain or remove it explicitly.

## No Longer Fork Blockers

### Background Effect Protocol

Fork README identifies `ext-background-effect-v1` as primary extension. Diutalia
uses `BackgroundEffect.blurRegion` in:

- `Modules/MainScreen/MainScreen.qml:203`
- `Modules/Dock/Dock.qml:865`
- `Modules/Panels/Launcher/LauncherOverlayWindow.qml:43`

Current upstream now includes `src/wayland/background_effect/` and exports same
`BackgroundEffect` API through `Quickshell.Wayland`. This feature must still be
tested against target compositor and `wayland-protocols` version, but no longer
requires downstream implementation.

### Niri IPC

Fork contains a native `Quickshell.Niri` module. Current shell backend instead
runs `niri msg` from `Services/Compositor/NiriService.qml`. Native module does not
appear to be a current runtime requirement.

### Branding and Packaging

Fork changes application name, app ID, crash URL, desktop file, icon, Nix flake,
and package metadata. Relevant examples:

- `quickshell/CMakeLists.txt:13`
- `quickshell/CMakeLists.txt:176`
- `quickshell/src/launch/main.cpp:108`
- `quickshell/src/launch/launch.cpp:134`
- `quickshell/nix/package.nix`

These changes improve attribution, crash routing, and integration but do not
require maintaining a source fork. Most can become package flags, small patches,
or wrapper configuration.

## Other Fork Changes To Audit

Fork history and current source contain more changes than README documents.
These are not all proven hard dependencies, but migration should test affected
behavior before dropping them:

- expanded NetworkManager QML API and connection/settings handling
- optional IPC function arguments
- MPRIS artwork preservation when same-track metadata omits `mpris:artUrl`
- PipeWire lifecycle and disconnect safety fixes
- layer-shell null checks and window visibility fixes
- Hyprland IPC lifecycle hardening
- object-model reorder handling
- Bluetooth rfkill unblocking
- Nix build and file-watcher changes

Important: bundled copy predates some later archived-fork fixes. For example,
local Bluetooth code still rejects enabling an rfkill-blocked adapter, and local
PipeWire pointers do not include later `QPointer` conversion. Do not describe all
archived `noctalia-qs` commits as present in Diutalia.

Current shell uses only `Networking.wifiEnabled` directly from
`Quickshell.Networking`; most network operations run through `nmcli`. Expanded
fork networking API may therefore be removable, but only after runtime testing.

## Why A Distribution Quickshell Package Is Risky

Even after removing fork APIs, selecting arbitrary system `quickshell` remains
risky:

- Quickshell uses Qt private APIs and must match distribution Qt version.
- QML APIs evolve between Quickshell snapshots.
- required modules depend on package build options.
- compositor protocol support depends on package and `wayland-protocols` age.

Prefer one pinned Quickshell revision built against same Nixpkgs Qt stack as
Diutalia. Do not silently accept whichever `qs` binary is first in `PATH`.

## Recommended Target

Replace full vendored source with:

1. pinned upstream Quickshell source
2. small patch directory with one concern per patch
3. explicit package flags and branding configuration
4. compatibility test matrix
5. documented upstream issue or pull request for each long-lived patch

Initial minimum patch set likely contains:

1. `PwAudioSpectrum`
2. inverted `Region` corners
3. DWL support, unless removed or externalized
4. explicit Wayland state flush
5. PipeWire default channel-map fallback, unless upstream fixed

Keep unrelated bug fixes only when reproducible against chosen upstream revision.
New upstream may already contain equivalent fixes implemented differently.

## Migration Plan

### Phase 1: Establish Baseline

1. Record exact bundled source origin or mark it permanently unknown.
2. Pin one upstream Quickshell commit, not floating `master`.
3. Build upstream unchanged against current Nixpkgs and Qt.
4. Capture QML load errors and map each to list above.

### Phase 2: Reduce Delta

1. Remove unused native Niri module.
2. Decide whether Mango/DWL remains supported.
3. Move branding and package-only changes out of source where possible.
4. Rebase required feature patches individually onto pinned upstream.
5. Drop historical fixes already present upstream.

### Phase 3: Adapt Shell

1. Port region masks to upstream API or retain inverted-corner patch.
2. Replace `flushWaylandState()` calls only after proving blur commits reliably.
3. Replace spectrum implementation or retain spectrum patch.
4. Remove `Quickshell.DWL` import only after Mango replacement/removal.

### Phase 4: Verify

Run at least:

```sh
nix build .#
```

Then test:

- shell startup and reload
- bar, panels, dock, launcher, and lock screen
- blur region opening, animation, immediate closing, and closing after app launch
- normal, flat, and inverted corner masks on every bar position
- audio output/input volume and mute
- audio visualizers while idle, playing, changing default sink, and disconnecting Bluetooth audio
- Wi-Fi enable/disable, scan, connect, disconnect, forget, and airplane mode
- Bluetooth enable after rfkill block, pairing, connection, and device removal
- media metadata and artwork updates
- IPC calls with zero, full, and omitted optional arguments
- Hyprland, Niri, Sway, and Mango/DWL backends claimed as supported
- monitor hotplug, scale changes, and shell reload
- crash reporting destination and application ID

### Phase 5: Remove Vendored Tree

Remove `quickshell/` only after patched upstream build passes full matrix and
normal package path is sole implementation used by development shell, NixOS
module, Home Manager module, and release package.

## Decision Record

Current decision: keep custom Quickshell build.

Reason: stock upstream lacks APIs directly referenced by current shell QML.

Preferred future decision: use pinned upstream plus minimal patches, then continue
shrinking patch set as features move upstream or shell dependencies are removed.
