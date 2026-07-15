local Utils = {}

local repStorage = game:GetService("ReplicatedStorage")
local plrServ = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local charEvents: Folder = repStorage:WaitForChild("CharacterEvents")
local PlrEvents: Folder = repStorage:WaitForChild("PlayerEvents")
local grabEvents = game:GetService("ReplicatedStorage"):WaitForChild("GrabEvents", 1)

local menuToys: RemoteEvent = repStorage:WaitForChild("MenuToys", 1)

local deleteToyRemote: RemoteEvent = menuToys:WaitForChild("DestroyToy", 1)
local spawnToyEvent: RemoteFunction = menuToys:WaitForChild("SpawnToyRemoteFunction", 1)

local ragdollRem: RemoteEvent = charEvents:FindFirstChild("RagdollRemote")
local struggleRem: RemoteEvent = charEvents:FindFirstChild("Struggle")



local lp = plrServ.LocalPlayer
local LpMouse = lp:GetMouse()

local ownedParts = {}
local Connections = {}
local threads = {}

local AgEnabled = false

local allowedCollisionGroups = {
    "Items",
    "Default",
	"Players"
}

 local ServerMessages = {
        Message = function(Msg: string)
            game:GetService("TextChatService").TextChannels.RBXGeneral:DisplaySystemMessage(prefix..Msg)
        end;

        Warning = function(Msg: string)
            local formatted = string.format('<font color="#ffff00">%s</font>', Msg)
            game:GetService("TextChatService").TextChannels.RBXGeneral:DisplaySystemMessage(prefix..formatted)
        end;

        Error = function(Msg: string)
            local formatted = string.format('<font color="#ff0000">%s</font>', Msg)
            game:GetService("TextChatService").TextChannels.RBXGeneral:DisplaySystemMessage(prefix..formatted)
        end;

 }

local function ValidGrabbable(obj)

    if table.find(allowedCollisionGroups, obj.CollisionGroup) and obj.Anchored == false then
        return true
    else
        return false
    end

end

function netOwnTarget(target)
	local args = {
		target,
		target.CFrame,
	}
	grabEvents:WaitForChild("SetNetworkOwner", 1):FireServer(unpack(args))
end

function dropTarget(target)
	local args = {
		target,
	}
	grabEvents:WaitForChild("DestroyGrabLine", 1):FireServer(unpack(args))
end




function Utils.OwnPart(Part)

    if ValidGrabbable(Part) then
        netOwnTarget(Part)
        task.wait()
        dropTarget(Part)
    end

end

function Utils.OwnMouseTarget()

    local targ = LpMouse.Target
	if targ then
	    if ValidGrabbable(targ) then
	        netOwnTarget(targ)
	        task.wait()
	        dropTarget(targ)
	    end
	end
end

function Utils.WhenLpGrabbing(func: (otherPart: BasePart) -> ())

    local ReturnConn 

    ReturnConn = game.Workspace.DescendantAdded:Connect(function(desc: Instance)
    if desc.Name == "GrabParts" then
        if desc.Parent == game.Workspace then
            local gp = desc:WaitForChild("GrabPart")
            if gp then
                local weld: WeldConstraint = gp:WaitForChild("WeldConstraint")

                if weld then
                    local PartGrabbing = weld.Part1
                    if ValidGrabbable(PartGrabbing) then
                        func(PartGrabbing)
                    end
                end
            end
        end
    end
end)

Connections["LpGrabbing"] = ReturnConn

return ReturnConn

end

function Utils.WhenOtherGrabbing(func: (otherPart: BasePart) -> ())

    local ReturnConn 

ReturnConn = game.Workspace.DescendantAdded:Connect(function(desc: Instance)
    if desc.Name == "GrabParts" then
        if desc.Parent ~= game.Workspace then
            local gp = desc:WaitForChild("GrabPart")
            if gp then
                local weld: WeldConstraint = gp:WaitForChild("WeldConstraint")
                if weld then
                    local PartGrabbing = weld.Part1
                    if ValidGrabbable(PartGrabbing) then
                        func(PartGrabbing)
                    end
                end
            end
        end
    end
end)


Connections["OtherGrabbing"] = ReturnConn

return ReturnConn 
    
end


function Utils.AntiGrab(Enabled: boolean)

end

function Utils.SpawnToy()

end

function Utils.DeleteToy()

end

return Utils

