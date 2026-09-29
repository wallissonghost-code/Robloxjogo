local InsertService=game:GetService("InsertService")
local Players=game:GetService("Players")
local ASSET_ID=580221169
local NAME="ImportedTree_"..ASSET_ID
local POS=Vector3.new(10,0,3)

local status="TESTANDO..."
local detail="Tentando LoadAsset("..ASSET_ID..")"

local function show(player)
	local pg=player:WaitForChild("PlayerGui",10)
	if not pg then return end
	local old=pg:FindFirstChild("TreeAssetDiagnostic"); if old then old:Destroy() end
	local gui=Instance.new("ScreenGui"); gui.Name="TreeAssetDiagnostic"; gui.ResetOnSpawn=false; gui.Parent=pg
	local frame=Instance.new("Frame"); frame.Size=UDim2.new(0,520,0,145); frame.Position=UDim2.new(.5,-260,0,18); frame.BackgroundColor3=Color3.fromRGB(18,20,24); frame.BackgroundTransparency=.08; frame.Parent=gui
	local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,12); corner.Parent=frame
	local label=Instance.new("TextLabel"); label.Size=UDim2.new(1,-24,1,-20); label.Position=UDim2.new(0,12,0,10); label.BackgroundTransparency=1; label.TextWrapped=true; label.TextXAlignment=Enum.TextXAlignment.Left; label.TextYAlignment=Enum.TextYAlignment.Top; label.Font=Enum.Font.Gotham; label.TextSize=17; label.TextColor3=Color3.new(1,1,1); label.Text="TREE ASSET "..ASSET_ID.."\nSTATUS: "..status.."\n"..detail; label.Parent=frame
end
local function broadcast()
	for _,p in ipairs(Players:GetPlayers()) do task.spawn(show,p) end
end
Players.PlayerAdded:Connect(function(p) task.wait(2); show(p) end)

local old=workspace:FindFirstChild(NAME); if old then old:Destroy() end
local ok,result=pcall(function() return InsertService:LoadAsset(ASSET_ID) end)
if not ok then
	status="FALHOU"
	detail=tostring(result)
	warn("[TreeAssetDiagnostic] "..detail)
	broadcast()
	return
end
local container=result
local children=container:GetChildren()
if #children==0 then
	status="VAZIO"
	detail="Roblox aceitou o ID, mas devolveu 0 objetos."
	container:Destroy(); broadcast(); return
end

local root
if #children==1 then root=children[1]; root.Parent=workspace; container:Destroy()
else
	root=Instance.new("Model"); root.Name=NAME; root.Parent=workspace
	for _,v in ipairs(children) do v.Parent=root end
	container:Destroy()
end
root.Name=NAME
if root:IsA("BasePart") then root.Anchored=true end
for _,v in ipairs(root:GetDescendants()) do if v:IsA("BasePart") then v.Anchored=true end end
if root:IsA("Model") then
	local cf,size=root:GetBoundingBox()
	local pivot=root:GetPivot()
	local bottom=cf.Position.Y-size.Y/2
	root:PivotTo(pivot+Vector3.new(POS.X-pivot.Position.X,POS.Y-bottom,POS.Z-pivot.Position.Z))
elseif root:IsA("BasePart") then root.Position=Vector3.new(POS.X,POS.Y+root.Size.Y/2,POS.Z) end
root:SetAttribute("SourceAssetId",ASSET_ID)
status="CARREGOU"
detail="O Roblox entregou "..#children.." objeto(s). A arvore foi colocada no mapa."
print("[TreeAssetDiagnostic] success")
broadcast()
