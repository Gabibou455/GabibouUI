# Install and create a menu

## 1. Choose a loader

### Roblox Studio

1. Copy the complete [standalone module](https://github.com/Gabibou455/GabibouUI/blob/main/gabibou_ui.luau).
2. Create a **ModuleScript** named exactly `GabibouUI` in `ReplicatedStorage` and replace its contents with the copied source.
3. Create a **LocalScript** under `StarterPlayer > StarterPlayerScripts`.
4. Start that LocalScript with:

```lua
local UI = require(game:GetService("ReplicatedStorage"):WaitForChild("GabibouUI"))
```

Start **Play** to see the menu. The interface runs on the client.

### A client providing loadstring and game:HttpGet

Use this loader:

```lua
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Gabibou455/GabibouUI/main/gabibou_ui.luau"))()
```

Both functions are required. In standard Studio, use the ModuleScript setup above. The `main` URL follows updates; pin an existing [release tag](https://github.com/Gabibou455/GabibouUI/releases) when you need a fixed version.

## 2. Create your menu

Paste this directly after your chosen loader in the same script:

```lua
local window = UI:CreateWindow("My menu")
local tab = window:Tab("Home", "home")

tab:Button("Say hello", function()
    window:Notify({Title = "Hello!", Kind = "success"})
end)

tab:Toggle("Enable effects", {Value = false}, function(enabled)
    print("Effects:", enabled)
end)

tab:Slider("Volume", {Min = 0, Max = 100, Value = 50}, function(value)
    print("Volume:", value)
end)
```

The button shows a notification. The toggle and slider print their new values in Output. Replace those `print` calls with your project behavior.

## 3. Understand a control call

```lua
local effects = tab:Toggle("Effects", {Id = "effects", Value = true}, function(enabled)
    print(enabled)
end)
```

| Part | Meaning |
|---|---|
| `"Effects"` | Displayed title |
| Options table | Initial value and stable ID |
| Callback function | Runs after a player changes the control |
| Returned `effects` handle | Provides `Get()`, `Set()` and other methods |

The same control can use a single options table:

```lua
local effects = tab:Toggle({
    Id = "effects", Title = "Effects", Value = true,
    Callback = function(enabled) print(enabled) end,
})
```

Choose one form; do not create both with the same ID. IDs must be unique within a window. Creation does not run the callback. `effects:Set(false, true)` calls it if the value changes; `effects:Set(false)` updates silently.

Next: [complete example](exemple-complet.md) or [all controls](composants.md).
