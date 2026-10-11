-- Client loader with engine-first HTTP and executor HTTP fallbacks.
-- Pin `version` to a reviewed release tag when reproducible updates are required.
local owner = "Gabibou455"
local repository = "GabibouUI"
local version = "main"
assert(owner:match("^[%w-]+$"), "Set owner to a valid GitHub username before loading Gabibou UI")

local function global_value(name)
    local direct_ok, direct_value = pcall(function()
        if name == "loadstring" then return loadstring end
        if name == "request" then return request end
        if name == "http_request" then return http_request end
        if name == "syn" then return syn end
        return nil
    end)
    if direct_ok and direct_value ~= nil then return direct_value end
    local ok, value = pcall(function() return _G[name] end)
    if ok and value ~= nil then return value end
    local getter_ok, getter = pcall(function() return getgenv end)
    if not getter_ok or type(getter) ~= "function" then return nil end
    local env_ok, environment = pcall(getter)
    if not env_ok or type(environment) ~= "table" then return nil end
    local value_ok, environment_value = pcall(function() return environment[name] end)
    if value_ok then return environment_value end
    return nil
end

local compile = global_value("loadstring")
assert(type(compile) == "function", "This environment does not expose loadstring; use ModuleScript + require in Studio")
local url = "https://raw.githubusercontent.com/" .. owner .. "/" .. repository .. "/" .. version .. "/gabibou_ui.luau"
local source
local http_get_ok, http_get_result = pcall(function() return game:HttpGet(url) end)
if http_get_ok and type(http_get_result) == "string" and #http_get_result > 0 then
    source = http_get_result
end

if not source then
    local request_functions = {}
    local seen = {}
    local function add_request(candidate)
        if type(candidate) == "function" and not seen[candidate] then
            seen[candidate] = true
            request_functions[#request_functions + 1] = candidate
        end
    end
    add_request(global_value("request"))
    add_request(global_value("http_request"))
    local syn = global_value("syn")
    if type(syn) == "table" then
        local syn_ok, syn_request = pcall(function() return syn.request end)
        if syn_ok then add_request(syn_request) end
    end

    for _, request_function in ipairs(request_functions) do
        local request_ok, response = pcall(request_function, {Url = url, Method = "GET"})
        if request_ok and type(response) == "table" then
            local fields_ok, status, body = pcall(function()
                local code = response.StatusCode
                if code == nil then code = response.Status end
                return code, response.Body
            end)
            if fields_ok and type(status) == "number" and status == math.floor(status) and status >= 200 and status < 300
                and type(body) == "string" and #body > 0 then
                source = body
                break
            end
        end
    end
end

assert(source, "Gabibou UI download failed; game:HttpGet did not return source and no request fallback returned a nonempty 2xx response: " .. url)
local chunk, problem = compile(source, "GabibouUI@" .. version)
assert(chunk, "Gabibou UI compile failed: " .. tostring(problem))
local UI = chunk()
assert(type(UI) == "table" and type(UI.CreateWindow) == "function", "The downloaded file is not the Gabibou UI library")

local window = UI:CreateWindow("My project", {Id = "RemoteExample"})
local settings = window:Tab("Settings", "settings")
settings:Toggle("Effects", {Id = "effects", Value = true}, function(enabled)
    print("Effects", enabled)
end)
