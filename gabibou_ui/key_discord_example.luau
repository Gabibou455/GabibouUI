-- LocalScript in StarterPlayerScripts.
-- Install key_server.example.luau in ServerScriptService and keep private keys there.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UI = require(ReplicatedStorage:WaitForChild("GabibouUI"))
local validateKey = ReplicatedStorage:WaitForChild("GabibouValidateKey")

local session = UI:Launch({
	Id = "DiscordExample",
	Title = "Garden Tools",
	Subtitle = "A small example application",
	Theme = "Graphite",
	Responsive = {Breakpoint = 620, TouchTarget = 44, Margin = 12},
	KeySystem = {
		Title = "Welcome",
		Subtitle = "Enter your access key to continue.",
		Logo = "Avatar", -- Default: the local player's avatar.
		MarkText = "GT", -- Displayed if Logo is false.
		SubmitText = "Verify key",
		Discord = {
			Url = "https://discord.gg/your-server", -- Replace with your invite.
			Text = "Copy our Discord invite",
			CopiedText = "Invite copied",
			Color = Color3.fromRGB(88, 101, 242),
			-- Optional: Logo = "rbxassetid://1234567890",
			-- Optional: Copy = function(url) ... end,
		},
		GetKey = {
			Url = "https://example.com/get-key", -- Replace with your provider URL.
			Text = "Get key",
			-- Optional clipboard implementation:
			-- Copy = function(url) setclipboard(url); return true end,
		},
		Validate = function(key)
			-- This RemoteFunction validates the key on the server.
			return validateKey:InvokeServer(key)
		end,
	},
	Loading = {
		Title = "Garden Tools",
		Subtitle = "Preparing your interface",
		Variant = "Centered",
		Logo = "Avatar",
		MinimumDuration = 0.5,
	},
	Steps = {
		{
			Title = "Loading preferences",
			Run = function(loader)
				-- Load or prepare application data here.
			end,
		},
	},
	Tabs = {
		{
			Title = "Home",
			Icon = "home",
			Sections = {
				{
					Title = "Preferences",
					Controls = {
						{
							Type = "Toggle",
							Id = "notifications",
							Title = "Notifications",
							Value = true,
							Callback = function(enabled)
								print("Notifications enabled:", enabled)
							end,
						},
						{
							Type = "Button",
							Id = "testNotification",
							Title = "Preview",
							Text = "Show notification",
							Callback = function()
								print("The window is ready.")
							end,
						},
					},
				},
			},
		},
	},
	OnReady = function(window, currentSession)
		local preview = window:Get("testNotification")
		if preview then
			preview.Callback = function()
				window:Notify({
					Title = "Ready",
					Content = "The key was accepted and setup completed.",
					Kind = "success",
				})
			end
		end
		print("Launch status:", currentSession.Status)
	end,
	OnError = function(message)
		warn("Startup failed:", message)
	end,
	OnCancel = function()
		print("Startup cancelled")
	end,
})

-- Later, for example when the owning application is removed:
-- session:Destroy()
