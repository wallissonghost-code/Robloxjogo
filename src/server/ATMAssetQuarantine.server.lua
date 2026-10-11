local InsertService = game:GetService("InsertService")

local ASSET_ID = 119678628566456
local MODEL_NAME = "QuarantinedATM_" .. ASSET_ID
local POSITION = Vector3.new(0, 0, -18)

local old = workspace:FindFirstChild(MODEL_NAME)
if old then old:Destroy() end

local ok, container = pcall(function()
	return InsertService:LoadAsset(ASSET_ID)
end)

if not ok then
	warn("[ATM Quarantine] LoadAsset failed: " .. tostring(container))
	return
end

-- IMPORTANT: asset remains outside Workspace while every embedded script is neutralized.
local scriptCount = 0
local scriptsFound = {}

local function quarantineScript(obj)
	if obj:IsA("Script") or obj:IsA("LocalScript") then
		obj.Disabled = true
		scriptCount += 1
		table.insert(scriptsFound, obj.ClassName .. " :: " .. obj:GetFullName())
	elseif obj:IsA("ModuleScript") then
		-- ModuleScripts do not execute by themselves, but remove them so another script can never require them.
		scriptCount += 1
		table.insert(scriptsFound, obj.ClassName .. " :: " .. obj:GetFullName())
		obj:Destroy()
	end
end

for _, obj in ipairs(container:GetDescendants()) do
	quarantineScript(obj)
end

-- Delete Script/LocalScript after recording them. We only keep the ATM's non-code assets.
for _, obj in ipairs(container:GetDescendants()) do
	if obj:IsA("Script") or obj:IsA("LocalScript") then
		obj:Destroy()
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
root:SetAttribute("RemovedScriptCount", scriptCount)

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

print(("[ATM Quarantine] Asset %d loaded. Removed %d embedded script(s)."):format(ASSET_ID, scriptCount))
for _, entry in ipairs(scriptsFound) do
	print("[ATM Quarantine] Removed: " .. entry)
end
