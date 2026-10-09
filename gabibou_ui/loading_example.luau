-- Run as a LocalScript with GabibouUI in ReplicatedStorage.
local UI=require(game:GetService("ReplicatedStorage"):WaitForChild("GabibouUI"))
local loader=UI:CreateLoader({
    Title="My project",
    Subtitle="Your workspace is almost ready.",
    Variant="Centered", -- Compact, Centered or Minimal
    Logo="Avatar", -- Or an rbxassetid:// image; false clears an image
    ProgressHeight=4,
    Theme={Accent=Color3.fromRGB(190,202,255)},
    MinimumDuration=.5,
})

-- Optional: move a built-in part. This survives reflow and Update.
-- loader:SetPartLayout("Title",{Position=UDim2.fromOffset(24,94)})

-- Optional custom visual. The loader owns its animation and cleanup.
local content=loader:GetParts().Content
local note=Instance.new("TextLabel")
note.BackgroundTransparency=1
note.Size=UDim2.fromScale(1,1)
note.Text="Made for your project"
note.TextColor3=Color3.fromRGB(158,158,169)
note.Font=Enum.Font.Gotham
note.TextSize=12
note.Parent=content
local tween=game:GetService("TweenService"):Create(note,TweenInfo.new(.8,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{TextTransparency=.6})
loader:Own(tween)
tween:Play()

loader:Run({
    {Title="Preparing interface",Run=function(owner)
        -- Replace this with your actual initialization work.
        owner:Update({Subtitle="Applying your display settings."})
    end},
    {Title="Applying preferences",Run=function()
        -- Load your project's preferences here.
    end},
})
