-- Regression: no island-to-island teleport, no free enclave repair,
-- and retreat cancels troop ships BEFORE they can land.
local H = dofile("tests/lua/helpers.lua")
local ok = H.ok

local rows = {}
for y = 0, 10 do
	if y == 0 or y == 10 then
		rows[#rows + 1] = string.rep(".", 49)
	else
		rows[#rows + 1] = "." .. string.rep("A", 16)
			.. string.rep(".", 12) .. string.rep("B", 12) .. string.rep(".", 8)
	end
end
local map = H.asciiMap(rows)
local cfg = H.configWith({
	Bots = { Nations = 0, Tribes = 0 },
	Spawn = { MinCapitalDistance = 8 },
})
local function cell(ctx, x, y) return ctx.Map:index(x, y) end
local function fresh()
	local world, ctx = H.newWorld({ mapData = map, Config = cfg })
	world:step(0.1, 1)
	local a = assert(ctx.Nations.create("player", "Player", cell(ctx, 5, 5), { userId = 1 }))
	ctx.Match.startPlaying()
	return world, ctx, a
end

-- The sea invasion has a separate landmass ID from the player's main base.
do
	local world, ctx, a = fresh()
	local island = cell(ctx, 30, 5)
	local mainlandNeutral = cell(ctx, 13, 5)
	ok(ctx.Landmass[island] ~= ctx.Landmass[mainlandNeutral],
		"left and right islands have distinct geographical ids")
	ok(ctx.Territory.ownerOf(mainlandNeutral) == 0, "some land remains on original island")
	ctx.Territory.setOwner(island, a.id) -- simulate the naval beachhead
	a.troops = 1000
	local order = ctx.Expansion.start(a.id, 0, island, 4000, { fromLanding = true })
	ok(order.mass == ctx.Landmass[island] and order.originCell == island,
		"naval order is fixed to its beachhead landmass and source")
	H.run(world, 10, 1)
	ok(ctx.Territory.ownerOf(mainlandNeutral) == 0,
		"finished beachhead cannot expand back on the original island")
	ok(#ctx.Expansion.ordersOf(a.id) == 0,
		"beachhead order ends when its own island is conquered")
	ok(a.troops > 1000, "surviving amphibious troops returned to reserves")
end
print("PASS beachhead never jumps to disconnected neutral land")

-- Independent neutral fronts do not merge just because target owner is 0.
do
	local world, ctx, a = fresh()
	local island = cell(ctx, 30, 5)
	local other = cell(ctx, 13, 5)
	ctx.Territory.setOwner(island, a.id)
	ctx.Territory.setOwner(other, a.id)
	a.troops = 20000
	local distant = ctx.Expansion.start(a.id, 0, island, 1000, { fromLanding = true })
	local nearer = ctx.Expansion.start(a.id, 0, other, 1000, { fromLanding = true })
	ok(distant.id ~= nearer.id and distant.mass ~= nearer.mass,
		"landings on distinct islands must use separate military orders")
	ok(#ctx.Expansion.ordersOf(a.id) == 2, "two independent orders can coexist")
	ctx.Expansion.cancel(a.id)
	ok(#ctx.Expansion.ordersOf(a.id) == 0, "retreat cancels both local fronts")
end
print("PASS multiple neutral fronts never merge across islands")

-- A nuclear crater or any enclosed neutral hole stays damaged until troops
-- explicitly conquer it. No periodic free fill after 3 or 6 seconds.
do
	local world, ctx, a = fresh()
	for y = 2, 8 do
		for x = 2, 13 do
			ctx.Territory.setOwner(cell(ctx, x, y), a.id)
		end
	end
	local crater = cell(ctx, 9, 5)
	ctx.Territory.setOwner(crater, 0)
	H.run(world, 9, 1)
	ok(ctx.Territory.ownerOf(crater) == 0,
		"nuclear crater must remain neutral without an explicit troop order")
end
print("PASS neutral bomb craters never self-heal")

-- The Cancel action must stop sailing armies as well as terrestrial orders.
do
	local world, ctx, a = fresh()
	a.troops, a.gold = 25000, 100000
	local port = cell(ctx, 16, 5)
	local shore = cell(ctx, 29, 5)
	ctx.Territory.setOwner(port, a.id)
	local built, buildReason = ctx.Buildings.build(a.id, port, "port")
	ok(built, "departure port built: " .. tostring(buildReason))
	local launched, launchReason = ctx.Naval.launch(a.id, shore, 0.5)
	ok(launched, "invasion route launched: " .. tostring(launchReason))
	local fleet = ctx.Naval.fleets()[1]
	ok(fleet and fleet.troops > 0, "transport sailing with troops")
	local troopCount = a.troops
	local survivors = math.floor(fleet.troops)
	local canceled, message = ctx.Commands.handle(1, "Player", "cancel")
	ok(canceled, "HUD retreat command accepted: " .. tostring(message))
	ok(#ctx.Naval.fleets() == 0, "transport removed immediately on retreat")
	ok(a.troops == troopCount + survivors,
		"troops in transit returned to reserve without duplication")
	H.run(world, 12, 1)
	ok(ctx.Territory.ownerOf(shore) == 0,
		"cancelled ship cannot land and restart the invasion later")
	ok(#ctx.Expansion.ordersOf(a.id) == 0,
		"cancelled transport does not spawn a new terrestrial order")
end
print("PASS retreat stops all troop transports and prevents delayed landings")
