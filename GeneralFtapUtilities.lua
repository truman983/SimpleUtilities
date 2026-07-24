local Utils = {}

local repStorage = game:GetService("ReplicatedStorage")
local plrServ = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local charEvents: Folder = repStorage:WaitForChild("CharacterEvents")
local PlrEvents: Folder = repStorage:WaitForChild("PlayerEvents")
local grabEvents = game:GetService("ReplicatedStorage"):WaitForChild("GrabEvents", 1)

local menuToys: Folder = repStorage:WaitForChild("MenuToys", 1)

local deleteToyRemote: RemoteEvent = menuToys:WaitForChild("DestroyToy", 1)
local spawnToyEvent: RemoteFunction = menuToys:WaitForChild("SpawnToyRemoteFunction", 1)

local ragdollRem: RemoteEvent = charEvents:FindFirstChild("RagdollRemote")
local struggleRem: RemoteEvent = charEvents:FindFirstChild("Struggle")



local lp = plrServ.LocalPlayer
local LpMouse = lp:GetMouse()

local ToyFolder = game.Workspace:FindFirstChild(lp.Name.."SpawnedInToys")

local ownedParts = {}
local Connections = {}
local threads = {}

local AgEnabled = false



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

 function PartInRange(OtherPart: BasePart, Range: number)

    return (OtherPart.Position - lp.Character.Head.Position).Magnitude <= Range

 end

 
function GetClosestPartOfModel(Model: Model)
    local Closest = {
        DistCheck = math.huge;
    }

    for i,v in pairs(Model:GetChildren()) do
        if v:IsA("BasePart") then
            local Dist: number = (v.Position - lp.Character.Head.Position).Magnitude
            if Dist < Closest.DistCheck then
                Closest.DistCheck = Dist
                Closest.Object = v
            end 
        end
    end

    if Closest.Object then
        return Closest.Object
    else
        warn("no valid object was found")
        return
    end

end

local function ValidGrabbable(obj)

    local allowedCollisionGroups = {
    "Items",
    "Default",
	"Players"
}

    if table.find(allowedCollisionGroups, obj.CollisionGroup) and obj.Anchored == false and PartInRange(obj, 19) then
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



function Utils.OwnModel(Model: Model)

    local closestPart = GetClosestPartOfModel(Model)

    if ValidGrabbable(closestPart) then
        netOwnTarget(closestPart)
        task.wait()
        dropTarget(closestPart)
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

function Utils.SpawnToy(ToyName: string, Position: Vector3, Orientation: Vector3?)

    local correction = CFrame.Angles(math.pi/2, 0, 0)
    local origin = CFrame.new(Position)

    local location = origin * correction

    task.spawn(function()
        if Orientation then
            spawnToyEvent:InvokeServer(ToyName, location, Orientation)
        else
            spawnToyEvent:InvokeServer(ToyName, location, Vector3.zero)
        end
        
    end)
end

function Utils.DeleteToy(ToyName: string)
    local Deleting = ToyFolder:FindFirstChild(ToyName)
    deleteToyRemote:FireServer(Deleting)
end

function Utils.OnLPToySpawn(func: (spawnedToy: Model) -> ())
    local returnConn
    
    returnConn = ToyFolder.ChildAdded:Connect(function(child: Instance)
        if child:IsA("Model") then
            func(child)
        end
    end)

    Connections["LPSpawnObject"] = returnConn

    return returnConn
end

return Utils

