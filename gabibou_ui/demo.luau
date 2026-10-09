-- ModuleScript: ReplicatedStorage.GabibouUI. Run this as a LocalScript.
local Library=require(game:GetService("ReplicatedStorage"):WaitForChild("GabibouUI"))
local loader=Library:CreateLoader({Title="Gabibou / Studio",Subtitle="Preparing controls and your workspace",Variant="Centered",Logo="Avatar",MinimumDuration=.8})
local window=Library:CreateWindow({
    Id="GabibouDemo",Title="Gabibou / Studio",Subtitle="Interface workshop",
    Theme="Graphite",Width=860,Height=620,
    Navigation={Variant="Soft",IconVariant="Outline"},
    Responsive={Breakpoint=620,TouchTarget=44,Margin=12},
    Branding={Mode="Avatar",Placement="BothRight"},
})
window:OnDestroy(function()loader:Destroy()end)
local workspace=window:Category("Workspace")
local overview=workspace:Tab({Title="Overview",Icon="home"})
local controls=workspace:Tab({Title="Controls",Icon="sliders"})
local appearance=workspace:Tab({Title="Appearance",Icon="palette"})
local profiles=workspace:Tab({Title="Profiles",Icon="save"})
local tools=window:Category("Tools")
local extensions=tools:Tab({Title="Extensions",Icon="code"})
local farm=tools:Tab({Title="Farm",Icon="farm",IconVariant="Duotone"})
local icons=tools:Tab({Title="Icons",Icon="panel"})
loader:SetProgress(.2,"Navigation ready")

overview:Paragraph({Title="Session",Description="Settings and examples for this interface."})
local setup=overview:Section({Title="Current setup"})
local status=setup:Paragraph({Title="Graphite",Description=""})
local function updateStatus()
    if window.Destroyed then return end
    status:SetTitle(window.ThemeName.." / "..(window.ReducedMotion and "Reduced motion" or "Standard motion"))
    status:SetDescription((window.Mobile and "Touch layout" or "Desktop layout").." - "..math.floor(window.Panel.AbsoluteSize.X).." x "..math.floor(window.Panel.AbsoluteSize.Y).." px")
end
window:On("ThemeChanged",updateStatus)
window:Connect(window.Panel:GetPropertyChangedSignal("AbsoluteSize"),updateStatus)
setup:Button({Title="Browse controls",Description="Values, text fields and shortcuts.",Text="Open",Callback=function()window:SelectTab(controls)end})
setup:Button({Title="Edit appearance",Description="Theme, corners and animation speed.",Text="Open",Callback=function()window:SelectTab(appearance)end})
setup:Button({Title="Custom components",Description="A meter built with the extension API.",Text="Open",Callback=function()window:SelectTab(extensions)end})
local loadingVariant=setup:Dropdown({Id="demo_loading_variant",Title="Loading layout",Options={"Centered","Compact","Minimal"},Value="Centered",Persistent=false})
setup:Button({Title="Loading screen",Description="Preview the selected layout with your current theme.",Text="Preview",Callback=function()
    local preview=Library:CreateLoader({Title=window.Title,Subtitle="Applying interface settings",Variant=loadingVariant:Get(),Theme=window.Theme,Style=window.Style,ReducedMotion=window.ReducedMotion,Logo="Avatar",MinimumDuration=1})
    preview:Run({
        {Title="Applying theme",Run=function()window:SetTheme(window.ThemeName=="Custom"and window.Theme or window.ThemeName)end},
        {Title="Applying style",Run=function()window:SetStyle(window.Style)end},
    })
    window:Own({Disconnect=function()preview:Destroy()end})
end})
setup:Button({Title="Access screen",Description="Interface preview. The demonstration key is demo.",Text="Preview",Callback=function()
    local gate=Library:CreateKeySystem({Title="Gabibou / Access",Subtitle="UI demonstration — enter demo to continue.",Theme=window.Theme,Style=window.Style,
        Discord={Url="https://discord.gg/your-server",Text="Copy example Discord link"},
        GetKey=function()window:Notify({Title="Get key preview",Content="The key for this interface preview is demo.",Kind="info"})end,
        Validate=function(key)return key=="demo"end,
        OnSuccess=function(g)g:Destroy();window:Notify({Title="Access confirmed",Content="The access screen is ready for your validator.",Kind="success"})end,
        OnCancel=function(g)g:Destroy()end,
    })
    window:Own({Disconnect=function()gate:Destroy()end})
end})

local values=controls:Section({Title="Values"})
values:Toggle({Id="demo_assist",Title="Enable alerts",Value=false,Callback=function(value)
    window:Notify({Title="Alerts",Content=value and "Alerts enabled."or"Alerts disabled."})
end})
values:Toggle({Id="demo_inline_status",Title="Show inline status",Description="Keep the current state beside this setting.",Value=true,Persistent=false})
local duration=values:Slider({Id="demo_amount",Title="Notification duration",Min=1,Max=10,Step=.5,Value=4})
local kind=values:Dropdown({Id="demo_mode",Title="Notification style",Options={"Neutral","Success","Warning","Error"},Value="Neutral"})
local fields=controls:Section({Title="Text and shortcuts"})
local message=fields:Input({Id="demo_name",Title="Message",Value="Saved.",Placeholder="Notification text",MaxLength=120})
local function notify()
    local types={Neutral="info",Success="success",Warning="warning",Error="error"}
    window:Notify({Title="Preview",Content=message:Get(),Duration=duration:Get(),Kind=types[kind:Get()]})
end
fields:Keybind({Id="demo_key",Title="Send notification",Description="Click to change the key; Escape cancels.",Value="F6",Callback=notify})
fields:Button({Title="Send notification",Text="Send",Callback=notify})
fields:Button({Title="Confirmation dialog",Text="Open",Callback=function()
    window:Confirm({Title="Restore default values?",Content="The notification preview will return to its initial settings.",ConfirmText="Restore",Callback=function()
        duration:Set(4,false);kind:Set("Neutral",false);message:Set("Saved.",false)
    end})
end})

loader:SetProgress(.4,"Controls ready")
local style=appearance:Section({Title="Colors"})
style:Dropdown({Id="demo_theme",Title="Theme",Options={"Graphite","Aurora","Ember"},Value="Graphite",Persistent=false,Callback=function(value)window:SetTheme(value)end})
style:ColorPicker({Id="demo_accent",Title="Accent",Description="Choose a swatch or enter a hex color.",Value="#F2F4F8",Callback=function(hex)
    local color=Color3.fromHex(hex)
    local brightness=color.R*.299+color.G*.587+color.B*.114
    window:SetTheme({Accent=color,AccentText=brightness>.55 and Color3.fromRGB(19,21,25)or Color3.fromRGB(245,246,248)})
end})
local motion=appearance:Section({Title="Shape and motion"})
motion:Dropdown({Id="demo_navigation_variant",Title="Navigation style",Options={"Soft","Classic","Pill"},Value="Soft",Persistent=false,Callback=function(value)window:SetNavigation({Variant=value})end})
motion:Dropdown({Id="demo_navigation_icons",Title="Tab icon style",Options={"Outline","Soft","Duotone"},Value="Outline",Persistent=false,Callback=function(value)window:SetNavigation({IconVariant=value})end})
motion:Slider({Id="demo_corners",Title="Corner radius",Min=0,Max=24,Step=1,Value=14,Persistent=false,Callback=function(value)
    window:SetStyle({WindowRadius=value,SectionRadius=math.max(0,value-4),ControlRadius=math.max(0,value-7)})
end})
motion:Dropdown({Id="demo_speed",Title="Transition speed",Options={"Instant","Quick","Soft"},Value="Quick",Persistent=false,Callback=function(value)
    window:SetMotion({Duration=value=="Instant"and 0 or(value=="Quick"and .16 or .35)})
end})
motion:Toggle({Id="demo_motion",Title="Reduce motion",Description="Applies final values without animated movement.",Value=window.ReducedMotion,Persistent=false,Callback=function(value)window:SetReducedMotion(value);updateStatus()end})
motion:Button({Title="Minimize interface",Description="Reopen with OPEN or RightControl.",Text="Hide",Icon="minimize",Callback=function()window:Hide()end})

local branding=appearance:Section({Title="Profile picture"})
branding:Dropdown({Id="demo_branding",Title="Picture position",Options={"Top right","Bottom right","Both right","Top left"},Value="Both right",Persistent=false,Callback=function(value)
    local placements={["Top right"]="TopRight",["Bottom right"]="BottomRight",["Both right"]="BothRight",["Top left"]="TopLeft"}
    window:SetBranding({Mode="Avatar",Placement=placements[value]})
end})
local arrangement=appearance:Section({Title="Layout"})
arrangement:Dropdown({Id="demo_tabs_position",Title="Tab position",Options={"Left","Right","Top","Bottom"},Value="Left",Persistent=false,Callback=function(value)window:SetLayout({TabPosition=value})end})
arrangement:Dropdown({Id="demo_mobile_tabs",Title="Mobile tabs",Options={"Top","Bottom"},Value="Top",Persistent=false,Callback=function(value)window:SetLayout({MobileTabPosition=value})end})
arrangement:Dropdown({Id="demo_control_position",Title="Control position",Options={"Right","Left","Below"},Value="Right",Persistent=false,Callback=function(value)window:SetLayout({ControlsPosition=value})end})
arrangement:Slider({Id="demo_button_size",Title="Button height",Min=44,Max=80,Value=44,Persistent=false,Callback=function(value)window:SetLayout({ButtonHeight=value})end})
arrangement:Slider({Id="demo_tabs_gap",Title="Tab spacing",Min=0,Max=24,Value=7,Persistent=false,Callback=function(value)window:SetLayout({TabGap=value})end})
local alerts=appearance:Section({Title="Notifications"})
alerts:Dropdown({Id="demo_toast_position",Title="Notification position",Options={"TopRight","BottomRight","TopLeft","BottomLeft"},Value="BottomRight",Persistent=false,Callback=function(value)window:SetNotifications({Position=value})end})
alerts:Button({Title="Preview notification",Text="Preview",Callback=function()window:Notify({Title="Preferences saved",Content="Your layout is ready. Continue where you left off.",Kind="success",Duration=5})end})
loader:SetProgress(.6,"Appearance ready")
local memoryProfile
local saved=profiles:Paragraph({Title="Session profile",Description="No profile saved. Values are kept in memory for this session."})
local storage=profiles:Section({Title="Saved values"})
local restore
storage:Button({Title="Save current values",Text="Save",Callback=function()
    memoryProfile=window:ExportConfig();restore:SetEnabled(true)
    saved:SetDescription("A profile is saved in memory. Saving again replaces it.")
end})
restore=storage:Button({Title="Restore saved values",Text="Restore",Disabled=true,Callback=function()
    if memoryProfile then local count=window:ImportConfig(memoryProfile,false);window:Notify({Title="Profile restored",Content=tostring(count).." values restored."})end
end})
profiles:Paragraph({Title="Permanent storage",Description="Connect your own Storage adapter to keep profiles between sessions. The library does not access files by default."})

farm:Paragraph({Title="Field / Workshop",Description="A visual farm template. Connect these controls to your own planting and harvest systems."})
local field=farm:Section({Title="Field controls"})
field:Button({Id="demo_plant",Title="Plant seeds",Description="Prepare the next growing cycle.",Text="Plant",Icon="seed",IconVariant="Soft",Callback=function()window:Notify({Title="Plant preview",Content="Your planting button is ready to connect.",Icon="sprout"})end})
field:Button({Id="demo_harvest",Title="Collect harvest",Description="Keep the next action easy to find.",Text="Collect",Icon="harvest",IconVariant="Duotone",Callback=function()window:Notify({Title="Harvest preview",Content="Your harvest button is ready to connect.",Icon="harvest",Kind="success"})end})
field:Button({Id="demo_inventory",Title="Inventory",Description="Seeds, crops and equipment.",Text="Open",Icon="inventory",Callback=function()window:SelectTab(icons)end})
local equipment=farm:Section({Title="Equipment"})
equipment:Dropdown({Id="demo_crop",Title="Crop",Options={"Potatoes","Wheat","Carrots"},Value="Potatoes"})
equipment:Slider({Id="demo_rows",Title="Rows per cycle",Min=1,Max=12,Value=4})

local galleryVariant="Outline"
local galleryRefreshers={}
icons:Dropdown({Id="demo_icon_variant",Title="Icon collection",Options=Library:GetIconVariants(),Value="Outline",Persistent=false,Callback=function(value)
    galleryVariant=value;for _,refresh in ipairs(galleryRefreshers)do refresh()end
end})
local allIconNames=Library:GetIconNames()
-- Small batches keep each custom component within its height limit on mobile.
for first=1,#allIconNames,30 do
    local batch=math.floor((first-1)/30)+1
    local names={}
    for index=first,math.min(first+29,#allIconNames)do names[#names+1]=allIconNames[index]end
    icons:Custom({Id=batch==1 and "demo_icon_gallery" or "demo_icon_gallery_"..batch,Title=batch==1 and "Original icons" or "More icons",Description="Navigation, automation, farming, tools and window actions.",Height=500,Build=function(root,control,owner)
    local grid=Instance.new("UIGridLayout")
    grid.CellPadding=UDim2.fromOffset(8,8);grid.SortOrder=Enum.SortOrder.LayoutOrder;grid.Parent=root
    local function layoutGallery()
        if control.Destroyed then return end
        local columns=math.clamp(math.floor((root.AbsoluteSize.X+8)/108),2,5)
        local cellWidth=math.max(1,math.floor((root.AbsoluteSize.X-8*(columns-1))/columns))
        grid.CellSize=UDim2.fromOffset(cellWidth,82)
        grid.FillDirectionMaxCells=columns
        control:SetHeight(math.ceil(#names/columns)*90-8)
    end
    local function galleryRefresh()
        if control.Destroyed then return end
        for _,child in ipairs(root:GetChildren())do
            if child:IsA("GuiObject")then owner:_ForgetTree(child);child:Destroy()end
        end
        for index,name in ipairs(names)do
            local cell=Instance.new("Frame");cell.Name=name;cell.BorderSizePixel=0;cell.LayoutOrder=index;cell.Parent=root
            owner:BindColor(cell,"BackgroundColor3","Raised")
            local rounded=Instance.new("UICorner");rounded.CornerRadius=UDim.new(0,10);rounded.Parent=cell
            Library:Icon(cell,name,{Size=26,Position=UDim2.new(.5,-13,0,13),Window=owner,Token="Text",Variant=galleryVariant})
            local label=Instance.new("TextLabel");label.Name="Caption";label.BackgroundTransparency=1;label.Position=UDim2.fromOffset(4,44);label.Size=UDim2.new(1,-8,0,18)
            label.Text=name;label.Font=owner.Style.Font;label.TextSize=11;label.TextTruncate=Enum.TextTruncate.AtEnd;label.Parent=cell
            owner:BindColor(label,"TextColor3","Muted")
            local idLabel=Instance.new("TextLabel");idLabel.Name="IconId";idLabel.BackgroundTransparency=1;idLabel.Position=UDim2.fromOffset(4,63);idLabel.Size=UDim2.new(1,-8,0,13)
            idLabel.Text="ID "..tostring(Library:GetIconId(name));idLabel.Font=owner.Style.Font;idLabel.TextSize=10;idLabel.Parent=cell
            owner:BindColor(idLabel,"TextColor3","Muted")
        end
        layoutGallery()
    end
    control:Own(root:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutGallery))
    galleryRefreshers[#galleryRefreshers+1]=galleryRefresh
    galleryRefresh()
end})
end

-- A registered component is built inside a library-owned frame.
loader:SetProgress(.8,"Profiles ready")
Library:RegisterComponent("Meter",function(root, control, owner, options)
    local label=Instance.new("TextLabel")
    label.BackgroundTransparency=1;label.TextXAlignment=Enum.TextXAlignment.Left
    label.Font=owner.Style.Font;label.TextSize=13;label.Size=UDim2.new(1,0,0,24);label.Parent=root
    owner:BindColor(label,"TextColor3","Muted")
    local track=Instance.new("Frame");track.BorderSizePixel=0;track.Position=UDim2.fromOffset(0,34);track.Size=UDim2.new(1,0,0,12);track.Parent=root
    owner:BindColor(track,"BackgroundColor3","Raised")
    local fill=Instance.new("Frame");fill.BorderSizePixel=0;fill.Size=UDim2.new(0,0,1,0);fill.Parent=track
    owner:BindColor(fill,"BackgroundColor3","Accent")
    for _,part in ipairs({track,fill})do local rounded=Instance.new("UICorner");rounded.CornerRadius=UDim.new(0,6);rounded.Parent=part end
    function control:Update(ratio,instant)
        self.Value=math.clamp(ratio,0,1);label.Text=tostring(math.floor(self.Value*100+.5)).." / 100"
        owner:Animate(fill,{Size=UDim2.new(self.Value,0,1,0)},instant and {Duration=0}or nil)
    end
    control:Own(owner:On("StyleChanged",function(tokens)label.Font=tokens.Font end))
    control:Update(options.Value or .4,true)
end)
extensions:Paragraph({Title="Custom components",Description="A registered meter using scoped animations, theme colors and style events."})
local example=extensions:Section({Title="Meter"})
local meter=example:Add("Meter",{Id="demo_meter",Title="Preview",Height=52,Value=.4})
local level=example:Slider({Id="demo_level",Title="Level",Min=0,Max=100,Step=1,Value=40,Callback=function(value)meter:Update(value/100)end})
example:Dropdown({Id="demo_curve",Title="Animation curve",Options={"Quad","Sine","Back"},Persistent=false,Callback=function(value)window:SetMotion({Style=Enum.EasingStyle[value]})end})
example:Button({Title="Animate to another level",Text="Play",Callback=function()
    local nextValue=level:Get()>=50 and 25 or 85;level:Set(nextValue,true)
end})
window:SelectTab(overview)
updateStatus()
loader:Complete("Workspace ready")
return {Library=Library,Window=window}
