local TweenService=game:GetService("TweenService")
local Players=game:GetService("Players")

local old=workspace:FindFirstChild("PremiumKeypad")
if old then old:Destroy() end

local keypad=Instance.new("Model")
keypad.Name="PremiumKeypad"
keypad.Parent=workspace

local rows={{"1","2","3"},{"4","5","6"},{"7","8","9"}}
local KEY=3.35
local GAP=0
local PITCH=3.05 -- slight visual overlap to compensate imported mesh internal margins
local KEY_HEIGHT=2.05
local TOP_SCALE=.82
local PRESS=1.30
local Y=2.05
local ACTIVE_COLORS={Color3.fromRGB(36,220,120),Color3.fromRGB(55,170,255),Color3.fromRGB(255,190,45),Color3.fromRGB(255,85,125),Color3.fromRGB(165,95,255),Color3.fromRGB(40,225,210),Color3.fromRGB(255,120,45),Color3.fromRGB(100,225,80),Color3.fromRGB(80,135,255)}

local deck=Instance.new("Part")
deck.Name="KeypadDeck"
deck.Anchored=true
deck.Size=Vector3.new(PITCH*3+.35,1,PITCH*3+.35)
deck.Position=Vector3.new(0,0.525,0)
deck.Material=Enum.Material.SmoothPlastic
deck.Color=Color3.fromRGB(205,207,203)
deck.TopSurface=Enum.SurfaceType.Smooth
deck.BottomSurface=Enum.SurfaceType.Smooth
deck.Parent=keypad

local rim=Instance.new("Part")
rim.Name="InnerPlate"
rim.Anchored=true
rim.CanCollide=false
rim.Size=Vector3.new(PITCH*3+.18,.18,PITCH*3+.18)
rim.Position=Vector3.new(0,1.015,0)
rim.Material=Enum.Material.Metal
rim.Color=Color3.fromRGB(205,207,203)
rim.Parent=keypad

local function playerFromHit(hit)
	local character=hit and hit:FindFirstAncestorOfClass("Model")
	if not character then return end
	local hum=character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health<=0 then return end
	local player=Players:GetPlayerFromCharacter(character)
	if player then return player,character end
end

local function makeKey(label,x,z,index)
	local holder=Instance.new("Model")
	holder.Name="Key_"..label
	holder.Parent=keypad

	local activeColor=ACTIVE_COLORS[index]
	local baseColor=Color3.fromRGB(205,207,203)
	local sideColor=Color3.fromRGB(218,220,216)
	local topColor=Color3.fromRGB(239,240,236)
	local pieces={}

	local body=Instance.new("Part")
	body.Name="KeycapCollision"
	body.Anchored=true
	body.Size=Vector3.new(KEY,KEY_HEIGHT*.70,KEY)
	body.Position=Vector3.new(x,Y-KEY_HEIGHT*.15,z)
	body.Material=Enum.Material.SmoothPlastic
	body.Color=baseColor
	body.TopSurface=Enum.SurfaceType.Smooth
	body.BottomSurface=Enum.SurfaceType.Smooth
	body:SetAttribute("Key",label)
	body.Parent=holder
	table.insert(pieces,body)

	local topSize=KEY*.78
	local shoulderY=Y+KEY_HEIGHT*.31
	local top=Instance.new("Part")
	top.Name="KeycapTop"
	top.Anchored=true
	top.CanCollide=false
	top.CanTouch=false
	top.CanQuery=false
	top.Size=Vector3.new(topSize,.24,topSize)
	top.Position=Vector3.new(x,Y+KEY_HEIGHT*.52,z)
	top.Material=Enum.Material.SmoothPlastic
	top.Color=topColor
	top.TopSurface=Enum.SurfaceType.Smooth
	top.BottomSurface=Enum.SurfaceType.Smooth
	top.Parent=holder
	table.insert(pieces,top)

	local slopeHeight=KEY_HEIGHT*.42
	local inset=(KEY-topSize)/2
	local function wedge(name,size,cf)
		local w=Instance.new("WedgePart")
		w.Name=name
		w.Anchored=true
		w.CanCollide=false
		w.CanTouch=false
		w.CanQuery=false
		w.Size=size
		w.CFrame=cf
		w.Material=Enum.Material.SmoothPlastic
		w.Color=sideColor
		w.Parent=holder
		table.insert(pieces,w)
		return w
	end

	wedge("BevelFront",Vector3.new(topSize,slopeHeight,inset),CFrame.new(x,shoulderY,z-KEY/2+inset/2)*CFrame.Angles(0,0,0))
	wedge("BevelBack",Vector3.new(topSize,slopeHeight,inset),CFrame.new(x,shoulderY,z+KEY/2-inset/2)*CFrame.Angles(0,math.pi,0))
	wedge("BevelLeft",Vector3.new(topSize,slopeHeight,inset),CFrame.new(x-KEY/2+inset/2,shoulderY,z)*CFrame.Angles(0,math.pi/2,0))
	wedge("BevelRight",Vector3.new(topSize,slopeHeight,inset),CFrame.new(x+KEY/2-inset/2,shoulderY,z)*CFrame.Angles(0,-math.pi/2,0))

	local gui=Instance.new("SurfaceGui")
	gui.Face=Enum.NormalId.Top
	gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud=45
	gui.Parent=top
	local txt=Instance.new("TextLabel")
	txt.Size=UDim2.fromScale(1,1)
	txt.BackgroundTransparency=1
	txt.Text=label
	txt.TextColor3=Color3.fromRGB(31,32,34)
	txt.TextScaled=true
	txt.Font=Enum.Font.GothamBold
	txt.Parent=gui
	local pad=Instance.new("UIPadding")
	pad.PaddingTop=UDim.new(.20,0);pad.PaddingBottom=UDim.new(.20,0);pad.PaddingLeft=UDim.new(.20,0);pad.PaddingRight=UDim.new(.20,0)
	pad.Parent=txt

	local raised={}
	local pressedTargets={}
	for i,piece in ipairs(pieces) do
		raised[i]=piece.CFrame
		pressedTargets[i]=piece.CFrame*CFrame.new(0,-PRESS,0)
	end

	local occupants={}
	local pressed=false
	local tweens={}
	local pressSound=Instance.new("Sound")
	pressSound.Name="KeyPressSound"
	pressSound.SoundId="rbxasset://sounds/button.wav"
	pressSound.Volume=.28
	pressSound.PlaybackSpeed=.96+((index-1)%5)*.018
	pressSound.Parent=body

	local function move(targets,time,easing)
		for _,t in ipairs(tweens) do t:Cancel() end
		table.clear(tweens)
		local info=TweenInfo.new(time,easing,Enum.EasingDirection.Out)
		for i,piece in ipairs(pieces) do
			local t=TweenService:Create(piece,info,{CFrame=targets[i]})
			table.insert(tweens,t)
			t:Play()
		end
	end

	local function setPressed(value,player)
		if pressed==value then return end
		pressed=value
		if value then
			for _,piece in ipairs(pieces) do
				piece.Material=Enum.Material.Neon
				piece.Color=activeColor
			end
			txt.TextColor3=Color3.fromRGB(18,18,18)
			pressSound.TimePosition=0
			pressSound:Play()
			move(pressedTargets,.07,Enum.EasingStyle.Quad)
			keypad:SetAttribute("LastKey",label)
			body:SetAttribute("LastPressedBy",player and player.UserId or 0)
		else
			body.Material=Enum.Material.SmoothPlastic
			body.Color=baseColor
			for _,piece in ipairs(pieces) do
				if piece~=body then
					piece.Material=Enum.Material.SmoothPlastic
					piece.Color=piece==top and topColor or sideColor
				end
			end
			txt.TextColor3=Color3.fromRGB(31,32,34)
			move(raised,.14,Enum.EasingStyle.Back)
		end
	end

	body.Touched:Connect(function(hit)
		local player,character=playerFromHit(hit)
		if not player then return end
		occupants[character]=true
		setPressed(true,player)
	end)
	body.TouchEnded:Connect(function(hit)
		local player,character=playerFromHit(hit)
		if not player then return end
		task.delay(.08,function()
			local root=character and character:FindFirstChild("HumanoidRootPart")
			if not root then occupants[character]=nil
			else
				local p=body.CFrame:PointToObjectSpace(root.Position)
				if math.abs(p.X)>KEY/2+.7 or math.abs(p.Z)>KEY/2+.7 then occupants[character]=nil end
			end
			if next(occupants)==nil then setPressed(false) end
		end)
	end)
end

for r,row in ipairs(rows) do
	for c,label in ipairs(row) do
		makeKey(label,(c-2)*PITCH,(r-2)*PITCH,(r-1)*3+c)
	end
end

local spawn=workspace:FindFirstChild("SpawnLocation")
if spawn then spawn.CFrame=CFrame.new(0,3,13.5) end


-- Standalone keycap captured from the donor keyboard.
local KEYCAP_MESH_ID="rbxassetid://8837613273"
local KEYCAP_SOURCE_SIZE=Vector3.new(3,1.368114709854126,3)

local function createStandaloneKeycap(holder)
	local body=holder:FindFirstChild("KeycapCollision")
	if not body then return end
	for _,p in ipairs(holder:GetChildren()) do
		if p:IsA("BasePart") and p~=body then p.Transparency=1 end
	end
	body.Transparency=1
	local visual=Instance.new("MeshPart")
	visual.Name="ImportedKeycapVisual"
	visual.MeshId=KEYCAP_MESH_ID
	visual.Size=KEYCAP_SOURCE_SIZE
	visual.Color=Color3.new(0.972549,0.972549,0.972549)
	visual.Material=Enum.Material.SmoothPlastic
	visual.Anchored=false
	visual.CanCollide=false
	visual.CanTouch=false
	visual.CanQuery=false
	visual.Massless=true
	local scale=KEY/math.max(visual.Size.X,visual.Size.Z)
	visual.Size=Vector3.new(visual.Size.X*scale,math.min(visual.Size.Y*scale,KEY_HEIGHT),visual.Size.Z*scale)
	visual.CFrame=body.CFrame*CFrame.new(0,KEY_HEIGHT*.36,0)
	visual.Parent=holder
	local weld=Instance.new("WeldConstraint")
	weld.Part0=body; weld.Part1=visual; weld.Parent=visual
	local gui=Instance.new("SurfaceGui")
	gui.Name="ImportedNumber"; gui.Face=Enum.NormalId.Top
	gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud=50; gui.Parent=visual
	local txt=Instance.new("TextLabel")
	txt.Size=UDim2.fromScale(1,1); txt.BackgroundTransparency=1
	txt.Text=holder.Name:sub(5); txt.TextColor3=Color3.fromRGB(25,25,25)
	txt.TextScaled=true; txt.Font=Enum.Font.GothamBold; txt.Parent=gui
	local pad=Instance.new("UIPadding")
	pad.PaddingTop=UDim.new(.2,0); pad.PaddingBottom=UDim.new(.2,0)
	pad.PaddingLeft=UDim.new(.2,0); pad.PaddingRight=UDim.new(.2,0); pad.Parent=txt
end

for _,holder in ipairs(keypad:GetChildren()) do
	if holder:IsA("Model") and holder.Name:match("^Key_") then createStandaloneKeycap(holder) end
end
