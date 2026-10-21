local TerritoryService = {}

local Config
local MapService
local NationService
local StateRemote

local function notify(state, text, kind)
	if state and state.Player then
		StateRemote:FireClient(state.Player, {
			type = "Notice",
			text = text,
			kind = kind or "Info",
		})
	end
end

local function broadcast(text)
	StateRemote:FireAllClients({
		type = "Feed",
		text = text,
	})
end

local function relocateCapitalIfNeeded(state)
	if not state or state.Eliminated then
		return
	end
	if state.CapitalCell and state.CapitalCell:GetAttribute("OwnerKey") == state.Key then
		return
	end
	local owned = MapService.GetOwnedCells(state.Key)
	if #owned == 0 then
		NationService.MarkEliminated(state)
		return
	end
	MapService.SetCapital(state, owned[1])
end

local function destroyCapturedBuilding(defender, cell)
	local buildingType = cell:GetAttribute("BuildingType")
	if buildingType and buildingType ~= "" then
		if defender and defender.Buildings[buildingType] then
			defender.Buildings[buildingType] = math.max(0, defender.Buildings[buildingType] - 1)
		end
		MapService.ClearBuilding(cell)
	end
end

local function captureCell(attacker, defender, cell)
	destroyCapturedBuilding(defender, cell)
	MapService.SetOwner(cell, attacker.Key, attacker.DisplayName, attacker.Color)
end

local function captureCluster(attacker, defender, firstCell, maxCells)
	local targetKey = firstCell:GetAttribute("OwnerKey")
	local queue = {firstCell}
	local index = 1
	local captured = 0
	local seen = {[firstCell] = true}

	while index <= #queue and captured < maxCells do
		local cell = queue[index]
		index += 1
		if cell:GetAttribute("OwnerKey") == targetKey then
			captureCell(attacker, defender, cell)
			captured += 1
			for _, neighbor in ipairs(MapService.GetNeighbors(cell)) do
				if not seen[neighbor] and neighbor:GetAttribute("OwnerKey") == targetKey then
					seen[neighbor] = true
					table.insert(queue, neighbor)
				end
			end
		end
	end
	return captured
end

function TerritoryService.Init(config, mapService, nationService, stateRemote)
	Config = config
	MapService = mapService
	NationService = nationService
	StateRemote = stateRemote
end

function TerritoryService.ClaimStart(state, cell)
	if not state or not cell or state.CapitalCell or state.Eliminated then
		return false
	end
	if cell:GetAttribute("OwnerKey") ~= "" then
		notify(state, "Essa área já foi ocupada.", "Error")
		return false
	end

	local cx = cell:GetAttribute("GX")
	local cy = cell:GetAttribute("GY")
	local claimed = 0
	for dx = -Config.Territory.StartRadius, Config.Territory.StartRadius do
		for dy = -Config.Territory.StartRadius, Config.Territory.StartRadius do
			local candidate = MapService.GetCell(cx + dx, cy + dy)
			if candidate and candidate:GetAttribute("OwnerKey") == "" then
				MapService.SetOwner(candidate, state.Key, state.DisplayName, state.Color)
				claimed += 1
			end
		end
	end

	if claimed == 0 then
		return false
	end

	MapService.SetCapital(state, cell)
	state.Troops = Config.Economy.StartTroops
	state.Gold = Config.Economy.StartGold
	state.Eliminated = false
	NationService.SyncState(state)
	notify(state, "Capital posicionada. Expanda pelas áreas vizinhas.", "Success")
	return true
end

local function expandNeutral(state, cell)
	if not MapService.IsAdjacentToOwner(cell, state.Key) then
		notify(state, "Você só pode expandir a partir da sua fronteira.", "Error")
		return false
	end

	local owned = MapService.GetOwnedCount(state.Key)
	local cost = Config.Territory.NeutralCaptureCost + math.floor(owned / 80)
	if state.Troops < cost then
		notify(state, "Tropas insuficientes para expandir.", "Error")
		return false
	end

	state.Troops -= cost
	MapService.SetOwner(cell, state.Key, state.DisplayName, state.Color)

	-- Envios maiores dão uma pequena expansão extra, mantendo o formato pixelado.
	if state.SelectedPercent >= 0.50 and state.Troops > cost * 3 then
		local candidates = MapService.GetNeighbors(cell)
		for _, neighbor in ipairs(candidates) do
			if neighbor:GetAttribute("OwnerKey") == "" and state.Troops >= cost then
				state.Troops -= cost
				MapService.SetOwner(neighbor, state.Key, state.DisplayName, state.Color)
				break
			end
		end
	end

	NationService.SyncState(state)
	return true
end

local function attackEnemy(state, cell)
	if not MapService.IsAdjacentToOwner(cell, state.Key) then
		notify(state, "O ataque terrestre precisa partir da sua fronteira.", "Error")
		return false
	end
	if state.Troops < Config.Territory.AttackMinTroops then
		notify(state, "Tropas insuficientes para atacar.", "Error")
		return false
	end

	local defenderKey = cell:GetAttribute("OwnerKey")
	local defender = NationService.GetByKey(defenderKey)
	if not defender then
		MapService.SetOwner(cell, "", "Neutro", nil)
		return expandNeutral(state, cell)
	end

	local send = math.max(1, math.floor(state.Troops * state.SelectedPercent))
	if send < Config.Territory.AttackMinTroops then
		notify(state, "A porcentagem escolhida envia poucas tropas.", "Error")
		return false
	end

	local defenderCells = math.max(MapService.GetOwnedCount(defender.Key), 1)
	local localDefense = math.max(6, (defender.Troops / math.sqrt(defenderCells)) * 0.13)
	local defenseBonus = 1 + math.min(0.80, defender.Buildings.Defense * (Config.Buildings.Defense.Defense or 0))
	if cell:GetAttribute("BuildingType") == "Defense" then
		defenseBonus += 0.35
	end
	local required = localDefense * defenseBonus

	state.Troops -= send

	if send > required then
		local ratio = send / math.max(required, 1)
		local captureCount = math.clamp(math.floor(ratio), 1, Config.Territory.MaxCellsPerAttack)
		local survivors = math.max(0, send - required) * 0.72
		state.Troops += survivors
		defender.Troops = math.max(0, defender.Troops - send * 0.42)

		captureCluster(state, defender, cell, captureCount)
		relocateCapitalIfNeeded(defender)

		if MapService.GetOwnedCount(defender.Key) == 0 then
			NationService.MarkEliminated(defender)
			broadcast(defender.DisplayName .. " foi eliminado por " .. state.DisplayName .. ".")
			notify(state, "Você eliminou " .. defender.DisplayName .. "!", "Success")
		end
	else
		defender.Troops = math.max(0, defender.Troops - send * 0.55)
		notify(state, "O ataque foi repelido. A defesa inimiga era maior.", "Error")
	end

	NationService.SyncState(state)
	NationService.SyncState(defender)
	return true
end

function TerritoryService.Act(state, cell)
	if not state or not cell or state.Eliminated then
		return false
	end
	if not state.CapitalCell then
		return TerritoryService.ClaimStart(state, cell)
	end

	local ownerKey = cell:GetAttribute("OwnerKey")
	if ownerKey == state.Key then
		return false
	elseif ownerKey == "" then
		return expandNeutral(state, cell)
	else
		return attackEnemy(state, cell)
	end
end

function TerritoryService.Build(state, cell, buildingType)
	if not state or not cell or not state.CapitalCell or state.Eliminated then
		return false
	end
	if cell:GetAttribute("OwnerKey") ~= state.Key then
		notify(state, "Construa apenas dentro do seu território.", "Error")
		return false
	end
	if cell:GetAttribute("BuildingType") ~= "" then
		notify(state, "Essa célula já possui uma construção.", "Error")
		return false
	end

	local definition = Config.Buildings[buildingType]
	if not definition then
		return false
	end
	if state.Buildings[buildingType] >= definition.Max then
		notify(state, "Limite dessa construção atingido.", "Error")
		return false
	end
	if definition.RequiresCoast and not MapService.IsCoastal(cell) then
		notify(state, "O porto precisa ser construído no litoral.", "Error")
		return false
	end
	if state.Gold < definition.Cost then
		notify(state, "Ouro insuficiente para " .. definition.DisplayName .. ".", "Error")
		return false
	end

	state.Gold -= definition.Cost
	state.Buildings[buildingType] += 1
	MapService.PlaceBuilding(cell, buildingType, state)
	NationService.SyncState(state)
	notify(state, definition.DisplayName .. " construída.", "Success")
	return true
end

return TerritoryService
