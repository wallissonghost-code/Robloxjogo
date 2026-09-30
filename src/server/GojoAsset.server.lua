local InsertService=game:GetService("InsertService")
local MarketplaceService=game:GetService("MarketplaceService")
local Players=game:GetService("Players")

local ASSET_ID=14034779103
local NAME="ImportedGojo_"..ASSET_ID
local POS=Vector3.new(0,0,3)

local report={}
local status="TESTANDO..."

local function add(title,value)
	table.insert(report,title..": "..tostring(value))
end

local function reportText()
	return table.concat(report,"\n")
end

local function show(player)
	local pg=player:WaitForChild("PlayerGui",10)
	if not pg then return end
	local old=pg:FindFirstChild("GojoAssetDiagnostic")
	if old then old:Destroy() end

	local gui=Instance.new("ScreenGui")
	gui.Name="GojoAssetDiagnostic"
	gui.ResetOnSpawn=false
	gui.DisplayOrder=999999
	gui.Parent=pg

	local frame=Instance.new("Frame")
	frame.Size=UDim2.new(.92,0,0,360)
	frame.Position=UDim2.new(.04,0,0,16)
	frame.BackgroundColor3=Color3.fromRGB(15,17,21)
	frame.BackgroundTransparency=.04
	frame.Parent=gui
	local corner=Instance.new("UICorner")
	corner.CornerRadius=UDim.new(0,12)
	corner.Parent=frame

	local label=Instance.new("TextLabel")
	label.Name="Report"
	label.Size=UDim2.new(1,-24,1,-24)
	label.Position=UDim2.new(0,12,0,12)
	label.BackgroundTransparency=1
	label.TextWrapped=true
	label.TextXAlignment=Enum.TextXAlignment.Left
	label.TextYAlignment=Enum.TextYAlignment.Top
	label.Font=Enum.Font.Code
	label.TextSize=14
	label.TextColor3=Color3.new(1,1,1)
	label.Text="GOJO DIAGNOSTIC "..ASSET_ID.."\nSTATUS: "..status.."\n\n"..reportText()
	label.Parent=frame
end

local function broadcast()
	for _,p in ipairs(Players:GetPlayers()) do task.spawn(show,p) end
end

Players.PlayerAdded:Connect(function(p)
	task.wait(2)
	show(p)
end)

add("PlaceId",game.PlaceId)
add("GameId/UniverseId",game.GameId)
add("CreatorId",game.CreatorId)
add("CreatorType",game.CreatorType.Name)

local infoOk,info=pcall(function()
	return MarketplaceService:GetProductInfo(ASSET_ID,Enum.InfoType.Asset)
end)
if infoOk and type(info)=="table" then
	add("Marketplace lookup","OK")
	add("Name",info.Name or "?")
	add("AssetTypeId",info.AssetTypeId or "?")
	add("IsPublicDomain",info.IsPublicDomain)
	add("IsForSale",info.IsForSale)
	add("SaleLocationType",info.SaleLocationType or "?")
	if type(info.Creator)=="table" then
		add("Asset Creator",info.Creator.Name or "?")
		add("Asset CreatorId",info.Creator.CreatorTargetId or info.Creator.Id or "?")
		add("Asset CreatorType",info.Creator.CreatorType or "?")
	end
else
	add("Marketplace lookup","FALHOU")
	add("Marketplace error",info)
end

local old=workspace:FindFirstChild(NAME)
if old then old:Destroy() end

local started=os.clock()
local ok,result=pcall(function()
	return InsertService:LoadAsset(ASSET_ID)
end)
add("LoadAsset time",string.format("%.3fs",os.clock()-started))

if not ok then
	status="FALHOU NO LOADASSET"
	add("LoadAsset result","ERRO")
	add("Error raw",result)
	local lower=string.lower(tostring(result))
	if string.find(lower,"not authorized",1,true) or string.find(lower,"not permitted",1,true) or string.find(lower,"permission",1,true) then
		add("Classificacao","PERMISSAO/AUTORIZACAO DO ASSET")
		add("Leitura","O Roblox bloqueou o asset antes de devolver o modelo; nao e erro de posicionamento.")
	elseif string.find(lower,"asset",1,true) and string.find(lower,"not found",1,true) then
		add("Classificacao","ASSET NAO ENCONTRADO/INDISPONIVEL")
	else
		add("Classificacao","ERRO DE LOADASSET NAO CLASSIFICADO")
	end
	warn("[GojoAssetDiagnostic]\n"..reportText())
	broadcast()
	return
end

local container=result
add("LoadAsset result","OK")
add("Returned class",container.ClassName)
local children=container:GetChildren()
add("Top-level objects",#children)

if #children==0 then
	status="VAZIO"
	add("Classificacao","ROBLOX DEVOLVEU CONTAINER SEM OBJETOS")
	container:Destroy()
	broadcast()
	return
end

for i,child in ipairs(children) do
	if i<=8 then add("Child "..i,child.ClassName.." / "..child.Name) end
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
	for _,v in ipairs(children) do v.Parent=root end
	container:Destroy()
end

root.Name=NAME
local partCount=0
local scriptCount=0
if root:IsA("BasePart") then
	root.Anchored=true
	partCount+=1
end
for _,v in ipairs(root:GetDescendants()) do
	if v:IsA("BasePart") then
		v.Anchored=true
		partCount+=1
	elseif v:IsA("Script") or v:IsA("LocalScript") or v:IsA("ModuleScript") then
		scriptCount+=1
	end
end
add("BaseParts",partCount)
add("Scripts inside asset",scriptCount)

if root:IsA("Model") then
	local cf,size=root:GetBoundingBox()
	add("Bounding size",tostring(size))
	local pivot=root:GetPivot()
	local bottom=cf.Position.Y-size.Y/2
	root:PivotTo(pivot+Vector3.new(POS.X-pivot.Position.X,POS.Y-bottom,POS.Z-pivot.Position.Z))
elseif root:IsA("BasePart") then
	add("Part size",tostring(root.Size))
	root.Position=Vector3.new(POS.X,POS.Y+root.Size.Y/2,POS.Z)
end

root:SetAttribute("SourceAssetId",ASSET_ID)
status="CARREGOU"
add("Workspace path",root:GetFullName())
add("Classificacao","LOADASSET FUNCIONOU E O OBJETO FOI INSERIDO")
print("[GojoAssetDiagnostic]\n"..reportText())
broadcast()
