-- Mundial War · client-side mirror of what the server replicates. Renders only; decides nothing.
local ClientState = {}
ClientState.__index = ClientState

function ClientState.new(Map, Protocol, Config, Palette, Stats)
	local self = setmetatable({}, ClientState)
	self.Map, self.Protocol, self.Config, self.Palette, self.Stats = Map, Protocol, Config, Palette, Stats
	self.owner = {}
	for i = 1, Map.N do self.owner[i] = Map.land[i] and 0 or -1 end
	self.nations = {}          -- id -> { info + troops, land, labelCell, labelSize }
	self.buildings = {}        -- cell -> { kind, owner }
	self.relations = {}        -- "a:b" -> kind
	self.orders = {}           -- list { id, nation, target, troops, front, anchor, origin, visualX, visualY }
	self.fleets = {}           -- id -> { id, nation, troops, path, speed, target, progress, port, t0 }
	self.boats = {}           -- list { id, nation, x, y, health, patrolCell, level }
	self.missiles = {}         -- id -> { id, kind, nation, from, to, speed, progress, t0 }
	self.fires = {}            -- list { id, centerCell, radius }
	self.cargos = {}           -- list { id, nation, cell }
	self.match = { phase = "waiting", round = 0, left = 0 }
	self.matchAt = 0
	self.you = nil
	self.me = nil              -- private HUD numbers
	self.percent = Config.DefaultTroopPercent
	self.listeners = {}
	return self
end

function ClientState:on(name, fn)
	self.listeners[name] = self.listeners[name] or {}
	table.insert(self.listeners[name], fn)
end

function ClientState:fire(name, ...)
	for _, fn in ipairs(self.listeners[name] or {}) do fn(...) end
end

local function key(a, b)
	if a > b then a, b = b, a end
	return a .. ":" .. b
end

function ClientState:relation(a, b)
	if not a or not b then return "neutral" end
	if a == b then return "self" end
	return self.relations[key(a, b)] or "neutral"
end

-- Show only battles that matter to this player: our own attack, an
-- attack against us, or an attack against one of our direct allies.
-- Allies' outgoing attacks and unrelated wars do not clutter the map.
function ClientState:shouldShowOrder(attacker, target)
	local me = self.you
	if not me then return false end
	if attacker == me then return true end
	if not target or target <= 0 then return false end
	return target == me or self:relation(me, target) == "ally"
end

function ClientState:nationColor(id)
	local n = self.nations[id]
	if not n then return self.Palette.Neutral end
	-- Tribes have a shared map/UI colour; nation identity and server colour IDs
	-- stay untouched for all game rules and other factions.
	if n.kind == "tribe" then return self.Palette.Tribe end
	return self.Palette.Nations[n.color] or self.Palette.Neutral
end

function ClientState:applyInit(data)
	local Map = self.Map
	for i = 1, Map.N do self.owner[i] = Map.land[i] and 0 or -1 end
	self.Protocol.decodeRuns(data.owners, self.owner)
	self.nations = {}
	for _, info in ipairs(data.nations) do
		info.troops = info.troops or 0
		info.land = info.land or 0
		info.labelCell = info.labelCell or info.capital
		info.labelSize = info.labelSize or math.max(1, info.land)
		self.nations[info.id] = info
	end
	self.buildings = {}
	for _, b in ipairs(data.buildings) do self.buildings[b[1]] = { kind = b[2], owner = b[3], level = b[4] or 1, off = b[5] == true } end
	self.relations = {}
	for _, r in ipairs(data.relations) do self.relations[key(r[1], r[2])] = r[3] end
	self.orders = {}
	self.fleets = {}
	local now = os.clock()
	for _, f in ipairs(data.fleets or {}) do
		self.fleets[f[1]] = { id = f[1], nation = f[2], troops = f[3], path = f[4], speed = f[5], target = f[6], progress = f[7], air = f[8] == true, port = f[9], t0 = now }
	end
	self.boats = data.boats or {}
	self.fires = data.fires or {}
	self.cargos = data.cargos or {}
	self.missiles = {}
	for _, m in ipairs(data.missiles or {}) do
		self.missiles[m[1]] = { id = m[1], kind = m[2], nation = m[3], from = m[4], to = m[5], speed = m[6], progress = m[7], t0 = now }
	end
	self.match = data.match
	self.matchAt = now
	self.you = data.you
	self.me = nil
	self.debug = data.debug
	self:fire("init")
end

function ClientState:applyDelta(data)
	local changed = data.d
	if changed then
		local cells = {}
		for k = 1, #changed, 2 do
			self.owner[changed[k]] = changed[k + 1]
			cells[#cells + 1] = changed[k]
		end
		self:fire("owners", cells)
	end
	if data.b then
		for _, b in ipairs(data.b) do
			if b[2] then self.buildings[b[1]] = { kind = b[2], owner = b[3], level = b[4] or 1, off = b[5] == true } else self.buildings[b[1]] = nil end
		end
		self:fire("buildings")
	end
end

function ClientState:applyNations(data)
	if data.add then
		local info = data.add
		local old = self.nations[info.id]
		info.troops = info.troops or (old and old.troops) or 0
		info.land = info.land or (old and old.land) or 0
		info.labelCell = info.labelCell or (old and old.labelCell) or info.capital
		info.labelSize = info.labelSize or (old and old.labelSize) or math.max(1, info.land)
		self.nations[info.id] = info
		self:fire("nationList")
		return
	end
	if data.remove then
		self.nations[data.remove] = nil
		if self.you == data.remove then
			self.you = nil
			self.me = nil
		end
		self:fire("nationList")
		return
	end
	if data.list then
		for _, row in ipairs(data.list) do
			local n = self.nations[row[1]]
			if n then
				n.troops, n.land, n.labelCell, n.labelSize, n.capital = row[2], row[3], row[4], row[5], row[6]
			end
		end
		if data.match then
			self.match = data.match
			self.matchAt = os.clock()
		end
		self:fire("nations")
	end
end

function ClientState:applyOrders(data)
	local now = os.clock()
	if data.fleet then
		local f = data.fleet
		self.fleets[f[1]] = { id = f[1], nation = f[2], troops = f[3], path = f[4], speed = f[5], target = f[6], progress = 1, air = f[7] == true, port = f[8], t0 = now }
	end
	if data.fleetEnd then
		local f = self.fleets[data.fleetEnd]
		if f and data.fleetReachedShore and not f.air then
			-- Keep the dot just long enough to reach the coast visually, even if
			-- the final server packet arrives ahead of the client's interpolation.
			f.finishing = true
			f.finishedAt = now
			f.progress = #f.path
			f.t0 = now
		else
			self.fleets[data.fleetEnd] = nil
		end
	end
	if data.orders then self.orders = data.orders end
	if data.fleets then
		for _, row in ipairs(data.fleets) do
			local f = self.fleets[row[1]]
			if f and not f.finishing then
				f.troops, f.progress, f.t0 = row[3], row[4], now
			end
		end
	end
	if data.boats then self.boats = data.boats end
	if data.fires then self.fires = data.fires end
	if data.cargos then self.cargos = data.cargos end
	if data.bots then self.botStates = data.bots end
	self:fire("orders")
end

function ClientState:applyDiplomacy(data)
	if data.rel then
		local k = key(data.a, data.b)
		self.relations[k] = data.rel ~= "neutral" and data.rel or nil
		self:fire("relations", data.a, data.b, data.rel)
	end
	if data.request then self:fire("allianceRequest", data.request, data.expires) end
end

function ClientState:applyImpact(data)
	local now = os.clock()
	if data.launch then
		local m = data.launch
		self.missiles[m[1]] = { id = m[1], kind = m[2], nation = m[3], from = m[4], to = m[5], speed = m[6], progress = 0, t0 = now }
	end
	if data.hit then
		self.missiles[data.hit[1]] = nil
		self:fire("impact", data.hit[2], data.hit[3], data.hit[4])
	end
end

function ClientState:applyMe(data)
	self.me = data
	if data.id and self.you ~= data.id then
		self.you = data.id
		self:fire("nationList")
	end
	self:fire("me")
end

function ClientState:timeLeft()
	return math.max(0, (self.match.left or 0) - (os.clock() - self.matchAt))
end

-- Own boat closest to map point (x, y) within `radius` cells, or nil.
function ClientState:boatNear(nid, x, y, radius)
	local best, bestD = nil, radius * radius
	for _, b in ipairs(self.boats) do
		if b[2] == nid then
			local d = (b[3] - x) ^ 2 + (b[4] - y) ^ 2
			if d <= bestD then best, bestD = b, d end
		end
	end
	return best
end

-- Nearest cell of `nid` to `cell` that touches other land (arrow origin for an order).
function ClientState:nearestBorder(nid, cell)
	local Map, owner = self.Map, self.owner
	local cx, cy = Map:xy(cell)
	local best, bestD = nil, math.huge
	for i = 1, Map.N do
		if owner[i] == nid then
			local x, y = Map:xy(i)
			local d = (x - cx) * (x - cx) + (y - cy) * (y - cy)
			if d < bestD then best, bestD = i, d end
		end
	end
	return best
end

return ClientState
