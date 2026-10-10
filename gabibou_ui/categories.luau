-- Navigation headings keep tab buttons in the shared scrolling rail.
local TabCategory={};TabCategory.__index=TabCategory

function Library:_CategoryTitle(title)
    assert(type(title)=="string" and title:match("%S") and not title:find("[%c]") and utf8.len(title) and utf8.len(title)<=80,"Category title must contain 1..80 characters without control characters")
    return title
end

function Window:_CategoryEntries()
    if not self._categoryEntries then
        self._categoryEntries={}
        for _,tab in ipairs(self.Tabs)do self._categoryEntries[#self._categoryEntries+1]={Tab=tab}end
    end
    self.Categories=self.Categories or {}
    return self._categoryEntries
end

function Window:Category(options)
    assert(not self.Destroyed,"Window is destroyed")
    if type(options)=="string"then options={Title=options}end
    assert(type(options)=="table","Category expects a title or options table")
    for key in pairs(options)do assert(key=="Title","Unknown category option: "..tostring(key))end
    local title=Library:_CategoryTitle(options.Title)
    local entries=self:_CategoryEntries()
    for _,category in ipairs(self.Categories)do if category.Title==title then return category end end
    local category=setmetatable({Window=self,Title=title,Tabs={},Destroyed=false},TabCategory)
    category.Root=create("Frame",{Name="TabCategory",BackgroundTransparency=1,Size=UDim2.new(1,-4,0,24),Visible=false},self.Nav)
    category.Label=self:_Label(category.Root,title,10,"Muted")
    category.Label.Name="CategoryTitle";category.Label.AutomaticSize=Enum.AutomaticSize.None
    category.Label.TextWrapped=false;category.Label.TextTruncate=Enum.TextTruncate.AtEnd
    self:_Style(category.Label,"Font","FontBold")
    category.Line=create("Frame",{Name="Divider",BackgroundTransparency=.72,BorderSizePixel=0},category.Root)
    self:_Color(category.Line,"BackgroundColor3","Border")
    self.Categories[#self.Categories+1]=category;entries[#entries+1]={Category=category}
    self:_LayoutCategories();return category
end

function Window:_ResolveTabCategory(value)
    if value==nil then return nil end
    if type(value)=="string"then return self:Category(value)end
    assert(type(value)=="table" and getmetatable(value)==TabCategory and value.Window==self and not value.Destroyed,"Category must belong to this window and be live")
    return value
end

function Window:_RegisterCategoryTab(tab,category)
    local entries=self:_CategoryEntries()
    -- First registration can initialize from Window.Tabs, which already contains tab.
    for index=#entries,1,-1 do if entries[index].Tab==tab then table.remove(entries,index)end end
    tab.Category=category
    if category then category.Tabs[#category.Tabs+1]=tab else entries[#entries+1]={Tab=tab}end
    self:_LayoutCategories()
end

function Window:_LayoutCategories()
    if self.Destroyed then return end
    if not self.Categories or #self.Categories==0 then
        for index,tab in ipairs(self.Tabs)do tab._button.LayoutOrder=tab.Layout.Order or index end
        return
    end
    local order=0
    local function place(tab)
        if tab and not tab.Destroyed then order+=1;tab._button.LayoutOrder=order end
    end
    local entries={}
    for index,entry in ipairs(self._categoryEntries or {})do entries[#entries+1]={Entry=entry,Index=index}end
    table.sort(entries,function(a,b)
        local left=a.Entry.Tab and a.Entry.Tab.Layout.Order or a.Index
        local right=b.Entry.Tab and b.Entry.Tab.Layout.Order or b.Index
        return left<right or left==right and a.Index<b.Index
    end)
    for _,item in ipairs(entries)do
        local entry=item.Entry
        local category=entry.Category
        if category and not category.Destroyed then
            order+=1;category.Root.LayoutOrder=order
            local visible=false
            local sorted={}
            for index,tab in ipairs(category.Tabs)do
                if not tab.Destroyed then
                    sorted[#sorted+1]={Tab=tab,Index=index}
                    visible=visible or tab._button.Visible
                end
            end
            table.sort(sorted,function(a,b)
                local left,right=a.Tab.Layout.Order or a.Index,b.Tab.Layout.Order or b.Index
                return left<right or left==right and a.Index<b.Index
            end)
            category.Root.Visible=visible
            if self.HorizontalTabs then
                local width=math.clamp((utf8.len(category.Title)or #category.Title)*6+24,56,180)
                category.Root.Size=UDim2.fromOffset(width,math.max(self.Responsive.TouchTarget,self.Layout.TabHeight))
                category.Label.Position=UDim2.new(0,10,.5,-14);category.Label.Size=UDim2.new(1,-16,0,28)
                category.Line.Position=UDim2.new(0,2,.5,-6);category.Line.Size=UDim2.fromOffset(1,12)
            else
                category.Root.Size=UDim2.new(1,-4,0,24)
                category.Label.Position=UDim2.fromOffset(12,1);category.Label.Size=UDim2.new(1,-24,0,20)
                category.Line.Position=UDim2.fromOffset(12,22);category.Line.Size=UDim2.new(1,-24,0,1)
            end
            for _,item in ipairs(sorted)do place(item.Tab)end
        else place(entry.Tab)end
    end
end

function Window:_RemoveCategoryTab(tab)
    if tab.Category then
        for index=#tab.Category.Tabs,1,-1 do if tab.Category.Tabs[index]==tab then table.remove(tab.Category.Tabs,index)end end
    end
    for index=#(self._categoryEntries or {}),1,-1 do
        if self._categoryEntries[index].Tab==tab then table.remove(self._categoryEntries,index)end
    end
    self:_LayoutCategories()
end

function TabCategory:Tab(options,iconOrOptions)
    assert(not self.Destroyed and not self.Window.Destroyed,"Category is destroyed")
    if type(options)=="string"then
        if type(iconOrOptions)=="string" or type(iconOrOptions)=="number"then iconOrOptions={Icon=iconOrOptions}end
        options=easy_options(options,iconOrOptions,nil,false)
    else
        assert(options==nil or type(options)=="table","Tab expects a title or options table")
        options=table.clone(options or {})
    end
    options.Category=self
    return self.Window:Tab(options)
end

function TabCategory:SetTitle(title)
    assert(not self.Destroyed and not self.Window.Destroyed,"Category is destroyed")
    title=Library:_CategoryTitle(title)
    for _,other in ipairs(self.Window.Categories)do assert(other==self or other.Title~=title,"Category title is already used")end
    self.Title=title;self.Label.Text=title;self.Window:SearchFor(self.Window.Query)
    self.Window:_LayoutCategories();return self
end

function TabCategory:Destroy()
    if self.Destroyed then return end
    self.Destroyed=true
    for _,tab in ipairs(table.clone(self.Tabs))do tab:Destroy()end
    local window=self.Window
    window:_ForgetTree(self.Root);self.Root:Destroy()
    for index=#window.Categories,1,-1 do if window.Categories[index]==self then table.remove(window.Categories,index)end end
    for index=#window._categoryEntries,1,-1 do if window._categoryEntries[index].Category==self then table.remove(window._categoryEntries,index)end end
    window:_LayoutCategories()
end
