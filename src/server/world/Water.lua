local Config = require(script.Parent.Config)
local TerrainShape = require(script.Parent.Terrain)

local Water = {}

-- Water is voxel terrain. If its outermost voxel is left exposed, Roblox renders
-- a vertical blue face ("frozen wave"). Build a terrain shoreline outside every
-- water fill so the bank, rather than the water side, is what remains visible.
local function terrainHeightForBank(x, z, waterLevel)
	local naturalHeight = TerrainShape.heightAt(x, z)
	return math.max(naturalHeight, waterLevel + 2)
end

local function fillBankCell(terrain, x, z, top, size)
	local bottom = -10
	local height = math.max(4, top - bottom)
	terrain:FillBlock(
		CFrame.new(x, bottom + height / 2, z),
		Vector3.new(size, height, size),
		Enum.Material.Grass
	)
end

local function fillWaterDisc(terrain, cx, cz, level, radius)
	local step = 12
	local bankWidth = step * 2

	-- Continuous terrain collar around the river section. It is generated first;
	-- the water then overwrites only the channel interior.
	for x = cx-radius-bankWidth, cx+radius+bankWidth, step do
		for z = cz-radius-bankWidth, cz+radius+bankWidth, step do
			local dx, dz = x-cx, z-cz
			local distance = math.sqrt(dx*dx + dz*dz)
			if distance > radius and distance <= radius + bankWidth then
				fillBankCell(terrain, x, z, terrainHeightForBank(x, z, level), step+2)
			end
		end
	end

	for x = cx-radius, cx+radius, step do
		for z = cz-radius, cz+radius, step do
			local dx, dz = x-cx, z-cz
			if dx*dx + dz*dz <= radius*radius then
				local ground = level - 12
				terrain:FillBlock(CFrame.new(x, ground + 2, z), Vector3.new(step+2, 4, step+2), Enum.Material.Sand)
				terrain:FillBlock(CFrame.new(x, level - 3, z), Vector3.new(step+2, 6, step+2), Enum.Material.Water)
			end
		end
	end
end

local function fillLake(terrain, lake)
	local step = 16
	local bankWidth = 32

	-- Elliptical shoreline collar. This fixes the same exposed-water edge for all
	-- lakes without hard-coding individual coordinates.
	for x = lake.x-lake.rx-bankWidth, lake.x+lake.rx+bankWidth, step do
		for z = lake.z-lake.rz-bankWidth, lake.z+lake.rz+bankWidth, step do
			local inner = ((x-lake.x)/lake.rx)^2 + ((z-lake.z)/lake.rz)^2
			local outer = ((x-lake.x)/(lake.rx+bankWidth))^2 + ((z-lake.z)/(lake.rz+bankWidth))^2
			if inner > 1 and outer <= 1 then
				fillBankCell(terrain, x, z, terrainHeightForBank(x, z, lake.level), step+2)
			end
		end
	end

	for x = lake.x-lake.rx, lake.x+lake.rx, step do
		for z = lake.z-lake.rz, lake.z+lake.rz, step do
			local d = ((x-lake.x)/lake.rx)^2 + ((z-lake.z)/lake.rz)^2
			if d <= 1 then
				terrain:FillBlock(CFrame.new(x, lake.level-9, z), Vector3.new(step+2, 5, step+2), Enum.Material.Sand)
				terrain:FillBlock(CFrame.new(x, lake.level-3, z), Vector3.new(step+2, 7, step+2), Enum.Material.Water)
			end
		end
	end
end

function Water.generate(terrain)
	local riverStep = 18
	for z = -Config.LAND_HALF, Config.LAND_HALF, riverStep do
		fillWaterDisc(terrain, TerrainShape.riverCenter(z), z, Config.WATER_LEVEL, Config.RIVER_HALF_WIDTH)
		fillWaterDisc(terrain, TerrainShape.riverTwoCenter(z), z, Config.WATER_LEVEL-1, Config.RIVER_HALF_WIDTH+6)
	end
	for x = -Config.LAND_HALF, Config.LAND_HALF, riverStep do
		fillWaterDisc(terrain, x, TerrainShape.riverThreeCenter(x), Config.WATER_LEVEL+1, Config.RIVER_HALF_WIDTH+4)
	end

	for _, lake in ipairs(Config.LAKES) do
		fillLake(terrain, lake)
	end
end

return Water
