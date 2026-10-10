-- Navigation tab visuals. Injected into ui.luau's shared lexical scope.
-- Tab controls use a distinct transparent treatment; action buttons retain
-- Window:_Button's raised control styling.

Library.Navigation = Library.Navigation or {Variant = "Soft", IconVariant = "Outline"}

navigation_for = function(options, base)
    assert(options == nil or type(options) == "table", "Navigation must be a table")
    local result = table.clone(base or Library.Navigation)
    for key, value in pairs(options or {}) do
        assert(key == "Variant" or key == "IconVariant", "Unknown navigation option: " .. tostring(key))
        result[key] = value
    end
    assert(result.Variant == "Classic" or result.Variant == "Soft" or result.Variant == "Pill" or result.Variant == "Rail",
        "Navigation Variant must be Classic, Soft, Pill or Rail")
    assert(result.IconVariant == "Outline" or result.IconVariant == "Soft" or result.IconVariant == "Duotone",
        "Navigation IconVariant must be Outline, Soft or Duotone")
    return result
end

local function navigationTween(window, instance, property, token, immediate)
    local previous = instance[property]
    local target = window.Theme[token]
    local record = window._animationRecords and window._animationRecords[instance]
    local activeGoal = record and record.Goals[property]
    window:_Color(instance, property, token)
    instance[property] = previous
    if immediate then
        if activeGoal ~= nil or previous ~= target then window:_CancelAnimation(instance) end
        instance[property] = target
    elseif previous ~= target then
        if activeGoal ~= target then window:_Tween(instance, {[property] = target}) end
    elseif activeGoal ~= nil and activeGoal ~= target then
        window:_CancelAnimation(instance)
    end
end

local function navigationButtonState(window, button, token, transparency, immediate)
    local previousColor = button.BackgroundColor3
    local previousTransparency = button.BackgroundTransparency
    local targetColor = window.Theme[token]
    local record = window._animationRecords and window._animationRecords[button]
    local activeColor = record and record.Goals.BackgroundColor3
    local activeTransparency = record and record.Goals.BackgroundTransparency

    window:_Color(button, "BackgroundColor3", token)
    button.BackgroundColor3 = previousColor
    if immediate then
        if record then window:_CancelAnimation(button) end
        button.BackgroundColor3 = targetColor
        button.BackgroundTransparency = transparency
    else
        local needsTween = previousColor ~= targetColor or previousTransparency ~= transparency
        local conflictingGoal = record ~= nil and (
            (activeColor ~= nil and activeColor ~= targetColor)
            or (activeTransparency ~= nil and activeTransparency ~= transparency)
        )
        local colorSettled = previousColor == targetColor or activeColor == targetColor
        local transparencySettled = previousTransparency == transparency or activeTransparency == transparency
        if record and not conflictingGoal and colorSettled and transparencySettled then return end
        if record and (needsTween or conflictingGoal) then window:_CancelAnimation(button) end
        if needsTween then
            -- The window permits one active tween per instance. Retarget both
            -- properties together so neither can retain a stale destination.
            button.BackgroundTransparency = previousTransparency
            window:_Tween(button, {
                BackgroundColor3 = targetColor,
                BackgroundTransparency = transparency,
            })
        end
    end
end

local function navigationAlpha(window, instance, property, target, immediate)
    local previous = instance[property]
    local record = window._animationRecords and window._animationRecords[instance]
    local activeGoal = record and record.Goals[property]
    if immediate then
        if record then window:_CancelAnimation(instance) end
        instance[property] = target
    elseif previous ~= target and activeGoal ~= target then
        if record then window:_CancelAnimation(instance) end
        window:_Tween(instance, {[property] = target})
    elseif previous == target and activeGoal ~= nil and activeGoal ~= target then
        window:_CancelAnimation(instance)
    end
end

function Window:_MakeTabButton(tab, options)
    assert(not self.Destroyed and not tab.Destroyed, "Cannot create navigation for a destroyed tab")
    options = options or {}
    self.Navigation = navigation_for(self.Navigation, Library.Navigation)

    local button = create("TextButton", {
        Name = tab.Title .. "Tab",
        Text = tab.Title,
        TextTransparency = 1,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Selectable = true,
        ClipsDescendants = false,
        Size = UDim2.new(1, -4, 0, self.Responsive.TouchTarget),
    }, self.Nav)
    self:_Rounded(button, "ControlRadius")
    self:_Color(button, "BackgroundColor3", "Surface")
    local stroke = self:_Stroke(button, "Border", 0.48)
    stroke.Enabled = false

    local iconTile = create("Frame", {
        Name = "IconTile",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(32, 32),
        Position = UDim2.fromOffset(8, 6),
    }, button)
    self:_Rounded(iconTile, "ControlRadius")

    local labelSurface = create("Frame", {
        Name = "LabelSurface",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -56, 1, -8),
        Position = UDim2.fromOffset(48, 4),
    }, button)
    self:_Rounded(labelSurface, "ControlRadius")

    -- Store the canonical name once; ID-based tabs then remain rebuildable if
    -- the registry later changes their numeric aliases.
    local iconName = Library:GetIconName(options.Icon)
    tab._iconVariantOverride = options.IconVariant
    local icon
    if iconName and Library._icons and type(Library._icons[iconName]) == "function" then
        icon = Library:Icon(iconTile, iconName, {
            Size = 16,
            Thickness = 1.5,
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Window = self,
            Token = "Muted",
            Variant = tab._iconVariantOverride or self.Navigation.IconVariant,
        })
    end

    local label = self:_Label(button, tab.Title, 13, "Muted")
    label.Name = "Label"
    label.TextWrapped = false
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.AutomaticSize = Enum.AutomaticSize.None
    self:_Style(label, "TextSize", "TextSize")
    self:_Style(label, "Font", "Font")

    local indicator = create("Frame", {
        Name = "SelectionIndicator",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = button.ZIndex + 1,
    }, button)
    corner(indicator, 2)
    self:_Color(indicator, "BackgroundColor3", "Accent")

    tab._button = button
    tab._rounding = button:FindFirstChildOfClass("UICorner")
    tab._label = label
    tab._indicator = indicator
    tab._stroke = stroke
    tab._icon = icon
    tab._iconTile = iconTile
    tab._labelSurface = labelSurface
    tab._iconName = iconName
    tab._hovered = false
    tab._focused = false
    tab._pressed = false
    tab._pressedInput = nil

    local function setPressed(value)
        value = value == true
        if tab.Destroyed or self.Destroyed or tab._pressed == value then return end
        tab._pressed = value
        self:_RefreshNavigation(false)
    end

    self:_Connect(button.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            tab._pressedInput = input
            setPressed(true)
        end
    end, tab)
    self:_Connect(UIS.InputEnded, function(input)
        local pressedInput = tab._pressedInput
        if pressedInput and (input == pressedInput or
            (pressedInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)) then
            tab._pressedInput = nil
            setPressed(false)
        end
    end, tab)
    self:_Connect(UIS.WindowFocusReleased, function()
        tab._pressedInput = nil
        setPressed(false)
    end, tab)

    self:_Connect(button.MouseEnter, function()
        tab._hovered = true
        self:_RefreshNavigation(false)
    end, tab)
    self:_Connect(button.MouseLeave, function()
        tab._hovered = false
        self:_RefreshNavigation(false)
    end, tab)
    self:_Connect(button.SelectionGained, function()
        tab._focused = true
        self:_RefreshNavigation(false)
    end, tab)
    self:_Connect(button.SelectionLost, function()
        tab._focused = false
        self:_RefreshNavigation(false)
    end, tab)

    self:_LayoutNavigation(self.HorizontalTabs == true)
    self:_RefreshNavigation(true)
    return button
end

function Window:SetNavigation(options)
    assert(not self.Destroyed, "Window is destroyed")
    local valid = navigation_for(options, self.Navigation)
    local generation = (self._navigationGeneration or 0) + 1
    self._navigationGeneration = generation
    local snapshotTabs = table.clone(self.Tabs)
    local staged = {}
    local stageRoot
    local function discardStaged()
        for _, entry in ipairs(staged) do
            if entry.Icon then
                if not self.Destroyed then pcall(function() self:_ForgetTree(entry.Icon) end) end
                pcall(function() entry.Icon:Destroy() end)
            end
        end
        if stageRoot then pcall(function() stageRoot:Destroy() end); stageRoot = nil end
        table.clear(staged)
    end

    local ok, problem = pcall(function()
        stageRoot = create("Frame", {
            Name = "NavigationIconStaging",
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(0, 0),
            Visible = false,
        }, self.Gui)
        for _, tab in ipairs(snapshotTabs) do
            local desiredVariant = tab._iconVariantOverride or valid.IconVariant
            if tab._iconName and Library._icons and Library._icons[tab._iconName]
                and (not tab._icon or tab._icon:GetAttribute("GabibouIconVariant") ~= desiredVariant) then
                local icon = Library:Icon(stageRoot, tab._iconName, {
                    Name = "Icon",
                    Size = 16,
                    Thickness = 1.5,
                    Position = UDim2.fromScale(0.5, 0.5),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Window = self,
                    Token = "Muted",
                    Variant = desiredVariant,
                })
                staged[#staged + 1] = {Tab = tab, Icon = icon}
            end
        end
        assert(not self.Destroyed and generation == self._navigationGeneration, "Window navigation changed during icon build")
        assert(#self.Tabs == #snapshotTabs, "Tabs changed during icon build")
        for index, tab in ipairs(snapshotTabs) do
            assert(self.Tabs[index] == tab and not tab.Destroyed and tab._button and tab._button.Parent == self.Nav,
                "A tab changed during icon build")
        end
    end)
    if not ok then
        discardStaged()
        error("Window:SetNavigation icon build failed: " .. tostring(problem), 2)
    end

    if self.Destroyed or generation ~= self._navigationGeneration then
        discardStaged()
        error("Window navigation changed during icon build", 2)
    end
    for _, entry in ipairs(staged) do
        local tab = entry.Tab
        local previous = tab._icon
        if previous then
            self:_ForgetTree(previous)
            previous:Destroy()
        end
        entry.Icon.Parent = tab._iconTile
        entry.Icon.Visible = true
        tab._icon = entry.Icon
    end
    if stageRoot then stageRoot:Destroy(); stageRoot = nil end
    self.Navigation = valid
    self:_LayoutNavigation(self.HorizontalTabs == true)
    self:_RefreshNavigation(true)
    self:_Emit(self, "NavigationChanged", table.clone(valid))
    return self
end

function Window:_LayoutNavigation(mobile)
    if self.Destroyed or not self.Nav then return end
    mobile = mobile == true
    local touchHeight = math.max(self.Responsive.TouchTarget,self.Layout.TabHeight)
    self:_LayoutCategories()

    for _, tab in ipairs(self.Tabs) do
        local button, label, icon, indicator = tab._button, tab._label, tab._icon, tab._indicator
        if button and button.Parent then
            local iconSize=tab.Layout.IconSize or self.Layout.TabIconSize
            local rail = self.Navigation and self.Navigation.Variant == "Rail"
            local buttonHeight=math.max(touchHeight,tab.Layout.Height or 0)
            local titleLength = utf8.len(tab.Title) or #tab.Title
            -- A small, quiet track keeps the glyph secondary to its label.
            -- Layout.IconSize remains the source of truth for custom sizes.
            local tileSize=rail and math.clamp(buttonHeight-16,24,28) or 24
            local iconWidth=icon and (rail and math.clamp(iconSize,12,tileSize-8) or iconSize) or 0
            local labelLeft=icon and (rail and tileSize+20 or iconSize+20) or 14
            local surfaceLeft=rail and math.max(6,labelLeft-8) or labelLeft-4
            local surfaceRight=rail and 20 or 8

            if mobile then
                local measuredTextWidth = titleLength * 8
                local desiredWidth = labelLeft + measuredTextWidth + surfaceRight
                local buttonWidth = tab.Layout.Width or math.clamp(desiredWidth,self.Layout.TabWidth,math.max(self.Layout.TabWidth,220))
                local labelWidth = math.max(0, buttonWidth - labelLeft - surfaceRight)
                button.Size = UDim2.fromOffset(buttonWidth, buttonHeight)
                if icon then
                    tab._iconTile.Position = UDim2.new(0, 8, 0.5, -tileSize/2)
                    tab._iconTile.Size = UDim2.fromOffset(tileSize, tileSize)
                    if rail then
                        icon.Position = UDim2.fromScale(0.5, 0.5)
                        icon.AnchorPoint = Vector2.new(0.5, 0.5)
                    else
                        icon.Position = UDim2.new(0, 6, 0, tileSize/2-iconWidth/2)
                        icon.AnchorPoint = Vector2.zero
                    end
                end
                if rail then
                    tab._labelSurface.Position = UDim2.new(0, surfaceLeft, 0, 4)
                    tab._labelSurface.Size = UDim2.new(1, -surfaceLeft-8, 1, -8)
                end
                label.Position = UDim2.new(0, labelLeft, 0, 0)
                label.Size = UDim2.new(0, labelWidth, 1, 0)
                label.TextXAlignment = Enum.TextXAlignment.Left
                if rail then
                    if self.TabPlacement == "Bottom" then
                        indicator.Position = UDim2.new(0.5, -10, 0, 2)
                    else
                        indicator.Position = UDim2.new(0.5, -10, 1, -2)
                    end
                    indicator.Size = UDim2.fromOffset(20, 2)
                else
                    indicator.Position = UDim2.new(0.5, -10, 1, -2)
                    indicator.Size = UDim2.fromOffset(20, 2)
                end
            else
                -- Keep a deliberate gutter around the rail instead of letting
                -- every selected page read as a full-width card.
                button.Size = UDim2.new(1, -12, 0, buttonHeight)
                if icon then
                    tab._iconTile.Position = UDim2.new(0, 8, 0.5, -tileSize/2)
                    tab._iconTile.Size = UDim2.fromOffset(tileSize, tileSize)
                    if rail then
                        icon.Position = UDim2.fromScale(0.5, 0.5)
                        icon.AnchorPoint = Vector2.new(0.5, 0.5)
                    else
                        icon.Position = UDim2.new(0, 6, 0, tileSize/2-iconWidth/2)
                        icon.AnchorPoint = Vector2.zero
                    end
                end
                if rail then
                    tab._labelSurface.Position = UDim2.new(0, surfaceLeft, 0, 4)
                    tab._labelSurface.Size = UDim2.new(1, -surfaceLeft-8, 1, -8)
                end
                label.Position = UDim2.new(0, labelLeft, 0, 0)
                label.Size = UDim2.new(1, -labelLeft - surfaceRight, 1, 0)
                label.TextXAlignment = Enum.TextXAlignment.Left
                if rail then
                    if self.TabPlacement == "Right" then
                        indicator.Position = UDim2.new(0, 3, 0.5, -7)
                    else
                        indicator.Position = UDim2.new(1, -15, 0.5, -7)
                    end
                    indicator.Size = UDim2.fromOffset(2, 14)
                else
                    indicator.Position = UDim2.new(0, 3, 0.5, -9)
                    indicator.Size = UDim2.fromOffset(2, 18)
                end
            end

            if icon then icon.Size = UDim2.fromOffset(iconWidth, iconWidth) end
            if tab._rounding then
                local radius = self.Navigation and self.Navigation.Variant == "Pill" and buttonHeight / 2 or self.Style.ControlRadius
                tab._rounding.CornerRadius = UDim.new(0, radius)
            end
        end
    end
end

function Window:_RefreshNavigation(immediate)
    if self.Destroyed then return end
    immediate = immediate == true
    local mobile = self.HorizontalTabs == true

    for _, tab in ipairs(self.Tabs) do
        local button = tab._button
        if button and button.Parent then
            local variant = self.Navigation and self.Navigation.Variant or "Classic"
            local selected = tab == self.CurrentTab
            local hovered = (tab._hovered == true or tab._focused == true) and not selected
            local railPressed = variant == "Rail" and tab._pressed == true
            local contrastSelected = selected and variant == "Pill"
            local backgroundToken = contrastSelected and "Accent" or (selected and "Raised" or (hovered and "Hover" or "Surface"))
            local textToken = contrastSelected and "AccentText" or ((selected or hovered or railPressed) and "Text" or "Muted")
            local iconToken = variant == "Rail" and (selected or railPressed) and "Text" or textToken
            -- Keep the rail quiet at rest. Selection remains easy to find from
            -- the raised surface, label weight, icon tint, and slim indicator.
            local alpha = variant == "Rail" and 1 or (variant == "Pill" and 0 or
                ((selected or hovered) and (selected and 0.46 or 0.78) or 1))

            navigationButtonState(self, button, backgroundToken, alpha, immediate)
            local labelSurfaceToken = (selected or railPressed) and "Raised" or (hovered and "Hover" or "Surface")
            local labelSurfaceAlpha = railPressed and 0.34 or (selected and 0.58 or (hovered and 0.78 or 1))
            navigationButtonState(self, tab._labelSurface, labelSurfaceToken,
                variant == "Rail" and labelSurfaceAlpha or 1, immediate)
            local iconTileToken = (selected or railPressed or hovered) and "Raised" or "Surface"
            local iconTileAlpha = not tab._icon and 1 or (selected and 0.58 or (railPressed and 0.34 or (hovered and 0.72 or 1)))
            navigationButtonState(self, tab._iconTile, iconTileToken,
                variant == "Rail" and iconTileAlpha or 1, immediate)
            navigationTween(self, tab._label, "TextColor3", textToken, immediate)
            self:_Style(tab._label, "Font", (selected or hovered) and "FontBold" or "Font")
            self:_Style(tab._label, "TextSize", "TextSize")

            tab._stroke.Enabled = variant == "Soft" and (hovered or selected) or variant == "Classic" and selected
            tab._stroke.Transparency = selected and 0.66 or (hovered and 0.76 or 0.84)
            tab._indicator.Visible = variant ~= "Pill"
            local indicatorVisible = selected or railPressed or ((variant == "Soft" or variant == "Rail") and hovered)
            navigationAlpha(self, tab._indicator, "BackgroundTransparency", (selected or railPressed) and 0 or (indicatorVisible and 0.42 or 1), immediate)
            self:_Color(tab._indicator, "BackgroundColor3", selected and contrastSelected and "AccentText" or "Accent")
            if variant == "Rail" then
                if mobile then
                    tab._indicator.Position = self.TabPlacement == "Bottom"
                        and UDim2.new(0.5, -10, 0, 2) or UDim2.new(0.5, -10, 1, -2)
                    tab._indicator.Size = UDim2.fromOffset(20, 2)
                else
                    tab._indicator.Position = self.TabPlacement == "Right"
                        and UDim2.new(0, 3, 0.5, -7) or UDim2.new(1, -15, 0.5, -7)
                    tab._indicator.Size = UDim2.fromOffset(2, 14)
                end
            else
                tab._indicator.Position = mobile and UDim2.new(0.5, -10, 1, -2) or UDim2.new(0, 3, 0.5, -9)
                tab._indicator.Size = mobile and UDim2.fromOffset(20, 2) or UDim2.fromOffset(2, 18)
            end

            local icon = tab._icon
            if icon then
                local descendants = icon:GetDescendants()
                local hasMarkedPrimitive = false
                for _, descendant in ipairs(descendants) do
                    if descendant:GetAttribute("GabibouIconPrimitive") == true then
                        hasMarkedPrimitive = true
                        if descendant.BackgroundTransparency < 1 then
                            navigationTween(self, descendant, "BackgroundColor3", iconToken, immediate)
                        end
                        for _, primitiveChild in ipairs(descendant:GetChildren()) do
                            if primitiveChild:IsA("UIStroke") then
                                navigationTween(self, primitiveChild, "Color", iconToken, immediate)
                            end
                        end
                    end
                end
                -- Preserve the public RegisterIcon builder contract for older
                -- builders that draw directly into unmarked Frames.
                if not hasMarkedPrimitive then
                    for _, descendant in ipairs(descendants) do
                        if descendant:IsA("UIStroke") then
                            navigationTween(self, descendant, "Color", iconToken, immediate)
                        elseif descendant:IsA("GuiObject") and descendant.BackgroundTransparency < 1 then
                            navigationTween(self, descendant, "BackgroundColor3", iconToken, immediate)
                        end
                    end
                end
            end
        end
    end
end
