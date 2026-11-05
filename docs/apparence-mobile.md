# Appearance and mobile

## Choose a design

Replace your window creation with:

```lua
local window = UI:CreateWindow("My menu", {
    Design = "Atelier", Width = 800, Height = 590,
    Responsive = {TouchTarget = 48, LandscapeHeight = 500},
    Layout = {MobileTabPosition = "Bottom"},
})
```

Then add your tabs and controls.

| Design | Appearance | Navigation |
|---|---|---|
| `Studio` | Graphite, comfortable | Left, `Soft` |
| `Minimal` | Graphite, compact, sharp | Left, `Classic` |
| `Command` | Near-black, spacious | Top, `Pill` |
| `Atelier` | Monochrome, comfortable | Left, `Rail` |

Explicit `Theme`, `Style`, `Layout` and `Navigation` override the preset. A custom schema can use `Design = {Preset = "Atelier", Accent = Color3.fromRGB(120, 184, 255), Radius = 12}`.

## Update an existing window

```lua
window:SetTheme("Aurora")
window:SetStyle({TextSize = 14, WindowRadius = 16})
window:SetLayout({TabPosition = "Left", MobileTabPosition = "Bottom"})
window:SetNavigation({Variant = "Rail", IconVariant = "Outline"})
window:SetReducedMotion(true)
```

Themes: `Graphite`, `Aurora`, `Ember`. Navigation: `Classic`, `Soft`, `Pill`, `Rail`.

To let players customize their interface:

```lua
window:Appearance({Title = "Appearance"})
```

This adds an editor tab whose settings are excluded from application profiles.

## Mobile behavior

The window accounts for safe insets and the keyboard. Wide inputs stack below their labels; toggles stay inline when room permits. Narrow windows and short touch landscapes use horizontal tabs.

| Responsive option | Default | Range |
|---|---:|---|
| `Breakpoint` | 620 | 320-1000 px: window width below which mobile layout applies |
| `TouchTarget` | 44 | 44-72 px: minimum size of affected controls |
| `Margin` | 12 | 4-40 px: outer margin |
| `LandscapeHeight` | 500 | 0-700 px: maximum safe height selecting mobile layout on a touch landscape; 0 disables this rule |

Landscape classification uses the safe screen before keyboard occlusion. A tablet keyboard does not classify the tablet as a phone. Rotation and keyboard changes recover a dragged panel inside the visible area.

Short layouts reduce the header and hide the subtitle and footer. Compact layouts hide search unless focused; panels below 260 px hide search even when focused. Tabs remain visible from 140 px of panel height. Test native rendering and gestures on physical devices in your project.

## Icons and branding

```lua
local home = window:Tab("Home", "home")
home:Button("Refresh", {Icon = "refresh", IconVariant = "Duotone"}, function()
    print("Refresh")
end)
window:SetBranding({Mode = "Initials", Text = "G", Placement = "TopLeft"})
```

See the [icon catalogue](reference/icones.md). Internal icon IDs are not Roblox image asset IDs. `Mode = "Avatar"` uses an avatar; `Mode = "Image"` requires a valid `Image` URI beginning with `rbxassetid://`.

`SetPartLayout` overrides apply after automatic layout, so check your coordinates on small screens. See [exact defaults](reference/options.md) for option tables.
