-- LocalScript in StarterPlayerScripts. Install key_server.example.luau first.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UI=require(ReplicatedStorage:WaitForChild("GabibouUI"))
local validateKey=ReplicatedStorage:WaitForChild("GabibouValidateKey")
local session=UI:Launch({
    Id="MyProject",Title="My project",Width=860,Height=620,
    Layout={TabPosition="Left",MobileTabPosition="Bottom",ButtonHeight=48,TabGap=8},
    Notifications={Position="BottomRight",Width=340},
    KeySystem={Title="Welcome",Subtitle="Enter your access key.",Validate=function(key)
        return validateKey:InvokeServer(key)
    end},
    Loading={Title="My project",Logo="Avatar",MinimumDuration=.5},
    Tabs={{Title="Settings",Icon="settings",Controls={
        {Type="Toggle",Id="effects",Title="Effects",Value=true},
        {Type="Button",Id="save",Title="Preview notification",Text="Preview",Layout={Width=140}},
    }}},
    OnReady=function(window)
        window:Get("save").Callback=function()
            window:Notify({Title="Ready",Content="Your interface is configured.",Kind="success"})
        end
    end,
})
-- session:Destroy() closes the gate, loader and window owned by this launch.
