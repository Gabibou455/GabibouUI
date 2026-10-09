-- Optional, client-side validation dialog. Injected in ui.luau's shared scope
-- after loading.luau; the caller supplies the validation policy.

Library.KeySystems = Library.KeySystems or {}
local KeyGate = {}
KeyGate.__index = KeyGate
local keyGateSerial = 0

local function key_text(value, fallback, limit, label)
    assert(value == nil or type(value) == "string", label .. " must be a string")
    local valid = Logic.text(value or fallback, limit)
    assert(valid == value or value == nil, label .. " is too long")
    return valid
end

local function discord_options(value)
    if value == nil or value == false then return value end
    if type(value) == "string" then value = {Url = value}
    else
        assert(type(value) == "table", "Discord must be a URL, options table, or false")
        value = table.clone(value)
    end
    local allowed = {Url = true, Text = true, CopiedText = true, Color = true, Logo = true, Copy = true}
    for key in pairs(value) do assert(allowed[key], "Unknown Discord option: " .. tostring(key)) end
    assert(type(value.Url) == "string" and #value.Url <= 256 and not value.Url:find("%s"), "Discord.Url must be an HTTPS invite URL")
    local normalizedUrl = value.Url:lower()
    local validInvite = normalizedUrl:match("^https://discord%.gg/[%w%-]+/?$") ~= nil
        or normalizedUrl:match("^https://discord%.com/invite/[%w%-]+/?$") ~= nil
    assert(validInvite, "Discord.Url must use discord.gg or discord.com/invite over HTTPS")
    value.Text = key_text(value.Text, "Copy Discord link", 48, "Discord.Text")
    value.CopiedText = key_text(value.CopiedText, "Link copied", 48, "Discord.CopiedText")
    assert(value.Text ~= "" and value.CopiedText ~= "", "Discord button text must not be empty")
    value.Color = value.Color or Color3.fromRGB(88, 101, 242)
    assert(typeof(value.Color) == "Color3", "Discord.Color must be a Color3")
    if value.Logo ~= nil then
        assert(type(value.Logo) == "string" and #value.Logo <= 64 and value.Logo:match("^rbxassetid://%d+$") ~= nil,
            "Discord.Logo must be an rbxassetid URI")
        assert(tonumber(value.Logo:match("rbxassetid://(%d+)")) > 0, "Discord.Logo asset ID must be positive")
    end
    assert(value.Copy == nil or type(value.Copy) == "function", "Discord.Copy must be a function")
    return value
end

local function get_key_options(value)
    if value == nil or value == false then return value end
    if type(value) == "function" then return value end
    if type(value) == "string" then value = {Url = value}
    else
        assert(type(value) == "table", "GetKey must be a URL, options table, callback, or false")
        value = table.clone(value)
    end
    for key in pairs(value) do
        assert(key == "Url" or key == "Text" or key == "Copy", "Unknown GetKey option: " .. tostring(key))
    end
    assert(type(value.Url) == "string" and #value.Url > 0 and #value.Url <= 2048,
        "GetKey.Url must be a nonempty HTTPS URL up to 2048 characters")
    assert(not value.Url:find("[%c%s]"), "GetKey.Url must not contain whitespace or control characters")
    local authority = value.Url:match("^https://([^/%?#]+)")
    assert(authority and authority ~= "", "GetKey.Url must use HTTPS and include a host")
    value.Text = key_text(value.Text, "Get key", 48, "GetKey.Text")
    assert(value.Text ~= "", "GetKey.Text must not be empty")
    assert(value.Copy == nil or type(value.Copy) == "function", "GetKey.Copy must be a function")
    return value
end

local function same_get_key(left, right)
    if left == right then return true end
    if type(left) ~= "table" or type(right) ~= "table" then return false end
    return left.Url == right.Url and left.Text == right.Text and left.Copy == right.Copy
end

local function key_options(options)
    assert(options == nil or type(options) == "table", "Key system options must be a table")
    options = table.clone(options or {})
    assert(type(options.Validate) == "function", "Validate callback is required")
    assert(options.OnSuccess == nil or type(options.OnSuccess) == "function", "OnSuccess must be a function")
    assert(options.OnCancel == nil or type(options.OnCancel) == "function", "OnCancel must be a function")
    options.Title = key_text(options.Title, "Access key", 80, "Title")
    options.Subtitle = key_text(options.Subtitle, "Enter your key to continue.", 240, "Subtitle")
    options.Placeholder = key_text(options.Placeholder, "Enter key…", 120, "Placeholder")
    options.SubmitText = key_text(options.SubmitText, "Verify key", 32, "SubmitText")
    options.CancelText = key_text(options.CancelText, "Cancel", 32, "CancelText")
    options.SuccessText = key_text(options.SuccessText, "Verified", 120, "SuccessText")
    options.InvalidText = key_text(options.InvalidText, "Key not accepted", 120, "InvalidText")
    options.InputLabel = key_text(options.InputLabel, "Access key", 48, "InputLabel")
    options.ValidatingText = key_text(options.ValidatingText, "Verifying…", 48, "ValidatingText")
    options.CancelledText = key_text(options.CancelledText, "Cancelled", 48, "CancelledText")
    options.MarkText = key_text(options.MarkText, "G", 8, "MarkText")
    assert(options.MarkText ~= "", "MarkText must not be empty")
    if options.Logo == nil then options.Logo = "Avatar" end
    assert(options.Logo == false or options.Logo == "Avatar" or
        (type(options.Logo) == "string" and #options.Logo <= 64 and
        options.Logo:match("^rbxassetid://%d+$") ~= nil and
        tonumber(options.Logo:match("%d+$")) > 0), "Logo must be Avatar, false, or an rbxassetid URI")
    options.Discord = discord_options(options.Discord)
    options.GetKey = get_key_options(options.GetKey)
    options.Width = options.Width == nil and 420 or options.Width
    if options.Height == nil then
        local hasDiscord = type(options.Discord) == "table"
        local hasGetKey = options.GetKey ~= nil and options.GetKey ~= false
        options.Height = 332 + (hasDiscord and 62 or 0) + (hasGetKey and 72 or 0) - (hasDiscord and hasGetKey and 4 or 0)
    end
    assert(Logic.finite(options.Width) and options.Width >= 280 and options.Width <= 600, "Width must be 280..600")
    assert(Logic.finite(options.Height) and options.Height >= 280 and options.Height <= 560, "Height must be 280..560")
    options.Position = options.Position or UDim2.fromScale(.5, .5)
    options.AnchorPoint = options.AnchorPoint or Vector2.new(.5, .5)
    assert(typeof(options.Position) == "UDim2", "Position must be a UDim2")
    assert(typeof(options.AnchorPoint) == "Vector2", "AnchorPoint must be a Vector2")
    for _, component in ipairs({options.Position.X.Scale, options.Position.X.Offset, options.Position.Y.Scale, options.Position.Y.Offset}) do
        assert(Logic.finite(component), "Position components must be finite")
    end
    assert(Logic.finite(options.AnchorPoint.X) and Logic.finite(options.AnchorPoint.Y)
        and options.AnchorPoint.X >= 0 and options.AnchorPoint.X <= 1
        and options.AnchorPoint.Y >= 0 and options.AnchorPoint.Y <= 1,
        "AnchorPoint components must be 0..1")
    options.MaxLength = options.MaxLength == nil and 256 or options.MaxLength
    assert(Logic.finite(options.MaxLength) and options.MaxLength % 1 == 0 and options.MaxLength >= 1 and options.MaxLength <= 4096, "MaxLength must be an integer in 1..4096")
    options.DisplayOrder = options.DisplayOrder == nil and 120 or options.DisplayOrder
    assert(Logic.finite(options.DisplayOrder) and options.DisplayOrder % 1 == 0, "DisplayOrder must be an integer")
    local player = Players.LocalPlayer
    assert(player, "Key system runs on a Roblox client")
    options.Parent = options.Parent or player:FindFirstChildOfClass("PlayerGui")
    assert(typeof(options.Parent) == "Instance", "Pass a GUI parent or wait for PlayerGui")
    options.Theme = theme_for(options.Theme or "Graphite")
    options.Style = style_for(options.Style, Library.Style)
    return options
end

local function safe_message(value, fallback, submittedKey)
    if type(value) ~= "string" or value == "" then return fallback end
    if submittedKey ~= "" and value:find(submittedKey, 1, true) then return fallback end
    local ok, result = pcall(function() return Logic.text(value:gsub("[%c]", " "), 120) end)
    if not ok or result == "" then return fallback end
    return result
end

function KeyGate:_Status(text, kind)
    if self.Destroyed then return end
    self.Status = text
    self._statusKind = kind or "normal"
    self.StatusLabel.Text = text
    self.StatusLabel.TextColor3 = self.Options.Theme[kind == "success" and "Success" or kind == "error" and "Danger" or "Muted"]
end

function KeyGate:GetParts()
    if self.Destroyed then return nil end
    return {
        Card = self.Card,
        ContentScroll = self.Scroll,
        Input = self.Input,
        Title = self.Title,
        Subtitle = self.Subtitle,
        Status = self.StatusLabel,
        Submit = self.SubmitButton,
        Cancel = self.CancelButton,
        Mark = self.Mark,
        MarkImage = self.MarkImage,
        MarkText = self.MarkLabel,
        KeyIcon = self.KeyIcon,
        KeyLabel = self.KeyLabel,
        DiscordButton = self.DiscordButton,
        DiscordIcon = self.DiscordIcon,
        DiscordLink = self.DiscordLink,
        DiscordStatus = self.DiscordStatus,
        GetKeyButton = self.GetKeyButton,
        KeyLink = self.KeyLink,
        KeyLinkStatus = self.KeyLinkStatus,
    }
end

function KeyGate:_StartLogo()
    self._logoGeneration = (self._logoGeneration or 0) + 1
    local generation = self._logoGeneration
    local previous = self._avatarThread
    self._avatarThread = nil
    if previous and previous ~= coroutine.running() and coroutine.status(previous) ~= "dead" then pcall(task.cancel, previous) end
    local logo = self.Options.Logo
    self.MarkImage.Image = ""
    self.MarkImage.Visible = false
    self.MarkLabel.Visible = logo == false
    self.MarkLabel.TextColor3 = self.Options.Theme[logo == false and "AccentText" or "Text"]
    self.Mark.BackgroundColor3 = self.Options.Theme[logo == false and "Accent" or "Raised"]
    if logo == false then return end
    if logo ~= "Avatar" then self.MarkImage.Image = logo; self.MarkImage.Visible = true; return end
    self._avatarThread = task.defer(function()
        local ok, content = pcall(function()
            return Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        if self.Destroyed or generation ~= self._logoGeneration then return end
        self._avatarThread = nil
        if ok then self.MarkImage.Image = content; self.MarkImage.Visible = true
        else self.MarkLabel.Visible = true end
    end)
end

local function find_clipboard_function()
    local candidate
    local ok = pcall(function() candidate = setclipboard end)
    if ok and type(candidate) == "function" then return candidate end
    local envGetter
    pcall(function() envGetter = getgenv end)
    if type(envGetter) == "function" then
        local envOk, env = pcall(envGetter)
        if envOk and type(env) == "table" and type(env.setclipboard) == "function" then return env.setclipboard end
    end
    return nil
end

function KeyGate:CopyDiscordLink()
    if self.Destroyed then return false, "Gate is destroyed" end
    if self._copyBusy then return false, "Copy is in progress" end
    local config = self.Options.Discord
    if type(config) ~= "table" then return false, "Discord link is disabled" end
    self._copyGeneration += 1
    local generation = self._copyGeneration
    self._copyBusy = true
    local ok, result
    local unavailable = false
    if config.Copy then
        ok, result = pcall(config.Copy, config.Url)
    else
        local copier = find_clipboard_function()
        if not copier then unavailable = true; ok, result = false, "Clipboard unavailable"
        else ok, result = pcall(copier, config.Url) end
    end
    if self.Destroyed or generation ~= self._copyGeneration or self.Options.Discord ~= config then
        return false, "Copy was cancelled by an update or destroy"
    end
    self._copyBusy = false
    if ok and result ~= false then
        self._manualLinkVisible = false
        self.DiscordLink.Visible = false
        self.DiscordStatus.Text = config.CopiedText
        self.DiscordStatus.TextColor3 = self.Options.Theme.Success
        self.DiscordStatus.Visible = true
        self._discordCopyKind = "success"
        self:_Layout()
        return true
    end

    self._manualLinkVisible = true
    self.DiscordLink.Text = config.Url
    self.DiscordLink.Visible = true
    self.DiscordStatus.Text = "Select and copy the link below."
    self.DiscordStatus.TextColor3 = self.Options.Theme.Muted
    self.DiscordStatus.Visible = true
    self._discordCopyKind = "manual"
    self:_Layout()
    self:_RevealDiscordLink()
    local reason = unavailable and "Clipboard unavailable" or (ok and "Copy callback declined" or "Copy failed")
    return false, reason
end

function KeyGate:GetKey()
    if self.Destroyed then return false, "Gate is destroyed" end
    if self._getKeyBusy then return false, "Get key action is in progress" end
    local config = self.Options.GetKey
    if config == nil or config == false then return false, "Get key action is disabled" end

    self._getKeyGeneration += 1
    local generation = self._getKeyGeneration
    self._getKeyBusy = true
    self.GetKeyButton.Active = false
    self.KeyLinkStatus.Text = type(config) == "function" and "Running key action..." or "Copying key link..."
    self.KeyLinkStatus.TextColor3 = self.Options.Theme.Muted
    self.KeyLinkStatus.Visible = true
    self:_Layout()
    local ok, result
    local unavailable = false
    if type(config) == "function" then
        ok, result = pcall(config, self)
    else
        local copier = config.Copy or find_clipboard_function()
        if not copier then unavailable = true; ok, result = false, "Clipboard unavailable"
        elseif config.Copy then ok, result = pcall(copier, config.Url)
        else ok, result = pcall(copier, config.Url) end
    end

    if self.Destroyed or generation ~= self._getKeyGeneration or not same_get_key(self.Options.GetKey, config) then
        return false, "Get key action was cancelled by an update or destroy"
    end
    self._getKeyBusy = false
    self.GetKeyButton.Active = true
    if ok and result ~= false then
        self._manualKeyLinkVisible = false
        self.KeyLink.Visible = false
        self.KeyLinkStatus.Text = type(config) == "function" and "Key action completed." or "Link copied. Open it in your browser."
        self.KeyLinkStatus.TextColor3 = self.Options.Theme.Success
        self.KeyLinkStatus.Visible = true
        self._getKeyStatusKind = "success"
        self:_Layout()
        return true
    end

    if type(config) ~= "function" then
        self._manualKeyLinkVisible = true
        self.KeyLink.Text = config.Url
        self.KeyLink.Visible = true
        self.KeyLinkStatus.Text = "Select and copy the link below."
        self._getKeyStatusKind = "manual"
        self:_Layout()
        self:_RevealKeyLink()
    else
        self._manualKeyLinkVisible = false
        self.KeyLink.Visible = false
        self.KeyLinkStatus.Text = "Key action failed."
        self._getKeyStatusKind = "error"
        self:_Layout()
    end
    self.KeyLinkStatus.TextColor3 = self._getKeyStatusKind == "error" and self.Options.Theme.Danger or self.Options.Theme.Muted
    self.KeyLinkStatus.Visible = true
    local reason = unavailable and "Clipboard unavailable" or (ok and "Get key callback declined" or "Get key action failed")
    return false, reason
end

local function set_corner(instance, radius)
    local rounding = instance and instance:FindFirstChildOfClass("UICorner")
    if rounding then rounding.CornerRadius = UDim.new(0, radius) end
end

function KeyGate:Update(changes)
    if self.Destroyed then return false, "Gate is destroyed" end
    if self.Busy then return false, "Validation is in progress" end
    if self.Completed then return false, "Gate has completed" end
    if type(changes) ~= "table" then return false, "Update options must be a table" end

    local merged = table.clone(self.Options)
    for key, value in pairs(changes) do
        if (key == "Theme" or key == "Style") and type(value) == "table" then
            local nested = table.clone(self.Options[key])
            for nestedKey, nestedValue in pairs(value) do nested[nestedKey] = nestedValue end
            merged[key] = nested
        elseif key == "Discord" and type(value) == "table" and type(self.Options.Discord) == "table" then
            local nested = table.clone(self.Options.Discord)
            for nestedKey, nestedValue in pairs(value) do nested[nestedKey] = nestedValue end
            merged[key] = nested
        elseif key == "GetKey" and type(value) == "table" and type(self.Options.GetKey) == "table" then
            local nested = table.clone(self.Options.GetKey)
            for nestedKey, nestedValue in pairs(value) do nested[nestedKey] = nestedValue end
            merged[key] = nested
        else
            merged[key] = value
        end
    end
    local ok, valid = pcall(key_options, merged)
    if not ok then return false, tostring(valid) end
    if self._automaticHeight and changes.Height == nil then
        local hasDiscord = type(valid.Discord) == "table"
        local hasGetKey = valid.GetKey ~= nil and valid.GetKey ~= false
        valid.Height = 332 + (hasDiscord and 62 or 0) + (hasGetKey and 72 or 0) - (hasDiscord and hasGetKey and 4 or 0)
    end

    -- Validation is complete. Apply the staged configuration to the existing GUI.
    local previousDiscord = self.Options.Discord
    local previousGetKey = self.Options.GetKey
    local pendingGetKey = self._getKeyBusy
    local logoChanged = self.Options.Logo ~= valid.Logo
    self._copyGeneration += 1
    self._copyBusy = false
    self._getKeyGeneration += 1
    self._getKeyBusy = false
    self.GetKeyButton.Active = self.Options.GetKey ~= nil and self.Options.GetKey ~= false
    self._automaticHeight = self._automaticHeight and changes.Height == nil
    if pendingGetKey then
        self.KeyLinkStatus.Text = "Get key action cancelled by update."
        self._getKeyStatusKind = "manual"
    end
    if valid.Parent ~= self.Gui.Parent then
        release_focus(valid.Parent)
        self.Gui.Parent = valid.Parent
    end
    self.Options = valid
    self.Gui.DisplayOrder = valid.DisplayOrder
    self.Title.Text = valid.Title
    self.Subtitle.Text = valid.Subtitle
    self.Input.PlaceholderText = valid.Placeholder
    self.SubmitButton.Text = valid.SubmitText
    self.CancelButton.Text = valid.CancelText
    self.MarkLabel.Text = valid.MarkText
    self.KeyLabel.Text = valid.InputLabel
    local discord = valid.Discord
    if type(previousDiscord) == "table" and type(discord) == "table" and previousDiscord.Url ~= discord.Url then
        self.DiscordStatus.Text = ""
        self._discordCopyKind = nil
        self._manualLinkVisible = false
    elseif type(discord) ~= "table" then
        self.DiscordStatus.Text = ""
        self._discordCopyKind = nil
        self._manualLinkVisible = false
    end
    self.DiscordButton.Visible = type(discord) == "table"
    self.DiscordLabel.Text = type(discord) == "table" and discord.Text or ""
    self.DiscordButton.BackgroundColor3 = type(discord) == "table" and discord.Color or Color3.fromRGB(88, 101, 242)
    self.DiscordLink.Text = type(discord) == "table" and discord.Url or ""
    self.DiscordLink.Visible = type(discord) == "table" and self._manualLinkVisible == true
    self.DiscordImage.Visible = type(discord) == "table" and discord.Logo ~= nil
    self.DiscordImage.Image = type(discord) == "table" and discord.Logo or ""
    self.DiscordVector.Visible = type(discord) == "table" and discord.Logo == nil
    self.DiscordStatus.Visible = type(discord) == "table" and self.DiscordStatus.Text ~= ""

    local getKey = valid.GetKey
    if not same_get_key(previousGetKey, getKey) then
        self.KeyLinkStatus.Text = ""
        self.KeyLinkStatus.Visible = false
        self.KeyLink.Visible = false
        self._manualKeyLinkVisible = false
        self._getKeyStatusKind = nil
    end
    self.GetKeyButton.Visible = getKey ~= nil and getKey ~= false
    self.GetKeyButton.Active = self.GetKeyButton.Visible
    self.GetKeyLabel.Text = type(getKey) == "table" and getKey.Text or "Get key"
    self.KeyLink.Text = type(getKey) == "table" and getKey.Url or ""
    self.KeyLink.Visible = self.GetKeyButton.Visible and self._manualKeyLinkVisible == true
    self.KeyLinkStatus.Visible = self.GetKeyButton.Visible and self.KeyLinkStatus.Text ~= ""

    local theme, style = valid.Theme, valid.Style
    self.Card.BackgroundColor3 = theme.Background
    self.Card:FindFirstChildOfClass("UIStroke").Color = theme.Border
    self.Edge.BackgroundColor3 = theme.Accent
    self.Mark.BackgroundColor3 = theme[valid.Logo == false and "Accent" or "Raised"]
    self.MarkLabel.TextColor3 = theme[valid.Logo == false and "AccentText" or "Text"]
    self.Title.TextColor3 = theme.Text
    self.Subtitle.TextColor3 = theme.Muted
    self.KeyLabel.TextColor3 = theme.Muted
    self.Input.BackgroundColor3 = theme.Raised
    self.Input.TextColor3 = theme.Text
    self.Input.PlaceholderColor3 = theme.Muted
    self.Input:FindFirstChildOfClass("UIStroke").Color = theme.Border
    self.StatusLabel.TextColor3 = theme[self._statusKind == "success" and "Success" or self._statusKind == "error" and "Danger" or "Muted"]
    self.CancelButton.BackgroundColor3 = theme.Surface
    self.CancelButton.TextColor3 = theme.Text
    self.CancelButton:FindFirstChildOfClass("UIStroke").Color = theme.Border
    self.SubmitButton.BackgroundColor3 = theme.Accent
    self.SubmitButton.TextColor3 = theme.AccentText
    self.DiscordLabel.TextColor3 = Color3.new(1, 1, 1)
    self.DiscordStatus.TextColor3 = self._discordCopyKind == "success" and theme.Success or theme.Muted
    self.DiscordLink.BackgroundColor3 = theme.Raised
    self.DiscordLink.TextColor3 = theme.Text
    self.DiscordLink:FindFirstChildOfClass("UIStroke").Color = theme.Border
    self.GetKeyButton.BackgroundColor3 = theme.Surface
    self.GetKeyButton.TextColor3 = theme.Text
    self.GetKeyButton:FindFirstChildOfClass("UIStroke").Color = theme.Border
    self.GetKeyLabel.TextColor3 = theme.Text
    self.KeyLinkStatus.TextColor3 = self._getKeyStatusKind == "success" and theme.Success or self._getKeyStatusKind == "error" and theme.Danger or theme.Muted
    self.KeyLink.BackgroundColor3 = theme.Raised
    self.KeyLink.TextColor3 = theme.Text
    self.KeyLink:FindFirstChildOfClass("UIStroke").Color = theme.Border
    for _, descendant in ipairs(self.GetKeyIcon:GetDescendants()) do
        if descendant:IsA("UIStroke") then descendant.Color = theme.Muted
        elseif descendant:IsA("GuiObject") and descendant.BackgroundTransparency < 1 then descendant.BackgroundColor3 = theme.Muted end
    end
    for _, descendant in ipairs(self.KeyIcon:GetDescendants()) do
        if descendant:IsA("UIStroke") then descendant.Color = theme.Muted
        elseif descendant:IsA("GuiObject") then descendant.BackgroundColor3 = theme.Muted end
    end
    for _, descendant in ipairs(self.DiscordVector:GetDescendants()) do
        if descendant.Name == "DiscordEye" then descendant.BackgroundColor3 = self.DiscordButton.BackgroundColor3 end
    end

    self.MarkLabel.Font = style.FontBold
    self.MarkLabel.TextSize = style.TitleSize
    self.Title.Font = style.FontBold
    self.Title.TextSize = style.TitleSize
    self.Subtitle.Font = style.Font
    self.Subtitle.TextSize = style.DescriptionSize
    self.KeyLabel.Font = style.FontBold
    self.KeyLabel.TextSize = style.DescriptionSize
    self.Input.Font = style.Font
    self.Input.TextSize = style.TextSize
    self.StatusLabel.Font = style.Font
    self.StatusLabel.TextSize = style.DescriptionSize
    self.CancelButton.Font = style.FontBold
    self.CancelButton.TextSize = style.TextSize
    self.SubmitButton.Font = style.FontBold
    self.SubmitButton.TextSize = style.TextSize
    self.DiscordLabel.Font = style.FontBold
    self.DiscordLabel.TextSize = style.TextSize
    self.DiscordStatus.Font = style.Font
    self.DiscordStatus.TextSize = style.DescriptionSize
    self.DiscordLink.Font = style.Font
    self.DiscordLink.TextSize = style.TextSize
    self.GetKeyLabel.Font = style.FontBold
    self.GetKeyLabel.TextSize = style.TextSize
    self.KeyLinkStatus.Font = style.Font
    self.KeyLinkStatus.TextSize = style.DescriptionSize
    self.KeyLink.Font = style.Font
    self.KeyLink.TextSize = style.TextSize
    set_corner(self.Card, style.WindowRadius)
    for _, instance in ipairs({self.Mark, self.MarkImage, self.Input, self.CancelButton, self.SubmitButton, self.DiscordButton, self.DiscordLink, self.GetKeyButton, self.KeyLink}) do
        set_corner(instance, style.ControlRadius)
    end
    self:_Layout()
    if logoChanged then self:_StartLogo() end
    return true
end

function KeyGate:_Viewport()
    local size = self.Backdrop.AbsoluteSize
    if UIS.OnScreenKeyboardVisible and UIS.OnScreenKeyboardPosition.Y > 0 then
        local origin = self.Backdrop.AbsolutePosition.Y
        size = Vector2.new(size.X, math.max(1, math.min(size.Y, UIS.OnScreenKeyboardPosition.Y - origin)))
    end
    return size
end

function KeyGate:_RevealInput()
    if self.Destroyed or not self.Scroll or not self.Input then return end
    local inputTop = self.Input.AbsolutePosition.Y - self.Scroll.AbsolutePosition.Y + self.Scroll.CanvasPosition.Y
    local inputBottom = inputTop + self.Input.AbsoluteSize.Y
    local current = self.Scroll.CanvasPosition.Y
    if inputTop < current then current = inputTop - 8
    elseif inputBottom > current + self.Scroll.AbsoluteSize.Y then current = inputBottom - self.Scroll.AbsoluteSize.Y + 8 end
    local maximum = math.max(0, self.Content.Size.Y.Offset - self.Scroll.AbsoluteSize.Y)
    self.Scroll.CanvasPosition = Vector2.new(0, math.clamp(current, 0, maximum))
end

function KeyGate:_RevealDiscordLink()
    task.defer(function()
        task.defer(function()
            if self.Destroyed or not self._manualLinkVisible or not self.DiscordLink.Visible or not self.Scroll then return end
            local top = self.DiscordLink.AbsolutePosition.Y - self.Scroll.AbsolutePosition.Y + self.Scroll.CanvasPosition.Y
            local bottom = top + self.DiscordLink.AbsoluteSize.Y
            local current = self.Scroll.CanvasPosition.Y
            if top < current then current = top - 8
            elseif bottom > current + self.Scroll.AbsoluteSize.Y then current = bottom - self.Scroll.AbsoluteSize.Y + 8 end
            local maximum = math.max(0, self.Content.Size.Y.Offset - self.Scroll.AbsoluteSize.Y)
            self.Scroll.CanvasPosition = Vector2.new(0, math.clamp(current, 0, maximum))
        end)
    end)
end

function KeyGate:_RevealKeyLink()
    task.defer(function()
        task.defer(function()
            if self.Destroyed or not self._manualKeyLinkVisible or not self.KeyLink.Visible or not self.Scroll then return end
            local top = self.KeyLink.AbsolutePosition.Y - self.Scroll.AbsolutePosition.Y + self.Scroll.CanvasPosition.Y
            local bottom = top + self.KeyLink.AbsoluteSize.Y
            local current = self.Scroll.CanvasPosition.Y
            if top < current then current = top - 8
            elseif bottom > current + self.Scroll.AbsoluteSize.Y then current = bottom - self.Scroll.AbsoluteSize.Y + 8 end
            local maximum = math.max(0, self.Content.Size.Y.Offset - self.Scroll.AbsoluteSize.Y)
            self.Scroll.CanvasPosition = Vector2.new(0, math.clamp(current, 0, maximum))
        end)
    end)
end

function KeyGate:_Layout()
    if self.Destroyed or not self.Backdrop then return end
    local viewport = self:_Viewport()
    local width = math.max(1, math.min(self.Options.Width, viewport.X - 24))
    local height = math.max(1, math.min(self.Options.Height, viewport.Y - 24))
    local options = self.Options
    local x = viewport.X * options.Position.X.Scale + options.Position.X.Offset - width * options.AnchorPoint.X
    local y = viewport.Y * options.Position.Y.Scale + options.Position.Y.Offset - height * options.AnchorPoint.Y
    local marginX = math.min(12, math.max(0, (viewport.X - width) / 2))
    local marginY = math.min(12, math.max(0, (viewport.Y - height) / 2))
    x = math.clamp(x, marginX, math.max(marginX, viewport.X - width - marginX))
    y = math.clamp(y, marginY, math.max(marginY, viewport.Y - height - marginY))
    self.Card.Size = UDim2.fromOffset(width, height)
    self.Card.Position = UDim2.fromOffset(x, y)
    self.Card.AnchorPoint = Vector2.zero
    self.Scroll.Size = UDim2.fromScale(1, 1)

    local hasDiscord = self.DiscordButton and self.DiscordButton.Visible
    local hasGetKey = self.GetKeyButton and self.GetKeyButton.Visible
    local manualKeyLink = hasGetKey and self._manualKeyLinkVisible == true
    local baseline = hasGetKey and (hasDiscord and 462 or 404) or (hasDiscord and 394 or 332)
    local contentHeight = math.max(height, baseline)
    local layoutOffset = math.max(0, (contentHeight - baseline) / 2)
    local compactOffset = height < 280 and -8 or 0
    self.Mark.Position = UDim2.fromOffset(28, 28 + layoutOffset + compactOffset)
    self.Mark.Size = UDim2.fromOffset(44, 44)
    self.Title.Position = UDim2.fromOffset(88, 32 + layoutOffset + compactOffset)
    self.Title.Size = UDim2.new(1, -116, 0, 25)
    self.Subtitle.Position = UDim2.fromOffset(28, 84 + layoutOffset + compactOffset)
    self.Subtitle.Size = UDim2.new(1, -56, 0, 32)

    local actionsY = 220 + layoutOffset
    local innerWidth = math.max(1, width - 64)
    local cancelWidth = math.min(84, innerWidth * .38)
    local actionGap = 8
    local statusY = actionsY + (hasGetKey and 136 or 64) + (manualKeyLink and 52 or 0)
    local discordY = actionsY + (hasGetKey and 168 or 100) + (manualKeyLink and 52 or 0)
    self.SubmitButton.Position = UDim2.fromOffset(28, actionsY)
    if hasGetKey then
        self.SubmitButton.Size = UDim2.fromOffset(innerWidth, 48)
        self.GetKeyButton.Position = UDim2.fromOffset(28, actionsY + 60)
        self.GetKeyButton.Size = UDim2.fromOffset(math.max(1, innerWidth - cancelWidth - actionGap), 46)
        self.GetKeyIcon.Position = UDim2.fromOffset(14, 14)
        self.GetKeyLabel.Position = UDim2.fromOffset(40, 0)
        self.GetKeyLabel.Size = UDim2.new(1, -48, 1, 0)
        self.CancelButton.Position = UDim2.fromOffset(28 + self.GetKeyButton.Size.X.Offset + actionGap, actionsY + 60)
        self.CancelButton.Size = UDim2.fromOffset(cancelWidth, 46)
        self.KeyLinkStatus.Position = UDim2.fromOffset(28, actionsY + 114)
        self.KeyLinkStatus.Size = UDim2.new(1, -56, 0, 18)
        self.KeyLink.Position = UDim2.fromOffset(28, actionsY + 136)
        self.KeyLink.Size = UDim2.new(1, -56, 0, 40)
    else
        self.SubmitButton.Size = UDim2.fromOffset(math.max(1, innerWidth - cancelWidth - actionGap), 48)
        self.CancelButton.Position = UDim2.fromOffset(28 + self.SubmitButton.Size.X.Offset + actionGap, actionsY)
        self.CancelButton.Size = UDim2.fromOffset(cancelWidth, 48)
        self.GetKeyButton.Position = UDim2.fromOffset(28, actionsY)
        self.GetKeyButton.Size = UDim2.fromOffset(1, 44)
        self.KeyLinkStatus.Position = UDim2.fromOffset(28, actionsY + 64)
        self.KeyLinkStatus.Size = UDim2.new(1, -56, 0, 18)
        self.KeyLink.Position = UDim2.fromOffset(28, actionsY + 86)
        self.KeyLink.Size = UDim2.new(1, -56, 0, 40)
    end

    local inputY = 156 + layoutOffset
    self.KeyLabel.Position = UDim2.fromOffset(48, 132 + layoutOffset)
    self.KeyLabel.Size = UDim2.new(1, -76, 0, 18)
    self.KeyIcon.Position = UDim2.fromOffset(28, 135 + layoutOffset)
    self.Input.Position = UDim2.fromOffset(28, inputY)
    self.Input.Size = UDim2.new(1, -56, 0, 48)
    self.StatusLabel.Position = UDim2.fromOffset(28, statusY)
    self.StatusLabel.Size = UDim2.new(1, -56, 0, 20)
    self.DiscordButton.Position = UDim2.fromOffset(28, discordY)
    self.DiscordButton.Size = UDim2.new(1, -56, 0, 46)
    self.DiscordIcon.Position = UDim2.fromOffset(14, 12)
    self.DiscordLabel.Size = UDim2.new(1, -54, 1, 0)
    self.DiscordLabel.Position = UDim2.fromOffset(44, 0)
    self.DiscordLink.Position = UDim2.fromOffset(28, discordY + 68)
    self.DiscordLink.Size = UDim2.new(1, -56, 0, 40)
    if self.DiscordStatus.Visible then
        self.DiscordStatus.Position = UDim2.fromOffset(28, discordY + 50)
        self.DiscordStatus.Size = UDim2.new(1, -56, 0, 18)
    end

    local requiredBottom = math.max(
        self.SubmitButton.Position.Y.Offset + self.SubmitButton.Size.Y.Offset,
        self.CancelButton.Position.Y.Offset + self.CancelButton.Size.Y.Offset,
        self.StatusLabel.Position.Y.Offset + self.StatusLabel.Size.Y.Offset
    )
    for _, part in ipairs({self.GetKeyButton, self.KeyLinkStatus, self.KeyLink, self.DiscordButton, self.DiscordStatus, self.DiscordLink}) do
        if part.Visible then requiredBottom = math.max(requiredBottom, part.Position.Y.Offset + part.Size.Y.Offset) end
    end
    contentHeight = math.max(contentHeight, requiredBottom + 28)
    self.Content.Size = UDim2.new(1, -8, 0, contentHeight)
    self.Scroll.CanvasSize = UDim2.fromOffset(0, contentHeight)
    self.KeyIcon.Visible = self.KeyLabel.Visible
    if UIS:GetFocusedTextBox() == self.Input then self:_RevealInput() end
end

function KeyGate:_WatchCamera()
    if self._cameraConnection then self._cameraConnection:Disconnect(); self._cameraConnection = nil end
    local camera = workspace.CurrentCamera
    if camera then self._cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function() self:_Layout() end) end
    self:_Layout()
end

function KeyGate:_TrackCallback(callback, ...)
    if self.Destroyed or type(callback) ~= "function" then return end
    local args = table.pack(...)
    local record = {Thread = nil, Finished = false}
    local thread = task.spawn(function()
        if self.Destroyed then return end
        local ok = pcall(callback, table.unpack(args, 1, args.n))
        if not ok and not self.Destroyed then self.LastError = "Callback failed" end
        record.Finished = true
        for index, active in ipairs(self._callbackThreads) do
            if active == record then table.remove(self._callbackThreads, index); break end
        end
    end)
    record.Thread = thread
    if not record.Finished then self._callbackThreads[#self._callbackThreads + 1] = record end
end

function KeyGate:Submit(key)
    if self.Destroyed or self.Busy or self._successCalled then return false end
    local submitted = key == nil and self.Input.Text or key
    if type(submitted) ~= "string" or submitted == "" or not submitted:match("%S") then
        self:_Status(self.Options.InvalidText, "error")
        return false
    end
    local submittedLength = utf8.len(submitted)
    if submittedLength == nil or submittedLength > self.Options.MaxLength then
        self:_Status(self.Options.InvalidText, "error")
        return false
    end

    self._generation += 1
    local generation = self._generation
    self.Busy = true
    self._cancelled = false
    self.SubmitButton.Active = false
    self.Input.TextEditable = false
    self:_Status(self.Options.ValidatingText, "normal")
    local validator = self.Options.Validate
    local submittedKey = submitted
    local thread = task.spawn(function()
        local ok, accepted, result = pcall(validator, submittedKey)
        if self.Destroyed or generation ~= self._generation or not self.Busy then submittedKey = nil; return end
        self._thread = nil
        self.Busy = false
        self.SubmitButton.Active = true
        self.Input.TextEditable = true
        if not ok then
            -- Never store or display the key or the thrown exception.
            self.Input.Text = ""
            self.LastError = "Validation callback failed"
            self:_Status(self.Options.InvalidText, "error")
        elseif accepted == true then
            self.Input.Text = ""
            self._successCalled = true
            self.Completed = true
            self:_Status(self.Options.SuccessText, "success")
            self.SubmitButton.Active = false
            self.Input.TextEditable = false
            self:_TrackCallback(self.Options.OnSuccess, self, result)
        else
            local message = safe_message(result, self.Options.InvalidText, submittedKey)
            self.Input.Text = ""
            self:_Status(message, "error")
        end
        submittedKey = nil
    end)
    if self.Busy and generation == self._generation then self._thread = thread end
    return true
end

function KeyGate:Cancel()
    if self.Destroyed or self.Completed or self._cancelled then return false end
    self._cancelled = true
    self._generation += 1
    self.Busy = false
    if self._getKeyBusy then
        self._getKeyGeneration += 1
        self._getKeyBusy = false
        self.GetKeyButton.Active = self.GetKeyButton.Visible
        self.KeyLinkStatus.Text = "Get key action cancelled."
        self.KeyLinkStatus.TextColor3 = self.Options.Theme.Muted
        self.KeyLinkStatus.Visible = self.GetKeyButton.Visible
        self._getKeyStatusKind = "manual"
    end
    local thread = self._thread
    self._thread = nil
    if thread then pcall(task.cancel, thread) end
    if self.SubmitButton then self.SubmitButton.Active = true end
    if self.Input then self.Input.TextEditable = true end
    if self.Input then self.Input.Text = "" end
    self:_Status(self.Options.CancelledText, "normal")
    self:_TrackCallback(self.Options.OnCancel, self)
    return true
end

function KeyGate:Destroy()
    if self.Destroyed then return true end
    self.Destroyed = true
    self._generation += 1
    self._copyGeneration += 1
    self._copyBusy = false
    self._getKeyGeneration += 1
    self._getKeyBusy = false
    self.Busy = false
    local threads = {}
    self._logoGeneration = (self._logoGeneration or 0) + 1
    if self._avatarThread then threads[#threads + 1] = self._avatarThread; self._avatarThread = nil end
    if self._thread then threads[#threads + 1] = self._thread; self._thread = nil end
    for _, record in ipairs(self._callbackThreads) do if record.Thread then threads[#threads + 1] = record.Thread end end
    table.clear(self._callbackThreads)
    for _, thread in ipairs(threads) do if thread ~= coroutine.running() then pcall(task.cancel, thread) end end
    for _, connection in ipairs(self._connections) do pcall(function() connection:Disconnect() end) end
    table.clear(self._connections)
    if self._cameraConnection then pcall(function() self._cameraConnection:Disconnect() end); self._cameraConnection = nil end
    release_focus(self.Gui)
    Library.KeySystems[self] = nil
    if self.Gui and not self._guiDestroying then self.Gui:Destroy() end
    return true
end

function Library:CreateKeySystem(options)
    local automaticHeight = type(options) ~= "table" or options.Height == nil
    local valid = key_options(options)
    keyGateSerial += 1
    local gate = setmetatable({
        Options = valid,
        Destroyed = false,
        Busy = false,
        Completed = false,
        _cancelled = false,
        _successCalled = false,
        Status = "",
        _generation = 0,
        _thread = nil,
        _callbackThreads = {},
        _connections = {},
        _manualLinkVisible = false,
        _discordCopyKind = nil,
        _copyGeneration = 0,
        _copyBusy = false,
        _getKeyGeneration = 0,
        _getKeyBusy = false,
        _manualKeyLinkVisible = false,
        _getKeyStatusKind = nil,
        _automaticHeight = automaticHeight,
    }, KeyGate)

    local theme, style = valid.Theme, valid.Style
    -- Drop any existing game text focus before the modal key gate takes focus.
    release_focus(valid.Parent)
    gate.Gui = create("ScreenGui", {
        Name = "GabibouUI_KeySystem_" .. keyGateSerial,
        ResetOnSpawn = false,
        ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
        DisplayOrder = valid.DisplayOrder,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, valid.Parent)
    gate.Backdrop = create("TextButton", {
        Name = "Backdrop", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = .42, Active = true, Modal = true, Text = "", AutoButtonColor = false,
    }, gate.Gui)
    gate.Card = create("Frame", {
        Name = "KeySystem", Size = UDim2.fromOffset(valid.Width, valid.Height),
        Position = valid.Position, AnchorPoint = valid.AnchorPoint,
        BackgroundColor3 = theme.Background, BorderSizePixel = 0,
    }, gate.Backdrop)
    corner(gate.Card, style.WindowRadius)
    gate.CardStroke = create("UIStroke", {Color = theme.Border, Thickness = 1, Transparency = .12}, gate.Card)
    gate.Scroll = create("ScrollingFrame", {
        Name = "ContentScroll", Position = UDim2.fromOffset(0, 0), Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.fromOffset(0, valid.Height),
        ScrollBarThickness = 4, ScrollingDirection = Enum.ScrollingDirection.Y, Active = true,
        ClipsDescendants = true,
    }, gate.Card)
    gate.Content = create("Frame", {
        Name = "Content", BackgroundTransparency = 1, Size = UDim2.new(1, -8, 0, valid.Height),
    }, gate.Scroll)
    gate.Edge = create("Frame", {
        Name = "AccentEdge", Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -40, 0, 1),
        BackgroundColor3 = theme.Accent, BackgroundTransparency = .35,
    }, gate.Content)
    create("UIGradient", {
        Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(.5, 0), NumberSequenceKeypoint.new(1, 1)}),
    }, gate.Edge)
    gate.Mark = create("Frame", {
        Name = "Mark", Position = UDim2.fromOffset(24, 24), Size = UDim2.fromOffset(42, 42),
        BackgroundColor3 = theme.Accent, BorderSizePixel = 0,
    }, gate.Content)
    corner(gate.Mark, style.ControlRadius)
    gate.MarkLabel = create("TextLabel", {
        Name = "MarkText", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
        Text = valid.MarkText, Font = style.FontBold, TextSize = style.TitleSize,
        TextColor3 = theme.AccentText, TextXAlignment = Enum.TextXAlignment.Center,
    }, gate.Mark)
    gate.MarkImage = create("ImageLabel", {
        Name = "MarkImage", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
        Image = "", ScaleType = Enum.ScaleType.Crop, Visible = false,
    }, gate.Mark)
    corner(gate.MarkImage, style.ControlRadius)
    gate.Title = create("TextLabel", {
        Name = "Title", Position = UDim2.fromOffset(78, 26), Size = UDim2.new(1, -102, 0, 25),
        BackgroundTransparency = 1, Text = valid.Title, Font = style.FontBold, TextSize = style.TitleSize,
        TextColor3 = theme.Text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, gate.Content)
    gate.Subtitle = create("TextLabel", {
        Name = "Subtitle", Position = UDim2.fromOffset(24, 82), Size = UDim2.new(1, -48, 0, 42),
        BackgroundTransparency = 1, Text = valid.Subtitle, Font = style.Font, TextSize = style.DescriptionSize,
        TextColor3 = theme.Muted, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
    }, gate.Content)
    gate.KeyLabel = create("TextLabel", {
        Name = "KeyLabel", Position = UDim2.fromOffset(44, 92), Size = UDim2.new(1, -68, 0, 18),
        BackgroundTransparency = 1, Text = valid.InputLabel, Font = style.FontBold, TextSize = style.DescriptionSize,
        TextColor3 = theme.Muted, TextXAlignment = Enum.TextXAlignment.Left,
    }, gate.Content)
    gate.KeyIcon = create("Frame", {
        Name = "KeyIcon", Position = UDim2.fromOffset(24, 95), Size = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 1,
    }, gate.Content)
    local keyRing = create("Frame", {Position = UDim2.fromOffset(0, 1), Size = UDim2.fromOffset(8, 8), BackgroundTransparency = 1}, gate.KeyIcon)
    create("UIStroke", {Color = theme.Muted, Thickness = 1.5}, keyRing)
    create("UICorner", {CornerRadius = UDim.new(1, 0)}, keyRing)
    create("Frame", {Position = UDim2.fromOffset(6, 7), Size = UDim2.fromOffset(7, 2), BackgroundColor3 = theme.Muted, BorderSizePixel = 0}, gate.KeyIcon)
    create("Frame", {Position = UDim2.fromOffset(10, 7), Size = UDim2.fromOffset(2, 4), BackgroundColor3 = theme.Muted, BorderSizePixel = 0}, gate.KeyIcon)
    gate.Input = create("TextBox", {
        Name = "KeyInput", Position = UDim2.fromOffset(24, 136), Size = UDim2.new(1, -48, 0, 44),
        BackgroundColor3 = theme.Raised, TextColor3 = theme.Text, PlaceholderColor3 = theme.Muted,
        PlaceholderText = valid.Placeholder, Text = "", ClearTextOnFocus = false,
        Font = style.Font, TextSize = style.TextSize, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, TextEditable = true, Active = true,
    }, gate.Content)
    corner(gate.Input, style.ControlRadius)
    create("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, gate.Input)
    gate.InputStroke = create("UIStroke", {Color = theme.Border, Thickness = 1, Transparency = .35}, gate.Input)
    gate.StatusLabel = create("TextLabel", {
        Name = "Status", Position = UDim2.new(0, 24, 0, valid.Height - 82), Size = UDim2.new(1, -48, 0, 20),
        BackgroundTransparency = 1, Text = "", Font = style.Font, TextSize = style.DescriptionSize,
        TextColor3 = theme.Muted, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, gate.Content)
    gate.CancelButton = create("TextButton", {
        Name = "Cancel", Position = UDim2.new(1, -198, 0, valid.Height - 60), Size = UDim2.fromOffset(78, 44),
        BackgroundColor3 = theme.Surface, Text = valid.CancelText, Font = style.FontBold,
        TextSize = style.TextSize, TextColor3 = theme.Text, AutoButtonColor = false, Selectable = true,
    }, gate.Content)
    corner(gate.CancelButton, style.ControlRadius)
    gate.CancelStroke = create("UIStroke", {Color = theme.Border, Thickness = 1, Transparency = .35}, gate.CancelButton)
    gate.SubmitButton = create("TextButton", {
        Name = "Verify", Position = UDim2.new(1, -110, 0, valid.Height - 60), Size = UDim2.fromOffset(86, 44),
        BackgroundColor3 = theme.Accent, Text = valid.SubmitText, Font = style.FontBold,
        TextSize = style.TextSize, TextColor3 = theme.AccentText, AutoButtonColor = false, Selectable = true,
    }, gate.Content)
    corner(gate.SubmitButton, style.ControlRadius)
    gate.DiscordButton = create("TextButton", {
        Name = "DiscordButton", Position = UDim2.fromOffset(24, valid.Height - 50), Size = UDim2.new(1, -48, 0, 44),
        BackgroundColor3 = type(valid.Discord) == "table" and valid.Discord.Color or Color3.fromRGB(88, 101, 242),
        Text = "", AutoButtonColor = false, Selectable = true, Visible = type(valid.Discord) == "table",
    }, gate.Content)
    corner(gate.DiscordButton, style.ControlRadius)
    gate.DiscordIcon = create("Frame", {Name = "DiscordIcon", Position = UDim2.fromOffset(14, 11), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1}, gate.DiscordButton)
    gate.DiscordVector = create("Frame", {Name = "DiscordVector", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = type(valid.Discord) == "table" and valid.Discord.Logo == nil}, gate.DiscordIcon)
    -- Antialiased Clyde silhouette from Discord's official brand kit; see THIRD_PARTY.md.
    local discordSpans={
        {6,2,1,15},
        {7,2,1,52},
        {14,2,1,50},
        {15,2,1,14},
        {3,3,1,9},
        {4,3,1,88},
        {5,3,1,172},
        {6,3,1,230},
        {7,3,1,255},
        {8,3,1,110},
        {9,3,1,60},
        {10,3,2,80},
        {12,3,1,60},
        {13,3,1,115},
        {14,3,1,255},
        {15,3,1,229},
        {16,3,1,172},
        {17,3,1,87},
        {18,3,1,8},
        {2,4,1,7},
        {3,4,1,198},
        {4,4,3,255},
        {7,4,1,254},
        {8,4,6,255},
        {14,4,1,254},
        {15,4,3,255},
        {18,4,1,193},
        {19,4,1,5},
        {0,5,1,4},
        {2,5,1,115},
        {3,5,1,255},
        {4,5,1,249},
        {5,5,1,252},
        {6,5,1,254},
        {7,5,1,255},
        {8,5,1,254},
        {9,5,1,253},
        {10,5,2,252},
        {12,5,1,253},
        {13,5,1,254},
        {14,5,1,255},
        {15,5,1,254},
        {16,5,1,252},
        {17,5,1,249},
        {18,5,1,255},
        {19,5,1,112},
        {21,5,1,4},
        {1,6,1,17},
        {2,6,1,237},
        {3,6,2,253},
        {5,6,12,255},
        {17,6,2,253},
        {19,6,1,235},
        {20,6,1,17},
        {1,7,1,113},
        {2,7,1,255},
        {3,7,1,251},
        {4,7,2,255},
        {6,7,1,253},
        {7,7,1,251},
        {8,7,1,254},
        {9,7,4,255},
        {13,7,1,254},
        {14,7,1,251},
        {15,7,1,253},
        {16,7,2,255},
        {18,7,1,251},
        {19,7,1,255},
        {20,7,1,111},
        {0,8,1,4},
        {1,8,1,209},
        {2,8,1,254},
        {3,8,1,252},
        {4,8,1,255},
        {5,8,1,254},
        {6,8,3,255},
        {9,8,1,254},
        {10,8,2,255},
        {12,8,1,254},
        {13,8,3,255},
        {16,8,1,254},
        {17,8,1,255},
        {18,8,1,252},
        {19,8,1,254},
        {20,8,1,207},
        {0,9,1,56},
        {1,9,1,254},
        {2,9,2,255},
        {4,9,1,254},
        {5,9,1,255},
        {6,9,1,209},
        {7,9,1,163},
        {8,9,1,233},
        {9,9,1,255},
        {10,9,2,254},
        {12,9,1,255},
        {13,9,1,233},
        {14,9,1,163},
        {15,9,1,210},
        {16,9,1,255},
        {17,9,1,254},
        {18,9,1,255},
        {19,9,1,254},
        {20,9,1,252},
        {21,9,1,54},
        {0,10,1,122},
        {1,10,1,255},
        {2,10,2,252},
        {4,10,1,255},
        {5,10,1,197},
        {6,10,1,7},
        {8,10,1,36},
        {9,10,1,235},
        {10,10,2,254},
        {12,10,1,235},
        {13,10,1,36},
        {15,10,1,8},
        {16,10,1,198},
        {17,10,1,254},
        {18,10,2,252},
        {20,10,1,255},
        {21,10,1,123},
        {0,11,1,179},
        {1,11,1,255},
        {2,11,1,252},
        {3,11,1,251},
        {4,11,1,255},
        {5,11,1,99},
        {7,11,1,13},
        {9,11,1,162},
        {10,11,2,255},
        {12,11,1,161},
        {14,11,1,13},
        {16,11,1,102},
        {17,11,1,255},
        {18,11,1,251},
        {19,11,1,252},
        {20,11,1,255},
        {21,11,1,175},
        {0,12,1,215},
        {1,12,1,255},
        {2,12,1,254},
        {3,12,1,251},
        {4,12,1,255},
        {5,12,1,126},
        {9,12,1,189},
        {10,12,2,255},
        {12,12,1,185},
        {16,12,1,131},
        {17,12,1,255},
        {18,12,1,251},
        {19,12,1,254},
        {20,12,1,255},
        {21,12,1,214},
        {0,13,1,232},
        {1,13,1,255},
        {2,13,3,254},
        {5,13,1,236},
        {6,13,1,69},
        {7,13,1,20},
        {8,13,1,109},
        {9,13,1,254},
        {10,13,3,253},
        {13,13,1,108},
        {14,13,1,20},
        {15,13,1,70},
        {16,13,1,237},
        {17,13,3,254},
        {20,13,1,255},
        {21,13,1,230},
        {0,14,1,242},
        {1,14,6,255},
        {7,14,1,238},
        {8,14,6,255},
        {14,14,1,238},
        {15,14,6,255},
        {21,14,1,238},
        {0,15,1,244},
        {1,15,2,253},
        {3,15,2,255},
        {5,15,1,252},
        {6,15,2,255},
        {8,15,1,254},
        {9,15,1,252},
        {10,15,2,251},
        {12,15,1,252},
        {13,15,1,254},
        {14,15,2,255},
        {16,15,1,252},
        {17,15,2,255},
        {19,15,2,253},
        {21,15,1,243},
        {0,16,1,169},
        {1,16,2,255},
        {3,16,1,250},
        {4,16,1,253},
        {5,16,1,160},
        {6,16,1,138},
        {7,16,1,215},
        {8,16,1,251},
        {9,16,4,255},
        {13,16,1,251},
        {14,16,1,215},
        {15,16,1,137},
        {16,16,1,161},
        {17,16,1,253},
        {18,16,1,250},
        {19,16,2,255},
        {21,16,1,169},
        {1,17,1,96},
        {2,17,1,225},
        {3,17,2,255},
        {5,17,1,251},
        {6,17,1,153},
        {8,17,1,40},
        {9,17,1,71},
        {10,17,2,94},
        {12,17,1,71},
        {13,17,1,40},
        {15,17,1,157},
        {16,17,1,251},
        {17,17,2,255},
        {19,17,1,225},
        {20,17,1,99},
        {2,18,1,16},
        {3,18,1,110},
        {4,18,1,208},
        {5,18,1,255},
        {6,18,1,82},
        {15,18,1,85},
        {16,18,1,255},
        {17,18,1,210},
        {18,18,1,112},
        {19,18,1,16},
        {5,19,1,44},
        {10,19,2,4},
        {16,19,1,45},
        {3,20,1,4},
        {18,20,1,4},
    }
    for _,span in ipairs(discordSpans)do
        create("Frame",{Name="DiscordSilhouette",Position=UDim2.fromScale(span[1]/22,span[2]/22),Size=UDim2.fromScale(span[3]/22,1/22),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1-span[4]/255,BorderSizePixel=0},gate.DiscordVector)
    end
    local logoWhite=Color3.new(1,1,1)
    gate.DiscordImage = create("ImageLabel", {
        Name = "DiscordImage", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        Image = type(valid.Discord) == "table" and valid.Discord.Logo or "", ImageColor3 = logoWhite,
        ScaleType = Enum.ScaleType.Fit, Visible = type(valid.Discord) == "table" and valid.Discord.Logo ~= nil,
    }, gate.DiscordIcon)
    gate.DiscordLabel = create("TextLabel", {
        Name = "DiscordText", Position = UDim2.fromOffset(44, 0), Size = UDim2.new(1, -54, 1, 0),
        BackgroundTransparency = 1, Text = type(valid.Discord) == "table" and valid.Discord.Text or "",
        Font = style.FontBold, TextSize = style.TextSize, TextColor3 = Color3.new(1, 1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
    }, gate.DiscordButton)
    gate.DiscordStatus = create("TextLabel", {
        Name = "DiscordStatus", Position = UDim2.fromOffset(24, valid.Height - 2), Size = UDim2.new(1, -48, 0, 18),
        BackgroundTransparency = 1, Text = "", Font = style.Font, TextSize = style.DescriptionSize,
        TextColor3 = theme.Muted, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        Visible = false,
    }, gate.Content)
    gate.DiscordLink = create("TextBox", {
        Name = "DiscordLink", Position = UDim2.fromOffset(24, valid.Height + 18), Size = UDim2.new(1, -48, 0, 38),
        BackgroundColor3 = theme.Raised, TextColor3 = theme.Text, Text = "", ClearTextOnFocus = false,
        TextEditable = false, Selectable = true, Font = style.Font, TextSize = style.TextSize,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Visible = false,
    }, gate.Content)
    corner(gate.DiscordLink, style.ControlRadius)
    create("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, gate.DiscordLink)
    create("UIStroke", {Color = theme.Border, Thickness = 1, Transparency = .35}, gate.DiscordLink)

    gate.GetKeyButton = create("TextButton", {
        Name = "GetKeyButton", Position = UDim2.fromOffset(24, valid.Height - 50), Size = UDim2.fromOffset(1, 44),
        BackgroundColor3 = theme.Surface, Text = "", AutoButtonColor = false, Selectable = true,
        Visible = valid.GetKey ~= nil and valid.GetKey ~= false,
    }, gate.Content)
    corner(gate.GetKeyButton, style.ControlRadius)
    create("UIStroke", {Color = theme.Border, Thickness = 1, Transparency = .35}, gate.GetKeyButton)
    gate.GetKeyIcon = Library:Icon(gate.GetKeyButton, "link", {
        Size = 18, Position = UDim2.fromOffset(12, 12), Color = theme.Muted, Name = "GetKeyIcon",
    })
    gate.GetKeyLabel = create("TextLabel", {
        Name = "GetKeyText", Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -48, 1, 0),
        BackgroundTransparency = 1, Text = type(valid.GetKey) == "table" and valid.GetKey.Text or "Get key",
        Font = style.FontBold, TextSize = style.TextSize, TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Center,
    }, gate.GetKeyButton)
    gate.KeyLinkStatus = create("TextLabel", {
        Name = "KeyLinkStatus", Position = UDim2.fromOffset(24, valid.Height - 2), Size = UDim2.new(1, -48, 0, 18),
        BackgroundTransparency = 1, Text = "", Font = style.Font, TextSize = style.DescriptionSize,
        TextColor3 = theme.Muted, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        Visible = false,
    }, gate.Content)
    gate.KeyLink = create("TextBox", {
        Name = "KeyLink", Position = UDim2.fromOffset(24, valid.Height + 18), Size = UDim2.new(1, -48, 0, 38),
        BackgroundColor3 = theme.Raised, TextColor3 = theme.Text, Text = "", ClearTextOnFocus = false,
        TextEditable = false, Selectable = true, Font = style.Font, TextSize = style.TextSize,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Visible = false,
    }, gate.Content)
    corner(gate.KeyLink, style.ControlRadius)
    create("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, gate.KeyLink)
    create("UIStroke", {Color = theme.Border, Thickness = 1, Transparency = .35}, gate.KeyLink)

    local function connect(signal, callback)
        local connection = signal:Connect(function(...)
            if not gate.Destroyed then callback(...) end
        end)
        gate._connections[#gate._connections + 1] = connection
        return connection
    end
    connect(gate.SubmitButton.Activated, function() gate:Submit() end)
    connect(gate.CancelButton.Activated, function() gate:Cancel() end)
    connect(gate.DiscordButton.Activated, function() gate:_TrackCallback(function() gate:CopyDiscordLink() end) end)
    connect(gate.GetKeyButton.Activated, function() gate:_TrackCallback(function() gate:GetKey() end) end)
    connect(gate.Input.FocusLost, function(enterPressed) if enterPressed then gate:Submit() end end)
    connect(gate.Input:GetPropertyChangedSignal("Text"), function()
        local ok, limited = pcall(Logic.text, gate.Input.Text, valid.MaxLength)
        if not ok then
            gate.Input.Text = ""
            gate:_Status(valid.InvalidText, "error")
        elseif limited ~= gate.Input.Text then
            gate.Input.Text = limited
        end
    end)
    connect(gate.Input.Focused, function()
        task.defer(function() if not gate.Destroyed then gate:_Layout(); gate:_RevealInput() end end)
    end)
    for _, property in ipairs({"OnScreenKeyboardVisible", "OnScreenKeyboardPosition", "OnScreenKeyboardSize"}) do
        connect(UIS:GetPropertyChangedSignal(property), function() gate:_Layout() end)
    end
    connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function() gate:_WatchCamera() end)
    connect(gate.Backdrop:GetPropertyChangedSignal("AbsoluteSize"), function() gate:_Layout() end)
    connect(gate.Gui.Destroying, function()
        gate._guiDestroying = true
        gate:Destroy()
    end)
    Library.KeySystems[gate] = true
    gate:_WatchCamera()
    gate:_StartLogo()
    return gate
end
