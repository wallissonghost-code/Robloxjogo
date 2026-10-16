-- LobbyBuilder.server.lua
-- Runtime creative-mode backend for decorating the lobby from mobile.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")

local OWNER_USER_ID = 9538436641
local HALLOWEEN_ASSET_ID = 113280926555931

local remotes = ReplicatedStorage:FindFirstChild("LobbyBuilderRemotes") or Instance.new("Folder")
remotes.Name = "LobbyBuilderRemotes"; remotes.Parent = ReplicatedStorage
local request = remotes:FindFirstChild("Request") or Instance.new("RemoteFunction")
request.Name = "Request"; request.Parent = remotes

local catalog = ReplicatedStorage:FindFirstChild("HalloweenCatalog") or Instance.new("Folder")
catalog.Name = "HalloweenCatalog"; catalog.Parent = ReplicatedStorage
local placed = workspace:FindFirstChild("LobbyDecor") or Instance.new("Folder")
placed.Name = "LobbyDecor"; placed.Parent = workspace

local catalogStatus = "Ainda não carregado"\nlocal catalogLoaded = false\nlocal catalogLoading = false
local function authorized(player) return player.UserId == OWNER_USER_ID end

local function sanitizeTemplate(inst)
	for _,d in ipairs(inst:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = true
		end
	end
	if inst:IsA("BasePart") then inst.Anchored=true; inst.CanCollide=true end
end

local function hasPart(inst)
	if inst:IsA("BasePart") then return true end
	return inst:FindFirstChildWhichIsA("BasePart", true) ~= nil
end

local serial = 0
local function addTemplate(item)
	if not hasPart(item) then return false end
	serial += 1
	local clone = item:Clone()
	clone.Name = string.format("%02d_%s", serial, item.Name)
	sanitizeTemplate(clone)
	clone.Parent = catalog
	return true
end

local function scanContainer(container)
	for _,item in ipairs(container:GetChildren()) do
		if item:IsA("Folder") then
			scanContainer(item)
		elseif item:IsA("Model") or item:IsA("Accessory") or item:IsA("BasePart") then
			addTemplate(item)
		elseif hasPart(item) then
			addTemplate(item)
		end
	end
end

local function loadCatalog()
	catalog:ClearAllChildren()
	serial = 0
	local ok, packOrError = pcall(function()
		return InsertService:LoadAsset(HALLOWEEN_ASSET_ID)
	end)
	if not ok or not packOrError then
		catalogStatus = "Roblox recusou o asset: "..tostring(packOrError)
		warn("[LobbyBuilder] "..catalogStatus)
		return
	end

	local pack = packOrError
	scanContainer(pack)
	local count = #catalog:GetChildren()

	-- Some toolbox assets arrive wrapped in one or more Models/Folders.
	-- If the first pass treated the whole wrapper as one item, unwrap it so the
	-- creative catalog exposes the individual decorations instead.
	if count == 1 then
		local only = catalog:GetChildren()[1]
		local original = pack:GetChildren()[1]
		if original and (original:IsA("Model") or original:IsA("Folder")) and #original:GetChildren() > 1 then
			only:Destroy(); serial=0
			scanContainer(original)
			count=#catalog:GetChildren()
		end
	end

	pack:Destroy()
	if count == 0 then
		catalogStatus = "Asset carregou, mas não encontrei peças 3D dentro dele."
	else
		catalogStatus = tostring(count).." itens carregados"
	end
	print("[LobbyBuilder] "..catalogStatus)
end
loadCatalog()

local function pivot(inst, cf)
	if inst:IsA("Model") then
		inst:PivotTo(cf)
	elseif inst:IsA("BasePart") then
		inst.CFrame=cf
	elseif inst:IsA("Accessory") then
		local handle=inst:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then handle.CFrame=cf end
	end
end

request.OnServerInvoke=function(player, action, data)
	if not authorized(player) then return {ok=false,error="Sem permissão"} end
	data = data or {}
	if action=="catalog" then
		local out={}
		for _,v in ipairs(catalog:GetChildren()) do table.insert(out,v.Name) end
		table.sort(out)
		return {ok=true,items=out,status=catalogStatus}
	elseif action=="reloadCatalog" then
		loadCatalog()
		return {ok=true,status=catalogStatus}
	elseif action=="place" then
		local t=catalog:FindFirstChild(data.name)
		if not t then return {ok=false,error="Item inválido"} end
		local p=data.position
		if typeof(p)~="Vector3" then return {ok=false,error="Posição inválida"} end
		if math.abs(p.X)>62 or math.abs(p.Z)>62 then return {ok=false,error="Fora do lobby"} end
		local obj=t:Clone()
		obj.Name="Decor_"..data.name
		obj:SetAttribute("PlacedBy",player.UserId)
		obj.Parent=placed
		pivot(obj,CFrame.new(p)*CFrame.Angles(0,math.rad(data.rotation or 0),0))
		return {ok=true}
	elseif action=="deleteNearest" then
		local p=data.position
		local best,dist
		for _,obj in ipairs(placed:GetChildren()) do
			local pos
			if obj:IsA("Model") then pos=obj:GetPivot().Position
			elseif obj:IsA("BasePart") then pos=obj.Position
			else
				local part=obj:FindFirstChildWhichIsA("BasePart",true)
				pos=part and part.Position
			end
			if pos then
				local d=(pos-p).Magnitude
				if not dist or d<dist then best,dist=obj,d end
			end
		end
		if best and dist<=12 then best:Destroy(); return {ok=true} end
		return {ok=false,error="Nenhum item próximo"}
	elseif action=="clear" then
		placed:ClearAllChildren(); return {ok=true}
	end
	return {ok=false,error="Ação inválida"}
end
