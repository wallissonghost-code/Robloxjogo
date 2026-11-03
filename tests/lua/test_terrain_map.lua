-- The real-terrain world map: MapRenderer in image mode paints satellite colours,
-- and relief from MapTerrain (the sea is one flat colour); nations tint the terrain; frames mode stays flat.
-- MW_PREVIEW=path.ppm writes the painted map for a visual check.
local M = dofile("tests/lua/roblox_mock.lua")
local ok = function(c, msg) if not c then error("ASSERT: " .. msg, 2) end end

local function boot(editable)
	M.reset()
	M.editableAvailable = editable
	local shared = M.mount(M.game:GetService("ReplicatedStorage"), "src/shared", "MundialWarShared")
	local client = M.mount(M.localPlayer, "src/client", "MundialWar")
	local env = M.env(client)
	local req = env.require
	local Map = req(shared.MapGrid).new(req(shared.MapData))
	local ClientState = req(client.ClientState)
	local state = ClientState.new(Map, req(shared.Protocol), req(shared.GameConfig), req(shared.Palette), req(shared.BuildingStats))
	return state, req(client.MapRenderer), Map
end

local function countryIndex(Map, code)
	for k, c in ipairs(Map.countries) do
		if c.code == code then return k end
	end
	error("no country " .. code)
end

local function own(state, Map, code, nation)
	local k = countryIndex(Map, code)
	for i = 1, Map.N do
		if Map.country[i] == k then state.owner[i] = nation end
	end
	return Map.countries[k].capital
end

local function pixel(i)
	local d = (i - 1) * 3
	local p = M.image.pixels
	return { p[d], p[d + 1], p[d + 2] }
end

local function same(a, b) return a[1] == b[1] and a[2] == b[2] and a[3] == b[3] end

-- image mode --------------------------------------------------------------------
local state, MapRenderer, Map = boot(true)
state.nations[1] = { id = 1, kind = "nation", color = 1, name = "Brasil" }
state.nations[2] = { id = 2, kind = "nation", color = 2, name = "Rússia" }
state.nations[3] = { id = 3, kind = "tribe", color = 3, name = "Tribo" }
local brazil = own(state, Map, "BRA", 1)
own(state, Map, "RUS", 2)
own(state, Map, "AUS", 3)
local world = M.Instance.new("Frame")
local r = MapRenderer.new(state, world, {})
ok(r:mode() == "image", "EditableImage renderer")
ok(r.terrain ~= nil, "terrain layer loaded in image mode")
local t0 = os.clock()
r:flush()
print(string.format("  full terrain paint: %.0f ms (Lua 5.4)", (os.clock() - t0) * 1000))

local T = r.terrainData
local deep = Map:index(80, 220)         -- mid South Pacific (lon -135)
local pd, isSea = pixel(deep), false
for _, w in ipairs(T.Water) do isSea = isSea or same(pd, w) end
ok(not Map.land[deep] and isSea, "open ocean uses the sea colour")
local distinctWater = {}
for i = 1, Map.N do
	if not Map.land[i] then
		local c = pixel(i)
		distinctWater[c[1] .. "," .. c[2] .. "," .. c[3]] = true
	end
end
local nWater = 0
for _ in pairs(distinctWater) do nWater = nWater + 1 end
ok(nWater == 1, "sea is one flat colour (got " .. nWater .. ")")

-- the Sahara reads as desert (warm, red > blue), the Congo basin as greener than it
local sahara = Map:index(math.floor((10 + 180) / 360 * Map.W), 0)
for y = 0, Map.H - 1 do
	if math.abs(Map.latitude[y] - 23) < 0.6 then sahara = Map:index(math.floor(190 / 360 * Map.W), y) break end
end
ok(Map.land[sahara] and state.owner[sahara] == 0, "Sahara sample is free land")
local s = pixel(sahara)
ok(s[1] > s[3] + 30, "Sahara is sandy")
local congo
for y = 0, Map.H - 1 do
	if math.abs(Map.latitude[y] - 0) < 0.6 then congo = Map:index(math.floor(203 / 360 * Map.W), y) break end
end
ok(Map.land[congo], "Congo sample is land")
local c = pixel(congo)
ok(c[2] - c[1] > s[2] - s[1], "rainforest is greener than the desert")

-- free land is not one flat colour any more
local tones = {}
for i = 1, Map.N do
	if Map.land[i] and state.owner[i] == 0 then
		local p = pixel(i)
		tones[p[1] .. "," .. p[2] .. "," .. p[3]] = true
	end
end
local nTones = 0
for _ in pairs(tones) do nTones = nTones + 1 end
ok(nTones > 40, "free land shows many terrain tones (got " .. nTones .. ")")

-- a nation's interior is its colour tinted by the terrain under it; its border stays solid
local fill = state.Palette.Nations[1]
local inner = pixel(brazil)
ok(not same(inner, fill), "nation fill shows the terrain through it")
local d = math.abs(inner[1] - fill[1]) + math.abs(inner[2] - fill[2]) + math.abs(inner[3] - fill[3])
ok(d < 160, "nation colour still dominates the tint")
local border
for i = 1, Map.N do
	if state.owner[i] == 1 and state.owner[i + 1] == 0 and Map.land[i + 1] then border = i break end
end
ok(border and same(pixel(border), r.colors[1].border), "national border keeps the solid dark band")

-- captures repaint with the terrain too
state.owner[sahara] = 2
r:markAround(sahara)
r:flush()
local cap = pixel(sahara)
ok(not same(cap, s) and not same(cap, state.Palette.Nations[2]), "captured desert cell is tinted, not flat")

if os.getenv("MW_PREVIEW") then
	local f = assert(io.open(os.getenv("MW_PREVIEW"), "wb"))
	f:write(string.format("P6\n%d %d\n255\n", Map.W, Map.H))
	local p, out = M.image.pixels, {}
	for k = 0, Map.N * 3 - 1 do out[#out + 1] = string.char(p[k] or 0) end
	f:write(table.concat(out))
	f:close()
end
r:dispose()
print("PASS real terrain in image mode")

-- frames mode keeps flat colours (each colour change would cost another Frame) ---------
local state2, MapRenderer2 = boot(false)
local r2 = MapRenderer2.new(state2, M.Instance.new("Frame"), { frames = true })
ok(r2:mode() == "frames", "frames renderer")
ok(r2.terrain == nil, "no terrain in frames mode")
r2:dispose()
print("PASS frames mode unchanged")
