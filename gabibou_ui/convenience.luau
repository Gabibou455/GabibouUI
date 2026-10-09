-- Declarative construction and grouped value helpers. Appended inside ui.luau's
-- lexical scope, after extensions.luau and before the public return.

local function convenience_assert(condition, path, message)
    assert(condition, path .. ": " .. message)
end

local function convenience_text(value, path, optional)
    convenience_assert(optional and value == nil or type(value) == "string", path, "expected a string")
end

local function validate_array(value, path, allowEmpty)
    convenience_assert(type(value) == "table", path, "expected an array")
    local count, maximum = 0, 0
    for key in pairs(value) do
        convenience_assert(type(key) == "number" and key % 1 == 0 and key >= 1, path, "expected consecutive integer indexes")
        count += 1
        maximum = math.max(maximum, key)
    end
    convenience_assert(count == maximum, path, "array must be dense without holes")
    convenience_assert(allowEmpty or count > 0, path, "array must not be empty")
    return count
end

local function validate_at(path, callback)
    local ok, result = pcall(callback)
    if not ok then error(path .. ": " .. tostring(result), 2) end
    return result
end

local function validate_control(options, path, ids)
    convenience_assert(type(options) == "table", path, "expected a control table")
    validate_at(path..".Layout",function()return control_layout_for(options.Layout)end)
    convenience_assert(type(options.Type) == "string" and options.Type ~= "", path .. ".Type", "expected a control type")
    convenience_assert(type(options.Id) == "string" and options.Id ~= "" and #options.Id <= 96 and not options.Id:find("[%c]"), path .. ".Id", "expected a nonempty ID of at most 96 characters")
    convenience_assert(not ids[options.Id], path .. ".Id", "duplicate control ID " .. options.Id)
    ids[options.Id] = true
    convenience_text(options.Title, path .. ".Title", true)
    convenience_text(options.Description, path .. ".Description", true)
    convenience_text(options.Desc, path .. ".Desc", true)
    convenience_assert(options.Callback == nil or type(options.Callback) == "function", path .. ".Callback", "expected a function")
    convenience_assert(options.Disabled == nil or type(options.Disabled) == "boolean", path .. ".Disabled", "expected a boolean")
    convenience_assert(options.Persistent == nil or type(options.Persistent) == "boolean", path .. ".Persistent", "expected a boolean")

    local kind = options.Type
    if kind == "Toggle" then
        convenience_assert(options.Value == nil or type(options.Value) == "boolean", path .. ".Value", "Toggle default must be boolean")
    elseif kind == "Slider" then
        local minimum, maximum, step = options.Min or 0, options.Max or 100, options.Step or 1
        convenience_assert(Logic.finite(minimum) and Logic.finite(maximum) and Logic.finite(step), path, "Slider Min, Max and Step must be finite")
        local value = options.Value == nil and minimum or options.Value
        validate_at(path .. ".Value", function() return Logic.number(value, minimum, maximum, step) end)
    elseif kind == "Dropdown" then
        validate_array(options.Options, path .. ".Options", false)
        local choices = validate_at(path .. ".Options", function() return Logic.options(options.Options) end)
        local value = options.Value == nil and choices[1] or options.Value
        validate_at(path .. ".Value", function() return Logic.option(value, choices) end)
    elseif kind == "Input" then
        local maximum = options.MaxLength == nil and 120 or options.MaxLength
        convenience_assert(Logic.finite(maximum) and maximum >= 1 and maximum <= 4096, path .. ".MaxLength", "must be 1..4096")
        validate_at(path .. ".Value", function() return Logic.text(options.Value == nil and "" or options.Value, math.floor(maximum)) end)
        convenience_text(options.Placeholder, path .. ".Placeholder", true)
    elseif kind == "Keybind" then
        local value = options.Value == nil and "F6" or options.Value
        if typeof(value) == "EnumItem" then value = value.Name end
        convenience_assert(type(value) == "string" and Enum.KeyCode[value] ~= nil and value ~= "Unknown", path .. ".Value", "Keybind must name a KeyCode")
    elseif kind == "ColorPicker" then
        local value = options.Value == nil and "#F2F4F8" or options.Value
        if typeof(value) == "Color3" then value = "#" .. value:ToHex() end
        validate_at(path .. ".Value", function() return Logic.hex(value) end)
        if options.Palette ~= nil then
            local paletteCount = validate_array(options.Palette, path .. ".Palette", false)
            convenience_assert(paletteCount <= 32, path .. ".Palette", "needs at most 32 colors")
            for index, color in ipairs(options.Palette) do validate_at(path .. ".Palette[" .. index .. "]", function() return Logic.hex(color) end) end
        end
    elseif kind == "Button" then
        convenience_assert(options.Icon == nil or Library:GetIconName(options.Icon)~=nil,path..".Icon","unknown button icon")
        convenience_assert(options.IconVariant == nil or options.IconVariant=="Outline"or options.IconVariant=="Soft"or options.IconVariant=="Duotone",path..".IconVariant","invalid icon variant")
    elseif kind == "Paragraph" then
        -- No value validation is needed for these non-persistent controls.
    elseif kind == "Custom" then
        convenience_assert(options.Build == nil or type(options.Build) == "function", path .. ".Build", "expected a function")
        local height = options.Height == nil and 80 or options.Height
        convenience_assert(Logic.finite(height) and height >= 0 and height <= 2000, path .. ".Height", "must be 0..2000")
    elseif Library._components and Library._components[kind] then
        -- Component-specific options belong to its builder; this API only checks
        -- the shared control fields and registered name before creating a window.
        if options.Height ~= nil then
            convenience_assert(Logic.finite(options.Height) and options.Height >= 0 and options.Height <= 2000, path .. ".Height", "must be 0..2000")
        end
    else
        error(path .. ".Type: unknown control type " .. tostring(kind), 2)
    end
end

local function validate_create_spec(spec)
    convenience_assert(type(spec) == "table", "spec", "expected a table")
    local tabCount = validate_array(spec.Tabs, "spec.Tabs", false)
    convenience_text(spec.Title, "spec.Title", true)
    convenience_assert(spec.Parent == nil or typeof(spec.Parent) == "Instance", "spec.Parent", "expected an Instance")
    convenience_assert(spec.Loading == nil or spec.Loading == true or type(spec.Loading) == "table", "spec.Loading", "expected true or a loader config table")

    local ids, total = {}, 0
    for tabIndex = 1, tabCount do
        local tab = spec.Tabs[tabIndex]
        local tabPath = "spec.Tabs[" .. tabIndex .. "]"
        convenience_assert(type(tab) == "table", tabPath, "expected a tab table")
        convenience_assert(type(tab.Title) == "string" and tab.Title ~= "", tabPath .. ".Title", "expected a nonempty title")
        if tab.Category~=nil then
            validate_at(tabPath..".Category",function()Library:_CategoryTitle(tab.Category)end)
        end
        convenience_assert(tab.Icon == nil or Library:GetIconName(tab.Icon)~=nil,tabPath..".Icon","unknown icon name or ID")
        convenience_assert(tab.IconVariant == nil or tab.IconVariant=="Outline"or tab.IconVariant=="Soft"or tab.IconVariant=="Duotone",tabPath..".IconVariant","invalid icon variant")
        validate_at(tabPath..".Layout",function()return tab_layout_for(tab.Layout)end)
        local controlCount = tab.Controls == nil and 0 or validate_array(tab.Controls, tabPath .. ".Controls", true)
        local sectionCount = tab.Sections == nil and 0 or validate_array(tab.Sections, tabPath .. ".Sections", true)
        for index = 1, controlCount do
            local control = tab.Controls[index]
            validate_control(control, tabPath .. ".Controls[" .. index .. "]", ids)
            total += 1
        end
        for sectionIndex = 1, sectionCount do
            local section = tab.Sections[sectionIndex]
            local sectionPath = tabPath .. ".Sections[" .. sectionIndex .. "]"
            convenience_assert(type(section) == "table", sectionPath, "expected a section table")
            convenience_assert(type(section.Title) == "string" and section.Title ~= "", sectionPath .. ".Title", "expected a nonempty title")
            local sectionControlCount = section.Controls == nil and 0 or validate_array(section.Controls, sectionPath .. ".Controls", true)
            for index = 1, sectionControlCount do
                local control = section.Controls[index]
                validate_control(control, sectionPath .. ".Controls[" .. index .. "]", ids)
                total += 1
            end
        end
    end
    return total
end

local function destroy_loader(loader)
    if loader and type(loader.Destroy) == "function" then pcall(function() loader:Destroy() end) end
end

local function loader_progress(loader, created, total, title)
    if not loader then return end
    local ratio = total == 0 and 1 or created / total
    local status = total == 0 and "Building " .. title or string.format("%d/%d controls", created, total)
    loader:SetProgress(ratio, status)
end

local function build_control(container, options, path)
    local kind = options.Type
    local supplied = table.clone(options)
    supplied.Type = nil
    local method = ({Toggle="Toggle", Slider="Slider", Dropdown="Dropdown", Input="Input", Keybind="Keybind", ColorPicker="ColorPicker", Button="Button", Paragraph="Paragraph"})[kind]
    if method then return container[method](container, supplied) end
    if kind == "Custom" then return container:Custom(supplied) end
    local ok, control = pcall(function() return container:Add(kind, supplied) end)
    if not ok then error(path .. ": " .. tostring(control), 2) end
    return control
end

local function create_interface(self,spec,onWindow)
    local controlTotal = validate_create_spec(spec)
    local windowOptions = table.clone(spec)
    windowOptions.Tabs = nil
    windowOptions.Loading = nil
    local windowId = tostring(windowOptions.Id or "GabibouUI")
    local previous = self.Windows[windowId]

    local loader
    if spec.Loading then
        convenience_assert(type(self.CreateLoader) == "function", "Library.CreateLoader", "loading support is not installed")
        local config = type(spec.Loading) == "table" and table.clone(spec.Loading) or {}
        if config.Parent == nil then config.Parent = spec.Parent or windowOptions.Parent end
        if config.Title == nil then config.Title = spec.Title or windowOptions.Title end
        for _,key in ipairs({"Theme","Style","ReducedMotion"})do
            if config[key]==nil then config[key]=windowOptions[key]end
        end
        if config.DisplayOrder==nil then config.DisplayOrder=(windowOptions.DisplayOrder or 90)+1 end
        loader = self:CreateLoader(config)
        local progressOk, progressProblem = pcall(loader_progress, loader, 0, controlTotal, config.Title or windowOptions.Title or "Gabibou UI")
        if not progressOk then
            destroy_loader(loader)
            error("Library:Create loader setup failed: " .. tostring(progressProblem), 2)
        end
    end

    local window
    local ok, problem = pcall(function()
        window = self:CreateWindow(windowOptions)
        if onWindow then onWindow(window)end
        if loader then window:OnDestroy(function()destroy_loader(loader)end)end
        local created = 0
        for tabIndex, tabSpec in ipairs(spec.Tabs) do
            local tab = window:Tab({Title = tabSpec.Title, Icon = tabSpec.Icon,IconVariant=tabSpec.IconVariant,Layout=tabSpec.Layout,Category=tabSpec.Category})
            for index, controlSpec in ipairs(tabSpec.Controls or {}) do
                local path = string.format("Tabs[%d].Controls[%d]", tabIndex, index)
                build_control(tab, controlSpec, path)
                created += 1
                loader_progress(loader, created, controlTotal, window.Title)
            end
            for sectionIndex, sectionSpec in ipairs(tabSpec.Sections or {}) do
                local section = tab:Section({Title = sectionSpec.Title})
                for index, controlSpec in ipairs(sectionSpec.Controls or {}) do
                    local path = string.format("Tabs[%d].Sections[%d].Controls[%d]", tabIndex, sectionIndex, index)
                    build_control(section, controlSpec, path)
                    created += 1
                    loader_progress(loader, created, controlTotal, window.Title)
                end
            end
        end
        if loader then loader:Complete("Ready") end
    end)
    if not ok then
        local registered = self.Windows[windowId]
        if registered and registered ~= previous then pcall(function() registered:Destroy() end) end
        if window and not window.Destroyed then pcall(function() window:Destroy() end) end
        local cleanupParent = windowOptions.Parent or (Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui"))
        if registered ~= previous and not window and cleanupParent then
            local partial = cleanupParent:FindFirstChild("GabibouUI_" .. windowId)
            if partial then pcall(function() partial:Destroy() end) end
        end
        destroy_loader(loader)
        error("Library:Create failed: " .. tostring(problem), 2)
    end
    return window
end

function Library:Create(spec)return create_interface(self,spec)end

function Window:Get(id)
    assert(not self.Destroyed, "Window is destroyed")
    return self.Controls[id]
end

function Window:GetValues()
    assert(not self.Destroyed, "Window is destroyed")
    local values = {}
    for id, control in pairs(self.Controls) do
        if control.Persistent and not control.Destroyed then values[id] = control:Get() end
    end
    return values
end

function Window:SetValues(values, fireCallbacks)
    assert(not self.Destroyed, "Window is destroyed")
    assert(type(values) == "table", "Values must be a table")
    assert(fireCallbacks == nil or type(fireCallbacks) == "boolean", "fireCallbacks must be boolean")
    local staged = {}
    for id, value in pairs(values) do
        assert(type(id) == "string", "Value IDs must be strings")
        local control = self.Controls[id]
        assert(control and control.Persistent and not control.Destroyed, "Unknown or non-persistent control ID: " .. id)
        staged[#staged + 1] = {Id = id, Control = control, Value = control:_Validate(value), Previous = control:Get()}
    end
    table.sort(staged, function(a, b) return a.Id < b.Id end)
    for _, entry in ipairs(staged) do entry.Control:Set(entry.Value, false) end
    if fireCallbacks == true then
        for _, entry in ipairs(staged) do
            if entry.Value ~= entry.Previous then
                self:_Callback(entry.Control, entry.Value)
                self:_Emit(entry.Control, "Changed", entry.Value, entry.Previous)
            end
        end
    end
    return #staged
end

function Library:GetComponentNames()
    local names = {}
    for name in pairs(self._components or {}) do names[#names + 1] = name end
    table.sort(names)
    return names
end

function Library:UnregisterComponent(name, expectedBuilder)
    local registered = self._components and self._components[name]
    if not registered or (expectedBuilder ~= nil and registered ~= expectedBuilder) then return false end
    self._components[name] = nil
    return true
end
