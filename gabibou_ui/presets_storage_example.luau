-- Optional file-storage example for environments with these filesystem APIs.
-- Studio clients need their own Storage adapter; this file is not a DataStore client.
assert(type(isfile) == "function" and type(readfile) == "function" and type(writefile) == "function",
    "This example requires isfile, readfile and writefile; provide another Storage adapter otherwise.")
local UI = require(game:GetService("ReplicatedStorage"):WaitForChild("GabibouUI"))
local window = UI:CreateWindow({
    Id = "PresetStorageExample",
    Title = "Stored presets",
    Storage = {
        Read = function(filename)
            if not isfile(filename) then return nil end
            return readfile(filename)
        end,
        Write = function(filename, contents)
            writefile(filename, contents)
        end,
    },
})
local settings = window:Tab({Title = "Settings", Icon = "sliders"})
settings:Toggle({Id = "alerts", Title = "Enable alerts", Value = true})
settings:Slider({Id = "duration", Title = "Notification duration", Min = 1, Max = 10, Step = 1, Value = 4})
window:Presets({StorageKey = "gabibou-example-presets"})
-- Saved names are restored on the next launch; choosing one applies its values.
-- Keep persistent control IDs and StorageKey stable across launches.
