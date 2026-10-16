local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
if player.UserId ~= 9538436641 then return end

local request = ReplicatedStorage:WaitForChild("LobbyBuilderRemotes"):WaitForChild("Request")
local catalogFolder = ReplicatedStorage:WaitForChild("HalloweenCatalog")

local selected, preview, previewBasePosition
local rotation = 0
local catalogLoaded = false
local placementDistance = 6
local heightOffset = 0
local joinLast = false
local lastPlacedTop
local lastPlacedCenter

local function clearPreview()
	if preview then preview:Destroy(); preview = nil end
	previewBasePosition = nil
end

local function makeGhost(obj)
	for _, d in ipairs(obj:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true; d.CanCollide = false; d.CanTouch = false; d.CanQuery = false
			d.Transparency = math.max(d.Transparency, 0.55)
		end
	end
	if obj:IsA("BasePart") then
		obj.Anchored = true; obj.CanCollide = false; obj.CanTouch = false; obj.CanQuery = false
		obj.Transparency = math.max(obj.Transparency, 0.55)
	end
end

local function pivotTo(obj, cf)
	if obj:IsA("Model") then
		obj:PivotTo(cf)
	elseif obj:IsA("BasePart") then
		obj.CFrame = cf
	else
		local part = obj:FindFirstChildWhichIsA("BasePart", true)
		if part then
			local delta = cf * part.CFrame:Inverse()
			for _, d in ipairs(obj:GetDescendants()) do
				if d:IsA("BasePart") then d.CFrame = delta * d.CFrame end
			end
		end
	end
end

local function bounds(obj)
	if obj:IsA("Model") then
		local cf, size = obj:GetBoundingBox()
		return cf, size
	end
	if obj:IsA("BasePart") then return obj.CFrame, obj.Size end
	local parts = {}
	for _, d in ipairs(obj:GetDescendants()) do if d:IsA("BasePart") then table.insert(parts, d) end end
	if #parts == 0 then return CFrame.new(), Vector3.zero end
	local minV = Vector3.new(math.huge, math.huge, math.huge)
	local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, p in ipairs(parts) do
		local half = p.Size * 0.5
		minV = Vector3.new(math.min(minV.X,p.Position.X-half.X),math.min(minV.Y,p.Position.Y-half.Y),math.min(minV.Z,p.Position.Z-half.Z))
		maxV = Vector3.new(math.max(maxV.X,p.Position.X+half.X),math.max(maxV.Y,p.Position.Y+half.Y),math.max(maxV.Z,p.Position.Z+half.Z))
	end
	local center=(minV+maxV)*0.5
	return CFrame.new(center), maxV-minV
end

local function placeBaseAt(obj, basePos, yaw)
	pivotTo(obj, CFrame.new(basePos) * CFrame.Angles(0, math.rad(yaw), 0))
	local boxCF, boxSize = bounds(obj)
	local bottomY = boxCF.Position.Y - boxSize.Y * 0.5
	local dy = basePos.Y - bottomY
	if math.abs(dy) > 0.001 then
		local current
		if obj:IsA("Model") then current=obj:GetPivot()
		elseif obj:IsA("BasePart") then current=obj.CFrame
		else
			local p=obj:FindFirstChildWhichIsA("BasePart",true); current=p and p.CFrame
		end
		if current then pivotTo(obj, current + Vector3.new(0,dy,0)) end
	end
	return bounds(obj)
end

local gui=Instance.new("ScreenGui")
gui.Name="LobbyCreativeHUD"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true; gui.Parent=player:WaitForChild("PlayerGui")
local open=Instance.new("TextButton")
open.Size=UDim2.fromOffset(92,34); open.Position=UDim2.new(0,10,1,-44); open.Text="CONSTRUIR"; open.TextScaled=true; open.Parent=gui
local panel=Instance.new("Frame")
panel.Size=UDim2.new(1,-20,0,184); panel.Position=UDim2.new(0,10,1,-194); panel.Visible=false; panel.Parent=gui
local scroll=Instance.new("ScrollingFrame")
scroll.Size=UDim2.new(1,-12,0,58); scroll.Position=UDim2.fromOffset(6,5); scroll.AutomaticCanvasSize=Enum.AutomaticSize.X
scroll.CanvasSize=UDim2.new(); scroll.ScrollingDirection=Enum.ScrollingDirection.X; scroll.ScrollBarThickness=3; scroll.Parent=panel
local layout=Instance.new("UIListLayout"); layout.FillDirection=Enum.FillDirection.Horizontal; layout.Padding=UDim.new(0,4); layout.Parent=scroll
local controls=Instance.new("Frame"); controls.BackgroundTransparency=1; controls.Size=UDim2.new(1,-12,0,40); controls.Position=UDim2.fromOffset(6,67); controls.Parent=panel
local status=Instance.new("TextLabel"); status.Size=UDim2.new(.30,0,1,0); status.BackgroundTransparency=1; status.Text="Selecione um item"; status.TextScaled=true; status.Parent=controls

local function button(parent,text,x,w,fn)
	local b=Instance.new("TextButton"); b.Text=text; b.TextScaled=true; b.Size=UDim2.new(w,-3,1,0); b.Position=UDim2.new(x,0,0,0); b.Parent=parent
	b.Activated:Connect(fn); return b
end

local adjust=Instance.new("Frame"); adjust.BackgroundTransparency=1; adjust.Size=UDim2.new(1,-12,0,30); adjust.Position=UDim2.fromOffset(6,108); adjust.Parent=panel
local joinRow=Instance.new("Frame"); joinRow.BackgroundTransparency=1; joinRow.Size=UDim2.new(1,-12,0,30); joinRow.Position=UDim2.fromOffset(6,142); joinRow.Parent=panel

button(adjust,"PERTO -",0,.25,function() placementDistance=math.max(0.5,placementDistance-1) end)
button(adjust,"LONGE +",.25,.25,function() placementDistance=math.min(30,placementDistance+1) end)
button(adjust,"ALTURA -",.50,.25,function() heightOffset=math.max(-20,heightOffset-.5) end)
button(adjust,"ALTURA +",.75,.25,function() heightOffset=math.min(30,heightOffset+.5) end)

local joinButton
joinButton=button(joinRow,"JUNTAR ULTIMA: OFF",0,.55,function()
	joinLast=not joinLast
	joinButton.Text=joinLast and "JUNTAR ULTIMA: ON" or "JUNTAR ULTIMA: OFF"
	if joinLast and lastPlacedTop then placementDistance=0; heightOffset=0 end
end)
button(joinRow,"RESET POSICAO",.55,.45,function() placementDistance=6; heightOffset=0; joinLast=false; joinButton.Text="JUNTAR ULTIMA: OFF" end)

local function selectItem(name)
	selected=name; clearPreview(); heightOffset=0
	placementDistance=(joinLast and lastPlacedTop) and 0 or 6
	local template=catalogFolder:FindFirstChild(name)
	if not template then status.Text="Item nao replicou"; return end
	preview=template:Clone(); preview.Name="CreativePreview"; makeGhost(preview); preview.Parent=workspace
	status.Text=name:gsub("^%d+_","")
end

local function loadCatalog()
	if catalogLoaded then return end
	status.Text="Carregando..."
	local result=request:InvokeServer("catalog")
	if not result or not result.ok then status.Text=result and (result.status or result.error) or "Falha no catalogo"; return end
	for _,name in ipairs(result.items) do
		local b=Instance.new("TextButton"); b.Size=UDim2.fromOffset(96,54); b.Text=name:gsub("^%d+_",""); b.TextWrapped=true; b.TextScaled=true; b.Parent=scroll
		b.Activated:Connect(function() selectItem(name) end)
	end
	catalogLoaded=true; status.Text=tostring(#result.items).." itens"
end

button(controls,"COLOCAR",.30,.20,function()
	if not selected or not previewBasePosition or not preview then status.Text="Selecione um item"; return end
	local boxCF,boxSize=bounds(preview)
	local result=request:InvokeServer("place",{name=selected,basePosition=previewBasePosition,rotation=rotation})
	if result.ok then
		lastPlacedCenter=boxCF.Position
		lastPlacedTop=Vector3.new(boxCF.Position.X,boxCF.Position.Y+boxSize.Y*.5,boxCF.Position.Z)
		status.Text="Colocado"
	else status.Text=result.error or "Erro" end
end)
button(controls,"GIRAR",.50,.12,function() rotation=(rotation+45)%360; status.Text=tostring(rotation).." graus" end)
button(controls,"APAGAR",.62,.18,function()
	local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart"); if not root then return end
	local r=request:InvokeServer("deleteNearest",{position=root.Position}); status.Text=r.ok and "Removido" or (r.error or "Erro")
end)
button(controls,"X",.80,.20,function() clearPreview(); panel.Visible=false end)

open.Activated:Connect(function() panel.Visible=not panel.Visible; if panel.Visible then loadCatalog() else clearPreview() end end)

local function updatePreview()
	if not panel.Visible or not selected or not preview then return end
	local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local camera=workspace.CurrentCamera
	if not root or not camera then return end
	local look=camera.CFrame.LookVector
	local flat=Vector3.new(look.X,0,look.Z)
	if flat.Magnitude<.05 then flat=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z) end
	flat=flat.Unit

	local base
	if joinLast and lastPlacedTop then
		base=lastPlacedTop + flat*placementDistance + Vector3.new(0,heightOffset,0)
	else
		-- Root is about 3 studs above the floor; use the player's floor as Y=0 reference.
		local floorY=root.Position.Y-3
		base=Vector3.new(root.Position.X, floorY+heightOffset, root.Position.Z) + flat*placementDistance
	end
	previewBasePosition=base
	placeBaseAt(preview,base,rotation)
end
RunService.RenderStepped:Connect(updatePreview)
