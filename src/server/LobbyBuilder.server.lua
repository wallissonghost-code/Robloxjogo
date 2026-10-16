local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")

local OWNER_USER_ID = 9538436641
local HALLOWEEN_ASSET_ID = 113280926555931

local remotes = ReplicatedStorage:FindFirstChild("LobbyBuilderRemotes") or Instance.new("Folder")
remotes.Name = "LobbyBuilderRemotes"
remotes.Parent = ReplicatedStorage

local request = remotes:FindFirstChild("Request") or Instance.new("RemoteFunction")
request.Name = "Request"
request.Parent = remotes

local catalog = ReplicatedStorage:FindFirstChild("HalloweenCatalog") or Instance.new("Folder")
catalog.Name = "HalloweenCatalog"
catalog.Parent = ReplicatedStorage

local placed = workspace:FindFirstChild("LobbyDecor") or Instance.new("Folder")
placed.Name = "LobbyDecor"
placed.Parent = workspace

local catalogLoaded = false
local catalogLoading = false
local catalogStatus = "Ainda nao carregado"

local function authorized(player)
	return player.UserId == OWNER_USER_ID
end

local function sanitize(inst)
	for _, d in ipairs(inst:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = true
		end
	end
	if inst:IsA("BasePart") then
		inst.Anchored = true
		inst.CanCollide = true
	end
end

local function containsPart(inst)
	return inst:IsA("BasePart") or inst:FindFirstChildWhichIsA("BasePart", true) ~= nil
end

local function loadCatalog()
	if catalogLoaded then return true end
	if catalogLoading then return false end

	catalogLoading = true
	catalogStatus = "Carregando..."
	catalog:ClearAllChildren()

	local ok, pack = pcall(function()
		return InsertService:LoadAsset(HALLOWEEN_ASSET_ID)
	end)

	if not ok or not pack then
		catalogStatus = "Falha ao carregar asset: " .. tostring(pack)
		catalogLoading = false
		warn("[LobbyBuilder] " .. catalogStatus)
		return false
	end

	local serial = 0
	local function add(item)
		if not containsPart(item) then return end
		serial += 1
		local clone = item:Clone()
		clone.Name = string.format("%03d_%s", serial, item.Name)
		sanitize(clone)
		clone.Parent = catalog
	end

	local function scan(container)
		for _, item in ipairs(container:GetChildren()) do
			if item:IsA("Folder") then
				scan(item)
			elseif item:IsA("Model") or item:IsA("Accessory") or item:IsA("BasePart") then
				add(item)
			elseif containsPart(item) then
				add(item)
			end
		end
	end

	scan(pack)
	pack:Destroy()

	local count = #catalog:GetChildren()
	catalogLoaded = count > 0
	catalogLoading = false
	catalogStatus = catalogLoaded and (tostring(count) .. " itens carregados") or "Asset sem pecas 3D utilizaveis"
	print("[LobbyBuilder] " .. catalogStatus)
	return catalogLoaded
end

local function setPivot(inst, cf)
	if inst:IsA("Model") then
		inst:PivotTo(cf)
	elseif inst:IsA("BasePart") then
		inst.CFrame = cf
	else
		local part = inst:FindFirstChildWhichIsA("BasePart", true)
		if part then
			local delta = cf * part.CFrame:Inverse()
			for _, d in ipairs(inst:GetDescendants()) do
				if d:IsA("BasePart") then d.CFrame = delta * d.CFrame end
			end
		end
	end
end

request.OnServerInvoke = function(player, action, data)
	if not authorized(player) then
		return {ok = false, error = "Sem permissao"}
	end
	data = data or {}

	if action == "catalog" then
		loadCatalog()
		local items = {}
		for _, item in ipairs(catalog:GetChildren()) do
			table.insert(items, item.Name)
		end
		table.sort(items)
		return {ok = catalogLoaded, items = items, status = catalogStatus}
	end

	if action == "place" then
		local template = catalog:FindFirstChild(data.name)
		if not template then return {ok = false, error = "Item invalido"} end
		if typeof(data.position) ~= "Vector3" then return {ok = false, error = "Posicao invalida"} end
		if math.abs(data.position.X) > 62 or math.abs(data.position.Z) > 62 then
			return {ok = false, error = "Fora do lobby"}
		end

		local obj = template:Clone()
		obj.Name = "Decor_" .. data.name
		obj:SetAttribute("PlacedBy", player.UserId)
		obj.Parent = placed
		setPivot(obj, CFrame.new(data.position) * CFrame.Angles(0, math.rad(data.rotation or 0), 0))
		return {ok = true}
	end

	if action == "deleteNearest" then
		if typeof(data.position) ~= "Vector3" then return {ok = false, error = "Posicao invalida"} end
		local best, bestDistance
		for _, obj in ipairs(placed:GetChildren()) do
			local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
			local pos = obj:IsA("Model") and obj:GetPivot().Position or (part and part.Position)
			if pos then
				local distance = (pos - data.position).Magnitude
				if not bestDistance or distance < bestDistance then
					best, bestDistance = obj, distance
				end
			end
		end
		if best and bestDistance <= 12 then
			best:Destroy()
			return {ok = true}
		end
		return {ok = false, error = "Nenhum item proximo"}
	end

	return {ok = false, error = "Acao invalida"}
end
