-- Regression tests for wavefront expansion and reciprocal counter-attacks.
-- Run with: python3 tests/run_lua.py tests/lua/test_frontlines.lua
local H = dofile("tests/lua/helpers.lua")
local ok = H.ok
local rows = {}
for _ = 1, 21 do rows[#rows + 1] = string.rep("A", 64) end
local map = H.asciiMap(rows)
local cfg = H.configWith({ Bots = { Nations = 0, Tribes = 0 }, Spawn = { MinCapitalDistance = 8 } })

local function cell(ctx, x, y) return ctx.Map:index(x, y) end

-- The chosen clicks intentionally target different ends of the enemy's land.
-- The reciprocal clash must be global to the two orders, not localized to clicks.
local function opponents(troopsA, troopsB, reverse)
	local world, ctx = H.newWorld({ mapData = map, Config = cfg })
	world:step(0.1, 2)
	local a = assert(ctx.Nations.create("player", "A", cell(ctx, 6, 10), { userId = 1 }))
	local b = assert(ctx.Nations.create("player", "B", cell(ctx, 54, 10), { userId = 2 }))
	ctx.Match.startPlaying()
	for y = 4, 16 do
		for x = 4, 55 do
			local i = cell(ctx, x, y)
			if ctx.Territory.ownerOf(i) == 0 then
				ctx.Territory.setOwner(i, x <= 25 and a.id or b.id)
			end
		end
	end
	a.troops, b.troops = troopsA, troopsB
	local function orderA()
		local accepted, msg = ctx.Expansion.issue(a.id, cell(ctx, 47, 14), 1)
		ok(accepted, "A order accepted: " .. tostring(msg))
	end
	local function orderB()
		local accepted, msg = ctx.Expansion.issue(b.id, cell(ctx, 10, 6), 1)
		ok(accepted, "B order accepted: " .. tostring(msg))
	end
	if reverse then orderB() orderA() else orderA() orderB() end
	return world, ctx, a, b
end

for _, reversed in ipairs({ false, true }) do
	local world, ctx, a, b = opponents(20000, 10000, reversed)
	local aLand, bLand = a.land, b.land
	world:step(0.2, 2)
	local aOrders, bOrders = ctx.Expansion.ordersOf(a.id), ctx.Expansion.ordersOf(b.id)
	ok(#aOrders == 1 and #bOrders == 0, "20K counters 10K in either issue order")
	ok(aOrders[1].troops > 9000 and aOrders[1].troops < 10000,
		"10K survivors less the cost of the first conquered wave")
	ok(a.land > aLand and b.land < bLand, "winner advances toward the original chosen enemy area")
	ok(b.troops == 0, "no defender reserve magically absorbs deployed army")
end
print("PASS reciprocal 20K versus 10K, independent of clicks and issue order")

do
	local world, ctx, a, b = opponents(10000, 10000)
	local aLand, bLand = a.land, b.land
	world:step(0.2, 2)
	ok(#ctx.Expansion.ordersOf(a.id) == 0 and #ctx.Expansion.ordersOf(b.id) == 0,
		"equal opposite armies annihilate with no winners")
	ok(a.land == aLand and b.land == bLand, "no overlapping conquests after equal counter")
end
print("PASS equal armies mutually stop before a territory capture")

do
	local world, ctx, a, b = opponents(20000, 10000)
	local aOrders, bOrders = ctx.Expansion.ordersOf(a.id), ctx.Expansion.ordersOf(b.id)
	-- Third-party-independent defence does not change the click's target.
	ok(aOrders[1].target == b.id and bOrders[1].target == a.id, "orders remain directed at correct nations")
	ok(aOrders[1].anchor == cell(ctx, 47, 14), "A's original strategic click is retained")
end
print("PASS enemy-scoped counters preserve the chosen anchor")

do
	local world, ctx = H.newWorld({ mapData = map, Config = cfg })
	world:step(0.1, 1)
	local a = assert(ctx.Nations.create("player", "Wave", cell(ctx, 5, 10), { userId = 1 }))
	ctx.Match.startPlaying()
	for y = 5, 16 do
		for x = 4, 8 do
			local i = cell(ctx, x, y)
			if ctx.Territory.ownerOf(i) == 0 then ctx.Territory.setOwner(i, a.id) end
		end
	end
	a.troops = 25000
	local accepted, msg = ctx.Expansion.issue(a.id, cell(ctx, 60, 10), 1)
	ok(accepted, "neutral wave accepted: " .. tostring(msg))
	H.run(world, 2, 1)
	local width = 0
	for y = 0, 20 do
		if ctx.Territory.ownerOf(cell(ctx, 10, y)) == a.id then width = width + 1 end
	end
	ok(width >= 4, "wave is several cells wide, not a single corridor: " .. width)
	ctx.Territory.analyze(a.id)
	ok(a.labelSize == a.land, "wave remains connected to the original territory")
end
print("PASS broad directional wave and connected land")

-- The directional wave also recruits flanking segments of an extended border.
do
	local wider = {}
	for _ = 1, 54 do wider[#wider + 1] = string.rep("A", 90) end
	local broadMap = H.asciiMap(wider)
	local world, ctx = H.newWorld({ mapData = broadMap, Config = cfg })
	world:step(0.1, 1)
	local a = assert(ctx.Nations.create("player", "Fan", cell(ctx, 5, 26), { userId = 1 }))
	ctx.Match.startPlaying()
	for y = 3, 50 do
		for x = 4, 8 do
			local i = cell(ctx, x, y)
			if ctx.Territory.ownerOf(i) == 0 then ctx.Territory.setOwner(i, a.id) end
		end
	end
	a.troops = 60000
	ok(ctx.Expansion.issue(a.id, cell(ctx, 75, 26), 1), "broad wave accepted")
	local order = ctx.Expansion.ordersOf(a.id)[1]
	local initialRadius = order.waveSeedRadius
	H.run(world, 5, 1)
	local farthestSide = 0
	for y = 0, 53 do
		if ctx.Territory.ownerOf(cell(ctx, 9, y)) == a.id then
			farthestSide = math.max(farthestSide, math.abs(y - 26))
		end
	end
	ok(farthestSide > initialRadius + 1, "wave recruits lateral border as it spreads: " .. farthestSide)
	ctx.Territory.analyze(a.id)
	ok(a.labelSize == a.land, "widened territory remains connected")
end
print("PASS lateral fan growth and connectivity")

-- Defence notifications communicate incoming threats without emoji prefixes.
do
	local world, ctx, a, b = opponents(20000, 10000)
	local found = false
	for _, entry in ipairs(ctx.outbox) do
		if entry.to == b.id and entry.payload.kind == "defense" then
			found = entry.payload.text:find("está atacando", 1, true) ~= nil
		end
	end
	ok(found, "defender receives explicit red incoming-attack notice")
end
print("PASS combat alert status")
