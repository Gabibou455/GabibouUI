local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local TweenService=game:GetService("TweenService")
local HttpService=game:GetService("HttpService")
local GuiService=game:GetService("GuiService")
local TextService=game:GetService("TextService")
local Library={Version="1.5.0-rc.3",Windows={}}
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
local function disconnect(connections,owner)
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
    task.spawn(function()
        if self.Destroyed or control.Destroyed or not control.Enabled then control._busy=false;return end
        local ok,err=pcall(control.Callback,table.unpack(arguments,1,arguments.n))
        control._busy=false
        if not ok and not self.Destroyed then
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
return Library
