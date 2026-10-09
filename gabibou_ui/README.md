# Gabibou UI 1.5.0-rc.3

A Roblox interface library written in Luau. Version 1.5.0-rc.3 includes 96 original vector icons in three styles, continuous rounded strokes, and an expanded mobile-friendly gallery. Navigation offers three variants, and buttons can display icons. The demo includes an interactive gallery and a visual Farm template. The library retains configurable layouts, notifications, the key screen, and `Launch` orchestration. Graphite remains the default black, gray, and white theme.

> The library is under active development, so its API may change. This guide describes implementation 1.5.0-rc.3.

Start with the [Developer Guide](DEVELOPER_GUIDE.md) for installation and a complete feature map. Use [CUSTOMIZATION.md](CUSTOMIZATION.md) for advanced styling, custom controls, events, and animations.

## Remote loading from GitHub

For client environments that expose `loadstring` and `game:HttpGet`, load the standalone module without installing it:

```lua
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Gabibou455/GabibouUI/v1.5.0-rc.3/gabibou_ui.luau"))()
```

This URL is for client environments that support both APIs; it is not a standard Studio loading method. See [remote_example.luau](remote_example.luau) for fetch and compile error handling. Studio client scripts use the `ModuleScript` installation below. Repository and release instructions are in [PUBLISHING.md](../PUBLISHING.md).

## Installation and quick start

1. Create a `ModuleScript` named `GabibouUI` in `ReplicatedStorage` and copy the standalone module [`../gabibou_ui.luau`](../gabibou_ui.luau) into it.
2. To enable the sample key gate, copy [`key_server.example.luau`](key_server.example.luau) into a `Script` under `ServerScriptService`. Replace `CHANGE_ME` with your private keys. While the marker remains unchanged, the sample rejects every key.
3. Add [`starter.luau`](starter.luau) as a `LocalScript` under `StarterPlayerScripts`. It calls `GabibouValidateKey` on the server and starts the interface after validation. For an interface without a key, use the `UI:Create` example below directly.

The server script limits each player to one attempt every 2 seconds, rejects keys longer than 256 bytes, and sets the server-side `GabibouAuthorized` attribute after accepting a key. Check this attribute on the server for every protected action. Never put private keys in a `LocalScript`.

The startup example without a gate:

```lua
local UI = require(game:GetService("ReplicatedStorage"):WaitForChild("GabibouUI"))
local window = UI:Create({
    Id = "MyInterface", Title = "My project", Subtitle = "Settings",
    Branding = {Mode = "Avatar", Placement = "BothRight"},
    Loading = {Title = "My project", Subtitle = "Preparing settings", Logo = "Avatar", MinimumDuration = 0.6},
    Tabs = {{Title = "Settings", Icon = "settings", Sections = {{Title = "Display", Controls = {
        {Type = "Toggle", Id = "effects", Title = "Effects", Value = true},
        {Type = "Slider", Id = "volume", Title = "Volume", Min = 0, Max = 100, Value = 50},
    }}}}},
})
window:Get("effects"):On("Changed", function(value) print("Effects", value) end)
window:SetValues({effects = true, volume = 75})
```

This example is also in [`quickstart.luau`](quickstart.luau). `UI:Create(schema)` takes window options at the root, along with `Tabs` and `Loading`. It validates the schema and control IDs before creating the interface. Every declarative control must have a unique, nonempty `Id` of at most 96 characters, with no control characters. Controls created through the direct API `window:Tab():Section():Toggle()` keep their existing behavior and can still receive automatically generated IDs.

`PlayerGui` is used by default. Window options include `Id`, `Title`, `Subtitle`, `Theme`, `Style`, `Motion`, `Responsive`, `Layout`, `Navigation`, `Notifications`, `Width`, `Height`, `Parent`, `DisplayOrder`, `ToggleKey`, `ReducedMotion`, `Storage`, and `Branding`. `Create` consumes `Tabs` and `Loading` and removes them before its internal call to `CreateWindow`. Reusing the same `Id` destroys the previous window as creation of the new one begins. If a `Custom` builder fails at runtime, the partial new interface is cleaned up; the previous window with that `Id` has already been replaced.

## Declarative controls

A control entry has a `Type` and an `Id`, followed by options specific to that control. Controls can be placed directly in `Tabs[n].Controls` or grouped under `Tabs[n].Sections[m].Controls`.

| `Type` | Main options | Callback value |
|---|---|---|
| `Paragraph` | `Title`, `Description` | — |
| `Button` | `Text`, `Callback` | no arguments |
| `Toggle` | `Value` (`boolean`) | new value |
| `Slider` | `Min`, `Max`, `Step`, `Value` | value clamped to the range and snapped to the step |
| `Dropdown` | `Options` (strings), `Value` | selected option |
| `ColorPicker` | `Value` (`#RRGGBB` or `Color3`), optional `Palette` | `#RRGGBB` string |
| `Input` | `Value`, `Placeholder`, `MaxLength` | text when focus is lost |
| `Keybind` | `Value` (key name or `Enum.KeyCode`) | key name when pressed |
| `Custom` | `Build`, `Height` | — |
| registered component | component name as `Type` | defined by its builder |

Common options are `Id`, `Type`, `Title`, `Description` (or `Desc`), `Disabled`, `Persistent`, and `Callback`. `Create` validates the shape and values before creating the window. Options specific to a registered component are then checked by its builder.

The procedural API is useful when creating controls in response to user activity: `window:Tab({Title = "Settings"})`, then `tab:Section({Title = "Display"})`, then `section:Toggle({...})`. It retains the methods shown in the demo and advanced guide.

## Values, profiles, and callbacks

`window:Get(id)` returns the associated control, or `nil` if the ID does not exist. `window:GetValues()` returns a new table containing the values of persistent controls. `window:SetValues(values, fireCallbacks)` rejects unknown or nonpersistent IDs and validates every value before changing any of them. After validation, it applies all values, then emits callbacks and `Changed` for values that actually changed.

```lua
local volume = window:Get("volume")
if volume then print(volume:Get()) end

local savedValues = window:GetValues()
local appliedCount = window:SetValues({effects = false, volume = 30}, false)
```

With `fireCallbacks = true`, callbacks are dispatched in sorted ID order. They run in protected tasks, so their actual execution order is not guaranteed. Without this option, the update is silent. `ExportConfig`, `ImportConfig`, `SaveConfig`, and `LoadConfig` remain available for JSON profiles. The library does not access disk implicitly; provide a `Storage` adapter for persistence.

Capturing a new key with `Keybind` updates its value and emits `Changed(newKey, oldKey)` without running the action `Callback`. The action runs when the assigned key is pressed outside of capture mode. Control callbacks are protected; an error is reported by notification and stored in `window.LastError`.

## Windows and profiles

The procedural window API remains available through `UI:CreateWindow(options)`. A window exposes methods including `Tab`, `SelectTab`, `SearchFor`, `SetSize`, `SetTheme`, `SetStyle`, `SetMotion`, `SetLayout`, `SetNotifications`, `SetReducedMotion`, `SetBranding`, `Hide`, `Show`, `Toggle`, `Notify`, `Confirm`, `OnDestroy`, and `Destroy`. `UI:DestroyAll()` destroys startup sessions, gates, windows, and loaders owned by that library instance.

JSON profiles use `ExportConfig`, `ImportConfig`, `SaveConfig`, and `LoadConfig`. No disk storage is implicit. For `SaveConfig` and `LoadConfig`, provide a `Storage` adapter with `Write(path, contents)` and `Read(path)`; Studio `LocalScripts` do not have `readfile` or `writefile`.

## Loading screen

`Loading` is optional. In `UI:Create`, pass `true` to use the defaults or provide a configuration table. The screen shows build progress and completes when the library has finished creating the tabs and controls.

The integrated loader inherits `Theme`, `Style`, `ReducedMotion`, and `Parent` from the window when they are not specified in `Loading`. Its `DisplayOrder` defaults to one greater than the window's. Destroying the window also closes its integrated loader, including during the minimum display time or exit transition.

For a network task or game-specific preparation, create a separate loader with `UI:CreateLoader(options)`, call `SetProgress(ratio, status)` or `SetStatus(text)` according to actual progress, then call `Complete(status)` when the task is truly finished. `Destroy()` closes the loader manually without calling `OnComplete`.

`MinimumDuration` sets the minimum time to show the loader before it closes after `Complete`. It does not guarantee that a download or network operation has finished. A percentage does not represent game loading unless your code connects it to a real measurement. The loader also exposes `Update(options)` for applying validated partial options and `Run(steps)` for running dense, sequential steps. `Run` updates progress after each successful step; an error stops the sequence and calls `OnError(loader, title, index)` without completing the loader.

Loader options also include `Variant` (`Compact`, `Centered`, or `Minimal`), `ShowSubtitle`, `ShowPercentage`, `ShowLogo`, `ShowActivity`, `ProgressHeight` (2–12 px), `Height` (160–480 px), `Position`, `AnchorPoint`, `Padding`, `LogoSize`, and `BackgroundTransparency`. `Centered` defaults to 300 px high; other variants default to 216 px. At heights below 260 px, `Centered` uses compact layout. A partial `Update({Variant = "Centered"})` preserves the current height, so pass `Height = 300` too when switching a default compact loader to centered. `GetParts()` exposes the overlay, card, logo, text, progress elements, and a free `Content` frame. `SetPartLayout` and `ResetPartLayout` can reposition supported parts; `Own(resource)` registers cleanup for custom listeners and effects. See [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) for a complete customization example.

```lua
local loader = UI:CreateLoader({
    Title = "Preparing",
    OnError = function(loader, title, index)
        warn("Step failed", title, index)
    end,
})

loader:Run({
    {Title = "Reading preferences", Run = function(activeLoader)
        -- Load one real startup step here.
    end},
    {Title = "Preparing the interface", Run = function(activeLoader)
        -- Prepare the data needed by the interface.
    end},
})
```

`Run(steps)` returns the loader immediately and runs asynchronously. `Destroy()` interrupts any steps still in progress. On failure, the loader remains visible so your code can offer a retry or close it.

## Startup with a key

`UI:Launch(spec)` takes the window options and `Tabs` from `UI:Create`, then accepts `KeySystem`, `Loading`, `Steps`, `OnReady`, `OnError`, and `OnCancel`. The gate appears before the steps. When `Validate(key)` returns `true, result`, the gate is destroyed, the `Run(loader)` steps execute in order, and then the window is created. Steps without a `Loading` option create a default loader. Without a key or loading screen, the window starts without a loader.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local validateAccess = ReplicatedStorage:WaitForChild("ValidateAccess") -- RemoteFunction handled by the server

local session = UI:Launch({
    Id = "Settings",
    Title = "Settings",
    KeySystem = {
        Title = "Access",
        Validate = function(key)
            return validateAccess:InvokeServer(key)
        end,
    },
    Loading = {Title = "Preparing", MinimumDuration = 0.2},
    Steps = {{Title = "Reading preferences", Run = function(loader)
        -- Perform real startup work here. Progress advances after this step.
    end}},
    Tabs = {{Title = "Home", Icon = "home"}},
    OnReady = function(window, currentSession)
        print("Interface ready", currentSession.Status)
    end,
    OnError = function(message, currentSession)
        warn(message) -- generic message, with no exception details or key
    end,
    OnCancel = function(currentSession)
        print("Startup cancelled", currentSession.Status)
    end,
})
```

The session status is `WaitingForKey`, `Loading`, `Ready`, `Failed`, or `Destroyed`. The session exposes `Gate`, `Loader`, `Window`, `Cancel()`, and `Destroy()`. Cancellation destroys owned resources; `OnCancel(session)` is called by `Cancel()` or when the gate is cancelled. `OnError(message, session)` receives a generic message on failure. `OnReady(window, session)` is called only after the window is created.

The gate is a **client-side** interface, not a server authentication mechanism. An exploiter can modify or bypass a `LocalScript`. `Validate` should ask the server to check access; keep keys and secret rules on the server, and also validate every protected action on the server. See [Roblox: Securing the client-server boundary](https://create.roblox.com/docs/scripting/security/client-server-boundary).

For the optional Discord invite button, copy [`key_discord_example.luau`](key_discord_example.luau). It shows the `Discord` option and clipboard fallback. The UI does not contact Discord or validate an invite.

The key gate defaults to the local player's avatar (`Logo = "Avatar"`) and the button label `Verify key`. Set `Logo = false` to display `MarkText`, or pass an `rbxassetid://` URI for a custom image. `GetParts()` exposes `MarkImage` and `MarkText`. Its default width is 420 px. Automatic heights are 332 px without Discord or GetKey, 394 px with Discord, 404 px with GetKey, and 462 px with both. An explicit `Height` remains in effect when options are updated.

`GetKey` adds a separate key-provider action. Supply an HTTPS URL to copy it, or pass a callback for a custom action. If clipboard access is unavailable or copying fails, a URL configuration displays a selectable link. The dialog does not open the provider automatically. See [`key_discord_example.luau`](key_discord_example.luau).

## Layout

`Layout` sets defaults for future windows with `UI:SetLayout(options)` and controls an individual window's layout with `window:SetLayout(options)`. Options cover tab position, navigation, spacing, dimensions, and whether the header, search, and footer are shown. See [CUSTOMIZATION.md](CUSTOMIZATION.md) for all values and ranges. `window:GetParts()`, `SetPartLayout(name, options)`, and `ResetPartLayout(name)` provide advanced control over window parts.

## Notifications

`UI:SetNotifications(options)` sets defaults for future windows; `window:SetNotifications(options)` updates the current window. `window:Notify({Title, Content, Kind})` displays a toast. Built-in types are `info`, `success`, `warning`, and `error`, each with a native icon. See [CUSTOMIZATION.md](CUSTOMIZATION.md) for defaults, ranges, and dismissal methods.

## Navigation, icons, and branding

Choose `Navigation = {Variant = "Soft", IconVariant = "Outline"}` in `CreateWindow`, `Create`, or `Launch`. `window:SetNavigation(...)` applies partial options to the current window. `Soft` is the default, with nuanced surfaces; `Classic` keeps transparent navigation; `Pill` highlights the selected tab with a contrasting capsule. Each tab can pin its own `IconVariant`.

Every native icon has a stable ID: `Icon = 21` adds Farm and `Icon = 24` adds Harvest. Names remain supported. [ICONS.md](ICONS.md) lists all names and IDs and includes examples for tabs, buttons, and notifications. These are Gabibou UI IDs; no Roblox image asset is needed for the library icons.

The catalogue contains 96 native designs, including `farm`, `harvest`, `seed`, `sprout`, `inventory`, `watering-can`, `shovel`, `tools`, `tractor`, `map`, `minimize`, `restore`, and `resize`. `UI:GetIconNames()` returns the full list; `UI:GetIconVariants()` returns `Outline`, `Soft`, and `Duotone`. Use `UI:GetIconId(name)`, `UI:GetIconName(idOrName)`, and `UI:GetIconCatalogue()` to look up stable IDs and names. Window actions use these designs too. The demo's Farm template shows controls you can connect to your own code; it does not automate gameplay.

```lua
local farm = window:Tab({Title = "Farm", Icon = "farm", IconVariant = "Duotone"})
farm:Button({
    Title = "Harvest", Text = "Harvest", Icon = "harvest", IconVariant = "Soft",
    Callback = function() print("Connect your harvest action here") end,
})
window:SetNavigation({Variant = "Pill"})
```

`Tabs` contains tabs with a `Title`, an optional `Icon`, direct `Controls`, and `Sections`. Navigation shows the selected tab, hover, and focus states with consistent transitions. Built-in native icons also include `home`, `sliders`, `palette`, `save`, `code`, `search`, `close`, `check`, `chevron-down`, `chevron-right`, `settings`, `user`, `folder`, `download`, `upload`, `refresh`, `bell`, `info`, `plus`, and `minus`. A tab can also use an icon registered with the library.

The included `GabibouUI_Icons` folder contains 288 PNG files and 288 SVG files in the same ZIP as the library. Open its [icon browser](../GabibouUI_Icons/index.html) to browse names, IDs, and variants. The exported images are optional at runtime because the library can draw its icons directly.

`Branding` configures the avatar or mark around the window. `Mode` can be `Avatar`, `Image`, or `Initials`; `Placement` can be `TopLeft`, `TopRight`, `BottomRight`, or `BothRight`. `Text` accepts 1 to 4 characters and is used as a monogram. For `Mode = "Image"`, `Image` must be a Roblox image asset ID in the format `rbxassetid://...`. `UserId` is optional; the local player's avatar is used by default.

## Mobile layout

The window and built-in controls share the same API on mobile and desktop. Configure responsive behavior with `Responsive`:

```lua
Responsive = {
    Breakpoint = 620, -- width below which navigation becomes horizontal
    TouchTarget = 44, -- touch height, range 44 to 72 px
    Margin = 12,      -- margin, range 4 to 40 px
}
```

Below the breakpoint, tab navigation scrolls horizontally and built-in controls adapt their layouts. The dimensions inside `Custom` components remain the builder's responsibility; [CUSTOMIZATION.md](CUSTOMIZATION.md) shows how to adapt them to the available width. Check your interface on the phones you intend to support.

## Advanced API and sources

The [customization guide](CUSTOMIZATION.md) covers `Launch`, the key gate, `Loader:Run`/`Update`, layout, notifications, `Style`, `Motion`, `Animate`, events, cleanup, `Custom` components, branding, and custom icons.

- [`../gabibou_ui.luau`](../gabibou_ui.luau): standalone module to copy into Studio.
- `quickstart.luau`: short example of `Library:Create` and `SetValues`.
- `starter.luau`: `LocalScript` startup example with a server gate.
- `key_server.example.luau`: sample server `Script` to adapt and place in `ServerScriptService`.
- `ui.luau`, `logic.luau`, `extensions.luau`, `icons.luau`, `navigation.luau`, `branding.luau`, `layout.luau`, `loading.luau`, `key_system.luau`, `convenience.luau`, `launch.luau`, `notifications.luau`: library sources.
- `build.cjs`: rebuilds the standalone module with Node.
- `demo.luau`: demo of controls and extensions.
- `ICONS.md`: complete icon catalogue with names and IDs.

From the parent `script` directory, rebuild the module with:

```powershell
node gabibou_ui/build.cjs
```
