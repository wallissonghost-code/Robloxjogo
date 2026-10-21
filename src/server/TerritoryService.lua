local Players = game:GetService("Players")

local TerritoryService = {}

local Config
local TroopService
local cells = {}
local owned = {}

local function key(x, z)
    return x .. ":" .. z
end

local function colorFor(player)
    local h = (player.UserId * 0.61803398875) % 1
    return Color3.fromHSV(h, 0.55, 0.92)
end

local function neighbors(cell)
    return {
        cells[key(cell.X + 1, cell.Z)],
        cells[key(cell.X - 1, cell.Z)],
        cells[key(cell.X, cell.Z + 1)],
        cells[key(cell.X, cell.Z - 1)],
    }
end

local function isAdjacentToPlayer(cell, player)
    for _, other in ipairs(neighbors(cell)) do
        if other and other.Owner == player then return true end
    end
    return false
end

local function largestComponent(player)
    local list = owned[player]
    if not list then return nil, 0 end
    local visited = {}
    local best, bestCount = nil, 0

    for _, start in pairs(list) do
        if not visited[start] then
            local queue, head, component = {start}, 1, {}
            visited[start] = true
            while queue[head] do
                local current = queue[head]
                head += 1
                table.insert(component, current)
                for _, n in ipairs(neighbors(current)) do
                    if n and n.Owner == player and not visited[n] then
                        visited[n] = true
                        table.insert(queue, n)
                    end
                end
            end
            if #component > bestCount then
                best, bestCount = component, #component
            end
        end
    end
    return best, bestCount
end

local function updateMarker(player)
    local component, count = largestComponent(player)
    local marker = workspace.PixelWarMap.Markers:FindFirstChild(tostring(player.UserId))
    if not component or count == 0 then
        if marker then marker:Destroy() end
        return
    end

    local sx, sz = 0, 0
    for _, cell in ipairs(component) do
        sx += cell.Part.Position.X
        sz += cell.Part.Position.Z
    end
    local position = Vector3.new(sx / count, Config.Map.CellHeight + 0.8, sz / count)

    if not marker then
        marker = Instance.new("Part")
        marker.Name = tostring(player.UserId)
        marker.Anchored = true
        marker.CanCollide = false
        marker.CanQuery = false
        marker.Transparency = 1
        marker.Size = Vector3.new(1,1,1)
        marker.Parent = workspace.PixelWarMap.Markers

        local gui = Instance.new("BillboardGui")
        gui.Name = "Label"
        gui.AlwaysOnTop = true
        gui.Size = UDim2.fromOffset(260, 64)
        gui.StudsOffsetWorldSpace = Vector3.new(0, 1, 0)
        gui.Parent = marker

        local avatar = Instance.new("ImageLabel")
        avatar.Name = "Avatar"
        avatar.BackgroundTransparency = 1
        avatar.Size = UDim2.fromOffset(42,42)
        avatar.Position = UDim2.fromOffset(0,8)
        avatar.Parent = gui
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1,0)
        corner.Parent = avatar
        task.spawn(function()
            local ok, image = pcall(Players.GetUserThumbnailAsync, Players, player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
            if ok and avatar.Parent then avatar.Image = image end
        end)

        local name = Instance.new("TextLabel")
        name.Name = "PlayerName"
        name.BackgroundTransparency = 1
        name.Position = UDim2.fromOffset(48,0)
        name.Size = UDim2.fromOffset(212,36)
        name.Font = Enum.Font.GothamBold
        name.TextColor3 = Color3.new(1,1,1)
        name.TextStrokeTransparency = 0.15
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Text = player.DisplayName
        name.Parent = gui

        local troops = Instance.new("TextLabel")
        troops.Name = "Troops"
        troops.BackgroundTransparency = 1
        troops.Position = UDim2.fromOffset(48,34)
        troops.Size = UDim2.fromOffset(212,26)
        troops.Font = Enum.Font.GothamBold
        troops.TextColor3 = Color3.new(1,1,1)
        troops.TextStrokeTransparency = 0.2
        troops.TextXAlignment = Enum.TextXAlignment.Left
        troops.Parent = gui
    end

    marker.Position = position
    local gui = marker.Label
    local scale = math.clamp(0.55 + math.log(count + 1) / 5, 0.6, 1.35)
    gui.Size = UDim2.fromOffset(260 * scale, 64 * scale)
    gui.PlayerName.TextSize = math.floor(22 * scale)
    gui.Troops.TextSize = math.floor(17 * scale)
end

local function formatNumber(v)
    if v >= 1e6 then return string.format("%.2fM", v/1e6) end
    if v >= 1e3 then return string.format("%.2fK", v/1e3) end
    return tostring(math.floor(v))
end

function TerritoryService.Init(config, troopService)
    Config = config
    TroopService = troopService
end

function TerritoryService.BuildMap()
    local old = workspace:FindFirstChild("PixelWarMap")
    if old then old:Destroy() end

    local map = Instance.new("Folder")
    map.Name = "PixelWarMap"
    map.Parent = workspace

    local cellFolder = Instance.new("Folder")
    cellFolder.Name = "Cells"
    cellFolder.Parent = map

    local markers = Instance.new("Folder")
    markers.Name = "Markers"
    markers.Parent = map

    table.clear(cells)
    table.clear(owned)

    local widthStuds = Config.Map.Width * Config.Map.CellSize
    local heightStuds = Config.Map.Height * Config.Map.CellSize
    local startX = Config.Map.Origin.X - widthStuds/2 + Config.Map.CellSize/2
    local startZ = Config.Map.Origin.Z - heightStuds/2 + Config.Map.CellSize/2

    -- Water is one continuous board behind the playable land.
    local water = Instance.new("Part")
    water.Name = "Water"
    water.Anchored = true
    water.CanCollide = false
    water.CanQuery = false
    water.Size = Vector3.new(widthStuds + 36, Config.Map.CellHeight * 0.45, heightStuds + 36)
    water.Position = Vector3.new(Config.Map.Origin.X, Config.Map.Origin.Y - Config.Map.CellHeight * 0.65, Config.Map.Origin.Z)
    water.Material = Enum.Material.SmoothPlastic
    water.Color = Config.Map.WaterColor
    water.Parent = map

    local function isLand(x, z)
        -- Deterministic low-resolution island mask. The lobes make coastlines
        -- irregular while keeping every playable cell connected.
        local nx = (x - (Config.Map.Width + 1)/2) / (Config.Map.Width/2)
        local nz = (z - (Config.Map.Height + 1)/2) / (Config.Map.Height/2)
        local wobble =
            0.10 * math.sin(z * 0.63) +
            0.07 * math.sin(x * 0.41) +
            0.05 * math.sin((x + z) * 0.31)
        local body = (nx*nx)/1.02 + (nz*nz)/0.76
        local westBay = ((nx + 0.55)^2)/0.13 + ((nz - 0.05)^2)/0.20
        local eastPeninsula = ((nx - 0.70)^2)/0.20 + ((nz + 0.12)^2)/0.12
        local land = body < (0.91 + wobble)
        if westBay < 0.50 then land = false end
        if eastPeninsula < 0.82 then land = true end
        return land
    end

    local landMask = {}
    for z = 1, Config.Map.Height do
        landMask[z] = {}
        for x = 1, Config.Map.Width do
            landMask[z][x] = isLand(x,z)
        end
    end

    local function isCoast(x,z)
        if not landMask[z][x] then return false end
        local dirs = {{1,0},{-1,0},{0,1},{0,-1}}
        for _,d in ipairs(dirs) do
            local xx,zz=x+d[1],z+d[2]
            if xx < 1 or xx > Config.Map.Width or zz < 1 or zz > Config.Map.Height or not landMask[zz][xx] then
                return true
            end
        end
        return false
    end

    for z = 1, Config.Map.Height do
        for x = 1, Config.Map.Width do
            if landMask[z][x] then
                local part = Instance.new("Part")
                part.Name = string.format("C_%d_%d", x, z)
                part.Anchored = true
                part.CanCollide = false
                part.Size = Vector3.new(Config.Map.CellSize - Config.Map.CellGap, Config.Map.CellHeight, Config.Map.CellSize - Config.Map.CellGap)
                part.Position = Vector3.new(startX + (x-1)*Config.Map.CellSize, Config.Map.Origin.Y, startZ + (z-1)*Config.Map.CellSize)
                part.Material = Enum.Material.SmoothPlastic
                part.Color = isCoast(x,z) and Config.Map.CoastColor or Config.Map.NeutralColor
                part:SetAttribute("BaseColor", part.Color)
                part:SetAttribute("GridX", x)
                part:SetAttribute("GridZ", z)
                part.Parent = cellFolder
                cells[key(x,z)] = {X=x, Z=z, Part=part, Owner=nil}
            end
        end
    end
end

function TerritoryService.TryClaim(player, part)
    if not part or part.Parent ~= workspace.PixelWarMap.Cells then return false end
    local x, z = part:GetAttribute("GridX"), part:GetAttribute("GridZ")
    local cell = x and z and cells[key(x,z)]
    if not cell or cell.Owner then return false end

    local playerCells = owned[player]
    local firstClaim = not playerCells or next(playerCells) == nil
    if not firstClaim and not isAdjacentToPlayer(cell, player) then return false end

    local cost = firstClaim and 0 or Config.Territory.NeutralClaimCost
    if cost > 0 and not TroopService.Spend(player, cost) then return false end

    cell.Owner = player
    cell.Part.Color = colorFor(player)
    cell.Part:SetAttribute("OwnerUserId", player.UserId)
    owned[player] = owned[player] or {}
    owned[player][key(x,z)] = cell

    local count = 0
    for _ in pairs(owned[player]) do count += 1 end
    player:SetAttribute("TerritoryCells", count)
    updateMarker(player)
    return true
end

function TerritoryService.RemovePlayer(player)
    local list = owned[player]
    if list then
        for _, cell in pairs(list) do
            cell.Owner = nil
            cell.Part.Color = cell.Part:GetAttribute("BaseColor") or Config.Map.NeutralColor
            cell.Part:SetAttribute("OwnerUserId", nil)
        end
    end
    owned[player] = nil
    local map = workspace:FindFirstChild("PixelWarMap")
    local marker = map and map.Markers:FindFirstChild(tostring(player.UserId))
    if marker then marker:Destroy() end
end

function TerritoryService.RefreshTroops(player)
    local map = workspace:FindFirstChild("PixelWarMap")
    local marker = map and map.Markers:FindFirstChild(tostring(player.UserId))
    if marker and marker:FindFirstChild("Label") then
        marker.Label.Troops.Text = formatNumber(TroopService.Get(player))
    end
end

return TerritoryService
