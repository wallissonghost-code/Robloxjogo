local Config = require(script.Parent.Config)

local Boundary = {}

local function createWall(parent, name, size, position)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Transparency = 1
	part.CanCollide = true
	part.CanTouch = false
	part.CanQuery = true
	part.Size = size
	part.Position = position
	part.Parent = parent
end

function Boundary.generate(workspace)
	local barriers = Instance.new("Folder")
	barriers.Name = "WorldBoundary"
	barriers.Parent = workspace

	local centerOffset = Config.LAND_HALF + Config.BOUNDARY_THICKNESS / 2
	local outerHalf = Config.LAND_HALF + Config.BOUNDARY_THICKNESS

	local function tileHorizontal(prefix, z)
		local cursor, index = -outerHalf, 1
		while cursor < outerHalf do
			local length = math.min(Config.BOUNDARY_SEGMENT_LENGTH, outerHalf - cursor)
			local center = cursor + length / 2
			createWall(barriers, string.format("%s_%02d", prefix, index),
				Vector3.new(length + Config.BOUNDARY_SEAM_OVERLAP, Config.BOUNDARY_HEIGHT, Config.BOUNDARY_THICKNESS),
				Vector3.new(center, Config.BOUNDARY_HEIGHT / 2, z))
			cursor += length
			index += 1
		end
	end

	local function tileVertical(prefix, x)
		local cursor, index = -outerHalf, 1
		while cursor < outerHalf do
			local length = math.min(Config.BOUNDARY_SEGMENT_LENGTH, outerHalf - cursor)
			local center = cursor + length / 2
			createWall(barriers, string.format("%s_%02d", prefix, index),
				Vector3.new(Config.BOUNDARY_THICKNESS, Config.BOUNDARY_HEIGHT, length + Config.BOUNDARY_SEAM_OVERLAP),
				Vector3.new(x, Config.BOUNDARY_HEIGHT / 2, center))
			cursor += length
			index += 1
		end
	end

	tileHorizontal("North", -centerOffset)
	tileHorizontal("South", centerOffset)
	tileVertical("West", -centerOffset)
	tileVertical("East", centerOffset)
end

return Boundary
