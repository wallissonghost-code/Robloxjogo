-- Server-owned match state. No yields: validation + reservation are one transaction.
local NationService = {}
NationService.__index = NationService

local function validIdentity(id)
    -- Studio test players can have zero/negative IDs. Only the server supplies IDs.
    return type(id) == "number" and id == id and math.abs(id) < 2^53 and id % 1 == 0
end

local function publicNation(nation)
    return {Id = nation.Id, Name = nation.Name, CapitalId = nation.CapitalId,
        TerritoryCount = nation.TerritoryCount,
        Color = {nation.Color[1], nation.Color[2], nation.Color[3]}}
end

function NationService.new(map, config)
    assert(#config.Palette > 0, "A nation palette is required")
    return setmetatable({Map = map, Config = config, Revision = 0,
        _nations = {}, _owners = {}}, NationService)
end

function NationService:GetNation(userId)
    local nation = self._nations[userId]
    return nation and publicNation(nation) or nil
end

function NationService:GetOwner(cellId)
    if not self.Map:IsValidLandCell(cellId) then return nil end
    return self._owners[cellId]
end

function NationService:Create(userId, displayName, capitalId)
    if not validIdentity(userId) or type(displayName) ~= "string" then return nil, "InvalidIdentity" end
    if self._nations[userId] then return nil, "AlreadyFounded" end
    if not self.Map:IsValidLandCell(capitalId) then return nil, "InvalidLand" end
    if self._owners[capitalId] ~= nil then return nil, "Occupied" end

    local counts = {}
    for _, nation in pairs(self._nations) do
        counts[nation.PaletteIndex] = (counts[nation.PaletteIndex] or 0) + 1
    end
    local colorIndex = 1
    for i = 2, #self.Config.Palette do
        if (counts[i] or 0) < (counts[colorIndex] or 0) then colorIndex = i end
    end
    local color = self.Config.Palette[colorIndex]
    local nation = {Id = userId, Name = displayName, CapitalId = capitalId,
        TerritoryCount = 1, Cells = {[capitalId] = true}, PaletteIndex = colorIndex,
        Color = {color[1], color[2], color[3]}}
    self._nations[userId] = nation
    self._owners[capitalId] = userId
    self.Revision = self.Revision + 1
    return {Kind = "Delta", Revision = self.Revision,
        Nations = {publicNation(nation)}, RemovedNations = {},
        Cells = {{Id = capitalId, OwnerId = userId}}}, "Founded"
end

function NationService:Remove(userId)
    local nation = self._nations[userId]
    if not nation then return nil end
    local changes = {}
    for cellId in pairs(nation.Cells) do
        self._owners[cellId] = nil
        changes[#changes + 1] = {Id = cellId, OwnerId = false}
    end
    self._nations[userId] = nil
    self.Revision = self.Revision + 1
    return {Kind = "Delta", Revision = self.Revision,
        Nations = {}, RemovedNations = {userId}, Cells = changes}
end

function NationService:Snapshot()
    local nations, cells = {}, {}
    for _, nation in pairs(self._nations) do nations[#nations + 1] = publicNation(nation) end
    for cellId, ownerId in pairs(self._owners) do cells[#cells + 1] = {Id = cellId, OwnerId = ownerId} end
    table.sort(nations, function(a, b) return a.Id < b.Id end)
    table.sort(cells, function(a, b) return a.Id < b.Id end)
    return {Kind = "Snapshot", Revision = self.Revision, Nations = nations, Cells = cells}
end

return NationService
