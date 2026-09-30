local InsertService = game:GetService("InsertService")

local ASSET_ID = 14034779103
local MODEL_NAME = "Gojo_" .. ASSET_ID
local POSITION = Vector3.new(0, 0, 0)

local old = workspace:FindFirstChild(MODEL_NAME)
if old then
	old:Destroy()
end

local ok, container = pcall(function()
	return InsertService:LoadAsset(ASSET_ID)
end)

if not ok then
	warn(("[GojoAsset] LoadAsset(%d) failed: %s"):format(ASSET_ID, tostring(container)))
	return
end

local children = container:GetChildren()
if #children == 0 then
	warn(("[GojoAsset] Asset %d returned no objects"):format(ASSET_ID))
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
	root.Name = MODEL_NAME
	root.Parent = workspace
	for _, child in ipairs(children) do
		child.Parent = root
	end
	container:Destroy()
end

root.Name = MODEL_NAME

local function prepare(instance)
	if instance:IsA("BasePart") then
		instance.Anchored = true
	end
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
end

prepare(root)

if root:IsA("Model") then
	local boxCFrame, boxSize = root:GetBoundingBox()
	local pivot = root:GetPivot()
	local bottomY = boxCFrame.Position.Y - boxSize.Y / 2
	root:PivotTo(pivot + Vector3.new(
		POSITION.X - pivot.Position.X,
		POSITION.Y - bottomY,
		POSITION.Z - pivot.Position.Z
	))
elseif root:IsA("BasePart") then
	root.Position = Vector3.new(POSITION.X, POSITION.Y + root.Size.Y / 2, POSITION.Z)
end

root:SetAttribute("SourceAssetId", ASSET_ID)
print(("[GojoAsset] Loaded asset %d into Workspace"):format(ASSET_ID))
