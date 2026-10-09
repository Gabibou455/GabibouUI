-- Public customization API. Included in the same lexical scope as ui.luau.
-- No separate event loop: every subscription and tween belongs to its window.
Library.Style = {
    Font = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,
    TextSize = 14,
    DescriptionSize = 12,
    TitleSize = 18,
    WindowRadius = 16,
    SectionRadius = 12,
    ControlRadius = 8,
    RowPadding = 12,
}
Library.Motion = {
    Duration = 0.16,
    Style = Enum.EasingStyle.Quad,
    Direction = Enum.EasingDirection.Out,
    RepeatCount = 0,
    Reverses = false,
    Delay = 0,
}
Library._components = {}

local function enum(value, expected)
    return typeof(value) == "EnumItem" and value.EnumType == expected
end

style_for = function(options, base)
    assert(options == nil or type(options) == "table", "Style must be a table")
    local result = table.clone(base)
    for key, value in pairs(options or {}) do
        assert(result[key] ~= nil, "Unknown style token: " .. tostring(key))
        result[key] = value
    end
    for key, value in pairs(result) do
        if key == "Font" or key == "FontBold" then
            assert(enum(value, Enum.Font), "Style font must be an Enum.Font")
        else
            local minimum = (key == "RowPadding" and 8) or (key:find("Size") and 10) or 0
            assert(Logic.finite(value) and value >= minimum and value <= 32, "Style value out of range: " .. key)
        end
    end
    return result
end

motion_for = function(options, base)
    assert(options == nil or type(options) == "table", "Motion must be a table")
    local result = table.clone(base)
    for key, value in pairs(options or {}) do
        assert(result[key] ~= nil, "Unknown motion option: " .. tostring(key))
        result[key] = value
    end
    assert(Logic.finite(result.Duration) and result.Duration >= 0 and result.Duration <= 30, "Duration must be 0..30 seconds")
    assert(Logic.finite(result.Delay) and result.Delay >= 0 and result.Delay <= 30, "Delay must be 0..30 seconds")
    assert(enum(result.Style, Enum.EasingStyle), "Style must be an EasingStyle")
    assert(enum(result.Direction, Enum.EasingDirection), "Direction must be an EasingDirection")
    assert(Logic.finite(result.RepeatCount) and result.RepeatCount % 1 == 0 and result.RepeatCount >= -1 and result.RepeatCount <= 100, "RepeatCount must be -1..100")
    assert(type(result.Reverses) == "boolean", "Reverses must be boolean")
    return result
end

function Window:_Style(instance, property, token, transform)
    self:_TrackBindingTarget(instance)
    local bindings = self._styleTargets[instance] or {}
    bindings[property] = {Token = token, Transform = transform}
    self._styleTargets[instance] = bindings
    local value = self.Style[token]
    instance[property] = transform and transform(value) or value
end

function Window:_Rounded(instance, token)
    local rounding = create("UICorner", {}, instance)
    self:_Style(rounding, "CornerRadius", token, function(value) return UDim.new(0, value) end)
    return rounding
end

function Library:SetStyle(options)
    self.Style = style_for(options, self.Style)
    return self
end

function Library:SetMotion(options)
    self.Motion = motion_for(options, self.Motion)
    return self
end

function Window:SetStyle(options)
    assert(not self.Destroyed, "Window is destroyed")
    local valid = style_for(options, self.Style)
    self.Style = valid
    for instance, bindings in pairs(self._styleTargets) do
        self:_CancelForProperties(instance, bindings)
        for property, binding in pairs(bindings) do
            local value = valid[binding.Token]
            instance[property] = binding.Transform and binding.Transform(value) or value
        end
    end
    self:_Layout()
    self:_Emit(self, "StyleChanged", table.clone(valid))
    return self
end

function Window:SetMotion(options)
    assert(not self.Destroyed, "Window is destroyed")
    self.Motion = motion_for(options, self.Motion)
    self:_Emit(self, "MotionChanged", table.clone(self.Motion))
    return self
end

function Window:_CancelAnimation(instance)
    local record = self._animationRecords[instance]
    if not record then return end
    self._animationRecords[instance] = nil
    self._tweens[instance] = nil
    if record.Completed then record.Completed:Disconnect()end
    if record.Destroying then record.Destroying:Disconnect()end
    if record.Ancestry then record.Ancestry:Disconnect()end
    record.Tween:Cancel()
end

function Window:_CancelForProperties(instance, properties)
    local record = self._animationRecords[instance]
    if not record then return end
    for property in pairs(properties) do
        if record.Goals[property] ~= nil then self:_CancelAnimation(instance);return end
    end
end

function Window:Animate(instance, properties, options)
    assert(not self.Destroyed, "Window is destroyed")
    assert(typeof(instance) == "Instance" and instance:IsDescendantOf(self.Gui), "Animation target must belong to this window")
    assert(type(properties) == "table" and next(properties) ~= nil, "Animation needs at least one property")
    assert(options == nil or type(options) == "table", "Animation options must be a table")
    local supplied = table.clone(options or {})
    local onComplete = supplied.OnComplete
    supplied.OnComplete = nil
    assert(onComplete == nil or type(onComplete) == "function", "OnComplete must be a function")
    local policy = motion_for(supplied, self.Motion)
    local goals = table.clone(properties)
    local reduced = self.ReducedMotion
    local info = TweenInfo.new(reduced and 0 or policy.Duration, policy.Style, policy.Direction,
        reduced and 0 or policy.RepeatCount, not reduced and policy.Reverses, reduced and 0 or policy.Delay)
    -- TweenService validates properties before a currently playing tween is cancelled.
    local tween = TweenService:Create(instance, info, goals)
    self:_CancelAnimation(instance)
    local record: {Tween: Tween, Goals: {[string]: any}, Completed: RBXScriptConnection?, Destroying: RBXScriptConnection?, Ancestry: RBXScriptConnection?} = {Tween = tween, Goals = goals}
    self._tweens[instance] = tween
    self._animationRecords[instance] = record
    local function detach()
        if self._animationRecords[instance] ~= record then return false end
        self._animationRecords[instance] = nil
        self._tweens[instance] = nil
        if record.Completed then record.Completed:Disconnect()end
        if record.Destroying then record.Destroying:Disconnect()end
        if record.Ancestry then record.Ancestry:Disconnect()end
        return true
    end
    record.Completed = tween.Completed:Connect(function(state)
        if not detach() then return end
        if state == Enum.PlaybackState.Completed and onComplete and not self.Destroyed then
            self:_RunUser(self, function()
                if instance:IsDescendantOf(self.Gui) then onComplete(instance) end
            end)
        end
    end)
    record.Destroying = instance.Destroying:Connect(function() self:_CancelAnimation(instance) end)
    record.Ancestry = instance.AncestryChanged:Connect(function()
        if not instance:IsDescendantOf(self.Gui) then self:_CancelAnimation(instance) end
    end)
    if reduced then for property, goal in pairs(goals) do instance[property] = goal end end
    tween:Play()
    return tween
end

function Control:Animate(properties, options)
    assert(not self.Destroyed, "Control is destroyed")
    return self.Window:Animate(self.Root, properties, options)
end

function Window:BindColor(instance, property, token)
    assert(not self.Destroyed, "Window is destroyed")
    assert(typeof(instance) == "Instance" and instance:IsDescendantOf(self.Gui), "Color target must belong to this window")
    assert(self.Theme[token] ~= nil and typeof(instance[property]) == "Color3", "Invalid color binding")
    self:_Color(instance, property, token)
    return self
end

function Window:_RunUser(owner, callback, ...)
    local arguments = table.pack(...)
    spawn_owned(owner, function()
        if self.Destroyed or owner.Destroyed or owner.Enabled == false then return end
        local ok, problem = pcall(callback, table.unpack(arguments, 1, arguments.n))
        if not ok and not self.Destroyed and not owner.Destroyed then
            self.LastError = tostring(problem)
            warn("[Gabibou UI] extension: " .. tostring(problem))
            self:Notify({Title = "Extension error", Content = tostring(problem), Kind = "error"})
        end
    end)
end

function Window:_Emit(owner, name, ...)
    local bucket = owner._events and owner._events[name]
    if not bucket then return end
    local arguments = table.pack(...)
    for _, subscription in ipairs(table.clone(bucket)) do
        self:_RunUser(owner, function()
            if subscription.Connected then subscription.Callback(table.unpack(arguments, 1, arguments.n)) end
        end)
    end
end

function Window:_Subscribe(owner, name, callback)
    assert(not self.Destroyed and not owner.Destroyed, "Owner is destroyed")
    assert(type(callback) == "function", "Event callback must be a function")
    owner._events = owner._events or {}
    local bucket = owner._events[name] or {}
    owner._events[name] = bucket
    local subscription = {Connected = true, Callback = callback}
    function subscription:Disconnect()
        if not self.Connected then return end
        self.Connected = false
        self.Callback = nil
        for index, entry in ipairs(bucket) do
            if entry == self then table.remove(bucket, index); break end
        end
    end
    bucket[#bucket + 1] = subscription
    return subscription
end

function Window:_DisconnectEvents(owner)
    for _, bucket in pairs(owner._events or {}) do
        for _, subscription in ipairs(table.clone(bucket)) do subscription:Disconnect() end
    end
    owner._events = nil
end

function Window:On(name, callback)
    local supported = {TabChanged = true, VisibilityChanged = true, ThemeChanged = true, StyleChanged = true, MotionChanged = true, ReducedMotionChanged = true, NavigationChanged = true}
    assert(supported[name], "Unknown window event: " .. tostring(name))
    return self:_Subscribe(self, name, callback)
end

function Control:On(name, callback)
    assert(not self.Destroyed, "Control is destroyed")
    assert(type(callback) == "function", "Event callback must be a function")
    local window = self.Window
    if name ~= "Changed" then
        local signal
        local focusTarget = self._colorInput or self._input
        if name == "HoverEnter" then signal = self.Root.MouseEnter
        elseif name == "HoverLeave" then signal = self.Root.MouseLeave
        elseif name == "Activated" and self._input and self._input:IsA("GuiButton") then signal = self._input.Activated
        elseif name == "FocusGained" and focusTarget then signal = focusTarget:IsA("TextBox") and focusTarget.Focused or focusTarget.SelectionGained
        elseif name == "FocusLost" and focusTarget then signal = focusTarget:IsA("TextBox") and focusTarget.FocusLost or focusTarget.SelectionLost
        end
        assert(signal, "Unsupported control event: " .. tostring(name))
        self._hookSignals = self._hookSignals or {}
        if not self._hookSignals[name] then
            self._hookSignals[name] = window:_Connect(signal, function(...) window:_Emit(self, name, ...) end, self)
        end
    end
    return window:_Subscribe(self, name, callback)
end

function Window:Connect(signal, callback)
    assert(not self.Destroyed and typeof(signal) == "RBXScriptSignal" and type(callback) == "function", "Connect expects a signal and function on a live window")
    return self:_Connect(signal, function(...) self:_RunUser(self, callback, ...) end)
end

function Control:Connect(signal, callback)
    assert(not self.Destroyed and typeof(signal) == "RBXScriptSignal" and type(callback) == "function", "Connect expects a signal and function on a live control")
    return self.Window:_Connect(signal, function(...) self.Window:_RunUser(self, callback, ...) end, self)
end

local function own(owner, resource)
    assert(not owner.Destroyed, "Owner is destroyed")
    assert((typeof(resource) == "RBXScriptConnection") or (type(resource) == "table" and type(resource.Disconnect) == "function"), "Own expects a disconnectable resource")
    owner._connections[#owner._connections + 1] = resource
    return resource
end

function Window:Own(resource) return own(self, resource) end
function Control:Own(resource) return own(self, resource) end

function Container:Custom(options)
    options = options or {}
    local height = options.Height or 80
    assert(Logic.finite(height) and height >= 0 and height <= 2000, "Custom Height must be 0..2000")
    assert(options.Build == nil or type(options.Build) == "function", "Build must be a function")
    local control = self:_Row("Custom", options, nil, false)
    list(control.Root, 10, false)
    control._text.LayoutOrder = 0
    control.Content = create("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height), LayoutOrder = 1}, control.Root)
    if options.Build then
        local ok, problem = pcall(options.Build, control.Content, control, self.Window, options)
        if not ok then control:Destroy(); error("Custom build failed: " .. tostring(problem), 2) end
    end
    self.Window:SearchFor(self.Window.Query)
    return control
end

function Control:SetHeight(height)
    assert(not self.Destroyed and self.Kind == "Custom", "SetHeight is for a live Custom control")
    assert(Logic.finite(height) and height >= 0 and height <= 2000, "Custom Height must be 0..2000")
    self.Content.Size = UDim2.new(1, 0, 0, height)
    return self
end

function Library:RegisterComponent(name, builder)
    assert(type(name) == "string" and name:match("^[%a][%w_]*$") and #name <= 48, "Component name must be an identifier")
    assert(type(builder) == "function" and self._components[name] == nil, "Component needs a unique name and builder")
    self._components[name] = builder
    return self
end

function Container:Add(name, options)
    local builder = assert(Library._components[name], "Unknown custom component: " .. tostring(name))
    assert(options == nil or type(options) == "table", "Component options must be a table")
    local supplied = table.clone(options or {})
    supplied.Title = supplied.Title or name
    supplied.Build = builder
    return self:Custom(supplied)
end
