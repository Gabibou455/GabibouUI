# Gabibou UI

A customizable Luau interface library with a black, gray and white default theme. Built for readable controls, flexible layouts and developers who want to make the interface their own.

**Version 1.5.0-rc.4 is a local, unreleased candidate.** This source includes four lifecycle corrections for library-managed callbacks, loader error handling, launch teardown, and key cancellation. The public `v1.5.0-rc.3` tag remains the version used in the loadstring example below; that remote source does not include these local rc.4 changes. Review [QUALITY.md](QUALITY.md) for this local candidate's verified checks and known limits.

## Load from GitHub

In a client environment that supports `loadstring` and `game:HttpGet`:

```lua
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Gabibou455/GabibouUI/v1.5.0-rc.3/gabibou_ui.luau"))()
local window = UI:CreateWindow({Title = "My project", Theme = "Graphite"})
local tab = window:Tab({Title = "Settings", Icon = "settings"})
tab:Toggle({Id = "effects", Title = "Effects", Value = true, Callback = function(enabled)
    print("Effects", enabled)
end})
```

The example pins the published `v1.5.0-rc.3` tag so later changes on `main` do not silently change the interface used by your script. This local guide describes rc.4 candidate fixes that are not in the pinned remote file. The repository is configured for the GitHub owner `Gabibou455`; check Releases for future publication status. The [remote example](gabibou_ui/remote_example.luau) includes clearer fetch and compile errors.

Standard Roblox Studio client scripts use `ModuleScript` and `require`; they do not support this remote `loadstring` pattern. Follow the [Studio installation guide](gabibou_ui/README.md#installation-and-quick-start) for that environment.

## What you can customize

- Colors, fonts, corner radii, spacing and motion, including reduced motion.
- Left, right, top or bottom navigation, with independent mobile layout settings.
- Tabs, sections, buttons, toggles, sliders, dropdowns, inputs, keybinds and color pickers.
- Loading screens, progress, player avatar branding, notifications and key validation callbacks.
- Native icons by name or stable numeric ID, in Outline, Soft and Duotone styles.
- Custom components, icon builders, callbacks and animation hooks.

The library does not automate gameplay. Developers connect controls to their own project logic.

## Documentation and examples

Start with the [complete developer guide](gabibou_ui/DEVELOPER_GUIDE.md): one small working interface first, then every customization option.

| Resource | Purpose |
|---|---|
| [API guide](gabibou_ui/README.md) | Installation, controls and public API |
| [Customization](gabibou_ui/CUSTOMIZATION.md) | Layouts, animations and extension hooks |
| [Icon IDs](gabibou_ui/ICONS.md) | Every icon name and numeric ID |
| [Icon browser](GabibouUI_Icons/index.html) | Offline search, variants, PNG and SVG files |
| [Demo](gabibou_ui/demo.luau) | Interactive component and icon gallery |
| [Quick start](gabibou_ui/quickstart.luau) | Small Studio example |
| [Loading example](gabibou_ui/loading_example.luau) | Three layouts, custom content and owned animation |
| [Key and Discord example](gabibou_ui/key_discord_example.luau) | Access screen and a configurable Discord copy button |
| [Remote example](gabibou_ui/remote_example.luau) | Remote loading with explicit errors |
| [Publishing guide](PUBLISHING.md) | Repository, version tag and release steps |
| [Mintlify documentation](gabibou_ui/mintlify/README.md) | English pages and navigation ready for a documentation site |

Download the release ZIP and open `GabibouUI_Icons/index.html` locally to use the icon browser. Its HTML is an offline tool; the GitHub file view does not run it.

## Source layout

`gabibou_ui.luau` is the standalone library. The `gabibou_ui` folder contains its source modules and examples. After editing source modules, rebuild from the repository root with:

```sh
node gabibou_ui/build.cjs
```

Node.js is a build dependency; scripts that load the standalone library do not need it. PNG/SVG assets are optional at runtime because the native icon renderer does not download images.

## License

MIT. See [LICENSE](LICENSE). The library and its 96 catalogue drawings are original to this project. The Discord mark is covered separately in [THIRD_PARTY.md](THIRD_PARTY.md).
