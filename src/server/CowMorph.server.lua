local InsertService=game:GetService("InsertService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local COW_ASSET_ID=80696062872929
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

local function clearCow(player)
	local state=states[player]
	if not state then return end
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
	states[player]={character=character,visual=visual}
	remote:FireClient(player,"ON",("Vaca %.1fx%.1fx%.1f studs | escala %.1f%% | parts=%d"):format(boundsSize.X,boundsSize.Y,boundsSize.Z,scaleFactor*100,#parts))
	remote:FireClient(player,"RIG",cowRigReport(visual))
end

remote.OnServerEvent:Connect(function(player,action)
	if action~="toggle" then return end
	if states[player] then clearCow(player) else morphCow(player) end
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
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

print("[CowMorph] Ready | asset "..COW_ASSET_ID)
