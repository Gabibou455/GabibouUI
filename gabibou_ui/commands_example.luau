-- UI-only example: searchable commands with a visible touch entry point.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UI = require(ReplicatedStorage:WaitForChild("GabibouUI"))

local window = UI:CreateWindow({Title = "Command example"})

window:Command({
    Id = "preview-status",
    Title = "Preview status",
    Description = "Show a sample notification",
    Keywords = {"demo", "message"},
    Icon = "bell",
    Callback = function()
        window:Notify({Title = "Ready", Content = "This is a local UI preview."})
    end,
})

local actions = window:Tab({Title = "Actions", Icon = "search"})
actions:Button("Open commands", {
    Description = "Search available actions",
    Callback = function()
        window:OpenCommands()
    end,
})

-- Scoped cleanup is also available:
-- window:RemoveCommand("preview-status")
