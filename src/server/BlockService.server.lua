local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local island = Workspace:WaitForChild("StarterIsland")
local spawn = Workspace:WaitForChild("SpawnLocation")
local breakBlock = ReplicatedStorage:WaitForChild("BreakBlock")
local inventoryUpdate = ReplicatedStorage:WaitForChild("InventoryUpdate")

local BLOCK_SIZE = Vector3.new(3.8, 3.8, 3.8)
local CELL_SPACING = 3.84
local MAX_BREAK_DISTANCE = 14

local positions = {}

-- 3x3 grass surface.
for z = -1, 1 do
	for x = -1, 1 do
		table.insert(positions, Vector3.new(x * CELL_SPACING, 0, z * CELL_SPACING))
	end
end

-- Three full dirt layers below the grass, creating a real Skyblock body.
for layer = 1, 3 do
	for z = -1, 1 do
		for x = -1, 1 do
			table.insert(positions, Vector3.new(x * CELL_SPACING, -layer * CELL_SPACING, z * CELL_SPACING))
		end
	end
end

local lastBreak = {}
local inventories = {}

local function getInventory(player)
	local inventory = inventories[player]
	if not inventory then
		inventory = { Grass = 0, Dirt = 0 }
		inventories[player] = inventory
	end
	return inventory
end

local function sendInventory(player)
	local inventory = getInventory(player)
	inventoryUpdate:FireClient(player, { Grass = inventory.Grass, Dirt = inventory.Dirt })
end

Players.PlayerAdded:Connect(function(player)
	getInventory(player)
	task.defer(sendInventory, player)
end)

local function isIslandBlock(block)
	return block
		and block:IsA("BasePart")
		and block.Parent == island
		and string.match(block.Name, "^Block_%d+$") ~= nil
end

for index, position in ipairs(positions) do
	local block = island:WaitForChild("Block_" .. index)
	block.Anchored = true
	block.Size = BLOCK_SIZE
	block.CFrame = CFrame.new(position)

	if index <= 9 then
		block.Material = Enum.Material.Grass
		block.Color = Color3.fromRGB(75, 136, 55)
	else
		block.Material = Enum.Material.Ground
		block.Color = Color3.fromRGB(101, 67, 33)
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

	local inventory = getInventory(player)
	if block.Material == Enum.Material.Grass then
		inventory.Grass += 1
	else
		inventory.Dirt += 1
	end

	block:Destroy()
	sendInventory(player)
end)

Players.PlayerRemoving:Connect(function(player)
	lastBreak[player] = nil
	inventories[player] = nil
end)
