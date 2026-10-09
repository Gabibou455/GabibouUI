-- Launch orchestration. Inject after convenience.luau in ui.luau's shared scope.
Library.Launches = Library.Launches or {}

local LaunchSession = {}
LaunchSession.__index = LaunchSession

local function launch_callback(callback, ...)
    if type(callback) ~= "function" then return true end
    return pcall(callback, ...)
end

local function launch_destroy(resource)
    if resource and type(resource.Destroy) == "function" then
        pcall(function() resource:Destroy() end)
    end
end

local function launch_stop_thread(session)
    local thread = session._thread
    session._thread = nil
    if thread and thread ~= coroutine.running() then pcall(task.cancel, thread) end
end

local function launch_cleanup(session)
    launch_stop_thread(session)
    launch_destroy(session.Gate)
    launch_destroy(session.Loader)
    launch_destroy(session.Window)
    session.Gate = nil
    session.Loader = nil
    session.Window = nil
    Library.Launches[session] = nil
end

local function launch_call_error(session, message)
    if session._errorCalled then return end
    session._errorCalled = true
    local ok = launch_callback(session._OnError, message, session)
    if not ok then session.LastError = "OnError callback failed" end
end

local function launch_fail(session)
    if session.Status == "Destroyed" or session.Status == "Failed" then return end
    session.Status = "Failed"
    session.LastError = "Launch failed"
    launch_cleanup(session)
    launch_call_error(session, "Launch failed")
end

local function launch_cancel(session, notify)
    if session.Status == "Failed" then return false end
    if session.Status ~= "Destroyed" then
        session.Status = "Destroyed"
        launch_cleanup(session)
    end
    if notify and not session._cancelCalled then
        session._cancelCalled = true
        local ok = launch_callback(session._OnCancel, session)
        if not ok then session.LastError = "OnCancel callback failed" end
    end
    return true
end

function LaunchSession:Cancel()
    if self.Status == "Destroyed" or self.Status == "Failed" then return false end
    if self.Status == "WaitingForKey" and self.Gate and self._keyCancelCallback and not self._keyCancelCalled then
        self._keyCancelCalled = true
        local ok = launch_callback(self._keyCancelCallback, self.Gate, self)
        if not ok then self.LastError = "Key system callback failed" end
    end
    return launch_cancel(self, true)
end

function LaunchSession:Destroy()
    return launch_cancel(self, false)
end

local function validate_launch_steps(steps)
    assert(steps == nil or type(steps) == "table", "spec.Steps: expected a dense array")
    steps = steps or {}
    local count, maximum = 0, 0
    for key in pairs(steps) do
        assert(type(key) == "number" and key % 1 == 0 and key >= 1, "spec.Steps: expected a dense array")
        count += 1
        maximum = math.max(maximum, key)
    end
    assert(count == maximum, "spec.Steps: array must be dense without holes")
    for index, step in ipairs(steps) do
        assert(type(step) == "table", "spec.Steps[" .. index .. "]: expected a step table")
        assert(type(step.Title) == "string" and step.Title ~= "", "spec.Steps[" .. index .. "].Title: expected a nonempty string")
        assert(type(step.Run) == "function", "spec.Steps[" .. index .. "].Run: expected a function")
    end
    return steps
end

local function validate_launch_spec(spec)
    assert(type(spec) == "table", "spec: expected a table")
    assert(type(validate_create_spec) == "function", "Library:Launch must be included after convenience.luau")
    validate_create_spec(spec)
    local steps = validate_launch_steps(spec.Steps)
    assert(spec.OnReady == nil or type(spec.OnReady) == "function", "spec.OnReady: expected a function")
    assert(spec.OnError == nil or type(spec.OnError) == "function", "spec.OnError: expected a function")
    assert(spec.OnCancel == nil or type(spec.OnCancel) == "function", "spec.OnCancel: expected a function")
    assert(spec.KeySystem == nil or type(spec.KeySystem) == "table", "spec.KeySystem: expected a table")
    if spec.KeySystem then
        assert(type(spec.KeySystem.Validate) == "function", "spec.KeySystem.Validate: required callback")
        assert(spec.KeySystem.OnSuccess == nil or type(spec.KeySystem.OnSuccess) == "function", "spec.KeySystem.OnSuccess: expected a function")
        assert(spec.KeySystem.OnCancel == nil or type(spec.KeySystem.OnCancel) == "function", "spec.KeySystem.OnCancel: expected a function")
    end
    local useLoader = spec.Loading ~= nil or #steps > 0
    assert(not useLoader or type(Library.CreateLoader) == "function", "Library.CreateLoader: loading support is not installed")
    assert(spec.KeySystem == nil or type(Library.CreateKeySystem) == "function", "Library.CreateKeySystem: key support is not installed")
    assert(type(Library.Create) == "function", "Library.Create: convenience support is not installed")
    return steps, useLoader
end

local function launch_loader_options(spec)
    local config = type(spec.Loading) == "table" and table.clone(spec.Loading) or {}
    if config.Parent == nil then config.Parent = spec.Parent end
    for _, key in ipairs({"Theme", "Style", "ReducedMotion"}) do
        if config[key] == nil then config[key] = spec[key] end
    end
    if config.Title == nil then config.Title = spec.Title end
    if config.DisplayOrder == nil then config.DisplayOrder = (spec.DisplayOrder or 90) + 1 end
    return config
end

local function window_spec(spec)
    local result = table.clone(spec)
    for _, key in ipairs({"KeySystem", "Loading", "Steps", "OnReady", "OnError", "OnCancel"}) do
        result[key] = nil
    end
    result.Loading = nil
    return result
end

local function launch_window_destroyed(session)
    if session.Status=="Loading" or session.Status=="Ready"then
        session.Status="Destroyed"
        launch_cleanup(session)
    end
end

local function launch_run(session, spec, steps, useLoader)
    if session.Status == "Destroyed" then return end
    session.Status = "Loading"
    local ok = pcall(function()
        if useLoader then
            session.Loader = Library:CreateLoader(launch_loader_options(spec))
        end
        for index, step in ipairs(steps) do
            if session.Status ~= "Loading" then return end
            local loader = session.Loader
            if loader then loader:SetStatus(step.Title) end
            step.Run(loader)
            if session.Status ~= "Loading" then return end
            if loader then
                loader:SetProgress(index / (#steps+1), step.Title)
            end
        end
        if session.Status ~= "Loading" then return end
        session.Window = create_interface(Library,window_spec(spec),function(window)
            session.Window=window
            window:OnDestroy(function()launch_window_destroyed(session)end)
        end)
        if session.Status ~= "Loading" then
            launch_destroy(session.Window)
            session.Window = nil
            return
        end
        if session.Loader then session.Loader:Complete("Ready") end
        session.Status = "Ready"
        local callbackOk = launch_callback(session._OnReady, session.Window, session)
        if not callbackOk then
            session.LastError = "OnReady callback failed"
            launch_call_error(session, "Launch callback failed")
        end
    end)
    if not ok and session.Status == "Loading" then launch_fail(session) end
    if session.Status == "Loading" then session.Status = "Ready" end
    if session._thread == coroutine.running() then session._thread = nil end
end

local function launch_start(session, spec, steps, useLoader)
    session.Status = "Loading"
    local thread
    thread = task.defer(function()
        if session.Status == "Loading" then launch_run(session, spec, steps, useLoader) end
    end)
    session._thread = thread
end

function Library:Launch(spec)
    local steps, useLoader = validate_launch_spec(spec)
    local session = setmetatable({
        Status = spec.KeySystem and "WaitingForKey" or "Loading",
        Gate = nil,
        Loader = nil,
        Window = nil,
        LastError = nil,
        _thread = nil,
        _OnReady = spec.OnReady,
        _OnError = spec.OnError,
        _OnCancel = spec.OnCancel,
        _errorCalled = false,
        _cancelCalled = false,
        _keyCancelCallback = spec.KeySystem and spec.KeySystem.OnCancel or nil,
        _keyCancelCalled = false,
    }, LaunchSession)
    self.Launches[session] = true

    if spec.KeySystem then
        local keyOptions = table.clone(spec.KeySystem)
        keyOptions.OnSuccess = function(gate, result)
            if session.Status ~= "WaitingForKey" then return end
            if not session._keySuccessCalled then
                session._keySuccessCalled = true
                launch_destroy(gate)
                session.Gate = nil
                local callbackOk = launch_callback(spec.KeySystem.OnSuccess, gate, result)
                if not callbackOk then session.LastError = "Key system callback failed" end
                if session.Status == "WaitingForKey" then launch_start(session, spec, steps, useLoader) end
            end
        end
        keyOptions.OnCancel = function(gate)
            if session.Status ~= "WaitingForKey" then return end
            if not session._keyCancelCalled then
                session._keyCancelCalled = true
                local callbackOk = launch_callback(spec.KeySystem.OnCancel, gate, session)
                if not callbackOk then session.LastError = "Key system callback failed" end
            end
            launch_cancel(session, true)
        end
        for _, key in ipairs({"Parent", "Theme", "Style"}) do
            if keyOptions[key] == nil then keyOptions[key] = spec[key] end
        end
        if keyOptions.DisplayOrder == nil then keyOptions.DisplayOrder = (spec.DisplayOrder or 90) + 2 end
        local ok, gate = pcall(function() return self:CreateKeySystem(keyOptions) end)
        if not ok then launch_fail(session)
        elseif session.Status == "WaitingForKey" then session.Gate = gate
        else launch_destroy(gate) end
    else
        launch_start(session, spec, steps, useLoader)
    end
    return session
end
