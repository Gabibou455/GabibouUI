-- Studio: put the GabibouUI ModuleScript in ReplicatedStorage,
-- then put this code in a LocalScript under StarterPlayerScripts.
local UI = require(game:GetService("ReplicatedStorage"):WaitForChild("GabibouUI"))
-- Compatible client: replace only the require above with:
-- local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Gabibou455/GabibouUI/main/gabibou_ui.luau"))()

local Lighting = game:GetService("Lighting")
local defaults = {
    shadows = Lighting.GlobalShadows,
    brightness = Lighting.Brightness,
    theme = "Graphite",
}

local window = UI:CreateWindow("My menu", {
    Id = "GabibouQuickstart",
    Design = "Atelier",
    Theme = defaults.theme,
    Responsive = {TouchTarget = 48},
    Layout = {MobileTabPosition = "Bottom"},
})

local tab = window:Tab("Settings", "settings")
local graphics = tab:Section("Game display")

graphics:Toggle("Shadows", {Id = "shadows", Value = defaults.shadows}, function(enabled)
    Lighting.GlobalShadows = enabled
end)

graphics:Slider("Brightness", {
    Id = "brightness", Min = 0, Max = 5, Step = 0.1, Value = defaults.brightness,
}, function(value)
    Lighting.Brightness = value
end)

tab:Dropdown("Theme", {
    Id = "theme", Options = {"Graphite", "Aurora", "Ember"}, Value = defaults.theme,
}, function(theme)
    window:SetTheme(theme)
end)

tab:Button("Reset settings", {Text = "Reset", Variant = "Secondary"}, function()
    window:SetValues(defaults, true)
    window:Notify({Title = "Settings reset", Kind = "success"})
end)

-- The profile editor restores controls without running callbacks.
-- Apply displayed values to the game explicitly.
tab:Button("Apply displayed values", {Text = "Apply"}, function()
    local values = window:GetValues()
    Lighting.GlobalShadows = values.shadows
    Lighting.Brightness = values.brightness
    window:SetTheme(values.theme)
end)

window:Command({
    Id = "status", Title = "Show status", Icon = "info",
    Callback = function()
        window:Notify({Title = "Interface ready", Content = "Version " .. UI.Version})
    end,
})

tab:Button("Commands", {Text = "Open"}, function()
    window:OpenCommands()
end)

window:Presets({Title = "Profiles"})
window:Appearance({Title = "Appearance"})
