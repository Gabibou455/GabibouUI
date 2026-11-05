# Buttons and controls

Use the `tab` and `window` from [Getting started](demarrer.md). Add these calls after creating the tab. The same control methods work on sections.

| Player action | Control | Callback receives |
|---|---|---|
| Run an action | `Button` | No arguments |
| Enable or disable | `Toggle` | Boolean |
| Adjust a number | `Slider` | Number |
| Choose an item | `Dropdown` | Selected option string |
| Enter text | `Input` | Changed text when focus is lost |
| Assign a shortcut | `Keybind` | Key name when pressed |
| Pick a color | `ColorPicker` | `#RRGGBB` string |
| Display text | `Paragraph` | No callback |

## Button

```lua
tab:Button("Refresh", {Text = "Run", Variant = "Primary"}, function()
    window:Notify({Title = "Refresh requested"})
end)
```

`Text` is the button caption, separate from the row title. `Variant` accepts `Primary` (default), `Secondary` and `Subtle`. Activating the button runs its callback.

## Toggle

```lua
local effects = tab:Toggle("Effects", {Id = "effects", Value = true}, function(enabled)
    print("Effects:", enabled)
end)
```

`Value` defaults to `false`. The callback receives a boolean after a change. `effects:Get()` reads the current value.

## Slider

```lua
local volume = tab:Slider("Volume", {
    Id = "volume", Min = 0, Max = 100, Step = 5, Value = 50,
}, function(value)
    print("Volume:", value)
end)
```

Defaults: `Min = 0`, `Max = 100`, `Step = 1`, `Value = Min`. Require `Max > Min` and `Step > 0`. Values are clamped and rounded to steps counted from `Min`. On mobile, horizontal drags adjust values, vertical swipes scroll, and taps select on release.

## Dropdown

```lua
local quality = tab:Dropdown("Quality", {
    Id = "quality", Options = {"Low", "Medium", "High"}, Value = "Medium",
}, function(choice)
    print("Quality:", choice)
end)
```

`Options` requires unique, nonempty strings. `Value` must match an option; the first is selected if omitted. `quality:SetOptions({"Low", "High"})` keeps the current selection when possible, otherwise selects the first option.

## Input

```lua
tab:Input("Player name", {Placeholder = "Enter a name", MaxLength = 24}, function(text)
    print("Player name:", text)
end)
```

The callback receives changed text when the field loses focus. `MaxLength` defaults to 120 and accepts 1-4096 UTF-8 characters.

## Keybind

```lua
tab:Keybind("Action", {Value = Enum.KeyCode.F6}, function(keyName)
    print("Key:", keyName)
end)
```

Activate the field and press a key to assign it. The callback runs when that key is later pressed outside text entry. `Value` accepts an `Enum.KeyCode` or its name, defaulting to `F6`. Also provide a visible button for touch users.

## ColorPicker

```lua
local color = tab:ColorPicker("Color", {
    Value = "#78B8FF", Palette = {"#78B8FF", "#A18FFF", "#F08B8B"},
}, function(hex)
    print("Color:", hex)
end)
```

The callback and `color:Get()` return `#RRGGBB`. `color:GetColor()` returns a `Color3`. `Value` also accepts a `Color3`; a custom palette accepts 1-32 colors.

## Paragraph and Section

```lua
tab:Paragraph("Information", {Description = "Settings belong to this session."})
local audio = tab:Section("Audio")
audio:Toggle("Music", {Value = true}, function(enabled)
    print("Music:", enabled)
end)
```

A section groups controls in a tab. A category groups tabs: `window:Category("Settings"):Tab("Audio", "volume")`.

## Common options

| Option | Purpose |
|---|---|
| `Id` | Find the control using `window:Get(id)` |
| `Description` | Help text below the title |
| `Disabled = true` | Start disabled |
| `Persistent = false` | Exclude its value from profiles |
| `Layout` | Width, height, order or placement |

Control options do not all apply to navigation containers such as sections. See [Values and profiles](valeurs-profils.md) for later updates and [API methods](reference/api.md) for custom controls.
