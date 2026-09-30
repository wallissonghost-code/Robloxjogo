local InsertService=game:GetService("InsertService")
local ASSET_ID=14034779103
local NAME="ImportedGojo_"..ASSET_ID
local POS=Vector3.new(0,0,3)

local old=workspace:FindFirstChild(NAME)
if old then old:Destroy() end

local ok,result=pcall(function()
	return InsertService:LoadAsset(ASSET_ID)
end)

if not ok then
	warn("[GojoAsset] "..tostring(result))
	return
end

local container=result
local children=container:GetChildren()
if #children==0 then
	warn("[GojoAsset] Roblox returned 0 objects for "..ASSET_ID)
	container:Destroy()
	return
end

local root
if #children==1 then
	root=children[1]
	root.Parent=workspace
	container:Destroy()
else
	root=Instance.new("Model")
	root.Name=NAME
	root.Parent=workspace
	for _,v in ipairs(children) do
		v.Parent=root
	end
	container:Destroy()
end

root.Name=NAME
if root:IsA("BasePart") then root.Anchored=true end
for _,v in ipairs(root:GetDescendants()) do
	if v:IsA("BasePart") then v.Anchored=true end
end

if root:IsA("Model") then
	local cf,size=root:GetBoundingBox()
	local pivot=root:GetPivot()
	local bottom=cf.Position.Y-size.Y/2
	root:PivotTo(pivot+Vector3.new(
		POS.X-pivot.Position.X,
		POS.Y-bottom,
		POS.Z-pivot.Position.Z
	))
elseif root:IsA("BasePart") then
	root.Position=Vector3.new(POS.X,POS.Y+root.Size.Y/2,POS.Z)
end

root:SetAttribute("SourceAssetId",ASSET_ID)
print("[GojoAsset] success "..ASSET_ID)
