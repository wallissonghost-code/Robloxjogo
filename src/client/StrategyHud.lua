-- Compact floating strategy HUD. The map remains the primary surface on mobile.
local StrategyHud = {}
StrategyHud.__index = StrategyHud

local BG = Color3.fromRGB(18, 27, 45)
local BG2 = Color3.fromRGB(28, 39, 60)
local TEXT = Color3.fromRGB(238, 242, 250)
local MUTED = Color3.fromRGB(177, 188, 211)
local GREEN = Color3.fromRGB(61, 219, 151)
local GOLD = Color3.fromRGB(247, 196, 67)
local ACTIVE = Color3.fromRGB(255, 177, 56)

local function round(parent, radius)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, radius); c.Parent = parent
end
local function stroke(parent)
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(53, 66, 94); s.Thickness = 1.5; s.Transparency = .2; s.Parent = parent
end
local function text(parent, value, size, bold)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1; t.Text = value; t.TextColor3 = TEXT
    t.Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium
    t.TextSize = size; t.TextXAlignment = Enum.TextXAlignment.Center
    t.TextYAlignment = Enum.TextYAlignment.Center; t.Parent = parent
    return t
end
local function button(parent, value)
    local b = Instance.new("TextButton")
    b.Text = value; b.TextSize = 15; b.Font = Enum.Font.GothamBold
    b.TextColor3 = MUTED; b.BackgroundColor3 = BG2; b.BorderSizePixel = 0; b.Parent = parent
    round(b, 9)
    return b
end
local function compact(v)
    v = tonumber(v) or 0
    if v >= 1e6 then return string.format("%.2fM", v / 1e6) end
    if v >= 1e3 then return string.format(v >= 1e4 and "%.1fK" or "%.2fK", v / 1e3) end
    return tostring(math.floor(v))
end

function StrategyHud.new(gui, config)
    local root = Instance.new("Frame")
    root.Name = "StrategyScreen"; root.Size = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1; root.BorderSizePixel = 0; root.Parent = gui

    local viewport = Instance.new("Frame")
    viewport.Name = "MapViewport"; viewport.Size = UDim2.fromScale(1, 1)
    viewport.BorderSizePixel = 0
    viewport.BackgroundColor3 = Color3.fromRGB(table.unpack(config.View.WaterColor))
    viewport.ClipsDescendants = true; viewport.Active = true; viewport.Parent = root

    local status = text(root, "Carregando…", 12, true)
    status.Name = "WorldStatus"; status.AnchorPoint = Vector2.new(1, 0)
    status.BackgroundTransparency = .08; status.BackgroundColor3 = BG
    status.TextXAlignment = Enum.TextXAlignment.Right
    status.Position = UDim2.new(1, -12, 0, 10); status.Size = UDim2.fromOffset(250, 36)
    round(status, 16); stroke(status)
    local statusPad = Instance.new("UIPadding"); statusPad.PaddingRight = UDim.new(0, 13); statusPad.PaddingLeft = UDim.new(0, 13); statusPad.Parent = status

    local hint = text(root, "Toque em terra livre para começar", 12, true)
    hint.Name = "Hint"; hint.AnchorPoint = Vector2.new(.5, 0)
    hint.BackgroundTransparency = .08; hint.BackgroundColor3 = BG
    hint.Position = UDim2.new(.5, 0, 0, 10); hint.Size = UDim2.fromOffset(390, 36)
    hint.TextTruncate = Enum.TextTruncate.AtEnd; round(hint, 14); stroke(hint)

    local panel = Instance.new("Frame")
    panel.Name = "BottomCommandBar"; panel.AnchorPoint = Vector2.new(.5, 1)
    panel.BackgroundColor3 = BG; panel.BackgroundTransparency = .03; panel.BorderSizePixel = 0
    panel.Parent = root; round(panel, 18); stroke(panel)

    local stats = text(panel, "⚔ —", 19, true)
    stats.Name = "Stats"; stats.TextXAlignment = Enum.TextXAlignment.Left
    local preview = text(panel, "Envio —", 12, true)
    preview.Name = "SendPreview"; preview.TextColor3 = TEXT

    local percentages = {}
    local percentBox = Instance.new("Frame")
    percentBox.Name = "Percentages"; percentBox.BackgroundColor3 = BG2; percentBox.BorderSizePixel = 0; percentBox.Parent = panel
    round(percentBox, 12)
    for index, percentage in ipairs(config.SendPercentages) do
        local item = button(percentBox, percentage .. "%")
        item.Name = "Send" .. percentage
        item.Position = UDim2.new((index - 1) / #config.SendPercentages, 2, 0, 2)
        item.Size = UDim2.new(1 / #config.SendPercentages, -4, 1, -4)
        percentages[percentage] = item
    end

    local action = button(panel, "Selecione terra")
    action.Name = "MapAction"; action.TextColor3 = TEXT; action.TextSize = 14
    action.Active = false

    local minus, reset, plus = button(root, "−"), button(root, "◎"), button(root, "+")
    minus.Name, reset.Name, plus.Name = "ZoomOut", "WorldView", "ZoomIn"
    minus.AnchorPoint, reset.AnchorPoint, plus.AnchorPoint = Vector2.new(1,0), Vector2.new(1,0), Vector2.new(1,0)
    minus.Size, reset.Size, plus.Size = UDim2.fromOffset(38,38), UDim2.fromOffset(42,38), UDim2.fromOffset(38,38)

    local self = setmetatable({Root=root, Viewport=viewport, Panel=panel, Status=status, Hint=hint,
        Action=action, Stats=stats, Preview=preview, Percentages=percentages,
        Minus=minus, Reset=reset, Plus=plus, PercentBox=percentBox}, StrategyHud)
    self.Resize = root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:Layout() end)
    self:Layout()
    return self
end

function StrategyHud:Layout()
    local size = self.Root.AbsoluteSize
    if size.X <= 0 or size.Y <= 0 then return end
    local landscape = size.X > size.Y
    local barW = math.min(size.X - 24, landscape and 860 or 560)
    local barH = landscape and 70 or 82
    self.Panel.Size = UDim2.fromOffset(barW, barH)
    self.Panel.Position = UDim2.new(.5, 0, 1, -10)

    local statsW = math.floor(barW * .28)
    local percentW = math.floor(barW * .40)
    local actionW = math.max(96, math.floor(barW * .16))
    self.Stats.Position = UDim2.fromOffset(14, 7)
    self.Stats.Size = UDim2.fromOffset(statsW - 14, barH - 14)
    self.PercentBox.Position = UDim2.fromOffset(statsW, 10)
    self.PercentBox.Size = UDim2.fromOffset(percentW, barH - 20)
    self.Preview.Position = UDim2.fromOffset(statsW + percentW + 4, 5)
    self.Preview.Size = UDim2.fromOffset(barW - statsW - percentW - actionW - 10, barH - 10)
    self.Action.Position = UDim2.fromOffset(barW - actionW - 8, 8)
    self.Action.Size = UDim2.fromOffset(actionW, barH - 16)

    local topY = 10
    self.Status.Position = UDim2.new(1, -12, 0, topY)
    self.Status.Size = UDim2.fromOffset(math.min(260, size.X * .32), 36)
    self.Hint.Position = UDim2.new(.5, 0, 0, topY)
    self.Hint.Size = UDim2.fromOffset(math.min(390, size.X * .42), 36)
    self.Minus.Position = UDim2.new(1, -102, 0, 54)
    self.Reset.Position = UDim2.new(1, -56, 0, 54)
    self.Plus.Position = UDim2.new(1, -12, 0, 54)
end

function StrategyHud:UpdateEconomy(nation, percentage)
    if nation then
        self.Stats.Text = string.format("⚔ %s   <font color=\"#3DDB97\">+%s/s</font>   <font color=\"#F7C443\">● %s</font>",
            compact(nation.Troops), compact(nation.TroopsPerSecond), compact(nation.Gold))
        self.Stats.RichText = true
        self.Preview.Text = nation.ExpansionActive
            and string.format("Enviando\n%s", compact(nation.ExpansionRemaining))
            or string.format("Envia\n%s", compact(math.floor(nation.Troops * percentage / 100)))
    else
        self.Stats.RichText = false
        self.Stats.Text = "⚔ —    +—/s    ● —"
        self.Preview.Text = "Envia\n—"
    end
    for value, item in pairs(self.Percentages) do
        local active = value == percentage
        item.BackgroundColor3 = active and ACTIVE or BG2
        item.TextColor3 = active and Color3.fromRGB(29, 31, 38) or MUTED
    end
end

function StrategyHud:Destroy()
    if self.Resize then self.Resize:Disconnect() end
end

return StrategyHud
