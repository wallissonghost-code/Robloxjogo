local InsertService=game:GetService("InsertService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")

local COW_ASSET_ID=80696062872929
local COW_BUILD="2026-10-02-cow-number-map"
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
		part:SetAttribute("CowMapNumber",i)
		local tag=Instance.new("BillboardGui")
		tag.Name="CowNumberTag"
		tag.Size=UDim2.fromOffset(34,26)
		tag.StudsOffset=Vector3.new(0,math.max(.2,part.Size.Y*.25),0)
		tag.AlwaysOnTop=true
		tag.MaxDistance=28
		tag.Parent=part
		local label=Instance.new("TextLabel")
		label.Size=UDim2.fromScale(1,1)
		label.BackgroundColor3=Color3.fromRGB(0,0,0)
		label.BackgroundTransparency=.15
		label.TextColor3=Color3.new(1,1,1)
		label.TextStrokeTransparency=0
		label.Font=Enum.Font.GothamBold
		label.TextScaled=true
		label.Text=tostring(i)
		label.Parent=tag
		Instance.new("UICorner",label).CornerRadius=UDim.new(0,6)
	end
	return #filtered
end

local function findMotorForPart(visual,partName)
	for _,obj in ipairs(visual:GetDescendants()) do
		if obj:IsA("Motor6D") and obj.Part1 and obj.Part1.Name==partName then
			return obj
		end
	end
end

local function setupCowWalk(player,visual,humanoid,visualRoot)
	local candidates={}
	for _,obj in ipairs(visual:GetDescendants()) do
		if obj:IsA("Motor6D") and obj.Part0==visualRoot and obj.Part1 then
			local part=obj.Part1
			local localPos=visualRoot.CFrame:PointToObjectSpace(part.Position)
			local longest=math.max(part.Size.X,part.Size.Y,part.Size.Z)
			local shortest=math.min(part.Size.X,part.Size.Y,part.Size.Z)
			if longest>=1.8 and shortest>=0.45 and localPos.Y<0 then
				table.insert(candidates,{oldMotor=obj,part=part,pos=localPos,score=longest})
			end
		end
	end
	table.sort(candidates,function(a,b) return a.score>b.score end)
	while #candidates>4 do table.remove(candidates) end
	if #candidates<4 then return nil,"legs="..#candidates end

	table.sort(candidates,function(a,b) return a.pos.Z<b.pos.Z end)
	local pairA={candidates[1],candidates[2]}
	local pairB={candidates[3],candidates[4]}
	table.sort(pairA,function(a,b) return a.pos.X<b.pos.X end)
	table.sort(pairB,function(a,b) return a.pos.X<b.pos.X end)
	local legs={FL=pairA[1],FR=pairA[2],BL=pairB[1],BR=pairB[2]}

	-- Replace only the four imported leg motors with joints we fully control.
	for key,data in pairs(legs) do
		local partWorld=data.part.CFrame
		data.oldMotor:Destroy()
		local motor=Instance.new("Motor6D")
		motor.Name="CowLeg_"..key
		motor.Part0=visualRoot
		motor.Part1=data.part
		motor.C0=visualRoot.CFrame:ToObjectSpace(partWorld)
		motor.C1=CFrame.new()
		motor.Parent=visualRoot
		data.motor=motor
		data.baseC0=motor.C0
	end

	local phase=0
	local connection
	connection=RunService.Heartbeat:Connect(function(dt)
		if not visual.Parent or not humanoid.Parent then
			if connection then connection:Disconnect() end
			return
		end
		local moving=humanoid.MoveDirection.Magnitude>0.05
		if moving then phase+=dt*8 end
		local swing=moving and math.sin(phase)*math.rad(28) or 0
		local angles={FL=swing,BR=swing,FR=-swing,BL=-swing}
		for key,data in pairs(legs) do
			local target=data.baseC0*CFrame.Angles(angles[key],0,0)
			data.motor.C0=data.motor.C0:Lerp(target,math.min(dt*14,1))
		end
	end)

	local names={}
	for key,data in pairs(legs) do table.insert(names,key.."="..data.part.Name) end
	table.sort(names)
	return connection,table.concat(names,",")
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
	local mapCount=applyNumberMap(visual)
	local walkConnection=nil
	local legMap="MAPA NUMERADO 1-"..mapCount
	states[player]={character=character,visual=visual,walkConnection=walkConnection}
	remote:FireClient(player,"ON",("BUILD %s | Vaca %.1fx%.1fx%.1f | %s"):format(COW_BUILD,boundsSize.X,boundsSize.Y,boundsSize.Z,tostring(legMap)))
end

remote.OnServerEvent:Connect(function(player,action,part)
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
