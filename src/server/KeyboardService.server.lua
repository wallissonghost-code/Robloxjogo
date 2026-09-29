local TweenService=game:GetService("TweenService")
local Players=game:GetService("Players")

local old=workspace:FindFirstChild("Keyboard")
if old then old:Destroy() end

local keyboard=Instance.new("Model")
keyboard.Name="RetroKeyboard"
keyboard.Parent=workspace

local rows={
	{"1","2","3","4","5","6","7","8","9","0"},
	{"Q","W","E","R","T","Y","U","I","O","P"},
	{"A","S","D","F","G","H","J","K","L"},
	{"Z","X","C","V","B","N","M"},
}
local KEY_SIZE=Vector3.new(5.2,1.55,5.2)
local GAP=.62
local PITCH=KEY_SIZE.X+GAP
local PRESS_DEPTH=.72
local ORIGIN_Y=2.15
local states={}

local maxColumns=10
local base=Instance.new("Part")
base.Name="KeyboardBase"
base.Anchored=true
base.Size=Vector3.new(maxColumns*PITCH+6,1.45,4*PITCH+6)
base.Position=Vector3.new(0,.72,0)
base.Material=Enum.Material.SmoothPlastic
base.Color=Color3.fromRGB(190,184,158)
base.TopSurface=Enum.SurfaceType.Smooth
base.Parent=keyboard

local function characterOnKey(hit)
	local character=hit and hit:FindFirstAncestorOfClass("Model")
	if not character then return nil end
	local humanoid=character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health<=0 then return nil end
	return Players:GetPlayerFromCharacter(character)
end

local function makeKey(label,x,z)
	local key=Instance.new("Part")
	key.Name="Key_"..label
	key.Anchored=true
	key.Size=KEY_SIZE
	key.Position=Vector3.new(x,ORIGIN_Y,z)
	key.Material=Enum.Material.SmoothPlastic
	key.Color=Color3.fromRGB(218,212,186)
	key.TopSurface=Enum.SurfaceType.Smooth
	key.BottomSurface=Enum.SurfaceType.Smooth
	key:SetAttribute("Key",label)
	key.Parent=keyboard

	local gui=Instance.new("SurfaceGui")
	gui.Name="Label"
	gui.Face=Enum.NormalId.Top
	gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud=32
	gui.Parent=key
	local text=Instance.new("TextLabel")
	text.Size=UDim2.fromScale(1,1)
	text.BackgroundTransparency=1
	text.Text=label
	text.TextColor3=Color3.fromRGB(38,36,31)
	text.TextScaled=true
	text.Font=Enum.Font.ArialBold
	text.Parent=gui
	local padding=Instance.new("UIPadding")
	padding.PaddingTop=UDim.new(.24,0);padding.PaddingBottom=UDim.new(.24,0);padding.PaddingLeft=UDim.new(.24,0);padding.PaddingRight=UDim.new(.24,0);padding.Parent=text

	local up=key.CFrame
	local down=up*CFrame.new(0,-PRESS_DEPTH,0)
	local state={touching={}}
	states[key]=state

	local function setPressed(isPressed,player)
		if state.pressed==isPressed then return end
		state.pressed=isPressed
		if isPressed then
			key.Color=Color3.fromRGB(174,169,149)
			TweenService:Create(key,TweenInfo.new(.075,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=down}):Play()
			keyboard:SetAttribute("LastKey",label)
			key:SetAttribute("LastPressedBy",player and player.UserId or 0)
		else
			TweenService:Create(key,TweenInfo.new(.13,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{CFrame=up}):Play()
			key.Color=Color3.fromRGB(218,212,186)
		end
	end

	key.Touched:Connect(function(hit)
		local player=characterOnKey(hit)
		if not player then return end
		local character=player.Character
		if not character then return end
		state.touching[character]=true
		setPressed(true,player)
	end)
	key.TouchEnded:Connect(function(hit)
		local player=characterOnKey(hit)
		if not player then return end
		local character=player.Character
		if not character then return end
		task.delay(.08,function()
			if not key.Parent or not character.Parent then state.touching[character]=nil return end
			local root=character:FindFirstChild("HumanoidRootPart")
			if not root then state.touching[character]=nil return end
			local localPos=key.CFrame:PointToObjectSpace(root.Position)
			local halfX=key.Size.X/2+.8;local halfZ=key.Size.Z/2+.8
			if math.abs(localPos.X)>halfX or math.abs(localPos.Z)>halfZ then state.touching[character]=nil end
			if next(state.touching)==nil then setPressed(false) end
		end)
	end)
end

for rowIndex,row in ipairs(rows) do
	local count=#row
	local rowWidth=(count-1)*PITCH
	local offset=(rowIndex==3 and PITCH*.35) or (rowIndex==4 and PITCH*1.05) or 0
	local start=-rowWidth/2+offset
	local z=(rowIndex-2.5)*PITCH
	for i,label in ipairs(row) do makeKey(label,start+(i-1)*PITCH,z) end
end

local spawn=workspace:FindFirstChild("SpawnLocation")
if spawn then spawn.CFrame=CFrame.new(0,4,23) end
