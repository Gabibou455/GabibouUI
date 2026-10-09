-- Optional window branding. Included in ui.luau's lexical scope by build.cjs.

local brandingDefaults = {
    Mode = "Initials",
    Placement = "TopLeft",
    Text = "G",
}

branding_for = function(options, base)
    assert(options == nil or type(options) == "table", "Branding must be a table")
    local result = table.clone(base or brandingDefaults)
    for key, value in pairs(options or {}) do
        assert(key == "Mode" or key == "Placement" or key == "Image" or key == "Text" or key == "UserId",
            "Unknown branding option: " .. tostring(key))
        result[key] = value
    end

    assert(result.Mode == "Avatar" or result.Mode == "Image" or result.Mode == "Initials",
        "Branding Mode must be Avatar, Image or Initials")
    assert(result.Placement == "TopLeft" or result.Placement == "TopRight" or
        result.Placement == "BottomRight" or result.Placement == "BothRight",
        "Invalid branding Placement")
    local textLength = type(result.Text) == "string" and utf8.len(result.Text) or nil
    assert(textLength and result.Text:match("%S") ~= nil and textLength <= 4,
        "Branding Text must contain 1..4 UTF-8 characters")
    if result.Image ~= nil then
        assert(type(result.Image) == "string" and #result.Image > 0 and #result.Image <= 256,
            "Branding Image must be a nonempty Roblox image content string")
        local assetId = result.Image:match("^rbxassetid://(%d+)$")
        local numericAssetId = assetId and tonumber(assetId)
        assert(assetId and #assetId <= 16 and Logic.finite(numericAssetId) and numericAssetId > 0,
            "Branding Image must use an rbxassetid:// asset")
    end
    if result.Mode == "Image" then
        assert(result.Image ~= nil, "Image mode requires Branding.Image")
    end
    if result.UserId ~= nil then
        assert(Logic.finite(result.UserId) and result.UserId >= 1 and result.UserId % 1 == 0 and result.UserId < 9007199254740992,
            "Branding UserId must be a positive integer")
    end
    return result
end

local function hasTopRight(placement)
    return placement == "TopRight" or placement == "BothRight"
end

local function hasBottomRight(placement)
    return placement == "BottomRight" or placement == "BothRight"
end

local function forgetAndDestroy(window, instance)
    if not instance then return end
    window:_ForgetTree(instance)
    instance:Destroy()
end

local function makeRightWidget(window, name, size, textSize)
    local frame = create("Frame", {
        Name = name,
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Active = false,
        Selectable = false,
        ZIndex = 7,
    }, window.Panel)
    window:_Rounded(frame, "ControlRadius")
    window:_Color(frame, "BackgroundColor3", "Raised")
    window:_Stroke(frame, "Border", 0.24)

    local highlight = create("Frame", {
        Name = "BrandHighlight",
        Position = UDim2.fromOffset(4, 1),
        Size = UDim2.new(1, -8, 0, 1),
        BackgroundTransparency = 0.58,
        BorderSizePixel = 0,
        ZIndex = 10,
    }, frame)
    window:_Color(highlight, "BackgroundColor3", "Accent")

    local label = create("TextLabel", {
        Name = "BrandInitials",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = bold,
        TextSize = textSize,
        Text = window.Branding.Text,
        TextColor3 = window.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 8,
    }, frame)
    window:_Style(label, "Font", "FontBold")
    window:_Color(label, "TextColor3", "Text")

    local image = create("ImageLabel", {
        Name = "BrandImage",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Image = "",
        ScaleType = Enum.ScaleType.Crop,
        Visible = false,
        ZIndex = 9,
    }, frame)
    window:_Rounded(image, "ControlRadius")
    return {Frame = frame, Image = image, Label = label, Highlight = highlight}
end

function Window:_CancelBranding()
    self._brandingVersion = (self._brandingVersion or 0) + 1
    local pending = self._brandingTask
    self._brandingTask = nil
    if pending then pcall(task.cancel, pending) end
end

function Window:_LayoutBranding(width, height, minimal, tiny)
    if not self.Mark then return end
    local branding = self.Branding or brandingDefaults
    local compactLogo = width < 320
    local showMark = branding.Placement == "TopLeft" and not compactLogo
    local showTop = hasTopRight(branding.Placement) and not compactLogo and not minimal and self.Layout.ShowHeader
    local showBottom = hasBottomRight(branding.Placement) and not compactLogo and not tiny and self.Layout.ShowFooter
    self.Mark.Visible = showMark
    self.Header.Size = UDim2.new(1, showTop and -188 or -112, 0, 60)

    local titleX = showMark and 50 or 0
    local titleRight = showMark and -54 or -4
    self.TitleLabel.Position = UDim2.fromOffset(titleX, 5)
    self.TitleLabel.Size = UDim2.new(1, titleRight, 0, 23)
    self._subtitle.Position = UDim2.fromOffset(titleX, 30)
    self._subtitle.Size = UDim2.new(1, titleRight, 0, 17)

    if self._brandTop then
        self._brandTop.Frame.Visible = showTop
        self._brandTop.Frame.Position = UDim2.new(1, -158, 0, 18)
    end
    if self._brandBottom then
        self._brandBottom.Frame.Visible = showBottom
        self._brandBottom.Frame.Position = UDim2.new(1, -68, 1, -34)
    end

    local footerHasLogo = showBottom
    self.Footer.Position = UDim2.new(0, 18, 1, -32)
    self.Footer.Size = UDim2.new(1, footerHasLogo and -102 or -36, 0, 22)
end

function Window:SetBranding(options)
    assert(not self.Destroyed, "Window is destroyed")
    local base
    if options ~= nil then base = self.Branding end
    local valid = branding_for(options, base)

    -- Validate fully before invalidating current assets or changing the UI.
    self:_CancelBranding()
    forgetAndDestroy(self, self._brandTop and self._brandTop.Frame)
    forgetAndDestroy(self, self._brandBottom and self._brandBottom.Frame)
    forgetAndDestroy(self, self._brandMarkImage)
    self._brandTop, self._brandBottom, self._brandMarkImage = nil, nil, nil
    if self._brandingError and self.LastError == self._brandingError then self.LastError = nil end
    self._brandingError = nil
    self.Branding = valid
    self.Mark.Text = valid.Text
    self.Mark.TextTransparency = 0
    self.Mark.ClipsDescendants = false

    if valid.Placement == "TopLeft" then
        self.Mark.ClipsDescendants = true
        local image = create("ImageLabel", {
            Name = "BrandImage",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Position = UDim2.fromScale(0, 0),
            Image = "",
            ScaleType = Enum.ScaleType.Crop,
            Visible = false,
            ZIndex = self.Mark.ZIndex + 1,
        }, self.Mark)
        corner(image, 11)
        self._brandMarkImage = image
    end
    if hasTopRight(valid.Placement) then
        self._brandTop = makeRightWidget(self, "BrandTopRight", 36, 15)
    end
    if hasBottomRight(valid.Placement) then
        self._brandBottom = makeRightWidget(self, "BrandBottomRight", 24, 10)
    end

    local targets = {}
    if self._brandMarkImage then
        targets[#targets + 1] = {Image = self._brandMarkImage, Label = self.Mark}
    end
    if self._brandTop then targets[#targets + 1] = self._brandTop end
    if self._brandBottom then targets[#targets + 1] = self._brandBottom end

    if valid.Mode == "Image" then
        for _, target in ipairs(targets) do
            target.Image.Image = valid.Image
            target.Image.Visible = true
            target.Label.TextTransparency = 1
        end
    elseif valid.Mode == "Avatar" then
        local version = self._brandingVersion
        local userId = valid.UserId or (Players.LocalPlayer and Players.LocalPlayer.UserId)
        if userId then
            self._brandingTask = task.defer(function()
                local content
                local ready = false
                for _ = 1, 12 do
                    if self.Destroyed or self._brandingVersion ~= version then return end
                    local ok, image, isReady = pcall(function()
                        return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                    end)
                    if not ok then break end
                    content, ready = image, isReady
                    if ready then break end
                    task.wait(0.25)
                end
                if self.Destroyed or self._brandingVersion ~= version then return end
                if ready and type(content) == "string" and content ~= "" then
                    for _, target in ipairs(targets) do
                        if target.Image.Parent then
                            target.Image.Image = content
                            target.Image.Visible = true
                            target.Label.TextTransparency = 1
                        end
                    end
                    if self.LastError == self._brandingError then self.LastError = nil end
                    self._brandingError = nil
                else
                    self._brandingError = "Avatar thumbnail unavailable"
                    self.LastError = self._brandingError
                end
                self._brandingTask = nil
            end)
        else
            self._brandingError = "Avatar thumbnail unavailable"
            self.LastError = self._brandingError
        end
    end

    self:_Layout()
    return self
end
