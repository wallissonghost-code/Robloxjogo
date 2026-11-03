-- Coloured Construir/Armamentos icons: MilitaryIconArt decodes into the shared
-- 320x320 runtime atlas, cards keep the art's colours, locked cards are dimmed,
-- and clients without EditableImage keep the monochrome silhouettes.
local M = dofile("tests/lua/roblox_mock.lua")
local ok = function(c, msg) if not c then error("ASSERT: " .. msg, 2) end end

local function boot(editable)
	M.reset()
	M.editableAvailable = editable
	M.mount(M.game:GetService("ReplicatedStorage"), "src/shared", "MundialWarShared")
	local client = M.mount(M.localPlayer, "src/client", "MundialWar")
	return M.env(client).require(client.MilitaryIcons)
end

local Icons = boot(true)
local function frame() local f = M.Instance.new("Frame") f.ZIndex = 1 return f end
local holder = frame()
local h = Icons.attach(holder, "city")
ok(h:usesTexture() and h:isColored(), "city icon uses the coloured atlas")
ok(M.image and M.image.Size.X == 320, "one 320x320 atlas texture")
-- city tile (0,0): the blue tower body is opaque and blue-ish
local p = M.image.pixels
local function px(x, y) local d = (y * 320 + x) * 3 return p[d], p[d + 1], p[d + 2] end
local r, g, b = px(31, 30)
ok(b > r and b > 150, "city tower is blue (" .. r .. "," .. g .. "," .. b .. ")")
-- the anchor of the port tile (128,0) is gold
r, g, b = px(128 + 32, 34)
ok(r > 200 and g > 150 and b < 120, "port anchor is gold (" .. r .. "," .. g .. "," .. b .. ")")
local img = holder:FindFirstChild("ColorIcon")
ok(img, "coloured ImageLabel created")
h:setColor(Icons.SELECTED_COLOR)
ok(img.ImageTransparency == 0, "selected keeps full colour")
h:setColor(Icons.LOCKED_COLOR)
ok(img.ImageTransparency > 0, "locked icon is faded")
local writes = M.pixelWrites
for _, kind in ipairs({ "factory", "silo", "atomic", "endofera" }) do Icons.attach(frame(), kind) end
ok(M.pixelWrites == writes, "all icons share the one atlas (no new texture)")
print("PASS coloured icon atlas")

local Mono = boot(false)
local function frame() local f = M.Instance.new("Frame") f.ZIndex = 1 return f end
local h2 = Mono.attach(frame(), "city")
ok(not h2:usesTexture() and not h2:isColored(), "no EditableImage: monochrome Frame silhouettes")
print("PASS monochrome fallback")
