-- Window-scoped command registry and search palette; injected into ui.luau's shared scope.
local command_option_keys = {Id = true, Title = true, Description = true, Keywords = true, Icon = true, Callback = true}
local command_limit = 256
local command_result_limit = 50
local command_query_limit = 256
local command_active_window
local command_order = 0

local function command_mark_active(window)
    if window and not window.Destroyed and not window.Closed and window._commandCount and window._commandCount > 0 then
        command_active_window = window
    elseif command_active_window == window then
        command_active_window = nil
    end
end

local function command_find_window_at(position)
    local winner, winner_order, winner_display
    for _, candidate in pairs(Library.Windows) do
        if candidate._commands and not candidate.Destroyed and not candidate.Closed and candidate.Root.Visible then
            local origin, size = candidate.Root.AbsolutePosition, candidate.Root.AbsoluteSize
            if position.X >= origin.X and position.Y >= origin.Y and position.X <= origin.X + size.X and position.Y <= origin.Y + size.Y then
                local display = candidate.Gui.DisplayOrder
                local order = candidate._commandWindowOrder or 0
                if not winner or display > winner_display or display == winner_display and order > winner_order then
                    winner, winner_order, winner_display = candidate, order, display
                end
            end
        end
    end
    command_active_window = winner
end

local function command_reselect_active(excluded)
    local winner, winner_order, winner_display
    for _, candidate in pairs(Library.Windows) do
        if candidate ~= excluded and candidate._commands and candidate._commandCount > 0
            and not candidate.Destroyed and not candidate.Closed and candidate.Root.Visible then
            local display, order = candidate.Gui.DisplayOrder, candidate._commandWindowOrder or 0
            if not winner or display > winner_display or display == winner_display and order > winner_order then
                winner, winner_order, winner_display = candidate, order, display
            end
        end
    end
    command_active_window = winner
end

local function command_text(value, field, maximum, required)
    if value == nil and not required then return "" end
    assert(type(value) == "string", "Command." .. field .. " must be a string")
    local length = utf8.len(value)
    assert(length ~= nil and (not required or length >= 1) and length <= maximum and not value:find("[%c]"),
        "Command." .. field .. " must be valid UTF-8 with " .. (required and "1.." or "0..") .. tostring(maximum) .. " characters and no control characters")
    return value
end

local function command_keywords(value)
    if value == nil then return {} end
    assert(type(value) == "table", "Command.Keywords must be an array")
    local count, maximum = 0, 0
    for key in pairs(value) do
        assert(type(key) == "number" and key % 1 == 0 and key >= 1, "Command.Keywords must be a dense array")
        count += 1
        maximum = math.max(maximum, key)
    end
    assert(count == maximum and count <= 20, "Command.Keywords must contain at most 20 entries without holes")
    local result, seen = {}, {}
    for index = 1, count do
        local keyword = command_text(value[index], "Keywords[" .. tostring(index) .. "]", 48, true)
        local normalized = string.lower(keyword)
        assert(not seen[normalized], "Command.Keywords must be unique")
        seen[normalized] = true
        result[index] = keyword
    end
    return result
end

local function command_matches(command, query)
    local haystack = string.lower(command.Title .. " " .. command.Description .. " " .. table.concat(command.Keywords, " "))
    for word in string.lower(query):gmatch("%S+") do
        if not string.find(haystack, word, 1, true) then return false end
    end
    return true
end

local function command_close_palette(window)
    local palette = window._commandPalette
    if not palette then return false end
    window._commandPalette = nil
    palette.Destroyed = true
    if palette.Search and UIS:GetFocusedTextBox() == palette.Search then
        pcall(function() palette.Search:ReleaseFocus(false) end)
    end
    for _, owner in ipairs(palette.RowOwners or {}) do
        owner.Destroyed = true
        disconnect(owner._connections, owner)
    end
    if palette.RowOwners then table.clear(palette.RowOwners) end
    disconnect(palette._connections, palette)
    if palette.Root and palette.Root.Parent then
        window:_ForgetTree(palette.Root)
        palette.Root:Destroy()
    end
    return true
end

local function command_activate(window, command, palette)
    if window.Destroyed or window.Closed or command.Destroyed or window._commands[command.Id] ~= command
        or palette and window._commandPalette ~= palette then return false end
    command_close_palette(window)
    window:_RunUser(command, function() command.Callback(command) end)
    return true
end

local function command_palette_bounds(window, palette)
    local width, height = window.Canvas.AbsoluteSize.X, window.Canvas.AbsoluteSize.Y
    local dialog_width = math.max(1, math.min(560, width - 32))
    local dialog_height = math.max(1, math.min(480, height - 32))
    palette.Dialog.Size = UDim2.fromOffset(dialog_width, dialog_height)
    palette.Dialog.Position = UDim2.fromScale(.5, .5)
end

local function command_render(window, palette)
    if window.Destroyed or palette.Destroyed or window._commandPalette ~= palette then return end
    local query = palette.Search.Text
    local valid_query = Logic.text(query, command_query_limit)
    if valid_query ~= query then
        palette.Search.Text = valid_query
        return
    end
    palette.Query = valid_query
    for _, row in ipairs(palette.Rows) do
        local owner = palette.RowOwners[#palette.RowOwners]
        if owner then owner.Destroyed = true;disconnect(owner._connections, owner) end
        table.remove(palette.RowOwners)
        window:_ForgetTree(row)
        row:Destroy()
    end
    table.clear(palette.Rows)
    table.clear(palette.RowOwners)
    palette.Matches = {}
    for _, command in ipairs(window._commandOrder) do
        if not command.Destroyed and window._commands[command.Id] == command and command_matches(command, valid_query) then
            palette.Matches[#palette.Matches + 1] = command
            if #palette.Matches >= command_result_limit then break end
        end
    end
    local empty = #palette.Matches == 0
    palette.Empty.Visible = empty
    palette.List.Visible = not empty
    palette.List.CanvasSize = UDim2.fromOffset(0, #palette.Matches * 48)
    palette.Selected = empty and 0 or 1
    for index, command in ipairs(palette.Matches) do
        local row = create("TextButton", {
            Name = "Command_" .. tostring(index), Text = "", AutoButtonColor = false, Selectable = true,
            Size = UDim2.new(1, -8, 0, 44), Position = UDim2.fromOffset(4, (index - 1) * 48),
            LayoutOrder = index, ZIndex = 33,
        }, palette.List)
        window:_Rounded(row, "ControlRadius")
        window:_Color(row, "BackgroundColor3", index == palette.Selected and "Hover" or "Raised")
        window:_Stroke(row, "Border", .82)
        local title = window:_Label(row, command.Title, 13, "Text")
        title.Name = "CommandTitle";title.Position = UDim2.fromOffset(command.Icon and 48 or 14, 5)
        title.Size = UDim2.new(1, command.Icon and -60 or -28, 0, command.Description ~= "" and 18 or 32)
        title.TextWrapped = false;title.TextTruncate = Enum.TextTruncate.AtEnd;title.ZIndex = 34
        window:_Style(title, "Font", "FontBold")
        if command.Description ~= "" then
            local description = window:_Label(row, command.Description, 11, "Muted")
            description.Name = "CommandDescription";description.Position = UDim2.fromOffset(command.Icon and 48 or 14, 24)
            description.Size = UDim2.new(1, command.Icon and -60 or -28, 0, 15)
            description.TextWrapped = false;description.TextTruncate = Enum.TextTruncate.AtEnd;description.ZIndex = 34
        end
        if command.Icon then
            Library:Icon(row, command.Icon, {Size = 18, Position = UDim2.fromOffset(14, 13), Window = window, Token = "Muted"})
        end
        palette.Rows[#palette.Rows + 1] = row
        local owner = {Destroyed = false, _connections = {}}
        palette.RowOwners[#palette.RowOwners + 1] = owner
        window:_Connect(row.Activated, function() command_activate(window, command, palette) end, owner)
        window:_Connect(row.MouseEnter, function()
            if owner.Destroyed or palette.Destroyed then return end
            for item_index, item in ipairs(palette.Matches) do
                local item_row = palette.Rows[item_index]
                if item_row then window:_Color(item_row, "BackgroundColor3", item == command and "Hover" or "Raised") end
            end
            palette.Selected = index
        end, owner)
    end
end

local function command_move_selection(window, palette, delta)
    if #palette.Matches == 0 then return end
    palette.Selected = ((palette.Selected - 1 + delta) % #palette.Matches) + 1
    for index, row in ipairs(palette.Rows) do
        window:_Color(row, "BackgroundColor3", index == palette.Selected and "Hover" or "Raised")
    end
    local selected = palette.Rows[palette.Selected]
    if selected then
        local top = selected.Position.Y.Offset
        local bottom = top + selected.AbsoluteSize.Y
        local current = palette.List.CanvasPosition.Y
        if top < current then palette.List.CanvasPosition = Vector2.new(0, top)
        elseif bottom > current + palette.List.AbsoluteWindowSize.Y then
            palette.List.CanvasPosition = Vector2.new(0, bottom - palette.List.AbsoluteWindowSize.Y)
        end
    end
end

function Window:Command(options)
    assert(not self.Destroyed, "Window is destroyed")
    assert(type(options) == "table", "Command options must be a table")
    for key in pairs(options) do assert(command_option_keys[key], "Unknown Command option: " .. tostring(key)) end
    local id = command_text(options.Id, "Id", 64, true)
    assert(id:match("^[%w_-]+$"), "Command.Id must use letters, digits, underscores or hyphens")
    local title = command_text(options.Title, "Title", 80, true)
    local description = command_text(options.Description, "Description", 160, false)
    local keywords = command_keywords(options.Keywords)
    assert(options.Icon == nil or Library:GetIconName(options.Icon) ~= nil, "Unknown command Icon")
    assert(type(options.Callback) == "function", "Command.Callback must be a function")
    assert(self._commands == nil or self._commands[id] == nil, "Duplicate command ID: " .. id)
    assert(self._commandCount == nil or self._commandCount < command_limit, "A window supports at most 256 commands")

    if not self._commands then self._commands = {};self._commandOrder = {};self._commandCount = 0 end
    local command = {Window = self, Id = id, Title = title, Description = description, Keywords = keywords, Icon = options.Icon, Callback = options.Callback, Destroyed = false, _connections = {}}
    function command:Remove()
        if self.Destroyed then return false end
        return self.Window:RemoveCommand(self.Id)
    end
    self._commands[id] = command
    self._commandOrder[#self._commandOrder + 1] = command
    self._commandCount += 1
    command_order += 1
    self._commandWindowOrder = command_order
    command_mark_active(self)
    if self._commandPalette then command_render(self, self._commandPalette) end

    if not self._commandHotkey then
        self._commandHotkey = self:_Connect(UIS.InputBegan, function(input, processed)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                command_find_window_at(Vector2.new(input.Position.X, input.Position.Y))
            end
            if processed or self.Destroyed or self.Closed or not self.Root.Visible or self._modal then return end
            if command_active_window ~= self then return end
            if UIS:GetFocusedTextBox() then return end
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.K
                and (UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl)) then
                self:OpenCommands()
            end
        end)
    end
    return command
end

function Window:RemoveCommand(id)
    assert(not self.Destroyed, "Window is destroyed")
    assert(type(id) == "string", "Command ID must be a string")
    local command = self._commands and self._commands[id]
    if not command then return false end
    self._commands[id] = nil
    self._commandCount -= 1
    if self._commandCount == 0 and command_active_window == self then command_reselect_active(self) end
    command.Destroyed = true
    disconnect(command._connections, command)
    command.Callback = nil
    for index, entry in ipairs(self._commandOrder) do
        if entry == command then table.remove(self._commandOrder, index);break end
    end
    if self._commandPalette then command_render(self, self._commandPalette) end
    return true
end

function Window:OpenCommands()
    assert(not self.Destroyed, "Window is destroyed")
    if self.Closed or not self.Root.Visible or self._modal then return false end
    command_mark_active(self)
    if self._commandPalette then
        self._commandPalette.Search:CaptureFocus()
        return true
    end
    local palette = {Destroyed = false, _connections = {}, Rows = {}, RowOwners = {}, Matches = {}, Selected = 0}
    self._commandPalette = palette
    local root = create("Frame", {Name = "CommandPalette", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 30}, self.Canvas)
    palette.Root = root
    local shade = create("TextButton", {Name = "Backdrop", Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = .42, Size = UDim2.fromScale(1, 1), ZIndex = 30}, root)
    palette.Shade = shade
    local dialog = create("Frame", {Name = "Dialog", AnchorPoint = Vector2.new(.5, .5), BackgroundTransparency = .04, ZIndex = 31}, root)
    palette.Dialog = dialog
    self:_Rounded(dialog, "WindowRadius");self:_Color(dialog, "BackgroundColor3", "Surface");self:_Stroke(dialog, "Border", .28);padding(dialog, 14)
    local search = create("TextBox", {Name = "Search", Text = "", PlaceholderText = "Search commands...", ClearTextOnFocus = false, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 44), ZIndex = 32}, dialog)
    palette.Search = search
    self:_Rounded(search, "ControlRadius");padding(search, 12);self:_Color(search, "BackgroundColor3", "Raised");self:_Color(search, "TextColor3", "Text");self:_Color(search, "PlaceholderColor3", "Muted");self:_Stroke(search, "Border", .48)
    local list = create("ScrollingFrame", {Name = "Results", Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 1, -56), BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(), ScrollBarThickness = 3, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 32}, dialog)
    palette.List = list
    local empty = self:_Label(dialog, "No commands found", 13, "Muted")
    empty.Name = "EmptyState";empty.AnchorPoint = Vector2.new(.5, .5);empty.Position = UDim2.new(.5, 0, .5, 14);empty.Size = UDim2.new(1, -24, 0, 44);empty.TextXAlignment = Enum.TextXAlignment.Center;empty.ZIndex = 33
    palette.Empty = empty
    command_palette_bounds(self, palette)
    command_render(self, palette)
    self:_Connect(shade.Activated, function() self:CloseCommands() end, palette)
    self:_Connect(search:GetPropertyChangedSignal("Text"), function() command_render(self, palette) end, palette)
    self:_Connect(search.FocusLost, function(enterPressed)
        if not enterPressed or palette.Destroyed or self._commandPalette ~= palette then return end
        local command = palette.Matches[palette.Selected]
        if command then command_activate(self, command, palette) end
    end, palette)
    self:_Connect(self.Canvas:GetPropertyChangedSignal("AbsoluteSize"), function() command_palette_bounds(self, palette) end, palette)
    palette.HandleKey = function(input)
        if palette.Destroyed or self._commandPalette ~= palette then return end
        if input.KeyCode == Enum.KeyCode.Escape then self:CloseCommands();return end
        if UIS:GetFocusedTextBox() ~= search then return end
        if input.KeyCode == Enum.KeyCode.Up then command_move_selection(self, palette, -1)
        elseif input.KeyCode == Enum.KeyCode.Down then command_move_selection(self, palette, 1)
        elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
            local command = palette.Matches[palette.Selected]
            if command then command_activate(self, command, palette) end
        end
    end
    self:_Connect(UIS.InputBegan, palette.HandleKey, palette)
    search:CaptureFocus()
    return true
end

function Window:CloseCommands()
    return command_close_palette(self)
end

local command_original_hide = Window.Hide
Window.Hide = function(self, ...)
    self:CloseCommands()
    local result = command_original_hide(self, ...)
    if command_active_window == self then command_reselect_active(self) end
    return result
end
local command_original_select_tab = Window.SelectTab
Window.SelectTab = function(self, ...)
    local selected = command_original_select_tab(self, ...)
    self:CloseCommands()
    return selected
end
local command_original_destroy = Window.Destroy
Window.Destroy = function(self, ...)
    self:CloseCommands()
    if command_active_window == self then command_reselect_active(self) end
    if self._commandOrder then
        for _, command in ipairs(self._commandOrder) do
            command.Destroyed = true
            disconnect(command._connections, command)
            command.Callback = nil
            command.Window = nil
        end
        table.clear(self._commands)
        table.clear(self._commandOrder)
        self._commandCount = 0
    end
    return command_original_destroy(self, ...)
end
