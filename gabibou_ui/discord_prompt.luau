-- Optional, explicit community invite prompt. No automatic network or join calls.
Library._discordPromptShown = Library._discordPromptShown or {}

local discordPromptDefaults = {
	Title = "Join the community",
	Content = "Join the Gabibou UI community for updates and help.",
	JoinText = "Copy invite",
	ContinueText = "Not now",
	OncePerSession = true,
}

local function normalize_discord_invite(value)
	assert(type(value) == "string" and #value <= 256 and not value:find("%s"),
		"DiscordPrompt.Url must be an invite code or HTTPS Discord invite URL")
	local code = value:match("^([%w_-]+)$")
	if not code then
		code = value:match("^https://discord%.gg/([%w_-]+)/?$")
			or value:match("^https://discord%.com/invite/([%w_-]+)/?$")
	end
	assert(code and #code >= 2 and #code <= 64,
		"DiscordPrompt.Url must be a code, https://discord.gg/code, or https://discord.com/invite/code")
	return "https://discord.gg/" .. code
end

function Library:_NormalizeDiscordPrompt(value, path)
	if value == nil then return nil end
	path = path or "DiscordPrompt"
	if type(value) == "string" then value = {Url = value} end
	assert(type(value) == "table", path .. " must be an invite string or options table")
	local allowed = {Url=true, Title=true, Content=true, JoinText=true, ContinueText=true,
		OncePerSession=true, Copy=true, Open=true}
	for key in pairs(value) do assert(allowed[key], path .. " has unknown option " .. tostring(key)) end
	assert(type(value.Url) == "string", path .. ".Url is required")
	local result = table.clone(discordPromptDefaults)
	result.Url = normalize_discord_invite(value.Url)
	for _, key in ipairs({"Title", "Content", "JoinText", "ContinueText"}) do
		if value[key] ~= nil then
			local maxLength = key == "Content" and 240 or 64
			assert(type(value[key]) == "string" and #value[key] <= maxLength, path .. "." .. key .. " must be a string of at most " .. maxLength .. " characters")
			result[key] = value[key]
		end
	end
	assert(result.Title ~= "" and result.Content ~= "" and result.JoinText ~= "" and result.ContinueText ~= "",
		path .. " text options cannot be empty")
	if value.OncePerSession ~= nil then
		assert(type(value.OncePerSession) == "boolean", path .. ".OncePerSession must be boolean")
		result.OncePerSession = value.OncePerSession
	end
	for _, key in ipairs({"Copy", "Open"}) do
		if value[key] ~= nil then assert(type(value[key]) == "function", path .. "." .. key .. " must be a function") end
		result[key] = value[key]
	end
	return result
end

local function clipboard_copy(text)
	local candidate
	pcall(function() candidate = setclipboard end)
	if type(candidate) ~= "function" then
		local getter
		pcall(function() getter = getgenv end)
		if type(getter) == "function" then
			local ok, env = pcall(getter)
			if ok and type(env) == "table" and type(env.setclipboard) == "function" then candidate = env.setclipboard end
		end
	end
	if type(candidate) ~= "function" then return false, "Clipboard unavailable. Select and copy the invite above." end
	local ok, result = pcall(candidate, text)
	if not ok then return false, "Clipboard copy failed. Select and copy the invite above." end
	if result == false then return false, "Clipboard copy failed. Select and copy the invite above." end
	return true
end

function Window:PromptDiscord(value)
	if self.Destroyed then return false, "Window is destroyed" end
	local ok, options = pcall(Library._NormalizeDiscordPrompt, Library, value, "PromptDiscord")
	if not ok then return false, tostring(options) end
	local url = options.Url
	if options.OncePerSession and Library._discordPromptShown[url] then
		return false, "This invite was already shown in this session"
	end
	local function explicit_action()
		local callback = options.Open or options.Copy
		local actionOk, result, message
		if callback then actionOk, result, message = pcall(callback, url)
		else actionOk, result, message = true, nil, nil end
		if callback then
			if not actionOk then return false, "Invite action failed. You can still copy the link above." end
			if result == false then return false, type(message) == "string" and message or "Invite action failed. You can still copy the link above." end
			return true
		end
		return clipboard_copy(url)
	end
	local opened = self:Confirm({
		Title = options.Title,
		Content = options.Content,
		ConfirmText = options.JoinText,
		CancelText = options.ContinueText,
		LinkText = url,
		FooterText = "Gabibou UI · by Gabibou",
		BeforeConfirm = explicit_action,
	})
	if not opened then return false, "A dialog is already open" end
	if options.OncePerSession then Library._discordPromptShown[url] = true end
	return true
end
