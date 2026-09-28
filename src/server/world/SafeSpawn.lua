local Config = require(script.Parent.Config)

local SafeSpawn = {}

local function inLake(x, z)
	for _, lake in ipairs(Config.LAKES) do
		local dx = (x - lake.x) / (lake.rx + 55)
		local dz = (z - lake.z) / (lake.rz + 55)
		if dx * dx + dz * dz <= 1 then return true end
	end
	return false
end

local function nearRiver(TerrainShape, x, z)
	local margin = Config.RIVER_HALF_WIDTH + 55
	return math.abs(x - TerrainShape.riverCenter(z)) < margin
		or math.abs(x - TerrainShape.riverTwoCenter(z)) < margin
		or math.abs(z - TerrainShape.riverThreeCenter(x)) < margin
end

local function valid(TerrainShape, x, z)
	if math.abs(x) > Config.LAND_HALF - 160 or math.abs(z) > Config.LAND_HALF - 160 then return false end
	if inLake(x, z) or nearRiver(TerrainShape, x, z) then return false end
	local h = TerrainShape.heightAt(x, z)
	if h < Config.WATER_LEVEL + 8 then return false end
	local delta = math.max(
		math.abs(TerrainShape.heightAt(x + 18, z) - h),
		math.abs(TerrainShape.heightAt(x - 18, z) - h),
		math.abs(TerrainShape.heightAt(x, z + 18) - h),
		math.abs(TerrainShape.heightAt(x, z - 18) - h)
	)
	return delta <= 7
end

function SafeSpawn.find(TerrainShape)
	local candidates = {
		{ 240, 240 }, { -240, 240 }, { 240, -240 }, { -240, -240 },
		{ 360, 180 }, { -360, 180 }, { 360, -180 }, { -360, -180 },
	}
	for _, point in ipairs(candidates) do
		local x, z = point[1], point[2]
		if valid(TerrainShape, x, z) then
			return Vector3.new(x, TerrainShape.heightAt(x, z) + 5, z)
		end
	end
	error("SafeSpawn: no safe land candidate was found")
end

return SafeSpawn
