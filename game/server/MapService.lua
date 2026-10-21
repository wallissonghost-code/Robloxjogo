local MapService = {}

local Config
local cells = {}
local allLandCells = {}
local ownerCells = {}
local gridFolder
local objectsFolder
local landCount = 0

local function ellipse(nx, ny, cx, cy, rx, ry, rotation)
	local dx = nx - cx
	local dy = ny - cy
	local c = math.cos(rotation or 0)
	local s = math.sin(rotation or 0)
	local x = dx * c - dy * s
	local y = dx * s + dy * c
	return (x * x) / (rx * rx) + (y * y) / (ry * ry)
end

local function isLand(nx, ny)
	local n = math.noise(nx * 5.2, ny * 5.2) * 0.13
	local function e(cx, cy, rx, ry, rot)
		return ellipse(nx, ny, cx, cy, rx, ry, rot) <= 1 + n
	end

	-- North America + Central America
	if e(-0.58, 0.43, 0.31, 0.28, -0.22) or e(-0.48, 0.17, 0.13, 0.27, -0.38) then
		return true
	end
	-- South America
	if e(-0.31, -0.30, 0.17, 0.37, -0.24) or e(-0.25, -0.57, 0.10, 0.22, -0.18) then
		return true
	end
	-- Greenland
	if e(-0.20, 0.76, 0.12, 0.16, 0.20) then
		return true
	end
	-- Europe
	if e(0.02, 0.45, 0.19, 0.16, 0.06) then
		return true
	end
	-- Africa
	if e(0.08, -0.05, 0.19, 0.36, 0.10) then
		return true
	end
	-- Asia
	if e(0.39, 0.40, 0.43, 0.28, 0.04) or e(0.55, 0.18, 0.23, 0.22, -0.12) then
		return true
	end
	-- Arabia / India / SE Asia
	if e(0.25, 0.08, 0.13, 0.15, 0.15) or e(0.38, -0.02, 0.10, 0.22, -0.25) or e(0.57, -0.08, 0.19, 0.11, -0.15) then
		return true
	end
	-- Japan-like island strip
	if e(0.71, 0.25, 0.035, 0.12, 0.25) then
		return true
	end
	-- Australia
	if e(0.62, -0.48, 0.20, 0.16, 0.06) then
		return true
	end
	-- Madagascar and New Zealand
	if e(0.22, -0.49, 0.035, 0.10, -0.15) or e(0.83, -0.62, 0.035, 0.12, -0.22) then
		return true
	end
	return false
end

local function chooseNeutralColor(x, y, ny)
	if math.abs(ny) > 0.72 then
		return Color3.fromRGB(232, 234, 221)
	end
	local index = ((x * 31 + y * 17) % #Config.Map.NeutralColors) + 1
	return Config.Map.NeutralColors[index]
end

local function coordKey(x, y)
	return tostring(x) .. ":" .. tostring(y)
end

local function formatNumber(value)
	value = math.floor(value or 0)
	if value >= 1000000 then
		return string.format("%.2fM", value / 1000000)
	elseif value >= 1000 then
		return string.format("%.2fK", value / 1000)
	end
	return tostring(value)
end

function MapService.Init(config)
	Config = config
	cells = {}
	allLandCells = {}
	ownerCells = {}
	landCount = 0

	gridFolder = Instance.new("Folder")
	gridFolder.Name = "WorldGrid"
	gridFolder.Parent = workspace

	objectsFolder = Instance.new("Folder")
	objectsFolder.Name = "WorldObjects"
	objectsFolder.Parent = workspace

	local mapWidth = Config.Map.Columns * Config.Map.CellSize
	local mapHeight = Config.Map.Rows * Config.Map.CellSize

	local ocean = Instance.new("Part")
	ocean.Name = "Ocean"
	ocean.Anchored = true
	ocean.CanCollide = false
	ocean.CanTouch = false
	ocean.Size = Vector3.new(mapWidth + 40, 0.6, mapHeight + 40)
	ocean.Position = Vector3.new(0, -0.4, 0)
	ocean.Color = Config.Map.OceanColor
	ocean.Material = Enum.Material.SmoothPlastic
	ocean.Parent = workspace

	for x = 1, Config.Map.Columns do
		cells[x] = {}
		for y = 1, Config.Map.Rows do
			local nx = ((x - 0.5) / Config.Map.Columns) * 2 - 1
			local ny = 1 - ((y - 0.5) / Config.Map.Rows) * 2
			if isLand(nx, ny) then
				local cell = Instance.new("Part")
				cell.Name = "G_" .. x .. "_" .. y
				cell.Anchored = true
				cell.CanCollide = false
				cell.CanTouch = false
				cell.Size = Vector3.new(
					Config.Map.CellSize - Config.Map.CellGap,
					0.5,
					Config.Map.CellSize - Config.Map.CellGap
				)
				local px = (x - (Config.Map.Columns + 1) / 2) * Config.Map.CellSize
				local pz = (y - (Config.Map.Rows + 1) / 2) * Config.Map.CellSize
				cell.Position = Vector3.new(px, 0, pz)
				cell.Material = Enum.Material.SmoothPlastic

				local neutralColor = chooseNeutralColor(x, y, ny)
				cell.Color = neutralColor
				cell:SetAttribute("GX", x)
				cell:SetAttribute("GY", y)
				cell:SetAttribute("OwnerKey", "")
				cell:SetAttribute("OwnerName", "Neutro")
				cell:SetAttribute("NeutralColor", neutralColor)
				cell:SetAttribute("BuildingType", "")
				cell.Parent = gridFolder

				cells[x][y] = cell
				table.insert(allLandCells, cell)
				landCount += 1
			end
		end
	end

	workspace:SetAttribute("WarMapColumns", Config.Map.Columns)
	workspace:SetAttribute("WarMapRows", Config.Map.Rows)
	workspace:SetAttribute("WarCellSize", Config.Map.CellSize)
	workspace:SetAttribute("WarLandCells", landCount)
	workspace:SetAttribute("WarMapReady", true)
end

function MapService.GetCell(x, y)
	x = tonumber(x)
	y = tonumber(y)
	if not x or not y then
		return nil
	end
	x = math.floor(x)
	y = math.floor(y)
	return cells[x] and cells[x][y] or nil
end

function MapService.GetAllLandCells()
	return allLandCells
end

function MapService.GetLandCount()
	return landCount
end

function MapService.GetOwnedCount(ownerKey)
	local set = ownerCells[ownerKey]
	if not set then
		return 0
	end
	local count = 0
	for _ in pairs(set) do
		count += 1
	end
	return count
end

function MapService.GetOwnedCells(ownerKey)
	local result = {}
	local set = ownerCells[ownerKey]
	if set then
		for cell in pairs(set) do
			table.insert(result, cell)
		end
	end
	return result
end

function MapService.GetNeighbors(cell)
	local result = {}
	if not cell then
		return result
	end
	local x = cell:GetAttribute("GX")
	local y = cell:GetAttribute("GY")
	local offsets = {{1,0},{-1,0},{0,1},{0,-1}}
	for _, offset in ipairs(offsets) do
		local neighbor = MapService.GetCell(x + offset[1], y + offset[2])
		if neighbor then
			table.insert(result, neighbor)
		end
	end
	return result
end

function MapService.IsAdjacentToOwner(cell, ownerKey)
	for _, neighbor in ipairs(MapService.GetNeighbors(cell)) do
		if neighbor:GetAttribute("OwnerKey") == ownerKey then
			return true
		end
	end
	return false
end

function MapService.IsCoastal(cell)
	if not cell then
		return false
	end
	local x = cell:GetAttribute("GX")
	local y = cell:GetAttribute("GY")
	local offsets = {{1,0},{-1,0},{0,1},{0,-1}}
	for _, offset in ipairs(offsets) do
		if not MapService.GetCell(x + offset[1], y + offset[2]) then
			return true
		end
	end
	return false
end

function MapService.GetFrontierCandidates(ownerKey)
	local result = {}
	local seen = {}
	local set = ownerCells[ownerKey]
	if not set then
		return result
	end
	for cell in pairs(set) do
		for _, neighbor in ipairs(MapService.GetNeighbors(cell)) do
			if neighbor:GetAttribute("OwnerKey") ~= ownerKey then
				local key = coordKey(neighbor:GetAttribute("GX"), neighbor:GetAttribute("GY"))
				if not seen[key] then
					seen[key] = true
					table.insert(result, neighbor)
				end
			end
		end
	end
	return result
end

function MapService.SetOwner(cell, ownerKey, ownerName, color)
	if not cell then
		return
	end
	local oldKey = cell:GetAttribute("OwnerKey") or ""
	if oldKey ~= "" and ownerCells[oldKey] then
		ownerCells[oldKey][cell] = nil
	end

	ownerKey = ownerKey or ""
	cell:SetAttribute("OwnerKey", ownerKey)
	cell:SetAttribute("OwnerName", ownerName or "Neutro")

	if ownerKey == "" then
		cell.Color = cell:GetAttribute("NeutralColor") or Config.Map.NeutralColors[1]
	else
		ownerCells[ownerKey] = ownerCells[ownerKey] or {}
		ownerCells[ownerKey][cell] = true
		cell.Color = color
	end
end

function MapService.NeutralizeOwner(ownerKey)
	local owned = MapService.GetOwnedCells(ownerKey)
	for _, cell in ipairs(owned) do
		MapService.ClearBuilding(cell)
		MapService.SetOwner(cell, "", "Neutro", nil)
	end
	ownerCells[ownerKey] = nil
end

function MapService.ClearBuilding(cell)
	if not cell then
		return
	end
	cell:SetAttribute("BuildingType", "")
	local marker = cell:FindFirstChild("BuildMarker")
	if marker then
		marker:Destroy()
	end
end

function MapService.PlaceBuilding(cell, buildingType, state)
	MapService.ClearBuilding(cell)
	cell:SetAttribute("BuildingType", buildingType)

	local marker = Instance.new("BillboardGui")
	marker.Name = "BuildMarker"
	marker.AlwaysOnTop = true
	marker.Size = UDim2.fromOffset(38, 38)
	marker.StudsOffsetWorldSpace = Vector3.new(0, 2.8, 0)
	marker.Parent = cell

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(22, 27, 42)
	label.BackgroundTransparency = 0.08
	label.Text = Config.Buildings[buildingType].Icon
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = marker

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = label

	local stroke = Instance.new("UIStroke")
	stroke.Color = state.Color
	stroke.Thickness = 2
	stroke.Parent = label
end

function MapService.SetCapital(state, cell)
	if state.CapitalCell and state.CapitalCell ~= cell then
		local old = state.CapitalCell:FindFirstChild("NationLabel")
		if old then
			old:Destroy()
		end
	end
	state.CapitalCell = cell
	if not cell then
		return
	end

	local old = cell:FindFirstChild("NationLabel")
	if old then
		old:Destroy()
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "NationLabel"
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(220, 54)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
	gui.Parent = cell

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = state.Color
	label.TextStrokeColor3 = Color3.fromRGB(15, 15, 20)
	label.TextStrokeTransparency = 0.05
	label.Text = state.DisplayName
	label.Parent = gui

	MapService.UpdateCapitalLabel(state)
end

function MapService.UpdateCapitalLabel(state)
	local cell = state.CapitalCell
	if not cell then
		return
	end
	local gui = cell:FindFirstChild("NationLabel")
	local label = gui and gui:FindFirstChild("Text")
	if label then
		label.Text = state.DisplayName .. "\n" .. formatNumber(state.Troops)
	end
end

return MapService
