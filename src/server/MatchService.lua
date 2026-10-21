-- Central bounded scheduler. Step has no Roblox dependency and never yields.
local MatchService = {}
MatchService.__index = MatchService

function MatchService.new(nations, economy, expansion, config)
    return setmetatable({Nations = nations, Economy = economy, Expansion = expansion,
        Config = config, _economyTime = 0, _expansionTime = 0}, MatchService)
end

function MatchService:Step(seconds)
    if type(seconds) ~= "number" or seconds ~= seconds or seconds <= 0 or seconds == math.huge then return nil end
    local elapsed = math.min(seconds, self.Config.MaxElapsed)
    self._economyTime = self._economyTime + elapsed
    self._expansionTime = math.min(self._expansionTime + elapsed,
        self.Config.ExpansionInterval * self.Config.MaxCatchUpPulses)
    local changed, cells = {}, {}
    if self._economyTime >= self.Config.EconomyInterval then
        local steps = math.floor(self._economyTime / self.Config.EconomyInterval)
        local duration = steps * self.Config.EconomyInterval
        self._economyTime = self._economyTime - duration
        -- Claims in this batch only increase income for later economy ticks.
        self.Economy:Step(self.Nations, duration, changed)
    end
    while self._expansionTime >= self.Config.ExpansionInterval do
        self._expansionTime = self._expansionTime - self.Config.ExpansionInterval
        self.Expansion:Step(changed, cells)
    end
    return self.Nations:Publish(changed, cells)
end

return MatchService
