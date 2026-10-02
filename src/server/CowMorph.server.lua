local InsertService=game:GetService("InsertService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local COW_ASSET_ID=80696062872929
local remote=ReplicatedStorage:FindFirstChild("CowMorphToggle") or Instance.new("RemoteEvent")
remote.Name="CowMorphToggle"
remote.Parent=ReplicatedStorage

local states={}

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

	for _,part in ipairs(parts) do
		part.Anchored=false
		part.CanCollide=false
		part.CanTouch=false
		part.CanQuery=false
		part.Massless=true
	end

	-- Move the whole cow to the player's physical root before connecting it.
	local currentPivot=visual:IsA("Model") and visual:GetPivot() or visualRoot.CFrame
	local rootOffset=currentPivot:ToObjectSpace(visualRoot.CFrame)
	local desiredRoot=hrp.CFrame*CFrame.new(0,-1.6,0)
	local desiredPivot=desiredRoot*rootOffset:Inverse()
	if visual:IsA("Model") then visual:PivotTo(desiredPivot) else visualRoot.CFrame=desiredRoot end

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
	remote:FireClient(player,"ON",("Vaca ativa | parts=%d | root=%s"):format(#parts,visualRoot.Name))
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
