local TweenService=game:GetService("TweenService")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")

local InsertService=game:GetService("InsertService")

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
local PRESS=.861 -- 60% of the 1.435-stud mechanical key height
local Y=2.05
local ACTIVE_COLORS={Color3.fromRGB(36,220,120),Color3.fromRGB(55,170,255),Color3.fromRGB(255,190,45),Color3.fromRGB(255,85,125),Color3.fromRGB(165,95,255),Color3.fromRGB(40,225,210),Color3.fromRGB(255,120,45),Color3.fromRGB(100,225,80),Color3.fromRGB(80,135,255)}

local stopPlate=Instance.new("Part")
stopPlate.Name="KeypadBase"
stopPlate.Anchored=true
stopPlate.Size=Vector3.new(PITCH*3+.35,2,PITCH*3+.35)
stopPlate.Position=Vector3.new(0,1.025,0)
stopPlate.Material=Enum.Material.SmoothPlastic
stopPlate.Color=Color3.fromRGB(205,207,203)
stopPlate.TopSurface=Enum.SurfaceType.Smooth
stopPlate.BottomSurface=Enum.SurfaceType.Smooth
stopPlate.Parent=keypad

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
			-- Keep the key's activated color after the player leaves it.
			-- Only restore the physical height; color remains as a persistent stepped-on state.
			for _,piece in ipairs(pieces) do
				piece.Material=Enum.Material.SmoothPlastic
				piece.Color=activeColor
			end
			txt.TextColor3=Color3.fromRGB(18,18,18)
			move(raised,.14,Enum.EasingStyle.Back)
		end
	end

	-- Touched is only a wake-up hint. The authoritative state is checked against
	-- the player's fixed X/Z footprint below, so moving the key cannot toggle itself.
	body.Touched:Connect(function(hit)
		local player,character=playerFromHit(hit)
		if not player then return end
		occupants[character]=true
		setPressed(true,player)
	end)

	local accumulator=0
	local heartbeatConnection
	heartbeatConnection=RunService.Heartbeat:Connect(function(dt)
		if not holder.Parent then
			heartbeatConnection:Disconnect()
			return
		end
		accumulator+=dt
		if accumulator<.05 then return end
		accumulator=0

		local anyPlayer=nil
		table.clear(occupants)
		for _,player in ipairs(Players:GetPlayers()) do
			local character=player.Character
			local hum=character and character:FindFirstChildOfClass("Humanoid")
			local root=character and character:FindFirstChild("HumanoidRootPart")
			if hum and hum.Health>0 and root then
				local dx=math.abs(root.Position.X-x)
				local dz=math.abs(root.Position.Z-z)
				-- Y guard rejects players far above/below while remaining independent
				-- from the animated key body's own moving position.
				local dy=root.Position.Y-Y
				if dx<=KEY/2+.45 and dz<=KEY/2+.45 and dy>=-.5 and dy<=5.5 then
					occupants[character]=true
					anyPlayer=anyPlayer or player
				end
			end
		end

		if next(occupants) then
			setPressed(true,anyPlayer)
		else
			setPressed(false)
		end
	end)
end

for r,row in ipairs(rows) do
	for c,label in ipairs(row) do
		makeKey(label,(c-2)*PITCH,(r-2)*PITCH,(r-1)*3+c)
	end
end

local spawn=workspace:FindFirstChild("SpawnLocation")
if spawn then spawn.CFrame=CFrame.new(0,3,13.5) end


-- Visual-only asset gallery test. No gameplay mechanics are intentionally added.
local VISUAL_ASSETS={
	{id=106424344571308,name="TestKeyboard",pos=Vector3.new(18,0,0)},
}


local function applyImportedKeycapTemplate(assetRoot)
	-- Find repeated, key-sized BaseParts inside the already-loaded keyboard asset.
	-- Repetition is intentional: a keyboard normally contains many copies of one key shape.
	local groups={}
	for _,obj in ipairs(assetRoot:GetDescendants()) do
		if obj:IsA("BasePart") then
			local s=obj.Size
			if s.X>.15 and s.Y>.08 and s.Z>.15 then
				local a=math.floor(math.min(s.X,s.Z)*20+.5)/20
				local b=math.floor(math.max(s.X,s.Z)*20+.5)/20
				local h=math.floor(s.Y*20+.5)/20
				local sig=string.format("%.2f/%.2f/%.2f",a,b,h)
				groups[sig]=groups[sig] or {}
				table.insert(groups[sig],obj)
			end
		end
	end
	local best
	for _,group in pairs(groups) do
		if #group>=9 and (not best or #group>#best) then best=group end
	end
	if not best then
		warn("[KeycapTemplate] no repeated 9+ part group found; procedural keypad preserved")
		return false
	end

	local template=best[1]
	print(("[KeycapTemplate] using %s %s repeated=%d"):format(template.ClassName,template.Name,#best))
	for _,holder in ipairs(keypad:GetChildren()) do
		if holder:IsA("Model") and holder.Name:match("^Key_") then
			local body=holder:FindFirstChild("KeycapCollision")
			local oldTop=holder:FindFirstChild("KeycapTop")
			if body then
				-- Keep the original collision/tween body as the mechanic.
				-- Only replace its visible shell with one cloned asset key.
				for _,p in ipairs(holder:GetChildren()) do
					if p:IsA("BasePart") and p~=body then p.Transparency=1 end
				end
				body.Transparency=1

				local visual=template:Clone()
				visual.Name="ImportedKeycapVisual"
				visual.Anchored=false
				visual.CanCollide=false
				visual.CanTouch=false
				visual.CanQuery=false
				visual.Massless=true

				-- Normalize the source key to our 3x3 footprint while preserving its proportions.
				local maxXZ=math.max(visual.Size.X,visual.Size.Z)
				local scale=KEY/maxXZ
				visual.Size=Vector3.new(visual.Size.X*scale,math.min(visual.Size.Y*scale,KEY_HEIGHT),visual.Size.Z*scale)
				visual.CFrame=body.CFrame*CFrame.new(0,KEY_HEIGHT*.36,0)
				visual.Parent=holder

				-- Strip the source key's original legend (A, Q, etc.) before
				-- drawing our own 1-9 label. Keep only geometry/material.
				for _,d in ipairs(visual:GetDescendants()) do
					if d:IsA("Script") or d:IsA("LocalScript")
						or d:IsA("Decal") or d:IsA("Texture")
						or d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
						d:Destroy()
					end
				end
				-- Some legacy keys store the printed character directly on a face.
				pcall(function() visual.TopSurface=Enum.SurfaceType.Smooth end)
				pcall(function() visual.BottomSurface=Enum.SurfaceType.Smooth end)
				local weld=Instance.new("WeldConstraint")
				weld.Part0=body
				weld.Part1=visual
				weld.Parent=visual

				local gui=Instance.new("SurfaceGui")
				gui.Name="ImportedNumber"
				gui.Face=Enum.NormalId.Top
				gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud
				gui.PixelsPerStud=50
				gui.Parent=visual
				local txt=Instance.new("TextLabel")
				txt.Size=UDim2.fromScale(1,1)
				txt.BackgroundTransparency=1
				txt.Text=holder.Name:sub(5)
				txt.TextColor3=Color3.fromRGB(25,25,25)
				txt.TextScaled=true
				txt.Font=Enum.Font.GothamBold
				txt.Parent=gui
				local pad=Instance.new("UIPadding")
				pad.PaddingTop=UDim.new(.2,0); pad.PaddingBottom=UDim.new(.2,0)
				pad.PaddingLeft=UDim.new(.2,0); pad.PaddingRight=UDim.new(.2,0)
				pad.Parent=txt
			end
		end
	end
	return true
end

local function loadVisualAsset(spec)
	local ok,container=pcall(function() return InsertService:LoadAsset(spec.id) end)
	if not ok then
		warn(("[VisualAssetTest] %s (%s) failed: %s"):format(spec.name,spec.id,tostring(container)))
		return
	end
	local children=container:GetChildren()
	if #children==0 then
		warn(("[VisualAssetTest] %s (%s) returned empty"):format(spec.name,spec.id))
		container:Destroy()
		return
	end
	local root
	if #children==1 then
		root=children[1]; root.Parent=workspace; container:Destroy()
	else
		root=Instance.new("Model"); root.Parent=workspace
		for _,child in ipairs(children) do child.Parent=root end
		container:Destroy()
	end
	root.Name=spec.name.."_"..spec.id
	if root:IsA("BasePart") then root.Anchored=true end
	for _,obj in ipairs(root:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored=true
		end
	end
	if root:IsA("Model") then
		local cf,size=root:GetBoundingBox()
		local pivot=root:GetPivot()
		local bottom=cf.Position.Y-size.Y/2
		root:PivotTo(pivot+Vector3.new(spec.pos.X-pivot.Position.X,spec.pos.Y-bottom,spec.pos.Z-pivot.Position.Z))
	elseif root:IsA("BasePart") then
		root.Position=Vector3.new(spec.pos.X,spec.pos.Y+root.Size.Y/2,spec.pos.Z)
	end
	print(("[VisualAssetTest] loaded %s (%s)"):format(spec.name,spec.id))
	if spec.id==106424344571308 then
		local cloned=applyImportedKeycapTemplate(root)
		if cloned then
			-- The 3x3 now owns independent cloned key geometry.
			-- The source keyboard is only a temporary donor and can leave the map.
			root:Destroy()
			print("[KeycapTemplate] donor keyboard removed after independent clones were created")
		end
	end

end

task.spawn(function()
	task.wait(1)
	for _,spec in ipairs(VISUAL_ASSETS) do
		loadVisualAsset(spec)
		task.wait(.25)
	end
end)
