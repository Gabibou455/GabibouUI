-- UI-only example. No storage adapter: presets last for this window session.
local UI = require(game:GetService("ReplicatedStorage"):WaitForChild("GabibouUI"))
local window = UI:CreateWindow({Title = "Preset example"})
local settings = window:Tab({Title = "Settings", Icon = "sliders"})
local alerts = settings:Toggle({Id = "alerts", Title = "Enable alerts", Value = true})
local duration = settings:Slider({Id = "duration", Title = "Notification duration", Min = 1, Max = 10, Step = 1, Value = 4})
settings:Button("Preview notification", function()
    if alerts:Get() then
        window:Notify({Title = "Preview", Content = "Your saved settings are in use.", Duration = duration:Get()})
    end
end)
window:Presets()
local saved, reason = window:SavePreset("default")
if not saved then warn(reason) end
-- window:LoadPreset("default") restores values without firing callbacks.
-- window:DeletePreset("default") removes the named snapshot.
