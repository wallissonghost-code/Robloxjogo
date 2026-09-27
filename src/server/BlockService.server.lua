local CollectionService = game:GetService("CollectionService")

local BLOCK_TAG = "CollectibleBlock"

local function setupBlock(block)
	if not block:IsA("BasePart") then
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
	prompt.RequiresLineOfSight = true
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

for _, block in CollectionService:GetTagged(BLOCK_TAG) do
	setupBlock(block)
end

CollectionService:GetInstanceAddedSignal(BLOCK_TAG):Connect(setupBlock)
