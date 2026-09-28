local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Workspace=game:GetService("Workspace")
local player=Players.LocalPlayer
if not player:GetAttribute("WorldId") then return end

local Catalog=require(ReplicatedStorage:WaitForChild("Building"):WaitForChild("PieceCatalog"))
local remotes=ReplicatedStorage:WaitForChild("BuildingRemotes")
local place=remotes:WaitForChild("PlacePiece")
local resolve=remotes:WaitForChild("ResolvePlacement")
local hotbar=player:WaitForChild("PlayerGui"):WaitForChild("ItemHotbar")
local selected=nil
local preview=nil
local previewValid=false
local lastResolve=0
local pending=false
local VALID=Color3.fromRGB(80,255,125)
local INVALID=Color3.fromRGB(255,75,75)

local actionGui=Instance.new("ScreenGui");actionGui.Name="BuildActions";actionGui.ResetOnSpawn=false;actionGui.DisplayOrder=51;actionGui.Parent=player.PlayerGui
local placeButton=Instance.new("TextButton");placeButton.AnchorPoint=Vector2.new(1,1);placeButton.Position=UDim2.new(1,-18,1,-72);placeButton.Size=UDim2.fromOffset(58,58);placeButton.Text="✓";placeButton.TextScaled=true;placeButton.Font=Enum.Font.GothamBold;placeButton.TextColor3=Color3.fromRGB(5,18,9);placeButton.BackgroundColor3=VALID;placeButton.Visible=false;placeButton.Parent=actionGui
Instance.new("UICorner",placeButton).CornerRadius=UDim.new(1,0)

local function target()
	local camera=Workspace.CurrentCamera;if not camera then return nil end
	local ray=camera:ViewportPointToRay(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
	local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={player.Character,preview}
	return Workspace:Raycast(ray.Origin,ray.Direction*90,params)
end
local function ensurePreview(def)
	if not preview then preview=Instance.new("Part");preview.Name="BuildPreview";preview.Anchored=true;preview.CanCollide=false;preview.CanTouch=false;preview.CanQuery=false;preview.CastShadow=false;preview.Material=Enum.Material.Neon;preview.Parent=Workspace end
	preview.Size=def.size;preview.Transparency=.55
end
local function updatePreview()
	if not selected then if preview then preview.Transparency=1 end;placeButton.Visible=false;return end
	local hit=target();if not hit then previewValid=false;if preview then preview.Transparency=1 end;placeButton.Visible=false;return end
	local def=Catalog[selected];ensurePreview(def)
	if os.clock()-lastResolve<.08 or pending then return end
	lastResolve=os.clock();pending=true
	task.spawn(function()
		local ok,result=pcall(function() return resolve:InvokeServer(selected,hit.Position) end)
		pending=false
		if selected and ok and type(result)=="table" and result.ok and typeof(result.position)=="Vector3" then
			preview.CFrame=CFrame.new(result.position)*CFrame.Angles(0,math.rad(result.rotation or 0),0);preview.Color=VALID;preview.Transparency=.55;previewValid=true;placeButton.Visible=true
		else
			local p=hit.Position;preview.CFrame=CFrame.new(p.X,p.Y+def.offsetY,p.Z);preview.Color=INVALID;preview.Transparency=.65;previewValid=false;placeButton.Visible=false
		end
	end)
end

hotbar:GetAttributeChangedSignal("BuildPiece"):Connect(function()
	local value=hotbar:GetAttribute("BuildPiece")
	selected=(type(value)=="string" and Catalog[value]) and value or nil
	previewValid=false
end)
hotbar:GetAttributeChangedSignal("RotateRequested"):Connect(function()
	-- Rotation is socket-defined; reserved for future free/variant pieces.
end)

placeButton.Activated:Connect(function()
	if not selected or not previewValid then return end
	local hit=target();if not hit then return end
	previewValid=false;placeButton.Visible=false
	local ok,result=pcall(function() return place:InvokeServer(selected,hit.Position) end)
	if not ok or not result or not result.ok then return end
end)
RunService.RenderStepped:Connect(updatePreview)
