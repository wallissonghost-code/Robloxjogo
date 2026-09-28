local Config = require(script.Parent.Config)

local Terrain = {}

function Terrain.riverCenter(z)
	return math.sin(z / 520) * 180 + math.sin(z / 190) * 55
end

function Terrain.riverTwoCenter(z)
	return -1050 + math.sin(z / 430 + 1.7) * 260 + math.sin(z / 170) * 65
end

function Terrain.riverThreeCenter(x)
	return 1050 + math.sin(x / 500 + .8) * 300 + math.sin(x / 210) * 70
end

local function lakeInfluence(x, z)
	local best, level = math.huge, nil
	for _, lake in ipairs(Config.LAKES) do
		local d = math.sqrt(((x-lake.x)/lake.rx)^2 + ((z-lake.z)/lake.rz)^2)
		if d < best then best, level = d, lake.level end
	end
	return best, level
end

local function flattenHeight(x, z, height)
	for _, zone in ipairs(Config.FLAT_ZONES) do
		local dx, dz = x - zone.x, z - zone.z
		local distance = math.sqrt(dx * dx + dz * dz)
		if distance < zone.radius then
			local blend = math.clamp((zone.radius - distance) / 70, 0, 1)
			height = height + (zone.height - height) * blend
		end
	end
	return height
end

function Terrain.heightAt(x, z)
	local broad = math.noise(x / 720, z / 720, 19) * 42
	local detail = math.noise(x / 210, z / 210, 41) * 16
	local ridgeNoise = math.abs(math.noise(x / 480, z / 480, 77))
	local edge = math.max(math.abs(x), math.abs(z)) / Config.LAND_HALF
	local mountains = math.max(0, edge - 0.58) * 190 + ridgeNoise * math.max(0, edge - 0.35) * 95
	local h = 15 + broad + detail + mountains

	local d1 = math.abs(x - Terrain.riverCenter(z))
	local d2 = math.abs(x - Terrain.riverTwoCenter(z))
	local d3 = math.abs(z - Terrain.riverThreeCenter(x))
	local distanceToRiver = math.min(d1, d2, d3)
	if distanceToRiver < Config.RIVER_HALF_WIDTH + 34 then
		local t = math.clamp(distanceToRiver / (Config.RIVER_HALF_WIDTH + 34), 0, 1)
		h = Config.WATER_LEVEL - 9 + t * t * math.max(0, h - (Config.WATER_LEVEL - 9))
	end
	local lakeD, lakeLevel = lakeInfluence(x, z)
	if lakeLevel and lakeD < 1.18 then
		local t = math.clamp((lakeD - .78) / .4, 0, 1)
		h = (lakeLevel - 10) * (1-t) + h * t
	end
	h = flattenHeight(x, z, h)

	if distanceToRiver < Config.RIVER_HALF_WIDTH + 34 then
		local t = math.clamp(distanceToRiver / (Config.RIVER_HALF_WIDTH + 34), 0, 1)
		h = math.min(h, Config.WATER_LEVEL - 10 + t * t * 16)
	end
	if lakeLevel and lakeD < 1.18 then
		local t = math.clamp((lakeD - .78) / .4, 0, 1)
		h = math.min(h, (lakeLevel - 11) + t * 18)
	end
	return math.max(-8, h)
end

function Terrain.generate(terrain)
	for x = -Config.LAND_HALF, Config.LAND_HALF, Config.CELL do
		for z = -Config.LAND_HALF, Config.LAND_HALF, Config.CELL do
			local h = Terrain.heightAt(x, z)
			local material = h > 55 and Enum.Material.Rock or Enum.Material.Grass
			terrain:FillBlock(CFrame.new(x, (h - 22) / 2, z), Vector3.new(Config.CELL + 1, h + 22, Config.CELL + 1), material)
		end
	end
end

return Terrain
