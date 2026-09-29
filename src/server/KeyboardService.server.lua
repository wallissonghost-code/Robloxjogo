local TweenService=game:GetService("TweenService")

local old=workspace:FindFirstChild("Keyboard")
if old then old:Destroy() end

local keyboard=Instance.new("Model")
keyboard.Name="Keyboard"
keyboard.Parent=workspace

local rows={
	{keys={"1","2","3","4","5","6","7","8","9","0"},offset=0},
	{keys={"Q","W","E","R","T","Y","U","I","O","P"},offset=.35},
	{keys={"A","S","D","F","G","H","J","K","L"},offset=.7},
	{keys={"Z","X","C","V","B","N","M"},offset=1.4},
}
local keySize=Vector3.new(2.15,.65,2.15)
local gap=.28
local pitch=keySize.X+gap
local origin=Vector3.new(0,1.05,0)
local pressed={}

local base=Instance.new("Part")
base.Name="KeyboardBase"
base.Anchored=true
base.Size=Vector3.new(27,.65,14)
base.Position=Vector3.new(0,.48,0)
base.Material=Enum.Material.SmoothPlastic
base.Color=Color3.fromRGB(24,26,29)
base.Parent=keyboard

local function makeKey(label,x,z,width)
	width=width or keySize.X
	local key=Instance.new("Part")
	key.Name="Key_"..label
	key.Anchored=true
	key.Size=Vector3.new(width,keySize.Y,keySize.Z)
	key.Position=origin+Vector3.new(x,0,z)
	key.Material=Enum.Material.SmoothPlastic
	key.Color=Color3.fromRGB(55,59,64)
	key.TopSurface=Enum.SurfaceType.Smooth
	key.BottomSurface=Enum.SurfaceType.Smooth
	key:SetAttribute("Key",label)
	key.Parent=keyboard

	local surface=Instance.new("SurfaceGui")
	surface.Name="Label"
	surface.Face=Enum.NormalId.Top
	surface.AlwaysOnTop=true
	surface.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud=42
	surface.Parent=key
	local text=Instance.new("TextLabel")
	text.Size=UDim2.fromScale(1,1)
	text.BackgroundTransparency=1
	text.Text=label=="SPACE" and "SPACE" or label
	text.TextColor3=Color3.fromRGB(245,247,250)
	text.TextScaled=true
	text.Font=Enum.Font.GothamBold
	text.Parent=surface
	local pad=Instance.new("UIPadding")
	pad.PaddingTop=UDim.new(.18,0);pad.PaddingBottom=UDim.new(.18,0);pad.PaddingLeft=UDim.new(.18,0);pad.PaddingRight=UDim.new(.18,0);pad.Parent=text

	local click=Instance.new("ClickDetector")
	click.MaxActivationDistance=28
	click.Parent=key
	local prompt=Instance.new("ProximityPrompt")
	prompt.ActionText="Pressionar"
	prompt.ObjectText=label
	prompt.KeyboardKeyCode=Enum.KeyCode.E
	prompt.HoldDuration=0
	prompt.MaxActivationDistance=9
	prompt.RequiresLineOfSight=false
	prompt.Parent=key

	local function press(player)
		if pressed[key] then return end
		pressed[key]=true
		key.Color=Color3.fromRGB(86,94,101)
		local up=key.CFrame
		local down=up*CFrame.new(0,-.28,0)
		TweenService:Create(key,TweenInfo.new(.055,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=down}):Play()
		key:SetAttribute("LastPressedBy",player and player.UserId or 0)
		keyboard:SetAttribute("LastKey",label)
		task.delay(.1,function()
			if not key.Parent then return end
			TweenService:Create(key,TweenInfo.new(.09,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=up}):Play()
			key.Color=Color3.fromRGB(55,59,64)
			task.delay(.1,function() pressed[key]=nil end)
		end)
	end
	click.MouseClick:Connect(press)
	prompt.Triggered:Connect(press)
	return key
end

for rowIndex,row in ipairs(rows) do
	local count=#row.keys
	local total=(count-1)*pitch
	local start=-total/2+row.offset
	local z=(rowIndex-2.5)*pitch
	for i,label in ipairs(row.keys) do
		makeKey(label,start+(i-1)*pitch,z)
	end
end
makeKey("SPACE",0,5.05,11.2)

local spawn=workspace:FindFirstChild("SpawnLocation")
if spawn then spawn.CFrame=CFrame.new(0,3,18) end
