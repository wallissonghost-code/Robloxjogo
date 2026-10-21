-- Responsive strategy controls: bottom in portrait, side panel in landscape.
local StrategyHud = {}
StrategyHud.__index = StrategyHud

local function label(parent, text, x, y, width, height, textSize)
    local item = Instance.new("TextLabel")
    item.BackgroundTransparency = 1
    item.Position = UDim2.fromOffset(x, y)
    item.Size = UDim2.new(width, -x * 2, 0, height)
    item.Font = Enum.Font.GothamMedium
    item.TextColor3 = Color3.fromRGB(230, 238, 242)
    item.TextSize = textSize
    item.TextWrapped = true
    item.Text = text
    item.Parent = parent
    return item
end

local function button(parent, text)
    local item = Instance.new("TextButton")
    item.Text = text
    item.TextSize = 15
    item.Font = Enum.Font.GothamBold
    item.TextColor3 = Color3.fromRGB(235, 243, 248)
    item.BackgroundColor3 = Color3.fromRGB(34, 62, 79)
    item.BorderSizePixel = 0
    item.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = item
    return item
end

function StrategyHud.new(gui, config)
    local root = Instance.new("Frame")
    root.Name = "StrategyScreen"
    root.Size = UDim2.fromScale(1, 1)
    root.BorderSizePixel = 0
    root.BackgroundColor3 = Color3.fromRGB(12, 25, 37)
    root.Parent = gui
    label(root, "DOMÍNIO MUNDIAL", 8, 0, 1, 26, 17)
    local status = label(root, "Carregando…", 8, 26, 1, 28, 11)

    local viewport = Instance.new("Frame")
    viewport.Name = "MapViewport"
    viewport.BorderSizePixel = 0
    viewport.BackgroundColor3 = Color3.fromRGB(table.unpack(config.View.WaterColor))
    viewport.ClipsDescendants, viewport.Active = true, true
    viewport.Parent = root

    local panel = Instance.new("ScrollingFrame")
    panel.Name = "Commands"
    panel.BackgroundTransparency = 1
    panel.BorderSizePixel = 0
    panel.CanvasSize = UDim2.fromOffset(0, 238)
    panel.ScrollBarThickness = 3
    panel.ScrollingDirection = Enum.ScrollingDirection.Y
    panel.Parent = root
    local stats = label(panel, "Funde sua capital para começar", 4, 0, 1, 36, 13)
    local preview = label(panel, "Envio: —", 4, 38, 1, 18, 12)
    local hint = label(panel, "Toque em terra livre", 4, 104, 1, 32, 12)
    local action = button(panel, "Sincronizando…")
    action.Name = "MapAction"
    action.Position, action.Size = UDim2.new(0, 4, 0, 138), UDim2.new(1, -8, 0, 44)
    action.Active = false
    local percentages = {}
    for index, percentage in ipairs(config.SendPercentages) do
        local item = button(panel, percentage .. "%")
        item.Position = UDim2.new((index - 1) / #config.SendPercentages, 4, 0, 58)
        item.Size = UDim2.new(1 / #config.SendPercentages, -8, 0, 44)
        percentages[percentage] = item
    end
    local minus, reset, plus = button(panel, "−"), button(panel, "Ver mundo"), button(panel, "+")
    minus.Position, minus.Size = UDim2.new(0, 4, 0, 190), UDim2.new(0.2, -8, 0, 44)
    reset.Position, reset.Size = UDim2.new(0.2, 4, 0, 190), UDim2.new(0.6, -8, 0, 44)
    plus.Position, plus.Size = UDim2.new(0.8, 4, 0, 190), UDim2.new(0.2, -8, 0, 44)
    local self = setmetatable({Root = root, Viewport = viewport, Panel = panel,
        Status = status, Hint = hint, Action = action, Stats = stats, Preview = preview,
        Percentages = percentages, Minus = minus, Reset = reset, Plus = plus}, StrategyHud)
    self.Resize = root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:Layout() end)
    self:Layout()
    return self
end

function StrategyHud:Layout()
    local size = self.Root.AbsoluteSize
    local landscape = size.X >= 620 and size.X > size.Y * 1.25
    if landscape then
        self.Panel.Position = UDim2.fromOffset(size.X - 304, 56)
        self.Panel.Size = UDim2.fromOffset(296, math.max(80, size.Y - 64))
        self.Viewport.Position = UDim2.fromOffset(8, 56)
        self.Viewport.Size = UDim2.fromOffset(math.max(80, size.X - 324), math.max(80, size.Y - 64))
    else
        local panelHeight = math.min(238, math.max(100, size.Y * 0.48))
        self.Panel.Position = UDim2.fromOffset(8, size.Y - panelHeight - 4)
        self.Panel.Size = UDim2.fromOffset(math.max(80, size.X - 16), panelHeight)
        self.Viewport.Position = UDim2.fromOffset(8, 56)
        self.Viewport.Size = UDim2.fromOffset(math.max(80, size.X - 16), math.max(60, size.Y - panelHeight - 68))
    end
end

function StrategyHud:UpdateEconomy(nation, percentage)
    if nation then
        self.Stats.Text = string.format("Tropas %d/%d  (+%g/s)\nOuro %.1f  (+%.1f/s)",
            nation.Troops, nation.MaxTroops, nation.TroopsPerSecond, nation.Gold, nation.GoldPerSecond)
        self.Preview.Text = nation.ExpansionActive
            and string.format("Em expansão: %d tropas • %d células", nation.ExpansionRemaining, nation.ExpansionClaimed)
            or string.format("Envio previsto: %d tropas (%d%%)", math.floor(nation.Troops * percentage / 100), percentage)
    else
        self.Stats.Text, self.Preview.Text = "Funde sua capital para começar", "Envio: —"
    end
    for value, item in pairs(self.Percentages) do
        item.BackgroundColor3 = value == percentage and Color3.fromRGB(38, 112, 97) or Color3.fromRGB(34, 62, 79)
    end
end

function StrategyHud:Destroy() self.Resize:Disconnect() end

return StrategyHud
