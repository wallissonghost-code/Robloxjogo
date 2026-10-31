-- Mundial War · one reciprocal conflict per pair of nations, regardless of click location.
-- All losses are applied before territorial conquest in the same simulation tick.
-- This module does not alter land ownership, reserves, or individual cell costs.
local FrontlineService = {}

local ctx

function FrontlineService.init(context)
	ctx = context
end

function FrontlineService.reset()
	-- Stateless: live orders belong exclusively to ExpansionService.
end

function FrontlineService.tick()
	if not ctx.Match.isPlaying() then return end
	local orders = ctx.Expansion.activeOrders()
	local directed = {}
	for _, o in ipairs(orders) do
		if not o.done and o.target > 0 and o.troops > 0
			and ctx.Nations.alive(o.nation) and ctx.Nations.alive(o.target)
			and ctx.Diplomacy.canAttack(o.nation, o.target) then
			directed[o.nation .. ":" .. o.target] = o
		end
	end

	for _, a in ipairs(orders) do
		if not a.done and a.target > a.nation then
			local b = directed[a.target .. ":" .. a.nation]
			if b and not b.done and a.troops > 0 and b.troops > 0 then
				local lossA, lossB = ctx.Combat.frontlineClash(a, b)
				a.troops = math.max(0, a.troops - lossA)
				b.troops = math.max(0, b.troops - lossB)
				-- The losing army must not capture a single cell after the clash.
				-- The winner remains in the same order, direction, and wavefront.
				if a.troops < 0.000001 then a.troops, a.done = 0, true end
				if b.troops < 0.000001 then b.troops, b.done = 0, true end
			end
		end
	end
end

return FrontlineService
