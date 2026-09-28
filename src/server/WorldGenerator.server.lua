local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local terrain = Workspace.Terrain
terrain:Clear()

local WORLD = 520
local CELL = 8
local WATER_LEVEL = 4
local RIVER_HALF_WIDTH = 15

local function riverCenter(z)
	return math.sin(z / 72) * 38 + math.sin(z / 31) * 10
end

local function heightAt(x, z)
	local broad = math.noise(x / 150, z / 150, 19) * 30
	local detail = math.noise(x / 58, z / 58, 41) * 12
	local ridgeNoise = math.abs(math.noise(x / 105, z / 105, 77))
	local edge = math.max(math.abs(x), math.abs(z)) / (WORLD * 0.5)
	local mountains = math.max(0, edge - 0.42) * 105 + ridgeNoise * math.max(0, edge - 0.25) * 55
	local h = 15 + broad + detail + mountains

	local distanceToRiver = math.abs(x - riverCenter(z))
	if distanceToRiver < RIVER_HALF_WIDTH + 13 then
		local t = math.clamp(distanceToRiver / (RIVER_HALF_WIDTH + 13), 0, 1)
		h = WATER_LEVEL - 7 + t * t * math.max(0, h - (WATER_LEVEL - 7))
	end
	return math.max(-5, h)
end

for x = -WORLD/2, WORLD/2, CELL do
	for z = -WORLD/2, WORLD/2, CELL do
		local h = heightAt(x, z)
		local material = h > 55 and Enum.Material.Rock or Enum.Material.Grass
		terrain:FillBlock(CFrame.new(x, (h - 22) / 2, z), Vector3.new(CELL + 1, h + 22, CELL + 1), material)
	end
end

-- Continuous winding river with a natural bed.
for z = -WORLD/2, WORLD/2, CELL do
	local x = riverCenter(z)
	terrain:FillBlock(CFrame.new(x, WATER_LEVEL - 4.5, z), Vector3.new(RIVER_HALF_WIDTH * 2, 5, CELL + 2), Enum.Material.Sand)
	terrain:FillBlock(CFrame.new(x, WATER_LEVEL - 1.5, z), Vector3.new(RIVER_HALF_WIDTH * 2 - 3, 5, CELL + 2), Enum.Material.Water)
end

local vegetation = Instance.new("Folder")
vegetation.Name = "Vegetation"
vegetation.Parent = Workspace

local rng = Random.new(2709)
local function makeTree(position, scale)
	local model = Instance.new("Model")
	model.Name = "Tree"
	model.Parent = vegetation

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

for i = 1, 125 do
	local x = rng:NextNumber(-WORLD*.43, WORLD*.43)
	local z = rng:NextNumber(-WORLD*.43, WORLD*.43)
	local h = heightAt(x, z)
	if math.abs(x - riverCenter(z)) > 28 and h > 7 and h < 54 then
		makeTree(Vector3.new(x, h + .5, z), rng:NextNumber(.75, 1.25))
	end
end

local grassFolder = Instance.new("Folder")
grassFolder.Name = "GrassDetails"
grassFolder.Parent = vegetation
for i = 1, 260 do
	local x = rng:NextNumber(-WORLD*.42, WORLD*.42)
	local z = rng:NextNumber(-WORLD*.42, WORLD*.42)
	local h = heightAt(x, z)
	if math.abs(x - riverCenter(z)) > 21 and h > 6 and h < 48 then
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

local spawn = Workspace:FindFirstChild("SpawnLocation")
if spawn then
	local y = heightAt(0, 0)
	spawn.CFrame = CFrame.new(0, y + 4, 0)
end

Lighting.ClockTime = 14.2
Lighting.Brightness = 2
Lighting.EnvironmentDiffuseScale = .35
Lighting.EnvironmentSpecularScale = .45
Lighting.Ambient = Color3.fromRGB(105, 112, 105)
Lighting.OutdoorAmbient = Color3.fromRGB(135, 145, 140)

local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmosphere.Density = .28
atmosphere.Offset = .12
atmosphere.Color = Color3.fromRGB(205, 220, 225)
atmosphere.Decay = Color3.fromRGB(100, 125, 110)
atmosphere.Glare = .08
atmosphere.Haze = 1.2
atmosphere.Parent = Lighting
