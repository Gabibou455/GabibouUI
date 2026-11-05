-- Studio : ModuleScript GabibouUI dans ReplicatedStorage,
-- puis ce code dans un LocalScript sous StarterPlayerScripts.
local UI = require(game:GetService("ReplicatedStorage"):WaitForChild("GabibouUI"))
-- Client compatible : remplace uniquement le require ci-dessus par :
-- local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Gabibou455/GabibouUI/main/gabibou_ui.luau"))()

local Lighting = game:GetService("Lighting")
local defaults = {
    shadows = Lighting.GlobalShadows,
    brightness = Lighting.Brightness,
    theme = "Graphite",
}

local window = UI:CreateWindow("Mon menu", {
    Id = "GabibouQuickstart",
    Design = "Atelier",
    Theme = defaults.theme,
    Responsive = {TouchTarget = 48},
    Layout = {MobileTabPosition = "Bottom"},
})

local tab = window:Tab("Reglages", "settings")
local graphics = tab:Section("Affichage du jeu")

graphics:Toggle("Ombres", {Id = "shadows", Value = defaults.shadows}, function(enabled)
    Lighting.GlobalShadows = enabled
end)

graphics:Slider("Luminosite", {
    Id = "brightness", Min = 0, Max = 5, Step = 0.1, Value = defaults.brightness,
}, function(value)
    Lighting.Brightness = value
end)

tab:Dropdown("Theme", {
    Id = "theme", Options = {"Graphite", "Aurora", "Ember"}, Value = defaults.theme,
}, function(theme)
    window:SetTheme(theme)
end)

tab:Button("Reinitialiser les reglages", {Text = "Reinitialiser", Variant = "Secondary"}, function()
    window:SetValues(defaults, true)
    window:Notify({Title = "Reglages reinitialises", Kind = "success"})
end)

-- L'editeur de profils restaure les champs sans lancer leurs callbacks.
-- Ce bouton applique explicitement les valeurs affichees au jeu.
tab:Button("Appliquer les valeurs affichees", {Text = "Appliquer"}, function()
    local values = window:GetValues()
    Lighting.GlobalShadows = values.shadows
    Lighting.Brightness = values.brightness
    window:SetTheme(values.theme)
end)

window:Command({
    Id = "status", Title = "Afficher le statut", Icon = "info",
    Callback = function()
        window:Notify({Title = "Interface prete", Content = "Version " .. UI.Version})
    end,
})

tab:Button("Commandes", {Text = "Ouvrir"}, function()
    window:OpenCommands()
end)

window:Presets({Title = "Profils"})
window:Appearance({Title = "Apparence"})
