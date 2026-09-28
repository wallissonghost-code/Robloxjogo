local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
if not player:GetAttribute("WorldId") then return end

local Catalog = require(ReplicatedStorage:WaitForChild("Building"):WaitForChild("PieceCatalog"))
local place = ReplicatedStorage:WaitForChild("BuildingRemotes"):WaitForChild("PlacePiece")

local gui = Instance.new("ScreenGui")
gui.Name = "BuildingUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local open = Instance.new("TextButton")
open.AnchorPoint = Vector2.new(1,1)
open.Position = UDim2.new(1,-18,1,-24)
open.Size = UDim2.fromOffset(112,46)
open.Text = "CONSTRUIR"
open.Font = Enum.Font.GothamBold
open.TextSize = 13
open.BackgroundColor3 = Color3.fromRGB(20,27,22)
open.TextColor3 = Color3.fromRGB(105,255,145)
open.Parent = gui
Instance.new("UICorner",open).CornerRadius=UDim.new(0,10)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(1,1)
panel.Position = UDim2.new(1,-18,1,-80)
panel.Size = UDim2.fromOffset(250,220)
panel.BackgroundColor3 = Color3.fromRGB(14,19,16)
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,12)

local selected, rotation, preview = "Foundation", 0, nil
local previewValid = false
local VALID_COLOR = Color3.fromRGB(80,255,125)
local INVALID_COLOR = Color3.fromRGB(255,75,75)
local status = Instance.new("TextLabel")
status.Position=UDim2.fromOffset(10,184);status.Size=UDim2.new(1,-20,0,26);status.BackgroundTransparency=1
status.Text="";status.TextColor3=Color3.fromRGB(190,200,193);status.Font=Enum.Font.Gotham;status.TextSize=11;status.Parent=panel

local names={"Foundation","Wall","Door","Roof"}
for i,key in ipairs(names) do
	local b=Instance.new("TextButton")
	b.Position=UDim2.fromOffset(10+((i-1)%2)*116,10+math.floor((i-1)/2)*44)
	b.Size=UDim2.fromOffset(108,36);b.Text=Catalog[key].label;b.Font=Enum.Font.GothamBold;b.TextSize=11
	b.BackgroundColor3=Color3.fromRGB(28,37,31);b.TextColor3=Color3.fromRGB(235,242,237);b.Parent=panel
	Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
	b.Activated:Connect(function() selected=key end)
end

local rotate=Instance.new("TextButton")
rotate.Position=UDim2.fromOffset(10,102);rotate.Size=UDim2.fromOffset(108,36);rotate.Text="GIRAR 90°"
rotate.Font=Enum.Font.GothamBold;rotate.TextSize=11;rotate.BackgroundColor3=Color3.fromRGB(28,37,31);rotate.TextColor3=Color3.fromRGB(235,242,237);rotate.Parent=panel
Instance.new("UICorner",rotate).CornerRadius=UDim.new(0,8)
rotate.Activated:Connect(function() rotation=(rotation+90)%360 end)

local confirm=Instance.new("TextButton")
confirm.Position=UDim2.fromOffset(126,102);confirm.Size=UDim2.fromOffset(108,36);confirm.Text="COLOCAR"
confirm.Font=Enum.Font.GothamBold;confirm.TextSize=11;confirm.BackgroundColor3=Color3.fromRGB(88,255,135);confirm.TextColor3=Color3.fromRGB(5,18,9);confirm.Parent=panel
Instance.new("UICorner",confirm).CornerRadius=UDim.new(0,8)

local function target()
	local camera=Workspace.CurrentCamera
	if not camera then return nil end
	local ray=camera:ViewportPointToRay(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
	local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={player.Character,preview}
	return Workspace:Raycast(ray.Origin,ray.Direction*80,params)
end

local function localPlacementValid(hit, def, cf)
	if not hit or hit.Material == Enum.Material.Water then return false end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - cf.Position).Magnitude > 45 then return false end

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, preview }
	local box = def.size - Vector3.new(.35,.15,.35)
	for _, part in ipairs(Workspace:GetPartBoundsInBox(cf, box, params)) do
		if part.CanCollide and part.Name ~= "SpawnLocation" then
			return false
		end
	end
	return true
end

local function refreshPreview()
	local hit=target()
	if not hit then
		previewValid=false
		if preview then preview.Transparency=1 end
		return
	end
	local def=Catalog[selected]
	if not preview then
		preview=Instance.new("Part")
		preview.Name="BuildPreview"
		preview.Anchored=true
		preview.CanCollide=false
		preview.CanTouch=false
		preview.CanQuery=false
		preview.CastShadow=false
		preview.Material=Enum.Material.Neon
		preview.Parent=Workspace
	end
	preview.Size=def.size
	preview.Transparency=.55
	local x=math.floor(hit.Position.X/2+.5)*2
	local z=math.floor(hit.Position.Z/2+.5)*2
	local cf=CFrame.new(x,hit.Position.Y+def.offsetY,z)*CFrame.Angles(0,math.rad(rotation),0)
	preview.CFrame=cf
	previewValid=localPlacementValid(hit,def,cf)
	preview.Color=previewValid and VALID_COLOR or INVALID_COLOR
end

RunService.RenderStepped:Connect(function() if panel.Visible then refreshPreview() elseif preview then preview.Transparency=1 end end)
open.Activated:Connect(function() panel.Visible=not panel.Visible;open.Text=panel.Visible and "FECHAR" or "CONSTRUIR" end)
confirm.Activated:Connect(function()
	local hit=target();if not hit then status.Text="Sem superfície válida.";return end
	refreshPreview()
	if not previewValid then status.Text="Não é possível construir aqui.";return end
	status.Text="Colocando..."
	local ok,result=pcall(function() return place:InvokeServer(selected,hit.Position,rotation) end)
	status.Text=ok and result and (result.ok and "Construção salva." or result.message) or "Falha ao construir."
end)
