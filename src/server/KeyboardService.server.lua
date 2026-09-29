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
	{id=6432306802,name="TestForest2",pos=Vector3.new(52,0,0)},
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

end

task.spawn(function()
	task.wait(1)
	for _,spec in ipairs(VISUAL_ASSETS) do
		loadVisualAsset(spec)
		task.wait(.25)
	end
end)


-- Player morph test: replace the player's Character with asset 117859430905186.
local MORPH_ASSET_ID=117859430905186

local function showMorphDiagnostic(player,text)
	local pg=player:WaitForChild("PlayerGui",10)
	if not pg then return end
	local old=pg:FindFirstChild("MorphRigDiagnostic")
	if old then old:Destroy() end
	local gui=Instance.new("ScreenGui")
	gui.Name="MorphRigDiagnostic"; gui.ResetOnSpawn=false; gui.Parent=pg
	local frame=Instance.new("Frame")
	frame.Size=UDim2.new(0,560,0,235); frame.Position=UDim2.new(.5,-280,0,175)
	frame.BackgroundColor3=Color3.fromRGB(15,17,21); frame.BackgroundTransparency=.05; frame.Parent=gui
	Instance.new("UICorner",frame).CornerRadius=UDim.new(0,12)
	local label=Instance.new("TextLabel")
	label.Size=UDim2.new(1,-24,1,-20); label.Position=UDim2.new(0,12,0,10)
	label.BackgroundTransparency=1; label.TextWrapped=true
	label.TextXAlignment=Enum.TextXAlignment.Left; label.TextYAlignment=Enum.TextYAlignment.Top
	label.Font=Enum.Font.Code; label.TextSize=15; label.TextColor3=Color3.new(1,1,1)
	label.Text=text; label.Parent=frame
end


local function morphPlayer(player,character)
	local steps={}
	local function status(message)
		table.insert(steps,message)
		print("[PlayerMorph] "..message)
		task.spawn(showMorphDiagnostic,player,"MORPH EXECUTION "..MORPH_ASSET_ID.."\n"..table.concat(steps,"\n"))
	end
	status("1. morphPlayer INICIO")
	task.wait(1)
	if not character or character~=player.Character then status("PAROU: Character mudou antes do teste"); return end
	status("2. Character original confirmado")
	local oldRoot=character:FindFirstChild("HumanoidRootPart")
	if not oldRoot then status("PAROU: Character original sem HumanoidRootPart"); return end
	status("3. Root original OK")
	local spawnCF=oldRoot.CFrame

	local ok,container=pcall(function() return InsertService:LoadAsset(MORPH_ASSET_ID) end)
	if not ok then status("PAROU: LoadAsset FALHOU - "..tostring(container)); return end
	status("4. LoadAsset OK")
	local candidates=container:GetChildren()
	local morph
	-- Asset 117859430905186 is an R15 rig without a Humanoid. Find the actual
	-- character model by its rig parts instead of requiring Humanoid up front.
	for _,candidate in ipairs(container:GetDescendants()) do
		if candidate:IsA("Model")
			and candidate:FindFirstChild("HumanoidRootPart")
			and candidate:FindFirstChild("UpperTorso") then
			morph=candidate
			break
		end
	end
	if not morph then
		for _,candidate in ipairs(candidates) do
			if candidate:IsA("Model") and candidate:FindFirstChild("HumanoidRootPart",true) then
				morph=candidate
				break
			end
		end
	end
	if not morph and #candidates==1 and candidates[1]:IsA("Model") then morph=candidates[1] end
	if not morph then status("PAROU: nenhum Model candidato encontrado"); container:Destroy(); return end
	status("5. Model candidato: "..morph.Name)
	morph.Parent=workspace
	container:Destroy()
	morph.Name=player.Name

	local humanoid=morph:FindFirstChildOfClass("Humanoid")
	local root=morph:FindFirstChild("HumanoidRootPart")
	if not root then status("PAROU: modelo sem HumanoidRootPart"); morph:Destroy(); return end
	status("6. HumanoidRootPart OK")
	-- This asset is an R15 rig but ships without a Humanoid. Inject one so
	-- Roblox can treat the imported rig as a playable Character.
	if not humanoid then
		humanoid=Instance.new("Humanoid")
		humanoid.Name="Humanoid"
		humanoid.RigType=Enum.HumanoidRigType.R15
		humanoid.WalkSpeed=16
		humanoid.JumpPower=50
		humanoid.AutoRotate=true
		humanoid.Parent=morph
		status("7. Humanoid R15 INJETADO")
	end

	-- Stabilize the imported rig before handing it to the player.
	-- Imported decorative rigs can contain dozens of collidable parts that
	-- explode apart / fling the character when all are released at once.
	for _,obj in ipairs(morph:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored=false
			obj.CanCollide=false
			obj.CanTouch=false
			obj.CanQuery=true
			obj.AssemblyLinearVelocity=Vector3.zero
			obj.AssemblyAngularVelocity=Vector3.zero
			obj.Massless=(obj~=root)
		end
	end
	root.CanCollide=false
	root.Massless=false
	root.AssemblyLinearVelocity=Vector3.zero
	root.AssemblyAngularVelocity=Vector3.zero
	status("8. Rig estabilizado / colisao interna removida")
	-- Pivot the whole rig instead of moving only HRP; this preserves every
	-- imported Motor6D offset and avoids a physics impulse on spawn.
	local currentPivot=morph:GetPivot()
	local relative=currentPivot:ToObjectSpace(root.CFrame)
	morph:PivotTo(spawnCF*relative:Inverse())
	root.AssemblyLinearVelocity=Vector3.zero
	root.AssemblyAngularVelocity=Vector3.zero
	status("9. Rig inteiro posicionado no player")
	morph:SetAttribute("MorphAssetId",MORPH_ASSET_ID)

	local okSet,errSet=pcall(function() player.Character=morph end)
	if not okSet then status("PAROU: player.Character falhou - "..tostring(errSet)); morph:Destroy(); return end
	status("10. player.Character SUBSTITUIDO")
	task.wait(.2)
	if player.Character~=morph then status("PAROU: Roblox nao manteve o novo Character"); return end
	character:Destroy()
	status("11. SUCESSO - personagem antigo destruido")
end

local function setupMorph(player)
	player.CharacterAdded:Connect(function(character)
		if character:GetAttribute("MorphAssetId")==MORPH_ASSET_ID then return end
		task.spawn(morphPlayer,player,character)
	end)
	if player.Character and player.Character:GetAttribute("MorphAssetId")~=MORPH_ASSET_ID then
		task.spawn(morphPlayer,player,player.Character)
	end
end

for _,player in ipairs(Players:GetPlayers()) do setupMorph(player) end
Players.PlayerAdded:Connect(setupMorph)


-- In-game rig diagnostic for morph asset 117859430905186.

task.spawn(function()
	task.wait(3)
	local ok,container=pcall(function() return InsertService:LoadAsset(MORPH_ASSET_ID) end)
	local report={"MORPH RIG "..MORPH_ASSET_ID}
	if not ok then
		table.insert(report,"LoadAsset: FALHOU")
		table.insert(report,tostring(container))
	else
		local descendants=container:GetDescendants()
		local humanoid=container:FindFirstChildWhichIsA("Humanoid",true)
		local hrp=container:FindFirstChild("HumanoidRootPart",true)
		local head=container:FindFirstChild("Head",true)
		local torso=container:FindFirstChild("Torso",true)
		local upper=container:FindFirstChild("UpperTorso",true)
		local parts,motors,models=0,0,0
		for _,obj in ipairs(descendants) do
			if obj:IsA("BasePart") then parts+=1 end
			if obj:IsA("Motor6D") then motors+=1 end
			if obj:IsA("Model") then models+=1 end
		end
		table.insert(report,"LoadAsset: OK")
		table.insert(report,"Humanoid: "..(humanoid and "SIM" or "NAO"))
		table.insert(report,"HumanoidRootPart: "..(hrp and "SIM" or "NAO"))
		table.insert(report,"Head: "..(head and "SIM" or "NAO"))
		table.insert(report,"Torso R6: "..(torso and "SIM" or "NAO"))
		table.insert(report,"UpperTorso R15: "..(upper and "SIM" or "NAO"))
		table.insert(report,"BaseParts: "..parts.." | Motor6D: "..motors.." | Models: "..models)
		if humanoid then table.insert(report,"RigType: "..tostring(humanoid.RigType)) end
		container:Destroy()
	end
	local textReport=table.concat(report,"\n")
	for _,p in ipairs(Players:GetPlayers()) do task.spawn(showMorphDiagnostic,p,textReport) end
	Players.PlayerAdded:Connect(function(p) task.wait(2); showMorphDiagnostic(p,textReport) end)
end)
