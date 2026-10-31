-- Real server regression: troop transports sail from a port through water,
-- slow down, leave their final position on the coastline, and trigger landing.
local H = dofile("tests/lua/helpers.lua")
local ok = H.ok

local rows = {}
for y = 0, 11 do
	if y == 0 or y == 11 then
		rows[#rows + 1] = string.rep(".", 49)
	else
		rows[#rows + 1] = "." .. string.rep("A", 19) .. string.rep(".", 9)
			.. string.rep("B", 19) .. "."
	end
end
local cfg = H.configWith({
	Bots = { Nations = 0, Tribes = 0 },
	Spawn = { MinCapitalDistance = 8 },
})
local world, ctx = H.newWorld({ mapData = H.asciiMap(rows), Config = cfg })
world:step(0.1, 1)
local function cell(x, y) return ctx.Map:index(x, y) end
local a = assert(ctx.Nations.create("player", "Transport", cell(17, 5), { userId = 1 }))
local b = assert(ctx.Nations.create("bot", "Defender", cell(30, 5)))
ctx.Match.startPlaying()
a.troops, a.gold = 30000, 100000
local port = cell(19, 5)
local coast = cell(29, 5)
local built, reason = ctx.Commands.handle(1, "Transport", "build", port, "port", 1)
ok(built, "build departure port: " .. tostring(reason))
local waterPath, departure = ctx.Naval.route(a.id, coast)
ok(waterPath and #waterPath > 1, "valid water-only route exists")
ok(departure == port, "route remembers the actual departure port")
for _, i in ipairs(waterPath) do
	ok(not ctx.Map.land[i], "pathfinding remains on water")
end
local started, message = ctx.Naval.launch(a.id, coast, 0.75)
ok(started, "troop transport launched: " .. tostring(message))
local fleet = ctx.Naval.fleets()[1]
ok(fleet ~= nil and fleet.path[#fleet.path] == coast, "last navigation cell is the coast")
ok(fleet.path[1] == waterPath[1] and fleet.port == port,
	"fleet preserves water path and starting port")
ok(ctx.Config.Naval.Speed == 6 and ctx.Config.Naval.BoatSpeed == 9,
	"only troop transport speed changed")
local event
for _, entry in ipairs(ctx.outbox) do
	if entry.payload.fleet then event = entry.payload.fleet end
end
ok(event and event[7] == false and event[8] == port,
	"live order is serialized with port and contiguous fields")
local snapshot = ctx.Naval.snapshot()
ok(snapshot[1][1][9] == port, "late joining players receive port origin")
local travel = (#fleet.path - 1) / ctx.Config.Naval.Speed
H.run(world, math.max(0, travel - 0.4), 1)
ok(ctx.Territory.ownerOf(coast) == b.id, "landing cannot resolve early")
H.run(world, travel + 1, 1)
ok(ctx.Territory.ownerOf(coast) == a.id, "coast conquered when transport reaches it")
print("PASS port-linked naval transport, slower speed and coastal landing")
