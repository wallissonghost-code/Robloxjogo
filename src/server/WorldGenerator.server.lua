local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local terrain = Workspace.Terrain
terrain:Clear()

local WORLD = 5200
local CELL = 20
local WATER_LEVEL = 4
local RIVER_HALF_WIDTH = 34
local BOUNDARY_HEIGHT = 1400

local function riverCenter(z)
	return math.sin(z / 520) * 180 + math.sin(z / 190) * 55
end

local function riverTwoCenter(z)
	return -1050 + math.sin(z / 430 + 1.7) * 260 + math.sin(z / 170) * 65
end

local function riverThreeCenter(x)
	return 1050 + math.sin(x / 500 + .8) * 300 + math.sin(x / 210) * 70
end

local LAKES = {
	{ x = 850, z = -850, rx = 230, rz = 165, level = 6 },
	{ x = -1250, z = 1050, rx = 290, rz = 205, level = 3 },
	{ x = 1450, z = 1250, rx = 190, rz = 250, level = 8 },
	{ x = -1550, z = -1150, rx = 240, rz = 180, level = 5 },
}

local function lakeInfluence(x, z)
	local best, level = math.huge, nil
	for _, lake in ipairs(LAKES) do
		local d = math.sqrt(((x-lake.x)/lake.rx)^2 + ((z-lake.z)/lake.rz)^2)
		if d < best then best, level = d, lake.level end
	end
	return best, level
end

local FLAT_ZONES = {
	{ x = 0, z = 0, radius = 180, height = 18 },
	{ x = 820, z = -620, radius = 240, height = 24 },
	{ x = -1050, z = 760, radius = 280, height = 20 },
	{ x = 1250, z = 1150, radius = 220, height = 28 },
	{ x = -1450, z = -1050, radius = 260, height = 22 },
}

local function flattenHeight(x, z, height)
	for _, zone in ipairs(FLAT_ZONES) do
		local dx, dz = x - zone.x, z - zone.z
		local distance = math.sqrt(dx * dx + dz * dz)
		if distance < zone.radius then
			local blend = math.clamp((zone.radius - distance) / 70, 0, 1)
			height = height + (zone.height - height) * blend
		end
	end
	return height
end

local function heightAt(x, z)
	local broad = math.noise(x / 720, z / 720, 19) * 42
	local detail = math.noise(x / 210, z / 210, 41) * 16
	local ridgeNoise = math.abs(math.noise(x / 480, z / 480, 77))
	local edge = math.max(math.abs(x), math.abs(z)) / (WORLD * 0.5)
	local mountains = math.max(0, edge - 0.58) * 190 + ridgeNoise * math.max(0, edge - 0.35) * 95
	local h = 15 + broad + detail + mountains

	local d1 = math.abs(x - riverCenter(z))
	local d2 = math.abs(x - riverTwoCenter(z))
	local d3 = math.abs(z - riverThreeCenter(x))
	local distanceToRiver = math.min(d1, d2, d3)
	if distanceToRiver < RIVER_HALF_WIDTH + 34 then
		local t = math.clamp(distanceToRiver / (RIVER_HALF_WIDTH + 34), 0, 1)
		h = WATER_LEVEL - 9 + t * t * math.max(0, h - (WATER_LEVEL - 9))
	end
	local lakeD, lakeLevel = lakeInfluence(x, z)
	if lakeLevel and lakeD < 1.18 then
		local t = math.clamp((lakeD - .78) / .4, 0, 1)
		h = (lakeLevel - 10) * (1-t) + h * t
	end
	h = flattenHeight(x, z, h)
	return math.max(-5, h)
end

for x = -WORLD/2, WORLD/2, CELL do
	for z = -WORLD/2, WORLD/2, CELL do
		local h = heightAt(x, z)
		local material = h > 55 and Enum.Material.Rock or Enum.Material.Grass
		terrain:FillBlock(CFrame.new(x, (h - 22) / 2, z), Vector3.new(CELL + 1, h + 22, CELL + 1), material)
	end
end

-- Three broad river systems. Overlapping spherical stamps remove the old blocky channels.
local function stampRiver(x, z, level, radius)
	terrain:FillBall(Vector3.new(x, level - 7, z), radius + 7, Enum.Material.Sand)
	terrain:FillBall(Vector3.new(x, level - 2, z), radius, Enum.Material.Water)
end
local RIVER_STEP = 24
for z = -WORLD/2, WORLD/2, RIVER_STEP do
	stampRiver(riverCenter(z), z, WATER_LEVEL, RIVER_HALF_WIDTH)
	stampRiver(riverTwoCenter(z), z, WATER_LEVEL - 1, RIVER_HALF_WIDTH + 6)
end
for x = -WORLD/2, WORLD/2, RIVER_STEP do
	stampRiver(x, riverThreeCenter(x), WATER_LEVEL + 1, RIVER_HALF_WIDTH + 4)
end

-- Lakes use overlapping terrain balls for rounded shorelines and reliable water volume.
for _, lake in ipairs(LAKES) do
	for ox = -lake.rx*.72, lake.rx*.72, 32 do
		for oz = -lake.rz*.72, lake.rz*.72, 32 do
			local normalized = (ox/(lake.rx*.78))^2 + (oz/(lake.rz*.78))^2
			if normalized <= 1 then
				local radius = 32
				terrain:FillBall(Vector3.new(lake.x+ox, lake.level-8, lake.z+oz), radius+8, Enum.Material.Sand)
				terrain:FillBall(Vector3.new(lake.x+ox, lake.level-3, lake.z+oz), radius, Enum.Material.Water)
			end
		end
	end
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

for i = 1, 900 do
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
for i = 1, 1600 do
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

-- Invisible perimeter prevents players from walking into the void.
local barriers = Instance.new("Folder")
barriers.Name = "WorldBoundary"
barriers.Parent = Workspace
local half = WORLD / 2 + 12
local wallHeight = BOUNDARY_HEIGHT
local wallThickness = 10
local function wall(name, size, position)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Transparency = 1
	part.CanCollide = true
	part.CanTouch = false
	part.CanQuery = true
	part.Size = size
	part.Position = position
	part.Parent = barriers
end
wall("North", Vector3.new(WORLD + 40, wallHeight, wallThickness), Vector3.new(0, wallHeight/2, -half))
wall("South", Vector3.new(WORLD + 40, wallHeight, wallThickness), Vector3.new(0, wallHeight/2, half))
wall("West", Vector3.new(wallThickness, wallHeight, WORLD + 40), Vector3.new(-half, wallHeight/2, 0))
wall("East", Vector3.new(wallThickness, wallHeight, WORLD + 40), Vector3.new(half, wallHeight/2, 0))

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
