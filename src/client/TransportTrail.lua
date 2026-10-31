-- Pure geometry for the travelled-only wake behind a troop transport.
-- Rendering uses ordinary Roblox GUI Frames, not the optional EditableImage API.
local TransportTrail = {}

local function center(map, cell)
	local x, y = map:xy(cell)
	return x + 0.5, y + 0.5
end

-- Merge only collinear adjacent path cells: no diagonal across land or islands.
-- Index 1 of the path is the port's first water neighbour; last is the coast.
function TransportTrail.sections(map, path, origin)
	local out = {}
	if not path or #path == 0 then return out end
	local function add(first, last, ax, ay, bx, by)
		if ax == bx and ay == by then return end
		out[#out + 1] = { from = first, to = last,
			ax = ax, ay = ay, bx = bx, by = by }
	end
	if origin and map:valid(origin) then
		local ax, ay = center(map, origin)
		local bx, by = center(map, path[1])
		-- Always visible at launch: this short segment links the true port.
		add(1, 1, ax, ay, bx, by)
	end
	local first, dx, dy = 1, nil, nil
	for i = 2, #path do
		local ax, ay = center(map, path[i - 1])
		local bx, by = center(map, path[i])
		local vx, vy = bx - ax, by - ay
		if dx and (vx ~= dx or vy ~= dy) then
			local sx, sy = center(map, path[first])
			add(first, i - 1, sx, sy, ax, ay)
			first = i - 1
		end
		dx, dy = vx, vy
	end
	if #path > 1 then
		local ax, ay = center(map, path[first])
		local bx, by = center(map, path[#path])
		add(first, #path, ax, ay, bx, by)
	end
	return out
end

function TransportTrail.position(map, path, progress)
	if not path or #path == 0 then return nil end
	local p = math.max(1, math.min(progress or 1, #path))
	local i = math.floor(p)
	local ax, ay = center(map, path[i])
	if i == #path then return ax, ay end
	local bx, by = center(map, path[i + 1])
	local t = p - i
	return ax + (bx - ax) * t, ay + (by - ay) * t
end

-- Nil when unvisited, partial endpoint when travelling, full endpoint once done.
function TransportTrail.traversedEnd(section, progress)
	if progress >= section.to then return section.bx, section.by, true end
	if progress <= section.from then return nil end
	local t = (progress - section.from) / (section.to - section.from)
	return section.ax + (section.bx - section.ax) * t,
		section.ay + (section.by - section.ay) * t, false
end

return TransportTrail
