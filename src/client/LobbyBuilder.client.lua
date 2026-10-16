local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if player.UserId ~= 9538436641 then return end

local request = ReplicatedStorage:WaitForChild("LobbyBuilderRemotes"):WaitForChild("Request")
local catalogFolder = ReplicatedStorage:WaitForChild("HalloweenCatalog")

local selected
local rotation = 0
local preview
local previewPosition
local catalogLoaded = false

local function clearPreview()
	if preview then
		preview:Destroy()
		preview = nil
	end
	previewPosition = nil
end

local function makeGhost(obj)
	for _, d in ipairs(obj:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Transparency = math.max(d.Transparency, 0.55)
		end
	end
	if obj:IsA("BasePart") then
		obj.Anchored = true
		obj.CanCollide = false
		obj.CanTouch = false
		obj.CanQuery = false
		obj.Transparency = math.max(obj.Transparency, 0.55)
	end
end

local function moveObject(obj, cf)
	if obj:IsA("Model") then
		obj:PivotTo(cf)
	elseif obj:IsA("BasePart") then
		obj.CFrame = cf
	else
		local part = obj:FindFirstChildWhichIsA("BasePart", true)
		if part then part.CFrame = cf end
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = "LobbyCreativeHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local open = Instance.new("TextButton")
open.Size = UDim2.fromOffset(92, 34)
open.Position = UDim2.new(0, 10, 1, -44)
open.Text = "CONSTRUIR"
open.TextScaled = true
open.Parent = gui

local panel = Instance.new("Frame")
panel.Size = UDim2.new(1, -20, 0, 112)
panel.Position = UDim2.new(0, 10, 1, -122)
panel.Visible = false
panel.Parent = gui

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -12, 0, 58)
scroll.Position = UDim2.fromOffset(6, 5)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.X
scroll.CanvasSize = UDim2.new()
scroll.ScrollingDirection = Enum.ScrollingDirection.X
scroll.ScrollBarThickness = 3
scroll.Parent = panel

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.Padding = UDim.new(0, 4)
layout.Parent = scroll

local controls = Instance.new("Frame")
controls.BackgroundTransparency = 1
controls.Size = UDim2.new(1, -12, 0, 40)
controls.Position = UDim2.fromOffset(6, 67)
controls.Parent = panel

local status = Instance.new("TextLabel")
status.Size = UDim2.new(0.34, 0, 1, 0)
status.BackgroundTransparency = 1
status.Text = "Selecione um item"
status.TextScaled = true
status.TextTruncate = Enum.TextTruncate.AtEnd
status.Parent = controls

local function addButton(text, x, width, callback)
	local b = Instance.new("TextButton")
	b.Text = text
	b.TextScaled = true
	b.Size = UDim2.new(width, -3, 1, 0)
	b.Position = UDim2.new(x, 0, 0, 0)
	b.Parent = controls
	b.Activated:Connect(callback)
	return b
end

local function selectItem(name)
	selected = name
	clearPreview()
	local template = catalogFolder:FindFirstChild(name)
	if not template then
		status.Text = "Item nao replicou"
		return
	end
	preview = template:Clone()
	preview.Name = "CreativePreview"
	makeGhost(preview)
	preview.Parent = workspace
	status.Text = name:gsub("^%d+_", "")
end

local function loadCatalog()
	if catalogLoaded then return end
	status.Text = "Carregando..."
	local result = request:InvokeServer("catalog")
	if not result or not result.ok then
		status.Text = result and (result.status or result.error) or "Falha no catalogo"
		return
	end

	for _, name in ipairs(result.items) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(96, 54)
		b.Text = name:gsub("^%d+_", "")
		b.TextWrapped = true
		b.TextScaled = true
		b.Parent = scroll
		b.Activated:Connect(function()
			selectItem(name)
		end)
	end

	catalogLoaded = true
	status.Text = tostring(#result.items) .. " itens"
end

addButton("COLOCAR", 0.35, 0.20, function()
	if not selected or not previewPosition then
		status.Text = "Toque no mapa primeiro"
		return
	end
	local result = request:InvokeServer("place", {
		name = selected,
		position = previewPosition,
		rotation = rotation
	})
	status.Text = result.ok and "Colocado" or (result.error or "Erro")
end)

addButton("GIRAR", 0.55, 0.10, function()
	rotation = (rotation + 45) % 360
	if preview and previewPosition then
		moveObject(preview, CFrame.new(previewPosition) * CFrame.Angles(0, math.rad(rotation), 0))
	end
	status.Text = tostring(rotation) .. " graus"
end)

addButton("APAGAR", 0.65, 0.18, function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local result = request:InvokeServer("deleteNearest", {position = root.Position})
	status.Text = result.ok and "Removido" or (result.error or "Erro")
end)

addButton("X", 0.83, 0.17, function()
	clearPreview()
	panel.Visible = false
end)

open.Activated:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		loadCatalog()
	else
		clearPreview()
	end
end)

local function pointPreview(screenPosition)
	if not panel.Visible or not selected or not preview then return end
	local camera = workspace.CurrentCamera
	if not camera then return end

	local ray = camera:ViewportPointToRay(screenPosition.X, screenPosition.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignored = {preview}
	if player.Character then table.insert(ignored, player.Character) end
	params.FilterDescendantsInstances = ignored

	local hit = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
	if hit then
		previewPosition = hit.Position
		moveObject(preview, CFrame.new(previewPosition) * CFrame.Angles(0, math.rad(rotation), 0))
		status.Text = "Preview pronto"
	end
end

UserInputService.TouchTap:Connect(function(points, processed)
	if not processed and points[1] then
		pointPreview(points[1])
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 then
		pointPreview(input.Position)
	end
end)
