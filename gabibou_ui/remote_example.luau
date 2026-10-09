-- Client environment with game:HttpGet and loadstring support.
-- The main URL follows published updates. Use a release tag to pin a version.
local owner = "Gabibou455"
local repository = "GabibouUI"
local version = "main"
assert(owner:match("^[%w-]+$"), "Set owner to a valid GitHub username before loading Gabibou UI")
assert(type(loadstring) == "function", "This environment does not expose loadstring; use ModuleScript + require in Studio")

local url = "https://raw.githubusercontent.com/" .. owner .. "/" .. repository .. "/" .. version .. "/gabibou_ui.luau"
local fetched, source = pcall(function() return game:HttpGet(url) end)
assert(fetched and type(source) == "string" and #source > 0,
    "Gabibou UI download failed; verify the public repository, version tag and URL: " .. url)
local chunk, problem = loadstring(source, "GabibouUI@" .. version)
assert(chunk, "Gabibou UI compile failed: " .. tostring(problem))
local UI = chunk()
assert(type(UI) == "table" and type(UI.CreateWindow) == "function", "The downloaded file is not the Gabibou UI library")

local window = UI:CreateWindow("My project", {Id = "RemoteExample"})
local settings = window:Tab("Settings", "settings")
settings:Toggle("Effects", {Id = "effects", Value = true}, function(enabled)
    print("Effects", enabled)
end)
