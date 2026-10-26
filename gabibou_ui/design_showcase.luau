-- Standalone UI-only design showcase.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UI = require(ReplicatedStorage:WaitForChild("GabibouUI"))

local window = UI:CreateWindow({
    Id = "DesignShowcase",
    Title = "Design showcase",
    Subtitle = "Presets, responsive layout, and icons",
    Width = 860,
    Height = 620,
    Design = UI:Design({
        Preset = "Atelier",
        Transparency = 0.08,
        Tabs = "Top",
    }),
    Navigation = {Variant = "Rail", IconVariant = "Soft"},
    Responsive = {Breakpoint = 620, TouchTarget = 44, Margin = 12},
    Layout = {MobileTabPosition = "Bottom", PanelTransparency = 0.08},
    ReducedMotion = true,
})

window:SetPosition(UDim2.new(0.5, 0, 0.5, 0), Vector2.new(0.5, 0.5))

local appearanceTab = window:Appearance({Title = "Display", Icon = "palette"})

local motion = window:Tab({Title = "Motion", Icon = "play"})
motion:Section({Title = "Animation"})
motion:Button("Use gentle motion", {
    Description = "Turn off reduced motion to preview transitions.",
    Callback = function()
        window:SetReducedMotion(false)
        window:SetMotion({Duration = 0.18, Style = Enum.EasingStyle.Quad})
    end,
})
motion:Button("Use reduced motion", {
    Callback = function()
        window:SetReducedMotion(true)
    end,
})



