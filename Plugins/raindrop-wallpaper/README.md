# Raindrop Wallpaper

Rain behind a glass window over the wallpaper managed by Diutalia. Clear,
liquid-glass-inspired droplets bend the wallpaper near their edges, with purple-blue
iridescent rims, broad colored reflections, bright white ribbons, and chromatic fringes.

## Features

- Three scales of circular glass beads, without pointed or stretched teardrop shapes.
- Fast falling rain in two background depth layers.
- Fresh impacts appear and fade continuously; larger droplets accelerate down the glass.
- Actual wallpaper sampling through curved droplet surfaces, not painted white streaks.
- Independent speed controls for background rain and large sliding window droplets.
- Configurable rain density, opacity, droplet size, refraction, glass intensity, lifetime, hit percentage, and background rain visibility.
- Click-through overlay on every connected monitor, below normal application windows.
- Stops rendering while locked, in performance mode, or when wallpaper is disabled.
- GPU shader bundled with the plugin; no runtime compiler or external processes.

## Usage

This plugin is bundled under `Plugins/raindrop-wallpaper/`. Restart Diutalia from
this source tree, then enable **Raindrop Wallpaper** in Settings > Plugins.
Wallpaper must be enabled. Open plugin settings to adjust the effect and save.

Recommended starting values: density 100, opacity 85%, size 1x, refraction 0.7.
Glass intensity defaults to 1.5x. Increase it toward 3x for stronger purple, blue,
and white reflections; set it to zero for clear, untinted lenses. Color follows
the droplet curvature rather than tinting the whole wallpaper.
Reflections use bounded blending so bright wallpapers retain their colors and
detail instead of turning into white blobs.
Default droplet lifetime is 3 seconds, window hit chance is 35%, and background
rain visibility is 65%. Try lifetime 1.5 seconds and speed 1.5x for a lively shower.
**Window droplet speed** controls the larger sliding layer independently of
background rain and smaller impacts. Set it to 0x to freeze just that layer, or
try 0.3x for a slow glide. Its appearance/fade cycle slows with the layer as well.
Set both rain speed and window droplet speed to zero to freeze the whole effect.

**Hit window percentage** controls the probability that an eligible rain event
becomes a window droplet, after the density setting is applied. At 0%, only
background rain remains. At 100%, every eligible event hits. Background particles
and glass impacts are separate procedural layers, not a physical collision simulation.
Set background rain to 0% to show glass droplets alone.

This Diutalia version discovers plugins inside its shell directory's `Plugins/`
folder; the user config directory stores settings, not plugin code.

```sh
qs -c diutalia-shell ipc call plugin:raindrop-wallpaper toggle
```

The toggle persists across restarts. Disabling the plugin removes its overlay
without changing wallpaper settings.

## Rendering

Requires Wayland layer-shell and a Qt Quick GPU rendering backend. The transparent
bottom-layer surface only draws rain and droplets; the actual background stays managed by
Diutalia. Refraction samples the current wallpaper image using Diutalia's center,
crop, fit, stretch, or repeat mapping. Solid-color wallpapers also work.

Wallpaper changes update the sampled image asynchronously. Refraction inside
droplets is not synchronized with Diutalia's animated wallpaper transitions, and
does not capture transformations from other wallpaper plugins or video wallpapers.
Desktop widgets share the bottom layer; surface ordering depends on the compositor.

## Development

Rebuild the bundled shader after editing its source:

```sh
qsb --qt6 --qsbversion 64 -o Plugins/raindrop-wallpaper/shaders/wet-glass.frag.qsb Plugins/raindrop-wallpaper/shaders/wet-glass.frag
```

Run the standalone smoke test with Qt 6's `qml` tool and an existing output directory:

```sh
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=rhi QSG_RHI_BACKEND=opengl qml Plugins/raindrop-wallpaper/tests/WetGlassSmoke.qml -- /tmp/opencode
```

The test checks independent rain/window clocks and renders wallpaper-backed and solid-color droplets, background-only rain,
glass-only droplets, and an empty overlay. It checks transparency, freeze/animation,
droplet renewal, zero/100% hit chance, colored/untinted glass, and purple-blue-white
reflections on a neutral background, and writes PNGs for visual inspection.
The separate refraction regression test uses a high-contrast checkerboard to
verify that changing refraction actually changes wallpaper pixels, and that
maximum glass intensity does not wash out more than 5% of covered pixels. It also
checks rendered droplet bounds for circular shapes:

```sh
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=rhi QSG_RHI_BACKEND=opengl qml Plugins/raindrop-wallpaper/tests/RefractionSmoke.qml -- /tmp/opencode
```

Qt Quick's `software`
backend does not render ShaderEffect; use OpenGL or Vulkan (software GPU drivers
such as llvmpipe also work). Verify click-through, multi-monitor layering,
lock-screen suspension, and settings persistence in a running Diutalia session.
