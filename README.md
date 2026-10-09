# Gabibou UI

A customizable Luau interface library with a black, gray and white default theme. Build a window, add controls, then customize its appearance when needed.

## Start with one line

In a client environment that supports `loadstring` and `game:HttpGet`, load the current source from GitHub:

```lua
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/Gabibou455/GabibouUI/main/gabibou_ui.luau'))()
```

The `main` URL follows repository updates. To keep a project on a fixed version, replace `main` with a published release tag from the [Releases page](https://github.com/Gabibou455/GabibouUI/releases).

## Create a window

```lua
local window = UI:CreateWindow('My project')
local tab = window:Tab('Home', 'home')
tab:Button('Hello', function()
    print('Hello!')
end)
```

The title-first API accepts simple arguments for common controls. Tables remain available for options and advanced configuration. For example, `tab:Toggle('Effects', function(enabled) print(enabled) end)` creates a toggle that starts off. See the [live documentation](https://gabibou-ui.mintlify.app) for the [quickstart](https://gabibou-ui.mintlify.app/getting-started/quickstart), [controls](https://gabibou-ui.mintlify.app/customization/controls), and [appearance options](https://gabibou-ui.mintlify.app/customization/appearance-and-layout).

## Roblox Studio

For a standard Roblox Studio client script, place the standalone source in a `ModuleScript` named `GabibouUI` under `ReplicatedStorage`, then load it with `require`:

```lua
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UI = require(ReplicatedStorage:WaitForChild('GabibouUI'))
```

Studio client scripts do not provide the remote `loadstring(game:HttpGet(...))` pattern. See the [Studio installation guide](https://gabibou-ui.mintlify.app/getting-started/installation) for setup details.

## Documentation and examples

The [live developer documentation](https://gabibou-ui.mintlify.app) covers controls, appearance, layouts, loading screens, values, and extension hooks. Repository references and examples:

| Resource | Purpose |
|---|---|
| [API guide](gabibou_ui/README.md) | Installation, controls and public API |
| [Customization](gabibou_ui/CUSTOMIZATION.md) | Layouts, animations and extension hooks |
| [Icon IDs](gabibou_ui/ICONS.md) | Icon names and numeric IDs |
| [Icon browser](GabibouUI_Icons/index.html) | Offline search, variants, PNG and SVG files |
| [Demo](gabibou_ui/demo.luau) | Interactive component and icon gallery |
| [Quick start](gabibou_ui/quickstart.luau) | Small Studio example |
| [Loading example](gabibou_ui/loading_example.luau) | Layouts, custom content and animation |
| [Key and Discord example](gabibou_ui/key_discord_example.luau) | Access screen and Discord copy button |
| [Remote example](gabibou_ui/remote_example.luau) | Remote loading with explicit errors |
| [Publishing guide](PUBLISHING.md) | Repository, version tags and releases |

Download `GabibouUI.zip` from the [GitHub Releases page](https://github.com/Gabibou455/GabibouUI/releases), then open `GabibouUI_Icons/index.html` locally to use the icon browser. Its HTML is an offline tool; the GitHub file view does not run it.

## Source layout

`gabibou_ui.luau` is the standalone library. The `gabibou_ui` folder contains its source modules and examples. After editing source modules, rebuild from the repository root with:

```sh
node gabibou_ui/build.cjs
```

Node.js is a build dependency; scripts that load the standalone library do not need it. PNG/SVG assets are optional at runtime because the native icon renderer does not download images.

## License

MIT. See [LICENSE](LICENSE). The library and its catalogue drawings are original to this project. The Discord mark is covered separately in [THIRD_PARTY.md](THIRD_PARTY.md).
