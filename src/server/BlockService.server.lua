local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local island = Workspace:WaitForChild("StarterIsland")
local spawn = Workspace:WaitForChild("SpawnLocation")
local breakBlock = ReplicatedStorage:WaitForChild("BreakBlock")
local inventoryUpdate = ReplicatedStorage:WaitForChild("InventoryUpdate")
local placeBlock = ReplicatedStorage:WaitForChild("PlaceBlock")

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
local placedBlockId = 0

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
		and (string.match(block.Name, "^Block_%d+$") ~= nil or block:GetAttribute("MineableBlock") == true)
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


local function blockItem(block)
	return block.Material == Enum.Material.Grass and "Grass" or "Dirt"
end

local function snap(value)
	return math.round(value / CELL_SPACING) * CELL_SPACING
end

placeBlock.OnServerEvent:Connect(function(player, itemName, worldPosition)
	if (itemName ~= "Grass" and itemName ~= "Dirt") or typeof(worldPosition) ~= "Vector3" then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - worldPosition).Magnitude > MAX_BREAK_DISTANCE then
		return
	end

	local inventory = getInventory(player)
	if (inventory[itemName] or 0) <= 0 then
		return
	end

	local position = Vector3.new(snap(worldPosition.X), snap(worldPosition.Y), snap(worldPosition.Z))
	local overlap = Workspace:GetPartBoundsInBox(CFrame.new(position), BLOCK_SIZE * 0.9)
	for _, part in ipairs(overlap) do
		if part:IsDescendantOf(island) then
			return
		end
	end

	placedBlockId += 1
	local block = Instance.new("Part")
	block.Name = "Block_Placed_" .. placedBlockId
	block.Anchored = true
	block.Size = BLOCK_SIZE
	block.CFrame = CFrame.new(position)
	block.TopSurface = Enum.SurfaceType.Smooth
	block.BottomSurface = Enum.SurfaceType.Smooth
	block.Material = itemName == "Grass" and Enum.Material.Grass or Enum.Material.Ground
	block.Color = itemName == "Grass" and Color3.fromRGB(75, 136, 55) or Color3.fromRGB(101, 67, 33)
	block:SetAttribute("MineableBlock", true)
	block.Parent = island

	inventory[itemName] -= 1
	sendInventory(player)
end)

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
	local itemName = blockItem(block)
	inventory[itemName] += 1

	block:Destroy()
	sendInventory(player)
end)

Players.PlayerRemoving:Connect(function(player)
	lastBreak[player] = nil
	inventories[player] = nil
end)
