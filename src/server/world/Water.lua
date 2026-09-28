local Config = require(script.Parent.Config)
local TerrainShape = require(script.Parent.Terrain)

local Water = {}

local function fillWaterDisc(terrain, cx, cz, level, radius)
	local step = 12
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
		local step = 16
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
end

return Water
