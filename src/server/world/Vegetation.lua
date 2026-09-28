local Config = require(script.Parent.Config)
local TerrainShape = require(script.Parent.Terrain)

local Vegetation = {}

local function makeTree(parent, position, scale)
	local model = Instance.new("Model")
	model.Name = "Tree"
	model.Parent = parent

	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Anchored = true
	trunk.Material = Enum.Material.Wood
	trunk.Color = Color3.fromRGB(91, 63, 42)
	trunk.Size = Vector3.new(2.2, 9, 2.2) * scale
	trunk.CFrame = CFrame.new(position + Vector3.new(0, trunk.Size.Y / 2, 0))
	trunk.Parent = model

	local crown = Instance.new("Part")
	crown.Name = "Crown"
	crown.Shape = Enum.PartType.Ball
	crown.Anchored = true
	crown.CanCollide = false
	crown.Material = Enum.Material.Grass
	crown.Color = Color3.fromRGB(48, 102, 48)
	crown.Size = Vector3.new(9, 8, 9) * scale
	crown.CFrame = CFrame.new(position + Vector3.new(0, trunk.Size.Y + crown.Size.Y * .25, 0))
	crown.Parent = model
end

function Vegetation.generate(workspace)
	local vegetation = Instance.new("Folder")
	vegetation.Name = "Vegetation"
	vegetation.Parent = workspace

	local rng = Random.new(Config.SEED)
	for _ = 1, 900 do
		local x = rng:NextNumber(-Config.WORLD*.43, Config.WORLD*.43)
		local z = rng:NextNumber(-Config.WORLD*.43, Config.WORLD*.43)
		local h = TerrainShape.heightAt(x, z)
		if math.abs(x - TerrainShape.riverCenter(z)) > 28 and h > 7 and h < 54 then
			makeTree(vegetation, Vector3.new(x, h + .5, z), rng:NextNumber(.75, 1.25))
		end
	end

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
