-- Screen-space 2D terrain: independent of 3D draw distance and streaming.
local MapView = {}
MapView.__index = MapView

function MapView.new(viewport, grid, config)
    local canvas = Instance.new("Frame")
    canvas.Name = "Terrain"
    canvas.AnchorPoint = Vector2.new(0.5, 0.5)
    canvas.BorderSizePixel = 0
    canvas.BackgroundColor3 = Color3.fromRGB(table.unpack(config.WaterColor))
    canvas.Parent = viewport
    local self = setmetatable({Viewport = viewport, Canvas = canvas, Grid = grid,
        Config = config, Zoom = config.MinZoom, Pan = Vector2.zero,
        Chunks = {}, RectangleCount = 0}, MapView)
    local count = math.ceil(grid.Width / grid.ChunkSize) * math.ceil(grid.Height / grid.ChunkSize)
    for chunkId = 1, count do self:RebuildChunk(chunkId) end
    self:Layout()
    self.ResizeConnection = viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        self:Layout()
    end)
    return self
end

function MapView:RebuildChunk(chunkId)
    if self.Chunks[chunkId] then
        for _, frame in ipairs(self.Chunks[chunkId]) do
            frame:Destroy()
            self.RectangleCount = self.RectangleCount - 1
        end
    end
    local frames = {}
    for _, rectangle in ipairs(self.Grid:GetLandRectangles(chunkId)) do
        local frame = Instance.new("Frame")
        frame.Name = "Land"
        frame.BorderSizePixel = 0
        frame.BackgroundColor3 = Color3.fromRGB(table.unpack(self.Config.LandColor))
        frame.Position = UDim2.fromScale((rectangle.X - 1) / self.Grid.Width,
            (rectangle.Y - 1) / self.Grid.Height)
        frame.Size = UDim2.fromScale(rectangle.Width / self.Grid.Width,
            rectangle.Height / self.Grid.Height)
        frame.Parent = self.Canvas
        frames[#frames + 1] = frame
        self.RectangleCount = self.RectangleCount + 1
    end
    self.Chunks[chunkId] = frames
end

function MapView:Layout()
    local size = self.Viewport.AbsoluteSize
    if size.X <= 0 or size.Y <= 0 then return end
    local fit = math.min(size.X / self.Grid.Width, size.Y / self.Grid.Height) * 0.96
    local width, height = self.Grid.Width * fit * self.Zoom, self.Grid.Height * fit * self.Zoom
    local maxX, maxY = math.max(0, (width - size.X) / 2), math.max(0, (height - size.Y) / 2)
    self.Pan = Vector2.new(math.clamp(self.Pan.X, -maxX, maxX), math.clamp(self.Pan.Y, -maxY, maxY))
    self.Canvas.Size = UDim2.fromOffset(width, height)
    self.Canvas.Position = UDim2.fromOffset(size.X / 2 + self.Pan.X, size.Y / 2 + self.Pan.Y)
end

function MapView:PanBy(delta)
    self.Pan = self.Pan + delta
    self:Layout()
end

function MapView:SetZoom(value, screenAnchor)
    local nextZoom = math.clamp(value, self.Config.MinZoom, self.Config.MaxZoom)
    local center = self.Viewport.AbsolutePosition + self.Viewport.AbsoluteSize / 2
    local anchor = screenAnchor and screenAnchor - center or Vector2.zero
    self.Pan = anchor + (self.Pan - anchor) * (nextZoom / self.Zoom)
    self.Zoom = nextZoom
    self:Layout()
end

function MapView:Reset()
    self.Zoom, self.Pan = self.Config.MinZoom, Vector2.zero
    self:Layout()
end

function MapView:CellAt(screenPosition)
    local size = self.Canvas.AbsoluteSize
    if size.X <= 0 or size.Y <= 0 then return nil end
    local point = screenPosition - self.Canvas.AbsolutePosition
    if point.X < 0 or point.Y < 0 or point.X >= size.X or point.Y >= size.Y then return nil end
    return self.Grid:ToId(math.floor(point.X / size.X * self.Grid.Width) + 1,
        math.floor(point.Y / size.Y * self.Grid.Height) + 1)
end

function MapView:Destroy()
    self.ResizeConnection:Disconnect()
    self.Canvas:Destroy()
end

return MapView
