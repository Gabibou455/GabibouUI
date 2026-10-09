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
