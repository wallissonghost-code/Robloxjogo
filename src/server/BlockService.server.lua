local Workspace = game:GetService("Workspace")

local island = Workspace:WaitForChild("StarterIsland")

local function setupBlock(block)
	if not block:IsA("BasePart") or not string.match(block.Name, "^Block_%d+$") then
		return
	end

	local oldPrompt = block:FindFirstChild("BreakPrompt")
	if oldPrompt then
		oldPrompt:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BreakPrompt"
	prompt.ActionText = "Quebrar"
	prompt.ObjectText = block.Name
	prompt.HoldDuration = 0.35
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = block

	local broken = false
	prompt.Triggered:Connect(function()
		if broken or not block.Parent then
			return
		end

		broken = true
		prompt.Enabled = false
		block:Destroy()
	end)
end

for _, block in island:GetChildren() do
	setupBlock(block)
end

island.ChildAdded:Connect(setupBlock)
