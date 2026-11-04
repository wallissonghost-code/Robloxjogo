-- Fast map fallback: fewer GUI Frames, correct dirty-band updates and view culling.
-- Run with: python3 tests/run_lua.py tests/lua/test_frame_renderer.lua
local M = dofile("tests/lua/roblox_mock.lua")
M.reset()
M.editableAvailable = true
local env = M.env(nil)
local MapRenderer = assert(loadfile("src/client/MapRenderer.lua", "t", env))()
local function ok(condition, why)
	if not condition then error("ASSERT: " .. why, 2) end
end
local W, H = 32, 16
local map = { W = W, H = H, N = W * H, land = {}, country = {}, latitude = {} }
for y = 0, H - 1 do map.latitude[y] = 0 end
for i = 1, map.N do map.land[i], map.country[i] = true, 1 end
local palette = {
	Neutral = { 188, 180, 162 }, NeutralPolar = { 188, 180, 162 },
	CountryLine = { 160, 155, 149 }, Water = { 47, 89, 133 },
	WaterCoast = { 50, 95, 140 },
}
function palette.mix(a, b, t)
	return { math.floor(a[1] + (b[1] - a[1]) * t + 0.5),
		math.floor(a[2] + (b[2] - a[2]) * t + 0.5),
		math.floor(a[3] + (b[3] - a[3]) * t + 0.5) }
end
function palette.shade(a, k)
	return { math.floor(a[1] * k), math.floor(a[2] * k), math.floor(a[3] * k) }
end
local state = {
	Map = map, owner = {}, nations = {}, Palette = palette,
	Config = { View = { ChunkSize = 16 } }, listeners = {},
}
for i = 1, map.N do state.owner[i] = 0 end
function state:on(event, callback)
	self.listeners[event] = self.listeners[event] or {}
	table.insert(self.listeners[event], callback)
end
function state:nationColor(id) return { 40, 90, 150 } end

local screen = env.Instance.new("ScreenGui")
local parent = env.Instance.new("Frame")
parent.Size = env.UDim2.fromOffset(W * 8, H * 8)
parent.Parent = screen
local renderer = MapRenderer.new(state, parent, { frames = true })
ok(renderer:mode() == "frames", "requested mode remains Frame-based")
renderer:flush()
renderer:flush() -- 2 x 16x16 chunks; one chunk per flush
local left, right = renderer.frameChunks[1], renderer.frameChunks[2]
ok(left and right, "both map chunks rendered")
ok(#left.bands[0] == 1 and #left.bands[1] == 1, "eight identical rows merge to one rectangle")
ok(#right.bands[0] == 1 and #right.bands[1] == 1, "second chunk also uses merged rectangles")
ok(M.created < 30, "uniform 512-cell map creates few GUI objects, not hundreds of Frames")
print("PASS Frame fallback vertically merges uniform map rows")

-- A capture only repaints the affected eight-row band, preserving the
-- untouched upper/lower bands and all other chunk instance identities.
local untouched = left.bands[1][1]
local remote = right.bands[0][1]
local ownerCell = 4 * W + 5
state.owner[ownerCell] = 2
state.nations[2] = { id = 2, name = "Teste" }
renderer:recolor()
renderer:markAround(ownerCell)
renderer:flush()
ok(left.bands[1][1] == untouched and untouched.Visible, "distant band stays pooled and visible")
ok(right.bands[0][1] == remote, "other chunk did not get recreated")
ok(#left.bands[0] > 1, "border cells produce additional rectangles only in changed band")
print("PASS capture repaints the affected band without destroying unrelated GUI")

-- At high zoom the offscreen chunk must not participate in the GUI draw.
local viewport = env.Vector2.new(64, 96)
local beforePan = M.created
renderer:setView(8, 8, 8, viewport)
ok(left.root.Visible and not right.root.Visible, "left camera culls right world chunk")
renderer:setView(24, 8, 8, viewport)
ok(right.root.Visible and not left.root.Visible, "panning swaps visible chunks")
ok(M.created == beforePan, "pan and zoom reuse existing objects without allocations")
print("PASS distant Frame chunks are culled with no pan-time allocations")

renderer:dispose()
local image = MapRenderer.new(state, parent, { frames = false })
ok(image:mode() == "image", "EditableImage renderer remains untouched")
image:flush()
ok(M.pixelWrites >= 1, "EditableImage still paints through the texture")
image:dispose()
print("PASS image mode and existing optional renderer remain functional")
