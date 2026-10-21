local BotService = {}

local Config
local MapService
local NationService
local TerritoryService

local botNames = {
	"Orion", "Atlas", "Vega", "Cobalt", "Nomads", "Aurora",
	"Draco", "Titan", "Nova", "Ares", "Comet", "Helios",
	"Falcon", "Boreal", "Quartz", "Raven", "Delta", "Zenith",
	"Mistral", "Ember", "Lynx", "Sol",
}

local function pickSpawnCell()
	local land = MapService.GetAllLandCells()
	for _ = 1, 100 do
		local cell = land[math.random(1, #land)]
		if cell:GetAttribute("OwnerKey") == "" then
			local occupiedNeighbor = false
			for _, neighbor in ipairs(MapService.GetNeighbors(cell)) do
				if neighbor:GetAttribute("OwnerKey") ~= "" then
					occupiedNeighbor = true
					break
				end
			end
			if not occupiedNeighbor then
				return cell
			end
		end
	end
	for _, cell in ipairs(land) do
		if cell:GetAttribute("OwnerKey") == "" then
			return cell
		end
	end
	return nil
end

local function maybeBuild(state)
	if math.random() > Config.Bot.BuildChance then
		return
	end
	local owned = MapService.GetOwnedCells(state.Key)
	if #owned == 0 then
		return
	end
	local order = {"Factory", "City", "Defense", "Port"}
	for _, buildingType in ipairs(order) do
		local def = Config.Buildings[buildingType]
		if state.Gold >= def.Cost and state.Buildings[buildingType] < def.Max then
			for _ = 1, 10 do
				local cell = owned[math.random(1, #owned)]
				if cell:GetAttribute("BuildingType") == "" then
					if not def.RequiresCoast or MapService.IsCoastal(cell) then
						TerritoryService.Build(state, cell, buildingType)
						return
					end
				end
			end
		end
	end
end

local function actBot(state)
	if state.Eliminated or not state.CapitalCell then
		return
	end
	maybeBuild(state)

	local frontier = MapService.GetFrontierCandidates(state.Key)
	if #frontier == 0 then
		return
	end

	local neutral = {}
	local enemies = {}
	for _, cell in ipairs(frontier) do
		if cell:GetAttribute("OwnerKey") == "" then
			table.insert(neutral, cell)
		else
			table.insert(enemies, cell)
		end
	end

	local target
	if #neutral > 0 and (state.Troops < 180 or math.random() < 0.72) then
		target = neutral[math.random(1, #neutral)]
	elseif #enemies > 0 and state.Troops >= Config.Territory.AttackMinTroops * 3 then
		target = enemies[math.random(1, #enemies)]
	elseif #neutral > 0 then
		target = neutral[math.random(1, #neutral)]
	end

	if target then
		local roll = math.random()
		if roll < 0.15 then
			NationService.SetSelectedPercent(state, 0.50)
		elseif roll < 0.35 then
			NationService.SetSelectedPercent(state, 0.35)
		else
			NationService.SetSelectedPercent(state, 0.25)
		end
		TerritoryService.Act(state, target)
	end
end

function BotService.Init(config, mapService, nationService, territoryService)
	Config = config
	MapService = mapService
	NationService = nationService
	TerritoryService = territoryService
end

function BotService.Start()
	task.spawn(function()
		task.wait(2)
		for i = 1, Config.Bot.Count do
			local color = Color3.fromHSV(((i * 0.083) % 1), 0.58, 0.92)
			local bot = NationService.CreateBot(botNames[i] or ("Comandante " .. i), color)
			local spawnCell = pickSpawnCell()
			if spawnCell then
				TerritoryService.ClaimStart(bot, spawnCell)
			end
		end

		while true do
			task.wait(Config.Bot.ActionInterval)
			for _, state in ipairs(NationService.GetAllStates()) do
				if state.IsBot then
					actBot(state)
				end
			end
		end
	end)
end

return BotService
