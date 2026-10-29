-- Mundial War · minimal interface around the map: player card, troop %, tools, ranking,
-- popovers and notices. Everything sits on the screen edges; the map stays the screen.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local HUD = {}
HUD.__index = HUD

local FONT = Enum.Font.GothamMedium
local BOLD = Enum.Font.GothamBold
local PANEL = Color3.fromRGB(16, 22, 30)
local PANEL_T = 0.12
local TEXT = Color3.fromRGB(236, 238, 240)
local MUTED = Color3.fromRGB(150, 160, 172)
local ACCENT = Color3.fromRGB(240, 196, 92)
local GOOD = Color3.fromRGB(110, 200, 130)
local BAD = Color3.fromRGB(235, 110, 100)

local CityModel = require(script.Parent.CityModel)
local function cityArt(parent, z)
	return CityModel.attach(parent, z)
end

local function make(class, parent, props)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do o[k] = v end
	o.Parent = parent
	return o
end

local function panel(parent, props)
	local f = make("Frame", parent, props)
	f.BackgroundColor3 = PANEL
	f.BackgroundTransparency = PANEL_T
	f.BorderSizePixel = 0
	make("UICorner", f, { CornerRadius = UDim.new(0, 8) })
	return f
end

local function button(parent, text, props)
	local b = make("TextButton", parent, props)
	b.Text = text
	b.Font = props and props.Font or BOLD
	b.TextSize = props and props.TextSize or 14
	b.TextColor3 = TEXT
	b.BackgroundColor3 = props and props.BackgroundColor3 or Color3.fromRGB(34, 44, 58)
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	make("UICorner", b, { CornerRadius = UDim.new(0, 6) })
	return b
end

local function rgb(c) return Color3.fromRGB(c[1], c[2], c[3]) end

function HUD.new(state, gui, handlers)
	local self = setmetatable({}, HUD)
	self.state, self.gui, self.h = state, gui, handlers
	self.Config, self.Protocol = state.Config, state.Protocol
	local player = Players.LocalPlayer

	-- Player identity is displayed on the map by OverlayRenderer, not in the HUD.
	-- Unified bottom HUD: economy, sending percentage, send amount and build action.
	local bar = panel(gui, { Name = "BottomHUD", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.fromOffset(0, 46), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 20 })
	self.percentBar = bar
	make("UIScale", bar, { Name = "UIScale", Scale = 1 })
	make("UIListLayout", bar, { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder })
	make("UIPadding", bar, { PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7) })
	local function stat(name, order, width, color)
		local label = make("TextLabel", bar, { Name = name, LayoutOrder = order, Size = UDim2.fromOffset(width, 34), BackgroundTransparency = 1, Font = BOLD, TextSize = 13, TextColor3 = color or TEXT, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 21, Text = "—" })
		return label
	end
	self.troopsText = stat("Troops", 1, 75)
	self.rateText = stat("TroopsPerSecond", 2, 72, Color3.fromRGB(238, 159, 108))
	self.goldText = stat("Gold", 3, 76, ACCENT)
	self.percentButtons = {}
	for index, p in ipairs(self.Config.TroopPercents) do
		local b = button(bar, math.floor(p * 100) .. "%", { Size = UDim2.fromOffset(44, 34), LayoutOrder = index + 3, TextSize = 13, ZIndex = 21 })
		b.Activated:Connect(function() self.h.onPercent(p) end)
		self.percentButtons[p] = b
	end
	self.sendText = stat("Sending", 8, 76)
	self.cancelButton = button(bar, "✖", { Size = UDim2.fromOffset(35, 34), LayoutOrder = 9, BackgroundColor3 = Color3.fromRGB(110, 46, 44), ZIndex = 21, Visible = false })
	self.cancelButton.Activated:Connect(function() self.h.onCancel() end)
	self.tools = {}
	self.tools.build = button(bar, "🏗 Construir", { Size = UDim2.fromOffset(105, 34), LayoutOrder = 10, TextSize = 13, ZIndex = 21 })
	self.tools.build.Activated:Connect(function() self.h.onTool("build") end)

	-- Build and weapon trays (above the tools): a grid of choices plus an explanation line ----
	local function tray(name, order, defs, onPick)
		-- Compact, native Roblox UI: no external asset IDs required.
		local t = panel(gui, { Name = name, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -70), Size = UDim2.new(0.96, 0, 0, 184), Visible = false, ZIndex = 30 })
		make("UISizeConstraint", t, { MaxSize = Vector2.new(760, 184) })
		local grid = make("ScrollingFrame", t, { Name = "Choices", Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -16, 1, -12), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 3, CanvasSize = UDim2.fromOffset(math.ceil(#order / 2) * 110 + 8, 166), ZIndex = 31 })
		local buttons = {}
		local tip = panel(gui, { Name = name .. "Details", Size = UDim2.fromOffset(270, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, ZIndex = 45 })
		make("UIPadding", tip, { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
		local detail = make("TextLabel", tip, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Font = FONT, TextSize = 12, TextColor3 = TEXT, RichText = false, ZIndex = 46 })
		local function hide() tip.Visible = false end
		local function show(kind, b)
			local def = defs[kind]
			local me = self.state.me
			local cost = me and me.costs and me.costs[kind] or def.cost or def.gold or 0
			local lines = defs == self.Config.Buildings and self.state.Stats.lines(self.Config, kind, 1) or {}
			detail.Text = def.name .. "\nCusto: " .. self.Protocol.formatK(cost) .. " ouro\n" .. (def.purpose or "") .. (#lines > 0 and ("\n" .. table.concat(lines, " · ")) or "")
			local pos = b.AbsolutePosition
			local bounds = gui.AbsoluteSize
			tip.Position = UDim2.fromOffset(math.clamp(pos.X, 8, math.max(8, bounds.X - 286)), math.clamp(t.AbsolutePosition.Y - 155, 55, math.max(55, bounds.Y - 180)))
			tip.Visible = true
		end
		for index, kind in ipairs(order) do
			local b = button(grid, "", { Position = UDim2.fromOffset(math.floor((index - 1) / 2) * 110, ((index - 1) % 2) * 80 + 2), Size = UDim2.fromOffset(104, 76), ZIndex = 31, TextSize = 11 })
			make("UICorner", b, { CornerRadius = UDim.new(0, 9) })
			make("UIStroke", b, { Color = Color3.fromRGB(76, 101, 122), Transparency = 0.3, Thickness = 1 })
			b.Text = ""
			b.TextWrapped = true
			b.RichText = false
			if defs == self.Config.Buildings then
				local def = defs[kind]
				if kind == "city" then
					local artHolder = make("Frame", b, { Name = "Icon", Position = UDim2.new(0.5, -16, 0, 1), Size = UDim2.fromOffset(32, 27), BackgroundTransparency = 1, ZIndex = 32 })
					cityArt(artHolder, 33)
				else
					make("TextLabel", b, { Name = "Icon", Position = UDim2.new(0, 0, 0, 2), Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1, Text = def.icon or "■", TextColor3 = TEXT, Font = BOLD, TextSize = 21, ZIndex = 32 })
				end
				make("TextLabel", b, { Name = "Title", Position = UDim2.new(0, 3, 0, 27), Size = UDim2.new(1, -6, 0, 24), BackgroundTransparency = 1, Text = def.name, TextColor3 = TEXT, Font = BOLD, TextSize = 10, TextWrapped = true, ZIndex = 32 })
				make("TextLabel", b, { Name = "Cost", Position = UDim2.new(0, 2, 0, 55), Size = UDim2.new(1, -4, 0, 18), BackgroundTransparency = 1, Text = "", TextColor3 = GOOD, Font = BOLD, TextSize = 12, ZIndex = 32 })
			end
			b.TextXAlignment = Enum.TextXAlignment.Center
			local pressing, longPressed = false, false
			b.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
					pressing, longPressed = true, false
					task.delay(0.45, function()
						if pressing and t.Visible then
							longPressed = true
							show(kind, b)
						end
					end)
				end
			end)
			b.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
					pressing = false
					hide()
				end
			end)
			b.MouseEnter:Connect(function()
				if not pressing then show(kind, b) end
			end)
			b.MouseLeave:Connect(hide)
			b.Activated:Connect(function()
				if longPressed then
					task.defer(function() longPressed = false end)
					return
				end
				hide()
				if defs == self.Config.Buildings then
					local me = self.state.me
					local def = defs[kind]
					local cost = me and me.costs and me.costs[kind] or def.cost or def.gold or 0
					if not me or (me.gold or 0) < cost then
						self:toast("Ouro insuficiente! Necessário: " .. self.Protocol.formatK(cost) .. " ouro.", "bad")
						return
					end
				end
				onPick(kind)
			end)
			buttons[kind] = b
		end
		t:GetPropertyChangedSignal("Visible"):Connect(function() if not t.Visible then hide() end end)
		local info = make("TextLabel", t, { Visible = false, Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, Text = "" })
		return t, buttons, info
	end
	self.tray, self.trayButtons, self.trayInfo = tray("BuildTray", self.Config.BuildingOrder, self.Config.Buildings, function(kind) self.h.onBuild(kind) end)
	self.weaponTray, self.weaponButtons, self.weaponInfo = tray("WeaponTray", self.Config.WeaponOrder, self.Config.Weapons, function(kind) self.h.onWeapon(kind) end)

	-- Placement controls remain visible after the construction tray closes.
	self.placement = panel(gui, { Name = "BuildPlacement", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -72), Size = UDim2.fromOffset(280, 54), Visible = false, ZIndex = 50 })
	make("UIStroke", self.placement, { Color = Color3.fromRGB(91, 114, 137), Transparency = 0.2, Thickness = 1 })
	self.placementText = make("TextLabel", self.placement, { Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(160, 42), BackgroundTransparency = 1, Text = "Toque na sua terra", Font = BOLD, TextSize = 12, TextWrapped = true, TextColor3 = TEXT, ZIndex = 51 })
	local cancelPlacement = button(self.placement, "X", { Position = UDim2.fromOffset(177, 7), Size = UDim2.fromOffset(43, 40), TextSize = 21, ZIndex = 51, BackgroundColor3 = Color3.fromRGB(99, 48, 50) })
	local confirmPlacement = button(self.placement, "✓", { Position = UDim2.fromOffset(226, 7), Size = UDim2.fromOffset(43, 40), TextSize = 21, ZIndex = 51, BackgroundColor3 = Color3.fromRGB(188, 138, 46) })
	cancelPlacement.Activated:Connect(function() self.h.onPlacementCancel() end)
	confirmPlacement.Activated:Connect(function() self.h.onPlacementConfirm() end)
	self.placementConfirm = confirmPlacement

	-- Top banner (phase / mode) and notices -------------------------------------------------
	self.banner = panel(gui, { Name = "Banner", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 20, Visible = false })
	make("UIPadding", self.banner, { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) })
	self.bannerText = make("TextLabel", self.banner, { Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Font = BOLD, TextSize = 14, TextColor3 = ACCENT, ZIndex = 21 })
	self.toasts = make("Frame", gui, { Name = "Notices", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 46), Size = UDim2.fromOffset(460, 120), ZIndex = 25 })
	make("UIListLayout", self.toasts, { Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder })

	-- Ranking (top-right) and alliance requests ---------------------------------------------------
	self.ranking = panel(gui, { Visible = false, Name = "Ranking", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 10), Size = UDim2.fromOffset(210, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 20 })
	make("UIPadding", self.ranking, { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })
	make("UIListLayout", self.ranking, { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })
	self.rankRows = {}
	for k = 1, 8 do
		local row = make("TextLabel", self.ranking, { LayoutOrder = k, Size = UDim2.new(1, 0, 0, 17), BackgroundTransparency = 1, Font = FONT, TextSize = 12, TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Left, RichText = true, TextTruncate = Enum.TextTruncate.AtEnd, Text = "", ZIndex = 21 })
		self.rankRows[k] = row
	end
	self.requests = make("Frame", gui, { Name = "Requests", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -230, 0, 10), Size = UDim2.fromOffset(250, 200), ZIndex = 25 })
	make("UIListLayout", self.requests, { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })

	-- Popover (nation / cell) ------------------------------------------------------------------
	self.popover = panel(gui, { Name = "Popover", Size = UDim2.fromOffset(310, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, ZIndex = 40 })
	make("UIStroke", self.popover, { Color = Color3.fromRGB(92, 107, 137), Thickness = 1, Transparency = 0.25 })
	make("UIPadding", self.popover, { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
	make("UIListLayout", self.popover, { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder })
	self.popTitle = make("TextLabel", self.popover, { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Font = BOLD, TextSize = 18, TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 41 })
	self.popBody = make("TextLabel", self.popover, { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Font = FONT, TextSize = 13, TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, RichText = true, ZIndex = 41 })
	self.popButtons = make("Frame", self.popover, { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 41 })
	make("UIGridLayout", self.popButtons, { CellSize = UDim2.new(0.5, -4, 0, 42), CellPadding = UDim2.fromOffset(8, 6), SortOrder = Enum.SortOrder.LayoutOrder })

	-- Victory / help overlays ----------------------------------------------------------------------
	self.center = panel(gui, { Name = "Center", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(420, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, ZIndex = 50 })
	make("UIPadding", self.center, { PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 16), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) })
	make("UIListLayout", self.center, { Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder })
	self.centerTitle = make("TextLabel", self.center, { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Font = BOLD, TextSize = 28, TextColor3 = ACCENT, ZIndex = 51 })
	self.centerBody = make("TextLabel", self.center, { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Font = FONT, TextSize = 14, TextColor3 = TEXT, TextWrapped = true, RichText = true, ZIndex = 51 })
	self.centerClose = button(self.center, "Fechar", { LayoutOrder = 3, Size = UDim2.fromOffset(120, 30), ZIndex = 51 })
	self.centerClose.Activated:Connect(function() self.center.Visible = false end)
	self.centerLobby = button(self.center, "VOLTAR AO LOBBY", {
		LayoutOrder = 4, Size = UDim2.fromOffset(240, 36), TextSize = 15,
		BackgroundColor3 = ACCENT, ZIndex = 51, Visible = false,
	})
	self.centerLobby.TextColor3 = Color3.fromRGB(30, 24, 10)
	self.centerLobby.Activated:Connect(function() self.h.onReturnLobby() end)

	-- narrow screens (phones/tablets): lift the percentage bar above the player card
	local function layout()
		local narrow = gui.AbsoluteSize.X < 1000
		bar.Position = UDim2.new(0.5, 0, 1, -12)
		bar.UIScale.Scale = math.min(1, (gui.AbsoluteSize.X - 16) / 740)
		local trayWidth = math.min(760, math.max(260, gui.AbsoluteSize.X - 24))
		-- Two rows of 76px cards at y=2 and y=82 need at least 166px of content.
		-- Keep the outer tray tall enough for both prices plus vertical padding.
		self.tray.Size = UDim2.fromOffset(trayWidth, 184)
		self.weaponTray.Size = UDim2.fromOffset(trayWidth, 184)
		self.ranking.Visible = false
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	layout()

	-- Mode menu: shown during the vote that opens every round -----------------------------------
	self.menu = panel(gui, { Name = "ModeMenu", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(560, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, ZIndex = 60 })
	make("UIPadding", self.menu, { PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 16), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) })
	make("UIListLayout", self.menu, { Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder })
	make("TextLabel", self.menu, { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Font = BOLD, TextSize = 28, TextColor3 = ACCENT, Text = "MUNDIAL WAR", ZIndex = 61 })
	self.menuTimer = make("TextLabel", self.menu, { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Font = FONT, TextSize = 13, TextColor3 = MUTED, Text = "Escolha o modo da próxima partida", ZIndex = 61 })
	local cards = make("Frame", self.menu, { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 61 })
	make("UIListLayout", cards, { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
	self.modeCards = {}
	for index, mode in ipairs(self.Config.ModeOrder) do
		local def = self.Config.Modes[mode]
		local card = make("Frame", cards, { LayoutOrder = index, Size = UDim2.new(0.5, -5, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Color3.fromRGB(28, 38, 52), BorderSizePixel = 0, ZIndex = 61 })
		make("UICorner", card, { CornerRadius = UDim.new(0, 8) })
		local stroke = make("UIStroke", card, { Thickness = 2, Color = ACCENT, Transparency = 1 })
		make("UIPadding", card, { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
		make("UIListLayout", card, { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
		make("TextLabel", card, { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Font = BOLD, TextSize = 17, TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Left, Text = def.icon .. " " .. def.name, ZIndex = 62 })
		make("TextLabel", card, { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Font = FONT, TextSize = 12, TextColor3 = MUTED, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Text = def.description, ZIndex = 62 })
		local votes = make("TextLabel", card, { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Font = FONT, TextSize = 12, TextColor3 = ACCENT, TextXAlignment = Enum.TextXAlignment.Left, Text = "0 votos", ZIndex = 62 })
		local vote = button(card, "Votar", { LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 30), ZIndex = 62 })
		vote.Activated:Connect(function() self.h.onVote(mode) end)
		self.modeCards[mode] = { stroke = stroke, votes = votes }
	end

	self:setPercent(state.percent)
	return self
end

function HUD:setPercent(p)
	if self.state.me then self.sendText.Text = "Enviar " .. self.Protocol.formatK(math.floor(self.state.me.troops * p)) end
	for value, b in pairs(self.percentButtons) do
		local on = math.abs(value - p) < 1e-6
		b.BackgroundColor3 = on and ACCENT or Color3.fromRGB(34, 44, 58)
		b.TextColor3 = on and Color3.fromRGB(30, 24, 10) or TEXT
	end
end

function HUD:toast(text, kind)
	if not text or text == "" then return end
	local color = kind == "bad" and BAD or kind == "good" and GOOD or kind == "war" and Color3.fromRGB(255, 140, 110) or TEXT
	local children = {}
	for _, c in ipairs(self.toasts:GetChildren()) do
		if c:IsA("TextLabel") then children[#children + 1] = c end
	end
	if #children >= 3 then children[1]:Destroy() end
	local t = make("TextLabel", self.toasts, {
		AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 26), BackgroundColor3 = PANEL,
		BackgroundTransparency = 0.1, Font = FONT, TextSize = 13, TextColor3 = color, Text = text,
		LayoutOrder = math.floor(os.clock() * 100) % 1000000, ZIndex = 26,
	})
	make("UICorner", t, { CornerRadius = UDim.new(0, 6) })
	make("UIPadding", t, { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
	task.delay(4, function()
		if t.Parent then
			local tween = TweenService:Create(t, TweenInfo.new(0.4), { TextTransparency = 1, BackgroundTransparency = 1 })
			tween:Play()
			tween.Completed:Connect(function() t:Destroy() end)
		end
	end)
end

function HUD:setBanner(text)
	self.banner.Visible = text ~= nil and text ~= ""
	self.bannerText.Text = text or ""
end

function HUD:refreshMe()
	local state = self.state
	local me = state.me
	local F = self.Protocol.formatK
	if not me or not state.you then
		self.troopsText.Text = "👥 —"
		self.rateText.Text = "+—/s"
		self.goldText.Text = "💰 —"
		self.sendText.Text = "Enviar —"
		self.cancelButton.Visible = false
		return
	end
	self.troopsText.Text = "👥 " .. F(me.troops)
	self.rateText.Text = "+" .. F(me.rate) .. "/s"
	self.goldText.Text = "💰 " .. F(me.gold)
	self.sendText.Text = "Enviar " .. F(math.floor(me.troops * state.percent))
	-- show only what exists in the current mode
	for kind, b in pairs(self.trayButtons) do
		local m = self.Config.Buildings[kind].mode
		b.Visible = m == nil or m == me.mode
	end
	for kind, b in pairs(self.weaponButtons) do
		local m = self.Config.Weapons[kind].mode
		b.Visible = m == nil or m == me.mode
	end
	local mine = 0
	for _, o in ipairs(state.orders) do
		if o[2] == state.you then mine = mine + 1 end
	end
	self.cancelButton.Visible = mine > 0
	self.cancelButton.Text = mine > 1 and ("✖" .. mine) or "✖"
	-- weapons only once something can launch them
	if self.tray.Visible then self:refreshTray() end
	if self.weaponTray.Visible then self:refreshWeapons() end
end

function HUD:refreshTray()
	local me = self.state.me
	for kind, b in pairs(self.trayButtons) do
		local def = self.Config.Buildings[kind]
		local cost = me and me.costs and me.costs[kind] or def.cost
		local affordable = me and me.gold >= cost
		b.AutoButtonColor = affordable and true or false
		-- The cost is supplied by the server and includes existing-building scaling.
		local costLabel = b:FindFirstChild("Cost")
		if costLabel then
			costLabel.Text = "● " .. self.Protocol.formatK(cost)
			costLabel.TextColor3 = affordable and GOOD or BAD
		end
		local iconLabel = b:FindFirstChild("Icon")
		if iconLabel and iconLabel:IsA("TextLabel") then iconLabel.TextTransparency = affordable and 0 or 0.45 end
		local titleLabel = b:FindFirstChild("Title")
		if titleLabel then titleLabel.TextTransparency = affordable and 0 or 0.35 end
		b.BackgroundColor3 = (self.selectedBuild == kind) and Color3.fromRGB(92, 74, 30) or Color3.fromRGB(34, 44, 58)
	end
	local kind = self.selectedBuild
	if kind then
		local def = self.Config.Buildings[kind]
		local lines = self.state.Stats.lines(self.Config, kind, 1)
		self.trayInfo.Text = "<b>" .. def.name .. "</b>: " .. def.purpose .. "\n" .. table.concat(lines, " · ")
	else
		self.trayInfo.Text = "Escolha uma construção para ver para que serve e o alcance; depois clique numa célula sua."
	end
end

function HUD:refreshWeapons()
	local me = self.state.me
	for kind, b in pairs(self.weaponButtons) do
		local w = self.Config.Weapons[kind]
		local ready = me and me.cooldowns and me.cooldowns[w.launcher]
		local affordable = me and me.gold >= w.gold and ready ~= nil
		local status = ready == nil and ("requer " .. self.Config.Buildings[w.launcher].name)
			or (ready > 0 and string.format("recarga %ds", math.ceil(ready)) or ("💰 " .. self.Protocol.formatK(w.gold)))
		b.Text = w.icon .. "\n" .. w.name
		b.BackgroundColor3 = (self.selectedWeapon == kind) and Color3.fromRGB(120, 48, 44) or Color3.fromRGB(34, 44, 58)
		b.TextTransparency = affordable and 0 or 0.35
	end
	local w = self.selectedWeapon and self.Config.Weapons[self.selectedWeapon]
	self.weaponInfo.Text = w and ("<b>" .. w.name .. "</b>: " .. w.purpose .. " Raio " .. w.radius .. ". Clique no alvo e confirme com um segundo clique.")
		or "Escolha uma arma. Aviões saem da base aérea; bombas EMP, atômica e de hidrogênio, do silo."
end

function HUD:showPlacement(visible, kind, ready)
	self.placement.Visible = visible
	if not visible then return end
	local def = kind and self.Config.Buildings[kind]
	self.placementText.Text = (def and def.name or "Construção") .. (ready and "\nPosição selecionada" or "\nToque na sua terra")
	self.placementConfirm.BackgroundColor3 = ready and Color3.fromRGB(188, 138, 46) or Color3.fromRGB(72, 77, 85)
end

function HUD:showWeapons(visible, selected)
	self.weaponTray.Visible = visible
	self.selectedWeapon = selected
	if visible then self:refreshWeapons() end
end

function HUD:showTray(visible, selected)
	self.tray.Visible = visible
	self.selectedBuild = selected
	if visible then self:refreshTray() end
end

function HUD:refreshRanking()
	local state = self.state
	local list = {}
	for id, n in pairs(state.nations) do list[#list + 1] = n end
	table.sort(list, function(a, b) return a.land > b.land end)
	local total = state.Map.landCount
	for k, row in ipairs(self.rankRows) do
		local n = list[k]
		if n then
			local c = state.Palette.Nations[n.color] or state.Palette.Neutral
			local hex = string.format("#%02x%02x%02x", c[1], c[2], c[3])
			local you = n.id == state.you
			row.Text = string.format("<font color=\"%s\">■</font> %s%s <font color=\"#96a0ac\">%.1f%% · %s</font>",
				hex, you and "<b>" or "", n.name .. (you and "</b>" or ""), n.land / total * 100, self.Protocol.formatK(n.troops))
			row.Visible = true
		else
			row.Visible = false
		end
	end
end

function HUD:toggleRanking()
	self.ranking.Visible = not self.ranking.Visible
end

-- Popover near a screen point with a title, text and buttons { {label, fn, danger} }.
function HUD:showPopover(screenPos, title, body, buttons)
	self.popTitle.Text = title
	self.popBody.Text = body or ""
	for _, c in ipairs(self.popButtons:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	for index, b in ipairs(buttons or {}) do
		local attack = b[4] == "attack"
		local btn = button(self.popButtons, b[1], { LayoutOrder = index, TextSize = 13, TextWrapped = true, ZIndex = 42, BackgroundColor3 = attack and Color3.fromRGB(246, 174, 60) or (b[3] and Color3.fromRGB(160, 67, 65) or Color3.fromRGB(87, 68, 136)) })
		if attack then btn.TextColor3 = Color3.fromRGB(30, 26, 20) end
		btn.Activated:Connect(function()
			self:hidePopover()
			b[2]()
		end)
	end
	local size = self.gui.AbsoluteSize
	local width = math.min(310, math.max(220, size.X - 16))
	self.popover.Size = UDim2.fromOffset(width, 0)
	local x = math.clamp(screenPos.X + 16, 8, math.max(8, size.X - width - 8))
	local y = math.clamp(screenPos.Y - 20, 50, math.max(50, size.Y - 230))
	self.popover.Position = UDim2.fromOffset(x, y)
	self.popover.Visible = true
end

function HUD:hidePopover()
	self.popover.Visible = false
end

function HUD:showCenter(title, body, closable)
	self.centerTitle.Text = title
	self.centerBody.Text = body
	self.centerClose.Visible = closable ~= false
	self.centerLobby.Visible = self.Config.Lobby and self.Config.Lobby.Enabled or false
	self.center.Visible = true
end

function HUD:hideCenter()
	self.center.Visible = false
end

function HUD:allianceRequest(fromId, seconds, onAccept, onDecline)
	local n = self.state.nations[fromId]
	if not n then return end
	local card = panel(self.requests, { Size = UDim2.new(1, 0, 0, 62), ZIndex = 26 })
	make("TextLabel", card, { Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 0, 18), BackgroundTransparency = 1, Font = BOLD, TextSize = 13, TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Left, Text = "🤝 " .. n.name .. " propõe aliança", TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 27 })
	local yes = button(card, "Aceitar", { Position = UDim2.fromOffset(10, 28), Size = UDim2.new(0.5, -14, 0, 26), BackgroundColor3 = Color3.fromRGB(46, 110, 64), TextSize = 12, ZIndex = 27 })
	local no = button(card, "Recusar", { Position = UDim2.new(0.5, 4, 0, 28), Size = UDim2.new(0.5, -14, 0, 26), TextSize = 12, ZIndex = 27 })
	yes.Activated:Connect(function() card:Destroy() onAccept() end)
	no.Activated:Connect(function() card:Destroy() onDecline() end)
	task.delay(seconds or 30, function() if card.Parent then card:Destroy() end end)
end


function HUD:refreshMenu(myVote)
	local match = self.state.match
	local show = match.phase == "vote"
	self.menu.Visible = show
	if not show then return end
	self.menuTimer.Text = "Escolha o modo da próxima partida · " .. math.ceil(self.state:timeLeft()) .. "s"
	for mode, c in pairs(self.modeCards) do
		local n = match.votes and match.votes[mode] or 0
		c.votes.Text = n .. (n == 1 and " voto" or " votos")
		c.stroke.Transparency = myVote == mode and 0 or 1
	end
end

return HUD
