-- ModuleScript: ReplicatedStorage.GabibouUI. Run as a LocalScript.
local UI=require(game:GetService("ReplicatedStorage"):WaitForChild("GabibouUI"))
local window=UI:Create({
    Id="MyInterface",Title="My project",Subtitle="Settings",
    Branding={Mode="Avatar",Placement="BothRight"},
    Loading={Title="My project",Subtitle="Preparing settings",Logo="Avatar",MinimumDuration=.6},
    Tabs={{Title="Settings",Icon="settings",Sections={{Title="Display",Controls={
        {Type="Toggle",Id="effects",Title="Effects",Value=true},
        {Type="Slider",Id="volume",Title="Volume",Min=0,Max=100,Value=50},
    }}}}},
})
window:Get("effects"):On("Changed",function(value)print("Effects",value)end)
window:SetValues({effects=true,volume=75})
