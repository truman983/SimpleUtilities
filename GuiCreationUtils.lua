local util = {}
util.__index = util

local Ts = game:GetService("TweenService")
local Uis = game:GetService("UserInputService")
local ScrGuiRef

local References = {}
local Callbacks = {}
local scriptObjects = {}

local defaultSize = UDim2.fromScale(0.2,0.2)
local defaultPosition = UDim2.fromScale(0.5, 0)
local defaultAnchorPoint = Vector2.new(0.5,0.5)
local defaultBackgroundColor = Color3.fromRGB(255,255,255)

local ElementDefaults = {

	["Frame"] = {
		BorderSizePixel = 0;

		Size = defaultSize;
		AnchorPoint = defaultAnchorPoint;
		Position = defaultPosition;

		BackgroundColor3 = defaultBackgroundColor;
	};

	["ScreenGui"] = {
		IgnoreGuiInset = true;
		ZIndexBehavior = Enum.ZIndexBehavior.Global;
	};

	["TextButton"] = {
		BorderSizePixel = 0;

		Size = defaultSize;
		AnchorPoint = defaultAnchorPoint;
		Position = defaultPosition;

		BackgroundColor3 = defaultBackgroundColor;
	};

	["TextBox"] = {
		BorderSizePixel = 0;

		Size = defaultSize;
		AnchorPoint = defaultAnchorPoint;
		Position = defaultPosition;

		BackgroundColor3 = defaultBackgroundColor;

		TextScaled = true;
	};

	["TextLabel"] = {
		BorderSizePixel = 0;

		Size = defaultSize;
		AnchorPoint = defaultAnchorPoint;
		Position = defaultPosition;

		BackgroundColor3 = defaultBackgroundColor;
	};

	["UIStroke"] = {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
		Thickness = 1;
		LineJoinMode = Enum.LineJoinMode.Round;
		Color = Color3.fromRGB(0,0,0);
	};

	["UICorner"] = {
		CornerRadius = UDim.new(0, 16);
	}
}

type GeneralGuiCallbacks = 
	"MouseEnter"|
"MouseLeave"|
"MouseMoved"|
"MouseWheelForward"|
"MouseWheelBackward"|
"MouseButton1Down"|
"InputEnded"|
"InputChanged"|
"InputBegan"|
"Focused"|
"FocusLost"

type UIElements = 
"Frame"
| "ScreenGui"
|"TextLabel"
|"TextButton"
|"ImageButton"
|"ImageLabel"
|"TextBox"
|"ScrollingFrame"

type GeneralUIComponents = "UIStroke"
|"UICorner"
|"UIGradient"


local function hasProperty(object, propertyName)
	local success, _ = pcall(function()
		local value = object[propertyName]
	end)
	return success
end


local function ApplyProperties(PropertyTable: {}, Inst: Instance)

	local Properties = table.clone(ElementDefaults[Inst.ClassName] or {})

	for Property, Value in pairs(PropertyTable or {}) do
		Properties[Property] = Value
	end

	for Property, Value in pairs(Properties) do
		if hasProperty(Inst, Property) then
			Inst[Property] = Value
		end
	end

end



-- Constructs a new instance to be used with custom methods.
function util.New(Inst:UIElements, Parent: Instance, Properties: {}?) -- Remember, use SELF.INSTANCE to reference the actual object
	local self = setmetatable({}, util)

	local Success, result = pcall(Instance.new, Inst)

	assert(Success, Inst.." Was not a valid Class!")

	self.Instance = result

	if Parent then
		self.Instance.Parent = Parent
	end

	ApplyProperties(Properties, self.Instance)

	table.insert(References, self)

	return self
end


-- Creates a new clone of the object and parents it to itself.
function util.Clone(Inst: Instance)

	local clone = setmetatable({}, util)

	local newObj = Inst:Clone()

	clone.Instance = newObj
	newObj.Parent = Inst

	return clone


end

function util.MouseUnlock(Toggle: boolean)
	local parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	if Toggle then
		if ScrGuiRef then
			return
		end

		local ok, ui = pcall(gethui)
		if ok then 
			parent = ui
		end

		local New = Instance.new("ScreenGui", parent)
		New.IgnoreGuiInset = true
		local New2 = Instance.new("TextButton", New)
		New2.BackgroundTransparency = 1
		New2.TextTransparency = 1
		New2.Size = UDim2.fromScale(1,1)
		New2.Modal = true
		ScrGuiRef = New
	else
		if ScrGuiRef then
			ScrGuiRef:Destroy()
			ScrGuiRef = nil
		end
	end
end

-- Smoothly tweens the property of an object
function util:TweenProperty(propName: string, NewValue: any, TweenProperties:{}?)

	assert(hasProperty(self.Instance, propName), propName.." was not a valid property of "..self.Instance.ClassName.."!")

	TweenProperties = TweenProperties or {}

	local time = TweenProperties.Time or 1
	local EasingStyle = TweenProperties.EasingStyle or Enum.EasingStyle.Cubic 
	local EasingDirection = TweenProperties.EasingDirection or Enum.EasingDirection.InOut
	local info = TweenInfo.new(time, EasingStyle, EasingDirection)

	local tween = Ts:Create(self.Instance, info, {[propName] = NewValue})

	tween:Play()

	return tween

end

-- Adds a UIComponent, or a UIGridStyleLayout to the object.
function util:AddComponent(Component: GeneralUIComponents, Properties: {})
	local newSelf = setmetatable({}, util)

	local Success, result = pcall(Instance.new, Component)

	assert(Success, "Not a valid class!")

	if result:IsA("UIComponent") or result:IsA("UIGridStyleLayout") then

		ApplyProperties(Properties, result)

		result.Parent = self.Instance

		newSelf.Instance = result

		table.insert(References, newSelf)

		return newSelf

	else

		warn("Not a UIComponent, nor a UIGridStyleLayout!")
		result:Destroy()
		table.clear(newSelf)
		return

	end

end

-- Changes the properties of the object this method is used on in a table format.
function util:ChangeProperties(Properties: {})

	ApplyProperties(Properties, self.Instance)

	return self

end
-- Changes a single property.
function util:SetProperty(Property: any, value: any)
	if hasProperty(self.Instance, Property) then
		self.Instance[Property] = value
	end
end

-- Creates a callback with the desired function and arguements.
function util:ObjectCallback(Cb: GeneralGuiCallbacks, func)
	local member = self.Instance[Cb]

	if typeof(member) ~= "RBXScriptSignal" then
		warn(Cb .. " is not a valid event of " .. self.Instance.ClassName)
		return nil
	end

	local connection = member:Connect(func)
	return connection
end

function util:MakeDraggable(Enabled: boolean)

	if Enabled then
		if not self.Instance:FindFirstChildOfClass("UIDragDetector", true) then
			local hi = Instance.new("UIDragDetector", self.Instance)
			hi.ResponseStyle = Enum.UIDragDetectorResponseStyle.Scale
			hi.CursorIcon = "randomshitsotheresnostupidcursor"
			hi.ActivatedCursorIcon = "morerandomshitsotheresnostupidcursor"
			if self.Instance:FindFirstAncestorOfClass("ScreenGui") then
				hi.BoundingUI = self.Instance:FindFirstAncestorOfClass("ScreenGui")
			end
		end
	else
		if self.Instance:FindFirstChild("UIDragDetector", true) then
			self.Instance.UIDragDetector:Destroy()
		end
	end

end



-- Shuts down everything.
function util.Kill()

	for _,ref in pairs(References) do
		if ref.Instance then
			ref.Instance:Destroy()
			ref.Instance = nil
		end
	end

	for _, callback:RBXScriptConnection in pairs(Callbacks) do
		callback:Disconnect()
	end

	for _,obj in pairs(scriptObjects) do
		obj:Destroy()
	end

	table.clear(References)

end


return util
