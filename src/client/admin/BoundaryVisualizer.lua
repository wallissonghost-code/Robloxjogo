local BoundaryVisualizer = {}

function BoundaryVisualizer.create(workspace)
	local visuals = Instance.new("Folder")
	visuals.Name = "AdminBoundaryVisuals"
	visuals.Parent = workspace

	local boundary = workspace:WaitForChild("WorldBoundary", 30)
	if not boundary then return visuals end

	for _, source in ipairs(boundary:GetChildren()) do
		if source:IsA("BasePart") then
			local visual = Instance.new("Part")
			visual.Name = source.Name .. "Visual"
			visual.Anchored = true
			visual.CanCollide = false
			visual.CanTouch = false
			visual.CanQuery = false
			visual.CastShadow = false
			visual.Material = Enum.Material.Neon
			visual.Color = Color3.fromRGB(255, 72, 72)
			visual.Transparency = .82
			visual.Size = source.Size
			visual.CFrame = source.CFrame
			visual.Parent = visuals
		end
	end
	return visuals
end

return BoundaryVisualizer
