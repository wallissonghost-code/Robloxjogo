local TweenService=game:GetService("TweenService")
local Players=game:GetService("Players")

-- Temporary diagnostic/import for inventory tree asset.
local InsertService=game:GetService("InsertService")
local TREE_ASSET_ID=580221169

local function showTreeStatus(status,detail)
	local function show(player)
		local pg=player:WaitForChild("PlayerGui",10)
		if not pg then return end
		local old=pg:FindFirstChild("TreeAssetDiagnostic")
		if old then old:Destroy() end
		local gui=Instance.new("ScreenGui")
		gui.Name="TreeAssetDiagnostic"; gui.ResetOnSpawn=false; gui.Parent=pg
		local frame=Instance.new("Frame")
		frame.Size=UDim2.new(0,520,0,145); frame.Position=UDim2.new(.5,-260,0,18)
		frame.BackgroundColor3=Color3.fromRGB(18,20,24); frame.BackgroundTransparency=.08; frame.Parent=gui
		Instance.new("UICorner",frame).CornerRadius=UDim.new(0,12)
		local label=Instance.new("TextLabel")
		label.Size=UDim2.new(1,-24,1,-20); label.Position=UDim2.new(0,12,0,10)
		label.BackgroundTransparency=1; label.TextWrapped=true
		label.TextXAlignment=Enum.TextXAlignment.Left; label.TextYAlignment=Enum.TextYAlignment.Top
		label.Font=Enum.Font.Gotham; label.TextSize=17; label.TextColor3=Color3.new(1,1,1)
		label.Text="TREE ASSET "..TREE_ASSET_ID.."\nSTATUS: "..status.."\n"..tostring(detail)
		label.Parent=frame
	end
	for _,p in ipairs(Players:GetPlayers()) do task.spawn(show,p) end
	Players.PlayerAdded:Connect(function(p) task.wait(2); show(p) end)
end

task.spawn(function()
	local ok,result=pcall(function() return InsertService:LoadAsset(TREE_ASSET_ID) end)
	if not ok then
		showTreeStatus("FALHOU",tostring(result))
		return
	end
	local children=result:GetChildren()
	if #children==0 then
		result:Destroy()
		showTreeStatus("VAZIO","Roblox aceitou o ID, mas devolveu 0 objetos.")
		return
	end
	local tree
	if #children==1 then
		tree=children[1]; tree.Parent=workspace; result:Destroy()
	else
		tree=Instance.new("Model"); tree.Parent=workspace
		for _,v in ipairs(children) do v.Parent=tree end
		result:Destroy()
	end
	tree.Name="ImportedTree_"..TREE_ASSET_ID
	if tree:IsA("BasePart") then tree.Anchored=true end
	for _,v in ipairs(tree:GetDescendants()) do if v:IsA("BasePart") then v.Anchored=true end end
	if tree:IsA("Model") then
		local cf,size=tree:GetBoundingBox()
		local pivot=tree:GetPivot()
		local bottom=cf.Position.Y-size.Y/2
		tree:PivotTo(pivot+Vector3.new(10-pivot.Position.X,-bottom,3-pivot.Position.Z))
	elseif tree:IsA("BasePart") then
		tree.Position=Vector3.new(10,tree.Size.Y/2,3)
	end
	showTreeStatus("CARREGOU","Asset recebido pelo Roblox e colocado em X=10, Z=3.")
end)


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
local PRESS=1.30
local Y=2.05
local ACTIVE_COLORS={Color3.fromRGB(36,220,120),Color3.fromRGB(55,170,255),Color3.fromRGB(255,190,45),Color3.fromRGB(255,85,125),Color3.fromRGB(165,95,255),Color3.fromRGB(40,225,210),Color3.fromRGB(255,120,45),Color3.fromRGB(100,225,80),Color3.fromRGB(80,135,255)}

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


-- Visual-only asset gallery test. No gameplay mechanics are intentionally added.
local VISUAL_ASSETS={
	{id=106424344571308,name="TestKeyboard",pos=Vector3.new(18,0,0)},
	{id=117859430905186,name="TestHumanoid",pos=Vector3.new(26,0,0)},
	{id=113427265105121,name="TestPortalGun",pos=Vector3.new(34,0,0)},
	{id=5352156968,name="TestPlayerRank",pos=Vector3.new(42,0,0)},
}

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

	-- Turn the humanoid test asset into a static avatar statue.
	if spec.id==117859430905186 then
		local humanoid=root:FindFirstChildOfClass("Humanoid") or root:FindFirstChildWhichIsA("Humanoid",true)
		if not humanoid then
			warn("[AvatarStatue] Asset loaded, but no Humanoid was found")
			return
		end
		local function applyPlayerAvatar(player)
			local okDesc,description=pcall(function()
				return Players:GetHumanoidDescriptionFromUserId(player.UserId)
			end)
			if not okDesc then
				warn("[AvatarStatue] Could not get avatar for "..player.Name..": "..tostring(description))
				return
			end
			local okApply,err=pcall(function()
				humanoid:ApplyDescription(description)
			end)
			if not okApply then
				warn("[AvatarStatue] Could not apply avatar: "..tostring(err))
				return
			end
			-- Applying a description can create new accessory parts; freeze them too.
			task.wait(.5)
			for _,obj in ipairs(root:GetDescendants()) do
				if obj:IsA("BasePart") then obj.Anchored=true end
			end
			root:SetAttribute("AvatarUserId",player.UserId)
			print("[AvatarStatue] Applied avatar from "..player.Name)
		end
		local player=Players:GetPlayers()[1]
		if player then
			task.spawn(applyPlayerAvatar,player)
		else
			local conn
			conn=Players.PlayerAdded:Connect(function(joined)
				conn:Disconnect()
				task.spawn(applyPlayerAvatar,joined)
			end)
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
