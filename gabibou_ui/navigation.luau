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
    assert(result.Variant == "Classic" or result.Variant == "Soft" or result.Variant == "Pill",
        "Navigation Variant must be Classic, Soft or Pill")
    assert(result.IconVariant == "Outline" or result.IconVariant == "Soft" or result.IconVariant == "Duotone",
        "Navigation IconVariant must be Outline, Soft or Duotone")
    return result
end

local function navigationTween(window, instance, property, token, immediate)
    local previous = instance[property]
    local target = window.Theme[token]
    window:_Color(instance, property, token)
    if immediate then
        if previous ~= target then window:_CancelAnimation(instance) end
        instance[property] = target
    elseif previous ~= target then
        instance[property] = previous
        window:_Tween(instance, {[property] = target})
    end
end

local function navigationButtonState(window, button, token, transparency, immediate)
    local previousColor = button.BackgroundColor3
    local previousTransparency = button.BackgroundTransparency
    local targetColor = window.Theme[token]

    window:_Color(button, "BackgroundColor3", token)
    if immediate then
        if previousColor ~= targetColor or previousTransparency ~= transparency then
            window:_CancelAnimation(button)
        end
        button.BackgroundColor3 = targetColor
        button.BackgroundTransparency = transparency
    elseif previousColor ~= targetColor or previousTransparency ~= transparency then
        -- The window permits one active tween per instance. Animate both visual
        -- properties together so a later alpha update cannot cancel the color.
        button.BackgroundColor3 = previousColor
        button.BackgroundTransparency = previousTransparency
        window:_Tween(button, {
            BackgroundColor3 = targetColor,
            BackgroundTransparency = transparency,
        })
    end
end

local function navigationAlpha(window, instance, property, target, immediate)
    local previous = instance[property]
    if previous == target then return end
    if immediate then
        window:_CancelAnimation(instance)
        instance[property] = target
    else
        window:_Tween(instance, {[property] = target})
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

    -- Store the canonical name once; ID-based tabs then remain rebuildable if
    -- the registry later changes their numeric aliases.
    local iconName = Library:GetIconName(options.Icon)
    tab._iconVariantOverride = options.IconVariant
    local icon
    if iconName and Library._icons and type(Library._icons[iconName]) == "function" then
        icon = Library:Icon(button, iconName, {
            Size = 20,
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
    tab._iconName = iconName
    tab._hovered = false

    self:_Connect(button.MouseEnter, function()
        tab._hovered = true
        self:_RefreshNavigation(false)
    end, tab)
    self:_Connect(button.MouseLeave, function()
        tab._hovered = false
        self:_RefreshNavigation(false)
    end, tab)
    self:_Connect(button.SelectionGained, function()
        tab._hovered = true
        self:_RefreshNavigation(false)
    end, tab)
    self:_Connect(button.SelectionLost, function()
        tab._hovered = false
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
                    Size = 20,
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
        entry.Icon.Parent = tab._button
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
            local iconWidth = icon and iconSize or 0
            local labelLeft = icon and iconSize+24 or 14
            local buttonHeight=math.max(touchHeight,tab.Layout.Height or 0)
            local titleLength = utf8.len(tab.Title) or #tab.Title

            if mobile then
                local measuredTextWidth = titleLength * 8
                local desiredWidth = labelLeft + measuredTextWidth + 12
                local buttonWidth = tab.Layout.Width or math.clamp(desiredWidth,self.Layout.TabWidth,math.max(self.Layout.TabWidth,200))
                local labelWidth = math.max(0, buttonWidth - labelLeft - 12)
                button.Size = UDim2.fromOffset(buttonWidth, buttonHeight)
                if icon then icon.Position = UDim2.new(0, 14, 0.5, -iconSize/2) end
                label.Position = UDim2.new(0, labelLeft, 0, 0)
                label.Size = UDim2.new(0, labelWidth, 1, 0)
                label.TextXAlignment = Enum.TextXAlignment.Left
                indicator.Position = UDim2.new(0.5, -12, 1, -4)
                indicator.Size = UDim2.fromOffset(24, 3)
            else
                button.Size = UDim2.new(1, -4, 0, buttonHeight)
                if icon then icon.Position = UDim2.new(0, 14, 0.5, -iconSize/2) end
                label.Position = UDim2.new(0, labelLeft, 0, 0)
                label.Size = UDim2.new(1, -labelLeft - 12, 1, 0)
                label.TextXAlignment = Enum.TextXAlignment.Left
                indicator.Position = UDim2.new(0, 2, 0.5, -10)
                indicator.Size = UDim2.fromOffset(3, 20)
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
            local hovered = tab._hovered == true and not selected
            local pillSelected = variant == "Pill" and selected
            local backgroundToken = pillSelected and "Accent" or (selected and "Raised" or (hovered and "Hover" or "Surface"))
            local textToken = pillSelected and "AccentText" or ((selected or hovered) and "Text" or "Muted")
            -- Keep the rail quiet at rest. Selection remains easy to find from
            -- the raised surface, label weight, icon tint, and slim indicator.
            local alpha = selected and 0 or (variant == "Soft" and (hovered and 0.48 or 0.84) or (hovered and 0 or 1))

            navigationButtonState(self, button, backgroundToken, alpha, immediate)
            navigationTween(self, tab._label, "TextColor3", textToken, immediate)
            self:_Style(tab._label, "Font", (selected or hovered) and "FontBold" or "Font")
            self:_Style(tab._label, "TextSize", "TextSize")

            tab._stroke.Enabled = variant == "Soft" and (selected or hovered) or variant == "Classic" and selected
            tab._stroke.Transparency = selected and 0.42 or (hovered and 0.55 or 0.68)
            tab._indicator.Visible = variant ~= "Pill"
            local indicatorVisible = selected or (variant == "Soft" and hovered)
            navigationAlpha(self, tab._indicator, "BackgroundTransparency", selected and 0 or (indicatorVisible and 0.42 or 1), immediate)
            tab._indicator.Position = mobile and UDim2.new(0.5, -12, 1, -4) or UDim2.new(0, 2, 0.5, -10)
            tab._indicator.Size = mobile and UDim2.fromOffset(24, 3) or UDim2.fromOffset(3, 20)

            local icon = tab._icon
            if icon then
                local descendants = icon:GetDescendants()
                local hasMarkedPrimitive = false
                for _, descendant in ipairs(descendants) do
                    if descendant:GetAttribute("GabibouIconPrimitive") == true then
                        hasMarkedPrimitive = true
                        if descendant.BackgroundTransparency < 1 then
                            navigationTween(self, descendant, "BackgroundColor3", textToken, immediate)
                        end
                        for _, primitiveChild in ipairs(descendant:GetChildren()) do
                            if primitiveChild:IsA("UIStroke") then
                                navigationTween(self, primitiveChild, "Color", textToken, immediate)
                            end
                        end
                    end
                end
                -- Preserve the public RegisterIcon builder contract for older
                -- builders that draw directly into unmarked Frames.
                if not hasMarkedPrimitive then
                    for _, descendant in ipairs(descendants) do
                        if descendant:IsA("UIStroke") then
                            navigationTween(self, descendant, "Color", textToken, immediate)
                        elseif descendant:IsA("GuiObject") and descendant.BackgroundTransparency < 1 then
                            navigationTween(self, descendant, "BackgroundColor3", textToken, immediate)
                        end
                    end
                end
            end
        end
    end
end
