local TweenService=game:GetService("TweenService")
local Players=game:GetService("Players")

for _,name in ipairs({"Keyboard","RetroKeyboard","PremiumKeypad"}) do
	local old=workspace:FindFirstChild(name)
	if old then old:Destroy() end
end

local keypad=Instance.new("Model")
keypad.Name="PremiumKeypad"
keypad.Parent=workspace

local rows={{"1","2","3"},{"4","5","6"},{"7","8","9"}}
local KEY=3.35
local GAP=.38
local PITCH=KEY+GAP
local KEY_HEIGHT=2.05
local TOP_SCALE=.82
local PRESS=.72
local Y=2.05

local deck=Instance.new("Part")
deck.Name="KeypadDeck"
deck.Anchored=true
deck.Size=Vector3.new(12.1,.7,12.1)
deck.Position=Vector3.new(0,.35,0)
deck.Material=Enum.Material.SmoothPlastic
deck.Color=Color3.fromRGB(49,51,55)
deck.TopSurface=Enum.SurfaceType.Smooth
deck.BottomSurface=Enum.SurfaceType.Smooth
deck.Parent=keypad

local rim=Instance.new("Part")
rim.Name="InnerPlate"
rim.Anchored=true
rim.CanCollide=false
rim.Size=Vector3.new(11.25,.18,11.25)
rim.Position=Vector3.new(0,.78,0)
rim.Material=Enum.Material.Metal
rim.Color=Color3.fromRGB(82,85,89)
rim.Parent=keypad

local function playerFromHit(hit)
	local character=hit and hit:FindFirstAncestorOfClass("Model")
	if not character then return end
	local hum=character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health<=0 then return end
	local player=Players:GetPlayerFromCharacter(character)
	if player then return player,character end
end

local function makeKey(label,x,z)
	local holder=Instance.new("Model")
	holder.Name="Key_"..label
	holder.Parent=keypad

	local lower=Instance.new("Part")
	lower.Name="Body"
	lower.Anchored=true
	lower.Size=Vector3.new(KEY,KEY_HEIGHT,KEY)
	lower.Position=Vector3.new(x,Y,z)
	lower.Material=Enum.Material.SmoothPlastic
	lower.Color=Color3.fromRGB(224,224,218)
	lower.TopSurface=Enum.SurfaceType.Smooth
	lower.BottomSurface=Enum.SurfaceType.Smooth
	lower:SetAttribute("Key",label)
	lower.Parent=holder

	local bevel=Instance.new("Part")
	bevel.Name="Top"
	bevel.Anchored=true
	bevel.CanCollide=false
	bevel.CanTouch=false
	bevel.Size=Vector3.new(KEY*TOP_SCALE,.22,KEY*TOP_SCALE)
	bevel.Position=Vector3.new(x,Y+KEY_HEIGHT/2+.08,z)
	bevel.Material=Enum.Material.SmoothPlastic
	bevel.Color=Color3.fromRGB(242,242,236)
	bevel.TopSurface=Enum.SurfaceType.Smooth
	bevel.Parent=holder

	local gui=Instance.new("SurfaceGui")
	gui.Face=Enum.NormalId.Top
	gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud=45
	gui.Parent=bevel
	local txt=Instance.new("TextLabel")
	txt.Size=UDim2.fromScale(1,1)
	txt.BackgroundTransparency=1
	txt.Text=label
	txt.TextColor3=Color3.fromRGB(31,32,34)
	txt.TextScaled=true
	txt.Font=Enum.Font.GothamBold
	txt.Parent=gui
	local pad=Instance.new("UIPadding")
	pad.PaddingTop=UDim.new(.22,0);pad.PaddingBottom=UDim.new(.22,0);pad.PaddingLeft=UDim.new(.22,0);pad.PaddingRight=UDim.new(.22,0)
	pad.Parent=txt

	local upBody=lower.CFrame
	local upTop=bevel.CFrame
	local downBody=upBody*CFrame.new(0,-PRESS,0)
	local downTop=upTop*CFrame.new(0,-PRESS,0)
	local occupants={}
	local pressed=false

	local function setPressed(value,player)
		if pressed==value then return end
		pressed=value
		if value then
			lower.Color=Color3.fromRGB(196,197,193)
			bevel.Color=Color3.fromRGB(216,217,212)
			TweenService:Create(lower,TweenInfo.new(.07,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=downBody}):Play()
			TweenService:Create(bevel,TweenInfo.new(.07,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=downTop}):Play()
			keypad:SetAttribute("LastKey",label)
			lower:SetAttribute("LastPressedBy",player and player.UserId or 0)
		else
			TweenService:Create(lower,TweenInfo.new(.14,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{CFrame=upBody}):Play()
			TweenService:Create(bevel,TweenInfo.new(.14,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{CFrame=upTop}):Play()
			lower.Color=Color3.fromRGB(224,224,218)
			bevel.Color=Color3.fromRGB(242,242,236)
		end
	end

	lower.Touched:Connect(function(hit)
		local player,character=playerFromHit(hit)
		if not player then return end
		occupants[character]=true
		setPressed(true,player)
	end)
	lower.TouchEnded:Connect(function(hit)
		local player,character=playerFromHit(hit)
		if not player then return end
		task.delay(.08,function()
			local root=character and character:FindFirstChild("HumanoidRootPart")
			if not root then occupants[character]=nil
			else
				local p=lower.CFrame:PointToObjectSpace(root.Position)
				if math.abs(p.X)>KEY/2+.7 or math.abs(p.Z)>KEY/2+.7 then occupants[character]=nil end
			end
			if next(occupants)==nil then setPressed(false) end
		end)
	end)
end

for r,row in ipairs(rows) do
	for c,label in ipairs(row) do
		makeKey(label,(c-2)*PITCH,(r-2)*PITCH)
	end
end

local spawn=workspace:FindFirstChild("SpawnLocation")
if spawn then spawn.CFrame=CFrame.new(0,3,13.5) end
