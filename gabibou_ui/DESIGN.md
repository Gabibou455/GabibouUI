# Gabibou UI — visual direction and interaction contract

## Visual direction

Navigation variants are Classic, Soft, Pill, and Rail; Soft is the default. Rail gives the selected tab a distinct icon tile while keeping its label neutral and visible. Native icons have three treatments: Outline, Soft, and Duotone. The icon catalogue covers tabs, farming, inventory, tools, and window controls. Each drawing has a stable ID listed in [ICONS.md](ICONS.md); the gallery shows both name and ID. Icon and navigation variants can change without replacing pages or losing values.

Surfaces use charcoal tones, a subtly shaded header, fine borders, and illustrated window actions. The visual direction uses dark desktop interfaces as a broad reference; Gabibou UI's source and drawings are original to this project.

Earlier Roblox captures are documented in [VALIDATION.md](VALIDATION.md). The screenshots there show prior iterations; check the report for which changes were verified by engine assertions.

## Historical native reference

The Roblox screenshots [notifications.png](notifications.png), [key.png](key.png), [layout.png](layout.png), [loading.png](loading.png), and [mobile.png](mobile.png) show earlier native rendering. `preview.html` retains the version 1.2 composition; native screenshots are the reference for later additions.

Notifications use a compact card, a type icon in a badge, a title distinct from its content, a transparent close button with a 44 px target, and a duration bar. The stack supports four corners and removes older cards when vertical space runs short. Animated dismissal and immediate cleanup are separate operations.

The access screen has a field, status, and two 44 px actions. It moves into a scrolling area when the keyboard or reduced height limits available space. The main window supports tabs on all four sides and an independent mobile placement. Controls can sit to the left, right, or below their label; they move below when the row is too narrow.

Gabibou UI is an original Roblox interface library written in Luau. This document sets visual and interaction guidelines for native `ScreenGui`, `Frame`, `TextLabel`, `TextButton`, `TextBox`, `ScrollingFrame`, `UICorner`, `UIStroke`, `UIPadding`, `UIListLayout`, and `UIGridLayout` elements. The HTML mockup is a composition reference and does not claim to reproduce every Roblox rendering capability.

## Intent

The demo is a small interface workshop that shows real library features. Each page answers a concrete question: where am I, which controls are available, how do I change the appearance, and how do I save a configuration? Graphite stays black, gray, and white. Layered surfaces, shadows, and fine borders provide depth; color marks selection, focus, or the chosen accent. Controls state their behavior clearly. Text describes a function or observable state without slogans or gameplay promises.

## Visual tokens

Colors below are hexadecimal mockup values. In Luau, convert them with `Color3.fromRGB(r, g, b)`.

| Token | Value | Use |
|---|---|---|
| `Background` | `#0E0F12` | Window surface |
| `Surface` | `#17191D` | Row, menu, or base card |
| `Raised` | `#202328` | Raised controls |
| `Hover` | `#2A2D33` | Hover and secondary selection |
| `Border` | `#3D4149` | Borders |
| `Text` | `#F5F6F8` | Primary text |
| `Muted` | `#9DA2AD` | Help text |
| `Accent` | `#F2F4F8` | Graphite selection and action |
| `AccentText` | `#131519` | Text on the accent |
| `Success` | `#AAD0B5` | Success state |
| `Danger` | `#F08B8B` | Error or destructive confirmation |

Depth comes from layered panels, a 1 px border, and offset shadows. Graphite uses a solid accent and a fine white top edge.

### Built-in themes

| Theme | `Accent` | `AccentText` |
|---|---|---|
| Graphite (default) | `#F2F4F8` | `#131519` |
| Aurora | `#A18FFF` | `#120F1E` |
| Ember | `#FFA671` | `#21140E` |

The built-in themes are `Graphite`, `Aurora`, and `Ember`. `Custom` is not a preset: `Window:SetTheme` accepts a partial token table, and the `ColorPicker` can choose a custom accent. State must remain identifiable by an icon or label as well as color.

### Size scale

| Element | Size / spacing |
|---|---|
| Demo window | `860 × 620 px`; library default is `800 × 590 px` |
| Title bar | `60 px`, plus a `9 px` top inset |
| Search | `44 px` high; desktop left rail is `168 px`, full width on mobile |
| Desktop navigation | `168 px` rail; five vector-icon tabs with 44 px touch targets |
| Content area | Page title to the right of the rail; `202 px` from the window's left edge |
| Window radius | `14 px` default; configurable with `WindowRadius` |
| Section radius | `10 px` default; configurable with `SectionRadius` |
| Control radius | `7 px` default; configurable with `ControlRadius` |
| Interactive control height | At least `44 px` |
| Section spacing | `10 px` |
| Label / description gap | `5 px` |
| Icons | `16–18 px`, one consistent visual family |
| Primary text | `13–14 px`; Roblox `TextSize = 13` equivalent |
| Control title | `14 px`, bold |
| Window title | `17 px`, bold |
| Section title | `13 px`, bold |
| Help text | `12 px`, contrasted and readable |

On phones, use touch targets at least `44 × 44 px`. Stack the label above its control when a row becomes too narrow.

## Composition

1. **Window:** Soft outer shadow, `Background` body, fine border, and white top edge. Keep the depth subtle; use no textures or particles.
2. **Title bar:** Configurable branding. The demo uses the user's avatar and can place it at the top right, bottom right, or both. Keep `Gabibou / Studio`, the `Interface workshop` subtitle, and the minimize and close actions readable.
3. **Desktop:** Search occupies a `168 px` left rail above the five `Overview`, `Controls`, `Appearance`, `Profiles`, and `Extensions` tabs. Each tab uses an original vector icon from the shared catalogue. Place the page title above the content area to the right. Keep the rail distinct from content without repeating a card around every control.
4. **Sections:** Give each section one `Surface`, a border, and a radius. Keep controls transparent with fine separators. Do not put the introductory paragraph inside a card.
5. **Overview:** A `Session` paragraph, theme/motion/layout state that updates with the window, and buttons to Controls, Appearance, and Extensions.
6. **Controls:** `Values` and `Text and shortcuts` sections for notifications, duration and style, messages, shortcuts, sending, and confirmation.
7. **Appearance:** `Colors` and `Shape and motion` sections for the three themes, accent, radius, speed, reduced motion, and visibility.
8. **Profiles and Extensions:** In-memory JSON session profiles and a Meter registered through the extension API, with level, curve, and animation action.
9. **Mobile:** Below `620 px`, search uses the window width and tabs form a horizontally scrolling strip. Hide the page title; use available width for sections and stack each label above its control. Keep a `12 px` margin and prevent horizontal overflow.
10. **Footer:** Version and desktop visibility-key hint, with a quiet status and no slogan.
11. **Loading:** An independent overlay shows the logo, title, status, and actual progress supplied by the application. Reduced motion disables the activity animation. `Complete` finishes the display and destroys its resources.

## Control contract

The public API is in `ui.luau`. Calls use `Tab`, `Section`, `Toggle`, and direct container methods. Controls accept `Id`, `Title`, and `Description`/`Desc`; interactive actions accept `Callback` and `Disabled`, and persistent values also accept `Persistent`. Read values with `Get()` and change them with `Set(value, fireCallback)`.

```lua
local window = Library:CreateWindow({
    Title = "Gabibou / Studio",
    Subtitle = "Interface workshop",
    Width = 860, Height = 620,
    ToggleKey = Enum.KeyCode.RightControl,
    Theme = "Graphite",
    Responsive = { Breakpoint = 620, TouchTarget = 44, Margin = 12 },
})

local tab = window:Tab({ Title = "Controls" })
local section = tab:Section({ Title = "Values" })
local toggle = section:Toggle({ Title = "Example toggle", Value = false, Callback = function(value) end })
local color = section:ColorPicker({
    Title = "Highlight color",
    Value = "#A18FFF", -- Color3.fromRGB(161, 143, 255) is also accepted
    Palette = { "#F2F4F8", "#A18FFF", "#78B8FF" },
    Callback = function(hex) end,
})
```

| Method | Main options | Behavior / handle |
|---|---|---|
| `Library:Create(spec)` | CreateWindow options at the root, `Tabs`, `Loading` | Validates the schema, then builds tabs, sections, and declarative controls. Control IDs are required and unique. `Loading` accepts `true` or a loader configuration; progress follows the number of controls created. |
| `Library:CreateWindow(options)` | `Title`, `Subtitle`, `Width`, `Height`, `ToggleKey`, `Theme`, `Responsive`, `Parent`, `DisplayOrder`, `ReducedMotion`, `Storage` | Returns `window`; defaults to `800 × 590`, Graphite, and RightControl. `Responsive` accepts `Breakpoint` (`320–1000`, default `620`), `TouchTarget` (`44–72`, default `44`), and `Margin` (`4–40`, default `12`). |
| `window:Tab({Title, Icon})` / `tab:Section({Title})` | Title and optional icon name | Creates a tab and vertical section. `window:SelectTab(tabOrIndex)` changes tabs. Unknown icon names are rejected. |
| `window:Get(id)` | Control ID | Returns the control or nil. |
| `window:GetValues()` / `window:SetValues(values, fireCallbacks?)` | Table mapping IDs to values | Reads a copy of persistent values. Writes reject missing/nonpersistent IDs and validate all values before applying; returns the number applied. Callbacks are optional and asynchronous tasks do not guarantee execution order. |
| `container:Button(options)` | `Title`, `Description`/`Desc`, `Text`, `Callback`, `Disabled` | Action button; callback runs on activation. |
| `container:Toggle(options)` | `Id`, `Title`, `Description`/`Desc`, `Value`, `Callback`, `Disabled`, `Persistent` | Boolean value; supports `Get()` and `Set(value, fireCallback)`. |
| `container:Slider(options)` | `Title`, `Min`, `Max`, `Step`, `Value`, `Callback`, `Persistent` | Quantized value; drag or touch its track, or use left/right arrows while focused. |
| `container:Dropdown(options)` | `Title`, `Options`, `Value`, `Callback`, `Persistent` | Menu; `SetOptions(values, value?)` updates available choices. |
| `container:ColorPicker(options)` | `Title`, `Description`/`Desc`, `Value`, `Palette`, `Callback`, `Persistent` | `Value` accepts `#RRGGBB` or `Color3`. `Get()` returns hex; `GetColor()` returns `Color3`; `Set(value, fireCallback)` accepts either format. `Palette` has `1–32` hex colors (default: 12). Hex input validates on focus loss; invalid input restores the prior value and reports an error. |
| `container:Input(options)` | `Title`, `Value`, `Placeholder`, `MaxLength`, `Callback`, `Persistent` | Text input validated on focus loss. |
| `container:Keybind(options)` | `Title`, `Value`, `Callback`, `Persistent` | Captures a `KeyCode`; Escape cancels. |
| `container:Paragraph(options)` | `Title`, `Description`/`Desc` | Information row. |
| `window:Notify(options)` / `window:Confirm(options)` | `Title`, `Content`, `Duration`, `Kind`; confirmation also uses `ConfirmText`, `Callback` | Toasts are capped at four; confirmation uses a modal with cancel and confirm actions. |
| `window:SetStyle(tokens)` | `Font`, `FontBold`, `TextSize`, `DescriptionSize`, `TitleSize`, `WindowRadius`, `SectionRadius`, `ControlRadius`, `RowPadding` | Updates existing styles and emits `StyleChanged`. Defaults: 17 px window title, 14/12 px control/help text, 14/10/7 px radii, and 14 px padding. |
| `window:SetMotion(options)` | `Duration`, `Style`, `Direction`, `RepeatCount`, `Reverses`, `Delay` | Changes window animations; duration and delay are capped at 30 seconds. `ReducedMotion` disables movement animations. |

`Id` is accepted by all controls. Containers and controls expose `SetVisible` and `Destroy`; controls also expose `SetTitle`, `SetDescription`, `SetEnabled`, `Get`, and `Set`. JSON persistence uses `ExportConfig`/`ImportConfig`; `SaveConfig`/`LoadConfig` require a caller-provided `Storage.Read/Write` adapter.

### Icons, branding, and loading

The registry provides original vector icons documented in [ICONS.md](ICONS.md). `Library:GetIconNames()` returns sorted names; `GetIconCatalogue()` returns `{Id, Name}` pairs sorted by ID. `RegisterIcon` and `UnregisterIcon(name, expectedBuilder?)` manage custom additions. Tabs accept `Icon = "farm"` or `Icon = 21`; drawings are Luau Frames and need no external image.

`window:SetBranding(options)` accepts `Mode` Avatar, Image, or Initials and `Placement` TopLeft, TopRight, BottomRight, or BothRight, with `Text`, `Image = "rbxassetid://…"`, and `UserId`. Avatar requests are cancelled on reconfiguration or destruction. On very small windows, right-side widgets hide to preserve title space.

`Library:CreateLoader(options)` returns an independent loader. `SetProgress(ratio, status?)` expects a ratio from 0 to 1; `SetStatus(text)` changes only the status; `Complete(status?)` sets progress to 100%, respects `MinimumDuration`, cleans the GUI, and calls `OnComplete`. `Destroy()` cancels progress, avatar, and exit timer. The loader accepts a theme and Avatar or `rbxassetid://…` logo; the calling application must provide real setup steps.

`Library:Create` accepts `CreateWindow` options at the root with `Tabs` and `Loading`. Each tab may contain `Controls` and `Sections`; sections may contain `Controls`. Nine built-in control types are Toggle, Slider, Dropdown, Input, Keybind, ColorPicker, Button, Paragraph, and Custom. A type registered with `RegisterComponent` is also accepted. `GetComponentNames()` returns sorted names; `UnregisterComponent(name, expectedBuilder?)` prevents an older reload from removing a newer registration. Control IDs are required and unique in each window.

### Extensions

`Library:RegisterComponent(name, builder)` registers a reusable constructor; `section:Add(name, options)` creates that control in a section. The constructor receives `(root, control, owner, options)`. `root` belongs to the library and is destroyed with its control. The owner exposes methods such as `BindColor(instance, property, token)`, `Animate(instance, properties, options)`, `On(eventName, callback)`, `Connect(signal, callback)`, and `Own(connection)`. Subscriptions and animations are tied to the window and cleaned up when it is destroyed. The demo uses this API for Meter.

```lua
Library:RegisterComponent("Meter", function(root, control, owner, options)
    local fill = Instance.new("Frame")
    fill.Parent = root
    owner:BindColor(fill, "BackgroundColor3", "Accent")
    function control:Update(ratio, instant)
        self.Value = math.clamp(ratio, 0, 1)
        owner:Animate(fill, { Size = UDim2.new(self.Value, 0, 1, 0) }, instant and { Duration = 0 } or nil)
    end
    control:Update(options.Value or 0, true)
end)

local meter = section:Add("Meter", { Title = "Level", Height = 52, Value = 0.4 })
meter:Update(0.75)
```

## Search, theme, and navigation

- Search filters tabs and controls by title, description, and tab title. It selects the first tab with a result and shows an empty state when nothing matches.
- Built-in themes are `Graphite` (default), `Aurora`, and `Ember`. A theme is a token table, not scattered color branches. A custom table can override selected tokens.
- `window:SetTheme(nameOrTable)` applies supported tokens to existing elements. A custom table accepts the theme keys listed above.
- Tab selection persists through resizing. Selecting a tab does not automatically move focus to the page title.

## Window, mobile, and recovery

- `window:Hide()` hides the interface and closes temporary menus. It does not destroy connections or control state.
- `window:Show()` restores the last page and visible state. `window:Toggle()` switches between these states.
- The visibility key is configurable. An accessible icon can also hide the window. Call `window:Destroy()` for full destruction and connection cleanup.
- Below `Responsive.Breakpoint` (default `620 px`), navigation becomes a horizontally scrolling strip. Sections use the available width; controls move below their labels and help text. Tab buttons and touch controls are at least `Responsive.TouchTarget` high (default `44 px`). `Responsive.Margin` (default `12 px`) keeps the window inside the safe area.
- Search is `44 px` high. Interactive controls and color swatches are at least `Responsive.TouchTarget` high.
- ColorPicker opens a panel with a hex field and `Palette`. Its grid uses `1–4` columns based on available width, with cells as high as `Responsive.TouchTarget`; it recalculates columns after resizing.
- On viewport resize or rotation, recalculate width and height using `Responsive.Margin`, keep the window onscreen, and reflow for the new `ViewportSize`.
- Existing transitions last `0.16 s` with `Quad.Out`; `ReducedMotion` can disable them.

## JSON profiles (optional)

Persistence is opt-in. `ExportConfig()` returns a JSON string for persistent controls; `ImportConfig(json, fireCallbacks)` validates and applies values. No disk storage is implicit.

```lua
local json = window:ExportConfig()
window:ImportConfig(json, false)
window:SaveConfig("default") -- requires Storage.Write(path, contents)
window:LoadConfig("default") -- requires Storage.Read(path)
```

Profile names accept letters, numbers, `_`, and `-`, up to 48 characters. The calling application owns the storage adapter.

## States and readability

- Define normal, hover, pressed, keyboard focus, active, disabled, loading (for asynchronous actions), and error/validation states.
- Never communicate state through color alone: add an On/Off label, checkmark, icon, or help text.
- Keep primary text readable on every surface; secondary descriptions may be quieter but must remain legible.
- Keep disabled controls visible and explain why they are unavailable when possible.
- Animations must not block input, accumulate tweens, or connect an event on every frame.

## Reference limits

`preview.html` shows the demo's five pages, icons, branding, and loader. Its values, notifications, theme, shortcut, progress, and profiles exist only in the mockup; it does not simulate Roblox effects or real loading progress. Roblox does not guarantee background blur, and the mockup cannot predict rendering on a physical phone. Validate the layout in Roblox on the devices you support.

## Responsive direction

The four built-in design presets are `Studio`, `Minimal`, `Command`, and `Atelier`. Atelier pairs monochrome surfaces with comfortable spacing, left-side tabs, Rail navigation, and `0.08` panel transparency. Presets are starting points: `UI:Design` combines theme, accent, density, radius, transparency, tab placement, and navigation. The existing `SetTheme`, `SetStyle`, `SetLayout`, `SetNavigation`, `SetMotion`, and `SetReducedMotion` methods refine the current window; these visual changes do not require a separate UI fork.

At a `375 px` width, the default `620 px` responsive breakpoint activates the mobile layout. Rail keeps page labels visible, and the tab strip scrolls horizontally when tabs do not fit. Keep touch targets at least `44 px`, preserve the default `12 px` margin, retain readable titles and descriptions, and place controls below labels when rows become narrow. Check both `375 × 667 px` and the same viewport with the keyboard open. Choose `MobileTabPosition = "Bottom"` or `"Top"` for the page and avoid icon-only tab labels.

Panel transparency from `0.08` to `0.12` lets a little of the scene show through; `0` is opaque and `1` is fully transparent. Use `SetMotion` to choose transition duration and `SetReducedMotion(true)` when motion adds no useful information. `Outline`, `Soft`, and `Duotone` icon variants apply to navigation or an individual tab without removing its title.

