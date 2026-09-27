local Workspace = game:GetService("Workspace")

local island = Workspace:WaitForChild("StarterIsland")
local spawn = Workspace:WaitForChild("SpawnLocation")

local BLOCK_SIZE = Vector3.new(3.8, 3.8, 3.8)
local CELL_SPACING = 3.84
local GRID = {
	Vector3.new(-CELL_SPACING, 0, -CELL_SPACING),
	Vector3.new(0, 0, -CELL_SPACING),
	Vector3.new(CELL_SPACING, 0, -CELL_SPACING),
	Vector3.new(-CELL_SPACING, 0, 0),
	Vector3.new(0, 0, 0),
	Vector3.new(CELL_SPACING, 0, 0),
	Vector3.new(-CELL_SPACING, 0, CELL_SPACING),
	Vector3.new(0, 0, CELL_SPACING),
	Vector3.new(CELL_SPACING, 0, CELL_SPACING),
}

local function setupBlock(block, index)
	if not block:IsA("BasePart") then
		return
	end

	block.Anchored = true
	block.Size = BLOCK_SIZE
	block.CFrame = CFrame.new(GRID[index])

	local oldPrompt = block:FindFirstChild("BreakPrompt")
	if oldPrompt then
		oldPrompt:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BreakPrompt"
	prompt.ActionText = "Quebrar"
	prompt.ObjectText = "Bloco " .. index
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

for index = 1, 9 do
	local block = island:WaitForChild("Block_" .. index)
	setupBlock(block, index)
end

spawn.CFrame = CFrame.new(0, BLOCK_SIZE.Y / 2 + 0.5, 0)
