-- Server-side entry point for geography. Ownership will belong to NationService.
-- Keeping this separate from terrain rendering prevents client visuals becoming authority.
local MapService = {}
MapService.__index = MapService

function MapService.new(grid)
    assert(grid.LandCount > 0, "The world must contain land")
    return setmetatable({Grid = grid}, MapService)
end

function MapService:IsValidLandCell(id)
    return self.Grid:IsLand(id)
end

function MapService:GetCell(id)
    if not self:IsValidLandCell(id) then return nil end
    local x, y = self.Grid:ToCoordinates(id)
    return {Id = id, X = x, Y = y, Coastal = self.Grid:IsCoastal(id), ChunkId = self.Grid:GetChunkId(id)}
end

function MapService:AreAdjacent(first, second)
    if not self:IsValidLandCell(first) or not self:IsValidLandCell(second) then return false end
    for _, id in ipairs(self.Grid:GetNeighbors(first)) do
        if id == second then return true end
    end
    return false
end

return MapService
