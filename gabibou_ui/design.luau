-- Validated, reusable visual-design presets. Included in ui.luau's shared lexical scope.
local function design_merge(base, override)
    local result = table.clone(base)
    for key, value in pairs(override or {}) do result[key] = value end
    return result
end

local designRadii = {
    Sharp = {WindowRadius = 8, SectionRadius = 4, ControlRadius = 0},
    Balanced = {WindowRadius = 16, SectionRadius = 12, ControlRadius = 8},
    Soft = {WindowRadius = 24, SectionRadius = 16, ControlRadius = 12},
}
local designDensities = {
    Compact = {Layout = {ContentPadding = 12, ContentGap = 12, TabGap = 6, RowGap = 6, SectionGap = 12, SearchGap = 8}, RowPadding = 10},
    Comfortable = {Layout = {ContentPadding = 16, ContentGap = 20, TabGap = 8, RowGap = 8, SectionGap = 16, SearchGap = 12}, RowPadding = 12},
    Spacious = {Layout = {ContentPadding = 20, ContentGap = 24, TabGap = 10, RowGap = 12, SectionGap = 20, SearchGap = 16}, RowPadding = 16},
}
local designPresets = {
    Studio = {
        Theme = "Graphite", Radius = "Balanced", Density = "Comfortable", Transparency = .10,
        Tabs = "Left", Navigation = "Soft",
    },
    Minimal = {
        Theme = "Graphite", Radius = "Sharp", Density = "Compact", Transparency = .02,
        Tabs = "Left", Navigation = "Classic",
    },
    Command = {
        Theme = {
            Background = Color3.fromRGB(12, 14, 17), Surface = Color3.fromRGB(25, 29, 34),
            Raised = Color3.fromRGB(39, 44, 51), Hover = Color3.fromRGB(52, 59, 67),
            Border = Color3.fromRGB(83, 91, 101), Text = Color3.fromRGB(248, 249, 251),
            Muted = Color3.fromRGB(190, 197, 205), Accent = Color3.fromRGB(248, 249, 251),
            AccentText = Color3.fromRGB(16, 18, 21),
        },
        Radius = "Balanced", Density = "Spacious", Transparency = .10,
        Tabs = "Top", Navigation = "Pill",
    },
    Atelier = {
        Theme = {
            Background = Color3.fromRGB(15, 17, 19), Surface = Color3.fromRGB(24, 27, 30),
            Raised = Color3.fromRGB(35, 39, 43), Hover = Color3.fromRGB(47, 52, 57),
            Border = Color3.fromRGB(73, 80, 87), Text = Color3.fromRGB(242, 244, 246),
            Muted = Color3.fromRGB(184, 190, 196), Accent = Color3.fromRGB(232, 235, 238),
            AccentText = Color3.fromRGB(20, 22, 24),
        },
        Radius = "Balanced", Density = "Comfortable", Transparency = .08,
        Tabs = "Left", Navigation = "Rail",
    },
}
local designFields = {Preset = true, Accent = true, Transparency = true, Radius = true, Density = true, Tabs = true, Navigation = true}
local designTabs = {Left = true, Right = true, Top = true, Bottom = true}
local designNavigation = {Classic = true, Soft = true, Pill = true, Rail = true}
local builtinDesignNames = {"Studio", "Minimal", "Command", "Atelier"}
local registeredDesigns = {}
local registeredDesignNames = {}

local function design_named(name)
    local preset = designPresets[name]
    if preset then return {Preset = name} end
    local schema = registeredDesigns[name]
    assert(schema ~= nil, "Unknown design: " .. tostring(name))
    return table.clone(schema)
end

local function design_schema(options)
    if type(options) == "string" then options = design_named(options) end
    assert(options == nil or type(options) == "table", "Design must be a table")
    local result = table.clone(options or {})
    for key in pairs(result) do assert(designFields[key], "Unknown Design option: " .. tostring(key)) end
    if result.Preset == nil then result.Preset = "Studio" end
    assert(type(result.Preset) == "string" and designPresets[result.Preset] ~= nil,
        "Design.Preset must be Studio, Minimal, Command or Atelier")
    assert(result.Accent == nil or typeof(result.Accent) == "Color3", "Design.Accent must be a Color3")
    assert(result.Transparency == nil or (Logic.finite(result.Transparency) and result.Transparency >= 0 and result.Transparency <= 1),
        "Design.Transparency must be 0..1")
    assert(result.Radius == nil or (type(result.Radius) == "number" and Logic.finite(result.Radius) and result.Radius >= 0 and result.Radius <= 32)
        or designRadii[result.Radius] ~= nil, "Design.Radius must be Sharp, Balanced, Soft or a number in 0..32")
    assert(result.Density == nil or designDensities[result.Density] ~= nil, "Design.Density must be Compact, Comfortable or Spacious")
    assert(result.Tabs == nil or designTabs[result.Tabs], "Design.Tabs must be Left, Right, Top or Bottom")
    assert(result.Navigation == nil or designNavigation[result.Navigation], "Design.Navigation must be Classic, Soft, Pill or Rail")
    return result
end

function Library:Design(options)
    return design_schema(options)
end

function Library:RegisterDesign(name, schema)
    assert(type(name) == "string" and #name > 0 and #name <= 64 and utf8.len(name) ~= nil
        and name:match("%S") ~= nil and not name:find("[%c]"),
        "Design name must contain 1..64 UTF-8 bytes and no control characters")
    assert(type(schema) == "table", "Registered design schema must be a table")
    local validated = design_schema(schema)
    if designPresets[name] or registeredDesigns[name] ~= nil then return false end
    registeredDesigns[name] = table.clone(validated)
    registeredDesignNames[#registeredDesignNames + 1] = name
    return true
end

function Library:GetDesignNames()
    local names = table.clone(builtinDesignNames)
    for _, name in ipairs(registeredDesignNames) do names[#names + 1] = name end
    return names
end

function Library:UnregisterDesign(name)
    if type(name) ~= "string" or designPresets[name] or registeredDesigns[name] == nil then return false end
    registeredDesigns[name] = nil
    for index, registeredName in ipairs(registeredDesignNames) do
        if registeredName == name then table.remove(registeredDesignNames, index); break end
    end
    return true
end

local function radius_tokens(value)
    if type(value) == "string" then return table.clone(designRadii[value]) end
    return {WindowRadius = value, SectionRadius = math.max(0, value - 4), ControlRadius = math.max(0, value - 8)}
end

local function accent_text(accent)
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

resolve_design_options = function(options, surface)
    if options == nil or options.Design == nil then return options end
    assert(type(options) == "table", "Options must be a table")
    local schema = design_schema(options.Design)
    local preset = designPresets[schema.Preset]
    local result = table.clone(options)
    result.Design = nil

    local presetTheme = type(preset.Theme) == "string" and Library.Themes[preset.Theme] or preset.Theme
    local theme = design_merge(Library.Themes.Graphite, presetTheme)
    if schema.Accent then theme.Accent = schema.Accent; theme.AccentText = accent_text(schema.Accent) end
    if type(options.Theme) == "string" then
        result.Theme = options.Theme
    else
        result.Theme = design_merge(theme, options.Theme)
    end

    local style = design_merge(Library.Style, {})
    local radius = schema.Radius or preset.Radius
    style = design_merge(style, radius_tokens(radius))
    local density = designDensities[schema.Density or preset.Density]
    style.RowPadding = density.RowPadding
    result.Style = design_merge(style, options.Style)

    local layout = design_merge(Library.Layout, {})
    layout = design_merge(layout, density.Layout)
    layout.PanelTransparency = schema.Transparency == nil and preset.Transparency or schema.Transparency
    local tabs = schema.Tabs or preset.Tabs
    layout.TabPosition = tabs
    layout.MobileTabPosition = (tabs == "Bottom" and "Bottom") or "Top"
    result.Layout = design_merge(layout, options.Layout)

    local navigation = design_merge(Library.Navigation, {Variant = schema.Navigation or preset.Navigation})
    if options.Navigation ~= nil then navigation = design_merge(navigation, options.Navigation) end
    result.Navigation = navigation

    if surface ~= "window" and options.CardTransparency == nil then
        result.CardTransparency = schema.Transparency == nil and preset.Transparency or schema.Transparency
    end
    return result
end
