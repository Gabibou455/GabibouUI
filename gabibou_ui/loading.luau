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
local function accent_glow(theme)
    local highlight=theme.Accent:Lerp(theme.Text,.18)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0,theme.Accent),
        ColorSequenceKeypoint.new(.5,highlight),
        ColorSequenceKeypoint.new(1,theme.Accent),
    })
end
local function loader_options(options,base)
    assert(options==nil or type(options)=="table","Loading must be a table")
    options=resolve_design_options(options,"loader")
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
    result.LogoSize=result.LogoSize or 56
    result.ShowPercentage=result.ShowPercentage==nil and true or result.ShowPercentage
    result.ShowLogo=result.ShowLogo==nil and true or result.ShowLogo
    result.ShowActivity=result.ShowActivity==nil and true or result.ShowActivity
    result.ShowSubtitle=result.ShowSubtitle==nil and true or result.ShowSubtitle
    result.ProgressHeight=result.ProgressHeight or 4
    result.BackgroundTransparency=result.BackgroundTransparency==nil and .3 or result.BackgroundTransparency
    result.CardTransparency=result.CardTransparency==nil and .1 or result.CardTransparency
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
    assert(Logic.finite(result.CardTransparency) and result.CardTransparency>=0 and result.CardTransparency<=1,"CardTransparency must be 0..1")
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
    local minimal=self.Options.Variant=="Minimal"
    local canShowMark=self.Options.ShowLogo and not minimal and width>=2*p+logo+96
    local compact=height<math.max(180,(canShowMark and logo or 0)+2*p+60)
    if compact then p=math.min(p,math.max(12,(height-120)/2))end
    local footerY=math.max(p,height-p-44)
    local centered=self.Options.Variant=="Centered" and height>=260
    local showMark=self.Options.ShowLogo and not compact and not minimal and width>=2*p+logo+96
    if centered and showMark then
        local candidateTextTop=p+logo+14
        local candidateHeaderBottom=candidateTextTop+(self.Options.ShowSubtitle and 70 or 26)
        if candidateHeaderBottom>footerY-12 then showMark=false end
    end
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
    local edgeWidth=centered and 56 or 36
    self.Edge.Position=UDim2.fromOffset(centered and (width-edgeWidth)/2 or p,0);self.Edge.Size=UDim2.fromOffset(edgeWidth,2)
    local statusHeight=20
    self.Percent.Visible=self.Options.ShowPercentage and height>=130 and width>=2*p+120
    self.StatusLabel.Visible=height>=130
    self.StatusIndicator.Visible=self.StatusLabel.Visible
    self.StatusIndicator.Position=UDim2.fromOffset(p+2,footerY+7);self.StatusIndicator.Size=UDim2.fromOffset(6,6)
    self.StatusLabel.Position=UDim2.fromOffset(p+14,footerY);self.StatusLabel.Size=UDim2.new(1,-(2*p+14+(self.Percent.Visible and 68 or 0)),0,statusHeight)
    self.Percent.Position=UDim2.new(1,-(p+52),0,footerY);self.Percent.Size=UDim2.fromOffset(52,statusHeight)
    self.Track.Position=UDim2.new(0,p,1,-(p+self.Options.ProgressHeight));self.Track.Size=UDim2.new(1,-2*p,0,self.Options.ProgressHeight)
    self.StatusPanel.Position=UDim2.fromOffset(p-12,footerY-8)
    self.StatusPanel.Size=UDim2.new(1,-2*(p-12),0,60)
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
        Title=self.Title,Subtitle=self.Subtitle,StatusPanel=self.StatusPanel,Status=self.StatusLabel,StatusIndicator=self.StatusIndicator,Percentage=self.Percent,Track=self.Track,
        Fill=self.Fill,Activity=self.Activity,Content=self.Content}
end
local loaderLayoutParts={Logo=true,Title=true,Subtitle=true,StatusPanel=true,Status=true,StatusIndicator=true,Percentage=true,Track=true,Content=true}
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
function Loader:_CancelEntrance()
    for _, record in ipairs(self._entranceTweens) do
        if record.Connection then record.Connection:Disconnect() end
        pcall(function() record.Tween:Cancel() end)
    end
    table.clear(self._entranceTweens)
end
function Loader:_FinishEntrance()
    self:_CancelEntrance()
    self.Border.Transparency = .15
    self.Edge.BackgroundTransparency = .5
    self.MarkStroke.Transparency = .18
    self.StatusPanel.BackgroundTransparency = self.Options.Variant == "Minimal" and .34 or .14
    self.StatusPanelStroke.Transparency = self.Options.Variant == "Minimal" and .48 or .22
    self.Title.TextTransparency = 0
    self.Subtitle.TextTransparency = 0
    self.StatusLabel.TextTransparency = 0
    self.Percent.TextTransparency = 0
end
function Loader:_TweenEntrance(instance, duration, goals)
    local tween = TweenService:Create(instance, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goals)
    local record = {Tween = tween}
    record.Connection = tween.Completed:Connect(function()
        if record.Connection then record.Connection:Disconnect(); record.Connection = nil end
        for index, active in ipairs(self._entranceTweens) do
            if active == record then table.remove(self._entranceTweens, index); break end
        end
    end)
    self._entranceTweens[#self._entranceTweens + 1] = record
    tween:Play()
end
function Loader:_StartEntrance()
    if self.Options.ReducedMotion then return end
    local reveal = {
        {self.Border, "Transparency", .62, .15},
        {self.Edge, "BackgroundTransparency", .88, .5},
        {self.MarkStroke, "Transparency", .62, .18},
        {self.StatusPanel, "BackgroundTransparency", .58, self.Options.Variant == "Minimal" and .34 or .14},
        {self.StatusPanelStroke, "Transparency", .62, self.Options.Variant == "Minimal" and .48 or .22},
        {self.Title, "TextTransparency", .34, 0},
        {self.Subtitle, "TextTransparency", .42, 0},
        {self.StatusLabel, "TextTransparency", .34, 0},
        {self.Percent, "TextTransparency", .42, 0},
    }
    for _, item in ipairs(reveal) do
        local instance, property, initial, target = item[1], item[2], item[3], item[4]
        instance[property] = initial
        self:_TweenEntrance(instance, .2, {[property] = target})
    end
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
    self.Card.BackgroundColor3=theme.Background;self.Card.BackgroundTransparency=valid.CardTransparency
    self.Border.Color=theme.Border;self.Edge.BackgroundColor3=theme.Accent;self.EdgeGradient.Color=accent_glow(theme);self.StatusIndicator.BackgroundColor3=theme.Accent
    self.Mark.BackgroundColor3=theme.Raised;self.MarkStroke.Color=theme.Border;self.MarkTextLabel.TextColor3=theme.Text
    self.MarkTextLabel.Font=style.FontBold;self.MarkTextLabel.TextSize=style.TitleSize+2
    self.Title.Text=valid.Title;self.Title.Font=style.FontBold;self.Title.TextSize=style.TitleSize+2;self.Title.TextColor3=theme.Text
    self.Subtitle.Text=valid.Subtitle;self.Subtitle.Font=style.Font;self.Subtitle.TextSize=style.DescriptionSize;self.Subtitle.TextColor3=theme.Muted
    self.StatusLabel.Font=style.Font;self.StatusLabel.TextSize=style.DescriptionSize;self.StatusLabel.TextColor3=theme.Text
    self.Percent.Font=style.Font;self.Percent.TextSize=style.DescriptionSize;self.Percent.TextColor3=theme.Muted
    self.Track.BackgroundColor3=theme.Raised;self.Fill.BackgroundColor3=theme.Accent;self.Activity.BackgroundColor3=theme.Text
    self.StatusPanel.BackgroundColor3=theme.Surface;self.StatusPanel.BackgroundTransparency=valid.Variant=="Minimal" and .34 or .14
    self.StatusPanelStroke.Color=theme.Border;self.StatusPanelStroke.Transparency=valid.Variant=="Minimal" and .48 or .22
    self.CardCorner.CornerRadius=UDim.new(0,style.WindowRadius)
    self.MarkCorner.CornerRadius=UDim.new(0,math.min(12,valid.LogoSize/3))
    self.MarkImageCorner.CornerRadius=self.MarkCorner.CornerRadius
    self.TrackCorner.CornerRadius=UDim.new(0,3);self.FillCorner.CornerRadius=UDim.new(0,3)
    self.StatusPanelCorner.CornerRadius=UDim.new(0,style.ControlRadius)
    if logoChanged then self:_StartLogo() end
    self.Mark.Visible=valid.ShowLogo
    self.MarkImage.Visible=valid.ShowLogo and self.MarkImage.Image~=""
    self.Root.BackgroundTransparency=valid.BackgroundTransparency
    self:_Layout();self:_SetActivity()
end
function Loader:Update(options)
    assert(not self.Destroyed and not self.Completed,"Loader is closed or completing")
    assert(type(options)=="table","Update expects an options table")
    assert(options.Design==nil,"Design is constructor-only; update Theme, Style or loader options directly")
    local previous=self.Options
    local valid=loader_options(options,previous)
    local logoChanged=valid.Logo~=previous.Logo or valid.MarkText~=previous.MarkText
    self:_FinishEntrance()
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
    self:_CancelEntrance()
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
        self:_FinishEntrance()
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
    options=resolve_design_options(options,"loader")
    local valid=loader_options(options)
    local self=setmetatable({Options=valid,Progress=0,Status="Starting",Completed=false,Destroyed=false,_connections={},_tweens={},_entranceTweens={},_owned={},_partLayouts={},_started=os.clock()},Loader)
    local theme,style=valid.Theme,valid.Style
    release_focus(valid.Parent)
    self.Gui=create("ScreenGui",{Name="GabibouUI_Loading",ResetOnSpawn=false,ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,DisplayOrder=valid.DisplayOrder,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},valid.Parent)
    self.Root=create("TextButton",{Name="LoadingOverlay",Size=UDim2.fromScale(1,1),Text="",AutoButtonColor=false,Modal=true,Active=true,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=valid.BackgroundTransparency},self.Gui)
    self.Card=create("Frame",{Name="LoadingCard",Position=valid.Position,AnchorPoint=valid.AnchorPoint,BackgroundColor3=theme.Background,BackgroundTransparency=valid.CardTransparency,ClipsDescendants=true},self.Root)
    self.CardCorner=Instance.new("UICorner");self.CardCorner.CornerRadius=UDim.new(0,style.WindowRadius);self.CardCorner.Parent=self.Card
    self.Border=create("UIStroke",{Color=theme.Border,Thickness=1,Transparency=.15},self.Card)
    self.Edge=create("Frame",{BackgroundColor3=theme.Accent,BackgroundTransparency=.5},self.Card)
    self.EdgeGradient=create("UIGradient",{Color=accent_glow(theme),Rotation=0},self.Edge)
    self.Content=create("Frame",{Name="CustomContent",BackgroundTransparency=1,ClipsDescendants=true},self.Card)
    self.Mark=create("Frame",{Name="Logo",BackgroundColor3=theme.Raised,ClipsDescendants=true},self.Card)
    self.MarkCorner=Instance.new("UICorner");self.MarkCorner.Parent=self.Mark
    self.MarkStroke=create("UIStroke",{Color=theme.Border,Thickness=1,Transparency=.18},self.Mark)
    self.MarkTextLabel=create("TextLabel",{Name="Placeholder",Text=valid.MarkText,Font=style.FontBold,TextSize=20,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),TextColor3=theme.Text},self.Mark)
    self.MarkImage=create("ImageLabel",{Name="Image",Image="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ScaleType=Enum.ScaleType.Crop,Visible=false},self.Mark)
    self.MarkImageCorner=Instance.new("UICorner");self.MarkImageCorner.Parent=self.MarkImage
    self.StatusPanel=create("Frame",{Name="ProgressStatusPanel",BackgroundColor3=theme.Surface,BackgroundTransparency=.14,BorderSizePixel=0},self.Card)
    self.StatusPanelCorner=Instance.new("UICorner");self.StatusPanelCorner.CornerRadius=UDim.new(0,style.ControlRadius);self.StatusPanelCorner.Parent=self.StatusPanel
    self.StatusPanelStroke=create("UIStroke",{Color=theme.Border,Thickness=1,Transparency=.22},self.StatusPanel)
    self.Title=create("TextLabel",{Text=valid.Title,Font=style.FontBold,TextSize=style.TitleSize+2,TextColor3=theme.Text,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},self.Card)
    self.Subtitle=create("TextLabel",{Text=valid.Subtitle,Font=style.Font,TextSize=style.DescriptionSize,TextColor3=theme.Muted,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true,TextTruncate=Enum.TextTruncate.AtEnd},self.Card)
    self.StatusLabel=create("TextLabel",{Text=self.Status,Font=style.Font,TextSize=style.DescriptionSize,TextColor3=theme.Text,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},self.Card)
    self.StatusIndicator=create("Frame",{Name="StatusIndicator",BackgroundColor3=theme.Accent,BorderSizePixel=0},self.Card)
    create("UICorner",{CornerRadius=UDim.new(1,0)},self.StatusIndicator)
    self.Percent=create("TextLabel",{Text="0%",Font=style.Font,TextSize=style.DescriptionSize,TextColor3=theme.Muted,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Right},self.Card)
    self.Track=create("Frame",{BackgroundColor3=theme.Raised,ClipsDescendants=true},self.Card)
    self.TrackCorner=Instance.new("UICorner");self.TrackCorner.Parent=self.Track
    self.Fill=create("Frame",{Size=UDim2.fromScale(0,1),BackgroundColor3=theme.Accent},self.Track)
    self.FillCorner=Instance.new("UICorner");self.FillCorner.Parent=self.Fill
    self.Activity=create("Frame",{Size=UDim2.fromScale(.18,1),Position=UDim2.fromScale(-.18,0),BackgroundColor3=theme.Text,BackgroundTransparency=.55},self.Track)
    self:_StartLogo();self:_Layout();self:_StartEntrance();self:_SetActivity()
    self._connections[#self._connections+1]=self.Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()self:_Layout()end)
    self._connections[#self._connections+1]=self.Gui.Destroying:Connect(function()self._guiDestroying=true;self:Destroy()end)
    Library.Loaders[self]=true
    return self
end
