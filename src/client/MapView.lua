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
        Chunks = {}, RectangleCount = 0, Owners = {}, Nations = {}, Markers = {}, Routes = {}}, MapView)
    local selection = Instance.new("Frame")
    selection.Name = "SelectedCell"
    selection.AnchorPoint = Vector2.new(0.5, 0.5)
    selection.BackgroundTransparency = 1
    selection.Size = UDim2.fromOffset(16, 16)
    selection.ZIndex = 4
    selection.Visible = false
    selection.Parent = canvas
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
    stroke.Parent = selection
    self.Selection = selection
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
    for _, rectangle in ipairs(self.Grid:GetLandRectangles(chunkId, self.Owners)) do
        local frame = Instance.new("Frame")
        frame.Name = "Land"
        frame.BorderSizePixel = 0
        local nation = rectangle.OwnerId ~= nil and self.Nations[rectangle.OwnerId]
        frame.BackgroundColor3 = Color3.fromRGB(table.unpack(nation and nation.Color or self.Config.LandColor))
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

function MapView:_layoutRoutes()
    local canvasSize = self.Canvas.AbsoluteSize
    for id, route in pairs(self.Routes) do
        local nation = self.Nations[id]
        if not nation or not nation.NavalActive or not nation.NavalFrom or not nation.NavalTo then
            route.Container:Destroy()
            self.Routes[id] = nil
        else
            local ax, ay = self.Grid:ToCoordinates(nation.NavalFrom)
            local bx, by = self.Grid:ToCoordinates(nation.NavalTo)
            if ax and bx then
                local a = Vector2.new((ax - .5) / self.Grid.Width * canvasSize.X, (ay - .5) / self.Grid.Height * canvasSize.Y)
                local b = Vector2.new((bx - .5) / self.Grid.Width * canvasSize.X, (by - .5) / self.Grid.Height * canvasSize.Y)
                local d, mid = b - a, (a + b) / 2
                route.Line.Position = UDim2.fromOffset(mid.X, mid.Y)
                route.Line.Size = UDim2.fromOffset(d.Magnitude, math.max(3, 5 * self.Zoom ^ .25))
                route.Line.Rotation = math.deg(math.atan2(d.Y, d.X))
                route.Target.Position = UDim2.fromOffset(b.X, b.Y)
                local progress = math.clamp(nation.NavalProgress or 0, 0, 1)
                local traveler = a:Lerp(b, progress)
                route.Traveler.Position = UDim2.fromOffset(traveler.X, traveler.Y)
            end
        end
    end
end

function MapView:Layout()
    local size = self.Viewport.AbsoluteSize
    if size.X <= 0 or size.Y <= 0 then return end
    -- Cover the viewport completely: never reveal the 3D world behind the 2D map.
    local fit = math.max(size.X / self.Grid.Width, size.Y / self.Grid.Height)
    local width, height = self.Grid.Width * fit * self.Zoom, self.Grid.Height * fit * self.Zoom
    local maxX, maxY = math.max(0, (width - size.X) / 2), math.max(0, (height - size.Y) / 2)
    self.Pan = Vector2.new(math.clamp(self.Pan.X, -maxX, maxX), math.clamp(self.Pan.Y, -maxY, maxY))
    self.Canvas.Size = UDim2.fromOffset(width, height)
    self.Selection.Size = UDim2.fromOffset(math.max(16, width / self.Grid.Width), math.max(16, height / self.Grid.Height))
    self.Canvas.Position = UDim2.fromOffset(size.X / 2 + self.Pan.X, size.Y / 2 + self.Pan.Y)
    for _, marker in pairs(self.Markers) do marker.NameLabel.Visible = self.Zoom >= 3 end
    self:_layoutRoutes()
end

function MapView:SetSelection(cellId)
    local x, y = self.Grid:ToCoordinates(cellId)
    self.Selection.Visible = x ~= nil
    if x then self.Selection.Position = UDim2.fromScale((x - 0.5) / self.Grid.Width, (y - 0.5) / self.Grid.Height) end
end

function MapView:ApplyNationState(replica, dirtyChunks)
    self.Owners, self.Nations = replica.Owners, replica.Nations
    for chunkId in pairs(dirtyChunks) do self:RebuildChunk(chunkId) end
    for id, marker in pairs(self.Markers) do
        if not self.Nations[id] then marker:Destroy(); self.Markers[id] = nil end
    end
    for id, nation in pairs(self.Nations) do
        local marker = self.Markers[id]
        if not marker then
            marker = Instance.new("TextLabel")
            marker.Name = "Capital"
            marker.AnchorPoint = Vector2.new(0.5, 0.5)
            marker.Size = UDim2.fromOffset(16, 16)
            marker.BackgroundTransparency = 1
            marker.Text = "★"
            marker.TextSize = 17
            marker.TextStrokeTransparency = 0
            marker.Font = Enum.Font.GothamBold
            marker.ZIndex = 3
            marker.Parent = self.Canvas
            local name = Instance.new("TextLabel")
            name.Name = "NameLabel"
            name.AnchorPoint = Vector2.new(0.5, 0)
            name.Position = UDim2.new(0.5, 0, 1, 2)
            name.Size = UDim2.fromOffset(112, 34)
            name.BackgroundTransparency = 1
            name.TextColor3 = Color3.fromRGB(255, 255, 255)
            name.TextStrokeTransparency = 0.2
            name.Font = Enum.Font.GothamMedium
            name.TextSize = 12
            name.TextTruncate = Enum.TextTruncate.AtEnd
            name.ZIndex = 3
            name.Parent = marker
            self.Markers[id] = marker
        end
        local x, y = self.Grid:ToCoordinates(nation.CapitalId)
        marker.Position = UDim2.fromScale((x - 0.5) / self.Grid.Width, (y - 0.5) / self.Grid.Height)
        marker.TextColor3 = Color3.fromRGB(table.unpack(nation.Color))
        marker.NameLabel.Text = string.format("%s\n%d tropas", nation.Name, nation.Troops or 0)
        marker.NameLabel.Visible = self.Zoom >= 3
    end
    for id, nation in pairs(self.Nations) do
        if nation.NavalActive and nation.NavalFrom and nation.NavalTo and not self.Routes[id] then
            local holder = Instance.new("Frame")
            holder.Name = "NavalRoute"; holder.BackgroundTransparency = 1
            holder.Size = UDim2.fromScale(1, 1); holder.ZIndex = 5; holder.Parent = self.Canvas
            local line = Instance.new("Frame")
            line.Name = "RouteLine"; line.AnchorPoint = Vector2.new(.5,.5); line.BorderSizePixel = 0
            line.BackgroundColor3 = Color3.fromRGB(table.unpack(nation.Color)); line.ZIndex = 5; line.Parent = holder
            local target = Instance.new("Frame")
            target.Name = "Destination"; target.AnchorPoint = Vector2.new(.5,.5)
            target.Size = UDim2.fromOffset(15,15); target.BackgroundColor3 = Color3.fromRGB(table.unpack(nation.Color))
            target.BorderSizePixel = 0; target.ZIndex = 6; target.Parent = holder
            local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(255,255,255); stroke.Thickness = 2; stroke.Parent = target
            local traveler = Instance.new("Frame")
            traveler.Name = "TroopTransport"; traveler.AnchorPoint = Vector2.new(.5,.5)
            traveler.Size = UDim2.fromOffset(11,11); traveler.BorderSizePixel = 0
            traveler.BackgroundColor3 = Color3.fromRGB(table.unpack(nation.Color)); traveler.ZIndex = 7; traveler.Parent = holder
            local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(1,0); tc.Parent = traveler
            self.Routes[id] = {Container=holder, Line=line, Target=target, Traveler=traveler}
        end
    end
    self:_layoutRoutes()
end

function MapView:FocusCell(cellId)
    local x, y = self.Grid:ToCoordinates(cellId)
    if not x then return end
    self:SetZoom(math.max(12, self.Zoom))
    -- Layout sets absolute offset size; use it immediately without waiting a frame.
    local size = Vector2.new(self.Canvas.Size.X.Offset, self.Canvas.Size.Y.Offset)
    self.Pan = Vector2.new((0.5 - (x - 0.5) / self.Grid.Width) * size.X,
        (0.5 - (y - 0.5) / self.Grid.Height) * size.Y)
    self:Layout()
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
