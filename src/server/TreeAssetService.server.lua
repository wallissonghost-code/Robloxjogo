local InsertService = game:GetService("InsertService")

local TREE_ASSET_ID = 580221169
local TREE_NAME = "ImportedTree_580221169"
local TREE_POSITION = Vector3.new(10, 0, 3)

local old = workspace:FindFirstChild(TREE_NAME)
if old then
	old:Destroy()
end

local ok, containerOrError = pcall(function()
	return InsertService:LoadAsset(TREE_ASSET_ID)
end)

if not ok then
	warn(("[TreeAssetService] Could not load asset %d: %s"):format(
		TREE_ASSET_ID,
		tostring(containerOrError)
	))
	return
end

local container = containerOrError
local children = container:GetChildren()

if #children == 0 then
	warn(("[TreeAssetService] Asset %d loaded but returned no instances"):format(TREE_ASSET_ID))
	container:Destroy()
	return
end

local tree
if #children == 1 then
	tree = children[1]
	tree.Parent = workspace
	container:Destroy()
else
	tree = Instance.new("Model")
	tree.Name = TREE_NAME
	tree.Parent = workspace
	for _, child in ipairs(children) do
		child.Parent = tree
	end
	container:Destroy()
end

tree.Name = TREE_NAME

local function anchorAll(root)
	if root:IsA("BasePart") then
		root.Anchored = true
	end
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
end

anchorAll(tree)

local function placeAtGround(root, target)
	if root:IsA("Model") then
		local cf, size = root:GetBoundingBox()
		local bottomOffset = cf.Position.Y - size.Y / 2
		local deltaY = target.Y - bottomOffset
		root:PivotTo(root:GetPivot() + Vector3.new(
			target.X - root:GetPivot().Position.X,
			deltaY,
			target.Z - root:GetPivot().Position.Z
		))
	elseif root:IsA("BasePart") then
		root.Position = Vector3.new(target.X, target.Y + root.Size.Y / 2, target.Z)
	else
		warn(("[TreeAssetService] Asset %d root is %s; loaded but could not auto-position"):format(
			TREE_ASSET_ID,
			root.ClassName
		))
	end
end

placeAtGround(tree, TREE_POSITION)

tree:SetAttribute("SourceAssetId", TREE_ASSET_ID)
print(("[TreeAssetService] Tree asset %d loaded successfully"):format(TREE_ASSET_ID))
