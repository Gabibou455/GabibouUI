-- Optional, window-scoped configuration presets, injected into ui.luau's shared lexical scope.
local preset_limit = 50
local preset_blob_limit = 262144
local preset_envelope_limit = 1048576
local preset_suffixes = {"name", "profile", "save", "load", "delete"}
local preset_fields = {Title = true, Icon = true, Id = true, StorageKey = true}

local function preset_name(value)
    return type(value) == "string" and #value >= 1 and #value <= 48 and value:match("^[%w_-]+$") ~= nil
end

local function validate_snapshot(window, snapshot)
    assert(type(snapshot) == "string" and #snapshot <= preset_blob_limit, "Preset snapshot exceeds 256 KiB")
    local document = HttpService:JSONDecode(snapshot)
    Logic.profile(document, window.Controls)
    if document.theme ~= nil then
        assert(type(document.theme) == "string" and Library.Themes[document.theme], "Invalid preset theme")
    end
end

local function encode_envelope(profiles)
    local encoded = HttpService:JSONEncode({version = 1, profiles = profiles})
    assert(#encoded <= preset_envelope_limit, "Preset collection exceeds 1 MiB")
    return encoded
end

local function restore_storage(window, state, key)
    assert(preset_name(key), "Presets.StorageKey must use 1–48 letters, digits, underscores or hyphens")
    assert(type(window.Storage) == "table" and type(window.Storage.Read) == "function" and type(window.Storage.Write) == "function",
        "Presets.StorageKey requires Window.Storage.Read and Window.Storage.Write")
    if state.StorageKey then
        assert(state.StorageKey == key, "Presets storage key is already configured")
        return true
    end
    assert(not state.StorageAttempted and next(state.Profiles) == nil, "Presets storage must be configured before session presets are created")
    state.StorageAttempted = true
    state.Busy = true
    local generation = state.Generation
    local ok, data, readError = pcall(window.Storage.Read, key .. ".json")
    state.Busy = false
    if window.Destroyed or state.Generation ~= generation then return false end
    if not ok then state.StorageError = "Could not read preset storage"; return false end
    if data == nil then
        if readError ~= nil then state.StorageError = "Could not read preset storage: " .. tostring(readError); return false end
        state.StorageKey = key
        return true
    end
    if type(data) ~= "string" or #data > preset_envelope_limit then
        state.StorageError = "Preset storage is invalid or exceeds 1 MiB"; return false
    end
    local decodedOk, envelope = pcall(function() return HttpService:JSONDecode(data) end)
    if not decodedOk or type(envelope) ~= "table" or envelope.version ~= 1 or type(envelope.profiles) ~= "table" then
        state.StorageError = "Preset storage is corrupt; it was left unchanged"; return false
    end
    local profiles, count = {}, 0
    for name, snapshot in pairs(envelope.profiles) do
        if not preset_name(name) then state.StorageError = "Preset storage contains an invalid name"; return false end
        count += 1
        if count > preset_limit then state.StorageError = "Preset storage contains more than 50 profiles"; return false end
        local valid, problem = pcall(validate_snapshot, window, snapshot)
        if not valid then state.StorageError = "Preset storage contains an invalid profile: " .. tostring(problem); return false end
        profiles[name] = snapshot
    end
    state.Profiles = profiles
    state.StorageKey = key
    return true
end

local function persist_candidate(window, state, profiles)
    if not state.StorageKey then return true end
    if state.StorageError then return false, state.StorageError end
    if state.Busy then return false, "Preset storage operation is already in progress" end
    local ok, encoded = pcall(encode_envelope, profiles)
    if not ok then return false, tostring(encoded) end
    state.Busy = true
    local generation = state.Generation
    local wrote, result, writeError = pcall(window.Storage.Write, state.StorageKey .. ".json", encoded)
    state.Busy = false
    if not wrote or result == false or writeError ~= nil then return false, "Could not write preset storage: " .. tostring(writeError or result) end
    if window.Destroyed or state.Generation ~= generation then return false, "Window was destroyed during preset storage" end
    return true
end

local function preset_state(window)
    assert(not window.Destroyed, "Window is destroyed")
    if window._presetState then return window._presetState end
    local state = {Profiles = {}, Views = {}, Generation = 0, StorageAttempted = false, Busy = false}
    window._presetState = state
    window:OnDestroy(function()
        state.Generation += 1
        state.Busy = false
        table.clear(state.Profiles)
        table.clear(state.Views)
        if window._presetState == state then window._presetState = nil end
    end)
    return state
end

local function refresh_preset_views(window, state, selected)
    if window.Destroyed then return end
    for tab, view in pairs(state.Views) do
        if tab.Destroyed then
            state.Views[tab] = nil
        else
            view.Refresh(selected)
        end
    end
end

function Window:GetPresetNames()
    assert(not self.Destroyed, "Window is destroyed")
    local state = self._presetState
    local names = {}
    if not state then return names end
    if state.StorageError then return names, state.StorageError end
    for name in pairs(state.Profiles) do names[#names + 1] = name end
    table.sort(names)
    return names
end

function Window:SavePreset(name)
    if self.Destroyed then return false, "Window is destroyed" end
    if not preset_name(name) then return false, "Preset names must be 1–48 letters, digits, underscores or hyphens" end
    local state = preset_state(self)
    if state.Busy then return false, "Preset storage operation is already in progress" end
    if state.StorageError then return false, state.StorageError end
    if state.Profiles[name] == nil then
        local count = 0
        for _ in pairs(state.Profiles) do count += 1 end
        if count >= preset_limit then return false, "This window already has 50 presets" end
    end
    local ok, snapshot = pcall(function() return self:ExportConfig() end)
    if not ok then return false, "Could not export the current configuration" end
    if #snapshot > preset_blob_limit then return false, "Configuration exceeds the 256 KiB preset limit" end
    local candidate = table.clone(state.Profiles)
    candidate[name] = snapshot
    local persisted, persistError = persist_candidate(self, state, candidate)
    if not persisted then return false, persistError end
    state.Profiles = candidate
    refresh_preset_views(self, state, name)
    return true
end

function Window:LoadPreset(name, fireCallbacks)
    if self.Destroyed then return false, "Window is destroyed" end
    if not preset_name(name) then return false, "Preset names must be 1–48 letters, digits, underscores or hyphens" end
    if fireCallbacks ~= nil and type(fireCallbacks) ~= "boolean" then return false, "fireCallbacks must be boolean" end
    local state = preset_state(self)
    if state.Busy then return false, "Preset storage operation is already in progress" end
    if state.StorageError then return false, state.StorageError end
    local snapshot = state.Profiles[name]
    if snapshot == nil then return false, "No preset named " .. name end
    local ok, count = pcall(self.ImportConfig, self, snapshot, fireCallbacks == true)
    if not ok then return false, "Preset could not be loaded: " .. tostring(count) end
    refresh_preset_views(self, state, name)
    return true, count
end

function Window:DeletePreset(name)
    if self.Destroyed then return false, "Window is destroyed" end
    if not preset_name(name) then return false, "Preset names must be 1–48 letters, digits, underscores or hyphens" end
    local state = preset_state(self)
    if state.Busy then return false, "Preset storage operation is already in progress" end
    if state.StorageError then return false, state.StorageError end
    if state.Profiles[name] == nil then return false, "No preset named " .. name end
    local candidate = table.clone(state.Profiles)
    candidate[name] = nil
    local persisted, persistError = persist_candidate(self, state, candidate)
    if not persisted then return false, persistError end
    state.Profiles = candidate
    refresh_preset_views(self, state, nil)
    return true
end

function Window:Presets(options)
    assert(not self.Destroyed, "Window is destroyed")
    assert(options == nil or type(options) == "table", "Presets options must be a table")
    options = options or {}
    for key in pairs(options) do assert(preset_fields[key], "Unknown Presets option: " .. tostring(key)) end
    local title = options.Title or "Presets"
    assert(type(title) == "string" and utf8.len(title) and utf8.len(title) >= 1 and utf8.len(title) <= 80 and not title:find("[%c]"),
        "Presets.Title must contain 1..80 characters without control characters")
    if options.Icon ~= nil then assert(Library:GetIconName(options.Icon) ~= nil, "Unknown presets tab icon: " .. tostring(options.Icon)) end
    local base = options.Id or "presets"
    assert(type(base) == "string" and #base >= 1 and #base <= 64 and base:match("^[%w_-]+$"),
        "Presets.Id must contain 1..64 letters, digits, underscores or hyphens")
    if options.StorageKey ~= nil then assert(preset_name(options.StorageKey), "Presets.StorageKey must use 1–48 letters, digits, underscores or hyphens") end

    local function ids_available(prefix)
        for _, suffix in ipairs(preset_suffixes) do
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
            assert(#base <= 64, "Unable to allocate unique preset control IDs")
        end
    else
        assert(ids_available(base), "Preset control ID prefix is already in use: " .. base)
    end

    local window = self
    local state = preset_state(window)
    if options.StorageKey then
        local restored = restore_storage(window, state, options.StorageKey)
        if restored and not window.Destroyed then refresh_preset_views(window, state, nil) end
    end
    local tab
    local ok, result = pcall(function()
        tab = window:Tab({Title = title, Icon = options.Icon or "save"})
        local section = tab:Section({Title = "Configuration profiles"})
        local persistenceDescription = state.StorageKey and ("Saved with configured storage: " .. state.StorageKey .. ".")
            or state.StorageError and ("Storage unavailable: " .. state.StorageError)
            or "Session only unless you configure a storage key."
        section:Paragraph({Title = "Configuration presets", Description = persistenceDescription .. " They include persistent control values and a built-in theme; custom theme, layout, motion and window geometry are not included."})
        local names = window:GetPresetNames()
        local selectedName = names[1]
        local nameInput = section:Input({
            Id = base .. "_name", Title = "Preset name", Description = "Letters, digits, _ and -; up to 48 characters.",
            Placeholder = "e.g. evening_setup", MaxLength = 48, Value = "", Persistent = false,
        })
        local profileDropdown = section:Dropdown({
            Id = base .. "_profile", Title = "Saved preset", Description = "Choose a session preset to load or delete.",
            Options = #names > 0 and names or {"No saved presets"}, Value = selectedName or "No saved presets", Persistent = false,
            Callback = function(value)
                if window.Destroyed or tab.Destroyed then return end
                selectedName = value ~= "No saved presets" and value or nil
            end,
        })
        local function notify(kind, heading, detail)
            if window.Destroyed or tab.Destroyed then return end
            window:Notify({Title = heading, Content = detail, Kind = kind, Duration = 5})
        end
        local function refresh(selection)
            if window.Destroyed or tab.Destroyed then return end
            names = window:GetPresetNames()
            selectedName = selection
            if not selectedName or not table.find(names, selectedName) then selectedName = names[1] end
            profileDropdown:SetOptions(#names > 0 and names or {"No saved presets"}, selectedName or "No saved presets")
        end
        state.Views[tab] = {Refresh = refresh}
        local weakTab = setmetatable({tab}, {__mode = "v"})
        local teardownConnection
        teardownConnection = window:Connect(tab.Page.Destroying, function()
            local destroyedTab = weakTab[1]
            if destroyedTab then state.Views[destroyedTab] = nil end
            teardownConnection:Disconnect()
            for index = #window._connections, 1, -1 do
                if window._connections[index] == teardownConnection then table.remove(window._connections, index); break end
            end
        end)

        section:Button({
            Id = base .. "_save", Title = "Save preset", Text = "Save", Variant = "Primary",
            Description = "Saves or replaces this name" .. (state.StorageKey and " in configured storage." or " for this window session."),
            Callback = function()
                if window.Destroyed or tab.Destroyed then return end
                local name = nameInput:Get()
                local saved, reason = window:SavePreset(name)
                if not saved then notify("error", "Preset not saved", reason); return end
                refresh(name)
                notify("success", "Preset saved", name .. (state.StorageKey and " is saved in configured storage." or " is available for this window session."))
            end,
        })
        section:Button({
            Id = base .. "_load", Title = "Load preset", Text = "Load", Variant = "Secondary",
            Callback = function()
                if window.Destroyed or tab.Destroyed then return end
                if not selectedName then notify("error", "Choose a preset", "Save a preset before loading one."); return end
                local loaded, count = window:LoadPreset(selectedName, false)
                if not loaded then notify("error", "Preset not loaded", count); return end
                notify("success", "Preset loaded", tostring(count) .. " values restored.")
            end,
        })
        section:Button({
            Id = base .. "_delete", Title = "Delete preset", Text = "Delete", Variant = "Subtle",
            Callback = function()
                if window.Destroyed or tab.Destroyed then return end
                if not selectedName then notify("error", "Choose a preset", "Select a saved preset to delete."); return end
                local deleting = selectedName
                window:Confirm({
                    Title = "Delete preset?", Content = "Delete " .. deleting .. (state.StorageKey and " from configured storage?" or " from this window session?"),
                    ConfirmText = "Delete", Callback = function()
                        if window.Destroyed or tab.Destroyed then return end
                        local deleted, reason = window:DeletePreset(deleting)
                        if not deleted then notify("error", "Preset not deleted", reason); return end
                        refresh(nil)
                        notify("success", "Preset deleted", deleting .. (state.StorageKey and " was removed from configured storage." or " was removed from this window session."))
                    end,
                })
            end,
        })
        return tab
    end)
    if not ok then
        if tab and not tab.Destroyed then tab:Destroy() end
        error(result, 2)
    end
    return result
end
