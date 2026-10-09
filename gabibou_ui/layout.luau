-- Layout presets are ordinary tables. Advanced part overrides persist across reflow.
Library.Layout={TabPosition="Left",MobileTabPosition="Top",SidebarWidth=176,TabWidth=96,TabHeight=44,TabGap=8,TabIconSize=20,ContentPadding=16,ContentGap=20,HeaderHeight=76,FooterHeight=42,SearchHeight=44,SearchGap=12,PageTitleHeight=40,ButtonWidth=112,ButtonHeight=44,RowGap=8,SectionGap=16,ControlsPosition="Right",Draggable=true,Resizable=true,ShowSearch=true,ShowFooter=true,ShowHeader=true,ShowPageTitle=true}
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
    if self.Tab==self then self.Window:_LayoutCategories();self.Window:_EnsureTabVisible(self.Window.CurrentTab)end
    return self
end
