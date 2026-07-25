local Utils = {}
local chatConsolePrefix = '<font color="#11edb2">[Server]: </font>'

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
            game:GetService("TextChatService").TextChannels.RBXGeneral:DisplaySystemMessage(chatConsolePrefix..Msg)
        end;

        Warning = function(Msg: string)
            local formatted = string.format('<font color="#ffff00">%s</font>', Msg)
            game:GetService("TextChatService").TextChannels.RBXGeneral:DisplaySystemMessage(chatConsolePrefix..formatted)
        end;

        Error = function(Msg: string)
            local formatted = string.format('<font color="#ff0000">%s</font>', Msg)
            game:GetService("TextChatService").TextChannels.RBXGeneral:DisplaySystemMessage(chatConsolePrefix..formatted)
        end;

 }

 function PartInRange(OtherPart: BasePart, Range: number)
    local mag = (OtherPart.Position - lp.Character.Head.Position).Magnitude

    return (mag <= Range)

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

function MouseRaycast()
    local unitRay = workspace.CurrentCamera:ScreenPointToRay(LpMouse.X, LpMouse.Y)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {lp.Character}

    local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, params)

    if result then
        return result.Instance
    end

end

function ValidGrabbable(obj)

    local allowedCollisionGroups = {
    "Items",
    "Default",
	"Players",
    "PlotItems"
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

function GetValidBlobAndSeat()
    local check
    repeat check = ToyFolder:FindFirstChild("CreatureBlobman") task.wait()
    until check

        local SeatCheck: VehicleSeat = check:WaitForChild("VehicleSeat", 5)
        if SeatCheck then
            return check, SeatCheck
        end

end

function RemoveVelocities(Model: Model)

    for i,v in pairs(Model:GetDescendants()) do
        if v:IsA("BasePart") then
            v.AssemblyAngularVelocity = Vector3.zero
            v.AssemblyLinearVelocity = Vector3.zero
        end
    end

end



function Utils.OwnModel(Model: Model)

    local closestPart = GetClosestPartOfModel(Model)

    if ValidGrabbable(closestPart) then
        netOwnTarget(closestPart)
        task.wait()
        dropTarget(closestPart)
        return Model
    end
end

function Utils.OwnMouseTarget()

    local targ = MouseRaycast()
	if targ then
	    if ValidGrabbable(targ) then
	        netOwnTarget(targ)
	        task.wait()
	        dropTarget(targ)
            return targ
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
                    if PartGrabbing.Anchored == false then
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

function Utils.SpawnToy(ToyName: string, Distance: number, Orientation: Vector3?)
    local root = lp.Character.HumanoidRootPart
    local lv = root.CFrame.LookVector
    local multiplier = Distance or 5

    local correction = CFrame.Angles(math.pi/2, 0, 0)
    local origin = CFrame.new((root.Position + (lv * multiplier)) - Vector3.new(0,10))

    local location = origin * correction

    task.spawn(function()
        if Orientation then
            spawnToyEvent:InvokeServer(ToyName, location, Orientation)
        else
            spawnToyEvent:InvokeServer(ToyName, location, Vector3.zero)
        end
        
    end)
end

function Utils.DeleteToy(ToyToDelete: string | Instance)
 
    if typeof(ToyToDelete) == "string" then
        local check = menuToys:FindFirstChild(ToyToDelete)
        if check then
            deleteToyRemote:FireServer(check)
        end
        
    elseif typeof(ToyToDelete) == "Instance" then
        deleteToyRemote:FireServer(ToyToDelete)
    end

end

function Utils.WhenLpToySpawn(func: (spawnedToy: Model) -> ())
    local returnConn
    
    returnConn = ToyFolder.ChildAdded:Connect(function(child: Instance)
        if child:IsA("Model") then
            func(child)
        end
    end)

    Connections["LPSpawnObject"] = returnConn

    return returnConn
end

function Utils.WhenLpToyRemove(func: (removedToy: Model) -> ())
     local returnConn
    
    returnConn = ToyFolder.ChildRemoved:Connect(function(child: Instance)
        if child:IsA("Model") then
            func(child)
        end
    end)

    Connections["LPRemoveObject"] = returnConn

    return returnConn

end

function Utils.Aura(func: (ModelInRange: Model) -> ()) 

    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {lp.Character}

    return task.spawn(function()
        while task.wait(0.05) do
            if not lp.Character or not lp.Character.Head then continue end 
             local seen = {}
            local PartsInRange = workspace:GetPartBoundsInRadius(lp.Character.Head.Position, 19, params)
            for i,v in ipairs(PartsInRange) do
                local model = v.Parent
                if ValidGrabbable(v) and model and not seen[model] then
                    seen[model] = true
                    func(model)
                end
            end

        end

    end)
end

function Utils.ChatConsole(Info, MessageType)
    if ServerMessages[MessageType] then
        ServerMessages[MessageType](Info)
    end
end

function Utils.DoBlobSpawn()
        Utils.SpawnToy("CreatureBlobman", 5)
        task.wait()
        return GetValidBlobAndSeat()
end

function Utils.BlobEscape()
    local lpHum = lp.Character:FindFirstChildOfClass("Humanoid")
    local ogPos = lp.Character.HumanoidRootPart.Position

    local blob, seat = Utils.DoBlobSpawn()
    struggleRem:FireServer()
    task.wait()
    lp.Character:MoveTo(seat.Position)
    task.wait()
    seat:Sit(lpHum)
    task.wait()
    Utils.DeleteToy(blob)
    task.wait()
    RemoveVelocities(lp.Character)
    ragdollRem:FireServer(lp.Character.HumanoidRootPart, 0)
    task.wait()
    lp.Character:MoveTo(ogPos)

end

function Utils.SimpleAntiGrabSetup() -- Inspired by RebornSpy's take on the simple anti grab.
    local antiEnabled = false
    local thread
    
    return {

        Enable = function()
                if antiEnabled then
                    return
                end

                antiEnabled = true
                
                thread = task.spawn(function()
                    while antiEnabled  do
                        task.wait()
                    local holdingBool = lp:FindFirstChild("IsHeld")
                    local char = lp.Character
                    if holdingBool and holdingBool.Value == true then
                        if char then
                            local root = char:FindFirstChild("HumanoidRootPart")
                            local Humanoid: Humanoid = char:FindFirstChild("Humanoid")
                            if root and Humanoid then
                                local ogPos = root.Position
                                Humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
                                while holdingBool.Value == true and antiEnabled do
                                    struggleRem:FireServer(lp)
                                    ragdollRem:FireServer(root, 0)
                                    task.wait()
                                    Humanoid:ChangeState(Enum.HumanoidStateType.Running)
                                    task.wait(0.001)
                                end
                                if (ogPos - root.Position).Magnitude >= 20 then
                                    root.CFrame = CFrame.new(ogPos)
                                    RemoveVelocities(lp.Character)
                                end
                            end

                        end
                    end
                end
            end)

        end;


        Disable = function()
            antiEnabled = false
            if thread then
                task.cancel(thread)
                thread = nil
            end
        end
    }

  
end

return Utils
