local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local island = Workspace:WaitForChild("StarterIsland")

local MAX_DISTANCE = 14

local highlight = Instance.new("Highlight")
highlight.Name = "BlockTargetHighlight"
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlight.FillTransparency = 1
highlight.OutlineColor = Color3.new(1, 1, 1)
highlight.OutlineTransparency = 0.35
highlight.Enabled = false
highlight.Parent = Workspace

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function isIslandBlock(instance)
	return instance
		and instance:IsA("BasePart")
		and instance.Parent == island
		and string.match(instance.Name, "^Block_%d+$") ~= nil
end

RunService.RenderStepped:Connect(function()
	camera = Workspace.CurrentCamera
	if not camera then
		highlight.Enabled = false
		highlight.Adornee = nil
		return
	end

	local character = player.Character
	raycastParams.FilterDescendantsInstances = character and { character } or {}

	local viewport = camera.ViewportSize
	local ray = camera:ViewportPointToRay(viewport.X * 0.5, viewport.Y * 0.5)
	local result = Workspace:Raycast(ray.Origin, ray.Direction * MAX_DISTANCE, raycastParams)

	if result and isIslandBlock(result.Instance) then
		highlight.Adornee = result.Instance
		highlight.Enabled = true
	else
		highlight.Enabled = false
		highlight.Adornee = nil
	end
end)
