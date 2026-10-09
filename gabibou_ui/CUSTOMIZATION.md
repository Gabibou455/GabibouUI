# Customization and animations — Gabibou UI 1.5.0-rc.5

This guide describes Gabibou UI 1.5.0-rc.5. Start with the [Developer Guide](DEVELOPER_GUIDE.md) for one-line loading and short constructors. These advanced examples use the full options-table API, which remains available for customization. Unless a snippet shows initialization, load the library before using it. The library is still under development, so names may change in future releases.

## Build a window from a schema

`UI:Create(schema)` accepts window options at the root and a dense, nonempty `Tabs` array. Each tab needs a nonempty `Title` and can contain `Icon`, direct controls in `Controls`, and sections in `Sections`; each section needs a nonempty `Title` and may contain `Controls`. `Tabs` and `Loading` are removed before the internal window is created. Every control in the schema needs a `Type` and a unique, nonempty `Id` of at most 96 characters with no control characters.

Built-in types are `Toggle`, `Slider`, `Dropdown`, `Input`, `Keybind`, `ColorPicker`, `Button`, `Paragraph`, and `Custom`. A type matching a registered component name is also accepted. `Create` validates the structure and built-in values before opening the window; the builder is responsible for validating options specific to a registered component.

```lua
local window = UI:Create({
    Id = "Settings",
    Title = "Settings",
    Responsive = {Breakpoint = 620, TouchTarget = 44, Margin = 12},
    Tabs = {{
        Title = "General",
        Icon = "settings",
        Sections = {{
            Title = "Interface",
            Controls = {
                {Type = "Toggle", Id = "compact", Title = "Compact mode", Value = false},
                {Type = "Slider", Id = "scale", Title = "Scale", Min = 80, Max = 120, Value = 100},
            },
        }},
    }},
})
```

The schema is validated before the interface is created. If a `Custom` builder fails after construction has started, the partial new interface is destroyed. If it reused an `Id` that was already open, the old window was destroyed while the new one was being created and is not restored.

## Orchestrate startup with `Launch`

`UI:Launch(spec)` uses the window options accepted by `UI:Create` and adds `KeySystem`, `Loading`, `Steps`, `OnReady`, `OnError`, and `OnCancel`. `Steps` is a dense array of `{Title, Run}` entries. The steps are validated before interface allocation, then run sequentially in an asynchronous task through `Run(loader)`. Progress is published only after the corresponding step succeeds. If steps are provided and `Loading` is absent, `Launch` creates a loader with default options. The loader completes only after the window has been fully created.

```lua
local validateAccess = game:GetService("ReplicatedStorage"):WaitForChild("ValidateAccess")

local session = UI:Launch({
    Id = "Settings",
    Title = "Settings",
    KeySystem = {
        Title = "Access",
        Validate = function(key)
            return validateAccess:InvokeServer(key)
        end,
    },
    Loading = {Title = "Setup", MinimumDuration = 0.2},
    Steps = {{Title = "Preferences", Run = function(loader)
        -- Perform real setup work here.
    end}},
    Tabs = {{Title = "General", Icon = "home"}},
    OnReady = function(window, currentSession)
        print("Ready", currentSession.Status)
    end,
    OnError = function(message, currentSession)
        warn(message)
    end,
    OnCancel = function(currentSession)
        print("Cancelled", currentSession.Status)
    end,
})
```

The session exposes `Status`, `Gate`, `Loader`, `Window`, `Cancel()`, and `Destroy()`. Status values are `WaitingForKey`, `Loading`, `Ready`, `Failed`, and `Destroyed`. `OnReady(window, session)` runs after the window is created. `OnError(message, session)` receives the generic message `Launch failed`; exception details and keys are not passed through. `Cancel()` cancels and destroys owned resources, then calls the session's `OnCancel(session)` once. `Destroy()` cleans up without calling that session callback. Cancelling the gate also sets the session status to `Destroyed` and calls the session callback. The gate's `KeySystem.OnCancel(gate)` is only called when cancellation happens before authentication succeeds; cancelling the launch after successful authentication still calls the launch session's `OnCancel(session)`, but not the gate callback. If the window is destroyed while a custom control builder is running, the session becomes `Destroyed` and cleans up without reporting `Ready` or calling `OnReady`.

`KeySystem.Validate(key)` receives the entered key and must return `true, result` to accept it or `false, message` to reject it. `KeySystem.OnSuccess(gate, result)` and `KeySystem.OnCancel(gate)` are optional and protected. After successful validation, the gate is destroyed before startup steps run.

To show the gate independently of `Launch`, use `UI:CreateKeySystem(options)`. `Validate` is required; `OnSuccess(gate, result)` and `OnCancel(gate)` are optional. `Submit(key)` starts a nonblocking validation; `Cancel()` cancels the attempt and keeps the gate open for another entry; `Destroy()` closes the gate and cancels its tasks. Observable properties include `Busy`, `Completed`, `Destroyed`, and `Status`. Defaults: `Title = "Access key"`, `Subtitle = "Enter your key to continue."`, `Placeholder = "Enter key…"`, `InputLabel = "Access key"`, `SubmitText = "Verify key"`, `CancelText = "Cancel"`, `SuccessText = "Verified"`, `InvalidText = "Key not accepted"`, `ValidatingText = "Verifying…"`, `CancelledText = "Cancelled"`, `Logo = "Avatar"`, `MarkText = "G"`, `Width = 420` (280–600), `MaxLength = 256` UTF-8 characters (integer from 1 to 4096), and `DisplayOrder = 120` (integer). Automatic height is 332 px without Discord/GetKey, 394 px with Discord only, 404 px with GetKey only, and 462 px with both; `Height` accepts 280–560 px. If you set `Height` explicitly, it remains fixed when `Update` changes other options. `Logo = "Avatar"` displays the local player's avatar; `Logo = false` displays `MarkText`; an image URI such as `rbxassetid://123` displays a custom image. `GetParts()` exposes `MarkImage` and `MarkText` for further customization. `InputLabel`, `ValidatingText`, and `CancelledText` accept up to 48 characters and can be changed with `gate:Update(options)` while the gate is idle and open. `Position` and `AnchorPoint` default to the center of the screen; `Theme`, `Style`, and `Parent` use their defaults when omitted.

`GetKey` is disabled by default (`nil` or `false`). A string URL or `{Url, Text, Copy}` table adds a button that copies an HTTPS link. `Text` defaults to `Get key`, accepts up to 48 characters, and `Copy(url)` may supply a clipboard implementation. URLs must be HTTPS, include a host, contain no whitespace or control characters, and be no longer than 2048 bytes. Without a working clipboard/copy callback, the dialog exposes the URL in a selectable text box for manual copying. It never opens the URL automatically. A `function(gate)` value runs a custom action instead; `gate:GetKey()` invokes it and returns a success boolean plus an optional reason. The method is single-flight. Errors or a declined action show generic feedback; a failed URL copy reveals the manual link. `gate:Update({GetKey = false})` removes the action and invalidates any stale result. `GetParts()` exposes `GetKeyButton`, `KeyLink`, and `KeyLinkStatus`.

The key system provides a **client-side** interface; it does not protect a server action. A player can modify or bypass a `LocalScript`, so `Validate` must call a server that owns the rule and secrets, and every protected action must be validated again on the server. Never put a secret key in the client module. The server must validate data sent by the client according to [Roblox's client-server boundary documentation](https://create.roblox.com/docs/scripting/security/client-server-boundary).

[`starter.luau`](starter.luau) and [`key_server.example.luau`](key_server.example.luau) show a three-part setup: the `GabibouUI` module in `ReplicatedStorage`, a server Script in `ServerScriptService`, and a LocalScript in `StarterPlayerScripts`. In the server Script, replace `CHANGE_ME` with your private keys; the marker itself is rejected, so the example remains closed until configured. The validator rejects keys longer than 256 bytes and limits each player to one attempt every 2 seconds. On success, the server sets the `GabibouAuthorized` attribute on the player. Every protected action must check this attribute and enforce its own server-side rules.

## Read and apply a group of values

`window:Get(id)` returns the control or `nil` if the ID is missing. `window:GetValues()` returns a copy containing only persistent control values. `window:SetValues(values, fireCallbacks)` rejects unknown keys and nonpersistent controls, then validates every value before changing any of them.

```lua
local scale = window:Get("scale")
local values = window:GetValues()
local count = window:SetValues({compact = true, scale = 110}, false)
```

After all values pass validation, `SetValues` applies them all before dispatching callbacks. With `fireCallbacks = true`, only controls whose values changed trigger `Callback` and `Changed`. Dispatch is ordered by control ID; because callbacks run in asynchronous tasks, their actual execution order is not guaranteed. The method returns the number of validated and applied entries.

Library-managed callbacks belong to their control or window. Destroying that owner cancels its callback tasks and disconnects its event subscriptions (including `Changed`) and `Connect` handlers. Callbacks that finish after destruction do not create stale notifications or update `LastError`. `Hide()` and `Show()` only change visibility; they preserve these registrations and do not cancel callbacks. If a callback destroys its own owner, that invocation is allowed to finish; destruction does not interrupt it mid-call. Tasks your code starts directly with `task.spawn` are not managed by the library. Cancel them through your own cleanup path, such as `window:OnDestroy(callback)` or a control-owned cleanup resource.

`gate:Update(options)` changes text, `MarkText`, dimensions, position, theme, and style before verification. It returns `false, reason` if an option is invalid, validation is in progress, or the gate is completed or destroyed. Options are validated before any changes are applied. `gate:GetParts()` exposes visual elements for customization; direct position changes may be reapplied by automatic layout.

## Application-driven loading screen

`UI:CreateLoader(options)` returns a standalone loader. Its methods are `SetProgress(ratio, status)`, `SetStatus(text)`, `Update(options)`, `Run(steps)`, `Complete(status)`, and `Destroy()`. `ratio` ranges from 0 to 1. `Complete` shows 100%, waits out any remaining minimum display time, plays the exit transition, and destroys the loader. `OnComplete(loader)` runs afterward. Calling `Destroy()` manually closes the loader immediately without calling `OnComplete`.

```lua
local loader = UI:CreateLoader({
    Title = "Preparing profile",
    Subtitle = "Loading preferences",
    Logo = "Avatar", -- or a Roblox image asset, such as rbxassetid://123456
    Theme = "Graphite",
    MinimumDuration = 0.5,
    ExitDuration = 0.18,
    OnComplete = function(closedLoader)
        print("Loading finished", closedLoader.Destroyed)
    end,
})

loader:SetProgress(0.2, "Reading preferences")
-- Match each update to a step that has actually finished.
loader:SetProgress(0.75, "Preparing controls")
loader:Complete("Ready")
```

Supported options: `Title` (up to 80 characters), `Subtitle` (up to 240), `MarkText` (up to 8), `Logo`, `Variant`, `Theme`, `Style`, `Width`, `Height`, `Position`, `AnchorPoint`, `Padding`, `LogoSize`, `ShowSubtitle`, `ShowPercentage`, `ShowLogo`, `ShowActivity`, `ProgressHeight`, `BackgroundTransparency`, `Parent`, `DisplayOrder`, `ReducedMotion`, `MinimumDuration`, `ExitDuration`, `OnComplete`, and `OnError`. Defaults: `Variant = "Compact"`, `Width = 420` (280–560), `Height = 216` (160–480; 300 for `Centered`), `Position = UDim2.fromScale(.5, .5)`, `AnchorPoint = Vector2.new(.5, .5)`, `Padding = 24` (12–40), `LogoSize = 46` (24–80), `ShowSubtitle = true`, `ShowPercentage = true`, `ShowLogo = true`, `ShowActivity = true`, `ProgressHeight = 4` (2–12), `BackgroundTransparency = 0.3` (0–1), `MinimumDuration = 0` (0–10 s), `ExitDuration = 0.18` (0–2 s), and `DisplayOrder = 100`. `Logo` accepts `"Avatar"`, a Roblox image-content string, or `false` to clear the image. The default parent is `PlayerGui`. `ReducedMotion` defaults to the Roblox preference.

`Update(options)` merges partial options with the current settings and validates them before changing the display. `Run(steps)` accepts a nonempty dense array of `{Title, Run}` entries with titles from 1 to 160 UTF-8 characters, then runs the steps sequentially in an asynchronous task. A step's `Run(loader)` function may yield; progress advances only after it succeeds. When all steps succeed, `Run` automatically calls `Complete("Ready")`. On failure, `LastError` becomes `"A loader step failed"`, the sequence stops without calling `Complete`, and `OnError(loader, title, index)` is protected. A yielding `OnError` belongs to the loader and `Destroy()` cancels it, including if it starts another `Run()` attempt. `Destroy()` also cancels the current sequence, as well as avatar and transition tasks.

Loader layout variants are `Compact` (default, height 216), `Centered` (height 300 with a centered logo and title), and `Minimal` (compact layout without a logo). `Centered` falls back to the compact arrangement below 260 px of available height. `ShowSubtitle` toggles the subtitle; `ProgressHeight` ranges from 2 to 12 px. `GetParts()` returns `Overlay`, `Card`, `Logo`, `LogoImage`, `LogoText`, `Title`, `Subtitle`, `Status`, `Percentage`, `Track`, `Fill`, `Activity`, and `Content`. Add custom GUI children to `Content`, a free frame between the heading and status area. `Update` preserves the current height when you change only the variant; to switch the default compact loader to centered, call `loader:Update({Variant = "Centered", Height = 300})`.

`SetPartLayout(name, options)` and `ResetPartLayout(name)` accept the names `Logo`, `Title`, `Subtitle`, `Status`, `Percentage`, `Track`, and `Content`. `options` supports finite `UDim2` values for `Position` and `Size`, a `Vector2` from 0 to 1 for `AnchorPoint`, and a boolean for `Visible`. Overrides are reapplied by responsive layout. The overlay, card, fill, and activity elements are exposed for styling, but their positions are not overrideable. `Own(resource)` registers a cleanup function, connection, tween, or destroyable resource; it is cleaned up when the loader is destroyed.

Minimum display time starts when the loader is created. It guarantees only a minimum amount of time on screen after `Complete`; it does not measure or guarantee that a network operation has finished. For a loader managed automatically by `UI:Create`, `Loading = true` uses default settings and `Loading = {...}` customizes them. This screen reflects schema construction progress. To represent downloads or game tasks, use `CreateLoader` and report your code's real steps.

The integrated loader inherits `Theme`, `Style`, `ReducedMotion`, and `Parent` from the window when they are absent from `Loading`. Its default `DisplayOrder` is one greater than the window's. It belongs to the window: destroying the window also cancels a loader that is still visible. A standalone loader created with `CreateLoader` keeps its own lifecycle.

## Window branding

`Branding` is a window option. `Mode` accepts `Avatar`, `Image`, or `Initials`. `Placement` accepts `TopLeft`, `TopRight`, `BottomRight`, or `BothRight`. `Text` is a monogram from 1 to 4 characters. `Image` is required in `Image` mode and must use the `rbxassetid://<id>` format. `UserId` is optional and must be a positive integer; without it, the local player is used for the avatar.

```lua
window:SetBranding({
    Mode = "Initials",
    Placement = "BothRight",
    Text = "AB",
})

window:SetBranding({Mode = "Image", Image = "rbxassetid://123456789"})
window:SetBranding(nil) -- restores default branding
```

`SetBranding` accepts a partial table, filling omitted values from the current branding; passing `nil` resets to defaults. Values are validated before the visible branding is replaced. Avatar loading depends on Roblox's thumbnail service and may fail; errors are stored in `window.LastError`.

## Native icon registry

The [ICONS.md](ICONS.md) catalogue lists each native icon's name and stable ID. `Icon` accepts a name or numeric ID on tabs, buttons, and notifications; `UI:Icon(parent, idOrName, options)` also accepts either form. Examples: `window:Tab({Title="Farm", Icon=21})`, `tab:Button({Title="Harvest", Icon=24})`. `UI:GetIconId(name)` and `UI:GetIconName(idOrName)` return `nil` when an entry is missing. `UI:GetIconCatalogue()` returns copies of `{Id, Name}` entries sorted by ID. Native IDs 1–96 are fixed (the original IDs 1–71 are unchanged); dynamically registered icons receive IDs starting at 1000 in registration order.

Navigation accepts `Icon` with an exact catalogue name. The 96 included names and IDs are listed in [ICONS.md](ICONS.md). `UI:GetIconNames()` returns the names in sorted order. `RegisterIcon(name, builder)` adds a lowercase kebab-case name; `UnregisterIcon(name, expectedBuilder)` removes it and returns `false` if it is absent or if the expected builder no longer matches.

`UI:GetIconVariants()` returns a copy of `{"Outline", "Soft", "Duotone"}`. Pass `Variant` to `UI:Icon`: Outline keeps the classic stroke; Soft uses a thicker, rounded, slightly transparent stroke; Duotone adds shading and a secondary outline. `IconVariant` is an alias, but providing both options is rejected.

Tabs and buttons accept `IconVariant`. On a tab, an explicit value takes priority over `Navigation.IconVariant`; on a button, the default is `Outline`. Example: `tab:Button({Title="Harvest", Text="Collect", Icon="harvest", IconVariant="Duotone"})`. `button:GetParts().Icon` provides access to the drawing.

`Navigation = {Variant="Soft", IconVariant="Outline"}` configures a window. `window:SetNavigation(partial)` changes these options at runtime. Navigation variants are `Classic`, `Soft` (default), and `Pill`. `UI.Navigation` sets defaults for future windows; changing this table does not affect existing windows. Colors follow the theme, sizes remain controlled by `Layout`, and mobile tabs keep the same variants.

`UI:Icon(parent, name, options)` draws an icon inside a `Frame` that it creates and returns. The default size is 20 px, with a range of 12 to 64; `Thickness` defaults to 2, with a range of 1 to 4. Other options are `Color`, `Name`, `Position`, `AnchorPoint`, `Window`, and `Token`. `Color` sets a `Color3`. Without `Color`, providing `Window` binds the icon color to the theme through `Token` (default `Muted`); the parent must belong to that window. Without a window or color, the icon uses neutral gray.

A custom builder receives `(root, color, thickness, window, token, variant)`; the sixth argument is optional for existing builders. `root` is the returned frame and the parent of the shapes. Minimal example:

```lua
UI:RegisterIcon("spark", function(root, color, thickness)
    local dot = Instance.new("Frame")
    dot.Name = "SparkDot"
    dot.Size = UDim2.fromScale(0.4, 0.4)
    dot.Position = UDim2.fromScale(0.3, 0.3)
    dot.BackgroundColor3 = color
    dot.BorderSizePixel = 0
    dot.Parent = root
end)

local icon = UI:Icon(customControl.Content, "spark", {
    Size = 24,
    Window = window,
    Token = "Accent",
})
```

A tab can now use `Icon = "spark"`. Icon names are shared by the library instance; an existing name cannot be replaced.

## Layout and advanced settings

`UI:SetLayout(options)` updates defaults for future windows. `window:SetLayout(options)` changes the current window's layout; these tables are partial, and unspecified values keep their current settings.

| Option | Default | Range or accepted values |
|---|---:|---|
| `TabPosition` | `"Left"` | `Left`, `Right`, `Top`, `Bottom` |
| `MobileTabPosition` | `"Top"` | `Top`, `Bottom` |
| `SidebarWidth` | 168 | 96–360 px |
| `TabWidth` | 128 | 64–400 px |
| `TabHeight` | 44 | 44–96 px |
| `TabGap` | 7 | 0–32 px |
| `TabIconSize` | 20 | 12–40 px |
| `ContentPadding` | 18 | 4–40 px |
| `ContentGap` | 18 | 0–48 px |
| `HeaderHeight` | 76 | 64–160 px |
| `FooterHeight` | 42 | 32–96 px |
| `SearchHeight` | 44 | 44–96 px |
| `SearchGap` | 12 | 0–40 px |
| `PageTitleHeight` | 40 | 28–80 px |
| `ButtonWidth` | 112 | 58–400 px |
| `ButtonHeight` | 44 | 44–120 px |
| `RowGap` | 10 | 0–40 px |
| `SectionGap` | 10 | 0–48 px |
| `ControlsPosition` | `"Right"` | `Left`, `Right`, `Below` |
| `Draggable`, `Resizable`, `ShowSearch`, `ShowFooter`, `ShowHeader`, `ShowPageTitle` | `true` | boolean |

Each tab and control can also take a local `Layout` table. A tab accepts `Order` (integer from −100000 to 100000), `Width` (58–600), `Height` (44–160), and `IconSize` (12–40). A control accepts `Order`, `Width`, `Height`, and `Position` (`Left`, `Right`, or `Below`).

`window:GetParts()` returns the named parts `Panel`, `Header`, `Tabs`, `Search`, `PageTitle`, `Pages`, `Footer`, `Reopen`, `Notifications`, `Minimize`, `Close`, and `Resize`. `SetPartLayout(name, options)` accepts finite `UDim2` values for `Position` and `Size`, a `Vector2` from 0 to 1 for `AnchorPoint`, and a boolean for `Visible`. These advanced values are applied after responsive layout and are not clamped to the screen; they may overlap other elements or extend beyond the window. `ResetPartLayout(name)` removes the overrides and restores calculated layout.

```lua
UI:SetLayout({TabPosition = "Top", ContentPadding = 20})
window:SetLayout({ShowFooter = false, SectionGap = 14})
window:SetPartLayout("Header", {Position = UDim2.fromOffset(20, 8)})
-- Later: window:ResetPartLayout("Header")
```

## Typed notifications

`UI:SetNotifications(options)` changes defaults for future windows; `window:SetNotifications(options)` updates the current window. Options are partially merged. Defaults: `Position = "BottomRight"`, `Width = 340` (220–600), `Margin = 18` (4–64), `Gap = 10` (0–32), `MaxVisible = 4` (integer from 1 to 8), `Duration = 4` (0.1–120 s), `ShowProgress = true`, and `AnimationDuration = 0.18` (0–0.8 s). `Position` accepts `TopRight`, `BottomRight`, `TopLeft`, or `BottomLeft`.

`window:Notify({Title, Content, Kind, Icon, Duration})` returns the created toast. `Title` is limited to 80 characters and `Content` to 1200. `Kind` accepts `info`, `success`, `warning`, or `error`; their default built-in icons and tokens are `info`/`Accent`, `check`/`Success`, `bell`/`Accent`, and `close`/`Danger`, respectively. `Icon` lets you choose another registered icon. A toast exposes `Dismiss()` to close with animation and `Destroy()` to remove it immediately.

```lua
UI:SetNotifications({Position = "TopRight", MaxVisible = 3, Duration = 6})
local toast = window:Notify({Title = "Saved", Content = "Preferences updated", Kind = "success"})
-- toast:Dismiss() -- dismiss early with animation
```

## Style defaults and window settings

`UI.Style` and `UI.Motion` are defaults copied when each window is created. Call `UI:SetStyle(...)` or `UI:SetMotion(...)` before `CreateWindow` to set values for future windows. These calls do not update windows that already exist.

```lua
local UI = require(game:GetService("ReplicatedStorage"):WaitForChild("GabibouUI"))

UI:SetStyle({
    Font = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,
    TextSize = 14,
    DescriptionSize = 12,
    TitleSize = 18,
    WindowRadius = 14,
    SectionRadius = 10,
    ControlRadius = 7,
    RowPadding = 14,
})
UI:SetMotion({Duration = 0.2, Style = Enum.EasingStyle.Quart})

local window = UI:CreateWindow({Title = "My settings"})
```

Available `Style` keys: `Font`, `FontBold`, `TextSize`, `DescriptionSize`, `TitleSize`, `WindowRadius`, `SectionRadius`, `ControlRadius`, and `RowPadding`. Fonts are `Enum.Font` values. Other values are numbers up to 32; `RowPadding` must be at least 8 and text sizes must be at least 10.

Available `Motion` keys:

| Key | Initial value | Purpose |
|---|---:|---|
| `Duration` | `0.16` | duration in seconds, from 0 to 30 |
| `Style` | `Enum.EasingStyle.Quad` | easing curve |
| `Direction` | `Enum.EasingDirection.Out` | easing direction |
| `RepeatCount` | `0` | repeats, from -1 to 100; -1 repeats forever |
| `Reverses` | `false` | return to the initial state after a repeat |
| `Delay` | `0` | delay in seconds, from 0 to 30 |

Each window then owns independent copies. `window:SetStyle(options)` immediately applies changed tokens to that window and preserves other values. `window:SetMotion(options)` changes the policy used by future animations in that window. Both methods return the window. `StyleChanged` or `MotionChanged` is emitted with a copy of the resulting table. `MotionChanged` covers the tween policy; reduced motion has its own `ReducedMotionChanged(boolean)` event.

```lua
window:SetStyle({
    Font = Enum.Font.GothamMedium,
    TitleSize = 20,
    WindowRadius = 18,
})
window:SetMotion({
    Duration = 0.28,
    Style = Enum.EasingStyle.Cubic,
    Direction = Enum.EasingDirection.Out,
})
```

Window options can also be provided at creation: `CreateWindow({Style = {...}, Motion = {...}})`. Each partial table fills from the library's current defaults.

## Create a black, gray, and white theme

Themes are tables of `Color3` tokens. Partial tables inherit unspecified colors from Graphite. The example below uses a monochrome palette with a white accent:

```lua
local window = UI:CreateWindow({Title = "My interface"})
window:SetTheme({
    Background = Color3.fromRGB(8, 8, 10),
    Surface = Color3.fromRGB(17, 18, 21),
    Raised = Color3.fromRGB(27, 29, 33),
    Hover = Color3.fromRGB(40, 42, 47),
    Border = Color3.fromRGB(65, 67, 73),
    Text = Color3.fromRGB(248, 248, 250),
    Muted = Color3.fromRGB(163, 165, 172),
    Accent = Color3.fromRGB(245, 245, 247),
    AccentText = Color3.fromRGB(15, 16, 18),
    Success = Color3.fromRGB(204, 210, 207),
    Danger = Color3.fromRGB(220, 185, 185),
})
```

To update a custom element when the theme changes, bind its property to a token with `window:BindColor(instance, property, token)`. The instance must belong to the window's `ScreenGui`, and the property must currently contain a `Color3`.

```lua
local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 4)
bar.Parent = customControl.Content
window:BindColor(bar, "BackgroundColor3", "Accent")
```

## Animate a window or control

`window:Animate(instance, properties, options)` calls `TweenService` for an instance belonging to that window and returns the created Roblox `Tween`. `control:Animate(properties, options)` animates the control's `Root` property. For a custom animation, create the instance inside a `Custom` control's `Content`, then animate it with `window:Animate`.

Animation options accept the six `Motion` keys and `OnComplete(instance)`. Omitted keys inherit from `window.Motion`. `OnComplete` runs only when the tween reaches `Completed`, not when it is cancelled. The callback runs in a protected task, like other extension callbacks.

```lua
local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(120, 36)
panel.Position = UDim2.fromOffset(0, 20)
panel.BackgroundTransparency = 1
panel.Parent = window.Gui -- In practice, prefer a Custom control's Content.

local tween = window:Animate(panel, {
    Position = UDim2.fromOffset(0, 0),
    BackgroundTransparency = 0,
}, {
    Duration = 0.35,
    Style = Enum.EasingStyle.Back,
    Direction = Enum.EasingDirection.Out,
    OnComplete = function(instance)
        print("Animation finished:", instance.Name)
    end,
})

-- If needed, the standard Tween object supports cancellation:
-- tween:Cancel()
```

The library allows only one managed tween per `Instance`, even if two tweens target different properties. Starting another tween on the same instance cancels the previous one. The library also cancels a tween if its target is destroyed, leaves the window's `ScreenGui`, or the window is destroyed.

A theme or style change cancels an instance's tween only when the animated properties overlap that instance's theme- or style-bound properties. Other animations continue. For example, changing `BackgroundColor3` while only `Position` is being animated does not stop the position tween.

`window:SetReducedMotion(true)` emits `ReducedMotionChanged(true)` only on a real transition from `false` to `true`, cancels every active tween, and applies its final values without calling `OnComplete`. Calling `SetReducedMotion(true)` again does not emit the event again. New animations with reduced motion finish at zero duration as usual; their `OnComplete` callbacks run asynchronously. `ReducedMotionChanged(false)` is emitted when motion is actually restored. The Roblox preference is read when the window is created unless `ReducedMotion` is supplied to `CreateWindow`.

`control:Animate` uses exactly `control.Root` as its target and also returns a `Tween`. To animate a child created by a custom component, use `window:Animate(child, ...)`; the child is then tracked as the target in the window's scope.

```lua
local rowTween = toggle:Animate({BackgroundTransparency = 0.15}, {
    Duration = 0.2,
    OnComplete = function(root)
        print("Row animation finished:", root.Name)
    end,
})

-- Explicit cancellation through the standard TweenService API:
rowTween:Cancel()

-- Enabling reduced motion immediately finishes managed tweens:
window:SetReducedMotion(true)
```

## Events, connections, and cleanup

`window:On(name, callback)` accepts `TabChanged`, `VisibilityChanged`, `ThemeChanged`, `StyleChanged`, `MotionChanged`, `ReducedMotionChanged`, and `NavigationChanged`. Window events pass, respectively: `(tab, previousTab)`, `(visible)`, `(themeName, themeTable)`, `(styleTable)`, `(motionTable)`, `(reducedMotion: boolean)`, and `(navigationTable)`. Passed tables are copies. `MotionChanged` reports only a policy change; `ReducedMotionChanged` fires only when the boolean state actually changes.

`control:On(name, callback)` accepts `Changed`, `HoverEnter`, `HoverLeave`, `Activated`, `FocusGained`, and `FocusLost` when the control has the corresponding signal. `Changed` receives `(newValue, oldValue)`. It fires when the value changes and the change was requested with callbacks enabled, for example `control:Set(value, true)`. User interactions that change a value follow the same path, with the Keybind capture exception described below.

For `Input`, `FocusGained` and `FocusLost` follow the text box's `Focused` and `FocusLost` events. For `ColorPicker`, they follow the hexadecimal input field. Other controls that use a button follow `SelectionGained` and `SelectionLost`, which cover keyboard and gamepad selection focus.

Capturing a new `Keybind` key updates its value and emits `Changed(newKey, oldKey)` if the value changed. This assignment does not run the keybind's `Callback` action. The `Callback` runs when the user presses the assigned key outside capture mode.

```lua
local toggle = section:Toggle({Id = "enabled", Title = "Enabled", Value = false})

local changed = toggle:On("Changed", function(value, previous)
    print(previous, "→", value)
end)

local hovered = toggle:On("HoverEnter", function()
    print("Pointer is over the control")
end)

toggle:Set(true, true) -- emits Changed and calls the control callback
changed:Disconnect()   -- explicitly cancels the subscription
```

To observe key assignment separately from the key action:

```lua
local keybind = section:Keybind({
    Id = "actionKey",
    Title = "Shortcut",
    Value = "F6",
    Callback = function(keyName)
        print("Shortcut action:", keyName)
    end,
})

keybind:On("Changed", function(newKey, oldKey)
    print("Assigned key:", oldKey, "→", newKey)
end)
-- Click the control and press a key to change the assignment only.
-- Press that key afterward, outside capture mode, to run the Callback.
```

`window:Connect(signal, callback)` and `control:Connect(signal, callback)` connect to an `RBXScriptSignal`. They return the Roblox connection. Connections registered through `control:Connect` are disconnected with the control; those registered through `window:Connect` are disconnected with the window.

```lua
local RunService = game:GetService("RunService")
local control = section:Paragraph({Title = "Status"})

control:Connect(RunService.Heartbeat, function(deltaTime)
    -- Example: update data while the control is alive.
end)
```

`window:Own(resource)` and `control:Own(resource)` accept an `RBXScriptConnection` or a table with a `Disconnect()` method; a function by itself is not a valid resource. This lets you register a Roblox connection or a subscription returned by `On`. When its owner is destroyed, the library attempts each disconnection independently: if one fails, it records the error in `window.LastError`, sends it to `warn`, and continues cleaning up the other resources. A developer-provided `Disconnect()` must be synchronous, must not yield, and should be idempotent so repeated calls are safe. Destroying the window also cleans up its controls, connections, subscriptions, tweens, and notifications. Use `window:OnDestroy(callback)` to release resources external to the library; tasks started directly by your code remain your responsibility and are not cancelled by UI owner destruction.

## Custom controls

`section:Custom(options)` creates a control with no predefined value and provides a `Content` container for building a free-form Luau interface. `Height` defaults to 80 and accepts a number from 0 to 2000. `Build` receives `(content, control, window, options)`.

```lua
local custom = section:Custom({
    Id = "preview",
    Title = "Animated preview",
    Description = "A small element built in Studio.",
    Height = 72,
    Build = function(content, control, window, options)
        local chip = Instance.new("Frame")
        chip.Name = "Chip"
        chip.Size = UDim2.fromOffset(110, 32)
        chip.Position = UDim2.fromOffset(0, 8)
        chip.Parent = content
        window:BindColor(chip, "BackgroundColor3", "Raised")

        local button = Instance.new("TextButton")
        button.Name = "Pulse"
        button.Size = UDim2.fromScale(1, 1)
        button.BackgroundTransparency = 1
        button.Text = "Animate"
        button.TextColor3 = window.Theme.Text
        button.Parent = chip

        control:Connect(button.Activated, function()
            window:Animate(chip, {
                Size = UDim2.fromOffset(150, 38),
            }, {
                Duration = 0.22,
                Style = Enum.EasingStyle.Back,
                OnComplete = function()
                    window:Animate(chip, {
                        Size = UDim2.fromOffset(110, 32),
                    }, {Duration = 0.18})
                end,
            })
        end)
    end,
})

custom:SetHeight(88) -- resizes Content while the control is alive
```

The library owns `control.Root` and `control.Content`. Add and arrange child instances inside `content`; leave the control in the container where it was created, and do not destroy its `Root` or `Content` directly. `control:Destroy()` cleanly removes the control and its connections. Use `SetVisible` and `SetEnabled` to control visibility and interaction.

### Make a `Custom` control responsive to available width

The builder is responsible for a `Custom` control's internal dimensions. Use relative widths, wrapped text, and `AutomaticSize` so content can reflow. This example recalculates height after a width change without creating a render loop: it calls `SetHeight` only when the calculated height changes. The button keeps a touch target at least 44 px high.

```lua
local responsiveCustom = section:Custom({
    Id = "responsiveCard",
    Title = "Responsive card",
    Height = 80,
    Build = function(content, control, window, options)
        local description = Instance.new("TextLabel")
        description.BackgroundTransparency = 1
        description.Text = "This text wraps across multiple lines as the card gets narrower."
        description.TextWrapped = true
        description.AutomaticSize = Enum.AutomaticSize.Y
        description.TextXAlignment = Enum.TextXAlignment.Left
        description.TextYAlignment = Enum.TextYAlignment.Top
        description.Size = UDim2.new(1, 0, 0, 0)
        description.Parent = content

        local action = Instance.new("TextButton")
        action.Text = "Continue"
        action.Size = UDim2.new(1, 0, 0, 44)
        action.Parent = content

        local currentHeight = options.Height or 80
        local function relayout()
            if control.Destroyed then return end
            local textHeight = description.AbsoluteSize.Y
            action.Position = UDim2.new(0, 0, 0, textHeight + 8)
            local nextHeight = textHeight + 8 + 44
            if nextHeight ~= currentHeight then
                currentHeight = nextHeight
                control:SetHeight(nextHeight)
            end
        end

        control:Connect(content:GetPropertyChangedSignal("AbsoluteSize"), function()
            task.defer(relayout)
        end)
        task.defer(relayout)
    end,
})
```

`task.defer` lets Roblox recalculate text sizes before measurement; the size-change signal does not create a loop because `SetHeight` is called only when the result differs. No access to private window layout or per-frame update is needed. This example describes expected layout behavior; it has not been verified on a physical phone.

## Register a reusable component

`UI:RegisterComponent(name, builder)` registers a unique name in this library instance. The builder uses the same signature as `Custom.Build`. Then `section:Add(name, options)` creates the component and returns the custom control.

```lua
UI:RegisterComponent("StatusBadge", function(content, control, window, options)
    local badge = Instance.new("TextLabel")
    badge.Name = "Badge"
    badge.Size = UDim2.new(1, 0, 0, 32)
    badge.BackgroundTransparency = 0
    badge.Text = options.Text or "Ready"
    badge.Parent = content
    window:BindColor(badge, "BackgroundColor3", options.ColorToken or "Raised")
    window:BindColor(badge, "TextColor3", "Text")

    control:Connect(badge.MouseEnter, function()
        window:Animate(badge, {TextTransparency = 0.25}, {Duration = 0.1})
    end)
    control:Connect(badge.MouseLeave, function()
        window:Animate(badge, {TextTransparency = 0}, {Duration = 0.1})
    end)
end)

local badge = section:Add("StatusBadge", {
    Title = "Service status",
    Description = "A reusable component.",
    Height = 40,
    Text = "Everything is working",
    ColorToken = "Surface",
})
```

`Title` defaults to the component name when omitted. `Height`, `Id`, `Description`, and other options are passed to the control and the builder. A name already registered cannot be replaced in the same library instance.

`UI:GetComponentNames()` returns registered names in alphabetical order. `UI:UnregisterComponent(name, expectedBuilder)` removes the component and returns `true`; it returns `false` if the name does not exist or the supplied builder no longer matches. The optional `expectedBuilder` parameter prevents removal of a registration that another module has replaced.

For the declarative API, use the registered name as the `Type` value:

```lua
local customWindow = UI:Create({
    Id = "CustomExample",
    Tabs = {{Title = "Home", Controls = {{
        Type = "StatusBadge",
        Id = "serviceStatus",
        Title = "Service status",
        Height = 40,
        Text = "Everything is working",
        ColorToken = "Surface",
    }}}},
})
```
