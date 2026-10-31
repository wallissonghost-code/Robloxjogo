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

-- Several geographically scoped orders can now attack the SAME enemy.
-- Resolve every reciprocal force once, not only the last one in a dictionary.
-- Field losses are still applied before any territory changes in this tick.
function FrontlineService.tick()
	if not ctx.Match.isPlaying() then return end
	local orders = ctx.Expansion.activeOrders()
	local directed = {}
	for _, o in ipairs(orders) do
		if not o.done and o.target > 0 and o.troops > 0
			and ctx.Nations.alive(o.nation) and ctx.Nations.alive(o.target)
			and ctx.Diplomacy.canAttack(o.nation, o.target) then
			local key = o.nation .. ":" .. o.target
			local list = directed[key]
			if not list then
				list = {}
				directed[key] = list
			end
			list[#list + 1] = o
		end
	end

	for _, a in ipairs(orders) do
		if not a.done and a.target > a.nation and a.troops > 0 then
			local enemies = directed[a.target .. ":" .. a.nation]
			if enemies then
				for _, b in ipairs(enemies) do
					if a.troops <= 0 then break end
					if not b.done and b.troops > 0 then
						local lossA, lossB = ctx.Combat.frontlineClash(a, b)
						a.troops = math.max(0, a.troops - lossA)
						b.troops = math.max(0, b.troops - lossB)
						if a.troops < 0.000001 then a.troops, a.done = 0, true end
						if b.troops < 0.000001 then b.troops, b.done = 0, true end
					end
				end
			end
		end
	end
end

return FrontlineService
