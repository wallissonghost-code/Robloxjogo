-- Run from repository root: lua tests/map_spec.lua (Lua 5.4 or Luau-compatible runner).
local Config = dofile("src/shared/Config.lua")
local Definition = dofile("src/shared/WorldDefinition.lua")
local MapGrid = dofile("src/shared/MapGrid.lua")
local MapService = dofile("src/server/MapService.lua")
local grid = MapGrid.new(Config.Map, Definition)
local service = MapService.new(grid)
local checks = 0
local function check(condition, message)
    checks = checks + 1
    assert(condition, message)
end

check(grid.LandCount > 6000 and grid.LandCount < 14000, "Unexpected land coverage")
for _, value in ipairs({0, -1, 1.5, "1", false, math.huge, -math.huge, 0/0, grid.Width * grid.Height + 1}) do
    check(not grid:IsLand(value), "Untrusted ID was accepted")
    check(service:GetCell(value) == nil, "Invalid cell metadata")
    check(not service:AreAdjacent(value, grid.LandIds[1]), "Invalid adjacency")
end
check(not grid:IsLand(nil), "nil ID accepted")
check(grid:ToId(0, 1) == nil and grid:ToId(241, 1) == nil, "Horizontal wrapping")
check(grid:ToId(1, 0) == nil and grid:ToId(1, 121) == nil, "Vertical wrapping")

for id = 1, grid.Width * grid.Height do
    local x, y = grid:ToCoordinates(id)
    check(grid:ToId(x, y) == id, "Cell round trip")
    if grid:IsLand(id) then
        local neighbors = grid:GetNeighbors(id)
        check(grid:IsCoastal(id) == (#neighbors < 4), "Coastal classification")
        for _, other in ipairs(neighbors) do
            local ox, oy = grid:ToCoordinates(other)
            check(math.abs(x - ox) + math.abs(y - oy) == 1, "Non-cardinal neighbor")
            check(grid:IsLand(other), "Water neighbor included")
            check(service:AreAdjacent(other, id), "Asymmetric adjacency")
        end
    end
end

local function at(longitude, latitude)
    local x, y = grid:Project(longitude, latitude)
    return grid:IsLand(grid:ToId(math.floor(x) + 1, math.floor(y) + 1))
end
for _, p in ipairs({{-100,40},{-102,57},{-64,-15},{-64,-40},{10,51},{20,3},{25,-25},{90,55},{105,32},{78,20},{135,-25},{47,-19},{-42,73},{-3,55},{140,37},{113,0},{169,-44}}) do
    check(at(p[1],p[2]), "Missing major landmass at " .. p[1] .. "," .. p[2])
end
for _, p in ipairs({{-140,0},{-30,0},{70,-30},{0,-50},{-86,59},{15,35},{155,-35}}) do
    check(not at(p[1],p[2]), "Unexpected land at " .. p[1] .. "," .. p[2])
end

-- Exact renderer reconstruction: no overlaps, missing cells or painted oceans.
local covered, rectangleCount = {}, 0
local chunkCount = math.ceil(grid.Width / grid.ChunkSize) * math.ceil(grid.Height / grid.ChunkSize)
for chunk = 1, chunkCount do
    for _, rectangle in ipairs(grid:GetLandRectangles(chunk)) do
        rectangleCount = rectangleCount + 1
        for y = rectangle.Y, rectangle.Y + rectangle.Height - 1 do
            for x = rectangle.X, rectangle.X + rectangle.Width - 1 do
                local id = grid:ToId(x, y)
                check(grid:IsLand(id), "Renderer painted water")
                check(not covered[id], "Renderer overlap")
                check(grid:GetChunkId(id) == chunk, "Rectangle crossed chunk")
                covered[id] = true
            end
        end
    end
end
for _, id in ipairs(grid.LandIds) do check(covered[id], "Renderer missed land") end
check(rectangleCount < grid.LandCount / 4, "Terrain merging ineffective")

-- Determinism: independent server/client generation must agree.
local second = MapGrid.new(Config.Map, Definition)
check(second.LandCount == grid.LandCount, "Land count differs")
for i, id in ipairs(grid.LandIds) do check(second.LandIds[i] == id, "Terrain differs") end

-- Regression: a missing eastern neighbor must not hide later neighbors (ipairs holes).
local tiny = MapGrid.new({Width=3, Height=3, ChunkSize=2, Version=1,
    MinLongitude=0, MaxLongitude=3, MinLatitude=0, MaxLatitude=3}, {
    Land={{Points={{0,0},{2,0},{2,3},{0,3}}}}, Water={},
})
local edge = tiny:ToId(2,2)
check(#tiny:GetNeighbors(edge) == 3, "Sparse neighbor regression")
check(#tiny:GetLandRectangles(0) == 0, "Invalid chunk accepted")

print(string.format("PASS: %d checks; %d land cells; %d rectangles; %d chunks", checks, grid.LandCount, rectangleCount, chunkCount))
