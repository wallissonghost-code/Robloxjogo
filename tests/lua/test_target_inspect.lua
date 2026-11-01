-- Inspect routes for the delayed diplomacy card without launching an attack.
-- Run with: python3 tests/run_lua.py tests/lua/test_target_inspect.lua
local H = dofile("tests/lua/helpers.lua")
local ok = H.ok
local rows = {}
for y = 0, 10 do
	if y == 0 or y == 10 then
		rows[#rows + 1] = string.rep(".", 60)
	else
		rows[#rows + 1] = "." .. string.rep("A", 25)
			.. string.rep(".", 10) .. string.rep("B", 14)
			.. string.rep(".", 10)
	end
end
local cfg = H.configWith({
	Bots = { Nations = 0, Tribes = 0 },
	Spawn = { MinCapitalDistance = 8 },
})
local world, ctx = H.newWorld({ mapData = H.asciiMap(rows), Config = cfg })
world:step(0.1, 2)
local cell = function(x, y) return ctx.Map:index(x, y) end
local a = assert(ctx.Nations.create("player", "Player", cell(5, 5), { userId = 1 }))
local b = assert(ctx.Nations.create("player", "Enemy", cell(16, 5), { userId = 2 }))
ctx.Match.startPlaying()

local function inspect(target, requestId, t)
	local accepted, msg = ctx.Commands.handle(1, "Player",
		ctx.Protocol.Actions.InspectTarget, target, requestId, t)
	ok(accepted and msg == nil, "silent route inspection accepted")
	local last = nil
	for _, event in ipairs(world:drainOutbox()) do
		if event.payload.k == ctx.Protocol.Events.TargetAccess then
			last = event
		end
	end
	ok(last and last.to == a.id, "only inspecting nation receives route result")
	ok(last.payload.cell == target and last.payload.requestId == requestId,
		"response identifies clicked cell and request to discard stale results")
	ok(last.payload.owner == b.id, "response identifies current target owner")
	return last.payload
end

-- First inland enemy has no land connection and cannot be accessed by boat.
local inland = cell(16, 5)
local r = inspect(inland, 1, 100)
ok(r.access == "blocked" and r.reason, "non-border, inland attack button must be disabled")
ok(ctx.Diplomacy.relation(a.id, b.id) == "neutral",
	"inspecting a nation does not start a war")
ok(#ctx.Expansion.ordersOf(a.id) == 0, "inspection spends no troops or orders")
print("PASS remote inland attack is marked inaccessible")

-- One adjacent captured square is enough to open a genuine land front.
ctx.Territory.setOwner(cell(15, 5), a.id)
r = inspect(inland, 2, 100.4)
ok(r.access == "land" and not r.reason, "actual land border authorizes ATACAR")
print("PASS connected enemy front is a terrestrial attack")

-- Remote coast is blocked until a usable port exists.
local shore = cell(36, 5)
ctx.Territory.setOwner(shore, b.id)
r = inspect(shore, 3, 100.8)
ok(r.access == "blocked" and r.reason:find("porto", 1, true),
	"coast without owned port is inaccessible")
a.gold = 100000
ctx.Territory.setOwner(cell(25, 5), a.id)
local built, why = ctx.Buildings.build(a.id, cell(25, 5), "port")
ok(built, "coastal port built: " .. tostring(why))
local gold, troops = a.gold, a.troops
local relation = ctx.Diplomacy.relation(a.id, b.id)
r = inspect(shore, 4, 101.2)
ok(r.access == "naval" and not r.reason, "water-connected port authorizes INVADIR POR MAR")
ok(a.gold == gold and a.troops == troops,
	"route preview is read-only: no transport purchase or troop commitment")
ok(ctx.Diplomacy.relation(a.id, b.id) == relation,
	"route preview cannot declare war")
ok(#ctx.Naval.fleets() == 0, "preview never launches a naval fleet")
print("PASS valid coast is identified as a naval attack, without side effects")

-- Neither the requester nor the server may bypass the preview rate limit.
local allowed = ctx.Commands.handle(1, "Player",
	ctx.Protocol.Actions.InspectTarget, shore, 5, 101.25)
ok(not allowed, "repeated route query is throttled for performance")
ok(#world:drainOutbox() == 0, "throttled query produces no reply")

-- Ally access must be disabled even if the nations already touch.
ok(ctx.Diplomacy.requestAlliance(a.id, b.id), "alliance request sent")
ok(ctx.Diplomacy.requestAlliance(b.id, a.id), "alliance accepted")
r = inspect(inland, 6, 101.7)
ok(r.access == "blocked", "allied nation cannot be attacked")
print("PASS ally preview blocked and repeated queries throttled")
