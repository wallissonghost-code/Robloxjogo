local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local island = Workspace:WaitForChild("StarterIsland")
local spawn = Workspace:WaitForChild("SpawnLocation")
local breakBlock = ReplicatedStorage:WaitForChild("BreakBlock")

local BLOCK_SIZE = Vector3.new(3.8, 3.8, 3.8)
local CELL_SPACING = 3.84
local MAX_BREAK_DISTANCE = 14
local GRID = {
	Vector3.new(-2 * CELL_SPACING, 0, -2 * CELL_SPACING),
	Vector3.new(-1 * CELL_SPACING, 0, -2 * CELL_SPACING),
	Vector3.new(0 * CELL_SPACING, 0, -2 * CELL_SPACING),
	Vector3.new(1 * CELL_SPACING, 0, -2 * CELL_SPACING),
	Vector3.new(2 * CELL_SPACING, 0, -2 * CELL_SPACING),
	Vector3.new(-2 * CELL_SPACING, 0, -1 * CELL_SPACING),
	Vector3.new(-1 * CELL_SPACING, 0, -1 * CELL_SPACING),
	Vector3.new(0 * CELL_SPACING, 0, -1 * CELL_SPACING),
	Vector3.new(1 * CELL_SPACING, 0, -1 * CELL_SPACING),
	Vector3.new(2 * CELL_SPACING, 0, -1 * CELL_SPACING),
	Vector3.new(-2 * CELL_SPACING, 0, 0 * CELL_SPACING),
	Vector3.new(-1 * CELL_SPACING, 0, 0 * CELL_SPACING),
	Vector3.new(0 * CELL_SPACING, 0, 0 * CELL_SPACING),
	Vector3.new(1 * CELL_SPACING, 0, 0 * CELL_SPACING),
	Vector3.new(2 * CELL_SPACING, 0, 0 * CELL_SPACING),
	Vector3.new(-2 * CELL_SPACING, 0, 1 * CELL_SPACING),
	Vector3.new(-1 * CELL_SPACING, 0, 1 * CELL_SPACING),
	Vector3.new(0 * CELL_SPACING, 0, 1 * CELL_SPACING),
	Vector3.new(1 * CELL_SPACING, 0, 1 * CELL_SPACING),
	Vector3.new(2 * CELL_SPACING, 0, 1 * CELL_SPACING),
	Vector3.new(-2 * CELL_SPACING, 0, 2 * CELL_SPACING),
	Vector3.new(-1 * CELL_SPACING, 0, 2 * CELL_SPACING),
	Vector3.new(0 * CELL_SPACING, 0, 2 * CELL_SPACING),
	Vector3.new(1 * CELL_SPACING, 0, 2 * CELL_SPACING),
	Vector3.new(2 * CELL_SPACING, 0, 2 * CELL_SPACING),
}
local lastBreak = {}

local function isIslandBlock(block)
	return block
		and block:IsA("BasePart")
		and block.Parent == island
		and string.match(block.Name, "^Block_%d+$") ~= nil
end

for index = 1, 25 do
	local block = island:WaitForChild("Block_" .. index)
	block.Anchored = true
	block.Size = BLOCK_SIZE
	block.CFrame = CFrame.new(GRID[index])

	local oldPrompt = block:FindFirstChild("BreakPrompt")
	if oldPrompt then
		oldPrompt:Destroy()
	end
end

spawn.CFrame = CFrame.new(0, BLOCK_SIZE.Y / 2 + 0.5, 0)

breakBlock.OnServerEvent:Connect(function(player, block)
	if not isIslandBlock(block) then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - block.Position).Magnitude > MAX_BREAK_DISTANCE then
		return
	end

	local now = os.clock()
	if lastBreak[player] and now - lastBreak[player] < 0.2 then
		return
	end
	lastBreak[player] = now

	block:Destroy()
end)

Players.PlayerRemoving:Connect(function(player)
	lastBreak[player] = nil
end)
