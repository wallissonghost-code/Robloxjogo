-- Pure geometry regression for the troop transport dot and travelled-only line.
local Trail = dofile("src/client/TransportTrail.lua")
local function ok(value, message)
	if not value then error("ASSERT: " .. message, 2) end
end
local map = { W = 200, H = 20 }
function map:xy(cell)
	local x = (cell - 1) % self.W
	return x, math.floor((cell - 1) / self.W)
end
function map:index(x, y) return y * self.W + x + 1 end
function map:valid(cell)
	return type(cell) == "number" and cell >= 1 and cell <= self.W * self.H
end
local function cell(x, y) return map:index(x, y) end
local port = cell(1, 1)
local path = { cell(2, 1), cell(3, 1), cell(4, 1), cell(4, 2), cell(4, 3), cell(5, 3) }
local sections = Trail.sections(map, path, port)
ok(#sections == 4, "one port connector plus three straight route spans")
ok(sections[1].from == 1 and sections[1].to == 1, "port connector starts fully travelled")
ok(sections[1].ax == 1.5 and sections[1].bx == 2.5, "trail stays linked to port")
ok(sections[2].from == 1 and sections[2].to == 3, "straight cells share one segment")
ok(sections[3].from == 3 and sections[3].to == 5, "route turns without diagonals")
ok(sections[4].from == 5 and sections[4].to == 6, "final segment reaches destination coast")
local sx, sy = Trail.position(map, path, 3.5)
ok(sx == 4.5 and sy == 2, "dot interpolates between adjacent water cells")
local cx, cy = Trail.position(map, path, 6)
ok(cx == 5.5 and cy == 3.5, "dot finishes exactly on land target")
local ox, oy, complete = Trail.traversedEnd(sections[2], 1)
ok(ox == nil, "nothing drawn ahead of the moving dot")
ox, oy, complete = Trail.traversedEnd(sections[2], 2)
ok(ox == 3.5 and oy == 1.5 and not complete, "wake reveals only travelled half")
ox, oy, complete = Trail.traversedEnd(sections[2], 3)
ok(ox == 4.5 and oy == 1.5 and complete, "finished section is complete")
ox = Trail.traversedEnd(sections[4], 4.5)
ok(ox == nil, "untravelled shore connector stays invisible")
local straight = {}
for x = 2, 151 do straight[#straight + 1] = cell(x, 1) end
ok(#Trail.sections(map, straight, port) == 2,
	"150 straight cells use only two GUI segments including the port")
print("PASS troop transport trail geometry and performance")
