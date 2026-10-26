-- Optional appearance editor, injected into ui.luau's shared lexical scope.
local function appearance_accent_text(accent)
    local function linear(channel)
        return channel <= .04045 and channel / 12.92 or ((channel + .055) / 1.055) ^ 2.4
    end
    local function luminance(color)
        return .2126 * linear(color.R) + .7152 * linear(color.G) + .0722 * linear(color.B)
    end
    local dark, light = Color3.fromRGB(19, 21, 25), Color3.fromRGB(245, 246, 248)
    local background = luminance(accent)
    local function contrast(foreground)
        local value = luminance(foreground)
        return (math.max(background, value) + .05) / (math.min(background, value) + .05)
    end
    return contrast(dark) >= contrast(light) and dark or light
end

local appearance_fields = {Title = true, Icon = true, Id = true}
local appearance_control_suffixes = {"theme", "accent", "opacity", "navigation", "tabs", "reduced_motion", "duration"}

function Window:Appearance(options)
    assert(not self.Destroyed, "Window is destroyed")
    assert(options == nil or type(options) == "table", "Appearance options must be a table")
    options = options or {}
    for key in pairs(options) do
        assert(appearance_fields[key], "Unknown Appearance option: " .. tostring(key))
    end
    local title = options.Title == nil and "Appearance" or options.Title
    assert(type(title) == "string" and utf8.len(title) and utf8.len(title) >= 1 and utf8.len(title) <= 80 and not title:find("[%c]"),
        "Appearance.Title must contain 1..80 characters without control characters")
    if options.Icon ~= nil then
        assert(Library:GetIconName(options.Icon) ~= nil, "Unknown appearance tab icon: " .. tostring(options.Icon))
    end
    local base = options.Id or "appearance"
    assert(type(base) == "string" and #base >= 1 and #base <= 64 and base:match("^[%w_-]+$"),
        "Appearance.Id must contain 1..64 letters, digits, underscores or hyphens")

    local function ids_available(prefix)
        for _, suffix in ipairs(appearance_control_suffixes) do
            if self.Controls[prefix .. "_" .. suffix] ~= nil then return false end
        end
        return true
    end
    if options.Id == nil then
        local root = base
        local serial = 1
        while not ids_available(base) do
            serial += 1
            base = root .. "_" .. tostring(serial)
            assert(#base <= 64, "Unable to allocate unique appearance control IDs")
        end
    else
        assert(ids_available(base), "Appearance control ID prefix is already in use: " .. base)
    end

    local window = self
    local initial_theme = table.clone(self.Theme)
    local initial_theme_name = self.ThemeName
    local initial_builtin = initial_theme_name == "Graphite" or initial_theme_name == "Aurora" or initial_theme_name == "Ember"
    local theme_choices = {"Graphite", "Aurora", "Ember", "Custom"}
    local theme_value = initial_builtin and initial_theme_name or "Custom"
    local starting_duration = self.Motion.Duration
    local duration_max = math.max(1, math.ceil(starting_duration))
    local tab
    local ok, result = pcall(function()
        tab = window:Tab({Title = title, Icon = options.Icon or "palette"})
        local theme_section = tab:Section({Title = "Color"})
        local theme_control, accent_control
        theme_control = theme_section:Dropdown({
            Id = base .. "_theme", Title = "Theme", Description = "Choose a built-in palette or restore this editor's starting colors.",
            Options = theme_choices, Value = theme_value, Persistent = false,
            Callback = function(value)
                if window.Destroyed or tab.Destroyed then return end
                local selected = value == "Custom" and initial_theme or value
                window:SetTheme(selected)
                accent_control:Set("#" .. window.Theme.Accent:ToHex(), false)
            end,
        })
        accent_control = theme_section:ColorPicker({
            Id = base .. "_accent", Title = "Accent color", Description = "Updates accent fills and their readable text color.",
            Value = "#" .. self.Theme.Accent:ToHex(), Persistent = false,
            Callback = function(value)
                if window.Destroyed or tab.Destroyed then return end
                local theme = table.clone(window.Theme)
                theme.Accent = Color3.fromHex(value)
                theme.AccentText = appearance_accent_text(theme.Accent)
                window:SetTheme(theme)
                if theme_control.Value ~= "Custom" then theme_control:Set("Custom", false) end
            end,
        })

        local layout_section = tab:Section({Title = "Layout & motion"})
        layout_section:Slider({
            Id = base .. "_opacity", Title = "Panel transparency", Description = "0 is opaque; 1 is fully transparent.",
            Min = 0, Max = 1, Step = .01, Value = self.Layout.PanelTransparency, Persistent = false,
            Callback = function(value)
                if not window.Destroyed and not tab.Destroyed then window:SetLayout({PanelTransparency = value}) end
            end,
        })
        layout_section:Dropdown({
            Id = base .. "_navigation", Title = "Navigation style", Options = {"Classic", "Soft", "Pill", "Rail"},
            Value = self.Navigation.Variant, Persistent = false,
            Callback = function(value)
                if not window.Destroyed and not tab.Destroyed then window:SetNavigation({Variant = value}) end
            end,
        })
        layout_section:Dropdown({
            Id = base .. "_tabs", Title = "Tab placement", Options = {"Left", "Right", "Top", "Bottom"},
            Value = self.Layout.TabPosition, Persistent = false,
            Callback = function(value)
                if not window.Destroyed and not tab.Destroyed then window:SetLayout({TabPosition = value}) end
            end,
        })
        layout_section:Toggle({
            Id = base .. "_reduced_motion", Title = "Reduce motion", Description = "Finish animated changes immediately.",
            Value = self.ReducedMotion, Persistent = false,
            Callback = function(value)
                if not window.Destroyed and not tab.Destroyed then window:SetReducedMotion(value) end
            end,
        })
        layout_section:Slider({
            Id = base .. "_duration", Title = "Animation duration", Description = "Used by future animations; 0 disables tween duration.",
            Min = 0, Max = duration_max, Step = .01, Value = starting_duration, Persistent = false,
            Callback = function(value)
                if not window.Destroyed and not tab.Destroyed then window:SetMotion({Duration = value}) end
            end,
        })
        return tab
    end)
    if not ok then
        if tab and not tab.Destroyed then pcall(function() tab:Destroy() end) end
        error(result, 2)
    end
    return result
end
