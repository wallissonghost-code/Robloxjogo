local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local BLOCK_TAG = "CollectibleBlock"

local function getBlockCount(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local blocks = leaderstats:FindFirstChild("Blocks")
	if not blocks then
		blocks = Instance.new("IntValue")
		blocks.Name = "Blocks"
		blocks.Value = 0
		blocks.Parent = leaderstats
	end

	return blocks
end

local function setupBlock(block)
	if not block:IsA("BasePart") or block:GetAttribute("CollectibleReady") then
		return
	end

	block:SetAttribute("CollectibleReady", true)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BreakPrompt"
	prompt.ActionText = "Quebrar"
	prompt.ObjectText = "Bloco de terra"
	prompt.HoldDuration = 0.65
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = block

	local claimed = false
	prompt.Triggered:Connect(function(player)
		if claimed or not block.Parent then
			return
		end

		claimed = true
		prompt.Enabled = false
		getBlockCount(player).Value += 1
		block:Destroy()
	end)
end

Players.PlayerAdded:Connect(function(player)
	getBlockCount(player)
end)

for _, block in CollectionService:GetTagged(BLOCK_TAG) do
	setupBlock(block)
end

CollectionService:GetInstanceAddedSignal(BLOCK_TAG):Connect(setupBlock)
