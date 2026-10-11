local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ASSET_ID = 119678628566456
local MODEL_NAME = "QuarantinedATM_" .. ASSET_ID
local POSITION = Vector3.new(0, 4.5, -18)

local openEvent = ReplicatedStorage:FindFirstChild("ATMOpen") or Instance.new("RemoteEvent")
openEvent.Name = "ATMOpen"
openEvent.Parent = ReplicatedStorage

local old = workspace:FindFirstChild(MODEL_NAME)
if old then old:Destroy() end

local ok, container = pcall(function()
	return InsertService:LoadAsset(ASSET_ID)
end)

if not ok then
	warn("[ATM Quarantine] LoadAsset failed: " .. tostring(container))
	return
end

-- Keep community code disabled. We inspect the interaction objects and rebuild
-- the ATM functionality ourselves instead of executing untrusted scripts.
local scriptCount = 0
local interactionCount = 0
local findings = {}

for _, obj in ipairs(container:GetDescendants()) do
	if obj:IsA("Script") or obj:IsA("LocalScript") then
		obj.Disabled = true
		scriptCount += 1
		table.insert(findings, "CODE(disabled) " .. obj.ClassName .. " :: " .. obj:GetFullName())
	elseif obj:IsA("ModuleScript") then
		scriptCount += 1
		table.insert(findings, "CODE(module-not-executed) :: " .. obj:GetFullName())
	elseif obj:IsA("ClickDetector") or obj:IsA("ProximityPrompt") then
		interactionCount += 1
		table.insert(findings, "INTERACTION " .. obj.ClassName .. " :: " .. obj:GetFullName())
	end
end

local children = container:GetChildren()
if #children == 0 then
	warn("[ATM Quarantine] Asset returned no usable objects.")
	container:Destroy()
	return
end

local root
if #children == 1 then
	root = children[1]
	root.Parent = workspace
	container:Destroy()
else
	root = Instance.new("Model")
	root.Parent = workspace
	for _, child in ipairs(children) do
		child.Parent = root
	end
	container:Destroy()
end

root.Name = MODEL_NAME
root:SetAttribute("SourceAssetId", ASSET_ID)
root:SetAttribute("Quarantined", true)
root:SetAttribute("DisabledScriptCount", scriptCount)
root:SetAttribute("InteractionCount", interactionCount)

-- Disable scripts again after reparenting as a defense-in-depth check.
for _, obj in ipairs(root:GetDescendants()) do
	if obj:IsA("Script") or obj:IsA("LocalScript") then
		obj.Disabled = true
	end
end

-- V7: this asset's root is a container, not a Model/BasePart.
-- Move every physical part together using their real world-space bounds.
local parts = {}
if root:IsA("BasePart") then table.insert(parts, root) end
for _, obj in ipairs(root:GetDescendants()) do
	if obj:IsA("BasePart") then table.insert(parts, obj) end
end

if #parts > 0 then
	local minX, minY, minZ = math.huge, math.huge, math.huge
	local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
	for _, part in ipairs(parts) do
		local half = part.Size * 0.5
		local p = part.Position
		minX = math.min(minX, p.X - half.X)
		minY = math.min(minY, p.Y - half.Y)
		minZ = math.min(minZ, p.Z - half.Z)
		maxX = math.max(maxX, p.X + half.X)
		maxY = math.max(maxY, p.Y + half.Y)
		maxZ = math.max(maxZ, p.Z + half.Z)
	end
	local center = Vector3.new((minX+maxX)/2, (minY+maxY)/2, (minZ+maxZ)/2)
	local targetBottomY = 0.65
	local delta = Vector3.new(POSITION.X-center.X, targetBottomY-minY, POSITION.Z-center.Z)
	for _, part in ipairs(parts) do
		part.CFrame = part.CFrame + delta
	end
	root:SetAttribute("VisualBottomY", targetBottomY)
	root:SetAttribute("MovedPartCount", #parts)
end

print(("[ATM Quarantine] Asset %d loaded; %d script(s) disabled; %d interaction object(s) found."):format(
	ASSET_ID, scriptCount, interactionCount
))
local anchor = parts[1]
if anchor then
	for _, obj in ipairs(root:GetDescendants()) do
		if obj:IsA("ProximityPrompt") then obj.Enabled = false end
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SafeATMPrompt"
	prompt.ActionText = "Acessar"
	prompt.ObjectText = "Caixa Eletronico"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor
	prompt.Triggered:Connect(function(player)
		openEvent:FireClient(player)
	end)
	root:SetAttribute("SafePromptReady", true)
	root:SetAttribute("ServerBuild", "V13")
	local tag = Instance.new("BillboardGui")
	tag.Name = "ServerBuildTag"
	tag.Size = UDim2.fromOffset(150, 34)
	tag.StudsOffset = Vector3.new(0, 5, 0)
	tag.AlwaysOnTop = true
	tag.Parent = anchor
	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.fromScale(1,1)
	txt.BackgroundColor3 = Color3.fromRGB(15,15,18)
	txt.BackgroundTransparency = 0.15
	txt.TextColor3 = Color3.new(1,1,1)
	txt.Text = "BUILD V13"
	txt.Font = Enum.Font.GothamBold
	txt.TextSize = 16
	txt.Parent = tag
end
