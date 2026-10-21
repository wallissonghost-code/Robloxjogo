local NationService = {}

local Config
local MapService
local statesByKey = {}
local statesByPlayer = {}
local nextBotId = 0

local palette = {
	Color3.fromRGB(235, 79, 162),
	Color3.fromRGB(75, 169, 255),
	Color3.fromRGB(72, 214, 147),
	Color3.fromRGB(255, 151, 74),
	Color3.fromRGB(173, 112, 255),
	Color3.fromRGB(255, 221, 79),
	Color3.fromRGB(73, 211, 216),
	Color3.fromRGB(242, 103, 103),
	Color3.fromRGB(126, 190, 92),
	Color3.fromRGB(142, 146, 234),
	Color3.fromRGB(225, 122, 206),
	Color3.fromRGB(203, 162, 89),
}

local function newBuildings()
	return {
		City = 0,
		Port = 0,
		Factory = 0,
		Defense = 0,
	}
end

local function createState(key, displayName, player, color, isBot)
	local state = {
		Key = key,
		DisplayName = displayName,
		Player = player,
		IsBot = isBot == true,
		Color = color,
		Troops = Config.Economy.StartTroops,
		Gold = Config.Economy.StartGold,
		SelectedPercent = Config.DefaultSendPercent,
		CapitalCell = nil,
		Buildings = newBuildings(),
		Eliminated = false,
		LastActionAt = 0,
		TroopRate = 0,
		GoldRate = 0,
		TroopCap = Config.Economy.BaseTroopCap,
	}
	statesByKey[key] = state
	if player then
		statesByPlayer[player] = state
	end
	return state
end

function NationService.Init(config, mapService)
	Config = config
	MapService = mapService
end

function NationService.CreateForPlayer(player)
	local key = "P:" .. tostring(player.UserId)
	local existing = statesByKey[key]
	if existing then
		statesByPlayer[player] = existing
		existing.Player = player
		NationService.SyncState(existing)
		return existing
	end
	local color = palette[(math.abs(player.UserId) % #palette) + 1]
	local state = createState(key, player.DisplayName, player, color, false)
	NationService.SyncState(state)
	return state
end

function NationService.CreateBot(displayName, color)
	nextBotId += 1
	local key = "B:" .. tostring(nextBotId)
	color = color or palette[(nextBotId % #palette) + 1]
	return createState(key, displayName, nil, color, true)
end

function NationService.GetForPlayer(player)
	return statesByPlayer[player]
end

function NationService.GetByKey(key)
	return statesByKey[key]
end

function NationService.GetAllStates()
	local result = {}
	for _, state in pairs(statesByKey) do
		table.insert(result, state)
	end
	return result
end

function NationService.SyncState(state)
	if not state then
		return
	end
	local cells = MapService.GetOwnedCount(state.Key)
	local land = math.max(MapService.GetLandCount(), 1)
	local buildings = state.Buildings

	local troopRate = Config.Economy.BaseTroopsPerSecond
		+ cells * Config.Economy.TroopsPerCellPerSecond
		+ buildings.City * (Config.Buildings.City.TroopRate or 0)
		+ buildings.Factory * (Config.Buildings.Factory.TroopRate or 0)

	local goldRate = Config.Economy.BaseGoldPerSecond
		+ cells * Config.Economy.GoldPerCellPerSecond
		+ buildings.Factory * (Config.Buildings.Factory.GoldRate or 0)
		+ buildings.Port * (Config.Buildings.Port.GoldRate or 0)

	local cap = Config.Economy.BaseTroopCap
		+ cells * Config.Economy.TroopCapPerCell
		+ buildings.City * (Config.Buildings.City.TroopCap or 0)

	state.TroopRate = troopRate
	state.GoldRate = goldRate
	state.TroopCap = cap

	if state.Player then
		local player = state.Player
		player:SetAttribute("WarTroops", math.floor(state.Troops))
		player:SetAttribute("WarGold", math.floor(state.Gold))
		player:SetAttribute("WarTroopRate", troopRate)
		player:SetAttribute("WarGoldRate", goldRate)
		player:SetAttribute("WarTroopCap", math.floor(cap))
		player:SetAttribute("WarTerritoryCells", cells)
		player:SetAttribute("WarTerritoryPct", (cells / land) * 100)
		player:SetAttribute("WarSelectedPercent", state.SelectedPercent)
		player:SetAttribute("WarHasCapital", state.CapitalCell ~= nil)
		player:SetAttribute("WarEliminated", state.Eliminated)
	end

	MapService.UpdateCapitalLabel(state)
end

function NationService.Step(seconds)
	for _, state in pairs(statesByKey) do
		if state.CapitalCell and not state.Eliminated then
			NationService.SyncState(state)
			state.Troops = math.min(state.TroopCap, state.Troops + state.TroopRate * seconds)
			state.Gold += state.GoldRate * seconds
			NationService.SyncState(state)
		end
	end
end

function NationService.SetSelectedPercent(state, value)
	value = tonumber(value)
	if not state or not value then
		return false
	end
	for _, allowed in ipairs(Config.SendPercents) do
		if math.abs(value - allowed) < 0.001 then
			state.SelectedPercent = allowed
			NationService.SyncState(state)
			return true
		end
	end
	return false
end

function NationService.RemovePlayer(player)
	local state = statesByPlayer[player]
	if not state then
		return
	end
	MapService.NeutralizeOwner(state.Key)
	statesByPlayer[player] = nil
	statesByKey[state.Key] = nil
end

function NationService.MarkEliminated(state)
	if not state then
		return
	end
	state.Eliminated = true
	state.CapitalCell = nil
	NationService.SyncState(state)
end

return NationService
