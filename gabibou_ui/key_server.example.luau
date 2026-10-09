-- Script in ServerScriptService. Keys belong here, never in a LocalScript.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local keys={ ["CHANGE_ME"]=true } -- Replace with your own private keys.
local remoteName="GabibouValidateKey"
assert(not ReplicatedStorage:FindFirstChild(remoteName),"GabibouValidateKey already exists")
local attempts={}
local remote=Instance.new("RemoteFunction")
remote.Name=remoteName
remote.OnServerInvoke=function(player,key)
    local now=os.clock()
    if attempts[player]and now-attempts[player]<2 then return false,"Please wait before trying again."end
    attempts[player]=now
    if type(key)~="string"or #key>256 or key=="CHANGE_ME"or keys[key]~=true then
        return false,"Key not accepted"
    end
    player:SetAttribute("GabibouAuthorized",true)
    return true
end
remote.Parent=ReplicatedStorage
Players.PlayerRemoving:Connect(function(player)attempts[player]=nil end)
-- Every protected server action must check this server-owned permission:
-- if player:GetAttribute("GabibouAuthorized")~=true then return end
