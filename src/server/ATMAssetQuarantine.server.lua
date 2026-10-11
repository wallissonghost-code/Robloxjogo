local InsertService = game:GetService("InsertService")

local ASSET_ID = 119678628566456
local MODEL_NAME = "QuarantinedATM_" .. ASSET_ID
local POSITION = Vector3.new(0, 0.55, -18)

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

if root:IsA("Model") then
	local boxCF, boxSize = root:GetBoundingBox()
	local pivot = root:GetPivot()
	local bottom = boxCF.Position.Y - boxSize.Y / 2
	root:PivotTo(pivot + Vector3.new(
		POSITION.X - pivot.Position.X,
		POSITION.Y - bottom,
		POSITION.Z - pivot.Position.Z
	))
elseif root:IsA("BasePart") then
	root.Position = Vector3.new(POSITION.X, POSITION.Y + root.Size.Y / 2, POSITION.Z)
end

print(("[ATM Quarantine] Asset %d loaded; %d script(s) disabled; %d interaction object(s) found."):format(
	ASSET_ID, scriptCount, interactionCount
))
for _, entry in ipairs(findings) do
	print("[ATM Quarantine] " .. entry)
end
