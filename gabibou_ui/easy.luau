-- Short constructors share the same controls, validation and lifecycle as the table API.
local function easy_options(title, supplied, callback, acceptsCallback)
    if type(supplied)=="function" then
        assert(acceptsCallback and callback==nil,"Pass one callback or an options table")
        callback=supplied;supplied=nil
    end
    assert(supplied==nil or type(supplied)=="table","Options after a title must be a table")
    assert(callback==nil or acceptsCallback and type(callback)=="function","Callback must be a function")
    local options=table.clone(supplied or {})
    options.Title=title
    if callback~=nil then options.Callback=callback end
    if acceptsCallback then
        assert(options.Callback==nil or type(options.Callback)=="function","Callback must be a function")
    end
    return options
end

local function easy_constructor(target,name,acceptsCallback)
    local original=target[name]
    target[name]=function(self,options,supplied,callback)
        if type(options)=="string" then
            options=easy_options(options,supplied,callback,acceptsCallback)
        end
        return original(self,options)
    end
end

easy_constructor(Library,"CreateWindow",false)
easy_constructor(Container,"Section",false)
for _,name in ipairs({"Button","Toggle","Slider","Input","Dropdown","Keybind","ColorPicker"})do
    easy_constructor(Container,name,true)
end
easy_constructor(Container,"Paragraph",false)

local easy_original_tab=Window.Tab
local function easy_tab(self,options,iconOrOptions)
    if type(options)=="string"then
        local supplied=iconOrOptions
        if type(supplied)=="string" or type(supplied)=="number"then supplied={Icon=supplied}end
        options=easy_options(options,supplied,nil,false)
    end
    return easy_original_tab(self,options)
end
Window.Tab=easy_tab
