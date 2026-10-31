-- Mundial War · connected wavefront expansion; combat between opposing orders happens
-- before this service's tick in FrontlineService.
-- Each order keeps a multi-source wave depth over cells it actually controls.
-- Lowest depth goes first: width is established at launch, and click direction
-- only breaks ties inside the same wave layer. No conquest through water or
-- disconnected target territory.
local ExpansionService = {}

local ctx, Config, Map, Territory
local orders = {}          -- list of active orders
local nextOrderId = 1
local candidates, scores, depths = {}, {}, {}
local scratch = {}

function ExpansionService.init(context)
	ctx = context
	Config = ctx.Config
	Map = ctx.Map
	Territory = ctx.Territory
end

function ExpansionService.reset()
	orders = {}
	nextOrderId = 1
end

function ExpansionService.activeOrders()
	return orders
end

function ExpansionService.ordersOf(nid)
	local out = {}
	for _, o in ipairs(orders) do
		if o.nation == nid then out[#out + 1] = o end
	end
	return out
end

local function findOrder(nid, target)
	for _, o in ipairs(orders) do
		if o.nation == nid and o.target == target then return o end
	end
	return nil
end

local function finish(o, refund)
	o.done = true
	local n = ctx.Nations.get(o.nation)
	if refund and n and n.alive and o.troops > 0 then
		n.troops = n.troops + math.floor(o.troops)
	end
	o.troops = 0
end

local function sweep()
	local k = 1
	for i = 1, #orders do
		local o = orders[i]
		if not o.done then
			orders[k] = o
			k = k + 1
		end
	end
	for i = k, #orders do orders[i] = nil end
end

-- Choose a border actually facing the intended owner (not some closer neutral shore).
local function adjacentToTarget(cell, target)
	local n = Map:neighbors(cell, scratch)
	for k = 1, n do
		if Territory.ownerOf(scratch[k]) == target then return true end
	end
	return false
end

local function nearestOwnBorder(nid, cell, target)
	local best, bestD = nil, math.huge
	for i in pairs(Territory.borderCells(nid) or {}) do
		if adjacentToTarget(i, target) then
			local d = Map:distance(i, cell)
			if d < bestD then best, bestD = i, d end
		end
	end
	return best
end

-- Seed several adjacent source cells, giving large orders a wider initial front.
-- The depth map is local to the order: remote national borders cannot teleport
-- an offensive wave to another side of the same target.
local function seedWave(o)
	local E = Config.Expansion
	local radius = math.min(E.WaveStartRadiusMax,
		E.WaveStartRadiusBase + math.sqrt(math.max(0, o.sent)) / E.WaveStartTroopDivisor)
	o.waveDepth = {}
	o.waveSeedRadius = radius
	o.waveMaxDepth = 0
	local seeded = false
	for i in pairs(Territory.borderCells(o.nation) or {}) do
		if Map:distance(i, o.originCell) <= radius and adjacentToTarget(i, o.target) then
			o.waveDepth[i] = 0
			seeded = true
		end
	end
	if not seeded and Territory.ownerOf(o.originCell) == o.nation then
		o.waveDepth[o.originCell] = 0
	end
	o.waveCone = math.rad(math.min(E.FrontConeMax,
		E.FrontConeBase + math.sqrt(math.max(0, o.sent)) / E.FrontConeTroopDivisor))
end

-- Multi-source wave depth, updated locally from the captured front.
-- The initial contact broadens sideways as its wave progresses. New flanking
-- border cells are admitted at the depth needed to reach them, not depth zero:
-- this makes the front a growing arc instead of a permanent narrow strip.
-- Do not recruit distant national borders: they would teleport the attack.
local function candidateDepth(o, cell)
	local best = nil
	local E = Config.Expansion
	local sideGain = E.WaveSideGrowth
	local lateralReach = math.min(E.WaveSideMax, o.waveMaxDepth * sideGain)
	local n = Map:neighbors(cell, scratch)
	for k = 1, n do
		local neighbor = scratch[k]
		if Territory.ownerOf(neighbor) == o.nation then
			local depth = o.waveDepth[neighbor]
			if depth then
				depth = depth + 1
			else
				-- An uncaptured segment of OUR border can reinforce the same
				-- advancing wave once its lateral distance is in range.
				local offset = Map:distance(neighbor, o.originCell) - o.waveSeedRadius
				if offset <= lateralReach and offset > 0 then
					depth = math.ceil(offset / sideGain) + 1
				end
			end
			if depth and (not best or depth < best) then best = depth end
		end
	end
	return best
end

-- True when the nation owns land on the same landmass as `cell` (land path exists).
function ExpansionService.sameLandmass(nid, cell)
	local mass = ctx.Landmass[cell]
	if not mass then return false end
	for i in pairs(Territory.borderCells(nid) or {}) do
		if ctx.Landmass[i] == mass then return true end
	end
	local n = ctx.Nations.get(nid)
	return n ~= nil and ctx.Landmass[n.capital] == mass and Territory.ownerOf(n.capital) == nid
end

-- Validates a land order without changing anything. Returns ok, reasonOrTarget.
function ExpansionService.validate(nid, cell, percent)
	local n = ctx.Nations.get(nid)
	if not ctx.Match.isPlaying() then return false, "A expansão começa após a fase de escolha." end
	if not n or not n.alive then return false, "Você ainda não tem nação." end
	if not Map:valid(cell) then return false, "Célula inválida." end
	if type(percent) ~= "number" or percent ~= percent or percent < 0.01 or percent > 1 then
		return false, "Percentual inválido."
	end
	local target = Territory.ownerOf(cell)
	if target == -1 then return false, "A água não pode ser conquistada. Use um porto." end
	if target == nid then return false, "Esse território já é seu." end
	if target > 0 and not ctx.Diplomacy.canAttack(nid, target) then
		return false, "Aliados não podem se atacar. Cancele a aliança antes."
	end
	if not ExpansionService.sameLandmass(nid, cell) then
		return false, "Sem ligação por terra. Use um porto para atravessar o mar.", "naval"
	end
	if not Territory.touches(nid, target) then
		if target == 0 then return false, "Não há terra livre na sua fronteira.", "blocked" end
		return false, "Sem fronteira com essa nação. Use um porto.", "naval"
	end
	if not Territory.reachable(nid, cell, Config.Expansion.ReachSearchLimit) then
		if target == 0 then
			return false, "Caminho bloqueado por outra nação. Ataque-a ou escolha terra livre ligada à sua fronteira.", "blocked"
		end
		return false, "Essa parte de " .. ctx.Nations.get(target).name .. " não encosta em você. Use um porto.", "naval"
	end
	return true, target
end

-- Starts or reinforces an order with troops that already left the reserve.
function ExpansionService.start(nid, target, cell, troops)
	local existing = findOrder(nid, target)
	if existing then
		existing.troops = existing.troops + troops
		existing.sent = existing.sent + troops
		existing.anchor = cell
		existing.origin = nearestOwnBorder(nid, cell, target) or existing.origin
		existing.originCell = existing.origin or existing.originCell
		-- Reinforcement may redirect the attack. Re-seed at the newly selected
		-- border rather than dragging stale depth data across the whole country.
		seedWave(existing)
		return existing
	end
	local o = {
		id = nextOrderId, nation = nid, target = target, troops = troops, sent = troops,
		anchor = cell, origin = nearestOwnBorder(nid, cell, target), front = nil, carry = 0,
		started = ctx.now(),
	}
	nextOrderId = nextOrderId + 1
	o.originCell = o.origin or cell
	o.front = o.origin
	seedWave(o)
	orders[#orders + 1] = o
	if target > 0 then ctx.Diplomacy.ensureWar(nid, target) end
	return o
end

function ExpansionService.issue(nid, cell, percent)
	local ok, targetOrWhy, hint = ExpansionService.validate(nid, cell, percent)
	if not ok then return false, targetOrWhy, hint end
	local target = targetOrWhy
	local n = ctx.Nations.get(nid)
	local existing = findOrder(nid, target)
	if not existing then
		local count = 0
		for _, o in ipairs(orders) do
			if o.nation == nid then count = count + 1 end
		end
		if count >= Config.Expansion.MaxOrdersPerNation then
			return false, "Limite de " .. Config.Expansion.MaxOrdersPerNation .. " frentes ativas. Cancele uma."
		end
	end
	local troops = math.floor(n.troops * percent)
	if troops < Config.Expansion.MinTroopsToSend then
		return false, "Tropas insuficientes para enviar."
	end
	n.troops = n.troops - troops
	local o = ExpansionService.start(nid, target, cell, troops)
	if target > 0 and not existing then
		ctx.notify(target, n.name .. " está atacando seu território com "
			.. ctx.Protocol.formatK(troops) .. " tropas.", "defense")
	end
	local targetName = target == 0 and "terra livre" or ctx.Nations.get(target).name
	return true, (existing and "Reforço enviado: " or "Avanço iniciado: ") .. troops .. " tropas → " .. targetName, o
end

function ExpansionService.cancel(nid, orderId)
	for _, o in ipairs(orders) do
		if o.nation == nid and (orderId == nil or o.id == orderId) then
			finish(o, true)
		end
	end
	sweep()
end

function ExpansionService.cancelAll(nid, refund)
	for _, o in ipairs(orders) do
		if o.nation == nid then finish(o, refund) end
	end
	sweep()
end

function ExpansionService.cancelAgainst(nid, target)
	for _, o in ipairs(orders) do
		if o.nation == nid and o.target == target then finish(o, true) end
	end
	sweep()
end

local function advance(o, dt)
	local E = Config.Expansion
	local n = ctx.Nations.get(o.nation)
	if not n or not n.alive then finish(o, false) return end
	if o.target > 0 then
		local t = ctx.Nations.get(o.target)
		if not t or not t.alive or not ctx.Diplomacy.canAttack(o.nation, o.target) then
			finish(o, true)
			return
		end
	end
	if o.troops < E.MinTroopsToSend * 0.5 then finish(o, true) return end

	-- Broad, connected wave. Candidates must touch territory captured by THIS
	-- order, or one of its original seed cells. Do not jump to remote borders.
	local sq = math.sqrt(math.max(0, o.troops))
	local reach = Map:distance(o.originCell, o.anchor) + E.FrontSearchMargin + sq / 4
	local _, count = Territory.frontierNear(o.nation, o.target, o.originCell, reach, candidates)
	if count == 0 then _, count = Territory.frontier(o.nation, o.target, candidates) end
	if count == 0 then finish(o, true) return end

	local W = Map.W
	local ox, oy = Map:xy(o.originCell)
	local ax, ay = Map:xy(o.anchor)
	local tx, ty = ax - ox, ay - oy
	local L = math.sqrt(tx * tx + ty * ty)
	local function scoreCandidates(count)
		local valid = 0
		for k = 1, count do
			local c = candidates[k]
			local depth = candidateDepth(o, c)
			if depth then
				valid = valid + 1
				local cx, cy = Map:xy(c)
				local vx, vy = cx - ox, cy - oy
				local radius = math.sqrt(vx * vx + vy * vy)
				local penalty = 0
				if L >= 1 and radius >= 2 then
					local cosang = math.clamp and math.clamp((vx * tx + vy * ty) / (radius * L), -1, 1)
						or math.max(-1, math.min(1, (vx * tx + vy * ty) / (radius * L)))
					local excess = math.acos(cosang) - o.waveCone
					if excess > 0 then
						penalty = math.min(E.WaveDirectionPenalty, excess * radius * E.ConePenalty)
					end
				end
				candidates[valid] = c
				depths[valid] = depth
				scores[valid] = depth * E.WaveDepthWeight + penalty
					- E.OwnNeighborWeight * Territory.ownNeighborCount(c, o.nation)
					+ ctx.random() * E.Jitter
			end
		end
		for k = valid + 1, count do candidates[k] = nil end
		return valid
	end
	local m = scoreCandidates(count)
	if m == 0 then
		_, count = Territory.frontier(o.nation, o.target, candidates)
		m = scoreCandidates(count)
	end
	if m == 0 then finish(o, true) return end

	local rate = math.min(E.CellsPerTickMax, E.CellsPerTickBase + sq / E.CellsPerTickTroopDivisor)
	if o.target > 0 then rate = rate * E.EnemyRateFactor end
	o.carry = o.carry + rate * dt / Config.Tick.Simulation
	local want = math.floor(o.carry)
	o.carry = o.carry - want
	if want <= 0 then return end

	local taken = 0
	for t = 1, math.min(want, m) do
		-- partial selection: best remaining score
		local best = t
		for k = t + 1, m do
			if scores[k] < scores[best] then best = k end
		end
		candidates[t], candidates[best] = candidates[best], candidates[t]
		scores[t], scores[best] = scores[best], scores[t]
		depths[t], depths[best] = depths[best], depths[t]
		local cell = candidates[t]
		if Territory.ownerOf(cell) == o.target then
			local cost, loss = ctx.Combat.cellCost(o.nation, cell, o.troops, o.front)
			if cost > o.troops then
				o.stalled = true
				break
			end
			o.troops = o.troops - cost
			if o.target > 0 then
				local d = ctx.Nations.get(o.target)
				d.troops = math.max(0, d.troops - loss)
			end
			Territory.setOwner(cell, o.nation)
			o.waveDepth[cell] = depths[t]
			o.waveMaxDepth = math.max(o.waveMaxDepth, depths[t])
			o.front = cell
			taken = taken + 1
		end
	end
	if taken > 0 then o.stalled = false end
	if o.stalled then
		-- not enough troops for the cheapest cell left: the order ends, survivors go home
		finish(o, true)
	end
end

function ExpansionService.tick(dt)
	if not ctx.Match.isPlaying() then return end
	for i = 1, #orders do
		local o = orders[i]
		if not o.done then advance(o, dt) end
	end
	sweep()
end

-- Compact public view for clients: { id, nation, target, troops, front, anchor, origin }
function ExpansionService.publicView()
	local out = {}
	for _, o in ipairs(orders) do
		out[#out + 1] = { o.id, o.nation, o.target, math.floor(o.troops), o.front or 0, o.anchor, o.origin or 0 }
	end
	return out
end

return ExpansionService
