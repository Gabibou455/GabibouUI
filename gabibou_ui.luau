-- Gabibou UI v1.5.0-rc.4 | Original Roblox client GUI library
-- No external UI or telemetry. Optional Roblox assets and avatar thumbnails.
local Logic=(function()
-- Pure, engine-independent rules shared by the library and its tests.
local Logic = {}
function Logic.finite(value)
    return type(value)=="number" and value==value and math.abs(value)<math.huge
end
function Logic.number(value,minimum,maximum,step)
    assert(Logic.finite(value),"Value must be a finite number")
    assert(Logic.finite(minimum) and Logic.finite(maximum) and maximum>minimum,"Invalid slider range")
    assert(Logic.finite(step) and step>0,"Slider step must be positive")
    assert(Logic.finite(maximum-minimum) and Logic.finite((maximum-minimum)/step),"Slider range or step exceeds numeric precision")
    local bounded=math.clamp(value,minimum,maximum)
    local snapped=minimum+math.floor((bounded-minimum)/step+0.5)*step
    assert(Logic.finite(snapped),"Slider snap exceeds numeric range")
    return math.clamp(snapped,minimum,maximum)
end
function Logic.query(text)
    return string.lower(tostring(text or "")):match("^%s*(.-)%s*$")
end
function Logic.matches(text,query)
    for word in Logic.query(query):gmatch("%S+") do
        if not string.find(string.lower(text),word,1,true) then return false end
    end
    return true
end
function Logic.option(value,options)
    assert(type(value)=="string","Dropdown value must be a string")
    for _,option in ipairs(options) do if option==value then return value end end
    error("Unknown dropdown option: "..value)
end
function Logic.options(options)
    assert(type(options)=="table" and #options>0,"Dropdown needs at least one option")
    local seen={};local copy={}
    for _,option in ipairs(options) do
        assert(type(option)=="string" and option~="" and not seen[option],"Options must be unique, nonempty strings")
        seen[option]=true;copy[#copy+1]=option
    end
    return copy
end
function Logic.text(value,maximum)
    assert(type(value)=="string","Input value must be a string")
    assert(utf8.len(value)~=nil,"Input must contain valid UTF-8")
    if utf8.len(value)>maximum then return string.sub(value,1,(utf8.offset(value,maximum+1) or (#value+1))-1) end
    return value
end
function Logic.hex(value)
    assert(type(value)=="string","Color must be a six-digit hexadecimal string")
    local hex=value:match("^%s*#?(%x%x%x%x%x%x)%s*$")
    assert(hex,"Color must use #RRGGBB format")
    return "#"..string.upper(hex)
end
function Logic.profile(document,controls)
    assert(type(document)=="table" and document.version==1 and type(document.values)=="table","Invalid Gabibou UI profile")
    local staged={}
    for id,entry in pairs(document.values) do
        assert(type(id)=="string" and type(entry)=="table","Invalid profile entry")
        local control=controls[id]
        if control and control.Persistent then
            assert(entry.kind==control.Kind,"Profile type mismatch: "..id)
            staged[#staged+1]={control=control,value=control:_Validate(entry.value)}
        end
    end
    table.sort(staged,function(a,b)return a.control.Id<b.control.Id end)
    return staged
end
return Logic

end)()
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local TweenService=game:GetService("TweenService")
local HttpService=game:GetService("HttpService")
local GuiService=game:GetService("GuiService")
local TextService=game:GetService("TextService")
local Library={Version="1.5.0-rc.4",Windows={}}
local style_for,motion_for,branding_for,layout_for,control_layout_for,tab_layout_for,notification_for,navigation_for
Library.Themes={
    Graphite={Background=Color3.fromRGB(15,15,17),Surface=Color3.fromRGB(26,26,30),Raised=Color3.fromRGB(38,38,43),Hover=Color3.fromRGB(50,50,56),Border=Color3.fromRGB(67,67,74),Text=Color3.fromRGB(245,245,248),Muted=Color3.fromRGB(158,158,169),Accent=Color3.fromRGB(242,242,247),AccentText=Color3.fromRGB(20,20,23),Success=Color3.fromRGB(170,208,181),Danger=Color3.fromRGB(240,139,139)},
    Aurora={Background=Color3.fromRGB(13,14,23),Surface=Color3.fromRGB(22,24,38),Raised=Color3.fromRGB(32,35,53),Hover=Color3.fromRGB(43,47,69),Border=Color3.fromRGB(62,67,91),Text=Color3.fromRGB(243,244,255),Muted=Color3.fromRGB(158,163,190),Accent=Color3.fromRGB(161,143,255),AccentText=Color3.fromRGB(18,15,30),Success=Color3.fromRGB(119,221,181),Danger=Color3.fromRGB(247,142,164)},
    Ember={Background=Color3.fromRGB(21,15,15),Surface=Color3.fromRGB(32,24,24),Raised=Color3.fromRGB(45,32,30),Hover=Color3.fromRGB(58,40,36),Border=Color3.fromRGB(82,59,52),Text=Color3.fromRGB(255,244,237),Muted=Color3.fromRGB(190,165,155),Accent=Color3.fromRGB(255,166,113),AccentText=Color3.fromRGB(33,20,14),Success=Color3.fromRGB(169,208,158),Danger=Color3.fromRGB(255,128,128)}
}
local Window={};Window.__index=Window
local Container={};Container.__index=Container
local Control={};Control.__index=Control
local font=Enum.Font.Gotham
local bold=Enum.Font.GothamBold
local function create(class,properties,parent)
    local instance=Instance.new(class)
    for key,value in pairs(properties or {}) do instance[key]=value end
    if instance:IsA("GuiObject") then instance.AutoLocalize=false;instance.BorderSizePixel=0 end
    instance.Parent=parent
    return instance
end
local function corner(instance,radius)create("UICorner",{CornerRadius=UDim.new(0,radius or 10)},instance)end
local function padding(instance,value)
    create("UIPadding",{PaddingLeft=UDim.new(0,value),PaddingRight=UDim.new(0,value),PaddingTop=UDim.new(0,value),PaddingBottom=UDim.new(0,value)},instance)
end
local function list(instance,gap,horizontal)
    return create("UIListLayout",{Padding=UDim.new(0,gap or 10),SortOrder=Enum.SortOrder.LayoutOrder,FillDirection=horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical},instance)
end
local function spawn_owned(owner,callback)
    if owner.Destroyed then return nil end
    local tasks=owner._callbackTasks
    if not tasks then tasks={};owner._callbackTasks=tasks end
    local record={}
    tasks[record]=true
    return task.spawn(function()
        record.Thread=coroutine.running()
        local ok,problem=pcall(callback)
        tasks[record]=nil
        if not ok then error(problem,0)end
    end)
end
local function cancel_callbacks(owner)
    if not owner then return end
    local tasks=owner._callbackTasks
    if tasks then
        for record in pairs(tasks)do
            local thread=record.Thread
            if thread and thread~=coroutine.running() and coroutine.status(thread)~="dead"then
                pcall(task.cancel,thread)
            end
        end
        table.clear(tasks)
    end
    owner._busy=false
end
local function disconnect(connections,owner)
    cancel_callbacks(owner)
    for _,connection in ipairs(connections) do
        local ok,problem=pcall(function()connection:Disconnect()end)
        if not ok then
            local window=owner and (owner.Window or owner)
            if window then window.LastError=tostring(problem)end
            warn("[Gabibou UI] cleanup: "..tostring(problem))
        end
    end
    table.clear(connections)
end
local function release_focus(root)
    local focused=UIS:GetFocusedTextBox()
    if focused and root and focused:IsDescendantOf(root) then focused:ReleaseFocus(false) end
end
local function theme_for(value)
    local theme=table.clone(Library.Themes.Graphite)
    local supplied=type(value)=="string" and Library.Themes[value] or value
    assert(supplied~=nil,"Unknown theme")
    assert(type(supplied)=="table","Theme must be a name or color table")
    for key,color in pairs(supplied) do
        assert(theme[key]~=nil and typeof(color)=="Color3","Invalid theme token: "..tostring(key))
        theme[key]=color
    end
    return theme
end
function Window:_Connect(signal,callback,owner)
    local connection=signal:Connect(function(...)
        if self.Destroyed or (owner and owner.Destroyed) then return end
        callback(...)
    end)
    local bucket=owner and owner._connections or self._connections
    bucket[#bucket+1]=connection
    return connection
end
function Window:_TrackBindingTarget(instance)
    if self._bindingConnections[instance] then return end
    self._bindingConnections[instance]=instance.Destroying:Connect(function()
        self:_ForgetBindingTarget(instance)
    end)
end
function Window:_ForgetBindingTarget(instance)
    self._themeTargets[instance]=nil;self._styleTargets[instance]=nil
    local connection=self._bindingConnections[instance]
    self._bindingConnections[instance]=nil
    if connection then connection:Disconnect()end
    self:_CancelAnimation(instance)
end
function Window:_Color(instance,property,token)
    self:_TrackBindingTarget(instance)
    local properties=self._themeTargets[instance] or {}
    properties[property]=token;self._themeTargets[instance]=properties
    instance[property]=self.Theme[token]
    if property=="BackgroundColor3"then
        local highlight=instance:FindFirstChild("SurfaceHighlight")
        if highlight then highlight.Visible=token=="Raised"end
    end
end
function Window:_Stroke(instance,token,transparency)
    local stroke=create("UIStroke",{Thickness=1,Transparency=transparency or 0,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},instance)
    self:_Color(stroke,"Color",token or "Border");return stroke
end
function Window:_Tween(instance,properties)
    if self.Destroyed then return nil end
    return self:Animate(instance,properties)
end
function Window:_Label(parent,text,size,token)
    local label=create("TextLabel",{BackgroundTransparency=1,Text=tostring(text or ""),TextSize=size or 13,Font=font,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y},parent)
    self:_Color(label,"TextColor3",token or "Text");self:_Style(label,"Font","Font");return label
end
function Window:_Button(parent,text,size,owner)
    local button=create("TextButton",{Text=tostring(text),Font=bold,TextSize=13,Size=size or UDim2.fromOffset(120,36),AutoButtonColor=false,Selectable=true},parent)
    self:_Rounded(button,"ControlRadius");self:_Style(button,"Font","FontBold");self:_Style(button,"TextSize","TextSize");self:_Color(button,"BackgroundColor3","Raised");self:_Color(button,"TextColor3","Text");self:_Stroke(button,"Border",.3)
    local highlight=create("Frame",{Name="SurfaceHighlight",Position=UDim2.new(0,8,0,1),Size=UDim2.new(1,-16,0,1),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=.94,BorderSizePixel=0,Active=false,Selectable=false,ZIndex=button.ZIndex+1},button)
    corner(highlight,1)
    self:_Connect(button:GetPropertyChangedSignal("ZIndex"),function()highlight.ZIndex=button.ZIndex+1 end,owner)
    local function refreshHighlight()
        local bindings=self._themeTargets[button]
        if not bindings or bindings.BackgroundColor3~="Raised"then highlight.Visible=false;return end
        local animation=self._animationRecords[button]
        if animation and animation.Goals.BackgroundColor3~=nil then return end
        highlight.Visible=button.BackgroundColor3==self.Theme.Raised or button.BackgroundColor3==self.Theme.Hover
    end
    self:_Connect(button:GetPropertyChangedSignal("BackgroundColor3"),refreshHighlight,owner)
    local function color(hover)
        local tokens=self._themeTargets[button]
        local base=tokens and tokens.BackgroundColor3 or "Raised"
        if not hover then return self.Theme[base] end
        return base=="Accent" and self.Theme.Accent:Lerp(self.Theme.Background,.08) or self.Theme.Hover
    end
    self:_Connect(button.MouseEnter,function()self:_Tween(button,{BackgroundColor3=color(true)})end,owner)
    self:_Connect(button.MouseLeave,function()self:_Tween(button,{BackgroundColor3=color(false)})end,owner)
    self:_Connect(button.SelectionGained,function()self:_Tween(button,{BackgroundColor3=color(true)})end,owner)
    self:_Connect(button.SelectionLost,function()self:_Tween(button,{BackgroundColor3=color(false)})end,owner)
    return button
end
function Window:_Callback(control,...)
    if self.Destroyed or control.Destroyed or not control.Enabled or control._busy or type(control.Callback)~="function" then return end
    if control.Kind=="Button" then control._busy=true end
    local arguments=table.pack(...)
    spawn_owned(control,function()
        if self.Destroyed or control.Destroyed or not control.Enabled then control._busy=false;return end
        local ok,err=pcall(control.Callback,table.unpack(arguments,1,arguments.n))
        control._busy=false
        if not ok and not self.Destroyed and not control.Destroyed then
            self.LastError=tostring(err)
            warn("[Gabibou UI] "..control.Id..": "..tostring(err))
            self:Notify({Title="Callback failed",Content=tostring(err),Kind="error",Duration=6})
        end
    end)
end
function Window:_Chevron(button)
    local arrow=create("Frame",{BackgroundTransparency=1,Size=UDim2.fromOffset(12,8),Position=UDim2.new(1,-16,.5,0),AnchorPoint=Vector2.new(.5,.5)},button)
    for index,rotation in ipairs({45,-45})do
        local line=create("Frame",{Size=UDim2.fromOffset(8,2),Position=UDim2.fromOffset((index-1)*5,3),Rotation=rotation,BorderSizePixel=0},arrow)
        self:_Color(line,"BackgroundColor3","Muted")
    end
    return arrow
end
function Window:SetTheme(value)
    assert(not self.Destroyed,"Window is destroyed")
    self.Theme=theme_for(value);self.ThemeName=type(value)=="string" and value or "Custom"
    for instance,properties in pairs(self._themeTargets) do
        self:_CancelForProperties(instance,properties)
        for property,token in pairs(properties) do instance[property]=self.Theme[token] end
    end
    for _,control in pairs(self.Controls) do if control._Render then control:_Render() end end
    self:_RefreshNavigation(true)
    self:_Emit(self,"ThemeChanged",self.ThemeName,table.clone(self.Theme))
    return self
end
function Window:SetReducedMotion(value)
    assert(not self.Destroyed,"Window is destroyed")
    assert(type(value)=="boolean","Reduced motion must be boolean")
    local changed=self.ReducedMotion~=value
    self.ReducedMotion=value
    if value then
        for instance,record in pairs(table.clone(self._animationRecords))do
            self:_CancelAnimation(instance)
            if instance.Parent then for property,goal in pairs(record.Goals)do instance[property]=goal end end
        end
    end
    if changed then self:_Emit(self,"ReducedMotionChanged",value)end
    return self
end
function Window:_Viewport()
    local size
    if self.Canvas and self.Canvas.AbsoluteSize.X>0 and self.Canvas.AbsoluteSize.Y>0 then size=self.Canvas.AbsoluteSize
    else
    local camera=workspace.CurrentCamera
    size=camera and camera.ViewportSize or Vector2.new(1280,720)
    local top,bottom=GuiService:GetGuiInset()
    size=size-top-bottom
    end
    if UIS.OnScreenKeyboardVisible and UIS.OnScreenKeyboardPosition.Y>0 then
        local origin=self.Canvas and self.Canvas.AbsolutePosition.Y or 0
        size=Vector2.new(size.X,math.max(1,math.min(size.Y,UIS.OnScreenKeyboardPosition.Y-origin)))
    end
    return size
end
function Window:_Layout()
    if self.Destroyed then return end
    local previousHorizontalTabs=self.HorizontalTabs
    local viewport=self:_Viewport()
    local margin=self.Responsive.Margin
    local width=math.max(1,math.min(self._desiredSize.X,viewport.X-margin*2))
    local height=math.max(1,math.min(self._desiredSize.Y,viewport.Y-margin*2))
    local mobile=width<self.Responsive.Breakpoint
    local compact=height<420
    local tiny=height<260
    local minimal=height<140
    self.Mobile=mobile
    self.Panel.Size=UDim2.fromOffset(width,height)
    self._size=Vector2.new(width,height)
    local position=self._position
    if self._positionSpec then
        local p,a=self._positionSpec,self._anchorPoint
        position=Vector2.new(viewport.X*p.X.Scale+p.X.Offset-width*a.X,viewport.Y*p.Y.Scale+p.Y.Offset-height*a.Y)
    end
    local x=math.clamp(position.X,0,math.max(0,viewport.X-width))
    local y=math.clamp(position.Y,0,math.max(0,viewport.Y-height))
    self._position=Vector2.new(x,y);self.Root.Position=UDim2.fromOffset(x,y);self.Root.Size=self.Panel.Size
    self:_Arrange(width,height,mobile,compact,tiny,minimal)
    self._headerWash.Visible=self.Layout.ShowHeader and not minimal
    if self._headerDivider then self._headerDivider.Visible=self._headerWash.Visible end
    self._headerWash.Size=UDim2.new(1,0,0,math.min(height,self.Layout.HeaderHeight+16))
    self._subtitle.Visible=not compact
    self.Footer.Text=mobile and "Gabibou UI  "..Library.Version or "Gabibou UI  "..Library.Version.."     ·     "..self.ToggleKey.Name.." to hide"
    self._resize.Visible=not mobile and not tiny and self.Layout.Resizable
    self:_LayoutNavigation(self.HorizontalTabs)
    if previousHorizontalTabs~=self.HorizontalTabs then self:_EnsureTabVisible(self.CurrentTab)end
    self:_LayoutBranding(width,height,minimal,tiny)
    for _,control in pairs(self.Controls) do control:_Layout(mobile) end
    self.ToastHost.Size=UDim2.new(0,math.min(300,math.max(1,viewport.X-36)),1,-36)
    self:_LayoutNotifications()
    self:_ApplyPartLayouts()
    self:_CloseDropdown()
    task.defer(function()
        if self.Destroyed then return end
        local focused=UIS:GetFocusedTextBox()
        if not focused then return end
        for _,control in pairs(self.Controls) do
            if (control._input==focused or control._colorInput==focused) and control.Root.Visible and control.Tab.Page.Visible then
                local page=control.Tab.Page
                local offset=focused.AbsolutePosition.Y-page.AbsolutePosition.Y+page.CanvasPosition.Y
                local maximum=math.max(0,page.AbsoluteCanvasSize.Y-page.AbsoluteSize.Y)
                local position=page.CanvasPosition.Y
                if offset<position then position=offset-12
                elseif offset+focused.AbsoluteSize.Y>position+page.AbsoluteSize.Y then position=offset+focused.AbsoluteSize.Y-page.AbsoluteSize.Y+12 end
                page.CanvasPosition=Vector2.new(0,math.clamp(position,0,maximum));break
            end
        end
    end)
end
function Window:_WatchCamera()
    if self._cameraConnection then self._cameraConnection:Disconnect();self._cameraConnection=nil end
    local camera=workspace.CurrentCamera
    if camera then self._cameraConnection=camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()self:_Layout()end) end
    self:_Layout()
end
function Window:_CloseDropdown()
    if self._dropdown then self:_ForgetTree(self._dropdown);self._dropdown:Destroy();self._dropdown=nil end
    self._dropdownControl=nil
end
function Window:_CancelInteraction(root)
    local function belongs(control)return control and (not root or control.Root==root or control.Root:IsDescendantOf(root))end
    if belongs(self._capture)then
        local target=self._capture;self._capture=nil
        if not target.Destroyed then target:_Render()end
    end
    if belongs(self._dropdownControl)then self:_CloseDropdown()end
    if self._gesture and (not root or belongs(self._gesture.control))then self._gesture=nil end
    release_focus(root or self.Root)
end
function Window:_ForgetTree(root)
    local function forget(instance)
        self:_ForgetBindingTarget(instance)
    end
    forget(root);for _,instance in ipairs(root:GetDescendants())do forget(instance)end
end
function Window:_EnsureTabVisible(tab)
    self._ensureTabVisibleGeneration=(self._ensureTabVisibleGeneration or 0)+1
    local generation=self._ensureTabVisibleGeneration
    if not tab or self.Destroyed then return end
    task.defer(function()
        task.defer(function()
            if self.Destroyed or generation~=self._ensureTabVisibleGeneration or self.CurrentTab~=tab or tab.Destroyed or not tab._button.Parent then return end
            local horizontal=self.HorizontalTabs==true
            local offset=horizontal and(tab._button.AbsolutePosition.X-self.Nav.AbsolutePosition.X+self.Nav.CanvasPosition.X)or(tab._button.AbsolutePosition.Y-self.Nav.AbsolutePosition.Y+self.Nav.CanvasPosition.Y)
            local current=horizontal and self.Nav.CanvasPosition.X or self.Nav.CanvasPosition.Y
            local extent=horizontal and tab._button.AbsoluteSize.X or tab._button.AbsoluteSize.Y
            local available=horizontal and self.Nav.AbsoluteSize.X or self.Nav.AbsoluteSize.Y
            if offset<current then current=offset
            elseif offset+extent>current+available then current=offset+extent-available end
            local total=horizontal and self.Nav.AbsoluteCanvasSize.X or self.Nav.AbsoluteCanvasSize.Y
            current=math.clamp(current,0,math.max(0,total-available))
            self.Nav.CanvasPosition=horizontal and Vector2.new(current,0)or Vector2.new(0,current)
        end)
    end)
end
function Window:SelectTab(tab)
    assert(not self.Destroyed,"Window is destroyed")
    if type(tab)=="number" then tab=self.Tabs[tab] end
    assert(tab and tab.Window==self and not tab.Destroyed,"Unknown tab")
    if self.CurrentTab and self.CurrentTab~=tab then self:_CancelInteraction(self.CurrentTab.Page) end
    local previous=self.CurrentTab
    self:_CloseDropdown();self.CurrentTab=tab;self.PageTitle.Text=tab.Title
    for _,entry in ipairs(self.Tabs) do
        entry.Page.Visible=entry==tab
    end
    self:_RefreshNavigation(false)
    self:_EnsureTabVisible(tab)
    if previous~=tab then self:_Emit(self,"TabChanged",tab,previous)end
    return tab
end
function Window:SearchFor(query)
    assert(type(query)=="string","Search needs a string")
    self.Query=query
    local first
    for _,tab in ipairs(self.Tabs) do
        local count=0
        for _,control in ipairs(tab._controls) do
            if not control.Destroyed then
                local match=tab._visible and control._visible and control.Container._visible and Logic.matches(control._search.." "..tab.Title,query)
                if not match then self:_CancelInteraction(control.Root)end
                control.Root.Visible=match
                if match then count+=1 end
            end
        end
        for _,section in ipairs(tab._sections) do
            if not section.Destroyed then
                local present=false
                local ordered=table.clone(section._children)
                table.sort(ordered,function(a,b)return a.Root.LayoutOrder<b.Root.LayoutOrder end)
                for _,control in ipairs(ordered) do
                    if not control.Destroyed then
                        if control._separator then control._separator.Visible=control.Root.Visible and present end
                        if control.Root.Visible then present=true end
                    end
                end
                section.Root.Visible=present and section._visible
            end
        end
        tab._empty.Visible=count==0
        tab._button.Visible=tab._visible and (query=="" or count>0)
        if tab._button.Visible and not first then first=tab end
    end
    if self.CurrentTab and not self.CurrentTab._button.Visible and first then self:SelectTab(first) end
    if self.CurrentTab and not self.CurrentTab._visible then self.CurrentTab.Page.Visible=false;self.CurrentTab=nil end
    if not self.CurrentTab and first then self:SelectTab(first)end
    return self
end
function Window:Hide()
    if self.Destroyed then return false end
    self:_CancelInteraction(self.Root)
    local changed=not self.Closed
    self.Closed=true;self:_CloseDropdown();self._gesture=nil
    if self._capture then self._capture:_Render();self._capture=nil end
    if self._modal then self:_ForgetTree(self._modal);self._modal:Destroy() end
    self.Root.Visible=false;self.Reopen.Visible=true
    if changed then self:_Emit(self,"VisibilityChanged",false)end
    return true
end
function Window:Show()
    if self.Destroyed then return false end
    local changed=self.Closed
    self.Closed=false;self.Root.Visible=true;self.Reopen.Visible=false;self:_Layout()
    if changed then self:_Emit(self,"VisibilityChanged",true)end
    return true
end
function Window:Toggle()if self.Closed then return self:Show() else return self:Hide() end end
function Window:SetSize(width,height)
    assert(Logic.finite(width) and Logic.finite(height),"Window size must be finite")
    self._desiredSize=Vector2.new(math.clamp(width,320,1400),math.clamp(height,300,1000));self:_Layout();return self
end
function Window:ExportConfig()
    assert(not self.Destroyed,"Window is destroyed")
    local values={}
    for id,control in pairs(self.Controls) do
        if control.Persistent then values[id]={kind=control.Kind,value=control:Get()} end
    end
    return HttpService:JSONEncode({version=1,theme=self.ThemeName~="Custom" and self.ThemeName or nil,values=values})
end
function Window:ImportConfig(json,fireCallbacks)
    assert(not self.Destroyed,"Window is destroyed")
    assert(type(json)=="string" and #json<=262144,"Profile must be a JSON string smaller than 256 KiB")
    local document=HttpService:JSONDecode(json)
    local staged=Logic.profile(document,self.Controls)
    local theme=document.theme
    if theme~=nil then assert(type(theme)=="string" and Library.Themes[theme],"Invalid profile theme") end
    -- Validate the complete profile before changing a single control.
    if theme then self:SetTheme(theme) end
    for _,change in ipairs(staged) do change.control:Set(change.value,false) end
    if fireCallbacks==true then for _,change in ipairs(staged) do self:_Callback(change.control,change.control:Get()) end end
    return #staged
end
function Window:SaveConfig(name)
    assert(type(name)=="string" and name:match("^[%w_-]+$") and #name<=48,"Profile name uses letters, digits, _ and -")
    assert(self.Storage and type(self.Storage.Write)=="function","Provide Storage.Write(path, contents) to save profiles")
    self.Storage.Write(name..".json",self:ExportConfig());return true
end
function Window:LoadConfig(name,fireCallbacks)
    assert(type(name)=="string" and name:match("^[%w_-]+$") and #name<=48,"Profile name uses letters, digits, _ and -")
    assert(self.Storage and type(self.Storage.Read)=="function","Provide Storage.Read(path) to load profiles")
    return self:ImportConfig(self.Storage.Read(name..".json"),fireCallbacks)
end
function Window:Destroy()
    if self.Destroyed then return true end
    self:_CancelBranding()
    self.Destroyed=true;self._gesture=nil;self._capture=nil
    release_focus(self.Root);self:_DisconnectEvents(self)
    self:_CloseDropdown()
    disconnect(self._connections,self)
    if self._cameraConnection then self._cameraConnection:Disconnect();self._cameraConnection=nil end
    for _,control in pairs(self.Controls) do control.Destroyed=true;disconnect(control._connections,control);self:_DisconnectEvents(control) end
    for _,tab in ipairs(self.Tabs) do tab.Destroyed=true;disconnect(tab._connections,tab);for _,section in ipairs(tab._sections) do section.Destroyed=true end end
    for instance in pairs(table.clone(self._tweens)) do self:_CancelAnimation(instance) end
    for _,connection in pairs(self._bindingConnections)do connection:Disconnect()end
    table.clear(self._bindingConnections)
    table.clear(self.Controls);table.clear(self._themeTargets);table.clear(self._styleTargets)
    for _,toast in ipairs(table.clone(self._notifications)) do toast:Destroy() end
    if not self._guiDestroying then self.Gui:Destroy()end
    if Library.Windows[self.Id]==self then Library.Windows[self.Id]=nil end
    for _,callback in ipairs(self._destroyCallbacks) do local ok,err=pcall(callback);if not ok then warn("[Gabibou UI] teardown: "..tostring(err)) end end
    table.clear(self._destroyCallbacks)
    return true
end
function Window:OnDestroy(callback)
    assert(not self.Destroyed and type(callback)=="function","Expected teardown callback on a live window")
    self._destroyCallbacks[#self._destroyCallbacks+1]=callback;return self
end
function Library:DestroyAll()
    for session in pairs(table.clone(self.Launches or {}))do session:Destroy()end
    for gate in pairs(table.clone(self.KeySystems or {}))do gate:Destroy()end
    local windows={};for _,window in pairs(self.Windows) do windows[#windows+1]=window end
    for _,window in ipairs(windows) do window:Destroy() end
    for loader in pairs(table.clone(self.Loaders or {}))do loader:Destroy()end
end
function Library:CreateWindow(options)
    options=options or {}
    assert(type(options)=="table","Window options must be a table")
    local player=Players.LocalPlayer;assert(player,"Gabibou UI runs on a Roblox client")
    local parent=options.Parent or player:FindFirstChildOfClass("PlayerGui")
    assert(typeof(parent)=="Instance","Pass a GUI parent or wait for PlayerGui")
    local theme=theme_for(options.Theme or "Graphite")
    local style=style_for(options.Style,Library.Style);local motion=motion_for(options.Motion,Library.Motion)
    local branding=options.Branding~=nil and branding_for(options.Branding) or nil
    local layout=layout_for(options.Layout,Library.Layout)
    local notifications=notification_for(options.Notifications,Library.Notifications)
    local navigation=navigation_for(options.Navigation,Library.Navigation)
    local initialPosition,anchor=options.Position,options.AnchorPoint or Vector2.new(.5,.5)
    assert(initialPosition==nil or (typeof(initialPosition)=="UDim2" and Logic.finite(initialPosition.X.Scale) and Logic.finite(initialPosition.X.Offset) and Logic.finite(initialPosition.Y.Scale) and Logic.finite(initialPosition.Y.Offset)),"Position must be a finite UDim2")
    assert(typeof(anchor)=="Vector2" and Logic.finite(anchor.X) and Logic.finite(anchor.Y) and anchor.X>=0 and anchor.X<=1 and anchor.Y>=0 and anchor.Y<=1,"AnchorPoint must be within 0..1")
    local responsive=options.Responsive or {}
    assert(type(responsive)=="table","Responsive options must be a table")
    responsive={Breakpoint=responsive.Breakpoint or 620,TouchTarget=responsive.TouchTarget or 44,Margin=responsive.Margin or 12}
    assert(Logic.finite(responsive.Breakpoint) and responsive.Breakpoint>=320 and responsive.Breakpoint<=1000,"Responsive.Breakpoint must be 320..1000")
    assert(Logic.finite(responsive.TouchTarget) and responsive.TouchTarget>=44 and responsive.TouchTarget<=72,"Responsive.TouchTarget must be 44..72")
    assert(Logic.finite(responsive.Margin) and responsive.Margin>=4 and responsive.Margin<=40,"Responsive.Margin must be 4..40")
    assert(Logic.finite(options.Width or 800) and Logic.finite(options.Height or 590),"Window size must be finite")
    local id=tostring(options.Id or "GabibouUI")
    local key=options.ToggleKey or Enum.KeyCode.RightControl
    assert(typeof(key)=="EnumItem" and key.EnumType==Enum.KeyCode,"ToggleKey must be a KeyCode")
    local reduced=false;pcall(function()reduced=GuiService.ReducedMotionEnabled end)
    if options.ReducedMotion~=nil then assert(type(options.ReducedMotion)=="boolean","ReducedMotion must be boolean");reduced=options.ReducedMotion end
    if self.Windows[id] then self.Windows[id]:Destroy() end
    local self=setmetatable({Id=id,Title=tostring(options.Title or "Gabibou UI"),Theme=theme,ThemeName=type(options.Theme)=="table" and "Custom" or (options.Theme or "Graphite"),Responsive=responsive,ReducedMotion=reduced,ToggleKey=key,Destroyed=false,Closed=false,Tabs={},Controls={},Query="",Storage=options.Storage,_connections={},_destroyCallbacks={},_themeTargets={},_tweens=setmetatable({},{__mode="k"}),_serial=0,_notifications={},_desiredSize=Vector2.new(math.clamp(options.Width or 800,320,1400),math.clamp(options.Height or 590,300,1000))},Window)
    self.Style=style;self.Motion=motion;self.Layout=layout;self.Notifications=notifications;self.Navigation=navigation;self._positionSpec=initialPosition;self._anchorPoint=anchor;self._partLayouts={};self._events={};self._styleTargets={};self._bindingConnections={};self._animationRecords={}
    self.Gui=create("ScreenGui",{Name="GabibouUI_"..id,ResetOnSpawn=false,ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,DisplayOrder=options.DisplayOrder or 90,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},parent)
    self.Canvas=create("Frame",{Name="SafeArea",BackgroundTransparency=1,Size=UDim2.fromScale(1,1)},self.Gui)
    self.Root=create("Frame",{Name="Window",BackgroundTransparency=1},self.Canvas)
    for i=3,1,-1 do
        local shadow=create("Frame",{Name="Depth"..i,Position=UDim2.fromOffset(-i*3,i*4),Size=UDim2.new(1,i*6,1,i*3),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.7+i*.07,BorderSizePixel=0,ZIndex=1},self.Root)
        corner(shadow,19+i*2)
    end
    self.Panel=create("Frame",{Name="Panel",Size=UDim2.fromScale(1,1),BorderSizePixel=0,Active=true,ZIndex=3},self.Root)
    self:_Rounded(self.Panel,"WindowRadius");self:_Color(self.Panel,"BackgroundColor3","Background");self:_Stroke(self.Panel,"Border",.18)
    self._headerWash=create("Frame",{Name="HeaderWash",BackgroundTransparency=.76,Size=UDim2.new(1,0,0,92),ZIndex=3},self.Panel)
    self:_Rounded(self._headerWash,"WindowRadius");self:_Color(self._headerWash,"BackgroundColor3","Raised")
    local cap=create("Frame",{Name="HeaderDivider",Position=UDim2.fromOffset(18,68),Size=UDim2.new(1,-36,0,1),BackgroundTransparency=.55,BorderSizePixel=0,ZIndex=5},self.Panel)
    self._headerDivider=cap;self:_Color(cap,"BackgroundColor3","Border")
    self.Header=create("Frame",{Name="Header",BackgroundTransparency=1,Size=UDim2.new(1,-112,0,60),Position=UDim2.fromOffset(18,9),Active=true},self.Panel)
    local mark=create("TextLabel",{Text="G",Font=bold,TextSize=18,Size=UDim2.fromOffset(38,38),Position=UDim2.fromOffset(0,5)},self.Header)
    self.Mark=mark
    corner(mark,11);self:_Color(mark,"BackgroundColor3","Accent");self:_Color(mark,"TextColor3","AccentText")
    self.TitleLabel=self:_Label(self.Header,self.Title,17,"Text");self.TitleLabel.Font=bold;self.TitleLabel.Position=UDim2.fromOffset(50,5);self.TitleLabel.Size=UDim2.new(1,-54,0,23);self.TitleLabel.AutomaticSize=Enum.AutomaticSize.None;self.TitleLabel.TextTruncate=Enum.TextTruncate.AtEnd;self.TitleLabel.TextWrapped=false
    self:_Style(self.TitleLabel,"Font","FontBold");self:_Style(self.TitleLabel,"TextSize","TitleSize")
    local subtitle=self:_Label(self.Header,options.Subtitle or "Interface settings",12,"Muted");subtitle.Position=UDim2.fromOffset(50,30);subtitle.Size=UDim2.new(1,-54,0,17);subtitle.AutomaticSize=Enum.AutomaticSize.None;subtitle.TextTruncate=Enum.TextTruncate.AtEnd;subtitle.TextWrapped=false;self._subtitle=subtitle
    local hide=self:_Button(self.Panel,"",UDim2.fromOffset(44,44));hide.Name="Minimize";hide.Position=UDim2.new(1,-104,0,16)
    local close=self:_Button(self.Panel,"",UDim2.fromOffset(44,44));close.Name="Close";close.Position=UDim2.new(1,-54,0,16)
    for _,action in ipairs({hide,close})do
        action.BackgroundTransparency=.52
        local outline=action:FindFirstChildOfClass("UIStroke")
        if outline then outline.Transparency=.68 end
    end
    Library:Icon(hide,"minimize",{Size=18,Position=UDim2.fromOffset(13,13),Window=self,Token="Muted"})
    Library:Icon(close,"close",{Size=18,Position=UDim2.fromOffset(13,13),Window=self,Token="Muted"})
    self._windowButtons={hide,close}
    self:_Connect(hide.Activated,function()self:Hide()end)
    self:_Connect(close.Activated,function()self:Confirm({Title="Close this interface?",Content="The window and its connections will be removed.",ConfirmText="Close",Callback=function()self:Destroy()end})end)
    self.Search=create("TextBox",{Name="Search",Text="",PlaceholderText="Search controls...",ClearTextOnFocus=false,Font=font,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},self.Panel)
    self:_Rounded(self.Search,"ControlRadius");self:_Style(self.Search,"Font","Font");self:_Style(self.Search,"TextSize","TextSize");padding(self.Search,12);self.Search:FindFirstChildOfClass("UIPadding").PaddingLeft=UDim.new(0,36);self:_Color(self.Search,"BackgroundColor3","Surface");self:_Color(self.Search,"TextColor3","Text");self:_Color(self.Search,"PlaceholderColor3","Muted");self:_Stroke(self.Search,"Border",.4)
    Library:Icon(self.Search,"search",{Size=16,Position=UDim2.new(0,-25,.5,-8),Window=self,Token="Muted"})
    self:_Connect(self.Search:GetPropertyChangedSignal("Text"),function()self:SearchFor(self.Search.Text)end)
    self.Nav=create("ScrollingFrame",{Name="Tabs",BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),ScrollBarThickness=2},self.Panel)
    self:_Color(self.Nav,"ScrollBarImageColor3","Border");self._navLayout=list(self.Nav,7,false)
    self.PageHost=create("Frame",{Name="Pages",BackgroundTransparency=1},self.Panel)
    self.PageTitle=self:_Label(self.Panel,"",22,"Text");self:_Style(self.PageTitle,"Font","FontBold");self.PageTitle.AutomaticSize=Enum.AutomaticSize.None;self.PageTitle.TextWrapped=false;self.PageTitle.TextTruncate=Enum.TextTruncate.AtEnd
    self:_Style(self.PageTitle,"TextSize","TitleSize",function(value)return value+5 end)
    self.Footer=self:_Label(self.Panel,"",10,"Muted");self.Footer.Size=UDim2.new(1,-36,0,22);self.Footer.Position=UDim2.new(0,18,1,-32);self.Footer.AutomaticSize=Enum.AutomaticSize.None
    self._resize=self:_Button(self.Panel,"",UDim2.fromOffset(28,28));self._resize.Name="Resize";self._resize.Position=UDim2.new(1,-34,1,-34)
    Library:Icon(self._resize,"resize",{Size=16,Position=UDim2.fromOffset(6,6),Window=self,Token="Muted"})
    self.Reopen=self:_Button(self.Canvas,"OPEN",UDim2.fromOffset(112,44));self.Reopen.Name="Reopen";self.Reopen.Position=UDim2.new(0,14,0.5,-22);self.Reopen.Visible=false
    padding(self.Reopen,8);self.Reopen:FindFirstChildOfClass("UIPadding").PaddingLeft=UDim.new(0,32)
    Library:Icon(self.Reopen,"restore",{Size=18,Position=UDim2.new(0,-22,.5,-9),Window=self,Token="Text"})
    self:_Connect(self.Reopen.Activated,function()self:Show()end)
    self.ToastHost=create("Frame",{Name="Notifications",BackgroundTransparency=1,Position=UDim2.new(1,-18,0,18),AnchorPoint=Vector2.new(1,0),Size=UDim2.new(0,300,1,-36),ZIndex=40},self.Canvas)
    list(self.ToastHost,8,false)
    local viewport=self:_Viewport();self._position=Vector2.new(math.max(0,(viewport.X-self._desiredSize.X)/2),math.max(0,(viewport.Y-self._desiredSize.Y)/2))
    local function gesture(gui,kind)
        self:_Connect(gui.InputBegan,function(input)
            if self.Closed or (input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch) then return end
            if kind=="drag" and not self.Layout.Draggable or kind=="resize" and not self.Layout.Resizable then return end
            if kind=="drag" then self._positionSpec=nil end
            self._gesture={kind=kind,input=input,origin=Vector2.new(input.Position.X,input.Position.Y),position=self._position,size=self._desiredSize}
        end)
    end
    gesture(self.Header,"drag");gesture(self._resize,"resize")
    self:_Connect(UIS.InputChanged,function(input)
        local g=self._gesture
        if not g then return end
        if input~=g.input and not (g.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement) then return end
        local position=Vector2.new(input.Position.X,input.Position.Y)
        if g.kind=="drag" then self._position=g.position+(position-g.origin);self:_Layout()
        elseif g.kind=="resize" then self:SetSize(g.size.X+position.X-g.origin.X,g.size.Y+position.Y-g.origin.Y)
        elseif g.kind=="slider" and not g.control.Destroyed then g.control:_Pointer(position.X) end
    end)
    self:_Connect(UIS.InputEnded,function(input)if self._gesture and input==self._gesture.input then self._gesture=nil end end)
    self:_Connect(UIS.WindowFocusReleased,function()self._gesture=nil;if self._capture then self._capture:_Render();self._capture=nil end end)
    self:_Connect(UIS.InputBegan,function(input,processed)
        if UIS:GetFocusedTextBox() then return end
        if self._capture and not self.Closed then
            if input.KeyCode==Enum.KeyCode.Escape then self._capture._input.Text=self._capture.Value;self._capture=nil;return end
            if input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode~=Enum.KeyCode.Unknown then
                local target=self._capture;local previous=target.Value;self._capture=nil;target:Set(input.KeyCode.Name,false)
                if target.Value~=previous then self:_Emit(target,"Changed",target.Value,previous)end
                return
            end
        end
        if processed then return end
        if input.KeyCode==self.ToggleKey then self:Toggle();return end
        if self.Closed or self._modal then return end
        for _,control in pairs(self.Controls) do
            if control.Kind=="Keybind" and control.Enabled and control.Value==input.KeyCode.Name then self:_Callback(control,control.Value) end
        end
    end)
    self:_Connect(workspace:GetPropertyChangedSignal("CurrentCamera"),function()self:_WatchCamera()end)
    self:_Connect(self.Canvas:GetPropertyChangedSignal("AbsoluteSize"),function()self:_Layout()end)
    self:_Connect(self.Nav:GetPropertyChangedSignal("AbsoluteSize"),function()self:_EnsureTabVisible(self.CurrentTab)end)
    self:_Connect(self._navLayout:GetPropertyChangedSignal("AbsoluteContentSize"),function()self:_EnsureTabVisible(self.CurrentTab)end)
    for _,property in ipairs({"OnScreenKeyboardVisible","OnScreenKeyboardPosition","OnScreenKeyboardSize"}) do
        self:_Connect(UIS:GetPropertyChangedSignal(property),function()self:_Layout()end)
    end
    self:_Connect(self.Gui.Destroying,function()self._guiDestroying=true;self:Destroy()end)
    if branding then self:SetBranding(branding)end
    self:_WatchCamera();Library.Windows[id]=self
    return self
end
function Window:Tab(options)
    assert(not self.Destroyed,"Window is destroyed");options=options or {}
    assert(type(options)=="table","Tab options must be a table")
    assert(options.Icon==nil or Library:GetIconName(options.Icon)~=nil,"Unknown tab icon: "..tostring(options.Icon))
    assert(options.IconVariant==nil or options.IconVariant=="Outline"or options.IconVariant=="Soft"or options.IconVariant=="Duotone","Invalid tab IconVariant")
    local tabLayout=tab_layout_for(options.Layout)
    local tab=setmetatable({Window=self,Title=tostring(options.Title or "Tab"),_controls={},_sections={},_children={},_connections={},_visible=true,Destroyed=false},Container)
    tab.Tab=tab
    tab.Layout=tabLayout
    tab._button=self:_MakeTabButton(tab,options)
    tab._button.LayoutOrder=tabLayout.Order or #self.Tabs+1
    tab.Page=create("ScrollingFrame",{Name=tab.Title,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=3,Visible=false},self.PageHost)
    padding(tab.Page,2);self:_Color(tab.Page,"ScrollBarImageColor3","Border");list(tab.Page,10,false)
    tab.Body=tab.Page
    tab._empty=self:_Label(tab.Page,"No matching controls.",13,"Muted");tab._empty.Visible=false;tab._empty.LayoutOrder=100000
    self.Tabs[#self.Tabs+1]=tab
    self:_Connect(tab._button.Activated,function()self:SelectTab(tab)end,tab)
    if not self.CurrentTab then self:SelectTab(tab) end
    self:_Layout();return tab
end
function Container:Section(options)
    assert(not self.Window.Destroyed and not self.Destroyed,"Container is destroyed")
    assert(self.Tab==self,"Sections belong directly to tabs")
    options=options or {}
    local section=setmetatable({Window=self.Window,Tab=self,Title=tostring(options.Title or "Section"),_children={},_visible=true,Destroyed=false},Container)
    self.Window._serial+=1
    section.Root=create("Frame",{Size=UDim2.new(1,-4,0,0),AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=self.Window._serial*2},self.Body)
    self.Window:_Rounded(section.Root,"SectionRadius");self.Window:_Color(section.Root,"BackgroundColor3","Surface");self.Window:_Stroke(section.Root,"Border",.4);list(section.Root,0,false)
    local header=create("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,44)},section.Root)
    local label=self.Window:_Label(header,section.Title,13,"Muted");self.Window:_Style(label,"Font","FontBold");label.Position=UDim2.fromOffset(14,0);label.Size=UDim2.new(1,-28,1,0);label.AutomaticSize=Enum.AutomaticSize.None
    local line=create("Frame",{Size=UDim2.new(1,-28,0,1),Position=UDim2.new(0,14,1,-1),BackgroundTransparency=.6},header);self.Window:_Color(line,"BackgroundColor3","Border")
    section.Body=create("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1},section.Root);list(section.Body,0,false)
    self._sections[#self._sections+1]=section;return section
end
function Container:SetVisible(value)
    assert(type(value)=="boolean","Visibility must be boolean")
    if not value then self.Window:_CancelInteraction(self.Root or self.Page) end
    self._visible=value
    if self.Root then self.Root.Visible=value end
    self.Window:SearchFor(self.Window.Query);return self
end
function Container:Destroy()
    if self.Destroyed then return end
    self.Destroyed=true
    self.Window:_CancelInteraction(self.Root or self.Page)
    if self.Tab==self then self.Window:_ForgetTree(self._button);self.Window:_ForgetTree(self.Page)
    else self.Window:_ForgetTree(self.Root)end
    local controls={};for _,control in ipairs(self._children) do controls[#controls+1]=control end
    for _,control in ipairs(controls) do control:Destroy() end
    if self.Tab==self then
        for _,section in ipairs(table.clone(self._sections)) do section:Destroy() end
        disconnect(self._connections,self)
        for i,tab in ipairs(self.Window.Tabs) do if tab==self then table.remove(self.Window.Tabs,i);break end end
        self.Page:Destroy();self._button:Destroy()
        if self.Window.CurrentTab==self then self.Window.CurrentTab=nil;if self.Window.Tabs[1] then self.Window:SelectTab(1) end end
    else
        self.Root:Destroy()
        for index=#self.Tab._sections,1,-1 do if self.Tab._sections[index]==self then table.remove(self.Tab._sections,index) end end
        self.Window:SearchFor(self.Window.Query)
    end
end
function Container:_Row(kind,options,rightWidth,persistent)
    assert(not self.Window.Destroyed and not self.Destroyed,"Container is destroyed")
    options=options or {};assert(type(options)=="table","Control options must be a table")
    local window=self.Window
    local controlLayout=control_layout_for(options.Layout)
    window._serial+=1
    local id=tostring(options.Id or (kind.."_"..window._serial))
    assert(window.Controls[id]==nil,"Duplicate control Id: "..id)
    local control=setmetatable({Window=window,Container=self,Tab=self.Tab,Id=id,Kind=kind,Title=tostring(options.Title or kind),Description=tostring(options.Description or options.Desc or ""),Callback=options.Callback,Enabled=options.Disabled~=true,Persistent=persistent and options.Persistent~=false or false,Destroyed=false,_connections={},_visible=true,Layout=controlLayout},Control)
    local row=create("Frame",{Name=id,Size=UDim2.new(1,-4,0,0),AutomaticSize=Enum.AutomaticSize.Y,BorderSizePixel=0,LayoutOrder=window._serial},self.Body)
    local grouped=self.Tab~=self;row.LayoutOrder=window._serial*2;control.Root=row
    if controlLayout.Order then row.LayoutOrder=controlLayout.Order*2 end
    local inset=kind=="Paragraph" and not grouped and 0 or window.Style.RowPadding
    padding(row,inset)
    if inset~=0 then
        local pad=row:FindFirstChildOfClass("UIPadding")
        for _,property in ipairs({"PaddingLeft","PaddingRight","PaddingTop","PaddingBottom"})do window:_Style(pad,property,"RowPadding",function(v)return UDim.new(0,v)end)end
    end
    if grouped then
        row.BackgroundTransparency=1;row.Size=UDim2.new(1,0,0,0)
        control._separator=create("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,1),LayoutOrder=row.LayoutOrder-1},self.Body)
        local line=create("Frame",{Size=UDim2.new(1,-28,1,0),Position=UDim2.fromOffset(14,0),BackgroundTransparency=.6},control._separator);window:_Color(line,"BackgroundColor3","Border")
    elseif kind=="Paragraph" then row.BackgroundTransparency=1
    else window:_Rounded(row,"SectionRadius");window:_Color(row,"BackgroundColor3","Surface");window:_Stroke(row,"Border",.45)end
    create("UISizeConstraint",{MinSize=Vector2.new(0,rightWidth and 44 or 0)},row)
    local text=create("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,-(rightWidth and rightWidth+14 or 0),0,0),AutomaticSize=Enum.AutomaticSize.Y},row);list(text,5,false)
    control._text=text;control._rightWidth=rightWidth
    control._title=window:_Label(text,control.Title,14,"Text");control._title.Font=bold
    control._description=window:_Label(text,control.Description,12,"Muted");control._description.LayoutOrder=1;control._description.Visible=control.Description~=""
    window:_Style(control._title,"Font","FontBold");window:_Style(control._title,"TextSize","TextSize");window:_Style(control._description,"TextSize","DescriptionSize")
    if rightWidth then control.Right=create("Frame",{BackgroundTransparency=1,Position=UDim2.fromScale(1,0),AnchorPoint=Vector2.new(1,0),Size=UDim2.fromOffset(rightWidth,40)},row) end
    control._search=control.Title.." "..control.Description.." "..self.Title
    window.Controls[id]=control;self._children[#self._children+1]=control;self.Tab._controls[#self.Tab._controls+1]=control
    return control
end
function Control:_Layout(mobile)
    if not self.Right then return end
    local layout=self.Layout;local settings=self.Window.Layout
    local rightWidth=layout.Width or (self.Kind=="Button" and settings.ButtonWidth or self._rightWidth)
    if self.Kind=="Toggle"then rightWidth=math.max(58,rightWidth)end
    local target=math.max(self.Window.Responsive.TouchTarget,layout.Height or settings.ButtonHeight)
    local placement=layout.Position or settings.ControlsPosition
    if self._paletteGrid then
        local width=math.max(1,self.Root.AbsoluteSize.X-self.Window.Style.RowPadding*2)
        local target=self.Window.Responsive.TouchTarget
        local columns=math.clamp(math.floor((width+8)/(target+8)),1,4)
        self._paletteLayout.CellSize=UDim2.new(1/columns,-8*(columns-1)/columns,0,target)
        self._paletteLayout.FillDirectionMaxCells=columns
        self._paletteGrid.Size=UDim2.new(1,0,0,math.ceil(#self._swatches/columns)*(target+8)-8)
        self._colorInput.Size=UDim2.new(1,0,0,target)
    end
    local available=math.max(1,self.Window.PageHost.Size.X.Offset-self.Window.Style.RowPadding*2-4)
    mobile=mobile or rightWidth+140>available or placement=="Below" or (self.Kind=="ColorPicker" and self._expanded==true)
    self._text.Position=not mobile and placement=="Left" and UDim2.fromOffset(rightWidth+14,0)or UDim2.new()
    self._text.Size=UDim2.new(1,mobile and 0 or -(rightWidth+14),0,0)
    if mobile then
        if not self._mobileLayout then self._mobileLayout=list(self.Root,settings.RowGap,false) end
        self._mobileLayout.Padding=UDim.new(0,settings.RowGap)
        self._text.LayoutOrder=0;self.Right.LayoutOrder=1
        self.Right.Position=UDim2.new();self.Right.AnchorPoint=Vector2.zero
        self.Right.Size=UDim2.new(1,0,0,target)
    else
        if self._mobileLayout then self._mobileLayout:Destroy();self._mobileLayout=nil end
        self.Right.Position=placement=="Left"and UDim2.new()or UDim2.fromScale(1,0);self.Right.AnchorPoint=placement=="Left"and Vector2.zero or Vector2.new(1,0)
        self.Right.Size=UDim2.fromOffset(rightWidth,target)
    end
    if self._input then
        if self.Kind=="Toggle" then
            self._input.Size=UDim2.fromOffset(58,target)
            self._track.Position=UDim2.new(0,2,.5,-14)
        elseif self.Kind=="Slider" then
            self._input.Size=UDim2.new(1,0,0,target)
            self.Right.Size=UDim2.new(mobile and 1 or 0,mobile and 0 or rightWidth,0,target+18)
        else self._input.Size=UDim2.new(1,0,0,target) end
    end
end
function Control:SetTitle(value)
    assert(not self.Destroyed,"Control is destroyed");self.Title=tostring(value);self._title.Text=self.Title
    self._search=self.Title.." "..self.Description.." "..self.Container.Title;self.Window:SearchFor(self.Window.Query);return self
end
function Control:SetDescription(value)
    assert(not self.Destroyed,"Control is destroyed");self.Description=tostring(value or "");self._description.Text=self.Description;self._description.Visible=self.Description~=""
    self._search=self.Title.." "..self.Description.." "..self.Container.Title;self.Window:SearchFor(self.Window.Query);return self
end
function Control:SetVisible(value)
    assert(type(value)=="boolean","Visibility must be boolean");if not value then self.Window:_CancelInteraction(self.Root)end;self._visible=value;self.Window:SearchFor(self.Window.Query);return self
end
function Control:SetEnabled(value)
    assert(type(value)=="boolean","Enabled must be boolean");self.Enabled=value
    if not value then release_focus(self.Root) end
    if not value and self.Window._capture==self then self:_Render();self.Window._capture=nil end
    if not value and self.Window._dropdownControl==self then self.Window:_CloseDropdown() end
    if not value and self.Window._gesture and self.Window._gesture.control==self then self.Window._gesture=nil end
    if not value and self.Kind=="ColorPicker" then self._expanded=false;self._paletteBody.Visible=false;self:_Layout(self.Window.Mobile);self._colorInput.TextEditable=false
    elseif value and self.Kind=="ColorPicker" then self._colorInput.TextEditable=self._expanded end
    if self.Kind=="ColorPicker" then self._colorInput.Active=value and self._expanded end
    self._title.TextTransparency=value and 0 or .5
    if self._input then self._input.Active=value;if self._input:IsA("TextBox") then self._input.TextEditable=value end end
    if self._Render then self:_Render() end
    return self
end
function Control:Get()return self.Value end
function Control:_Validate(value)
    if self.Kind=="Toggle" then assert(type(value)=="boolean","Toggle value must be boolean");return value
    elseif self.Kind=="Slider" then return Logic.number(value,self.Min,self.Max,self.Step)
    elseif self.Kind=="Dropdown" then return Logic.option(value,self.Options)
    elseif self.Kind=="Input" then return Logic.text(value,self.MaxLength)
    elseif self.Kind=="ColorPicker" then
        if typeof(value)=="Color3" then value="#"..value:ToHex() end
        return Logic.hex(value)
    elseif self.Kind=="Keybind" then assert(type(value)=="string" and Enum.KeyCode[value]~=nil and value~="Unknown","Keybind must name a KeyCode");return value end
    error("This control has no persistent value")
end
function Control:Set(value,fireCallback)
    assert(not self.Destroyed and not self.Window.Destroyed,"Control is destroyed")
    local valid=self:_Validate(value);local previous=self.Value;local changed=previous~=valid;self.Value=valid
    self:_Render()
    if changed and fireCallback==true then self.Window:_Callback(self,valid);self.Window:_Emit(self,"Changed",valid,previous) end
    return self
end
function Control:Destroy()
    if self.Destroyed then return end
    self.Destroyed=true;disconnect(self._connections,self)
    self.Window:_DisconnectEvents(self)
    if self.Window._dropdownControl==self then self.Window:_CloseDropdown() end
    if self.Window._capture==self then self.Window._capture=nil end
    if self.Window._gesture and self.Window._gesture.control==self then self.Window._gesture=nil end
    self.Window.Controls[self.Id]=nil
    self.Window:_ForgetTree(self.Root);self.Root:Destroy()
    if self._separator then self.Window:_ForgetTree(self._separator);self._separator:Destroy()end
    for _,array in ipairs({self.Container._children,self.Tab._controls}) do
        for index=#array,1,-1 do if array[index]==self then table.remove(array,index) end end
    end
    if not self.Window.Destroyed then self.Window:SearchFor(self.Window.Query) end
end
function Container:Paragraph(options)local c=self:_Row("Paragraph",options,nil,false);self.Window:SearchFor(self.Window.Query);return c end
function Container:Button(options)
    options=options or {}
    assert(type(options)=="table","Button options must be a table")
    assert(options.Icon==nil or Library:GetIconName(options.Icon)~=nil,"Unknown button Icon")
    assert(options.IconVariant==nil or options.IconVariant=="Outline"or options.IconVariant=="Soft"or options.IconVariant=="Duotone","Invalid button IconVariant")
    local control=self:_Row("Button",options,110,false)
    control._input=self.Window:_Button(control.Right,options.Text or "Run",UDim2.fromOffset(110,36),control)
    if options.Icon then
        create("UIPadding",{PaddingLeft=UDim.new(0,30),PaddingRight=UDim.new(0,8)},control._input)
        control._icon=Library:Icon(control._input,options.Icon,{Size=18,Position=UDim2.new(0,-22,.5,-9),Window=self.Window,Token="Text",Variant=options.IconVariant or "Outline"})
        control._input.TextTruncate=Enum.TextTruncate.AtEnd
    end
    self.Window:_Connect(control._input.Activated,function()self.Window:_Callback(control)end,control)
    control:_Layout(self.Window.Mobile);control:SetEnabled(control.Enabled);self.Window:SearchFor(self.Window.Query);return control
end
function Container:Toggle(options)
    options=options or {};assert(options.Value==nil or type(options.Value)=="boolean","Toggle default must be boolean")
    local control=self:_Row("Toggle",options,58,true)
    control.Value=options.Value==true
    control._input=create("TextButton",{Text="",AutoButtonColor=false,BackgroundTransparency=1,Size=UDim2.fromOffset(58,44),Selectable=true},control.Right)
    control._track=create("Frame",{Size=UDim2.fromOffset(54,28),BorderSizePixel=0},control._input);corner(control._track,14)
    control._knob=create("Frame",{Size=UDim2.fromOffset(20,20),Position=UDim2.fromOffset(4,4),BorderSizePixel=0},control._track);corner(control._knob,10)
    function control:_Render()
        self._track.BackgroundColor3=self.Window.Theme[self.Value and "Accent" or "Raised"]
        self._knob.BackgroundColor3=self.Window.Theme[self.Value and "AccentText" or "Muted"]
        self.Window:_Tween(self._knob,{Position=UDim2.fromOffset(self.Value and 30 or 4,4)})
    end
    self.Window:_Connect(control._input.Activated,function()if control.Enabled then control:Set(not control.Value,true) end end,control)
    control:_Render();control:_Layout(self.Window.Mobile);control:SetEnabled(control.Enabled);self.Window:SearchFor(self.Window.Query);return control
end
function Container:Slider(options)
    options=options or {}
    local minimum=options.Min or 0;local maximum=options.Max or 100;local step=options.Step or 1
    local initial=Logic.number(options.Value or minimum,minimum,maximum,step)
    local control=self:_Row("Slider",options,140,true);control.Min=minimum;control.Max=maximum;control.Step=step;control.Value=initial
    control._value=self.Window:_Label(control.Right,"",12,"Text");control._value.TextXAlignment=Enum.TextXAlignment.Right;control._value.Size=UDim2.new(1,0,0,16);control._value.AutomaticSize=Enum.AutomaticSize.None
    control._input=create("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.new(1,0,0,28),Position=UDim2.fromOffset(0,17),AutoButtonColor=false,Selectable=true},control.Right)
    local track=create("Frame",{Size=UDim2.new(1,0,0,5),Position=UDim2.fromOffset(0,11),BorderSizePixel=0},control._input);corner(track,3);self.Window:_Color(track,"BackgroundColor3","Raised")
    control._fill=create("Frame",{Size=UDim2.fromScale(0,1),BorderSizePixel=0},track);corner(control._fill,3);self.Window:_Color(control._fill,"BackgroundColor3","Accent")
    control._knob=create("Frame",{Size=UDim2.fromOffset(14,14),Position=UDim2.fromScale(0,.5),AnchorPoint=Vector2.new(.5,.5),BorderSizePixel=0},track);corner(control._knob,7);self.Window:_Color(control._knob,"BackgroundColor3","Accent")
    function control:_Render()
        local ratio=(self.Value-self.Min)/(self.Max-self.Min)
        self._value.Text=string.format("%.4g",self.Value)
        self._fill.Size=UDim2.fromScale(ratio,1);self._knob.Position=UDim2.fromScale(ratio,.5)
    end
    function control:_Pointer(x)
        if not self.Enabled or self.Window.Closed or self._input.AbsoluteSize.X<=0 then return end
        self:Set(self.Min+math.clamp((x-self._input.AbsolutePosition.X)/self._input.AbsoluteSize.X,0,1)*(self.Max-self.Min),true)
    end
    self.Window:_Connect(control._input.InputBegan,function(input)
        if not control.Enabled then return end
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            self.Window._gesture={kind="slider",control=control,input=input};control:_Pointer(input.Position.X)
        elseif input.KeyCode==Enum.KeyCode.Left or input.KeyCode==Enum.KeyCode.DPadLeft then control:Set(control.Value-control.Step,true)
        elseif input.KeyCode==Enum.KeyCode.Right or input.KeyCode==Enum.KeyCode.DPadRight then control:Set(control.Value+control.Step,true) end
    end,control)
    control:_Render();control:_Layout(self.Window.Mobile);control:SetEnabled(control.Enabled);self.Window:SearchFor(self.Window.Query);return control
end
function Container:Input(options)
    options=options or {};local maximum=options.MaxLength or 120;assert(Logic.finite(maximum) and maximum>=1 and maximum<=4096,"MaxLength must be 1..4096");maximum=math.floor(maximum)
    local initial=Logic.text(options.Value or "",maximum)
    local control=self:_Row("Input",options,140,true);control.MaxLength=maximum;control.Value=initial
    control._input=create("TextBox",{Text=initial,PlaceholderText=options.Placeholder or "Type here...",ClearTextOnFocus=false,Font=font,TextSize=12,Size=UDim2.fromOffset(140,36),TextTruncate=Enum.TextTruncate.AtEnd},control.Right)
    self.Window:_Style(control._input,"Font","Font");self.Window:_Style(control._input,"TextSize","TextSize");self.Window:_Rounded(control._input,"ControlRadius");padding(control._input,9);self.Window:_Color(control._input,"BackgroundColor3","Raised");self.Window:_Color(control._input,"TextColor3","Text");self.Window:_Color(control._input,"PlaceholderColor3","Muted");self.Window:_Stroke(control._input,"Border",.3)
    function control:_Render()self._input.Text=self.Value end
    self.Window:_Connect(control._input.FocusLost,function()if control.Enabled then control:Set(control._input.Text,true) end end,control)
    control:_Layout(self.Window.Mobile);control:SetEnabled(control.Enabled);self.Window:SearchFor(self.Window.Query);return control
end
function Container:Keybind(options)
    options=options or {};local value=options.Value or "F6";if typeof(value)=="EnumItem" then value=value.Name end
    assert(type(value)=="string" and Enum.KeyCode[value] and value~="Unknown","Keybind default must name a KeyCode")
    local control=self:_Row("Keybind",options,110,true);control.Value=value
    control._input=self.Window:_Button(control.Right,value,UDim2.fromOffset(110,36),control)
    function control:_Render()self._input.Text=self.Value end
    self.Window:_Connect(control._input.Activated,function()
        if not control.Enabled then return end
        if self.Window._capture then self.Window._capture:_Render() end
        self.Window._capture=control;control._input.Text="Press a key..."
    end,control)
    control:_Layout(self.Window.Mobile);control:SetEnabled(control.Enabled);self.Window:SearchFor(self.Window.Query);return control
end
function Container:Dropdown(options)
    options=options or {};local choices=Logic.options(options.Options);local initial=Logic.option(options.Value or choices[1],choices)
    local control=self:_Row("Dropdown",options,140,true);control.Options=choices;control.Value=initial
    control._input=self.Window:_Button(control.Right,"",UDim2.fromOffset(140,36),control);control._input.TextTruncate=Enum.TextTruncate.AtEnd
    control._arrow=self.Window:_Chevron(control._input)
    control._valueLabel=self.Window:_Label(control._input,"",13,"Text");control._valueLabel.Font=bold;control._valueLabel.AutomaticSize=Enum.AutomaticSize.None;control._valueLabel.Size=UDim2.new(1,-38,1,0);control._valueLabel.Position=UDim2.fromOffset(10,0);control._valueLabel.TextXAlignment=Enum.TextXAlignment.Center;control._valueLabel.TextWrapped=false;control._valueLabel.TextTruncate=Enum.TextTruncate.AtEnd
    self.Window:_Style(control._valueLabel,"Font","FontBold");self.Window:_Style(control._valueLabel,"TextSize","TextSize")
    function control:_Render()self._valueLabel.Text=self.Value end
    function control:SetOptions(values,value)
        local valid=Logic.options(values);local selected=value or self.Value
        local found=false;for _,entry in ipairs(valid) do if entry==selected then found=true end end
        if not found then selected=valid[1] end
        selected=Logic.option(selected,valid)
        self.Window:_CloseDropdown();self.Options=valid;self.Value=selected;self:_Render();return self
    end
    self.Window:_Connect(control._input.Activated,function()
        if not control.Enabled then return end
        local window=self.Window
        if window._dropdownControl==control then window:_CloseDropdown();return end
        window:_CloseDropdown()
        local shield=create("TextButton",{Name="Dropdown",Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),AutoButtonColor=false,ZIndex=30},window.Canvas)
        window._dropdown=shield;window._dropdownControl=control
        local viewport=window:_Viewport();local position=control._input.AbsolutePosition-window.Canvas.AbsolutePosition;local width=math.min(210,viewport.X-24);local height=math.min(260,#control.Options*48+16,viewport.Y-24)
        local y=position.Y+control._input.AbsoluteSize.Y+6;if y+height>viewport.Y-12 then y=math.max(12,position.Y-height-6) end
        local menu=create("ScrollingFrame",{Name="Options",Position=UDim2.fromOffset(math.clamp(position.X,12,math.max(12,viewport.X-width-12)),y),Size=UDim2.fromOffset(width,height),BorderSizePixel=0,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollBarThickness=3,ZIndex=31,Active=true},shield)
        corner(menu,8);padding(menu,8);list(menu,4,false);window:_Color(menu,"BackgroundColor3","Surface");window:_Stroke(menu,"Border",.2)
        local temporary={_connections={},Destroyed=false}
        menu.Destroying:Once(function()temporary.Destroyed=true;disconnect(temporary._connections)end)
        window:_Connect(shield.Activated,function()window:_CloseDropdown()end,temporary)
        for index,option in ipairs(control.Options) do
            local selected=option==control.Value
            local button=window:_Button(menu,option,UDim2.new(1,-4,0,window.Responsive.TouchTarget),temporary)
            button.ZIndex=32;button.LayoutOrder=index;button.TextXAlignment=Enum.TextXAlignment.Left;button.TextTruncate=Enum.TextTruncate.AtEnd
            local inset=button:FindFirstChildOfClass("UIPadding") or create("UIPadding",{},button)
            inset.PaddingLeft=UDim.new(0,12);inset.PaddingRight=UDim.new(0,34)
            local outline=button:FindFirstChildOfClass("UIStroke");if outline then outline.Enabled=false end
            window:_Color(button,"BackgroundColor3",selected and "Raised" or "Surface")
            window:_Color(button,"TextColor3",selected and "Text" or "Muted")
            if selected then
                Library:Icon(button,"check",{Size=14,Position=UDim2.new(1,-26,.5,-7),Window=window,Token="Text"})
            end
            window:_Connect(button.Activated,function()control:Set(option,true);window:_CloseDropdown()end,temporary)
        end
    end,control)
    control:_Render();control:_Layout(self.Window.Mobile);control:SetEnabled(control.Enabled);self.Window:SearchFor(self.Window.Query);return control
end
function Container:ColorPicker(options)
    options=options or {}
    local value=options.Value or "#F2F4F8"
    if typeof(value)=="Color3" then value="#"..value:ToHex() end
    value=Logic.hex(value)
    local palette=options.Palette or {"#F2F4F8","#A5A6AA","#60636D","#202328","#A18FFF","#78B8FF","#7BDDD0","#A6DBC4","#FFA671","#F08B8B","#F5CA77","#D29EEB"}
    assert(type(palette)=="table" and #palette>0 and #palette<=32,"Palette needs 1..32 colors")
    local valid={};for _,color in ipairs(palette)do valid[#valid+1]=Logic.hex(color) end
    local control=self:_Row("ColorPicker",options,140,true);control.Value=value;control._expanded=false;control._swatches={}
    control._input=self.Window:_Button(control.Right,"",UDim2.fromOffset(140,44),control)
    control._arrow=self.Window:_Chevron(control._input)
    control._valueLabel=self.Window:_Label(control._input,"",13,"Text");control._valueLabel.Font=bold;control._valueLabel.AutomaticSize=Enum.AutomaticSize.None;control._valueLabel.Size=UDim2.new(1,-64,1,0);control._valueLabel.Position=UDim2.fromOffset(32,0);control._valueLabel.TextXAlignment=Enum.TextXAlignment.Center;control._valueLabel.TextWrapped=false;control._valueLabel.TextTruncate=Enum.TextTruncate.AtEnd
    control._swatch=create("Frame",{Size=UDim2.fromOffset(16,16),Position=UDim2.new(0,10,.5,-8),BorderSizePixel=0},control._input);corner(control._swatch,4)
    control._paletteBody=create("Frame",{Name="ColorPalette",BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=2,Visible=false},control.Root)
    list(control._paletteBody,10,false)
    local grid=create("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,math.ceil(#valid/4)*52)},control._paletteBody)
    control._paletteGrid=grid
    control._paletteLayout=create("UIGridLayout",{CellSize=UDim2.new(.25,-6,0,44),CellPadding=UDim2.fromOffset(8,8),FillDirectionMaxCells=4,SortOrder=Enum.SortOrder.LayoutOrder},grid)
    for index,color in ipairs(valid)do
        local swatch=create("TextButton",{Text="",BackgroundColor3=Color3.fromHex(color),AutoButtonColor=false,Selectable=true,LayoutOrder=index},grid);corner(swatch,8)
        local stroke=self.Window:_Stroke(swatch,"Border")
        control._swatches[#control._swatches+1]={Color=color,Stroke=stroke}
        self.Window:_Connect(swatch.Activated,function()if control.Enabled then control:Set(color,true)end end,control)
    end
    control._colorInput=create("TextBox",{Name="HexColor",Text=value,PlaceholderText="#RRGGBB",ClearTextOnFocus=false,TextEditable=false,Active=false,Font=font,TextSize=13,Size=UDim2.new(1,0,0,44),LayoutOrder=1},control._paletteBody)
    self.Window:_Style(control._colorInput,"Font","Font");self.Window:_Style(control._colorInput,"TextSize","TextSize");self.Window:_Style(control._valueLabel,"Font","FontBold");self.Window:_Style(control._valueLabel,"TextSize","TextSize");self.Window:_Rounded(control._colorInput,"ControlRadius");self.Window:_Color(control._colorInput,"BackgroundColor3","Raised");self.Window:_Color(control._colorInput,"TextColor3","Text");self.Window:_Color(control._colorInput,"PlaceholderColor3","Muted");self.Window:_Stroke(control._colorInput,"Border",.3)
    function control:_Render()
        self._valueLabel.Text=self.Value;self._swatch.BackgroundColor3=Color3.fromHex(self.Value);self._colorInput.Text=self.Value
        self._arrow.Rotation=self._expanded and 180 or 0
        for _,swatch in ipairs(self._swatches)do
            local selected=swatch.Color==self.Value
            self.Window:_Color(swatch.Stroke,"Color",selected and "Accent" or "Border")
            swatch.Stroke.Thickness=selected and 2 or 1
            swatch.Stroke.Transparency=selected and 0 or .18
        end
    end
    function control:GetColor()return Color3.fromHex(self.Value)end
    self.Window:_Connect(control._input.Activated,function()
        if not control.Enabled then return end
        control._expanded=not control._expanded
        if not control._expanded then release_focus(control._paletteBody)end
        control._paletteBody.Visible=control._expanded;control._colorInput.TextEditable=control._expanded;control._colorInput.Active=control._expanded;control:_Render();control:_Layout(self.Window.Mobile)
    end,control)
    self.Window:_Connect(control._colorInput.FocusLost,function()
        if not control.Enabled or not control._expanded then control:_Render();return end
        local ok=pcall(function()control:Set(control._colorInput.Text,true)end)
        if not ok then control:_Render();self.Window:Notify({Title="Invalid color",Content="Use six hexadecimal digits, for example #A6DBC4.",Kind="error"})end
    end,control)
    self.Window:_Connect(control._colorInput.Focused,function()
        if not control.Enabled or not control._expanded then control._colorInput:ReleaseFocus(false)end
    end,control)
    self.Window:_Connect(control.Root:GetPropertyChangedSignal("AbsoluteSize"),function()control:_Layout(self.Window.Mobile)end,control)
    control:_Render();control:_Layout(self.Window.Mobile);control:SetEnabled(control.Enabled);self.Window:SearchFor(self.Window.Query);return control
end
function Window:Confirm(options)
    assert(not self.Destroyed,"Window is destroyed");options=options or {}
    if self._modal then return false end
    self:_CancelInteraction(self.Root)
    self:_CloseDropdown();self._gesture=nil
    if self._capture then self._capture:_Render();self._capture=nil end
    local overlay=create("TextButton",{Name="Confirmation",Text="",AutoButtonColor=false,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.35,Size=UDim2.fromScale(1,1),ZIndex=50},self.Canvas)
    local popup=create("Frame",{Size=UDim2.new(0,math.min(380,self:_Viewport().X-32),0,0),AutomaticSize=Enum.AutomaticSize.Y,Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),BorderSizePixel=0,ZIndex=51},overlay)
    corner(popup,16);padding(popup,20);list(popup,12,false);self:_Color(popup,"BackgroundColor3","Surface");self:_Stroke(popup,"Border",.18)
    local title=self:_Label(popup,options.Title or "Confirm",18,"Text");title.Font=bold;title.ZIndex=52;self:_Style(title,"Font","FontBold");self:_Style(title,"TextSize","TitleSize")
    local description=self:_Label(popup,options.Content or "",12,"Muted");description.ZIndex=52;description.LayoutOrder=1
    local actions=create("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,self.Responsive.TouchTarget),LayoutOrder=2,ZIndex=52},popup);list(actions,8,true)
    local scope={_connections={},Destroyed=false};self._modal=overlay
    overlay.Destroying:Once(function()scope.Destroyed=true;disconnect(scope._connections);if self._modal==overlay then self._modal=nil end end)
    local cancel=self:_Button(actions,"Cancel",UDim2.new(.5,-4,1,0),scope);cancel.ZIndex=53
    local confirm=self:_Button(actions,options.ConfirmText or "Confirm",UDim2.new(.5,-4,1,0),scope);confirm.ZIndex=53
    self:_Color(cancel,"BackgroundColor3","Surface");self:_Color(cancel,"TextColor3","Muted")
    local cancelOutline=cancel:FindFirstChildOfClass("UIStroke");if cancelOutline then cancelOutline.Transparency=.35 end
    self:_Color(confirm,"BackgroundColor3","Accent");self:_Color(confirm,"TextColor3","AccentText")
    local function close()self:_ForgetTree(overlay);overlay:Destroy()end
    self:_Connect(cancel.Activated,close,scope)
    self:_Connect(confirm.Activated,function()
        close()
        if type(options.Callback)=="function" then self:_Callback({Id="Confirmation",Enabled=true,Callback=options.Callback},true) end
    end,scope)
    return true
end
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
    RowPadding = 14,
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

-- Native vector icon registry. Injected into ui.luau's shared lexical scope.
-- Builders receive a 24-unit design canvas; geometry scales with the root Frame.

Library._icons = Library._icons or {}

local function iconFrame(parent, name, properties)
    properties = properties or {}
    properties.Name = name
    properties.BackgroundTransparency = properties.BackgroundTransparency or 0
    properties.BorderSizePixel = 0
    properties.AutoLocalize = false
    local frame=create("Frame", properties, parent)
    frame:SetAttribute("GabibouIconPrimitive",true)
    return frame
end

local function iconBuilder(window, root, color, token, thickness, variant)
    local strokeWidth = variant == "Soft" and math.min(4, thickness * 1.2) or thickness
    local function paint(instance, property)
        if color then instance[property] = color
        elseif window then window:BindColor(instance, property, token)
        else instance[property] = Color3.fromRGB(157, 162, 173) end
    end

    local function line(x1, y1, x2, y2, radius)
        local dx, dy = x2 - x1, y2 - y1
        local length = math.sqrt(dx * dx + dy * dy)
        local shape = iconFrame(root, "Vector", {
            AnchorPoint = Vector2.new(.5, .5),
            Position = UDim2.new((x1 + x2) / 48, 0, (y1 + y2) / 48, 0),
            -- Rounded caps shorten the visible ends of each segment. Extend the
            -- native width by one stroke so joined path segments overlap cleanly.
            Size = UDim2.new(length / 24, strokeWidth, 0, strokeWidth),
            Rotation = math.deg(math.atan2(dy, dx)),
        })
        if radius ~= false then corner(shape, variant == "Soft" and strokeWidth * 1.5 or strokeWidth) end
        paint(shape, "BackgroundColor3")
        if variant == "Duotone" then
            local canvasWidth = root.Size.X.Offset
            local extension = canvasWidth > 0 and strokeWidth * 24 / canvasWidth or 0
            local halfExtension = extension / 2
            local unitX, unitY = dx / length, dy / length
            local function fieldColor(x, y)
                local field = math.clamp((x + y) / 48, 0, 1)
                local value = 1 - (1 - 150 / 255) * field
                return Color3.new(value, value, value)
            end
            local startColor = fieldColor(x1 - unitX * halfExtension, y1 - unitY * halfExtension)
            local endColor = fieldColor(x2 + unitX * halfExtension, y2 + unitY * halfExtension)
            create("UIGradient", {
                Color = ColorSequence.new(startColor, endColor),
                Rotation = 0,
            }, shape)
        end
        return shape
    end

    local function rect(x, y, width, height, outline, radius)
        local shape = iconFrame(root, outline and "Outline" or "Vector", {
            BackgroundTransparency = outline and 1 or 0,
            Position = UDim2.new(x / 24, 0, y / 24, 0),
            Size = UDim2.new(width / 24, 0, height / 24, 0),
        })
        if radius then corner(shape, radius) end
        if outline then
            if variant == "Duotone" then
                local depth = create("UIStroke", {Thickness = strokeWidth + 1, Transparency = .62, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, shape)
                paint(depth, "Color")
            end
            local stroke = create("UIStroke", {Thickness = strokeWidth, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Transparency = 0}, shape)
            paint(stroke, "Color")
        else
            paint(shape, "BackgroundColor3")
            if variant == "Duotone" then
                create("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(150,150,150)), Rotation = 45}, shape)
            end
        end
        return shape
    end

    local function circle(cx, cy, diameter, outline)
        local shape = rect(cx - diameter / 2, cy - diameter / 2, diameter, diameter, outline, 0)
        local rounding = shape:FindFirstChildOfClass("UICorner")
        if rounding then rounding:Destroy() end
        corner(shape, 100)
        return shape
    end

    local function path(points)
        for index = 1, #points - 1 do
            local a, b = points[index], points[index + 1]
            line(a[1], a[2], b[1], b[2])
        end
    end

    return {line = line, rect = rect, circle = circle, path = path}
end

local function drawIcon(root, color, thickness, window, token, name, variant)
    local p = iconBuilder(window, root, color, token, thickness, variant)
    local line, rect, circle, path = p.line, p.rect, p.circle, p.path
    local function cubic(startPoint, controlA, controlB, endPoint, segments)
        local points = {}
        for index = 0, segments do
            local t = index / segments
            local u = 1 - t
            local x = u*u*u*startPoint[1] + 3*u*u*t*controlA[1] + 3*u*t*t*controlB[1] + t*t*t*endPoint[1]
            local y = u*u*u*startPoint[2] + 3*u*u*t*controlA[2] + 3*u*t*t*controlB[2] + t*t*t*endPoint[2]
            points[#points + 1] = {x, y}
        end
        path(points)
        return points
    end
    local function ellipse(cx, cy, radiusX, radiusY, segments, rotation)
        local points = {}
        local angleOffset = math.rad(rotation or 0)
        for index = 0, segments do
            local angle = math.pi * 2 * index / segments
            local x, y = math.cos(angle) * radiusX, math.sin(angle) * radiusY
            points[#points + 1] = {
                cx + x * math.cos(angleOffset) - y * math.sin(angleOffset),
                cy + x * math.sin(angleOffset) + y * math.cos(angleOffset),
            }
        end
        path(points)
        return points
    end
    local function arc(cx, cy, radiusX, radiusY, startAngle, endAngle, segments)
        local points = {}
        for index = 0, segments do
            local angle = math.rad(startAngle + (endAngle - startAngle) * index / segments)
            points[#points + 1] = {cx + math.cos(angle) * radiusX, cy + math.sin(angle) * radiusY}
        end
        path(points)
        return points
    end

    if name == "home" then
        path({{3,11},{12,4},{21,11}});rect(5,10,14,10,true,2)
        rect(7,13,3,3,false,1);rect(14,13,3,3,false,1);rect(10,15,4,5,false,1)
    elseif name == "sliders" then
        line(3,6,21,6);line(3,12,21,12);line(3,18,21,18)
        circle(8,6,5,true);circle(15,12,5,true);circle(10,18,5,true)
    elseif name == "palette" then
        cubic({10,3.5},{6,3.5},{3.5,7},{3.5,11},5)
        cubic({3.5,11},{3.5,16},{7.5,20.5},{12,20.5},6)
        cubic({12,20.5},{15,20.5},{17,18.5},{17,16.5},4)
        cubic({17,16.5},{17,14.5},{15,13.5},{14.2,12.2},4)
        cubic({14.2,12.2},{13.2,10.6},{15,9.4},{17,9.4},4)
        cubic({17,9.4},{19,9.4},{20.5,8.5},{20.5,7.2},3)
        cubic({20.5,7.2},{20.5,5.1},{17,3.5},{13,3.5},5)
        path({{13,3.5},{10,3.5}})
        circle(8,8,2.2,false);circle(13,6.8,2.2,false);circle(17,8,2.2,false);circle(8,13,2.2,false)
    elseif name == "save" then
        path({{4,3},{17,3},{21,7},{21,21},{3,21},{3,4},{4,3}})
        line(7,4,7,9);line(7,9,16,9);rect(8,13,8,6,true,1);line(11,4,11,8)
    elseif name == "code" then
        path({{8,6},{3,12},{8,18}}); path({{16,6},{21,12},{16,18}}); line(14,4,10,20)
    elseif name == "search" then
        circle(10,10,12,true); line(14.5,14.5,21,21)
    elseif name == "close" then
        line(5,5,19,19); line(19,5,5,19)
    elseif name == "check" then
        path({{4,12},{10,18},{20,6}})
    elseif name == "chevron-down" then
        path({{5,9},{12,16},{19,9}})
    elseif name == "chevron-right" then
        path({{9,5},{16,12},{9,19}})
    elseif name == "settings" then
        local teeth = {}
        for index = 0, 31 do
            local angle = -math.pi / 2 + index * math.pi * 2 / 32
            local toothPhase = index % 4
            local radius = (toothPhase == 0 or toothPhase == 1) and 8.5 or 7.1
            teeth[#teeth + 1] = {12 + math.cos(angle) * radius, 12 + math.sin(angle) * radius}
        end
        teeth[#teeth + 1] = teeth[1]
        path(teeth)
        circle(12,12,7.4,true);circle(12,12,2.2,false)
    elseif name == "user" then
        circle(12,8,6.5,true)
        cubic({4,20},{4,16},{7,14.5},{12,14.5},7)
        cubic({12,14.5},{17,14.5},{20,16},{20,20},7)
        line(4,20,20,20)
    elseif name == "folder" then
        path({{3,8},{9,8},{11,10},{21,10},{20,19},{4,19},{3,8}})
        cubic({4,8},{4,6},{5,5},{7,5},3);line(7,5,10,5);line(10,5,12,8)
    elseif name == "download" then
        line(12,3,12,15); path({{7,11},{12,16},{17,11}}); line(4,20,20,20)
    elseif name == "upload" then
        line(12,21,12,9); path({{7,13},{12,8},{17,13}}); line(4,4,20,4)
    elseif name == "refresh" then
        local function arc(cx, cy, radius, startAngle, endAngle, segments)
            local points = {}
            for index = 0, segments do
                local angle = math.rad(startAngle + (endAngle - startAngle) * index / segments)
                points[#points + 1] = {cx + math.cos(angle) * radius, cy + math.sin(angle) * radius}
            end
            path(points)
            return points[#points]
        end
        local function arrowHead(tip, tangentAngle)
            local angle = math.rad(tangentAngle)
            local directionX, directionY = -math.sin(angle), math.cos(angle)
            local normalX, normalY = -directionY, directionX
            local baseX, baseY = tip[1] - directionX * 2.6, tip[2] - directionY * 2.6
            path({
                {baseX + normalX * 1.55, baseY + normalY * 1.55},
                {tip[1], tip[2]},
                {baseX - normalX * 1.55, baseY - normalY * 1.55},
            })
        end
        arrowHead(arc(12, 12, 7.5, 205, 330, 14), 330)
        arrowHead(arc(12, 12, 7.5, 30, 150, 14), 150)
    elseif name == "bell" then
        cubic({5,17},{7,15},{7,11},{7,9},5);cubic({7,9},{7,5},{10,4},{12,4},5)
        cubic({12,4},{15,4},{17,6},{17,9},5);cubic({17,9},{17,12},{17,15},{19,17},5)
        path({{19,17},{5,17}});cubic({10,19},{10,21},{14,21},{14,19},4)
    elseif name == "info" then
        circle(12,12,18,true); circle(12,7,2,false); line(12,11,12,17)
    elseif name == "plus" then
        line(12,4,12,20); line(4,12,20,12)
    elseif name == "minus" then
        line(4,12,20,12)
    elseif name == "farm" then
        path({{4,11},{12,5},{20,11},{20,19},{4,19},{4,11}})
        line(4,11,20,11);rect(7,12,10,7,true,1);rect(10,14,4,5,false,1)
        line(7,7,7,5);line(7,5,10,5)
        path({{3,21},{8,20},{12,21},{16,20},{21,21}})
    elseif name == "panel" then
        rect(3,4,18,16,true,2);line(3,9,21,9);line(12,9,12,20);circle(6,6.5,1,false);circle(9,6.5,1,false)
    elseif name == "inventory" then
        path({{4,8},{7,5},{17,5},{20,8},{20,19},{4,19},{4,8}})
        line(4,9,20,9);path({{9,9},{9,12},{15,12},{15,9}});line(8,15,8,17);line(16,15,16,17)
    elseif name == "harvest" then
        path({{5,13},{19,13},{17,20},{7,20},{5,13}});line(6,16,18,16);line(7,18,17,18)
        line(12,13,12,5);cubic({12,9},{9,5},{7,6},{7,9},5);cubic({12,8},{15,4},{18,5},{18,8},5)
        path({{9,10},{12,7},{15,9}})
    elseif name == "seed" then
        ellipse(12,12,5.7,8,16,-27)
        cubic({8,16},{10,13},{13,9},{16,7},7)
    elseif name == "sprout" then
        line(12,20,12,11)
        cubic({12,15},{9,15},{6,12},{6,9},6);cubic({6,9},{10,8},{13,10},{13,14},6)
        cubic({12,12},{13,8},{16,5},{20,5},6);cubic({20,5},{20,10},{17,14},{12,14},6)
        line(5,20,19,20)
    elseif name == "watering-can" then
        path({{5,11},{16,11},{15,19},{7,19},{5,11}})
        cubic({7,11},{6,7},{8,5},{11,5},5);cubic({11,5},{14,5},{15,7},{15,11},5)
        path({{16,12},{19,10},{21,11},{17,15}})
        line(19,11,20,9);line(20,9,21,9);circle(20,16,1.6,false);circle(18,19,1.6,false)
    elseif name == "shovel" then
        line(12,4,12,15);path({{8,15},{16,15},{18,18},{12,21},{6,18},{8,15}})
        line(9,5,15,5);line(10,4,14,4)
    elseif name == "tools" then
        -- Open jaw wrench with a round handle; the shaft stays clear of both ends.
        path({{4,4},{6,3},{10,7},{8,9},{7,8},{6,9},{8,11},{10,9},{12,11}})
        line(10,9,16,15);line(12,11,18,17);circle(18,18,5,true)
    elseif name == "tractor" then
        circle(7,18,8,true);circle(18,18,6,true);circle(7,18,1.5,false)
        rect(7,5,7,8,true,1)
        path({{14,10},{18,10},{21,12},{21,14},{14,14}})
    elseif name == "map" then
        path({{3,6},{9,4},{15,6},{21,4},{21,18},{15,20},{9,18},{3,20},{3,6}})
        line(9,4,9,18);line(15,6,15,20)
    elseif name == "menu" then
        line(4,6,20,6);line(4,12,20,12);line(4,18,20,18)
    elseif name == "arrow-left" then
        path({{14,5},{7,12},{14,19}});line(7,12,21,12)
    elseif name == "arrow-right" then
        path({{10,5},{17,12},{10,19}});line(3,12,17,12)
    elseif name == "minimize" then
        line(4,18,20,18)
    elseif name == "maximize" then
        rect(4,4,16,16,true,1)
    elseif name == "restore" then
        path({{8,8},{8,4},{20,4},{20,16},{16,16}});rect(4,8,12,12,true,1)
    elseif name == "resize" then
        path({{5,19},{19,5}});path({{12,5},{19,5},{19,12}});path({{5,12},{5,19},{12,19}})
    elseif name == "window" then
        rect(3,4,18,16,true,2);line(3,9,21,9);circle(6,6.5,1,false);circle(9,6.5,1,false)
    elseif name == "automation" then
        circle(9,13,11,true);circle(9,13,3,false);circle(18,7,5,true);line(9,3,9,5);line(9,20,9,21);line(3,13,5,13);line(14,13,16,13)
    elseif name == "play" then
        path({{7,4},{19,12},{7,20},{7,4}})
    elseif name == "pause" then
        rect(6,4,4,16,false,1);rect(14,4,4,16,false,1)
    elseif name == "stop" then
        rect(5,5,14,14,false,2)
    elseif name == "bolt" then
        path({{14,3},{7,12},{11,12},{9,21},{17,11},{13,11},{14,3}})
    elseif name == "shield" then
        path({{12,3},{20,6},{19,12}})
        cubic({19,12},{18,16},{15,19},{12,21},7)
        cubic({12,21},{9,19},{6,16},{5,12},7)
        path({{5,12},{4,6},{12,3}})
    elseif name == "key" then
        circle(8,9,9,true);line(11,12,20,21);line(16,17,18,15);line(18,19,20,17)
    elseif name == "lock" then
        rect(4,10,16,11,true,2);path({{7,10},{7,7},{8,4},{10,3},{14,3},{16,5},{17,8},{17,10}});circle(12,15,2,false);line(12,16,12,18)
    elseif name == "unlock" then
        rect(4,10,16,11,true,2);path({{7,10},{7,7},{8,4},{10,3},{14,3},{16,5},{16,7}});circle(12,15,2,false);line(12,16,12,18)
    elseif name == "coins" then
        circle(8,8,9,true);circle(16,16,9,true);circle(8,8,2,false);circle(16,16,2,false)
    elseif name == "gift" then
        rect(4,10,16,11,true,2);line(12,10,12,21);line(3,10,21,10);rect(3,7,18,4,true,1);path({{12,7},{8,7},{6,5},{7,3},{9,3},{12,7},{15,3},{17,3},{18,5},{16,7},{12,7}})
    elseif name == "teleport" then
        ellipse(12,12,5.5,8.5,16,0);line(3,12,17,12);path({{17,8},{21,12},{17,16}})
    elseif name == "target" then
        circle(12,12,18,true);circle(12,12,10,true);circle(12,12,2,false);line(12,3,12,5);line(19,12,21,12);line(12,19,12,21);line(3,12,5,12)
    elseif name == "chart" then
        line(4,4,4,20);line(4,20,21,20);path({{6,16},{10,12},{13,14},{19,7}});path({{15,7},{19,7},{19,11}})
    elseif name == "chart-bar" then
        line(4,4,4,20);line(4,20,21,20);rect(7,13,3,7,false,1);rect(12,9,3,11,false,1);rect(17,5,3,15,false,1)
    elseif name == "clock" then
        circle(12,12,18,true);line(12,6,12,12);line(12,12,17,15)
    elseif name == "timer" then
        circle(12,13,16,true);line(12,7,12,13);line(12,13,16,15);line(9,3,15,3);line(12,3,12,5);line(18,6,20,4)
    elseif name == "compass" then
        circle(12,12,19,true);path({{15,7},{13,13},{7,17},{9,11},{15,7}});circle(12,12,2,false)
    elseif name == "heart" then
        cubic({12,20},{9,17},{3,13},{3,9},7)
        cubic({3,9},{3,4},{9,4},{12,9},7)
        cubic({12,9},{15,4},{21,4},{21,9},7)
        cubic({21,9},{21,13},{15,17},{12,20},7)
    elseif name == "star" then
        path({{12,3},{14.2,9},{20.8,9.5},{15.7,13.5},{17.5,20},{12,16.4},{6.5,20},{8.3,13.5},{3.2,9.5},{9.8,9},{12,3}})
    elseif name == "eye" then
        cubic({3,12},{7,4.5},{17,4.5},{21,12},10);cubic({21,12},{17,19.5},{7,19.5},{3,12},10)
        circle(12,12,6.5,true);circle(12,12,2.4,false)
    elseif name == "eye-off" then
        cubic({3,12},{7,4.5},{17,4.5},{21,12},10);cubic({21,12},{17,19.5},{7,19.5},{3,12},10)
        line(5,5,19,19)
    elseif name == "filter" then
        path({{3,4},{21,4},{14,12},{14,19},{10,21},{10,12},{3,4}})
    elseif name == "sort" then
        path({{7,4},{7,20},{4,17}});path({{7,20},{10,17}});path({{17,20},{17,4},{14,7}});path({{17,4},{20,7}})
    elseif name == "check-circle" then
        circle(12,12,18,true);path({{7,12},{10,15},{17,8}})
    elseif name == "alert" then
        path({{12,4},{21,20},{3,20},{12,4}});line(12,9,12,14);circle(12,17,1.8,false)
    elseif name == "help" then
        cubic({8,8},{8,4.5},{16,3.5},{16,7.5},8)
        cubic({16,7.5},{16,10},{12,10.5},{12,13},5);circle(12,18,2,false)
    elseif name == "copy" then
        rect(8,4,12,15,true,2);path({{6,8},{4,8},{4,20},{15,20},{15,19}})
    elseif name == "clipboard" then
        rect(5,5,14,17,true,2);rect(9,3,6,4,false,1);line(8,11,16,11);line(8,15,16,15);line(8,18,13,18)
    elseif name == "trash" then
        path({{6,7},{7,20},{17,20},{18,7}});line(4,6,20,6);line(9,4,15,4);line(10,10,10,17);line(14,10,14,17)
    elseif name == "edit" then
        path({{4,17},{15,6},{19,10},{8,20},{4,21},{4,17}});path({{13,8},{17,12}});line(14,6,17,3);line(19,5,21,7)
    elseif name == "wand" then
        line(5,19,18,6);path({{17,3},{18,5},{21,6},{18,7},{17,9},{16,7},{14,6},{16,5},{17,3}});line(5,5,5,9);line(3,7,7,7);line(20,15,20,19);line(18,17,21,17)
    elseif name == "wifi" then
        arc(12,20,3,3,-135,-45,4);arc(12,20,6,6,-135,-45,6);arc(12,20,9,9,-135,-45,8);circle(12,19,2.2,false)
    elseif name == "globe" then
        ellipse(12,12,9,9,16,0);ellipse(12,12,4,9,16,0);line(3,12,21,12)
    elseif name == "link" then
        arc(7,12,4,7,45,315,12);arc(17,12,4,7,225,495,12);line(10,12,14,12)
    elseif name == "mail" then
        rect(3,6,18,12,true,2);path({{4,7},{12,13},{20,7}})
    elseif name == "message" then
        cubic({5,5},{4,5},{4,6},{4,7},3);line(4,7,4,15)
        cubic({4,15},{4,16},{5,17},{6,17},3);line(6,17,8,17);line(8,17,8,20);line(8,20,12,17)
        line(12,17,18,17);cubic({18,17},{19,17},{20,16},{20,15},3);line(20,15,20,7)
        cubic({20,7},{20,6},{19,5},{18,5},3);line(18,5,5,5);line(8,10,16,10);line(8,13,14,13)
    elseif name == "terminal" then
        rect(3,4,18,16,true,2);path({{7,9},{10,12},{7,15}});line(13,15,17,15)
    elseif name == "bug" then
        circle(12,13,10,true);circle(12,6,5,true);line(12,3,12,2);line(8,11,5,9);line(16,11,19,9)
        line(7,14,4,14);line(17,14,20,14);line(8,17,6,19);line(16,17,18,19)
    elseif name == "cpu" then
        rect(6,6,12,12,true,2);rect(9,9,6,6,true,1)
        for _, offset in ipairs({8,12,16}) do
            line(offset,3,offset,6);line(offset,18,offset,21)
            line(3,offset,6,offset);line(18,offset,21,offset)
        end
    elseif name == "server" then
        rect(4,4,16,7,true,2);rect(4,13,16,7,true,2)
        circle(7,7.5,2,false);circle(7,16.5,2,false);line(11,7.5,17,7.5);line(11,16.5,17,16.5)
    elseif name == "database" then
        ellipse(12,6,8,3,12,0);line(4,6,4,18);line(20,6,20,18)
        ellipse(12,18,8,3,12,0);arc(12,11,8,3,0,180,8)
    elseif name == "cloud" then
        cubic({6,18},{3,18},{3,15},{4,13},5);cubic({4,13},{4,10},{7,9},{9,10},5)
        cubic({9,10},{10,5},{15,4},{18,8},6);cubic({18,8},{21,8},{22,11},{20,14},5)
        cubic({20,14},{22,18},{19,19},{17,19},5);line(17,19,6,19);line(6,19,6,18)
    elseif name == "cloud-download" then
        cubic({6,12},{3,12},{3,9},{4,7},5);cubic({4,7},{4,4},{7,3},{9,4},5)
        cubic({9,4},{10,2.5},{15,2.5},{17,5},6);cubic({17,5},{21,5},{22,8},{20,11},5)
        cubic({20,11},{22,14},{19,15},{17,15},5);line(17,15,6,15);line(6,15,6,12)
        line(12,9,12,18);path({{8,15},{12,19},{16,15}})
    elseif name == "camera" then
        rect(3,7,18,13,true,2);path({{7,7},{9,4},{15,4},{17,7}})
        circle(13,13,7,true);circle(13,13,2,false);circle(18,9,1.6,false)
    elseif name == "image" then
        rect(3,4,18,16,true,2);circle(8,9,2.4,false);path({{5,18},{10,12},{13,15},{16,11},{20,17}})
    elseif name == "music" then
        line(10,6,10,17);line(10,6,18,4);line(18,4,18,15);circle(7,18,5,true);circle(15,16,5,true)
    elseif name == "volume" then
        path({{4,10},{8,10},{13,6},{13,18},{8,14},{4,14},{4,10}})
        arc(12,12,6,7,-55,55,5);arc(12,12,9,10,-55,55,6)
    elseif name == "volume-off" then
        path({{4,10},{8,10},{13,6},{13,18},{8,14},{4,14},{4,10}});line(16,9,21,15);line(21,9,16,15)
    elseif name == "sun" then
        circle(12,12,8,true)
        for _, angle in ipairs({0,45,90,135,180,225,270,315}) do
            local radians=math.rad(angle)
            line(12+math.cos(radians)*6.5,12+math.sin(radians)*6.5,12+math.cos(radians)*9,12+math.sin(radians)*9)
        end
    elseif name == "moon" then
        cubic({15,4},{7,4},{4,9},{5,14},8);cubic({5,14},{6,20},{13,21},{18,17},8)
        cubic({18,17},{13,17},{9,13},{9,9},7);cubic({9,9},{9,7},{11,5},{15,4},7)
    elseif name == "gamepad" then
        cubic({7,8},{4,8},{3,11},{3,15},5);cubic({3,15},{3,19},{6,20},{8,17},5)
        line(8,17,16,17);cubic({16,17},{18,20},{21,19},{21,15},5)
        cubic({21,15},{21,11},{20,8},{17,8},5);line(17,8,7,8)
        line(7,11,7,15);line(5,13,9,13);circle(16,12,2,false);circle(18,15,2,false)
    elseif name == "trophy" then
        path({{7,4},{17,4},{17,9},{16,14},{13,16},{11,16},{8,14},{7,9},{7,4}})
        cubic({7,6},{3,5},{3,12},{8,13},5);cubic({17,6},{21,5},{21,12},{16,13},5)
        line(12,16,12,19);line(8,20,16,20);line(9,18,15,18)
    elseif name == "rocket" then
        path({{12,3},{16,6},{18,11},{17,16},{12,19},{7,16},{6,11},{8,6},{12,3}})
        circle(12,9,4,true);path({{7,14},{4,17},{4,20},{9,17}});path({{17,14},{20,17},{20,20},{15,17}})
        path({{10,19},{12,21},{14,19}})
    elseif name == "backpack" then
        cubic({9,6},{9,2},{15,2},{15,6},8)
        rect(5,6,14,15,true,4)
        path({{5,9},{3,10},{3,18},{5,19}});path({{19,9},{21,10},{21,18},{19,19}})
        rect(8,13,8,5,true,1)
    elseif name == "sword" then
        path({{15,4},{19,8},{11,16},{8,13},{15,4}});line(8,13,5,16);line(5,15,9,19);line(8,20,12,16)
        line(12,10,16,14);line(13,9,17,13)
    elseif name == "flag" then
        line(5,3,5,20);path({{6,5},{20,7},{16,11},{20,15},{6,13},{6,5}})
    end
end

local builtinNames = {
    "home", "sliders", "palette", "save", "code", "search", "close", "check",
    "chevron-down", "chevron-right", "settings", "user", "folder", "download",
    "upload", "refresh", "bell", "info", "plus", "minus",
    "farm", "panel", "inventory", "harvest", "seed", "sprout", "watering-can",
    "shovel", "tools", "tractor", "map", "menu", "arrow-left", "arrow-right",
    "minimize", "maximize", "restore", "resize", "window",
    "automation", "play", "pause", "stop", "bolt", "shield", "key", "lock",
    "unlock", "coins", "gift", "teleport", "target", "chart", "chart-bar",
    "clock", "timer", "compass", "heart", "star", "eye", "eye-off", "filter",
    "sort", "check-circle", "alert", "help", "copy", "clipboard", "trash", "edit", "wand",
    "wifi", "globe", "link", "mail", "message", "terminal", "bug", "cpu", "server", "database",
    "cloud", "cloud-download", "camera", "image", "music", "volume", "volume-off", "sun", "moon",
    "gamepad", "trophy", "rocket", "backpack", "sword", "flag",
}
local iconVariants={"Outline","Soft","Duotone"}
Library._iconIds=Library._iconIds or {}
Library._iconNamesById=Library._iconNamesById or {}
Library._nextCustomIconId=math.max(Library._nextCustomIconId or 1000,1000)

local function bindIconId(name,id)
    local oldId=Library._iconIds[name]
    if oldId and Library._iconNamesById[oldId]==name then Library._iconNamesById[oldId]=nil end
    local oldName=Library._iconNamesById[id]
    if oldName and oldName~=name then Library._iconIds[oldName]=nil end
    Library._iconIds[name]=id
    Library._iconNamesById[id]=name
end

local builtinSet={}
for id,iconName in ipairs(builtinNames)do
    builtinSet[iconName]=true
    bindIconId(iconName,id)
end

for _, iconName in ipairs(builtinNames) do
    local registeredName = iconName
    Library._icons[registeredName] = function(root, color, thickness, window, token, variant)
        drawIcon(root, color, thickness, window, token, registeredName, variant)
    end
end

local unassignedCustomNames={}
local highestCustomId=999
for name,builder in pairs(Library._icons)do
    if not builtinSet[name] then
        local id=Library._iconIds[name]
        if type(id)=="number" and id%1==0 and id>=1000 and Library._iconNamesById[id]==name then
            highestCustomId=math.max(highestCustomId,id)
        else
            unassignedCustomNames[#unassignedCustomNames+1]=name
        end
    end
end
table.sort(unassignedCustomNames)
Library._nextCustomIconId=math.max(Library._nextCustomIconId,highestCustomId+1)
for _,name in ipairs(unassignedCustomNames)do
    bindIconId(name,Library._nextCustomIconId)
    Library._nextCustomIconId+=1
end

local function validIconName(name)
    return type(name) == "string"
        and #name > 0
        and #name <= 48
        and name:match("^[a-z][a-z0-9%-]*$") ~= nil
        and not name:find("--", 1, true)
        and name:sub(-1) ~= "-"
end

function Library:GetIconNames()
    local names = {}
    for name in pairs(self._icons) do names[#names + 1] = name end
    table.sort(names)
    return names
end

function Library:GetIconId(name)
    if type(name)~="string" or type(self._icons[name])~="function" then return nil end
    local id=self._iconIds and self._iconIds[name]
    if type(id)=="number" and id%1==0 and self._iconNamesById[id]==name then return id end
    return nil
end

function Library:GetIconName(idOrName)
    if type(idOrName)=="string" then
        return type(self._icons[idOrName])=="function" and idOrName or nil
    end
    if type(idOrName)~="number" or idOrName~=idOrName or math.abs(idOrName)==math.huge or idOrName%1~=0 then return nil end
    local name=self._iconNamesById and self._iconNamesById[idOrName]
    if name and type(self._icons[name])=="function" and self._iconIds[name]==idOrName then return name end
    return nil
end

function Library:GetIconCatalogue()
    local catalogue={}
    for name,builder in pairs(self._icons)do
        local id=self:GetIconId(name)
        if type(builder)=="function" and id then catalogue[#catalogue+1]={Id=id,Name=name} end
    end
    table.sort(catalogue,function(a,b)return a.Id<b.Id end)
    return catalogue
end

function Library:GetIconVariants()
    return table.clone(iconVariants)
end

function Library:RegisterIcon(name, drawFunction)
    assert(validIconName(name), "Icon name must be lowercase kebab-case")
    assert(type(drawFunction) == "function", "Icon builder must be a function")
    assert(self._icons[name] == nil, "Icon name is already registered: " .. name)
    self._icons[name] = drawFunction
    bindIconId(name,self._nextCustomIconId)
    self._nextCustomIconId+=1
    return self
end

function Library:UnregisterIcon(name, expectedDraw)
    if not validIconName(name) then return false end
    local current = self._icons[name]
    if current == nil or (expectedDraw ~= nil and current ~= expectedDraw) then return false end
    self._icons[name] = nil
    local id=self._iconIds[name]
    self._iconIds[name]=nil
    if id and self._iconNamesById[id]==name then self._iconNamesById[id]=nil end
    return true
end

function Library:Icon(parent, name, options)
    assert(typeof(parent) == "Instance", "Icon parent must be an Instance")
    local iconName=self:GetIconName(name)
    assert(iconName,"Unknown icon ID or name: "..tostring(name))
    options = options or {}
    assert(type(options) == "table", "Icon options must be a table")
    local allowed = {Size=true, Color=true, Thickness=true, Name=true, Position=true, AnchorPoint=true, Window=true, Token=true, Variant=true, IconVariant=true}
    for key in pairs(options) do assert(allowed[key], "Unknown icon option: " .. tostring(key)) end
    assert(not (options.Variant~=nil and options.IconVariant~=nil),"Use Variant or IconVariant, not both")
    local builder = self._icons[iconName]
    local size = options.Size == nil and 20 or options.Size
    local thickness = options.Thickness == nil and 2 or options.Thickness
    local variant = options.IconVariant
    if variant == nil then variant = options.Variant end
    if variant == nil then variant = "Outline" end
    assert(type(size) == "number" and size == size and size >= 12 and size <= 64, "Icon Size must be 12..64")
    assert(type(thickness) == "number" and thickness == thickness and thickness >= 1 and thickness <= 4, "Icon Thickness must be 1..4")
    assert(variant == "Outline" or variant == "Soft" or variant == "Duotone", "Icon Variant must be Outline, Soft or Duotone")
    assert(options.Color == nil or typeof(options.Color) == "Color3", "Icon Color must be a Color3")
    assert(options.Name == nil or (type(options.Name) == "string" and #options.Name > 0), "Icon Name must be a non-empty string")
    assert(options.Position == nil or typeof(options.Position) == "UDim2", "Icon Position must be a UDim2")
    assert(options.AnchorPoint == nil or typeof(options.AnchorPoint) == "Vector2", "Icon AnchorPoint must be a Vector2")
    local window = options.Window
    if window ~= nil then
        assert(type(window) == "table" and window.BindColor and not window.Destroyed, "Icon Window must be a live Gabibou window")
        assert(parent:IsDescendantOf(window.Gui), "Icon parent must belong to Icon Window")
    end
    local token = options.Token or "Muted"
    if window and options.Color == nil then
        assert(type(token) == "string" and window.Theme[token] ~= nil and typeof(window.Theme[token]) == "Color3", "Unknown icon theme token: " .. tostring(token))
    else
        assert(options.Token == nil or (type(token) == "string" and #token > 0), "Icon Token must be a string")
    end
    local drawColor = options.Color or (window and window.Theme[token]) or Color3.fromRGB(157, 162, 173)

    local root = create("Frame", {
        Name = options.Name or (string.gsub(iconName, "%-", " ") .. "Icon"),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoLocalize = false,
        ClipsDescendants = false,
        Size = UDim2.fromOffset(size, size),
        Position = options.Position or UDim2.new(),
        AnchorPoint = options.AnchorPoint or Vector2.new(),
    }, parent)
    root:SetAttribute("GabibouIconVariant",variant)
    local ok, problem = pcall(builder, root, drawColor, thickness, window, token, variant)
    if ok and window and options.Color == nil then
        ok, problem = pcall(function()
            for _, instance in ipairs(root:GetDescendants()) do
                if instance:IsA("GuiObject") and instance.BackgroundTransparency < 1 then
                    window:BindColor(instance, "BackgroundColor3", token)
                elseif instance:IsA("UIStroke") then
                    window:BindColor(instance, "Color", token)
                end
            end
        end)
    end
    if not ok then
        if window and not window.Destroyed then window:_ForgetTree(root) end
        root:Destroy()
        error("Icon builder failed for '" .. iconName .. "': " .. tostring(problem), 2)
    end
    if window then
        local tracked = {root}
        for _, instance in ipairs(root:GetDescendants()) do tracked[#tracked + 1] = instance end
        local cleaned = false
        root.Destroying:Connect(function()
            if cleaned then return end
            cleaned = true
            for _, instance in ipairs(tracked) do
                window._themeTargets[instance] = nil
                window._styleTargets[instance] = nil
                window:_CancelAnimation(instance)
            end
            table.clear(tracked)
        end)
    end
    return root
end

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

-- Optional window branding. Included in ui.luau's lexical scope by build.cjs.

local brandingDefaults = {
    Mode = "Initials",
    Placement = "TopLeft",
    Text = "G",
}

branding_for = function(options, base)
    assert(options == nil or type(options) == "table", "Branding must be a table")
    local result = table.clone(base or brandingDefaults)
    for key, value in pairs(options or {}) do
        assert(key == "Mode" or key == "Placement" or key == "Image" or key == "Text" or key == "UserId",
            "Unknown branding option: " .. tostring(key))
        result[key] = value
    end

    assert(result.Mode == "Avatar" or result.Mode == "Image" or result.Mode == "Initials",
        "Branding Mode must be Avatar, Image or Initials")
    assert(result.Placement == "TopLeft" or result.Placement == "TopRight" or
        result.Placement == "BottomRight" or result.Placement == "BothRight",
        "Invalid branding Placement")
    local textLength = type(result.Text) == "string" and utf8.len(result.Text) or nil
    assert(textLength and result.Text:match("%S") ~= nil and textLength <= 4,
        "Branding Text must contain 1..4 UTF-8 characters")
    if result.Image ~= nil then
        assert(type(result.Image) == "string" and #result.Image > 0 and #result.Image <= 256,
            "Branding Image must be a nonempty Roblox image content string")
        local assetId = result.Image:match("^rbxassetid://(%d+)$")
        local numericAssetId = assetId and tonumber(assetId)
        assert(assetId and #assetId <= 16 and Logic.finite(numericAssetId) and numericAssetId > 0,
            "Branding Image must use an rbxassetid:// asset")
    end
    if result.Mode == "Image" then
        assert(result.Image ~= nil, "Image mode requires Branding.Image")
    end
    if result.UserId ~= nil then
        assert(Logic.finite(result.UserId) and result.UserId >= 1 and result.UserId % 1 == 0 and result.UserId < 9007199254740992,
            "Branding UserId must be a positive integer")
    end
    return result
end

local function hasTopRight(placement)
    return placement == "TopRight" or placement == "BothRight"
end

local function hasBottomRight(placement)
    return placement == "BottomRight" or placement == "BothRight"
end

local function forgetAndDestroy(window, instance)
    if not instance then return end
    window:_ForgetTree(instance)
    instance:Destroy()
end

local function makeRightWidget(window, name, size, textSize)
    local frame = create("Frame", {
        Name = name,
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Active = false,
        Selectable = false,
        ZIndex = 7,
    }, window.Panel)
    window:_Rounded(frame, "ControlRadius")
    window:_Color(frame, "BackgroundColor3", "Raised")
    window:_Stroke(frame, "Border", 0.24)

    local highlight = create("Frame", {
        Name = "BrandHighlight",
        Position = UDim2.fromOffset(4, 1),
        Size = UDim2.new(1, -8, 0, 1),
        BackgroundTransparency = 0.58,
        BorderSizePixel = 0,
        ZIndex = 10,
    }, frame)
    window:_Color(highlight, "BackgroundColor3", "Accent")

    local label = create("TextLabel", {
        Name = "BrandInitials",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = bold,
        TextSize = textSize,
        Text = window.Branding.Text,
        TextColor3 = window.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 8,
    }, frame)
    window:_Style(label, "Font", "FontBold")
    window:_Color(label, "TextColor3", "Text")

    local image = create("ImageLabel", {
        Name = "BrandImage",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Image = "",
        ScaleType = Enum.ScaleType.Crop,
        Visible = false,
        ZIndex = 9,
    }, frame)
    window:_Rounded(image, "ControlRadius")
    return {Frame = frame, Image = image, Label = label, Highlight = highlight}
end

function Window:_CancelBranding()
    self._brandingVersion = (self._brandingVersion or 0) + 1
    local pending = self._brandingTask
    self._brandingTask = nil
    if pending then pcall(task.cancel, pending) end
end

function Window:_LayoutBranding(width, height, minimal, tiny)
    if not self.Mark then return end
    local branding = self.Branding or brandingDefaults
    local compactLogo = width < 320
    local showMark = branding.Placement == "TopLeft" and not compactLogo
    local showTop = hasTopRight(branding.Placement) and not compactLogo and not minimal and self.Layout.ShowHeader
    local showBottom = hasBottomRight(branding.Placement) and not compactLogo and not tiny and self.Layout.ShowFooter
    self.Mark.Visible = showMark
    self.Header.Size = UDim2.new(1, showTop and -188 or -112, 0, 60)

    local titleX = showMark and 50 or 0
    local titleRight = showMark and -54 or -4
    self.TitleLabel.Position = UDim2.fromOffset(titleX, 5)
    self.TitleLabel.Size = UDim2.new(1, titleRight, 0, 23)
    self._subtitle.Position = UDim2.fromOffset(titleX, 30)
    self._subtitle.Size = UDim2.new(1, titleRight, 0, 17)

    if self._brandTop then
        self._brandTop.Frame.Visible = showTop
        self._brandTop.Frame.Position = UDim2.new(1, -158, 0, 18)
    end
    if self._brandBottom then
        self._brandBottom.Frame.Visible = showBottom
        self._brandBottom.Frame.Position = UDim2.new(1, -68, 1, -34)
    end

    local footerHasLogo = showBottom
    self.Footer.Position = UDim2.new(0, 18, 1, -32)
    self.Footer.Size = UDim2.new(1, footerHasLogo and -102 or -36, 0, 22)
end

function Window:SetBranding(options)
    assert(not self.Destroyed, "Window is destroyed")
    local base
    if options ~= nil then base = self.Branding end
    local valid = branding_for(options, base)

    -- Validate fully before invalidating current assets or changing the UI.
    self:_CancelBranding()
    forgetAndDestroy(self, self._brandTop and self._brandTop.Frame)
    forgetAndDestroy(self, self._brandBottom and self._brandBottom.Frame)
    forgetAndDestroy(self, self._brandMarkImage)
    self._brandTop, self._brandBottom, self._brandMarkImage = nil, nil, nil
    if self._brandingError and self.LastError == self._brandingError then self.LastError = nil end
    self._brandingError = nil
    self.Branding = valid
    self.Mark.Text = valid.Text
    self.Mark.TextTransparency = 0
    self.Mark.ClipsDescendants = false

    if valid.Placement == "TopLeft" then
        self.Mark.ClipsDescendants = true
        local image = create("ImageLabel", {
            Name = "BrandImage",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Position = UDim2.fromScale(0, 0),
            Image = "",
            ScaleType = Enum.ScaleType.Crop,
            Visible = false,
            ZIndex = self.Mark.ZIndex + 1,
        }, self.Mark)
        corner(image, 11)
        self._brandMarkImage = image
    end
    if hasTopRight(valid.Placement) then
        self._brandTop = makeRightWidget(self, "BrandTopRight", 36, 15)
    end
    if hasBottomRight(valid.Placement) then
        self._brandBottom = makeRightWidget(self, "BrandBottomRight", 24, 10)
    end

    local targets = {}
    if self._brandMarkImage then
        targets[#targets + 1] = {Image = self._brandMarkImage, Label = self.Mark}
    end
    if self._brandTop then targets[#targets + 1] = self._brandTop end
    if self._brandBottom then targets[#targets + 1] = self._brandBottom end

    if valid.Mode == "Image" then
        for _, target in ipairs(targets) do
            target.Image.Image = valid.Image
            target.Image.Visible = true
            target.Label.TextTransparency = 1
        end
    elseif valid.Mode == "Avatar" then
        local version = self._brandingVersion
        local userId = valid.UserId or (Players.LocalPlayer and Players.LocalPlayer.UserId)
        if userId then
            self._brandingTask = task.defer(function()
                local content
                local ready = false
                for _ = 1, 12 do
                    if self.Destroyed or self._brandingVersion ~= version then return end
                    local ok, image, isReady = pcall(function()
                        return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                    end)
                    if not ok then break end
                    content, ready = image, isReady
                    if ready then break end
                    task.wait(0.25)
                end
                if self.Destroyed or self._brandingVersion ~= version then return end
                if ready and type(content) == "string" and content ~= "" then
                    for _, target in ipairs(targets) do
                        if target.Image.Parent then
                            target.Image.Image = content
                            target.Image.Visible = true
                            target.Label.TextTransparency = 1
                        end
                    end
                    if self.LastError == self._brandingError then self.LastError = nil end
                    self._brandingError = nil
                else
                    self._brandingError = "Avatar thumbnail unavailable"
                    self.LastError = self._brandingError
                end
                self._brandingTask = nil
            end)
        else
            self._brandingError = "Avatar thumbnail unavailable"
            self.LastError = self._brandingError
        end
    end

    self:_Layout()
    return self
end

-- Layout presets are ordinary tables. Advanced part overrides persist across reflow.
Library.Layout={TabPosition="Left",MobileTabPosition="Top",SidebarWidth=176,TabWidth=128,TabHeight=44,TabGap=9,TabIconSize=20,ContentPadding=20,ContentGap=20,HeaderHeight=76,FooterHeight=42,SearchHeight=44,SearchGap=12,PageTitleHeight=40,ButtonWidth=112,ButtonHeight=44,RowGap=12,SectionGap=12,ControlsPosition="Right",Draggable=true,Resizable=true,ShowSearch=true,ShowFooter=true,ShowHeader=true,ShowPageTitle=true}
local layoutRanges={SidebarWidth={96,360},TabWidth={64,400},TabHeight={44,96},TabGap={0,32},TabIconSize={12,40},ContentPadding={4,40},ContentGap={0,48},HeaderHeight={64,160},FooterHeight={32,96},SearchHeight={44,96},SearchGap={0,40},PageTitleHeight={28,80},ButtonWidth={58,400},ButtonHeight={44,120},RowGap={0,40},SectionGap={0,48}}
local function finiteUDim2(value)
    return typeof(value)=="UDim2" and Logic.finite(value.X.Scale) and Logic.finite(value.Y.Scale) and Logic.finite(value.X.Offset) and Logic.finite(value.Y.Offset)
end
local function validAnchor(value)
    return typeof(value)=="Vector2" and Logic.finite(value.X) and Logic.finite(value.Y) and value.X>=0 and value.X<=1 and value.Y>=0 and value.Y<=1
end
layout_for=function(options,base)
    assert(options==nil or type(options)=="table","Layout must be a table")
    local result=table.clone(base)
    for key,value in pairs(options or {})do
        assert(result[key]~=nil,"Unknown Layout option: "..tostring(key));result[key]=value
    end
    for key,range in pairs(layoutRanges)do assert(Logic.finite(result[key])and result[key]>=range[1]and result[key]<=range[2],"Layout."..key.." is out of range")end
    assert(result.TabPosition=="Left"or result.TabPosition=="Right"or result.TabPosition=="Top"or result.TabPosition=="Bottom","Invalid Layout.TabPosition")
    assert(result.MobileTabPosition=="Top"or result.MobileTabPosition=="Bottom","MobileTabPosition must be Top or Bottom")
    assert(result.ControlsPosition=="Left"or result.ControlsPosition=="Right"or result.ControlsPosition=="Below","Invalid ControlsPosition")
    for _,key in ipairs({"Draggable","Resizable","ShowSearch","ShowFooter","ShowHeader","ShowPageTitle"})do assert(type(result[key])=="boolean","Layout."..key.." must be boolean")end
    return result
end
local function itemLayout(options,tab)
    assert(options==nil or type(options)=="table","Item Layout must be a table")
    local result=table.clone(options or {})
    for key,value in pairs(result)do
        if key=="Order"then assert(Logic.finite(value)and value%1==0 and math.abs(value)<=100000,"Order must be an integer within -100000..100000")
        elseif key=="Width"then assert(Logic.finite(value)and value>=58 and value<=600,"Item Width must be 58..600")
        elseif key=="Height"then assert(Logic.finite(value)and value>=44 and value<=160,"Item Height must be 44..160")
        elseif key=="IconSize"and tab then assert(Logic.finite(value)and value>=12 and value<=40,"IconSize must be 12..40")
        elseif key=="Position"and not tab then assert(value=="Left"or value=="Right"or value=="Below","Control Position must be Left, Right or Below")
        else error("Unknown item Layout option: "..tostring(key),2)end
    end
    return result
end
control_layout_for=function(options)return itemLayout(options,false)end
tab_layout_for=function(options)return itemLayout(options,true)end
function Library:SetLayout(options)self.Layout=layout_for(options,self.Layout);return self end
function Window:SetLayout(options)
    assert(not self.Destroyed,"Window is destroyed")
    self.Layout=layout_for(options,self.Layout);self:_Layout();self:_RefreshNavigation(true)
    if self.CurrentTab then self:SelectTab(self.CurrentTab)end
    return self
end
function Window:SetPosition(position,anchor)
    assert(not self.Destroyed,"Window is destroyed")
    assert(finiteUDim2(position),"Position must be a finite UDim2")
    anchor=anchor or self._anchorPoint;assert(validAnchor(anchor),"AnchorPoint must be within 0..1")
    self._positionSpec=position;self._anchorPoint=anchor;self:_Layout();return self
end
function Window:GetParts()
    return {Panel=self.Panel,Header=self.Header,Tabs=self.Nav,Search=self.Search,PageTitle=self.PageTitle,Pages=self.PageHost,Footer=self.Footer,Reopen=self.Reopen,Notifications=self.ToastHost,Minimize=self._windowButtons[1],Close=self._windowButtons[2],Resize=self._resize}
end
function Window:SetPartLayout(name,options)
    assert(not self.Destroyed,"Window is destroyed")
    assert(type(name)=="string"and self:GetParts()[name],"Unknown window part")
    assert(type(options)=="table","Part layout must be a table")
    local valid=table.clone(self._partLayouts[name]or {})
    for key,value in pairs(options)do
        if key=="Position"or key=="Size"then assert(finiteUDim2(value),key.." must be a finite UDim2")
        elseif key=="AnchorPoint"then assert(validAnchor(value),"AnchorPoint must be within 0..1")
        elseif key=="Visible"then assert(type(value)=="boolean","Visible must be boolean")
        else error("Unsupported part layout property: "..tostring(key),2)end
        valid[key]=value
    end
    self._partLayouts[name]=valid;self:_Layout();return self
end
function Window:ResetPartLayout(name)
    assert(not self.Destroyed,"Window is destroyed")
    assert(type(name)=="string"and self:GetParts()[name],"Unknown window part")
    self._partLayouts[name]=nil
    local part=self:GetParts()[name];part.AnchorPoint=Vector2.zero
    if name=="Reopen"then part.Position=UDim2.new(0,14,.5,-22);part.Size=UDim2.fromOffset(108,44);part.Visible=self.Closed end
    self:_Layout();return self
end
function Window:_ApplyPartLayouts()
    local parts=self:GetParts()
    for name,properties in pairs(self._partLayouts)do
        for key,value in pairs(properties)do parts[name][key]=value end
    end
end
function Window:_Arrange(width,height,mobile,compact,tiny,minimal)
    local l=self.Layout
    local pad=l.ContentPadding
    local header=l.ShowHeader and not minimal and l.HeaderHeight or 0
    local footer=l.ShowFooter and not tiny and l.FooterHeight or (tiny and 12 or pad)
    local placement=mobile and l.MobileTabPosition or l.TabPosition
    local horizontal=placement=="Top"or placement=="Bottom"
    if self.HorizontalTabs~=horizontal then self.Nav.CanvasPosition=Vector2.zero end
    self.HorizontalTabs=horizontal;self.TabPlacement=placement
    local showSearch=l.ShowSearch and(not compact or UIS:GetFocusedTextBox()==self.Search)and not tiny
    local searchHeight=math.max(self.Responsive.TouchTarget,l.SearchHeight)
    local tabHeight=math.max(self.Responsive.TouchTarget,l.TabHeight)
    for _,tab in ipairs(self.Tabs)do tabHeight=math.max(tabHeight,tab.Layout.Height or 0)end
    local rail=math.min(l.SidebarWidth,math.max(1,width-pad*2-l.ContentGap-100))
    local railX=placement=="Right"and width-pad-rail or pad
    self.Header.Position=UDim2.fromOffset(pad,9);self.Header.Visible=l.ShowHeader and not minimal
    for _,button in ipairs(self._windowButtons)do button.Visible=l.ShowHeader and not minimal end
    self.Search.Visible=showSearch
    self.Search.Position=UDim2.fromOffset(horizontal and pad or railX,header+(horizontal and 0 or 16))
    self.Search.Size=UDim2.fromOffset(horizontal and math.max(1,width-pad*2)or rail,searchHeight)
    local navY=header+(showSearch and(searchHeight+l.SearchGap+(horizontal and 0 or 16))or 0)
    local contentX=(not horizontal and not tiny and placement=="Left")and pad+rail+l.ContentGap or pad
    local contentWidth=math.max(1,width-pad*2-((not horizontal and not tiny)and(rail+l.ContentGap)or 0))
    self.Nav.Visible=not tiny
    self.Nav.Position=UDim2.fromOffset(horizontal and pad or railX,placement=="Bottom"and math.max(header,height-footer-tabHeight-l.SearchGap)or navY)
    self.Nav.Size=UDim2.fromOffset(horizontal and math.max(1,width-pad*2)or rail,horizontal and tabHeight+4 or math.max(1,height-navY-footer))
    self.Nav.ScrollingDirection=horizontal and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y
    self.Nav.AutomaticCanvasSize=horizontal and Enum.AutomaticSize.X or Enum.AutomaticSize.Y
    self._navLayout.FillDirection=horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
    self._navLayout.Padding=UDim.new(0,l.TabGap)
    local showTitle=l.ShowPageTitle and not horizontal and not compact and not tiny
    self.PageTitle.Visible=showTitle;self.PageTitle.Position=UDim2.fromOffset(contentX,header+16);self.PageTitle.Size=UDim2.fromOffset(contentWidth,math.max(1,l.PageTitleHeight-12))
    local pageY
    if minimal then pageY=math.min(12,math.max(0,height-1))
    elseif tiny then pageY=l.ShowHeader and math.min(70,height-1)or pad
    elseif horizontal then pageY=placement=="Top"and navY+tabHeight+14 or header+(showSearch and searchHeight+l.SearchGap or pad)
    else pageY=header+(showTitle and l.PageTitleHeight+16 or 0)end
    local bottomReserve=footer+(placement=="Bottom"and not tiny and tabHeight+l.SearchGap or 0)
    self.PageHost.Position=UDim2.fromOffset(contentX,pageY);self.PageHost.Size=UDim2.fromOffset(contentWidth,math.max(1,height-pageY-bottomReserve))
    self.Footer.Visible=l.ShowFooter and not tiny
    for _,tab in ipairs(self.Tabs)do local flow=tab.Page:FindFirstChildOfClass("UIListLayout");if flow then flow.Padding=UDim.new(0,l.SectionGap)end end
end
function Control:SetLayout(options)
    assert(not self.Destroyed,"Control is destroyed")
    assert(type(options)=="table","Control layout must be a table")
    local merged=table.clone(self.Layout);for key,value in pairs(options or {})do merged[key]=value end
    self.Layout=control_layout_for(merged)
    if self.Layout.Order then self:SetOrder(self.Layout.Order)end
    self:_Layout(self.Window.Mobile);return self
end
function Control:SetOrder(order)
    assert(not self.Destroyed,"Control is destroyed")
    control_layout_for({Order=order});self.Layout.Order=order;self.Root.LayoutOrder=order*2
    if self._separator then self._separator.LayoutOrder=order*2-1 end
    self.Window:SearchFor(self.Window.Query)
    return self
end
function Control:GetParts()return {Root=self.Root,Title=self._title,Description=self._description,Input=self._input,Right=self.Right,Content=self.Content,Icon=self._icon}end
function Container:SetLayout(options)
    assert(not self.Destroyed and not self.Window.Destroyed,"Container is destroyed")
    assert(self.Tab==self,"Use section:SetOrder for sections")
    assert(type(options)=="table","Tab layout must be a table")
    local merged=table.clone(self.Layout);for key,value in pairs(options)do merged[key]=value end
    self.Layout=tab_layout_for(merged)
    if self.Layout.Order then self._button.LayoutOrder=self.Layout.Order end
    self.Window:_Layout();self.Window:_RefreshNavigation(true);return self
end
function Container:SetOrder(order)
    assert(not self.Destroyed and not self.Window.Destroyed,"Container is destroyed")
    tab_layout_for({Order=order})
    if self.Tab==self then self.Layout.Order=order;self._button.LayoutOrder=order
    else self.Root.LayoutOrder=order*2 end
    return self
end

-- Optional loader. Progress only advances after work supplied by the caller.
Library.Loaders={}
local Loader={};Loader.__index=Loader

local function loader_text(value,fallback,maximum)
    assert(value==nil or type(value)=="string","Loader text must be a string")
    return Logic.text(value or fallback,maximum)
end
local function copy_options(source)
    local result={}
    if source then for key,value in pairs(source)do result[key]=value end end
    return result
end
local function merge_theme(value,base)
    if value==nil then return theme_for(base or "Graphite") end
    if type(value)=="table" and type(base)=="table" then
        local merged=table.clone(base)
        for key,item in pairs(value)do merged[key]=item end
        return theme_for(merged)
    end
    return theme_for(value)
end
local function loader_options(options,base)
    assert(options==nil or type(options)=="table","Loading must be a table")
    local result=copy_options(base)
    for key,value in pairs(options or {})do result[key]=value end
    local player=Players.LocalPlayer;assert(player,"Loader runs on a Roblox client")
    result.Parent=result.Parent or (base and base.Parent) or player:FindFirstChildOfClass("PlayerGui")
    assert(typeof(result.Parent)=="Instance","Loader needs a GUI parent")
    result.Theme=merge_theme(options and options.Theme,base and base.Theme)
    result.Style=style_for(options and options.Style,base and base.Style or Library.Style)
    result.Title=loader_text(result.Title,"Gabibou UI",80)
    result.Subtitle=loader_text(result.Subtitle,"Preparing your interface",240)
    result.MarkText=loader_text(result.MarkText,"G",8)
    result.Variant=result.Variant or "Compact"
    assert(result.Variant=="Compact" or result.Variant=="Centered" or result.Variant=="Minimal","Loader Variant must be Compact, Centered or Minimal")
    result.Width=result.Width or 420
    result.Height=result.Height or (result.Variant=="Centered" and 300 or 216)
    result.Position=result.Position or UDim2.fromScale(.5,.5)
    result.AnchorPoint=result.AnchorPoint or Vector2.new(.5,.5)
    result.Padding=result.Padding or 24
    result.LogoSize=result.LogoSize or 46
    result.ShowPercentage=result.ShowPercentage==nil and true or result.ShowPercentage
    result.ShowLogo=result.ShowLogo==nil and true or result.ShowLogo
    result.ShowActivity=result.ShowActivity==nil and true or result.ShowActivity
    result.ShowSubtitle=result.ShowSubtitle==nil and true or result.ShowSubtitle
    result.ProgressHeight=result.ProgressHeight or 4
    result.BackgroundTransparency=result.BackgroundTransparency==nil and .3 or result.BackgroundTransparency
    result.MinimumDuration=result.MinimumDuration or 0
    result.ExitDuration=result.ExitDuration==nil and .18 or result.ExitDuration
    result.DisplayOrder=result.DisplayOrder or 100
    assert(Logic.finite(result.Width) and result.Width>=280 and result.Width<=560,"Loader Width must be 280..560")
    assert(Logic.finite(result.Height) and result.Height>=160 and result.Height<=480,"Loader Height must be 160..480")
    assert(typeof(result.Position)=="UDim2" and Logic.finite(result.Position.X.Scale) and Logic.finite(result.Position.X.Offset) and Logic.finite(result.Position.Y.Scale) and Logic.finite(result.Position.Y.Offset),"Position must be a finite UDim2")
    assert(typeof(result.AnchorPoint)=="Vector2" and Logic.finite(result.AnchorPoint.X) and Logic.finite(result.AnchorPoint.Y) and result.AnchorPoint.X>=0 and result.AnchorPoint.X<=1 and result.AnchorPoint.Y>=0 and result.AnchorPoint.Y<=1,"AnchorPoint must be a Vector2 in 0..1")
    assert(Logic.finite(result.Padding) and result.Padding>=12 and result.Padding<=40,"Padding must be 12..40")
    assert(Logic.finite(result.LogoSize) and result.LogoSize>=24 and result.LogoSize<=80,"LogoSize must be 24..80")
    assert(Logic.finite(result.BackgroundTransparency) and result.BackgroundTransparency>=0 and result.BackgroundTransparency<=1,"BackgroundTransparency must be 0..1")
    for _,key in ipairs({"ShowPercentage","ShowLogo","ShowActivity","ShowSubtitle"})do assert(type(result[key])=="boolean",key.." must be boolean")end
    assert(Logic.finite(result.ProgressHeight) and result.ProgressHeight>=2 and result.ProgressHeight<=12,"ProgressHeight must be 2..12")
    assert(Logic.finite(result.MinimumDuration) and result.MinimumDuration>=0 and result.MinimumDuration<=10,"MinimumDuration must be 0..10 seconds")
    assert(Logic.finite(result.ExitDuration) and result.ExitDuration>=0 and result.ExitDuration<=2,"ExitDuration must be 0..2 seconds")
    assert(Logic.finite(result.DisplayOrder) and result.DisplayOrder%1==0,"DisplayOrder must be an integer")
    assert(result.Logo==nil or result.Logo==false or type(result.Logo)=="string","Logo must be an image content string, Avatar, or false to clear")
    if result.Logo==false then result.Logo=nil end
    assert(result.OnComplete==nil or type(result.OnComplete)=="function","OnComplete must be a function")
    assert(result.OnError==nil or type(result.OnError)=="function","OnError must be a function")
    if result.ReducedMotion==nil then
        result.ReducedMotion=false;pcall(function()result.ReducedMotion=GuiService.ReducedMotionEnabled end)
    end
    assert(type(result.ReducedMotion)=="boolean","ReducedMotion must be boolean")
    return result
end

function Loader:_Layout()
    if self.Destroyed then return end
    local available=self.Root.AbsoluteSize
    local width=math.max(1,math.min(self.Options.Width,available.X-24))
    local height=math.max(1,math.min(self.Options.Height,available.Y-24))
    self.Card.Size=UDim2.fromOffset(width,height)
    local anchor=self.Options.AnchorPoint;local requested=self.Options.Position
    local left=available.X*requested.X.Scale+requested.X.Offset-anchor.X*width
    local top=available.Y*requested.Y.Scale+requested.Y.Offset-anchor.Y*height
    left=math.clamp(left,0,math.max(0,available.X-width));top=math.clamp(top,0,math.max(0,available.Y-height))
    self.Card.AnchorPoint=anchor
    self.Card.Position=UDim2.fromOffset(left+anchor.X*width,top+anchor.Y*height)
    local p=math.min(self.Options.Padding,math.max(0,(width-80)/2));local logo=self.Options.LogoSize
    local compact=height<math.max(180,logo+2*p+60)
    if compact then p=math.min(p,math.max(12,(height-120)/2))end
    local centered=self.Options.Variant=="Centered" and height>=260
    local minimal=self.Options.Variant=="Minimal"
    local showMark=self.Options.ShowLogo and not compact and not minimal and width>=2*p+logo+96
    if showMark then p=math.min(p,math.max(0,(width-logo-96)/2))end
    self.Mark.Visible=showMark
    self.Mark.AnchorPoint=Vector2.zero
    local textTop=p+2
    if centered and showMark then textTop=p+logo+14 end
    self.Title.TextXAlignment=centered and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
    self.Subtitle.TextXAlignment=self.Title.TextXAlignment
    self.Title.Position=UDim2.fromOffset(p+(showMark and not centered and logo+16 or 0),textTop)
    self.Title.Size=UDim2.new(1,-(2*p+(showMark and logo+16 or 0)),0,26)
    self.Subtitle.Visible=self.Options.ShowSubtitle and not compact
    self.Subtitle.Position=UDim2.fromOffset(p+(showMark and not centered and logo+16 or 0),textTop+32)
    self.Subtitle.Size=UDim2.new(1,-(2*p+(showMark and logo+16 or 0)),0,38)
    if centered then
        self.Title.Size=UDim2.new(1,-2*p,0,26)
        self.Subtitle.Size=UDim2.new(1,-2*p,0,38)
    end
    if showMark then self.Mark.Position=UDim2.fromOffset(centered and (width-logo)/2 or p,p);self.Mark.Size=UDim2.fromOffset(logo,logo) end
    self.Edge.Position=UDim2.fromOffset(p,0);self.Edge.Size=UDim2.new(1,-2*p,0,1)
    local statusHeight=20;local footerY=math.max(p,height-p-44)
    self.Percent.Visible=self.Options.ShowPercentage and height>=130 and width>=2*p+120
    self.StatusLabel.Visible=height>=130
    self.StatusLabel.Position=UDim2.fromOffset(p,footerY);self.StatusLabel.Size=UDim2.new(1,-(2*p+(self.Percent.Visible and 68 or 0)),0,statusHeight)
    self.Percent.Position=UDim2.new(1,-(p+52),0,footerY);self.Percent.Size=UDim2.fromOffset(52,statusHeight)
    self.Track.Position=UDim2.new(0,p,1,-(p+self.Options.ProgressHeight));self.Track.Size=UDim2.new(1,-2*p,0,self.Options.ProgressHeight)
    local contentTop=textTop+(self.Subtitle.Visible and 76 or 34)
    self.Content.Position=UDim2.fromOffset(p,contentTop)
    self.Content.Size=UDim2.new(1,-2*p,0,math.max(0,footerY-contentTop-12))
    for name,properties in pairs(self._partLayouts)do
        local part=self:GetParts()[name]
        for key,value in pairs(properties)do part[key]=value end
    end
end

function Loader:GetParts()
    if self.Destroyed then return nil end
    return {Overlay=self.Root,Card=self.Card,Logo=self.Mark,LogoImage=self.MarkImage,LogoText=self.MarkTextLabel,
        Title=self.Title,Subtitle=self.Subtitle,Status=self.StatusLabel,Percentage=self.Percent,Track=self.Track,
        Fill=self.Fill,Activity=self.Activity,Content=self.Content}
end
local loaderLayoutParts={Logo=true,Title=true,Subtitle=true,Status=true,Percentage=true,Track=true,Content=true}
function Loader:SetPartLayout(name,options)
    assert(not self.Destroyed and not self.Completed,"Loader is closed or completing")
    assert(loaderLayoutParts[name],"Unknown or fixed loader layout part")
    assert(type(options)=="table","Part layout must be a table")
    local staged=table.clone(self._partLayouts[name] or {})
    for key,value in pairs(options)do
        if key=="Position" or key=="Size"then assert(finiteUDim2(value),key.." must be a finite UDim2")
        elseif key=="AnchorPoint"then assert(validAnchor(value),"AnchorPoint must be within 0..1")
        elseif key=="Visible"then assert(type(value)=="boolean","Visible must be boolean")
        else error("Unsupported loader layout property: "..tostring(key),2)end
        staged[key]=value
    end
    self._partLayouts[name]=staged;self:_Layout();return self
end
function Loader:ResetPartLayout(name)
    assert(not self.Destroyed and not self.Completed,"Loader is closed or completing")
    assert(loaderLayoutParts[name],"Unknown or fixed loader layout part")
    self._partLayouts[name]=nil
    local part=self:GetParts()[name];part.AnchorPoint=Vector2.zero;part.Visible=true
    self:_Layout();return self
end
function Loader:Own(resource)
    assert(not self.Destroyed and not self.Completed,"Loader is closed or completing")
    local cleanup
    if type(resource)=="function"then cleanup=resource
    else
        local method
        for _,name in ipairs({"Disconnect","Cancel","Destroy"})do
            local ok,candidate=pcall(function()return resource[name]end)
            if ok and type(candidate)=="function"then method=candidate;break end
        end
        assert(method,"Own expects a cleanup function, connection, tween or destroyable resource")
        cleanup=function()method(resource)end
    end
    self._owned[#self._owned+1]=cleanup;return resource
end
function Loader:SetStatus(text)
    assert(not self.Destroyed and not self.Completed,"Loader is closed or completing")
    self.Status=loader_text(text,"",160);self.StatusLabel.Text=self.Status
    return self
end
function Loader:SetProgress(ratio,status)
    assert(not self.Destroyed and not self.Completed,"Loader is closed or completing")
    assert(Logic.finite(ratio) and ratio>=0 and ratio<=1,"Loader progress must be 0..1")
    local valid=status~=nil and loader_text(status,"",160) or nil
    self.Progress=ratio;self.Percent.Text=string.format("%d%%",math.floor(ratio*100+.5))
    if valid then self.Status=valid;self.StatusLabel.Text=valid end
    if self._progressTween then self._progressTween:Cancel();self._progressTween=nil end
    if self.Options.ReducedMotion then self.Fill.Size=UDim2.fromScale(ratio,1)
    else
        self._progressTween=TweenService:Create(self.Fill,TweenInfo.new(.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.fromScale(ratio,1)})
        self._progressTween:Play()
    end
    return self
end
function Loader:_SetActivity()
    if self._activityTween then self._activityTween:Cancel();self._activityTween=nil end
    local enabled=self.Options.ShowActivity and not self.Options.ReducedMotion and not self.Completed and not self.Destroyed
    self.Activity.Visible=enabled
    if enabled then
        self.Activity.Position=UDim2.fromScale(-.18,0)
        self._activityTween=TweenService:Create(self.Activity,TweenInfo.new(1.4,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1),{Position=UDim2.fromScale(1.18,0)})
        self._activityTween:Play()
    end
end
function Loader:_StartLogo()
    self._logoVersion=(self._logoVersion or 0)+1
    local version=self._logoVersion
    local old=self._avatarTask;self._avatarTask=nil
    if old and old~=coroutine.running() and coroutine.status(old)~="dead"then task.cancel(old)end
    self.MarkTextLabel.Text=self.Options.MarkText
    self.MarkImage.Image="";self.MarkImage.Visible=false;self.MarkTextLabel.Visible=true
    if not self.Options.Logo then return end
    if self.Options.Logo~="Avatar"then
        self.MarkImage.Image=self.Options.Logo;self.MarkImage.Visible=true;self.MarkTextLabel.Visible=false;return
    end
    local image=self.MarkImage;local text=self.MarkTextLabel
    self._avatarTask=task.defer(function()
        local ok,content=pcall(function()return Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)end)
        if self._logoVersion~=version then return end
        self._avatarTask=nil
        if self.Destroyed then return end
        if ok then image.Image=content;image.Visible=self.Options.ShowLogo;text.Visible=false
        else self.LastError="Avatar image could not be loaded" end
    end)
end
function Loader:_Apply(valid,logoChanged)
    self.Options=valid
    local theme,style=valid.Theme,valid.Style
    self.Gui.DisplayOrder=valid.DisplayOrder
    if self.Gui.Parent~=valid.Parent then release_focus(valid.Parent);self.Gui.Parent=valid.Parent end
    self.Root.BackgroundTransparency=valid.BackgroundTransparency
    self.Card.BackgroundColor3=theme.Background;self.Border.Color=theme.Border;self.Edge.BackgroundColor3=theme.Accent
    self.Mark.BackgroundColor3=theme.Raised;self.MarkTextLabel.TextColor3=theme.Text
    self.MarkTextLabel.Font=style.FontBold;self.MarkTextLabel.TextSize=style.TitleSize+2
    self.Title.Text=valid.Title;self.Title.Font=style.FontBold;self.Title.TextSize=style.TitleSize+2;self.Title.TextColor3=theme.Text
    self.Subtitle.Text=valid.Subtitle;self.Subtitle.Font=style.Font;self.Subtitle.TextSize=style.DescriptionSize;self.Subtitle.TextColor3=theme.Muted
    self.StatusLabel.Font=style.Font;self.StatusLabel.TextSize=style.DescriptionSize;self.StatusLabel.TextColor3=theme.Text
    self.Percent.Font=style.Font;self.Percent.TextSize=style.DescriptionSize;self.Percent.TextColor3=theme.Muted
    self.Track.BackgroundColor3=theme.Raised;self.Fill.BackgroundColor3=theme.Accent;self.Activity.BackgroundColor3=theme.Text
    self.CardCorner.CornerRadius=UDim.new(0,style.WindowRadius)
    self.MarkCorner.CornerRadius=UDim.new(0,math.min(12,valid.LogoSize/3))
    self.MarkImageCorner.CornerRadius=self.MarkCorner.CornerRadius
    self.TrackCorner.CornerRadius=UDim.new(0,3);self.FillCorner.CornerRadius=UDim.new(0,3)
    if logoChanged then self:_StartLogo() end
    self.Mark.Visible=valid.ShowLogo
    self.MarkImage.Visible=valid.ShowLogo and self.MarkImage.Image~=""
    self.Root.BackgroundTransparency=valid.BackgroundTransparency
    self:_Layout();self:_SetActivity()
end
function Loader:Update(options)
    assert(not self.Destroyed and not self.Completed,"Loader is closed or completing")
    assert(type(options)=="table","Update expects an options table")
    local previous=self.Options
    local valid=loader_options(options,previous)
    local logoChanged=valid.Logo~=previous.Logo or valid.MarkText~=previous.MarkText
    self:_Apply(valid,logoChanged)
    return self
end
function Loader:Run(steps)
    assert(not self.Destroyed and not self.Completed,"Loader is closed or completing")
    assert(not self._running,"Loader is already running")
    assert(type(steps)=="table" and #steps>0,"Run expects a nonempty dense step array")
    local staged={}
    for i=1,#steps do
        local step=steps[i]
        assert(type(step)=="table" and type(step.Title)=="string" and step.Title~="" and utf8.len(step.Title)~=nil and utf8.len(step.Title)<=160 and type(step.Run)=="function","Each step needs a title and Run function")
        staged[i]={Title=step.Title,Run=step.Run}
    end
    for key in pairs(steps)do assert(type(key)=="number" and key%1==0 and key>=1 and key<=#steps,"Run steps must be a dense array")end
    self._running=true;self._runToken=(self._runToken or 0)+1
    local token=self._runToken;self:SetProgress(0,staged[1].Title)
    self._runThread=task.defer(function()
        for index,step in ipairs(staged)do
            if self.Destroyed or self._runToken~=token then return end
            self.Status=step.Title;self.StatusLabel.Text=step.Title
            local ok=pcall(step.Run,self)
            if self.Destroyed or self._runToken~=token then return end
            if not ok then
                self._running=false;self._runThread=nil
                self.LastError="A loader step failed";self:SetStatus("Preparation could not be completed")
                local onError=self.Options.OnError
                if onError then
                    spawn_owned(self,function()pcall(onError,self,step.Title,index)end)
                end
                return
            end
            self:SetProgress(index/#staged,step.Title)
        end
        if self.Destroyed or self._runToken~=token then return end
        self._running=false;self._runThread=nil;self:Complete("Ready")
    end)
    return self
end
function Loader:Destroy()
    if self.Destroyed then return end
    self.Destroyed=true;self._runToken=(self._runToken or 0)+1;self._running=false
    for _,key in ipairs({"_finishThread","_avatarTask","_runThread"})do
        local thread=self[key];self[key]=nil
        if thread and thread~=coroutine.running() and coroutine.status(thread)~="dead"then task.cancel(thread)end
    end
    if self._progressTween then self._progressTween:Cancel();self._progressTween=nil end
    if self._activityTween then self._activityTween:Cancel();self._activityTween=nil end
    for _,tween in ipairs(self._tweens)do pcall(function()tween:Cancel()end)end
    table.clear(self._tweens);disconnect(self._connections,self)
    for index=#self._owned,1,-1 do
        local ok=pcall(self._owned[index])
        if not ok then self.LastError="Loader resource cleanup failed" end
    end
    table.clear(self._owned)
    Library.Loaders[self]=nil
    if not self._guiDestroying then self.Gui:Destroy()end
end
function Loader:Complete(status)
    if self.Destroyed or self.Completed or self._running then return self end
    self:SetProgress(1,status or "Ready");self.Completed=true;self._running=false
    if self._runThread and self._runThread~=coroutine.running()then task.cancel(self._runThread);self._runThread=nil end
    if self._progressTween then self._progressTween:Cancel();self._progressTween=nil end
    self.Fill.Size=UDim2.fromScale(1,1);self.Activity.Visible=false
    if self._activityTween then self._activityTween:Cancel();self._activityTween=nil end
    local function finish()
        self._finishThread=nil
        if self.Destroyed then return end
        local callback=self.Options.OnComplete
        self:Destroy()
        if callback then
            local ok,problem=pcall(callback,self)
            if not ok then self.LastError=tostring(problem);warn("[Gabibou UI] loader: "..tostring(problem))end
        end
    end
    local function fade()
        self._finishThread=nil
        if self.Destroyed then return end
        local duration=self.Options.ReducedMotion and 0 or self.Options.ExitDuration
        if duration==0 then finish();return end
        for _,instance in ipairs(self.Gui:GetDescendants())do
            local goals={}
            if instance:IsA("GuiObject")then goals.BackgroundTransparency=1 end
            if instance:IsA("TextLabel")then goals.TextTransparency=1 end
            if instance:IsA("ImageLabel")then goals.ImageTransparency=1 end
            if instance:IsA("UIStroke")then goals.Transparency=1 end
            if next(goals)then
                local tween=TweenService:Create(instance,TweenInfo.new(duration),goals)
                self._tweens[#self._tweens+1]=tween;tween:Play()
            end
        end
        self._finishThread=task.delay(duration,finish)
    end
    local remaining=math.max(0,self.Options.MinimumDuration-(os.clock()-self._started))
    self._finishThread=task.delay(remaining,fade)
    return self
end

function Library:CreateLoader(options)
    local valid=loader_options(options)
    local self=setmetatable({Options=valid,Progress=0,Status="Starting",Completed=false,Destroyed=false,_connections={},_tweens={},_owned={},_partLayouts={},_started=os.clock()},Loader)
    local theme,style=valid.Theme,valid.Style
    release_focus(valid.Parent)
    self.Gui=create("ScreenGui",{Name="GabibouUI_Loading",ResetOnSpawn=false,ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,DisplayOrder=valid.DisplayOrder,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},valid.Parent)
    self.Root=create("TextButton",{Name="LoadingOverlay",Size=UDim2.fromScale(1,1),Text="",AutoButtonColor=false,Modal=true,Active=true,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=valid.BackgroundTransparency},self.Gui)
    self.Card=create("Frame",{Name="LoadingCard",Position=valid.Position,AnchorPoint=valid.AnchorPoint,BackgroundColor3=theme.Background,ClipsDescendants=true},self.Root)
    self.CardCorner=Instance.new("UICorner");self.CardCorner.CornerRadius=UDim.new(0,style.WindowRadius);self.CardCorner.Parent=self.Card
    self.Border=create("UIStroke",{Color=theme.Border,Thickness=1,Transparency=.15},self.Card)
    self.Edge=create("Frame",{BackgroundColor3=theme.Accent,BackgroundTransparency=.65},self.Card)
    create("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.5,0),NumberSequenceKeypoint.new(1,1)})},self.Edge)
    self.Content=create("Frame",{Name="CustomContent",BackgroundTransparency=1,ClipsDescendants=true},self.Card)
    self.Mark=create("Frame",{Name="Logo",BackgroundColor3=theme.Raised,ClipsDescendants=true},self.Card)
    self.MarkCorner=Instance.new("UICorner");self.MarkCorner.Parent=self.Mark
    self.MarkTextLabel=create("TextLabel",{Name="Placeholder",Text=valid.MarkText,Font=style.FontBold,TextSize=20,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),TextColor3=theme.Text},self.Mark)
    self.MarkImage=create("ImageLabel",{Name="Image",Image="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ScaleType=Enum.ScaleType.Crop,Visible=false},self.Mark)
    self.MarkImageCorner=Instance.new("UICorner");self.MarkImageCorner.Parent=self.MarkImage
    self.Title=create("TextLabel",{Text=valid.Title,Font=style.FontBold,TextSize=style.TitleSize+2,TextColor3=theme.Text,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},self.Card)
    self.Subtitle=create("TextLabel",{Text=valid.Subtitle,Font=style.Font,TextSize=style.DescriptionSize,TextColor3=theme.Muted,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true,TextTruncate=Enum.TextTruncate.AtEnd},self.Card)
    self.StatusLabel=create("TextLabel",{Text=self.Status,Font=style.Font,TextSize=style.DescriptionSize,TextColor3=theme.Text,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},self.Card)
    self.Percent=create("TextLabel",{Text="0%",Font=style.Font,TextSize=style.DescriptionSize,TextColor3=theme.Muted,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Right},self.Card)
    self.Track=create("Frame",{BackgroundColor3=theme.Raised,ClipsDescendants=true},self.Card)
    self.TrackCorner=Instance.new("UICorner");self.TrackCorner.Parent=self.Track
    self.Fill=create("Frame",{Size=UDim2.fromScale(0,1),BackgroundColor3=theme.Accent},self.Track)
    self.FillCorner=Instance.new("UICorner");self.FillCorner.Parent=self.Fill
    self.Activity=create("Frame",{Size=UDim2.fromScale(.18,1),Position=UDim2.fromScale(-.18,0),BackgroundColor3=theme.Text,BackgroundTransparency=.55},self.Track)
    self:_StartLogo();self:_Layout();self:_SetActivity()
    self._connections[#self._connections+1]=self.Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()self:_Layout()end)
    self._connections[#self._connections+1]=self.Gui.Destroying:Connect(function()self._guiDestroying=true;self:Destroy()end)
    Library.Loaders[self]=true
    return self
end

-- Optional, client-side validation dialog. Injected in ui.luau's shared scope
-- after loading.luau; the caller supplies the validation policy.

Library.KeySystems = Library.KeySystems or {}
local KeyGate = {}
KeyGate.__index = KeyGate
local keyGateSerial = 0

local function key_text(value, fallback, limit, label)
    assert(value == nil or type(value) == "string", label .. " must be a string")
    local valid = Logic.text(value or fallback, limit)
    assert(valid == value or value == nil, label .. " is too long")
    return valid
end

local function discord_options(value)
    if value == nil or value == false then return value end
    if type(value) == "string" then value = {Url = value}
    else
        assert(type(value) == "table", "Discord must be a URL, options table, or false")
        value = table.clone(value)
    end
    local allowed = {Url = true, Text = true, CopiedText = true, Color = true, Logo = true, Copy = true}
    for key in pairs(value) do assert(allowed[key], "Unknown Discord option: " .. tostring(key)) end
    assert(type(value.Url) == "string" and #value.Url <= 256 and not value.Url:find("%s"), "Discord.Url must be an HTTPS invite URL")
    local normalizedUrl = value.Url:lower()
    local validInvite = normalizedUrl:match("^https://discord%.gg/[%w%-]+/?$") ~= nil
        or normalizedUrl:match("^https://discord%.com/invite/[%w%-]+/?$") ~= nil
    assert(validInvite, "Discord.Url must use discord.gg or discord.com/invite over HTTPS")
    value.Text = key_text(value.Text, "Copy Discord link", 48, "Discord.Text")
    value.CopiedText = key_text(value.CopiedText, "Link copied", 48, "Discord.CopiedText")
    assert(value.Text ~= "" and value.CopiedText ~= "", "Discord button text must not be empty")
    value.Color = value.Color or Color3.fromRGB(88, 101, 242)
    assert(typeof(value.Color) == "Color3", "Discord.Color must be a Color3")
    if value.Logo ~= nil then
        assert(type(value.Logo) == "string" and #value.Logo <= 64 and value.Logo:match("^rbxassetid://%d+$") ~= nil,
            "Discord.Logo must be an rbxassetid URI")
        assert(tonumber(value.Logo:match("rbxassetid://(%d+)")) > 0, "Discord.Logo asset ID must be positive")
    end
    assert(value.Copy == nil or type(value.Copy) == "function", "Discord.Copy must be a function")
    return value
end

local function get_key_options(value)
    if value == nil or value == false then return value end
    if type(value) == "function" then return value end
    if type(value) == "string" then value = {Url = value}
    else
        assert(type(value) == "table", "GetKey must be a URL, options table, callback, or false")
        value = table.clone(value)
    end
    for key in pairs(value) do
        assert(key == "Url" or key == "Text" or key == "Copy", "Unknown GetKey option: " .. tostring(key))
    end
    assert(type(value.Url) == "string" and #value.Url > 0 and #value.Url <= 2048,
        "GetKey.Url must be a nonempty HTTPS URL up to 2048 characters")
    assert(not value.Url:find("[%c%s]"), "GetKey.Url must not contain whitespace or control characters")
    local authority = value.Url:match("^https://([^/%?#]+)")
    assert(authority and authority ~= "", "GetKey.Url must use HTTPS and include a host")
    value.Text = key_text(value.Text, "Get key", 48, "GetKey.Text")
    assert(value.Text ~= "", "GetKey.Text must not be empty")
    assert(value.Copy == nil or type(value.Copy) == "function", "GetKey.Copy must be a function")
    return value
end

local function same_get_key(left, right)
    if left == right then return true end
    if type(left) ~= "table" or type(right) ~= "table" then return false end
    return left.Url == right.Url and left.Text == right.Text and left.Copy == right.Copy
end

local function key_options(options)
    assert(options == nil or type(options) == "table", "Key system options must be a table")
    options = table.clone(options or {})
    assert(type(options.Validate) == "function", "Validate callback is required")
    assert(options.OnSuccess == nil or type(options.OnSuccess) == "function", "OnSuccess must be a function")
    assert(options.OnCancel == nil or type(options.OnCancel) == "function", "OnCancel must be a function")
    options.Title = key_text(options.Title, "Access key", 80, "Title")
    options.Subtitle = key_text(options.Subtitle, "Enter your key to continue.", 240, "Subtitle")
    options.Placeholder = key_text(options.Placeholder, "Enter key…", 120, "Placeholder")
    options.SubmitText = key_text(options.SubmitText, "Verify key", 32, "SubmitText")
    options.CancelText = key_text(options.CancelText, "Cancel", 32, "CancelText")
    options.SuccessText = key_text(options.SuccessText, "Verified", 120, "SuccessText")
    options.InvalidText = key_text(options.InvalidText, "Key not accepted", 120, "InvalidText")
    options.InputLabel = key_text(options.InputLabel, "Access key", 48, "InputLabel")
    options.ValidatingText = key_text(options.ValidatingText, "Verifying…", 48, "ValidatingText")
    options.CancelledText = key_text(options.CancelledText, "Cancelled", 48, "CancelledText")
    options.MarkText = key_text(options.MarkText, "G", 8, "MarkText")
    assert(options.MarkText ~= "", "MarkText must not be empty")
    if options.Logo == nil then options.Logo = "Avatar" end
    assert(options.Logo == false or options.Logo == "Avatar" or
        (type(options.Logo) == "string" and #options.Logo <= 64 and
        options.Logo:match("^rbxassetid://%d+$") ~= nil and
        tonumber(options.Logo:match("%d+$")) > 0), "Logo must be Avatar, false, or an rbxassetid URI")
    options.Discord = discord_options(options.Discord)
    options.GetKey = get_key_options(options.GetKey)
    options.Width = options.Width == nil and 420 or options.Width
    if options.Height == nil then
        local hasDiscord = type(options.Discord) == "table"
        local hasGetKey = options.GetKey ~= nil and options.GetKey ~= false
        options.Height = 332 + (hasDiscord and 62 or 0) + (hasGetKey and 72 or 0) - (hasDiscord and hasGetKey and 4 or 0)
    end
    assert(Logic.finite(options.Width) and options.Width >= 280 and options.Width <= 600, "Width must be 280..600")
    assert(Logic.finite(options.Height) and options.Height >= 280 and options.Height <= 560, "Height must be 280..560")
    options.Position = options.Position or UDim2.fromScale(.5, .5)
    options.AnchorPoint = options.AnchorPoint or Vector2.new(.5, .5)
    assert(typeof(options.Position) == "UDim2", "Position must be a UDim2")
    assert(typeof(options.AnchorPoint) == "Vector2", "AnchorPoint must be a Vector2")
    for _, component in ipairs({options.Position.X.Scale, options.Position.X.Offset, options.Position.Y.Scale, options.Position.Y.Offset}) do
        assert(Logic.finite(component), "Position components must be finite")
    end
    assert(Logic.finite(options.AnchorPoint.X) and Logic.finite(options.AnchorPoint.Y)
        and options.AnchorPoint.X >= 0 and options.AnchorPoint.X <= 1
        and options.AnchorPoint.Y >= 0 and options.AnchorPoint.Y <= 1,
        "AnchorPoint components must be 0..1")
    options.MaxLength = options.MaxLength == nil and 256 or options.MaxLength
    assert(Logic.finite(options.MaxLength) and options.MaxLength % 1 == 0 and options.MaxLength >= 1 and options.MaxLength <= 4096, "MaxLength must be an integer in 1..4096")
    options.DisplayOrder = options.DisplayOrder == nil and 120 or options.DisplayOrder
    assert(Logic.finite(options.DisplayOrder) and options.DisplayOrder % 1 == 0, "DisplayOrder must be an integer")
    local player = Players.LocalPlayer
    assert(player, "Key system runs on a Roblox client")
    options.Parent = options.Parent or player:FindFirstChildOfClass("PlayerGui")
    assert(typeof(options.Parent) == "Instance", "Pass a GUI parent or wait for PlayerGui")
    options.Theme = theme_for(options.Theme or "Graphite")
    options.Style = style_for(options.Style, Library.Style)
    return options
end

local function safe_message(value, fallback, submittedKey)
    if type(value) ~= "string" or value == "" then return fallback end
    if submittedKey ~= "" and value:find(submittedKey, 1, true) then return fallback end
    local ok, result = pcall(function() return Logic.text(value:gsub("[%c]", " "), 120) end)
    if not ok or result == "" then return fallback end
    return result
end

function KeyGate:_Status(text, kind)
    if self.Destroyed then return end
    self.Status = text
    self._statusKind = kind or "normal"
    self.StatusLabel.Text = text
    self.StatusLabel.TextColor3 = self.Options.Theme[kind == "success" and "Success" or kind == "error" and "Danger" or "Muted"]
end

function KeyGate:GetParts()
    if self.Destroyed then return nil end
    return {
        Card = self.Card,
        ContentScroll = self.Scroll,
        Input = self.Input,
        Title = self.Title,
        Subtitle = self.Subtitle,
        Status = self.StatusLabel,
        Submit = self.SubmitButton,
        Cancel = self.CancelButton,
        Mark = self.Mark,
        MarkImage = self.MarkImage,
        MarkText = self.MarkLabel,
        KeyIcon = self.KeyIcon,
        KeyLabel = self.KeyLabel,
        DiscordButton = self.DiscordButton,
        DiscordIcon = self.DiscordIcon,
        DiscordLink = self.DiscordLink,
        DiscordStatus = self.DiscordStatus,
        GetKeyButton = self.GetKeyButton,
        KeyLink = self.KeyLink,
        KeyLinkStatus = self.KeyLinkStatus,
    }
end

function KeyGate:_StartLogo()
    self._logoGeneration = (self._logoGeneration or 0) + 1
    local generation = self._logoGeneration
    local previous = self._avatarThread
    self._avatarThread = nil
    if previous and previous ~= coroutine.running() and coroutine.status(previous) ~= "dead" then pcall(task.cancel, previous) end
    local logo = self.Options.Logo
    self.MarkImage.Image = ""
    self.MarkImage.Visible = false
    self.MarkLabel.Visible = logo == false
    self.MarkLabel.TextColor3 = self.Options.Theme[logo == false and "AccentText" or "Text"]
    self.Mark.BackgroundColor3 = self.Options.Theme[logo == false and "Accent" or "Raised"]
    if logo == false then return end
    if logo ~= "Avatar" then self.MarkImage.Image = logo; self.MarkImage.Visible = true; return end
    self._avatarThread = task.defer(function()
        local ok, content = pcall(function()
            return Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        if self.Destroyed or generation ~= self._logoGeneration then return end
        self._avatarThread = nil
        if ok then self.MarkImage.Image = content; self.MarkImage.Visible = true
        else self.MarkLabel.Visible = true end
    end)
end

local function find_clipboard_function()
    local candidate
    local ok = pcall(function() candidate = setclipboard end)
    if ok and type(candidate) == "function" then return candidate end
    local envGetter
    pcall(function() envGetter = getgenv end)
    if type(envGetter) == "function" then
        local envOk, env = pcall(envGetter)
        if envOk and type(env) == "table" and type(env.setclipboard) == "function" then return env.setclipboard end
    end
    return nil
end

function KeyGate:CopyDiscordLink()
    if self.Destroyed then return false, "Gate is destroyed" end
    if self._copyBusy then return false, "Copy is in progress" end
    local config = self.Options.Discord
    if type(config) ~= "table" then return false, "Discord link is disabled" end
    self._copyGeneration += 1
    local generation = self._copyGeneration
    self._copyBusy = true
    local ok, result
    local unavailable = false
    if config.Copy then
        ok, result = pcall(config.Copy, config.Url)
    else
        local copier = find_clipboard_function()
        if not copier then unavailable = true; ok, result = false, "Clipboard unavailable"
        else ok, result = pcall(copier, config.Url) end
    end
    if self.Destroyed or generation ~= self._copyGeneration or self.Options.Discord ~= config then
        return false, "Copy was cancelled by an update or destroy"
    end
    self._copyBusy = false
    if ok and result ~= false then
        self._manualLinkVisible = false
        self.DiscordLink.Visible = false
        self.DiscordStatus.Text = config.CopiedText
        self.DiscordStatus.TextColor3 = self.Options.Theme.Success
        self.DiscordStatus.Visible = true
        self._discordCopyKind = "success"
        self:_Layout()
        return true
    end

    self._manualLinkVisible = true
    self.DiscordLink.Text = config.Url
    self.DiscordLink.Visible = true
    self.DiscordStatus.Text = "Select and copy the link below."
    self.DiscordStatus.TextColor3 = self.Options.Theme.Muted
    self.DiscordStatus.Visible = true
    self._discordCopyKind = "manual"
    self:_Layout()
    self:_RevealDiscordLink()
    local reason = unavailable and "Clipboard unavailable" or (ok and "Copy callback declined" or "Copy failed")
    return false, reason
end

function KeyGate:GetKey()
    if self.Destroyed then return false, "Gate is destroyed" end
    if self._getKeyBusy then return false, "Get key action is in progress" end
    local config = self.Options.GetKey
    if config == nil or config == false then return false, "Get key action is disabled" end

    self._getKeyGeneration += 1
    local generation = self._getKeyGeneration
    self._getKeyBusy = true
    self.GetKeyButton.Active = false
    self.KeyLinkStatus.Text = type(config) == "function" and "Running key action..." or "Copying key link..."
    self.KeyLinkStatus.TextColor3 = self.Options.Theme.Muted
    self.KeyLinkStatus.Visible = true
    self:_Layout()
    local ok, result
    local unavailable = false
    if type(config) == "function" then
        ok, result = pcall(config, self)
    else
        local copier = config.Copy or find_clipboard_function()
        if not copier then unavailable = true; ok, result = false, "Clipboard unavailable"
        elseif config.Copy then ok, result = pcall(copier, config.Url)
        else ok, result = pcall(copier, config.Url) end
    end

    if self.Destroyed or generation ~= self._getKeyGeneration or not same_get_key(self.Options.GetKey, config) then
        return false, "Get key action was cancelled by an update or destroy"
    end
    self._getKeyBusy = false
    self.GetKeyButton.Active = true
    if ok and result ~= false then
        self._manualKeyLinkVisible = false
        self.KeyLink.Visible = false
        self.KeyLinkStatus.Text = type(config) == "function" and "Key action completed." or "Link copied. Open it in your browser."
        self.KeyLinkStatus.TextColor3 = self.Options.Theme.Success
        self.KeyLinkStatus.Visible = true
        self._getKeyStatusKind = "success"
        self:_Layout()
        return true
    end

    if type(config) ~= "function" then
        self._manualKeyLinkVisible = true
        self.KeyLink.Text = config.Url
        self.KeyLink.Visible = true
        self.KeyLinkStatus.Text = "Select and copy the link below."
        self._getKeyStatusKind = "manual"
        self:_Layout()
        self:_RevealKeyLink()
    else
        self._manualKeyLinkVisible = false
        self.KeyLink.Visible = false
        self.KeyLinkStatus.Text = "Key action failed."
        self._getKeyStatusKind = "error"
        self:_Layout()
    end
    self.KeyLinkStatus.TextColor3 = self._getKeyStatusKind == "error" and self.Options.Theme.Danger or self.Options.Theme.Muted
    self.KeyLinkStatus.Visible = true
    local reason = unavailable and "Clipboard unavailable" or (ok and "Get key callback declined" or "Get key action failed")
    return false, reason
end

local function set_corner(instance, radius)
    local rounding = instance and instance:FindFirstChildOfClass("UICorner")
    if rounding then rounding.CornerRadius = UDim.new(0, radius) end
end

function KeyGate:Update(changes)
    if self.Destroyed then return false, "Gate is destroyed" end
    if self.Busy then return false, "Validation is in progress" end
    if self.Completed then return false, "Gate has completed" end
    if type(changes) ~= "table" then return false, "Update options must be a table" end

    local merged = table.clone(self.Options)
    for key, value in pairs(changes) do
        if (key == "Theme" or key == "Style") and type(value) == "table" then
            local nested = table.clone(self.Options[key])
            for nestedKey, nestedValue in pairs(value) do nested[nestedKey] = nestedValue end
            merged[key] = nested
        elseif key == "Discord" and type(value) == "table" and type(self.Options.Discord) == "table" then
            local nested = table.clone(self.Options.Discord)
            for nestedKey, nestedValue in pairs(value) do nested[nestedKey] = nestedValue end
            merged[key] = nested
        elseif key == "GetKey" and type(value) == "table" and type(self.Options.GetKey) == "table" then
            local nested = table.clone(self.Options.GetKey)
            for nestedKey, nestedValue in pairs(value) do nested[nestedKey] = nestedValue end
            merged[key] = nested
        else
            merged[key] = value
        end
    end
    local ok, valid = pcall(key_options, merged)
    if not ok then return false, tostring(valid) end
    if self._automaticHeight and changes.Height == nil then
        local hasDiscord = type(valid.Discord) == "table"
        local hasGetKey = valid.GetKey ~= nil and valid.GetKey ~= false
        valid.Height = 332 + (hasDiscord and 62 or 0) + (hasGetKey and 72 or 0) - (hasDiscord and hasGetKey and 4 or 0)
    end

    -- Validation is complete. Apply the staged configuration to the existing GUI.
    local previousDiscord = self.Options.Discord
    local previousGetKey = self.Options.GetKey
    local pendingGetKey = self._getKeyBusy
    local logoChanged = self.Options.Logo ~= valid.Logo
    self._copyGeneration += 1
    self._copyBusy = false
    self._getKeyGeneration += 1
    self._getKeyBusy = false
    self.GetKeyButton.Active = self.Options.GetKey ~= nil and self.Options.GetKey ~= false
    self._automaticHeight = self._automaticHeight and changes.Height == nil
    if pendingGetKey then
        self.KeyLinkStatus.Text = "Get key action cancelled by update."
        self._getKeyStatusKind = "manual"
    end
    if valid.Parent ~= self.Gui.Parent then
        release_focus(valid.Parent)
        self.Gui.Parent = valid.Parent
    end
    self.Options = valid
    self.Gui.DisplayOrder = valid.DisplayOrder
    self.Title.Text = valid.Title
    self.Subtitle.Text = valid.Subtitle
    self.Input.PlaceholderText = valid.Placeholder
    self.SubmitButton.Text = valid.SubmitText
    self.CancelButton.Text = valid.CancelText
    self.MarkLabel.Text = valid.MarkText
    self.KeyLabel.Text = valid.InputLabel
    local discord = valid.Discord
    if type(previousDiscord) == "table" and type(discord) == "table" and previousDiscord.Url ~= discord.Url then
        self.DiscordStatus.Text = ""
        self._discordCopyKind = nil
        self._manualLinkVisible = false
    elseif type(discord) ~= "table" then
        self.DiscordStatus.Text = ""
        self._discordCopyKind = nil
        self._manualLinkVisible = false
    end
    self.DiscordButton.Visible = type(discord) == "table"
    self.DiscordLabel.Text = type(discord) == "table" and discord.Text or ""
    self.DiscordButton.BackgroundColor3 = type(discord) == "table" and discord.Color or Color3.fromRGB(88, 101, 242)
    self.DiscordLink.Text = type(discord) == "table" and discord.Url or ""
    self.DiscordLink.Visible = type(discord) == "table" and self._manualLinkVisible == true
    self.DiscordImage.Visible = type(discord) == "table" and discord.Logo ~= nil
    self.DiscordImage.Image = type(discord) == "table" and discord.Logo or ""
    self.DiscordVector.Visible = type(discord) == "table" and discord.Logo == nil
    self.DiscordStatus.Visible = type(discord) == "table" and self.DiscordStatus.Text ~= ""

    local getKey = valid.GetKey
    if not same_get_key(previousGetKey, getKey) then
        self.KeyLinkStatus.Text = ""
        self.KeyLinkStatus.Visible = false
        self.KeyLink.Visible = false
        self._manualKeyLinkVisible = false
        self._getKeyStatusKind = nil
    end
    self.GetKeyButton.Visible = getKey ~= nil and getKey ~= false
    self.GetKeyButton.Active = self.GetKeyButton.Visible
    self.GetKeyLabel.Text = type(getKey) == "table" and getKey.Text or "Get key"
    self.KeyLink.Text = type(getKey) == "table" and getKey.Url or ""
    self.KeyLink.Visible = self.GetKeyButton.Visible and self._manualKeyLinkVisible == true
    self.KeyLinkStatus.Visible = self.GetKeyButton.Visible and self.KeyLinkStatus.Text ~= ""

    local theme, style = valid.Theme, valid.Style
    self.Card.BackgroundColor3 = theme.Background
    self.Card:FindFirstChildOfClass("UIStroke").Color = theme.Border
    self.Edge.BackgroundColor3 = theme.Accent
    self.Mark.BackgroundColor3 = theme[valid.Logo == false and "Accent" or "Raised"]
    self.MarkLabel.TextColor3 = theme[valid.Logo == false and "AccentText" or "Text"]
    self.Title.TextColor3 = theme.Text
    self.Subtitle.TextColor3 = theme.Muted
    self.KeyLabel.TextColor3 = theme.Muted
    self.Input.BackgroundColor3 = theme.Raised
    self.Input.TextColor3 = theme.Text
    self.Input.PlaceholderColor3 = theme.Muted
    self.Input:FindFirstChildOfClass("UIStroke").Color = theme.Border
    self.StatusLabel.TextColor3 = theme[self._statusKind == "success" and "Success" or self._statusKind == "error" and "Danger" or "Muted"]
    self.CancelButton.BackgroundColor3 = theme.Surface
    self.CancelButton.TextColor3 = theme.Text
    self.CancelButton:FindFirstChildOfClass("UIStroke").Color = theme.Border
    self.SubmitButton.BackgroundColor3 = theme.Accent
    self.SubmitButton.TextColor3 = theme.AccentText
    self.DiscordLabel.TextColor3 = Color3.new(1, 1, 1)
    self.DiscordStatus.TextColor3 = self._discordCopyKind == "success" and theme.Success or theme.Muted
    self.DiscordLink.BackgroundColor3 = theme.Raised
    self.DiscordLink.TextColor3 = theme.Text
    self.DiscordLink:FindFirstChildOfClass("UIStroke").Color = theme.Border
    self.GetKeyButton.BackgroundColor3 = theme.Surface
    self.GetKeyButton.TextColor3 = theme.Text
    self.GetKeyButton:FindFirstChildOfClass("UIStroke").Color = theme.Border
    self.GetKeyLabel.TextColor3 = theme.Text
    self.KeyLinkStatus.TextColor3 = self._getKeyStatusKind == "success" and theme.Success or self._getKeyStatusKind == "error" and theme.Danger or theme.Muted
    self.KeyLink.BackgroundColor3 = theme.Raised
    self.KeyLink.TextColor3 = theme.Text
    self.KeyLink:FindFirstChildOfClass("UIStroke").Color = theme.Border
    for _, descendant in ipairs(self.GetKeyIcon:GetDescendants()) do
        if descendant:IsA("UIStroke") then descendant.Color = theme.Muted
        elseif descendant:IsA("GuiObject") and descendant.BackgroundTransparency < 1 then descendant.BackgroundColor3 = theme.Muted end
    end
    for _, descendant in ipairs(self.KeyIcon:GetDescendants()) do
        if descendant:IsA("UIStroke") then descendant.Color = theme.Muted
        elseif descendant:IsA("GuiObject") then descendant.BackgroundColor3 = theme.Muted end
    end
    for _, descendant in ipairs(self.DiscordVector:GetDescendants()) do
        if descendant.Name == "DiscordEye" then descendant.BackgroundColor3 = self.DiscordButton.BackgroundColor3 end
    end

    self.MarkLabel.Font = style.FontBold
    self.MarkLabel.TextSize = style.TitleSize
    self.Title.Font = style.FontBold
    self.Title.TextSize = style.TitleSize
    self.Subtitle.Font = style.Font
    self.Subtitle.TextSize = style.DescriptionSize
    self.KeyLabel.Font = style.FontBold
    self.KeyLabel.TextSize = style.DescriptionSize
    self.Input.Font = style.Font
    self.Input.TextSize = style.TextSize
    self.StatusLabel.Font = style.Font
    self.StatusLabel.TextSize = style.DescriptionSize
    self.CancelButton.Font = style.FontBold
    self.CancelButton.TextSize = style.TextSize
    self.SubmitButton.Font = style.FontBold
    self.SubmitButton.TextSize = style.TextSize
    self.DiscordLabel.Font = style.FontBold
    self.DiscordLabel.TextSize = style.TextSize
    self.DiscordStatus.Font = style.Font
    self.DiscordStatus.TextSize = style.DescriptionSize
    self.DiscordLink.Font = style.Font
    self.DiscordLink.TextSize = style.TextSize
    self.GetKeyLabel.Font = style.FontBold
    self.GetKeyLabel.TextSize = style.TextSize
    self.KeyLinkStatus.Font = style.Font
    self.KeyLinkStatus.TextSize = style.DescriptionSize
    self.KeyLink.Font = style.Font
    self.KeyLink.TextSize = style.TextSize
    set_corner(self.Card, style.WindowRadius)
    for _, instance in ipairs({self.Mark, self.MarkImage, self.Input, self.CancelButton, self.SubmitButton, self.DiscordButton, self.DiscordLink, self.GetKeyButton, self.KeyLink}) do
        set_corner(instance, style.ControlRadius)
    end
    self:_Layout()
    if logoChanged then self:_StartLogo() end
    return true
end

function KeyGate:_Viewport()
    local size = self.Backdrop.AbsoluteSize
    if UIS.OnScreenKeyboardVisible and UIS.OnScreenKeyboardPosition.Y > 0 then
        local origin = self.Backdrop.AbsolutePosition.Y
        size = Vector2.new(size.X, math.max(1, math.min(size.Y, UIS.OnScreenKeyboardPosition.Y - origin)))
    end
    return size
end

function KeyGate:_RevealInput()
    if self.Destroyed or not self.Scroll or not self.Input then return end
    local inputTop = self.Input.AbsolutePosition.Y - self.Scroll.AbsolutePosition.Y + self.Scroll.CanvasPosition.Y
    local inputBottom = inputTop + self.Input.AbsoluteSize.Y
    local current = self.Scroll.CanvasPosition.Y
    if inputTop < current then current = inputTop - 8
    elseif inputBottom > current + self.Scroll.AbsoluteSize.Y then current = inputBottom - self.Scroll.AbsoluteSize.Y + 8 end
    local maximum = math.max(0, self.Content.Size.Y.Offset - self.Scroll.AbsoluteSize.Y)
    self.Scroll.CanvasPosition = Vector2.new(0, math.clamp(current, 0, maximum))
end

function KeyGate:_RevealDiscordLink()
    task.defer(function()
        task.defer(function()
            if self.Destroyed or not self._manualLinkVisible or not self.DiscordLink.Visible or not self.Scroll then return end
            local top = self.DiscordLink.AbsolutePosition.Y - self.Scroll.AbsolutePosition.Y + self.Scroll.CanvasPosition.Y
            local bottom = top + self.DiscordLink.AbsoluteSize.Y
            local current = self.Scroll.CanvasPosition.Y
            if top < current then current = top - 8
            elseif bottom > current + self.Scroll.AbsoluteSize.Y then current = bottom - self.Scroll.AbsoluteSize.Y + 8 end
            local maximum = math.max(0, self.Content.Size.Y.Offset - self.Scroll.AbsoluteSize.Y)
            self.Scroll.CanvasPosition = Vector2.new(0, math.clamp(current, 0, maximum))
        end)
    end)
end

function KeyGate:_RevealKeyLink()
    task.defer(function()
        task.defer(function()
            if self.Destroyed or not self._manualKeyLinkVisible or not self.KeyLink.Visible or not self.Scroll then return end
            local top = self.KeyLink.AbsolutePosition.Y - self.Scroll.AbsolutePosition.Y + self.Scroll.CanvasPosition.Y
            local bottom = top + self.KeyLink.AbsoluteSize.Y
            local current = self.Scroll.CanvasPosition.Y
            if top < current then current = top - 8
            elseif bottom > current + self.Scroll.AbsoluteSize.Y then current = bottom - self.Scroll.AbsoluteSize.Y + 8 end
            local maximum = math.max(0, self.Content.Size.Y.Offset - self.Scroll.AbsoluteSize.Y)
            self.Scroll.CanvasPosition = Vector2.new(0, math.clamp(current, 0, maximum))
        end)
    end)
end

function KeyGate:_Layout()
    if self.Destroyed or not self.Backdrop then return end
    local viewport = self:_Viewport()
    local width = math.max(1, math.min(self.Options.Width, viewport.X - 24))
    local height = math.max(1, math.min(self.Options.Height, viewport.Y - 24))
    local options = self.Options
    local x = viewport.X * options.Position.X.Scale + options.Position.X.Offset - width * options.AnchorPoint.X
    local y = viewport.Y * options.Position.Y.Scale + options.Position.Y.Offset - height * options.AnchorPoint.Y
    local marginX = math.min(12, math.max(0, (viewport.X - width) / 2))
    local marginY = math.min(12, math.max(0, (viewport.Y - height) / 2))
    x = math.clamp(x, marginX, math.max(marginX, viewport.X - width - marginX))
    y = math.clamp(y, marginY, math.max(marginY, viewport.Y - height - marginY))
    self.Card.Size = UDim2.fromOffset(width, height)
    self.Card.Position = UDim2.fromOffset(x, y)
    self.Card.AnchorPoint = Vector2.zero
    self.Scroll.Size = UDim2.fromScale(1, 1)

    local hasDiscord = self.DiscordButton and self.DiscordButton.Visible
    local hasGetKey = self.GetKeyButton and self.GetKeyButton.Visible
    local manualKeyLink = hasGetKey and self._manualKeyLinkVisible == true
    local baseline = hasGetKey and (hasDiscord and 462 or 404) or (hasDiscord and 394 or 332)
    local contentHeight = math.max(height, baseline)
    local layoutOffset = math.max(0, (contentHeight - baseline) / 2)
    local compactOffset = height < 280 and -8 or 0
    self.Mark.Position = UDim2.fromOffset(28, 28 + layoutOffset + compactOffset)
    self.Mark.Size = UDim2.fromOffset(44, 44)
    self.Title.Position = UDim2.fromOffset(88, 32 + layoutOffset + compactOffset)
    self.Title.Size = UDim2.new(1, -116, 0, 25)
    self.Subtitle.Position = UDim2.fromOffset(28, 84 + layoutOffset + compactOffset)
    self.Subtitle.Size = UDim2.new(1, -56, 0, 32)

    local actionsY = 220 + layoutOffset
    local innerWidth = math.max(1, width - 64)
    local cancelWidth = math.min(84, innerWidth * .38)
    local actionGap = 8
    local statusY = actionsY + (hasGetKey and 136 or 64) + (manualKeyLink and 52 or 0)
    local discordY = actionsY + (hasGetKey and 168 or 100) + (manualKeyLink and 52 or 0)
    self.SubmitButton.Position = UDim2.fromOffset(28, actionsY)
    if hasGetKey then
        self.SubmitButton.Size = UDim2.fromOffset(innerWidth, 48)
        self.GetKeyButton.Position = UDim2.fromOffset(28, actionsY + 60)
        self.GetKeyButton.Size = UDim2.fromOffset(math.max(1, innerWidth - cancelWidth - actionGap), 46)
        self.GetKeyIcon.Position = UDim2.fromOffset(14, 14)
        self.GetKeyLabel.Position = UDim2.fromOffset(40, 0)
        self.GetKeyLabel.Size = UDim2.new(1, -48, 1, 0)
        self.CancelButton.Position = UDim2.fromOffset(28 + self.GetKeyButton.Size.X.Offset + actionGap, actionsY + 60)
        self.CancelButton.Size = UDim2.fromOffset(cancelWidth, 46)
        self.KeyLinkStatus.Position = UDim2.fromOffset(28, actionsY + 114)
        self.KeyLinkStatus.Size = UDim2.new(1, -56, 0, 18)
        self.KeyLink.Position = UDim2.fromOffset(28, actionsY + 136)
        self.KeyLink.Size = UDim2.new(1, -56, 0, 40)
    else
        self.SubmitButton.Size = UDim2.fromOffset(math.max(1, innerWidth - cancelWidth - actionGap), 48)
        self.CancelButton.Position = UDim2.fromOffset(28 + self.SubmitButton.Size.X.Offset + actionGap, actionsY)
        self.CancelButton.Size = UDim2.fromOffset(cancelWidth, 48)
        self.GetKeyButton.Position = UDim2.fromOffset(28, actionsY)
        self.GetKeyButton.Size = UDim2.fromOffset(1, 44)
        self.KeyLinkStatus.Position = UDim2.fromOffset(28, actionsY + 64)
        self.KeyLinkStatus.Size = UDim2.new(1, -56, 0, 18)
        self.KeyLink.Position = UDim2.fromOffset(28, actionsY + 86)
        self.KeyLink.Size = UDim2.new(1, -56, 0, 40)
    end

    local inputY = 156 + layoutOffset
    self.KeyLabel.Position = UDim2.fromOffset(48, 132 + layoutOffset)
    self.KeyLabel.Size = UDim2.new(1, -76, 0, 18)
    self.KeyIcon.Position = UDim2.fromOffset(28, 135 + layoutOffset)
    self.Input.Position = UDim2.fromOffset(28, inputY)
    self.Input.Size = UDim2.new(1, -56, 0, 48)
    self.StatusLabel.Position = UDim2.fromOffset(28, statusY)
    self.StatusLabel.Size = UDim2.new(1, -56, 0, 20)
    self.DiscordButton.Position = UDim2.fromOffset(28, discordY)
    self.DiscordButton.Size = UDim2.new(1, -56, 0, 46)
    self.DiscordIcon.Position = UDim2.fromOffset(14, 12)
    self.DiscordLabel.Size = UDim2.new(1, -54, 1, 0)
    self.DiscordLabel.Position = UDim2.fromOffset(44, 0)
    self.DiscordLink.Position = UDim2.fromOffset(28, discordY + 68)
    self.DiscordLink.Size = UDim2.new(1, -56, 0, 40)
    if self.DiscordStatus.Visible then
        self.DiscordStatus.Position = UDim2.fromOffset(28, discordY + 50)
        self.DiscordStatus.Size = UDim2.new(1, -56, 0, 18)
    end

    local requiredBottom = math.max(
        self.SubmitButton.Position.Y.Offset + self.SubmitButton.Size.Y.Offset,
        self.CancelButton.Position.Y.Offset + self.CancelButton.Size.Y.Offset,
        self.StatusLabel.Position.Y.Offset + self.StatusLabel.Size.Y.Offset
    )
    for _, part in ipairs({self.GetKeyButton, self.KeyLinkStatus, self.KeyLink, self.DiscordButton, self.DiscordStatus, self.DiscordLink}) do
        if part.Visible then requiredBottom = math.max(requiredBottom, part.Position.Y.Offset + part.Size.Y.Offset) end
    end
    contentHeight = math.max(contentHeight, requiredBottom + 28)
    self.Content.Size = UDim2.new(1, -8, 0, contentHeight)
    self.Scroll.CanvasSize = UDim2.fromOffset(0, contentHeight)
    self.KeyIcon.Visible = self.KeyLabel.Visible
    if UIS:GetFocusedTextBox() == self.Input then self:_RevealInput() end
end

function KeyGate:_WatchCamera()
    if self._cameraConnection then self._cameraConnection:Disconnect(); self._cameraConnection = nil end
    local camera = workspace.CurrentCamera
    if camera then self._cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function() self:_Layout() end) end
    self:_Layout()
end

function KeyGate:_TrackCallback(callback, ...)
    if self.Destroyed or type(callback) ~= "function" then return end
    local args = table.pack(...)
    local record = {Thread = nil, Finished = false}
    local thread = task.spawn(function()
        if self.Destroyed then return end
        local ok = pcall(callback, table.unpack(args, 1, args.n))
        if not ok and not self.Destroyed then self.LastError = "Callback failed" end
        record.Finished = true
        for index, active in ipairs(self._callbackThreads) do
            if active == record then table.remove(self._callbackThreads, index); break end
        end
    end)
    record.Thread = thread
    if not record.Finished then self._callbackThreads[#self._callbackThreads + 1] = record end
end

function KeyGate:Submit(key)
    if self.Destroyed or self.Busy or self._successCalled then return false end
    local submitted = key == nil and self.Input.Text or key
    if type(submitted) ~= "string" or submitted == "" or not submitted:match("%S") then
        self:_Status(self.Options.InvalidText, "error")
        return false
    end
    local submittedLength = utf8.len(submitted)
    if submittedLength == nil or submittedLength > self.Options.MaxLength then
        self:_Status(self.Options.InvalidText, "error")
        return false
    end

    self._generation += 1
    local generation = self._generation
    self.Busy = true
    self._cancelled = false
    self.SubmitButton.Active = false
    self.Input.TextEditable = false
    self:_Status(self.Options.ValidatingText, "normal")
    local validator = self.Options.Validate
    local submittedKey = submitted
    local thread = task.spawn(function()
        local ok, accepted, result = pcall(validator, submittedKey)
        if self.Destroyed or generation ~= self._generation or not self.Busy then submittedKey = nil; return end
        self._thread = nil
        self.Busy = false
        self.SubmitButton.Active = true
        self.Input.TextEditable = true
        if not ok then
            -- Never store or display the key or the thrown exception.
            self.Input.Text = ""
            self.LastError = "Validation callback failed"
            self:_Status(self.Options.InvalidText, "error")
        elseif accepted == true then
            self.Input.Text = ""
            self._successCalled = true
            self.Completed = true
            self:_Status(self.Options.SuccessText, "success")
            self.SubmitButton.Active = false
            self.Input.TextEditable = false
            self:_TrackCallback(self.Options.OnSuccess, self, result)
        else
            local message = safe_message(result, self.Options.InvalidText, submittedKey)
            self.Input.Text = ""
            self:_Status(message, "error")
        end
        submittedKey = nil
    end)
    if self.Busy and generation == self._generation then self._thread = thread end
    return true
end

function KeyGate:Cancel()
    if self.Destroyed or self.Completed or self._cancelled then return false end
    self._cancelled = true
    self._generation += 1
    self.Busy = false
    if self._getKeyBusy then
        self._getKeyGeneration += 1
        self._getKeyBusy = false
        self.GetKeyButton.Active = self.GetKeyButton.Visible
        self.KeyLinkStatus.Text = "Get key action cancelled."
        self.KeyLinkStatus.TextColor3 = self.Options.Theme.Muted
        self.KeyLinkStatus.Visible = self.GetKeyButton.Visible
        self._getKeyStatusKind = "manual"
    end
    local thread = self._thread
    self._thread = nil
    if thread then pcall(task.cancel, thread) end
    if self.SubmitButton then self.SubmitButton.Active = true end
    if self.Input then self.Input.TextEditable = true end
    if self.Input then self.Input.Text = "" end
    self:_Status(self.Options.CancelledText, "normal")
    self:_TrackCallback(self.Options.OnCancel, self)
    return true
end

function KeyGate:Destroy()
    if self.Destroyed then return true end
    self.Destroyed = true
    self._generation += 1
    self._copyGeneration += 1
    self._copyBusy = false
    self._getKeyGeneration += 1
    self._getKeyBusy = false
    self.Busy = false
    local threads = {}
    self._logoGeneration = (self._logoGeneration or 0) + 1
    if self._avatarThread then threads[#threads + 1] = self._avatarThread; self._avatarThread = nil end
    if self._thread then threads[#threads + 1] = self._thread; self._thread = nil end
    for _, record in ipairs(self._callbackThreads) do if record.Thread then threads[#threads + 1] = record.Thread end end
    table.clear(self._callbackThreads)
    for _, thread in ipairs(threads) do if thread ~= coroutine.running() then pcall(task.cancel, thread) end end
    for _, connection in ipairs(self._connections) do pcall(function() connection:Disconnect() end) end
    table.clear(self._connections)
    if self._cameraConnection then pcall(function() self._cameraConnection:Disconnect() end); self._cameraConnection = nil end
    release_focus(self.Gui)
    Library.KeySystems[self] = nil
    if self.Gui and not self._guiDestroying then self.Gui:Destroy() end
    return true
end

function Library:CreateKeySystem(options)
    local automaticHeight = type(options) ~= "table" or options.Height == nil
    local valid = key_options(options)
    keyGateSerial += 1
    local gate = setmetatable({
        Options = valid,
        Destroyed = false,
        Busy = false,
        Completed = false,
        _cancelled = false,
        _successCalled = false,
        Status = "",
        _generation = 0,
        _thread = nil,
        _callbackThreads = {},
        _connections = {},
        _manualLinkVisible = false,
        _discordCopyKind = nil,
        _copyGeneration = 0,
        _copyBusy = false,
        _getKeyGeneration = 0,
        _getKeyBusy = false,
        _manualKeyLinkVisible = false,
        _getKeyStatusKind = nil,
        _automaticHeight = automaticHeight,
    }, KeyGate)

    local theme, style = valid.Theme, valid.Style
    -- Drop any existing game text focus before the modal key gate takes focus.
    release_focus(valid.Parent)
    gate.Gui = create("ScreenGui", {
        Name = "GabibouUI_KeySystem_" .. keyGateSerial,
        ResetOnSpawn = false,
        ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
        DisplayOrder = valid.DisplayOrder,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, valid.Parent)
    gate.Backdrop = create("TextButton", {
        Name = "Backdrop", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = .42, Active = true, Modal = true, Text = "", AutoButtonColor = false,
    }, gate.Gui)
    gate.Card = create("Frame", {
        Name = "KeySystem", Size = UDim2.fromOffset(valid.Width, valid.Height),
        Position = valid.Position, AnchorPoint = valid.AnchorPoint,
        BackgroundColor3 = theme.Background, BorderSizePixel = 0,
    }, gate.Backdrop)
    corner(gate.Card, style.WindowRadius)
    gate.CardStroke = create("UIStroke", {Color = theme.Border, Thickness = 1, Transparency = .12}, gate.Card)
    gate.Scroll = create("ScrollingFrame", {
        Name = "ContentScroll", Position = UDim2.fromOffset(0, 0), Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.fromOffset(0, valid.Height),
        ScrollBarThickness = 4, ScrollingDirection = Enum.ScrollingDirection.Y, Active = true,
        ClipsDescendants = true,
    }, gate.Card)
    gate.Content = create("Frame", {
        Name = "Content", BackgroundTransparency = 1, Size = UDim2.new(1, -8, 0, valid.Height),
    }, gate.Scroll)
    gate.Edge = create("Frame", {
        Name = "AccentEdge", Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -40, 0, 1),
        BackgroundColor3 = theme.Accent, BackgroundTransparency = .35,
    }, gate.Content)
    create("UIGradient", {
        Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(.5, 0), NumberSequenceKeypoint.new(1, 1)}),
    }, gate.Edge)
    gate.Mark = create("Frame", {
        Name = "Mark", Position = UDim2.fromOffset(24, 24), Size = UDim2.fromOffset(42, 42),
        BackgroundColor3 = theme.Accent, BorderSizePixel = 0,
    }, gate.Content)
    corner(gate.Mark, style.ControlRadius)
    gate.MarkLabel = create("TextLabel", {
        Name = "MarkText", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
        Text = valid.MarkText, Font = style.FontBold, TextSize = style.TitleSize,
        TextColor3 = theme.AccentText, TextXAlignment = Enum.TextXAlignment.Center,
    }, gate.Mark)
    gate.MarkImage = create("ImageLabel", {
        Name = "MarkImage", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
        Image = "", ScaleType = Enum.ScaleType.Crop, Visible = false,
    }, gate.Mark)
    corner(gate.MarkImage, style.ControlRadius)
    gate.Title = create("TextLabel", {
        Name = "Title", Position = UDim2.fromOffset(78, 26), Size = UDim2.new(1, -102, 0, 25),
        BackgroundTransparency = 1, Text = valid.Title, Font = style.FontBold, TextSize = style.TitleSize,
        TextColor3 = theme.Text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, gate.Content)
    gate.Subtitle = create("TextLabel", {
        Name = "Subtitle", Position = UDim2.fromOffset(24, 82), Size = UDim2.new(1, -48, 0, 42),
        BackgroundTransparency = 1, Text = valid.Subtitle, Font = style.Font, TextSize = style.DescriptionSize,
        TextColor3 = theme.Muted, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
    }, gate.Content)
    gate.KeyLabel = create("TextLabel", {
        Name = "KeyLabel", Position = UDim2.fromOffset(44, 92), Size = UDim2.new(1, -68, 0, 18),
        BackgroundTransparency = 1, Text = valid.InputLabel, Font = style.FontBold, TextSize = style.DescriptionSize,
        TextColor3 = theme.Muted, TextXAlignment = Enum.TextXAlignment.Left,
    }, gate.Content)
    gate.KeyIcon = create("Frame", {
        Name = "KeyIcon", Position = UDim2.fromOffset(24, 95), Size = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 1,
    }, gate.Content)
    local keyRing = create("Frame", {Position = UDim2.fromOffset(0, 1), Size = UDim2.fromOffset(8, 8), BackgroundTransparency = 1}, gate.KeyIcon)
    create("UIStroke", {Color = theme.Muted, Thickness = 1.5}, keyRing)
    create("UICorner", {CornerRadius = UDim.new(1, 0)}, keyRing)
    create("Frame", {Position = UDim2.fromOffset(6, 7), Size = UDim2.fromOffset(7, 2), BackgroundColor3 = theme.Muted, BorderSizePixel = 0}, gate.KeyIcon)
    create("Frame", {Position = UDim2.fromOffset(10, 7), Size = UDim2.fromOffset(2, 4), BackgroundColor3 = theme.Muted, BorderSizePixel = 0}, gate.KeyIcon)
    gate.Input = create("TextBox", {
        Name = "KeyInput", Position = UDim2.fromOffset(24, 136), Size = UDim2.new(1, -48, 0, 44),
        BackgroundColor3 = theme.Raised, TextColor3 = theme.Text, PlaceholderColor3 = theme.Muted,
        PlaceholderText = valid.Placeholder, Text = "", ClearTextOnFocus = false,
        Font = style.Font, TextSize = style.TextSize, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, TextEditable = true, Active = true,
    }, gate.Content)
    corner(gate.Input, style.ControlRadius)
    create("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, gate.Input)
    gate.InputStroke = create("UIStroke", {Color = theme.Border, Thickness = 1, Transparency = .35}, gate.Input)
    gate.StatusLabel = create("TextLabel", {
        Name = "Status", Position = UDim2.new(0, 24, 0, valid.Height - 82), Size = UDim2.new(1, -48, 0, 20),
        BackgroundTransparency = 1, Text = "", Font = style.Font, TextSize = style.DescriptionSize,
        TextColor3 = theme.Muted, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, gate.Content)
    gate.CancelButton = create("TextButton", {
        Name = "Cancel", Position = UDim2.new(1, -198, 0, valid.Height - 60), Size = UDim2.fromOffset(78, 44),
        BackgroundColor3 = theme.Surface, Text = valid.CancelText, Font = style.FontBold,
        TextSize = style.TextSize, TextColor3 = theme.Text, AutoButtonColor = false, Selectable = true,
    }, gate.Content)
    corner(gate.CancelButton, style.ControlRadius)
    gate.CancelStroke = create("UIStroke", {Color = theme.Border, Thickness = 1, Transparency = .35}, gate.CancelButton)
    gate.SubmitButton = create("TextButton", {
        Name = "Verify", Position = UDim2.new(1, -110, 0, valid.Height - 60), Size = UDim2.fromOffset(86, 44),
        BackgroundColor3 = theme.Accent, Text = valid.SubmitText, Font = style.FontBold,
        TextSize = style.TextSize, TextColor3 = theme.AccentText, AutoButtonColor = false, Selectable = true,
    }, gate.Content)
    corner(gate.SubmitButton, style.ControlRadius)
    gate.DiscordButton = create("TextButton", {
        Name = "DiscordButton", Position = UDim2.fromOffset(24, valid.Height - 50), Size = UDim2.new(1, -48, 0, 44),
        BackgroundColor3 = type(valid.Discord) == "table" and valid.Discord.Color or Color3.fromRGB(88, 101, 242),
        Text = "", AutoButtonColor = false, Selectable = true, Visible = type(valid.Discord) == "table",
    }, gate.Content)
    corner(gate.DiscordButton, style.ControlRadius)
    gate.DiscordIcon = create("Frame", {Name = "DiscordIcon", Position = UDim2.fromOffset(14, 11), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1}, gate.DiscordButton)
    gate.DiscordVector = create("Frame", {Name = "DiscordVector", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = type(valid.Discord) == "table" and valid.Discord.Logo == nil}, gate.DiscordIcon)
    -- Antialiased Clyde silhouette from Discord's official brand kit; see THIRD_PARTY.md.
    local discordSpans={
        {6,2,1,15},
        {7,2,1,52},
        {14,2,1,50},
        {15,2,1,14},
        {3,3,1,9},
        {4,3,1,88},
        {5,3,1,172},
        {6,3,1,230},
        {7,3,1,255},
        {8,3,1,110},
        {9,3,1,60},
        {10,3,2,80},
        {12,3,1,60},
        {13,3,1,115},
        {14,3,1,255},
        {15,3,1,229},
        {16,3,1,172},
        {17,3,1,87},
        {18,3,1,8},
        {2,4,1,7},
        {3,4,1,198},
        {4,4,3,255},
        {7,4,1,254},
        {8,4,6,255},
        {14,4,1,254},
        {15,4,3,255},
        {18,4,1,193},
        {19,4,1,5},
        {0,5,1,4},
        {2,5,1,115},
        {3,5,1,255},
        {4,5,1,249},
        {5,5,1,252},
        {6,5,1,254},
        {7,5,1,255},
        {8,5,1,254},
        {9,5,1,253},
        {10,5,2,252},
        {12,5,1,253},
        {13,5,1,254},
        {14,5,1,255},
        {15,5,1,254},
        {16,5,1,252},
        {17,5,1,249},
        {18,5,1,255},
        {19,5,1,112},
        {21,5,1,4},
        {1,6,1,17},
        {2,6,1,237},
        {3,6,2,253},
        {5,6,12,255},
        {17,6,2,253},
        {19,6,1,235},
        {20,6,1,17},
        {1,7,1,113},
        {2,7,1,255},
        {3,7,1,251},
        {4,7,2,255},
        {6,7,1,253},
        {7,7,1,251},
        {8,7,1,254},
        {9,7,4,255},
        {13,7,1,254},
        {14,7,1,251},
        {15,7,1,253},
        {16,7,2,255},
        {18,7,1,251},
        {19,7,1,255},
        {20,7,1,111},
        {0,8,1,4},
        {1,8,1,209},
        {2,8,1,254},
        {3,8,1,252},
        {4,8,1,255},
        {5,8,1,254},
        {6,8,3,255},
        {9,8,1,254},
        {10,8,2,255},
        {12,8,1,254},
        {13,8,3,255},
        {16,8,1,254},
        {17,8,1,255},
        {18,8,1,252},
        {19,8,1,254},
        {20,8,1,207},
        {0,9,1,56},
        {1,9,1,254},
        {2,9,2,255},
        {4,9,1,254},
        {5,9,1,255},
        {6,9,1,209},
        {7,9,1,163},
        {8,9,1,233},
        {9,9,1,255},
        {10,9,2,254},
        {12,9,1,255},
        {13,9,1,233},
        {14,9,1,163},
        {15,9,1,210},
        {16,9,1,255},
        {17,9,1,254},
        {18,9,1,255},
        {19,9,1,254},
        {20,9,1,252},
        {21,9,1,54},
        {0,10,1,122},
        {1,10,1,255},
        {2,10,2,252},
        {4,10,1,255},
        {5,10,1,197},
        {6,10,1,7},
        {8,10,1,36},
        {9,10,1,235},
        {10,10,2,254},
        {12,10,1,235},
        {13,10,1,36},
        {15,10,1,8},
        {16,10,1,198},
        {17,10,1,254},
        {18,10,2,252},
        {20,10,1,255},
        {21,10,1,123},
        {0,11,1,179},
        {1,11,1,255},
        {2,11,1,252},
        {3,11,1,251},
        {4,11,1,255},
        {5,11,1,99},
        {7,11,1,13},
        {9,11,1,162},
        {10,11,2,255},
        {12,11,1,161},
        {14,11,1,13},
        {16,11,1,102},
        {17,11,1,255},
        {18,11,1,251},
        {19,11,1,252},
        {20,11,1,255},
        {21,11,1,175},
        {0,12,1,215},
        {1,12,1,255},
        {2,12,1,254},
        {3,12,1,251},
        {4,12,1,255},
        {5,12,1,126},
        {9,12,1,189},
        {10,12,2,255},
        {12,12,1,185},
        {16,12,1,131},
        {17,12,1,255},
        {18,12,1,251},
        {19,12,1,254},
        {20,12,1,255},
        {21,12,1,214},
        {0,13,1,232},
        {1,13,1,255},
        {2,13,3,254},
        {5,13,1,236},
        {6,13,1,69},
        {7,13,1,20},
        {8,13,1,109},
        {9,13,1,254},
        {10,13,3,253},
        {13,13,1,108},
        {14,13,1,20},
        {15,13,1,70},
        {16,13,1,237},
        {17,13,3,254},
        {20,13,1,255},
        {21,13,1,230},
        {0,14,1,242},
        {1,14,6,255},
        {7,14,1,238},
        {8,14,6,255},
        {14,14,1,238},
        {15,14,6,255},
        {21,14,1,238},
        {0,15,1,244},
        {1,15,2,253},
        {3,15,2,255},
        {5,15,1,252},
        {6,15,2,255},
        {8,15,1,254},
        {9,15,1,252},
        {10,15,2,251},
        {12,15,1,252},
        {13,15,1,254},
        {14,15,2,255},
        {16,15,1,252},
        {17,15,2,255},
        {19,15,2,253},
        {21,15,1,243},
        {0,16,1,169},
        {1,16,2,255},
        {3,16,1,250},
        {4,16,1,253},
        {5,16,1,160},
        {6,16,1,138},
        {7,16,1,215},
        {8,16,1,251},
        {9,16,4,255},
        {13,16,1,251},
        {14,16,1,215},
        {15,16,1,137},
        {16,16,1,161},
        {17,16,1,253},
        {18,16,1,250},
        {19,16,2,255},
        {21,16,1,169},
        {1,17,1,96},
        {2,17,1,225},
        {3,17,2,255},
        {5,17,1,251},
        {6,17,1,153},
        {8,17,1,40},
        {9,17,1,71},
        {10,17,2,94},
        {12,17,1,71},
        {13,17,1,40},
        {15,17,1,157},
        {16,17,1,251},
        {17,17,2,255},
        {19,17,1,225},
        {20,17,1,99},
        {2,18,1,16},
        {3,18,1,110},
        {4,18,1,208},
        {5,18,1,255},
        {6,18,1,82},
        {15,18,1,85},
        {16,18,1,255},
        {17,18,1,210},
        {18,18,1,112},
        {19,18,1,16},
        {5,19,1,44},
        {10,19,2,4},
        {16,19,1,45},
        {3,20,1,4},
        {18,20,1,4},
    }
    for _,span in ipairs(discordSpans)do
        create("Frame",{Name="DiscordSilhouette",Position=UDim2.fromScale(span[1]/22,span[2]/22),Size=UDim2.fromScale(span[3]/22,1/22),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1-span[4]/255,BorderSizePixel=0},gate.DiscordVector)
    end
    local logoWhite=Color3.new(1,1,1)
    gate.DiscordImage = create("ImageLabel", {
        Name = "DiscordImage", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        Image = type(valid.Discord) == "table" and valid.Discord.Logo or "", ImageColor3 = logoWhite,
        ScaleType = Enum.ScaleType.Fit, Visible = type(valid.Discord) == "table" and valid.Discord.Logo ~= nil,
    }, gate.DiscordIcon)
    gate.DiscordLabel = create("TextLabel", {
        Name = "DiscordText", Position = UDim2.fromOffset(44, 0), Size = UDim2.new(1, -54, 1, 0),
        BackgroundTransparency = 1, Text = type(valid.Discord) == "table" and valid.Discord.Text or "",
        Font = style.FontBold, TextSize = style.TextSize, TextColor3 = Color3.new(1, 1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
    }, gate.DiscordButton)
    gate.DiscordStatus = create("TextLabel", {
        Name = "DiscordStatus", Position = UDim2.fromOffset(24, valid.Height - 2), Size = UDim2.new(1, -48, 0, 18),
        BackgroundTransparency = 1, Text = "", Font = style.Font, TextSize = style.DescriptionSize,
        TextColor3 = theme.Muted, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        Visible = false,
    }, gate.Content)
    gate.DiscordLink = create("TextBox", {
        Name = "DiscordLink", Position = UDim2.fromOffset(24, valid.Height + 18), Size = UDim2.new(1, -48, 0, 38),
        BackgroundColor3 = theme.Raised, TextColor3 = theme.Text, Text = "", ClearTextOnFocus = false,
        TextEditable = false, Selectable = true, Font = style.Font, TextSize = style.TextSize,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Visible = false,
    }, gate.Content)
    corner(gate.DiscordLink, style.ControlRadius)
    create("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, gate.DiscordLink)
    create("UIStroke", {Color = theme.Border, Thickness = 1, Transparency = .35}, gate.DiscordLink)

    gate.GetKeyButton = create("TextButton", {
        Name = "GetKeyButton", Position = UDim2.fromOffset(24, valid.Height - 50), Size = UDim2.fromOffset(1, 44),
        BackgroundColor3 = theme.Surface, Text = "", AutoButtonColor = false, Selectable = true,
        Visible = valid.GetKey ~= nil and valid.GetKey ~= false,
    }, gate.Content)
    corner(gate.GetKeyButton, style.ControlRadius)
    create("UIStroke", {Color = theme.Border, Thickness = 1, Transparency = .35}, gate.GetKeyButton)
    gate.GetKeyIcon = Library:Icon(gate.GetKeyButton, "link", {
        Size = 18, Position = UDim2.fromOffset(12, 12), Color = theme.Muted, Name = "GetKeyIcon",
    })
    gate.GetKeyLabel = create("TextLabel", {
        Name = "GetKeyText", Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -48, 1, 0),
        BackgroundTransparency = 1, Text = type(valid.GetKey) == "table" and valid.GetKey.Text or "Get key",
        Font = style.FontBold, TextSize = style.TextSize, TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Center,
    }, gate.GetKeyButton)
    gate.KeyLinkStatus = create("TextLabel", {
        Name = "KeyLinkStatus", Position = UDim2.fromOffset(24, valid.Height - 2), Size = UDim2.new(1, -48, 0, 18),
        BackgroundTransparency = 1, Text = "", Font = style.Font, TextSize = style.DescriptionSize,
        TextColor3 = theme.Muted, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        Visible = false,
    }, gate.Content)
    gate.KeyLink = create("TextBox", {
        Name = "KeyLink", Position = UDim2.fromOffset(24, valid.Height + 18), Size = UDim2.new(1, -48, 0, 38),
        BackgroundColor3 = theme.Raised, TextColor3 = theme.Text, Text = "", ClearTextOnFocus = false,
        TextEditable = false, Selectable = true, Font = style.Font, TextSize = style.TextSize,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Visible = false,
    }, gate.Content)
    corner(gate.KeyLink, style.ControlRadius)
    create("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, gate.KeyLink)
    create("UIStroke", {Color = theme.Border, Thickness = 1, Transparency = .35}, gate.KeyLink)

    local function connect(signal, callback)
        local connection = signal:Connect(function(...)
            if not gate.Destroyed then callback(...) end
        end)
        gate._connections[#gate._connections + 1] = connection
        return connection
    end
    connect(gate.SubmitButton.Activated, function() gate:Submit() end)
    connect(gate.CancelButton.Activated, function() gate:Cancel() end)
    connect(gate.DiscordButton.Activated, function() gate:_TrackCallback(function() gate:CopyDiscordLink() end) end)
    connect(gate.GetKeyButton.Activated, function() gate:_TrackCallback(function() gate:GetKey() end) end)
    connect(gate.Input.FocusLost, function(enterPressed) if enterPressed then gate:Submit() end end)
    connect(gate.Input:GetPropertyChangedSignal("Text"), function()
        local ok, limited = pcall(Logic.text, gate.Input.Text, valid.MaxLength)
        if not ok then
            gate.Input.Text = ""
            gate:_Status(valid.InvalidText, "error")
        elseif limited ~= gate.Input.Text then
            gate.Input.Text = limited
        end
    end)
    connect(gate.Input.Focused, function()
        task.defer(function() if not gate.Destroyed then gate:_Layout(); gate:_RevealInput() end end)
    end)
    for _, property in ipairs({"OnScreenKeyboardVisible", "OnScreenKeyboardPosition", "OnScreenKeyboardSize"}) do
        connect(UIS:GetPropertyChangedSignal(property), function() gate:_Layout() end)
    end
    connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function() gate:_WatchCamera() end)
    connect(gate.Backdrop:GetPropertyChangedSignal("AbsoluteSize"), function() gate:_Layout() end)
    connect(gate.Gui.Destroying, function()
        gate._guiDestroying = true
        gate:Destroy()
    end)
    Library.KeySystems[gate] = true
    gate:_WatchCamera()
    gate:_StartLogo()
    return gate
end

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
            local tab = window:Tab({Title = tabSpec.Title, Icon = tabSpec.Icon,IconVariant=tabSpec.IconVariant,Layout=tabSpec.Layout})
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

-- Compact, typed notifications. Destroy is immediate; Dismiss animates then destroys.
Library.Notifications={Position="BottomRight",Width=340,Margin=18,Gap=10,MaxVisible=4,Duration=4,ShowProgress=true,AnimationDuration=.18}
notification_for=function(options,base)
    assert(options==nil or type(options)=="table","Notifications must be a table")
    local result=table.clone(base)
    for key,value in pairs(options or {})do assert(result[key]~=nil,"Unknown Notifications option: "..tostring(key));result[key]=value end
    assert(result.Position=="TopRight"or result.Position=="BottomRight"or result.Position=="TopLeft"or result.Position=="BottomLeft","Invalid notification Position")
    for key,range in pairs({Width={220,600},Margin={4,64},Gap={0,32},MaxVisible={1,8},Duration={.1,120},AnimationDuration={0,.8}})do
        assert(Logic.finite(result[key])and result[key]>=range[1]and result[key]<=range[2],"Notifications."..key.." is out of range")
    end
    assert(result.MaxVisible%1==0,"MaxVisible must be an integer")
    assert(type(result.ShowProgress)=="boolean","ShowProgress must be boolean")
    return result
end
function Library:SetNotifications(options)self.Notifications=notification_for(options,self.Notifications);return self end
function Window:SetNotifications(options)
    assert(not self.Destroyed,"Window is destroyed")
    self.Notifications=notification_for(options,self.Notifications)
    while #self._notifications>self.Notifications.MaxVisible do self._notifications[1]:Destroy()end
    self:_LayoutNotifications();return self
end
function Window:_LayoutNotifications()
    if self.Destroyed or not self.ToastHost then return end
    local settings=self.Notifications;local viewport=self:_Viewport()
    local margin=math.min(settings.Margin,math.max(0,(math.min(viewport.X,viewport.Y)-1)/2))
    local width=math.max(1,math.min(settings.Width,viewport.X-margin*2))
    local right=settings.Position:find("Right",1,true)~=nil
    local bottom=settings.Position:find("Bottom",1,true)~=nil
    self.ToastHost.AnchorPoint=Vector2.new(right and 1 or 0,bottom and 1 or 0)
    self.ToastHost.Position=UDim2.new(right and 1 or 0,right and -margin or margin,bottom and 1 or 0,bottom and -margin or margin)
    self.ToastHost.Size=UDim2.fromOffset(width,math.max(1,viewport.Y-margin*2))
    local flow=self.ToastHost:FindFirstChildOfClass("UIListLayout")
    flow.Padding=UDim.new(0,settings.Gap);flow.HorizontalAlignment=right and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
    flow.VerticalAlignment=bottom and Enum.VerticalAlignment.Bottom or Enum.VerticalAlignment.Top
    local availableHeight=math.max(1,viewport.Y-margin*2)
    local totalHeight=0
    for _,toast in ipairs(self._notifications)do
        local textLeft=60
        local textWidth=math.max(1,width-textLeft-44-12)
        local bounds=TextService:GetTextSize(toast.Content,self.Style.DescriptionSize,self.Style.Font,Vector2.new(textWidth,1000))
        local textHeight=toast.Content==""and 0 or math.min(bounds.Y+2,self.Style.DescriptionSize*5+10)
        local height=math.min(availableHeight,math.max(72,50+textHeight))
        toast.Root.Size=UDim2.new(1,0,0,height)
        toast.Title.Position=UDim2.fromOffset(textLeft,14)
        toast.Title.Size=UDim2.new(1,-(textLeft+56),0,22)
        toast.Description.Position=UDim2.fromOffset(textLeft,39)
        toast.Description.Size=UDim2.fromOffset(textWidth,textHeight)
        toast.Description.Visible=height>=72
        toast.Progress.Visible=settings.ShowProgress
        totalHeight+=height+settings.Gap
    end
    totalHeight-=settings.Gap
    while #self._notifications>1 and totalHeight>availableHeight do
        local oldest=self._notifications[1]
        totalHeight-=oldest.Root.Size.Y.Offset+settings.Gap
        oldest:Destroy()
    end
    for property,value in pairs(self._partLayouts.Notifications or {})do self.ToastHost[property]=value end
end
function Window:Notify(options)
    if self.Destroyed then return nil end
    assert(options==nil or type(options)=="table","Notification must be a table")
    options=options or {}
    local settings=self.Notifications
    local duration=options.Duration or settings.Duration
    assert(Logic.finite(duration)and duration>=.1 and duration<=120,"Notification duration must be .1..120 seconds")
    assert(options.Title==nil or type(options.Title)=="string","Notification Title must be a string")
    assert(options.Content==nil or type(options.Content)=="string","Notification Content must be a string")
    local title=Logic.text(options.Title or "Notification",80)
    local content=Logic.text(options.Content or "",1200)
    local kind=options.Kind or "info"
    local kinds={info={"info","Accent"},success={"check","Success"},warning={"bell","Accent"},error={"close","Danger"}}
    assert(kinds[kind],"Notification Kind must be info, success, warning or error")
    local iconName=Library:GetIconName(options.Icon or kinds[kind][1])
    assert(iconName~=nil,"Unknown notification Icon")
    while #self._notifications>=settings.MaxVisible do self._notifications[1]:Destroy()end
    self._notificationSerial=(self._notificationSerial or 0)+1
    local toast={Destroyed=false,Dismissing=false,_connections={},Content=content,Kind=kind}
    local root=create("Frame",{Name="Notification",BackgroundTransparency=1,LayoutOrder=self._notificationSerial,Size=UDim2.new(1,0,0,90)},self.ToastHost)
    toast.Root=root
    local card=create("CanvasGroup",{Name="Card",Size=UDim2.fromScale(1,1),GroupTransparency=self.ReducedMotion and 0 or 1,Position=UDim2.fromOffset(self.ReducedMotion and 0 or 12,0)},root)
    toast.Card=card;self:_Rounded(card,"SectionRadius");self:_Color(card,"BackgroundColor3","Surface");self:_Stroke(card,"Border",.28)
    local token=kinds[kind][2]
    local badge=create("Frame",{Name="IconBadge",BackgroundTransparency=.84,Size=UDim2.fromOffset(34,34),Position=UDim2.new(0,16,.5,0),AnchorPoint=Vector2.new(0,.5)},card)
    corner(badge,11);self:_Color(badge,"BackgroundColor3",token);self:_Stroke(badge,token,.72)
    toast.IconBadge=badge
    toast.Icon=Library:Icon(badge,iconName,{Size=18,Position=UDim2.fromOffset(8,8),Window=self,Token=token})
    local heading=self:_Label(card,title,self.Style.TextSize,"Text");heading.Name="Title";heading.Position=UDim2.fromOffset(60,14);heading.Size=UDim2.new(1,-116,0,22);heading.AutomaticSize=Enum.AutomaticSize.None;heading.TextWrapped=false;heading.TextTruncate=Enum.TextTruncate.AtEnd
    self:_Style(heading,"Font","FontBold");self:_Style(heading,"TextSize","TextSize");toast.Title=heading
    local body=self:_Label(card,content,self.Style.DescriptionSize,"Muted");body.Name="Content";body.Position=UDim2.fromOffset(60,39);body.AutomaticSize=Enum.AutomaticSize.None;body.TextYAlignment=Enum.TextYAlignment.Top;body.TextTruncate=Enum.TextTruncate.AtEnd;self:_Style(body,"TextSize","DescriptionSize");toast.Description=body
    local close=create("TextButton",{Name="Dismiss",Text="",AutoButtonColor=false,BackgroundTransparency=1,Size=UDim2.fromOffset(44,44),Position=UDim2.new(1,-44,0,4),Selectable=true},card)
    self:_Rounded(close,"ControlRadius");self:_Color(close,"BackgroundColor3","Hover")
    Library:Icon(close,"close",{Size=14,Position=UDim2.fromOffset(15,15),Window=self,Token="Muted"});toast.CloseButton=close
    local track=create("Frame",{Name="ProgressTrack",BackgroundTransparency=.82,Position=UDim2.new(0,14,1,-4),Size=UDim2.new(1,-28,0,1)},card);self:_Color(track,"BackgroundColor3","Border")
    toast.Progress=track
    local fill=create("Frame",{Size=UDim2.fromScale(1,1)},track);self:_Color(fill,"BackgroundColor3",token);toast.Fill=fill
    local window=self
    function toast:Destroy()
        if self.Destroyed then return end
        self.Destroyed=true;disconnect(self._connections,self)
        for _,key in ipairs({"_timer","_exitThread"})do
            local thread=self[key];self[key]=nil
            if thread and thread~=coroutine.running()and coroutine.status(thread)~="dead"then task.cancel(thread)end
        end
        if self._progressTween then self._progressTween:Cancel();self._progressTween=nil end
        window:_ForgetTree(root)
        if not self._rootDestroying then root:Destroy()end
        for index,entry in ipairs(window._notifications)do if entry==self then table.remove(window._notifications,index);break end end
    end
    function toast:Dismiss()
        if self.Destroyed or self.Dismissing then return self end
        self.Dismissing=true
        if window.ReducedMotion or settings.AnimationDuration==0 or window.Destroyed then self:Destroy();return self end
        window:Animate(card,{GroupTransparency=1,Position=UDim2.fromOffset(12,0)},{Duration=settings.AnimationDuration})
        self._exitThread=task.delay(settings.AnimationDuration,function()self._exitThread=nil;self:Destroy()end)
        return self
    end
    self._notifications[#self._notifications+1]=toast
    self:_Connect(close.Activated,function()toast:Dismiss()end,toast)
    self:_Connect(close.MouseEnter,function()window:_Tween(close,{BackgroundTransparency=.9})end,toast)
    self:_Connect(close.MouseLeave,function()window:_Tween(close,{BackgroundTransparency=1})end,toast)
    self:_Connect(close.SelectionGained,function()window:_Tween(close,{BackgroundTransparency=.9})end,toast)
    self:_Connect(close.SelectionLost,function()window:_Tween(close,{BackgroundTransparency=1})end,toast)
    self:_Connect(root.Destroying,function()toast._rootDestroying=true;toast:Destroy()end,toast)
    self:_LayoutNotifications()
    if not self.ReducedMotion and settings.AnimationDuration>0 then self:Animate(card,{GroupTransparency=0,Position=UDim2.new()},{Duration=settings.AnimationDuration})else card.GroupTransparency=0;card.Position=UDim2.new()end
    toast._progressTween=TweenService:Create(fill,TweenInfo.new(duration,Enum.EasingStyle.Linear),{Size=UDim2.fromScale(0,1)});toast._progressTween:Play()
    toast._timer=task.delay(duration,function()toast._timer=nil;toast:Dismiss()end)
    return toast
end

return Library
