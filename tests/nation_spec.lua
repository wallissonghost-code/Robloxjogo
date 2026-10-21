local Config = dofile("src/shared/Config.lua")
local grid = dofile("src/shared/MapGrid.lua").new(Config.Map, dofile("src/shared/WorldDefinition.lua"))
local map = dofile("src/server/MapService.lua").new(grid)
local NationService = dofile("src/server/NationService.lua")
local CommandService = dofile("src/server/CommandService.lua")
local Replica = dofile("src/client/NationReplica.lua")
local checks = 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local nations = NationService.new(map, Config.Nations)
local a, b, c = grid.LandIds[100], grid.LandIds[200], grid.LandIds[300]
local sea
for id = 1, grid.Width * grid.Height do if not grid:IsLand(id) then sea = id; break end end
for _, id in ipairs({sea, -1, 0, 0/0, math.huge, "100", {}, false, 1.1}) do
    local delta, code = nations:Create(1, "Player 1", id)
    check(delta == nil and code == "InvalidLand", "Rejected malformed/water position")
end
check(nations:Create(1, "Player 1", nil) == nil, "Reject nil")
check(nations.Revision == 0 and #nations:Snapshot().Cells == 0, "Rejected commands cannot mutate")

local before = nations:Snapshot()
local delta = assert(nations:Create(1, "Player 1", a))
check(nations:GetOwner(a) == 1 and nations:GetNation(1).CapitalId == a, "Capital ownership")
local duplicate, code = nations:Create(1, "Player 1", b)
check(not duplicate and code == "AlreadyFounded" and not nations:GetOwner(b), "Second capital rejected")
local rival, occupied = nations:Create(2, "Player 2", a)
check(not rival and occupied == "Occupied", "Only one winner for simultaneous target")
check(nations.Revision == 1, "No revision for rejected transaction")
check(#before.Cells == 0 and #before.Nations == 0, "Snapshots are independent")
local external = nations:GetNation(1)
external.Color[1] = -999; external.CapitalId = b
check(nations:GetNation(1).Color[1] > 0 and nations:GetNation(1).CapitalId == a, "Public records cannot mutate state")
local delta2 = assert(nations:Create(2, "Player 2", b))
check(nations:GetNation(1).Color[1] ~= nations:GetNation(2).Color[1], "Different initial colors")

-- Late join, duplicate/out-of-order events and missed revision recovery.
local replica = Replica.new(grid)
local _, reason = replica:Apply(delta)
check(reason == "Resync" and not replica.Ready, "Require initial snapshot")
replica:Apply(before)
local dirty = replica:Apply(delta)
check(dirty[grid:GetChunkId(a)] and replica.Owners[a] == 1, "Initial ownership delta")
local dirtyCount = 0; for _ in pairs(dirty) do dirtyCount = dirtyCount + 1 end
check(dirtyCount == 1, "Only changed chunk invalidated")
check(select(2, replica:Apply(delta)) == "Stale", "Duplicate ignored")
replica:Apply(delta2)
local removal = nations:Remove(1)
local after = nations:Snapshot()
replica:Apply(removal)
check(replica.Owners[a] == nil and replica.Nations[1] == nil, "Leave clears color and marker")
check(nations:GetOwner(a) == nil and nations:Remove(1) == nil, "Leave idempotent")
replica:Apply(delta)
check(replica.Owners[a] == nil, "Delayed old message cannot resurrect nation")
local late = Replica.new(grid); late:Apply(after)
check(late.Owners[b] == 2 and late.Nations[2].CapitalId == b, "Late join sees existing nation")
check(nations:Create(0, "Studio", a) ~= nil and nations:GetOwner(a) == 0, "Studio ID zero supported")
local latest = assert(nations:Create(-1, "Studio 2", c))
check(select(2, replica:Apply(latest)) == "Resync" and replica.Owners[c] == nil, "Revision gap not applied")
replica:Apply(nations:Snapshot())
check(replica.Owners[a] == 0 and replica.Owners[c] == -1, "Snapshot repairs gap")

-- Reconstruct ownership-aware rectangles exactly, including owner zero.
local coverage = {}
for chunk = 1, math.ceil(grid.Width/grid.ChunkSize)*math.ceil(grid.Height/grid.ChunkSize) do
    for _, r in ipairs(grid:GetLandRectangles(chunk, replica.Owners)) do
        for y = r.Y, r.Y+r.Height-1 do for x = r.X, r.X+r.Width-1 do
            local id = grid:ToId(x,y)
            check(grid:IsLand(id) and not coverage[id], "Exact colored land coverage")
            check(r.OwnerId == replica.Owners[id], "No color bleeding between nations")
            coverage[id] = true
        end end
    end
end
for _, id in ipairs(grid.LandIds) do check(coverage[id], "No missing colored terrain") end

-- Gateway identity is supplied by transport, payload only chooses a cell.
local now = 0
local authority = NationService.new(map, Config.Nations)
local gateway = CommandService.new(authority, Config.Network, function() return now end)
check(gateway:Handle(12,"Actual player","Sync").Kind == "Snapshot", "Initial sync")
check(gateway:Handle(12,"Actual player","Sync") == nil, "Snapshot throttling")
local response, mutation = gateway:Handle(12,"Actual player","ChooseCapital",{OwnerId=99,Id=a},1)
check(response.Code == "InvalidLand" and not mutation, "Cannot inject identity in cell payload")
response, mutation = gateway:Handle(12,"Actual player","ChooseCapital",a,2)
check(response.Code == "Founded" and authority:GetOwner(a) == 12, "Gateway binds authenticated actor")
check(mutation.Revision == 1, "Gateway produces broadcast delta")
check(gateway:Handle(13,"Player","ChooseCapital",b,0/0) == nil, "NaN request ID rejected")
check(gateway:Handle(13,"Player","ChooseCapital",b,{}) == nil, "Object request ID rejected")
for i=1,100 do gateway:Handle(14,"Flood","Unknown",a,i) end
check(gateway:Handle(14,"Flood","ChooseCapital",b,101) == nil, "Flood is dropped")
check(authority:GetOwner(b) == nil, "Throttled command cannot mutate")
now = 3
check(gateway:Handle(14,"Flood","ChooseCapital",b,102).Code == "Founded", "Bucket refills")
check(gateway:Handle(12,"Actual player","Sync").Revision == 2, "Resync sees current server")
gateway:Forget(12)
check(gateway._limits[12] == nil, "Limiter cleanup")
authority:Remove(12)
check(gateway:Handle(12,"Returned player","ChooseCapital",a,1).Code == "Founded", "Rejoin after cleanup")
print(string.format("PASS: %d nation/network/replica checks",checks))
