-- Pure Lua/Luau terrain topology: no Instances, physics, remotes or ownership.
local MapGrid = {}
MapGrid.__index = MapGrid

local function integer(value)
    return type(value) == "number" and value == value
        and value > -math.huge and value < math.huge and value % 1 == 0
end

local function inside(x, y, points)
    local hit = false
    local previous = points[#points]
    for _, point in ipairs(points) do
        if (point[2] > y) ~= (previous[2] > y) then
            local crossing = (previous[1] - point[1]) * (y - point[2])
                / (previous[2] - point[2]) + point[1]
            if x < crossing then hit = not hit end
        end
        previous = point
    end
    return hit
end

function MapGrid.new(config, definition)
    assert(integer(config.Width) and config.Width > 0, "Invalid map width")
    assert(integer(config.Height) and config.Height > 0, "Invalid map height")
    assert(integer(config.ChunkSize) and config.ChunkSize > 0, "Invalid chunk size")
    assert(config.MaxLongitude > config.MinLongitude, "Invalid longitude bounds")
    assert(config.MaxLatitude > config.MinLatitude, "Invalid latitude bounds")
    local self = setmetatable({
        Width = config.Width, Height = config.Height, ChunkSize = config.ChunkSize,
        Version = config.Version, LandIds = {}, LandCount = 0,
        _land = {}, _coastal = {}, _neighbors = {}, _config = config,
    }, MapGrid)

    -- Rasterize only each polygon's bounding box, once at startup.
    local function rasterize(polygons, value)
        for _, polygon in ipairs(polygons) do
            local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
            for _, point in ipairs(polygon.Points) do
                local gx, gy = self:Project(point[1], point[2])
                minX, maxX = math.min(minX, gx), math.max(maxX, gx)
                minY, maxY = math.min(minY, gy), math.max(maxY, gy)
            end
            for y = math.max(1, math.floor(minY) + 1), math.min(self.Height, math.ceil(maxY)) do
                for x = math.max(1, math.floor(minX) + 1), math.min(self.Width, math.ceil(maxX)) do
                    local longitude, latitude = self:GeographicCenter(x, y)
                    if inside(longitude, latitude, polygon.Points) then
                        self._land[self:ToId(x, y)] = value
                    end
                end
            end
        end
    end
    rasterize(definition.Land, true)
    rasterize(definition.Water or {}, false)
    for id = 1, self.Width * self.Height do
        if self._land[id] then
            self.LandIds[#self.LandIds + 1] = id
            local x, y = self:ToCoordinates(id)
            local neighbors = {}
            local coastal = false
            for _, offset in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
                local other = self:ToId(x + offset[1], y + offset[2])
                if other and self._land[other] then
                    neighbors[#neighbors + 1] = other
                else
                    coastal = true
                end
            end
            self._neighbors[id] = neighbors -- dense: never iterate sparse arrays with ipairs
            self._coastal[id] = coastal
        end
    end
    self.LandCount = #self.LandIds
    return self
end

function MapGrid:ToId(x, y)
    if not integer(x) or not integer(y) or x < 1 or y < 1 or x > self.Width or y > self.Height then
        return nil
    end
    return (y - 1) * self.Width + x
end

function MapGrid:ToCoordinates(id)
    if not integer(id) or id < 1 or id > self.Width * self.Height then return nil end
    return (id - 1) % self.Width + 1, math.floor((id - 1) / self.Width) + 1
end

function MapGrid:Project(longitude, latitude)
    local c = self._config
    return (longitude - c.MinLongitude) / (c.MaxLongitude - c.MinLongitude) * self.Width,
        (c.MaxLatitude - latitude) / (c.MaxLatitude - c.MinLatitude) * self.Height
end

function MapGrid:GeographicCenter(x, y)
    local c = self._config
    return c.MinLongitude + (x - 0.5) / self.Width * (c.MaxLongitude - c.MinLongitude),
        c.MaxLatitude - (y - 0.5) / self.Height * (c.MaxLatitude - c.MinLatitude)
end

function MapGrid:IsLand(id)
    return self:ToCoordinates(id) ~= nil and self._land[id] == true
end

function MapGrid:IsCoastal(id)
    return self:IsLand(id) and self._coastal[id] == true
end

-- Returned neighbor lists are read-only by convention; never insert/remove entries.
function MapGrid:GetNeighbors(id)
    return self:IsLand(id) and self._neighbors[id] or {}
end

function MapGrid:GetChunkId(id)
    local x, y = self:ToCoordinates(id)
    if not x then return nil end
    local columns = math.ceil(self.Width / self.ChunkSize)
    return math.floor((y - 1) / self.ChunkSize) * columns
        + math.floor((x - 1) / self.ChunkSize) + 1
end

-- Merge identical horizontal spans on consecutive rows, within each chunk.
-- Future ownership changes can rebuild one chunk instead of the whole world.
function MapGrid:GetLandRectangles(chunkId, owners)
    local columns = math.ceil(self.Width / self.ChunkSize)
    local rows = math.ceil(self.Height / self.ChunkSize)
    if not integer(chunkId) or chunkId < 1 or chunkId > columns * rows then return {} end
    local x0 = ((chunkId - 1) % columns) * self.ChunkSize + 1
    local y0 = math.floor((chunkId - 1) / columns) * self.ChunkSize + 1
    local x1 = math.min(x0 + self.ChunkSize - 1, self.Width)
    local y1 = math.min(y0 + self.ChunkSize - 1, self.Height)
    local rectangles, previous = {}, {}
    for y = y0, y1 do
        local current, x = {}, x0
        while x <= x1 do
            if self:IsLand(self:ToId(x, y)) then
                local startX = x
                local ownerId = owners and owners[self:ToId(x, y)]
                repeat x = x + 1 until x > x1 or not self:IsLand(self:ToId(x, y))
                    or (owners and owners[self:ToId(x, y)]) ~= ownerId
                local width = x - startX
                local key = startX .. ":" .. width .. ":" .. tostring(ownerId)
                local rectangle = previous[key]
                if rectangle then
                    rectangle.Height = rectangle.Height + 1
                else
                    rectangle = {X = startX, Y = y, Width = width, Height = 1, OwnerId = ownerId}
                    rectangles[#rectangles + 1] = rectangle
                end
                current[key] = rectangle
            else
                x = x + 1
            end
        end
        previous = current
    end
    return rectangles
end

return MapGrid
