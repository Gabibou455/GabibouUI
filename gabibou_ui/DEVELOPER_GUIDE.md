# Gabibou UI Developer Guide

Version: `1.5.0-rc.4` (local, unreleased candidate)  
Language: Luau  
Runtime: Roblox client

This guide describes the local 1.5.0-rc.4 candidate and its lifecycle corrections. The remote-loading example below remains pinned to the public `v1.5.0-rc.3` tag; that published example does not include local rc.4 changes. The library builds interface objects; your callbacks connect those controls to your own game or application logic.

## Contents

1. [Install](#install)
2. [Choose a creation path](#choose-a-creation-path)
3. [Declarative windows with `UI:Create`](#declarative-windows-with-uicreate)
4. [Build a window directly](#build-a-window-directly)
5. [Controls and values](#controls-and-values)
6. [Read, set, and save values](#read-set-and-save-values)
7. [Themes, style, motion, and navigation](#themes-style-motion-and-navigation)
8. [Responsive layout and parts](#responsive-layout-and-parts)
9. [Icons and branding](#icons-and-branding)
10. [Loading screens](#loading-screens)
11. [Key systems and launch flow](#key-systems-and-launch-flow)
12. [Events and cleanup](#events-and-cleanup)
13. [Custom controls and components](#custom-controls-and-components)
14. [Notifications and confirmation dialogs](#notifications-and-confirmation-dialogs)
15. [Debugging](#debugging)
16. [Publish and runtime limits](#publish-and-runtime-limits)
17. [API quick reference](#api-quick-reference)

## Install

### Roblox Studio

1. Create a `ModuleScript` named `GabibouUI` under `ReplicatedStorage`.
2. Copy the standalone source from [`../gabibou_ui.luau`](../gabibou_ui.luau) into that module.
3. Require it from a client `LocalScript`:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UI = require(ReplicatedStorage:WaitForChild("GabibouUI"))
```

### GitHub loadstring environments

Some client environments provide both `loadstring` and `game:HttpGet`. In those environments, the public `1.5.0-rc.3` source can be loaded like this:

```lua
local source = game:HttpGet(
    "https://raw.githubusercontent.com/Gabibou455/GabibouUI/v1.5.0-rc.3/gabibou_ui.luau"
)
local UI = assert(loadstring(source))()
```

This loader is not a standard Roblox Studio feature. Studio projects should use a `ModuleScript`. The package also contains [`remote_example.luau`](remote_example.luau) with separate fetch and compile error handling.

## Choose a creation path

Use `UI:Create(spec)` when the interface can be described as data. It validates the schema before creating the window and is the shortest path for ordinary menus.

Use `UI:CreateWindow(options)` when you want to add tabs, sections, and controls step by step, or need the returned object during construction.

Use `UI:Launch(spec)` when the startup flow needs key validation, asynchronous setup steps, a loading screen, and a final window. Launch returns a session immediately; its callbacks report the result.

## Declarative windows with `UI:Create`

Window options sit at the root of the specification. `Tabs` is a dense, nonempty array. Every control needs a unique `Id` across the full window.

```lua
local window = UI:Create({
    Id = "Settings",
    Title = "My Settings",
    Subtitle = "Preferences",
    Tabs = {
        {
            Title = "General",
            Icon = "settings",
            Sections = {
                {
                    Title = "Behavior",
                    Controls = {
                        {Type = "Toggle", Id = "enabled", Title = "Enabled", Value = true},
                        {Type = "Slider", Id = "volume", Title = "Volume", Min = 0, Max = 100, Value = 60},
                        {Type = "Button", Id = "apply", Title = "Apply", Text = "Apply", Callback = function()
                            print("Applied")
                        end},
                    },
                },
            },
        },
    },
})
```

Tabs may also put controls directly in `Controls`, without a section. A tab can contain both `Controls` and `Sections`. A section has `Title` and an optional `Controls` array. `Loading = true` or a loading options table shows build progress while the schema is created. See [Loading screens](#loading-screens).

The schema checks built-in control options and IDs before opening the window. It cannot predict side effects in a registered component builder. If runtime construction fails, the partial new window and loader are cleaned up; an older window with the same ID is not restored.

## Build a window directly

```lua
local window = UI:CreateWindow({
    Id = "DirectExample",
    Title = "My Interface",
    Subtitle = "Built step by step",
    Theme = "Graphite",
    Responsive = {Breakpoint = 620, TouchTarget = 44, Margin = 12},
})

local tab = window:Tab({Title = "Home", Icon = "home"})
local section = tab:Section({Title = "Actions"})
local enabled = section:Toggle({
    Id = "enabled",
    Title = "Enabled",
    Value = false,
    Callback = function(value)
        print("Enabled:", value)
    end,
})
```

The same control methods work in either creation path. Use `window:Tab`, `tab:Section`, and section methods such as `Toggle`, `Slider`, and `Button` to build incrementally.

## Controls and values

All controls accept common fields: `Id`, `Title`, `Description` (or `Desc`), `Disabled`, `Persistent`, `Callback`, and an optional `Layout` table. `Title` and `Id` are especially useful for accessible, searchable menus. Controls are searchable by title and description.

| Type | Main options | Value |
|---|---|---|
| `Toggle` | `Value` | Boolean |
| `Slider` | `Min`, `Max`, `Step`, `Value` | Number, snapped to the step |
| `Dropdown` | `Options` (unique strings), `Value` | Selected string |
| `Input` | `Value`, `Placeholder`, `MaxLength` (default 120; 1–4096) | String; commits on focus lost |
| `Keybind` | `Value` (KeyCode name; default `F6`) | KeyCode name |
| `ColorPicker` | `Value` (`#RRGGBB` or `Color3`), optional `Palette` (1–32 colors) | Hex string; `GetColor()` returns `Color3` |
| `Button` | `Text`, optional `Icon`, `IconVariant` | No persistent value |
| `Paragraph` | `Title`, `Description` | No persistent value |
| `Custom` | `Height` (0–2000), `Build(content, control, window, options)` | Builder-owned |

Sliders default to `Min = 0`, `Max = 100`, `Step = 1`, and `Value = Min`. Dropdowns require a nonempty `Options` array and default to its first item. `Button` defaults its label to `Run` when `Text` is omitted. Standard value controls are persistent by default; set `Persistent = false` to leave a control out of configuration snapshots.

```lua
local amount = section:Slider({Id = "amount", Title = "Amount", Min = 20, Max = 80, Step = 5, Value = 35})
amount:Set(50, true) -- updates the value and calls Callback if it changed
print(amount:Get())
```

`control:Set(value, fireCallback)` validates the value. The callback runs only when `fireCallback == true` and the value changed. User interaction invokes the callback for value changes. `SetTitle`, `SetDescription`, `SetVisible`, `SetEnabled`, `SetLayout`, `SetOrder`, `GetParts`, and `Destroy` are also available while the control is alive.

Library-managed callbacks belong to their control or window. Destroying that owner cancels its callback tasks and disconnects subscriptions registered with `On` or `Connect`. `Hide()` and `Show()` preserve callbacks and subscriptions. A callback that destroys its own owner is allowed to finish its current call. Tasks started directly by your code with `task.spawn` are outside the library's lifecycle; cancel them in your own cleanup path.

For `Keybind`, clicking the control captures a new key. Assignment emits `Changed`, but does not run the action callback. Pressing the assigned key outside capture mode runs the callback.

## Read, set, and save values

`window:Get(id)` returns the control or `nil`. `window:GetValues()` returns a copy of persistent values. `window:SetValues(values, fireCallbacks)` validates every ID and value before applying any changes, applies the full set, then emits callbacks for changed values when requested. It returns the number of applied values. Callback task order is not guaranteed.

```lua
local values = window:GetValues()
window:SetValues({enabled = true, volume = 75}, false)
```

`window:ExportConfig()` returns JSON. `window:ImportConfig(json, fireCallbacks)` validates and applies a snapshot. `SaveConfig(name)` and `LoadConfig(name, fireCallbacks)` use an explicitly supplied storage adapter:

```lua
local UI = require(game:GetService("ReplicatedStorage"):WaitForChild("GabibouUI"))
local storage = {
    Write = function(path, contents)
        -- Write through storage available in your environment.
    end,
    Read = function(path)
        -- Return file contents, or nil if the file is absent.
    end,
}

local window = UI:CreateWindow({Title = "Settings", Storage = storage})
window:SaveConfig("default")
window:LoadConfig("default", false)
```

The library does not read or write files by itself. Roblox Studio does not expose executor-style `readfile`/`writefile`; supply an adapter appropriate to your environment. Profile names are restricted to letters, numbers, `_`, and `-` (maximum 48 characters). JSON snapshots are limited to 256 KiB.

## Themes, style, motion, and navigation

Built-in themes are `Graphite`, `Aurora`, and `Ember`. Use `Theme = "Graphite"`, `window:SetTheme("Aurora")`, or pass a table of `Color3` tokens. Partial custom tables inherit omitted values from Graphite. Tokens are `Background`, `Surface`, `Raised`, `Hover`, `Border`, `Text`, `Muted`, `Accent`, `AccentText`, `Success`, and `Danger`.

`UI:SetStyle(options)` and `UI:SetMotion(options)` set defaults for future windows. `window:SetStyle(options)` and `window:SetMotion(options)` update one window. Style fields include fonts, text sizes, window/section/control radii, and row padding. Motion fields are `Duration`, `Style`, `Direction`, `RepeatCount`, `Reverses`, and `Delay`. See [CUSTOMIZATION.md](CUSTOMIZATION.md) for ranges and examples.

Navigation is configured with `Navigation = {Variant = "Soft", IconVariant = "Outline"}`. Variants are `Classic`, `Soft` (default), and `Pill`; icon variants are `Outline`, `Soft`, and `Duotone`. A tab can pin its own `IconVariant`. `window:SetNavigation(partialOptions)` updates the current window.

Use `window:Animate(instance, properties, options)` for an instance inside the window GUI, or `control:Animate(properties, options)` for the control root. The methods return a Roblox `Tween`; starting another managed tween on the same instance cancels the previous one. `window:SetReducedMotion(true)` cancels active tweens and applies final values immediately. `window:BindColor(instance, property, token)` binds a descendant's `Color3` property to a theme token.

## Responsive layout and parts

Responsive layout is enabled by default. The library adapts tab placement and control rows to the viewport and uses a keyboard-aware safe area. `Responsive` accepts a partial options table; the defaults are a 620 px breakpoint, 44 px touch targets, and 12 px margin. These rules are automated layout behavior; test your own custom controls on target devices.

`Layout` options may be set as defaults with `UI:SetLayout(options)`, per window with `window:SetLayout(options)`, and per tab/control with their `Layout` option. Common settings include `TabPosition`, `MobileTabPosition`, `SidebarWidth`, `ContentPadding`, `ContentGap`, `RowGap`, `SectionGap`, `ControlsPosition`, `ShowSearch`, `ShowHeader`, and `ShowFooter`.

`window:GetParts()` exposes named window parts. `window:SetPartLayout(name, options)` can override `Position`, `Size`, `AnchorPoint`, and `Visible`; `window:ResetPartLayout(name)` restores automatic layout. Part overrides apply after the responsive layout and can overlap or extend beyond the window, so keep custom offsets within the available area. The precise part names and layout bounds are listed in [CUSTOMIZATION.md](CUSTOMIZATION.md).

## Icons and branding

The library includes 96 original vector icons, each available in `Outline`, `Soft`, and `Duotone`. Use a name or stable numeric ID in `Tab`, `Button`, and `UI:Icon`. Look up IDs with `UI:GetIconId(name)`, `UI:GetIconName(idOrName)`, or `UI:GetIconCatalogue()`; `UI:GetIconNames()` returns names. The catalogue is documented in [`ICONS.md`](ICONS.md). `UI:RegisterIcon(name, builder)` adds an icon to the current library instance; `UI:UnregisterIcon(name, expectedBuilder)` removes it safely.

```lua
local window = UI:CreateWindow({Title = "Garden", Navigation = {Variant = "Pill", IconVariant = "Duotone"}})
local tab = window:Tab({Title = "Farm", Icon = "farm", IconVariant = "Soft"})
local iconId = UI:GetIconId("watering-can")
```

Window branding supports an initial, avatar, or image, and can be positioned around the title bar. Use `Branding = {...}` at creation or `window:SetBranding(partialOptions)`. Image branding accepts an `rbxassetid://` URI. Avatar mode uses Roblox's thumbnail service. See [CUSTOMIZATION.md](CUSTOMIZATION.md) for branding fields.

## Loading screens

### Built-in loading for a declarative window

`Loading = true` displays the default loader. A table lets you configure it; window `Parent`, `Theme`, `Style`, and `ReducedMotion` are inherited when omitted. The loader is closed when the build completes or the window is destroyed.

```lua
local window = UI:Create({
    Title = "Garden Tools",
    Loading = {
        Title = "Garden Tools",
        Subtitle = "Preparing your interface",
        MarkText = "GT",
        Logo = "rbxassetid://1234567890", -- optional uploaded image
        Variant = "Centered",
        MinimumDuration = 0.8,
        ShowPercentage = true,
        ShowActivity = true,
        ShowSubtitle = true,
        ProgressHeight = 5,
    },
    Tabs = {{Title = "Home", Controls = {
        {Type = "Toggle", Id = "enabled", Title = "Enabled", Value = true},
    }}},
})
```

The built-in `Create` loader reports how many schema controls have been constructed. For a standalone loading screen with manual progress, use `UI:CreateLoader(options)`, then call `SetProgress(ratio, status)`, `SetStatus(text)`, `Update(options)`, `Complete(status)`, or `Destroy()`.

Loader layout variants are `Compact` (default, height 216), `Centered` (height 300 with a centered logo and title; below 260 px it falls back to compact layout), and `Minimal` (compact layout without a logo). You can set `Height` explicitly. `ShowSubtitle` controls the subtitle, `ShowLogo` controls the logo area, `ShowPercentage` controls the number, `ShowActivity` controls the moving activity indicator, and `ProgressHeight` sets the progress track height from 2 to 12 px. Other options include `Title`, `Subtitle`, `MarkText`, `Logo` (`"Avatar"` or an image string), `Theme`, `Style`, `Width` (280–560), `Position`, `AnchorPoint`, `Padding` (12–40), `LogoSize` (24–80), `BackgroundTransparency` (0–1), `Parent`, `DisplayOrder`, `ReducedMotion`, `MinimumDuration` (0–10 seconds), `ExitDuration` (0–2 seconds), `OnComplete(loader)`, and `OnError(loader, title, index)`.

`Update` preserves the current `Height` when you change only `Variant`. To switch a default compact loader to the centered preset, set both fields: `loader:Update({Variant = "Centered", Height = 300})`.

`loader:Run(steps)` runs a dense list of `{Title, Run}` entries asynchronously and advances only after each successful step. A failed step keeps the loader visible, stores a generic `LastError`, and calls `OnError(loader, title, index)` if supplied. A yielding `OnError` callback belongs to the loader and `Destroy()` cancels it, including if it starts another `Run()` attempt. `MinimumDuration` controls the minimum visible time; `ExitDuration` controls the closing fade; `OnComplete(loader)` runs after completion and destruction.

```lua
local loader = UI:CreateLoader({
    Title = "Starting",
    Subtitle = "Loading your data",
    MarkText = "G",
    Variant = "Centered",
    Theme = "Graphite",
    Width = 420,
    Height = 300,
    MinimumDuration = 0.5,
})

loader:Run({
    {Title = "Loading profile", Run = function()
        -- Fetch or prepare data here.
    end},
    {Title = "Building menu", Run = function()
        -- Prepare resources here.
    end},
})
```

`loader:GetParts()` returns `Overlay`, `Card`, `Logo`, `LogoImage`, `LogoText`, `Title`, `Subtitle`, `Status`, `Percentage`, `Track`, `Fill`, `Activity`, and `Content`. `Content` is a free frame between the header and status row for custom instances. `SetPartLayout(name, options)` and `ResetPartLayout(name)` support `Logo`, `Title`, `Subtitle`, `Status`, `Percentage`, `Track`, and `Content`; options are `Position`, `Size`, `AnchorPoint`, and `Visible`. `Overlay`, `Card`, and inner progress objects are exposed for styling but do not have automatic-layout overrides. Responsive layout may recalculate positions on viewport changes.

Register custom listeners or effects with `loader:Own(resource)`. It accepts a cleanup function, an `RBXScriptConnection`, or an object with `Disconnect()`, `Cancel()`, or `Destroy()`; the selected cleanup is called when the loader is destroyed. For example:

```lua
local parts = loader:GetParts()
local label = Instance.new("TextLabel")
label.BackgroundTransparency = 1
label.Size = UDim2.fromScale(1, 1)
label.Text = "Connecting to your service…"
label.Parent = parts.Content

loader:SetPartLayout("Content", {
    Position = UDim2.fromOffset(24, 168),
    Size = UDim2.new(1, -48, 0, 48),
})
```

The library exposes supported parts and layout hooks rather than a custom renderer callback. Build your own elements under `Content`; own any external listener or effect with `Own`. See [CUSTOMIZATION.md](CUSTOMIZATION.md) for additional loader and theme examples.

## Key systems and launch flow

### Direct key dialog

`UI:CreateKeySystem(options)` requires `Validate(key)`. It can yield; `gate:Submit(key)` starts validation without blocking. The validator returns `true, result` for acceptance or `false, message` for rejection. The dialog handles failures without displaying raw exceptions. `gate:Cancel()` cancels an in-progress attempt and leaves the dialog open; `gate:Destroy()` closes it and makes future callbacks silent.

```lua
local gate = UI:CreateKeySystem({
    Title = "Access key",
    Subtitle = "Enter your key to continue.",
    Logo = "Avatar",
    MarkText = "G", -- shown when Logo = false
    SubmitText = "Verify key",
    Validate = function(key)
        return key == "example", "Key not accepted"
    end,
    OnSuccess = function(gate, result)
        print("Access granted")
    end,
    OnCancel = function(gate)
        print("Key dialog cancelled")
    end,
})
```

The optional `Discord` value may be an invite URL string or a table with `Url`, `Text`, `CopiedText`, `Color`, optional `Logo`, and optional `Copy(url)` callback. Set `Discord = false` to remove it. Accepted URLs use `https://discord.gg/...` or `https://discord.com/invite/...`. `gate:CopyDiscordLink()` returns whether copying succeeded. If clipboard access is unavailable or fails, the gate shows a selectable URL for manual copying. `gate:Update({Discord = false})` removes the button.

The visible key label and in-progress/cancelled status are customizable with `InputLabel` (default `Access key`), `ValidatingText` (default `Verifying…`), and `CancelledText` (default `Cancelled`). Each accepts up to 48 characters and can be changed with `gate:Update({...})` while the gate is idle and open.

The key gate shows the local player's avatar by default with `Logo = "Avatar"`. Set `Logo = false` to show the `MarkText` monogram, or pass an uploaded image such as `Logo = "rbxassetid://123456"`. `gate:GetParts()` exposes both `MarkImage` and `MarkText` if you want to customize the existing logo elements.

### Add a Get key action

`GetKey` is optional and disabled when omitted or set to `false`. A URL string or `{Url, Text, Copy}` table adds a button that copies a provider link. The URL must use HTTPS, include a host, contain no whitespace or control characters, and fit within 2048 bytes. `Text` defaults to `Get key` and accepts up to 48 characters. If no clipboard function is available, or copying fails, the gate shows a selectable link for manual copying. It does not open the URL automatically.

```lua
GetKey = {
    Url = "https://example.com/get-key", -- Replace with your provider URL.
    Text = "Get key",
    -- Optional clipboard implementation:
    -- Copy = function(url) setclipboard(url); return true end,
}
```

Use `GetKey = function(gate) ... end` to run a custom action. `gate:GetKey()` returns a success boolean and optional reason. The action is single-flight; updating or destroying the gate invalidates a yielding callback's stale UI result. The built-in demo uses this callback form to show the sample key `demo` in a notification; it is only a local preview. `gate:Update({GetKey = false})` removes the action. `gate:GetParts()` exposes `GetKeyButton`, `KeyLink`, and `KeyLinkStatus`.

The key dialog defaults to `Width = 420`. Automatic heights are 332 px without Discord/GetKey, 394 px with Discord, 404 px with GetKey, and 462 px with both. `Height` accepts 280–560 px. Automatic height follows GetKey/Discord changes; an explicitly supplied `Height` remains fixed when other options change.

See [`key_discord_example.luau`](key_discord_example.luau) for a complete launch example. A client-side key dialog is only a user interface. It does not protect server data or privileged actions; validate access on the server and keep secrets out of client code.

### Complete startup with `UI:Launch`

`UI:Launch(spec)` combines the declarative window with optional `KeySystem`, `Loading`, and `Steps`. Each step is `{Title, Run}`; `Run(loader)` may yield. The key gate is shown before loading. After validation, steps run sequentially, then the window is built.

```lua
local session = UI:Launch({
    Title = "My Interface",
    KeySystem = {Validate = function(key)
        return validateOnServer(key) -- use a server-backed validation request
    end},
    Loading = {Title = "Starting", MinimumDuration = 0.6},
    Steps = {{Title = "Loading data", Run = function(loader)
        -- Load application data here.
    end}},
    Tabs = {{Title = "Home", Controls = {
        {Type = "Paragraph", Id = "status", Title = "Ready", Description = "Setup complete."},
    }}},
    OnReady = function(window, session)
        window:Notify({Title = "Ready", Content = "The interface is open.", Kind = "success"})
    end,
    OnError = function(message, session)
        warn(message) -- generic public message
    end,
    OnCancel = function(session)
        print("Startup cancelled")
    end,
})

-- Later: session:Cancel() or session:Destroy()
```

The session exposes `Status`, `LastError`, `Gate`, `Loader`, `Window`, `Cancel()`, and `Destroy()`. Status moves through `WaitingForKey`, `Loading`, `Ready`, `Failed`, and `Destroyed`. The session's `OnCancel(session)` runs once when `Cancel()` is called or the gate is cancelled; `Destroy()` cleans up without that callback. The gate's `KeySystem.OnCancel(gate)` only runs when cancellation occurs before authentication succeeds. Cancelling after authentication still calls the session's `OnCancel(session)`, but not the gate callback. If the window is destroyed while a custom control builder is running, the session becomes `Destroyed`, cleans up its owned resources, and does not report `Ready` or call `OnReady`.

## Events and cleanup

`window:On(name, callback)` subscribes to window events such as `TabChanged`, `VisibilityChanged`, `ThemeChanged`, `StyleChanged`, `MotionChanged`, `ReducedMotionChanged`, and `NavigationChanged`. `control:On(name, callback)` supports `Changed`, hover, activation, and focus events when the control exposes them. Both return a subscription with `Disconnect()`.

`window:Connect(signal, callback)` and `control:Connect(signal, callback)` connect a Roblox signal in the owner's lifetime. `window:Own(resource)` and `control:Own(resource)` register an `RBXScriptConnection` or an object with `Disconnect()`. `window:OnDestroy(callback)` runs cleanup for external resources. The library cleans up owned connections, subscriptions, callback tasks, managed tweens, controls, and notifications when their owner is destroyed. `Hide()` and `Show()` only change visibility; they do not cancel callbacks. If one of a callback's own actions destroys its owner, the callback is allowed to return normally. Work started with your own `task.spawn` remains yours to cancel.

```lua
local subscription = toggle:On("Changed", function(value, previous)
    print(previous, "->", value)
end)
window:OnDestroy(function()
    -- Stop application work started outside the UI.
end)
```

Work your callbacks start outside the UI remains your responsibility. Cancel those tasks from `OnDestroy` or a control's own cleanup path.

## Custom controls and components

`section:Custom({Build = function(content, control, window, options) ... end})` gives you a free-form content frame. Create descendants under `content`, use `window:BindColor` for theme-aware colors, and register event connections with `control:Connect` so they disconnect with the control. `control:SetHeight(height)` updates its reserved height.

For reusable controls, `UI:RegisterComponent(name, builder)` registers a builder used by `section:Add(name, options)` or a declarative `Type = name`. `UI:GetComponentNames()` lists registrations. `UI:UnregisterComponent(name, expectedBuilder)` removes one; the optional expected builder protects another module's replacement. See [CUSTOMIZATION.md](CUSTOMIZATION.md) for responsive custom-control and component examples.

## Notifications and confirmation dialogs

`window:Notify({Title, Content, Kind, Icon, Duration})` shows a typed notification. Kinds are `info`, `success`, `warning`, and `error`. Configure defaults with `UI:SetNotifications(options)` for future windows or `window:SetNotifications(options)` for one window. The returned toast supports `Dismiss()` and `Destroy()`.

`window:Confirm({Title, Content, ConfirmText, Callback})` opens a confirmation dialog and returns whether it could be shown. Only one confirmation modal can be open at a time.

## Debugging

Start with the returned object and its public state: check `window:Get(id)`, `control:Get()`, the launch session's `Status` and `LastError`, or the loader's `Progress`, `Status`, and `LastError`. A failed declarative schema reports the failing path, such as `Tabs[1].Sections[2].Controls[1].Value`, before the window is created.

User callbacks and custom cleanup run in protected calls so one failure does not stop the rest of the UI lifecycle. While an owner is alive, window-owned callback and cleanup errors are recorded in `window.LastError` and reported with `warn`. Destroying an owner cancels its library-managed callback tasks; a callback that destroys its own owner may finish its active call, while callbacks that finish after destruction do not create stale notifications or update `LastError`. Key validation and Launch expose generic error messages; they do not forward a submitted key or raw validation exception. A separate debug console or logging mode is not part of the public API.

Use the focused examples and the release's quality report when diagnosing library behavior. Do not treat a Studio preview as evidence that executor-only services such as `setclipboard`, `loadstring`, or filesystem functions exist in a standard client.

## Publish and runtime limits

- The standalone file is [`../gabibou_ui.luau`](../gabibou_ui.luau). The module sources and release notes live in this folder and the repository root.
- `loadstring`, `game:HttpGet`, clipboard functions, and executor file APIs are environment-dependent, not standard Roblox Studio APIs.
- Storage is opt-in through the `Storage.Read` and `Storage.Write` adapter. The library does not silently access the filesystem or network.
- Key verification should be backed by server logic. Never place a private key list or secret credential in a LocalScript.
- Responsive rules and keyboard handling are implemented in the UI; they do not replace testing custom content on the devices you support.
- The `Farm` demo is a visual control example. It does not automate game actions.

See [`PUBLISHING.md`](../PUBLISHING.md) for the repository's release procedure and [`QUALITY.md`](../QUALITY.md) for verified checks and remaining validation.

## API quick reference

| Object | Methods |
|---|---|
| Library | `Create`, `CreateWindow`, `Launch`, `CreateLoader`, `CreateKeySystem`, `DestroyAll`, `SetLayout`, `SetStyle`, `SetMotion`, `SetNotifications`, `RegisterComponent`, `GetComponentNames`, `UnregisterComponent`, `GetIconNames`, `GetIconId`, `GetIconName`, `GetIconCatalogue`, `GetIconVariants`, `RegisterIcon`, `UnregisterIcon`, `Icon` |
| Window | `Tab`, `Get`, `GetValues`, `SetValues`, `SelectTab`, `SearchFor`, `Hide`, `Show`, `Toggle`, `SetSize`, `SetPosition`, `SetTheme`, `SetStyle`, `SetMotion`, `SetReducedMotion`, `SetLayout`, `SetNavigation`, `SetBranding`, `SetNotifications`, `Notify`, `Confirm`, config methods, `GetParts`, `SetPartLayout`, `ResetPartLayout`, `Animate`, `BindColor`, `On`, `Connect`, `Own`, `OnDestroy`, `Destroy` |
| Control | `Get`, `Set`, `SetTitle`, `SetDescription`, `SetVisible`, `SetEnabled`, `SetLayout`, `SetOrder`, `SetHeight` for custom controls, `GetParts`, `Animate`, `On`, `Connect`, `Own`, `Destroy` |
| Loader | `SetProgress`, `SetStatus`, `Update`, `Run`, `GetParts`, `SetPartLayout`, `ResetPartLayout`, `Own`, `Complete`, `Destroy` |
| Key gate | `Submit`, `GetKey`, `Cancel`, `Destroy`, `Update`, `GetParts`, `CopyDiscordLink` |
| Launch session | `Cancel`, `Destroy`; fields `Status`, `LastError`, `Gate`, `Loader`, `Window` |

For full option tables and validation ranges, use [CUSTOMIZATION.md](CUSTOMIZATION.md), [ICONS.md](ICONS.md), and the focused examples in this folder.
