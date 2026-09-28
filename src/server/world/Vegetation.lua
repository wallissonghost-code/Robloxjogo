local Config = require(script.Parent.Config)
local TerrainShape = require(script.Parent.Terrain)

local Vegetation = {}

function Vegetation.generate(workspace)
	local vegetation = Instance.new("Folder")
	vegetation.Name = "Vegetation"
	vegetation.Parent = workspace

	local rng = Random.new(Config.SEED)

	local grassFolder = Instance.new("Folder")
	grassFolder.Name = "GrassDetails"
	grassFolder.Parent = vegetation
	for _ = 1, 1600 do
		local x = rng:NextNumber(-Config.WORLD*.42, Config.WORLD*.42)
		local z = rng:NextNumber(-Config.WORLD*.42, Config.WORLD*.42)
		local h = TerrainShape.heightAt(x, z)
		if math.abs(x - TerrainShape.riverCenter(z)) > 21 and h > 6 and h < 48 then
			local blade = Instance.new("Part")
			blade.Name = "WildGrass"
			blade.Anchored = true
			blade.CanCollide = false
			blade.CanTouch = false
			blade.Material = Enum.Material.Grass
			blade.Color = Color3.fromRGB(72, 126, 58)
			blade.Size = Vector3.new(.18, rng:NextNumber(1.3, 2.8), .18)
			blade.CFrame = CFrame.new(x, h + blade.Size.Y/2, z) * CFrame.Angles(rng:NextNumber(-.12,.12), rng:NextNumber(0,6.28), rng:NextNumber(-.12,.12))
			blade.Parent = grassFolder
		end
	end
end

return Vegetation
