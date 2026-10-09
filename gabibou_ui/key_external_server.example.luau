-- Script in ServerScriptService. HTTP and provider credentials stay on the server.
-- Replace the endpoint and request/response fields with your provider's documented contract.
-- Create the KeyProviderToken secret for your provider's domain in the Creator Dashboard.
-- Allow HTTP Requests in Experience Settings.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local remoteName = "GabibouValidateKey"
local endpoint = "https://replace-with-your-provider.example/v1/validate"
local secretName = "KeyProviderToken"
local includeRobloxUserId = false

assert(not ReplicatedStorage:FindFirstChild(remoteName), remoteName .. " already exists")

local attempts = {}
local remote = Instance.new("RemoteFunction")
remote.Name = remoteName

local function requestProvider(key, player)
	local body = {key = key}
	-- Only send this identifier if your provider needs Roblox account binding.
	if includeRobloxUserId then body.userId = player.UserId end

	local credential = HttpService:GetSecret(secretName)
	return HttpService:RequestAsync({
		Url = endpoint,
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json",
			Authorization = credential:AddPrefix("Bearer "),
		},
		Body = HttpService:JSONEncode(body),
	})
end

remote.OnServerInvoke = function(player, key)
	local now = os.clock()
	if attempts[player] and now - attempts[player] < 2 then
		return false, "Please wait before trying again."
	end
	attempts[player] = now
	if type(key) ~= "string" or #key == 0 or #key > 512 or not key:match("%S") then
		return false, "Key not accepted"
	end

	-- The expected provider response is JSON: {"valid": true} or {"valid": false}.
	-- Adapt the request and this field check to the provider; there is no universal key API.
	local requestOk, response = pcall(requestProvider, key, player)
	if not requestOk or type(response) ~= "table" or response.Success ~= true or type(response.Body) ~= "string" or #response.Body > 32768 then
		return false, "Validation service unavailable. Try again."
	end
	local decodeOk, result = pcall(HttpService.JSONDecode, HttpService, response.Body)
	if not decodeOk or type(result) ~= "table" or type(result.valid) ~= "boolean" then
		return false, "Validation service unavailable. Try again."
	end
	if result.valid ~= true then return false, "Key not accepted" end

	player:SetAttribute("GabibouAuthorized", true)
	return true
end

remote.Parent = ReplicatedStorage
Players.PlayerRemoving:Connect(function(player)
	attempts[player] = nil
end)

-- Check this server-owned attribute in every protected server action:
-- if player:GetAttribute("GabibouAuthorized") ~= true then return end
