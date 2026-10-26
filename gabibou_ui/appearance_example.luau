-- Standalone example for the current GabibouUI ModuleScript.
-- The appearance editor changes this window only and persists no values.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UI = require(ReplicatedStorage:WaitForChild("GabibouUI"))

local window = UI:CreateWindow({
    Title = "Appearance example",
    Width = 860,
    Height = 620,
})

-- One line adds a ready-to-use Appearance tab.
local appearanceTab = window:Appearance()

-- Optional: choose the tab label and an existing icon name or ID.
-- local appearanceTab = window:Appearance({Title = "Look and feel", Icon = "palette"})

-- Remove the editor tab and its controls when it is no longer needed.
-- appearanceTab:Destroy()
