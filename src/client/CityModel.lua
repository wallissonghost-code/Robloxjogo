-- Client-only isometric 3D miniature for the City building.
-- ViewportFrame renders Parts offscreen; no Parts are added to Workspace.
local CityModel = {}

local function part(parent, name, size, position, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.Size = size
    p.Position = position
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.Parent = parent
    return p
end

local function building(parent, x, z, width, height, depth, facade, roof)
    part(parent, "Building", Vector3.new(width, height, depth), Vector3.new(x, height / 2 + 0.12, z), facade)
    part(parent, "Roof", Vector3.new(width + 0.15, 0.14, depth + 0.15), Vector3.new(x, height + 0.2, z), roof)
    local windows = Color3.fromRGB(255, 208, 112)
    -- Window panels on both camera-facing walls, rather than hundreds of tiny parts.
    for floor = 1, math.floor((height - 0.4) / 0.68) do
        local y = floor * 0.68
        for i = -1, 1 do
            local wx = x + i * width * 0.26
            part(parent, "FrontWindow", Vector3.new(0.20, 0.29, 0.035), Vector3.new(wx, y, z + depth / 2 + 0.025), windows, Enum.Material.Neon)
            local wz = z + i * depth * 0.26
            part(parent, "SideWindow", Vector3.new(0.035, 0.29, 0.20), Vector3.new(x + width / 2 + 0.025, y, wz), windows, Enum.Material.Neon)
        end
    end
end

function CityModel.attach(parent, zIndex)
    local viewport = Instance.new("ViewportFrame")
    viewport.Name = "City3D"
    viewport.BackgroundTransparency = 1
    viewport.BorderSizePixel = 0
    viewport.Size = UDim2.fromScale(1, 1)
    viewport.ZIndex = zIndex or 6
    viewport.Ambient = Color3.fromRGB(170, 182, 203)
    viewport.LightColor = Color3.fromRGB(255, 233, 193)
    viewport.LightDirection = Vector3.new(-1, -2, -1)
    viewport.Parent = parent

    local world = Instance.new("WorldModel")
    world.Parent = viewport
    part(world, "CityBlock", Vector3.new(8.5, 0.24, 7.5), Vector3.new(0, -0.08, 0), Color3.fromRGB(66, 78, 83))
    part(world, "Street", Vector3.new(1.0, 0.03, 7.1), Vector3.new(0.6, 0.06, 0), Color3.fromRGB(39, 48, 57))
    part(world, "CrossStreet", Vector3.new(8.1, 0.03, 0.9), Vector3.new(0, 0.07, 1.5), Color3.fromRGB(39, 48, 57))
    building(world, -2.35, -1.25, 1.75, 3.5, 1.7, Color3.fromRGB(85, 130, 160), Color3.fromRGB(50, 76, 101))
    building(world, 2.25, -1.35, 1.65, 5.4, 1.55, Color3.fromRGB(103, 137, 164), Color3.fromRGB(55, 76, 101))
    building(world, -2.2, 2.5, 1.7, 2.25, 1.3, Color3.fromRGB(156, 115, 93), Color3.fromRGB(94, 73, 69))
    building(world, 2.15, 2.45, 1.65, 2.9, 1.4, Color3.fromRGB(121, 144, 151), Color3.fromRGB(69, 89, 101))
    local camera = Instance.new("Camera")
    camera.FieldOfView = 36
    camera.CFrame = CFrame.lookAt(Vector3.new(13, 13, 17), Vector3.new(0, 1.8, 0))
    camera.Parent = viewport
    viewport.CurrentCamera = camera
    return viewport
end

return CityModel
