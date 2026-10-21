-- Pure server economy. One batch per match tick, never a loop per cell/player.
local EconomyService = {}
EconomyService.__index = EconomyService

function EconomyService.new(config)
    return setmetatable({Config = config}, EconomyService)
end

function EconomyService:Recalculate(nation)
    local c, cells = self.Config, nation.TerritoryCount
    nation.MaxTroops = c.BaseTroopCapacity + cells * c.CapacityPerCell
    nation.TroopsPerSecond = c.BaseTroopsPerSecond + cells * c.TroopsPerCell
    nation.GoldPerSecond = c.BaseGoldPerSecond + cells * c.GoldPerCell
end

function EconomyService:Initialize(nation)
    self:Recalculate(nation)
    nation.Troops = math.min(self.Config.StartingTroops, nation.MaxTroops)
    nation.Gold = self.Config.StartingGold
    nation.ExpansionActive, nation.ExpansionRemaining, nation.ExpansionClaimed = false, 0, 0
end

function EconomyService:Step(nations, seconds, changed)
    nations:ForEachState(function(nation)
        local reserveCapacity = math.max(0, nation.MaxTroops - (nation.ExpansionRemaining or 0))
        local troops = math.min(reserveCapacity, nation.Troops + nation.TroopsPerSecond * seconds)
        local gold = math.min(self.Config.MaxGold, nation.Gold + nation.GoldPerSecond * seconds)
        if troops ~= nation.Troops or gold ~= nation.Gold then
            nation.Troops, nation.Gold = troops, gold
            changed[nation.Id] = true
        end
    end)
end

return EconomyService
