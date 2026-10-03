local InsertService=game:GetService("InsertService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")

local COW_ASSET_ID=80696062872929
local COW_BUILD="2026-10-03-cow-rollback-hoof-lock-5"
local remote=ReplicatedStorage:FindFirstChild("CowMorphToggle") or Instance.new("RemoteEvent")
remote.Name="CowMorphToggle"
remote.Parent=ReplicatedStorage

local states={}

local function cowRigReport(visual)
	local lines={"=== COW RIG "..COW_ASSET_ID.." ==="}
	local motors,welds,parts=0,0,0
	for _,obj in ipairs(visual:GetDescendants()) do
		if obj:IsA("BasePart") then parts+=1 end
		if obj:IsA("Motor6D") then motors+=1 end
		if obj:IsA("Weld") or obj:IsA("WeldConstraint") then welds+=1 end
	end
	table.insert(lines,("Parts: %d | Motor6D: %d | Welds: %d"):format(parts,motors,welds))
	table.insert(lines,"--- JOINTS ---")
	for _,obj in ipairs(visual:GetDescendants()) do
		if obj:IsA("Motor6D") or obj:IsA("Weld") or obj:IsA("WeldConstraint") then
			local p0=obj.Part0 and obj.Part0.Name or "nil"
			local p1=obj.Part1 and obj.Part1.Name or "nil"
			table.insert(lines,("%s %s | %s -> %s"):format(obj.ClassName,obj.Name,p0,p1))
		end
	end
	table.insert(lines,"--- PARTS ---")
	for _,obj in ipairs(visual:GetDescendants()) do
		if obj:IsA("BasePart") then
			table.insert(lines,("%s [%s] size=%.2f,%.2f,%.2f"):format(obj.Name,obj.ClassName,obj.Size.X,obj.Size.Y,obj.Size.Z))
		end
	end
	return table.concat(lines,"\n")
end

local function setCharacterVisible(character,visible)
	for _,obj in ipairs(character:GetDescendants()) do
		if obj:IsA("BasePart") then
			if obj.Name~="HumanoidRootPart" then
				if visible then
					local saved=obj:GetAttribute("CowOldTransparency")
					if saved~=nil then obj.Transparency=saved; obj:SetAttribute("CowOldTransparency",nil) end
				else
					if obj:GetAttribute("CowOldTransparency")==nil then obj:SetAttribute("CowOldTransparency",obj.Transparency) end
					obj.Transparency=1
				end
			end
		elseif obj:IsA("Decal") then
			if visible then
				local saved=obj:GetAttribute("CowOldTransparency")
				if saved~=nil then obj.Transparency=saved; obj:SetAttribute("CowOldTransparency",nil) end
			else
				if obj:GetAttribute("CowOldTransparency")==nil then obj:SetAttribute("CowOldTransparency",obj.Transparency) end
				obj.Transparency=1
			end
		end
	end
end

local function unwrapAsset(container)
	local children=container:GetChildren()
	if #children==1 then
		local only=children[1]
		only.Parent=nil
		container:Destroy()
		return only
	end
	local model=Instance.new("Model")
	model.Name="CowVisual"
	for _,child in ipairs(children) do child.Parent=model end
	container:Destroy()
	return model
end

local function getParts(root)
	local parts={}
	if root:IsA("BasePart") then table.insert(parts,root) end
	for _,obj in ipairs(root:GetDescendants()) do
		if obj:IsA("BasePart") then table.insert(parts,obj) end
	end
	return parts
end

local function chooseRoot(root,parts)
	if root:IsA("Model") then
		return root:FindFirstChild("HumanoidRootPart",true)
			or root.PrimaryPart
			or root:FindFirstChild("Torso",true)
			or root:FindFirstChild("UpperTorso",true)
			or parts[1]
	end
	return root:IsA("BasePart") and root or parts[1]
end

local function applyNumberMap(visual)
	local list=getParts(visual)
	local filtered={}
	for _,part in ipairs(list) do
		if part.Name~="RootPart" then table.insert(filtered,part) end
	end
	table.sort(filtered,function(a,b)
		if a.Name==b.Name then return a:GetFullName()<b:GetFullName() end
		return a.Name<b.Name
	end)
	for i,part in ipairs(filtered) do
		local tag=Instance.new("BillboardGui")
		tag.Name="CowNumberTag_"..i
		tag.Size=UDim2.fromOffset(16,14)
		tag.StudsOffset=Vector3.new(0,math.max(.2,part.Size.Y*.25),0)
		tag.AlwaysOnTop=true
		tag.MaxDistance=28
		tag.Enabled=false
		tag.Parent=part
		local label=Instance.new("TextLabel")
		label.Size=UDim2.fromScale(1,1)
		label.BackgroundTransparency=1
		label.TextColor3=Color3.new(1,1,1)
		label.TextStrokeTransparency=.05
		label.Font=Enum.Font.GothamBold
		label.TextScaled=false
		label.TextSize=9
		label.Text=tostring(i)
		label.Parent=tag
	end
	return #filtered
end

local function setNumberVisible(visual,number,visible)
	local wanted="CowNumberTag_"..tostring(number)
	for _,obj in ipairs(visual:GetDescendants()) do
		if obj:IsA("BillboardGui") and obj.Name==wanted then
			obj.Enabled=visible==true
			return true
		end
	end
	return false
end

local function findMotorForPart(visual,partName)
	for _,obj in ipairs(visual:GetDescendants()) do
		if obj:IsA("Motor6D") and obj.Part1 and obj.Part1.Name==partName then
			return obj
		end
	end
end

local function setupCowWalk(player,visual,humanoid,visualRoot)
	-- The cow asset is a star rig: leg decorations/hooves are separate RootPart children.
	-- Build four complete leg groups (long leg + nearby small meshes) and animate carriers.
	local legNames={
		["Cube.017"]=true,["Cube.018"]=true,
		["Pintar marron.002"]=true,["Pintar marron.003"]=true,
	}
	local hoofNames={
		["M.B.L.F."]=true,["M.B.R.F"]=true,["M.F.L.F"]=true,["M.F.R.F"]=true,
	}
	local longLegs,hooves={},{}
	for _,p in ipairs(getParts(visual)) do
		if legNames[p.Name] then table.insert(longLegs,p) end
		if hoofNames[p.Name] then table.insert(hooves,p) end
	end
	if #longLegs~=4 then return nil,"LONG LEGS="..#longLegs.."/4" end

	-- Pair each hoof AND every small leg-skin/decor mesh to the closest long leg.
	-- The imported asset attaches these black markings independently to RootPart.
	local hoofFor={}
	local skinFor={}
	for _,leg in ipairs(longLegs) do skinFor[leg]={} end
	for _,p in ipairs(getParts(visual)) do
		if p~=visualRoot and not legNames[p.Name] and not hoofNames[p.Name] then
			local best,bestD=nil,math.huge
			for _,leg in ipairs(longLegs) do
				local d=(p.Position-leg.Position).Magnitude
				if d<bestD then best,bestD=leg,d end
			end
			-- Only claim small meshes physically sitting on/next to a leg. This avoids
			-- stealing body/head pieces while capturing the separate black leg markings.
			if best and bestD <= math.max(1.05,best.Size.X*1.35) and p.Size.Magnitude <= 1.8 then
				table.insert(skinFor[best],p)
			end
		end
	end
	for _,hoof in ipairs(hooves) do
		local best,bestD=nil,math.huge
		for _,leg in ipairs(longLegs) do
			local d=(hoof.Position-leg.Position).Magnitude
			if d<bestD then best,bestD=leg,d end
		end
		if best then hoofFor[best]=hoof end
	end

	local function removeConnections(part)
		for _,j in ipairs(visual:GetDescendants()) do
			if (j:IsA("Motor6D") or j:IsA("Weld") or j:IsA("WeldConstraint"))
				and (j.Part0==part or j.Part1==part) then
				j:Destroy()
			end
		end
	end

	local legs={}
	for _,leg in ipairs(longLegs) do
		local hoof=hoofFor[leg]
		local legWorld=leg.CFrame
		local hoofWorld=hoof and hoof.CFrame or nil
		local skins=skinFor[leg] or {}
		local skinWorld={}
		for _,skin in ipairs(skins) do skinWorld[skin]=skin.CFrame end
		removeConnections(leg)
		if hoof then removeConnections(hoof) end
		for _,skin in ipairs(skins) do removeConnections(skin) end

		-- Invisible carrier at the hip. It is the only articulated object.
		local hipWorld=legWorld*CFrame.new(0,leg.Size.Y*.5,0)
		local carrier=Instance.new("Part")
		carrier.Name="CowLegCarrier_"..leg.Name
		carrier.Size=Vector3.new(.12,.12,.12)
		carrier.Transparency=1
		carrier.CanCollide=false
		carrier.CanTouch=false
		carrier.CanQuery=false
		carrier.Massless=true
		carrier.Anchored=false
		carrier.CFrame=hipWorld
		carrier.Parent=visual

		local hip=Instance.new("Motor6D")
		hip.Name="CowHip_"..leg.Name
		hip.Part0=visualRoot
		hip.Part1=carrier
		hip.C0=visualRoot.CFrame:ToObjectSpace(hipWorld)
		hip.C1=CFrame.identity
		hip.Parent=visualRoot

		-- Weld visual pieces to the carrier preserving their exact current pose.
		local legWeld=Instance.new("Weld")
		legWeld.Name="CowLegVisual_"..leg.Name
		legWeld.Part0=carrier
		legWeld.Part1=leg
		legWeld.C0=carrier.CFrame:ToObjectSpace(legWorld)
		legWeld.C1=CFrame.identity
		legWeld.Parent=carrier
		if hoof then
			-- Keep the black hoof rigidly attached to the animated leg carrier.
			-- WeldConstraint avoids the imported hoof pose fighting a classic Weld C0.
			hoof.CFrame=hoofWorld
			local hoofWeld=Instance.new("WeldConstraint")
			hoofWeld.Name="CowHoofLock_"..hoof.Name
			hoofWeld.Part0=carrier
			hoofWeld.Part1=hoof
			hoofWeld.Parent=carrier
		end
		for _,skin in ipairs(skins) do
			local skinWeld=Instance.new("Weld")
			skinWeld.Name="CowLegSkin_"..skin.Name
			skinWeld.Part0=carrier
			skinWeld.Part1=skin
			skinWeld.C0=carrier.CFrame:ToObjectSpace(skinWorld[skin])
			skinWeld.C1=CFrame.identity
			skinWeld.Parent=carrier
		end

		table.insert(legs,{
			leg=leg,hoof=hoof,motor=hip,baseC0=hip.C0,
			pos=visualRoot.CFrame:PointToObjectSpace(leg.Position),
		})
	end

	table.sort(legs,function(x,y) return x.pos.Z<y.pos.Z end)
	local a={legs[1],legs[2]}; local b={legs[3],legs[4]}
	table.sort(a,function(x,y) return x.pos.X<y.pos.X end)
	table.sort(b,function(x,y) return x.pos.X<y.pos.X end)
	local gait={{a[1],1},{a[2],-1},{b[1],-1},{b[2],1}}
	local phase=0
	local connection
	connection=RunService.PostSimulation:Connect(function(dt)
		if not visual.Parent or not humanoid.Parent then
			if connection then connection:Disconnect() end
			return
		end
		local moving=humanoid.MoveDirection.Magnitude>0.03
		if moving then phase+=dt*7.2 end
		local swing=moving and math.sin(phase)*math.rad(25) or 0
		for _,entry in ipairs(gait) do
			local d,sign=entry[1],entry[2]
			d.motor.Transform=CFrame.identity
			d.motor.C0=d.baseC0*CFrame.Angles(swing*sign,0,0)
		end
	end)
	local skinCount=0; for _,list in pairs(skinFor) do skinCount+=#list end
	return connection,"LEG GROUPS=4 | HOOFS="..#hooves.." | SKIN="..skinCount
end

local function clearCow(player)
	local state=states[player]
	if not state then return end
	if state.walkConnection then state.walkConnection:Disconnect() end
	if state.visual and state.visual.Parent then state.visual:Destroy() end
	if state.character and state.character.Parent then setCharacterVisible(state.character,true) end
	states[player]=nil
	remote:FireClient(player,"OFF","Vaca removida")
end

local function morphCow(player)
	local character=player.Character
	if not character then return end
	local hrp=character:FindFirstChild("HumanoidRootPart")
	local humanoid=character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then
		remote:FireClient(player,"ERROR","Character sem Humanoid/HRP")
		return
	end

	clearCow(player)
	local ok,container=pcall(function() return InsertService:LoadAsset(COW_ASSET_ID) end)
	if not ok then
		remote:FireClient(player,"ERROR","LoadAsset falhou: "..tostring(container))
		return
	end

	local visual=unwrapAsset(container)
	visual.Name="CowMorph_"..player.UserId
	visual.Parent=workspace
	local parts=getParts(visual)
	if #parts==0 then
		visual:Destroy()
		remote:FireClient(player,"ERROR","Asset da vaca nao possui BasePart")
		return
	end

	local visualRoot=chooseRoot(visual,parts)
	if not visualRoot then
		visual:Destroy()
		remote:FireClient(player,"ERROR","Nao achei raiz visual da vaca")
		return
	end

	local boundsSize
	if visual:IsA("Model") then
		local _,size=visual:GetBoundingBox()
		boundsSize=size
	else
		boundsSize=visualRoot.Size
	end
	print(("[CowMorph] original bounds %.2f x %.2f x %.2f studs | parts=%d | root=%s"):format(
		boundsSize.X,boundsSize.Y,boundsSize.Z,#parts,visualRoot.Name
	))

	-- Normalize this oversized asset to roughly one Roblox player's height.
	local TARGET_HEIGHT=6
	local scaleFactor=TARGET_HEIGHT/boundsSize.Y
	if visual:IsA("Model") then
		local originalModelScale=visual:GetScale()
		local targetModelScale=originalModelScale*scaleFactor
		local okScale,scaleErr=pcall(function() visual:ScaleTo(targetModelScale) end)
		if not okScale then
			warn("[CowMorph] ScaleTo failed: "..tostring(scaleErr))
			visual:Destroy()
			remote:FireClient(player,"ERROR","Nao consegui reduzir a vaca")
			return
		end
		parts=getParts(visual)
		visualRoot=chooseRoot(visual,parts)
		local _,scaledSize=visual:GetBoundingBox()
		boundsSize=scaledSize
		print(("[CowMorph] scale %.5f -> %.5f | scaled bounds %.2f x %.2f x %.2f"):format(
			originalModelScale,targetModelScale,boundsSize.X,boundsSize.Y,boundsSize.Z
		))
	end

	for _,part in ipairs(parts) do
		part.Anchored=false
		part.CanCollide=false
		part.CanTouch=false
		part.CanQuery=false
		part.Massless=true
	end

	-- First align the cow root with the player's root, then correct vertical placement
	-- from the cow's real bounding-box bottom instead of using a fixed offset.
	local currentPivot=visual:IsA("Model") and visual:GetPivot() or visualRoot.CFrame
	local rootOffset=currentPivot:ToObjectSpace(visualRoot.CFrame)
	local desiredPivot=hrp.CFrame*rootOffset:Inverse()
	if visual:IsA("Model") then visual:PivotTo(desiredPivot) else visualRoot.CFrame=hrp.CFrame end

	if visual:IsA("Model") then
		local boxCF,boxSize=visual:GetBoundingBox()
		local cowBottomY=boxCF.Position.Y-boxSize.Y/2
		-- Approximate the player's standing floor from HRP + Humanoid.HipHeight.
		local playerFloorY=hrp.Position.Y-(hrp.Size.Y/2+humanoid.HipHeight)
		local lift=playerFloorY-cowBottomY+0.08
		visual:PivotTo(visual:GetPivot()+Vector3.new(0,lift,0))
		print(("[CowMorph] floor align bottom=%.2f floor=%.2f lift=%.2f"):format(cowBottomY,playerFloorY,lift))
	end

	-- Preserve any original Motor6D/Weld rig. Only disconnected assemblies are tied
	-- to the chosen cow root, then that root follows the real player character.
	local connected={}
	for _,p in ipairs(visualRoot:GetConnectedParts(true)) do connected[p]=true end
	connected[visualRoot]=true
	for _,part in ipairs(parts) do
		if part~=visualRoot and not connected[part] then
			local weld=Instance.new("WeldConstraint")
			weld.Name="CowFallbackWeld"
			weld.Part0=visualRoot
			weld.Part1=part
			weld.Parent=visualRoot
		end
	end
	local follow=Instance.new("WeldConstraint")
	follow.Name="CowPlayerWeld"
	follow.Part0=hrp
	follow.Part1=visualRoot
	follow.Parent=visualRoot

	-- Disable scripts/humanoids shipped inside the cosmetic asset so they cannot
	-- fight the player's own controller.
	for _,obj in ipairs(visual:GetDescendants()) do
		if obj:IsA("Script") or obj:IsA("LocalScript") then obj.Disabled=true end
		if obj:IsA("Humanoid") then
			obj.PlatformStand=true
			obj.AutoRotate=false
		end
	end

	-- Hide only the original avatar. The cow lives in Workspace, so it remains visible.
	setCharacterVisible(character,false)
	hrp.Transparency=1
	for _,part in ipairs(parts) do
		part.Transparency=math.min(part.Transparency,0)
	end
	local walkConnection,walkMap=setupCowWalk(player,visual,humanoid,visualRoot)
	states[player]={character=character,visual=visual,walkConnection=walkConnection}
	local legMap=walkMap or "walk sem mapa"
	remote:FireClient(player,"ON",("BUILD %s | Vaca %.1fx%.1fx%.1f | %s"):format(COW_BUILD,boundsSize.X,boundsSize.Y,boundsSize.Z,tostring(legMap)))
end

remote.OnServerEvent:Connect(function(player,action,part)
	if action=="number" then
		local state=states[player]
		if not state or not state.visual then return end
		local number=tonumber(part)
		if not number then return end
		local enabled=state.numberEnabled or {}
		state.numberEnabled=enabled
		enabled[number]=not enabled[number]
		setNumberVisible(state.visual,number,enabled[number])
		remote:FireClient(player,"NUMBER",number,enabled[number])
		return
	end
	if action=="inspect" then
		local state=states[player]
		if not state or not state.visual or typeof(part)~="Instance" or not part:IsA("BasePart") or not part:IsDescendantOf(state.visual) then return end
		local motor
		for _,obj in ipairs(state.visual:GetDescendants()) do
			if obj:IsA("Motor6D") and obj.Part1==part then motor=obj break end
		end
		local root=chooseRoot(state.visual,getParts(state.visual))
		local lp=root and root.CFrame:PointToObjectSpace(part.Position) or Vector3.zero
		remote:FireClient(player,"INSPECT",part,part.Name,part.ClassName,
			("%.2f x %.2f x %.2f"):format(part.Size.X,part.Size.Y,part.Size.Z),
			("%.2f, %.2f, %.2f"):format(lp.X,lp.Y,lp.Z),
			motor and motor.Name or "sem Motor6D")
		return
	end
	if action~="toggle" then return end
	if states[player] then clearCow(player) else morphCow(player) end
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
	local state=states[player]
	if state and state.walkConnection then state.walkConnection:Disconnect() end
	states[player]=nil
end)

game:GetService("Players").PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		states[player]=nil
		remote:FireClient(player,"OFF","Respawn: forma normal")
	end)
end)

for _,player in ipairs(game:GetService("Players"):GetPlayers()) do
	player.CharacterAdded:Connect(function()
		states[player]=nil
		remote:FireClient(player,"OFF","Respawn: forma normal")
	end)
end

print("[CowMorph] Ready | asset "..COW_ASSET_ID.." | "..COW_BUILD)
