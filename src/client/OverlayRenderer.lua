-- Mundial War · everything drawn on top of the territory: nation names, capitals,
-- structures, fronts, fleets, missiles and the aiming preview. Items live inside the
-- world frame with scale positions, so panning costs nothing; sizes follow the zoom (LOD).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local OverlayRenderer = {}
OverlayRenderer.__index = OverlayRenderer

local FONT = Enum.Font.GothamBold
local WHITE = Color3.new(1, 1, 1)
local INK = Color3.fromRGB(20, 26, 34)

local function rgb(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

local MilitaryIcons = require(script.Parent.MilitaryIcons)
local TransportTrail = require(script.Parent.TransportTrail)

local function make(class, parent, props)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end

function OverlayRenderer.new(state, camera, world)
	local self = setmetatable({}, OverlayRenderer)
	self.state, self.camera, self.Map = state, camera, state.Map
	self.Config, self.Protocol = state.Config, state.Protocol
	self.layer = make("Frame", world, { Name = "Overlay", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 2 })
	self.labels, self.capitals, self.icons, self.orderItems = {}, {}, {}, {}
	self.fleetItems, self.missileItems, self.shipItems = {}, {}, {}
	self.fireItems, self.cargoItems = {}, {}
	self.thumbs = {}
	self.aim = nil
	self.needsLayout = true

	state:on("init", function() self:rebuildAll() end)
	-- a nation joined or fell: create/remove only its own items (ids restart each round,
	-- which is handled by the full rebuild on "init")
	state:on("nationList", function() self.needsLayout = true end)
	state:on("nations", function() self:updateLabels() end)
	state:on("buildings", function() self:updateBuildings() end)
	state:on("orders", function() self:updateOrders() end)
	state:on("relations", function()
		self:updateLabels()
		self:updateOrders() -- alliance changes immediately hide/show relevant battles
	end)
	state:on("impact", function(kind, cell, stopped) self:flash(kind, cell, stopped) end)
	camera:onChanged(function() self.needsLayout = true end)
	RunService.RenderStepped:Connect(function(dt)
		if self.needsLayout then
			self.needsLayout = false
			self:updateLabels()
			self:updateBuildings()
			self:updateOrders()
		end
		self:animate(dt)
	end)
	return self
end

function OverlayRenderer:pos(cell, dx, dy)
	local x, y = self.Map:xy(cell)
	return UDim2.fromScale((x + 0.5 + (dx or 0)) / self.Map.W, (y + 0.5 + (dy or 0)) / self.Map.H)
end

function OverlayRenderer:posXY(x, y)
	return UDim2.fromScale(x / self.Map.W, y / self.Map.H)
end

-- A straight line between two map points (cell units) that scales with the world frame.
function OverlayRenderer:line(frame, ax, ay, bx, by, thickness)
	local dx, dy = bx - ax, by - ay
	local length = math.sqrt(dx * dx + dy * dy)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = self:posXY((ax + bx) / 2, (ay + by) / 2)
	frame.Size = UDim2.new(length / self.Map.W, 0, 0, thickness or 2)
	frame.Rotation = math.deg(math.atan2(dy, dx))
end

function OverlayRenderer:center(cell)
	local x, y = self.Map:xy(cell)
	return x + 0.5, y + 0.5
end

function OverlayRenderer:rebuildAll()
	for _, l in pairs(self.labels) do l.frame:Destroy() end
	for _, c in pairs(self.capitals) do c:Destroy() end
	for _, icon in pairs(self.icons) do icon:Destroy() end
	-- Order IDs restart every match; never reuse stale interpolated positions.
	for _, item in pairs(self.orderItems) do item.label:Destroy() end
	self.orderItems = {}
	-- Fleet IDs also restart each round. Destroy their old GUI/wake immediately
	-- instead of reusing a previous voyage under the same ID.
	for _, item in pairs(self.fleetItems) do
		item.icon:Destroy()
		item.route:Destroy()
		if item.dot then item.dot:Destroy() end
	end
	self.fleetItems = {}
	self.labels, self.capitals, self.icons = {}, {}, {}
	self:updateLabels()
	self:updateBuildings()
	self:updateOrders()
end

-- Nation name/avatar/troops over the centre of each nation's largest block.
function OverlayRenderer:updateLabels()
	local state, cam = self.state, self.camera
	local lod = cam:lod()
	local scale = cam.scale
	local alive = {}
	for id, n in pairs(state.nations) do
		alive[id] = true
		-- Bots/tribes: plain country name and troop count, without avatar/emojis.
		-- Real players: Roblox profile picture, name and troop count.
		local isPlayer = n.kind == "player" and type(n.userId) == "number" and n.userId > 0
		local item = self.labels[id]
		-- Conquista Extrema changes a country's bot into a human (or back)
		-- without changing its nation id: rebuild only that label on role changes.
		if item and (item.isPlayer ~= isPlayer or (isPlayer and item.userId ~= n.userId)) then
			item.frame:Destroy()
			self.labels[id] = nil
			if self.capitals[id] then
				self.capitals[id]:Destroy()
				self.capitals[id] = nil
			end
			item = nil
		end
		if not item then
			local frame = make("Frame", self.layer, {
				BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 6,
			})
			local list = make("UIListLayout", frame, {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 0),
			})
			list.SortOrder = Enum.SortOrder.LayoutOrder
			local head = make("Frame", frame, {
				BackgroundTransparency = 1, LayoutOrder = 1, AutomaticSize = Enum.AutomaticSize.X,
			})
			make("UIListLayout", head, {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, isPlayer and 4 or 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
			})
			local avatar, initial
			if isPlayer then
				avatar = make("ImageLabel", head, {
					BackgroundColor3 = rgb(state:nationColor(id)),
					BorderSizePixel = 0, LayoutOrder = 1, ZIndex = 6,
				})
				make("UICorner", avatar, { CornerRadius = UDim.new(1, 0) })
				make("UIStroke", avatar, { Color = WHITE, Thickness = 1.5 })
				initial = make("TextLabel", avatar, {
					BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
					Font = FONT, TextColor3 = WHITE, TextScaled = true,
					Text = string.sub(n.name:match("%((.-)%)$") or n.name, 1,
						(utf8.offset(n.name:match("%((.-)%)$") or n.name, 2) or 2) - 1),
					ZIndex = 7,
				})
			end
			local name = make("TextLabel", head, {
				BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X,
				Font = FONT, TextColor3 = INK,
				TextStrokeColor3 = Color3.fromRGB(245, 242, 232),
				TextStrokeTransparency = 0.25,
				Text = n.name, LayoutOrder = 2, ZIndex = 6,
			})
			-- All nations have troops. Avatar creation stays player-only.
			local troops = make("TextLabel", frame, {
				BackgroundTransparency = 1, Font = FONT,
				TextColor3 = INK, TextStrokeColor3 = Color3.fromRGB(245, 242, 232),
				TextStrokeTransparency = 0.35, LayoutOrder = 2, ZIndex = 6,
			})
			item = { frame = frame, head = head, avatar = avatar,
				initial = initial, name = name, troops = troops,
				isPlayer = isPlayer, userId = isPlayer and n.userId or nil }
			self.labels[id] = item
			if isPlayer then
				task.spawn(function()
					local thumb = self.thumbs[n.userId]
					if not thumb then
						local ok, url = pcall(function()
							return Players:GetUserThumbnailAsync(n.userId,
								Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
						end)
						if ok then thumb = url self.thumbs[n.userId] = url end
					end
					if thumb and avatar.Parent then
						avatar.Image = thumb
						initial.Visible = false
					end
				end)
			end
		end
		local area = math.max(1, n.labelSize or n.land or 1)
		local px = math.sqrt(area) * scale
		local font = math.clamp(px * 0.16, 9, 30)
		local isYou = id == state.you
		local visible = n.land > 0 and (isYou or (lod == 0 and px > 30)
			or (lod == 1 and px > 20) or lod == 2)
		item.frame.Visible = visible
		if visible then
			item.frame.Position = self:pos(n.labelCell or n.capital)
			-- Reserve a second line for troop numbers for BOTH bots and players.
			item.frame.Size = UDim2.fromOffset(math.max(60, font * 10), font * 2.4)
			item.head.Size = UDim2.fromOffset(0, font * 1.3)
			if item.avatar then
				item.avatar.Size = UDim2.fromOffset(font * 1.25, font * 1.25)
			end
			item.name.TextSize = font
			item.name.Size = UDim2.fromOffset(0, font * 1.3)
			local displayName = n.name
			if isPlayer then
				-- Extreme mode: "Angola (Player)" -> "Player".
				displayName = n.name:match("%((.-)%)$") or n.name
			else
				local country = self.Map.countries and self.Map.countries[n.country]
				displayName = (country and country.name) or n.name:gsub("^Tribos de ", "")
			end
			item.name.Text = displayName
			-- When a nation's label is visible its troop count is visible too.
			item.troops.Visible = true
			item.troops.TextSize = math.max(9, font * 0.85)
			item.troops.Size = UDim2.fromOffset(font * 6, font * 1.1)
			item.troops.Text = self.Protocol.formatK(n.troops)
		end
		local cap = self.capitals[id]
		if cap then
			cap.Visible = n.land > 0 and (lod >= 1 or isYou)
			cap.Position = self:pos(n.capital)
			cap.TextSize = math.clamp(scale * 1.6, 10, 22)
			cap.Size = UDim2.fromOffset(cap.TextSize, cap.TextSize)
			cap.TextColor3 = isYou and Color3.fromRGB(255, 226, 120) or WHITE
		end
	end
	for id, item in pairs(self.labels) do
		if not alive[id] then
			item.frame:Destroy()
			self.labels[id] = nil
			if self.capitals[id] then
				self.capitals[id]:Destroy()
				self.capitals[id] = nil
			end
		end
	end
end

-- Only visible buildings consume GUIs. The silhouette comes from exactly the
-- same MilitaryIcons atlas/bitmap as the Construir menu, never an emoji.
-- A cap protects low-graphics clients that use the bitmap-Frame fallback.
function OverlayRenderer:updateBuildings()
	local state, cam, Map = self.state, self.camera, self.Map
	local lod = cam:lod()
	local active = {}
	local count = 0
	-- One ImageLabel per building on capable clients; the bitmap-Frame
	-- compatibility fallback has a much smaller object budget.
	local maxShown = MilitaryIcons.mapTextureReady() and 110 or 32
	local viewport = cam.viewport.AbsoluteSize
	local halfW = viewport.X / math.max(0.01, 2 * cam.scale)
	local halfH = viewport.Y / math.max(0.01, 2 * cam.scale)
	local minX, maxX = cam.cx - halfW - 2, cam.cx + halfW + 2
	local minY, maxY = cam.cy - halfH - 2, cam.cy + halfH + 2
	local size = math.floor(math.clamp(cam.scale * 1.6, 13, 25))
	if lod >= 1 then
		for cell, b in pairs(state.buildings) do
			local x, y = Map:xy(cell)
			if count < maxShown and x >= minX and x <= maxX
				and y >= minY and y <= maxY and MilitaryIcons.Items[b.kind] then
				count = count + 1
				active[cell] = true
				local icon = self.icons[cell]
				if not icon or icon:GetAttribute("Kind") ~= b.kind then
					if icon then icon:Destroy() end
					icon = make("Frame", self.layer, {
						Name = "WorldBuildingIcon", AnchorPoint = Vector2.new(0.5, 0.5),
						BorderSizePixel = 0, BackgroundColor3 = INK,
						BackgroundTransparency = 0.24, ZIndex = 4,
					})
					make("UICorner", icon, { CornerRadius = UDim.new(0, 4) })
					local graphic = make("Frame", icon, {
						Name = "Silhouette", BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.12, 0.12),
						Size = UDim2.fromScale(0.76, 0.76), ZIndex = 5,
					})
					MilitaryIcons.attach(graphic, b.kind)
					icon:SetAttribute("Kind", b.kind)
					self.icons[cell] = icon
				end
				icon.Position = self:pos(cell)
				icon.Size = UDim2.fromOffset(size, size)
				icon.BackgroundColor3 = b.off and Color3.fromRGB(64, 68, 74)
					or rgb(state.Palette.shade(state:nationColor(b.owner), 0.55))
				local badge = icon:FindFirstChild("Level")
				if b.level and b.level > 1 then
					if not badge then
						badge = make("TextLabel", icon, {
							Name = "Level", AnchorPoint = Vector2.new(1, 1),
							Position = UDim2.new(1, 3, 1, 3), Size = UDim2.fromOffset(12, 12),
							BackgroundColor3 = INK, BorderSizePixel = 0,
							TextColor3 = Color3.fromRGB(245, 199, 92),
							Font = FONT, TextSize = 10, ZIndex = 7,
						})
					end
					badge.Text = tostring(b.level)
					badge.Visible = true
				elseif badge then
					badge.Visible = false
				end
			end
		end
	end
	for cell, icon in pairs(self.icons) do
		if not active[cell] then
			icon:Destroy()
			self.icons[cell] = nil
		end
	end
end

local function pool(list, key, factory)
	local item = list[key]
	if not item then
		item = factory()
		list[key] = item
	end
	item.used = true
	return item
end

local function release(list)
	for key, item in pairs(list) do
		if item.used then
			item.used = false
		else
			for _, inst in pairs(item) do
				if typeof(inst) == "Instance" then inst:Destroy() end
			end
			list[key] = nil
		end
	end
end

-- Fronts: show only our attacks and incoming threats to us or our direct allies.
-- Troop labels follow a smoothed center of the wave instead of a last-captured cell.
function OverlayRenderer:updateOrders()
	local state, cam = self.state, self.camera
	local attackBlue = Color3.fromRGB(90, 185, 255)
	local defenseRed = Color3.fromRGB(255, 100, 111)
	local lod = cam:lod()
	for _, o in ipairs(state.orders) do
		if state:shouldShowOrder(o[2], o[3]) then
			local id, nation, target, troops, front, anchor, origin = o[1], o[2], o[3], o[4], o[5], o[6], o[7]
			local mine = nation == state.you
			local incoming = not mine
			local item = pool(self.orderItems, id, function()
				return {
					label = make("TextLabel", self.layer, {
						AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 1,
						TextColor3 = WHITE, TextStrokeColor3 = Color3.new(0, 0, 0),
						TextStrokeTransparency = 0, Font = FONT, ZIndex = 7,
						AutomaticSize = Enum.AutomaticSize.X,
					}),
				}
			end)
			-- Combat indicators have only numbers; no attack arrows or target rings.
			local color = incoming and defenseRed or attackBlue
			-- An ally under attack must be visible even for fewer than 5K troops.
			local showLabel = front and front > 0
			item.label.Visible = showLabel
			if showLabel then
				local x, y = o[8], o[9]
				if type(x) ~= "number" or type(y) ~= "number" then
					x, y = self:center(front) -- compatible with older order packets
				end
				item.targetX, item.targetY = x, y
				if item.anchor ~= anchor then
					-- A deliberate reinforcement can redirect the wave; switch its
					-- visual center immediately rather than dragging it across the map.
					item.visualX, item.visualY = x, y
					item.anchor = anchor
				elseif not item.visualX then
					item.visualX, item.visualY = x, y
				end
				item.label.Position = self:posXY(item.visualX, item.visualY - 0.6)
				item.label.TextSize = 15
				-- Numbers only, colored by combat role, outlined in black, no background.
				item.label.Text = self.Protocol.formatK(troops)
				item.label.TextColor3 = color
				item.label.Size = UDim2.fromOffset(0, 21)
				item.label.BackgroundTransparency = 1
			end
		end
	end
	release(self.orderItems)

	for _, w in ipairs(state.boats) do
		local id, nation, x, y, health, patrol = w[1], w[2], w[3], w[4], w[5], w[6]
		local mine = nation == state.you
		local item = pool(self.shipItems, id, function()
			local it = {
				icon = make("Frame", self.layer, { Name = "DefenseVessel", AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(185, 210, 221), ZIndex = 6 }),
				bar = make("Frame", self.layer, { AnchorPoint = Vector2.new(0.5, 0), BorderSizePixel = 0, BackgroundColor3 = INK, ZIndex = 6 }),
				ring = make("Frame", self.layer, { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 3 }),
			}
			make("UICorner", it.icon, { CornerRadius = UDim.new(0, 3) })
			make("UIStroke", it.icon, { Color = INK, Thickness = 1.5 })
			make("Frame", it.bar, { Name = "Fill", BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(110, 200, 130), ZIndex = 7 })
			make("UICorner", it.ring, { CornerRadius = UDim.new(1, 0) })
			make("UIStroke", it.ring, { Name = "Stroke", Thickness = 1, Transparency = 0.4 })
			return it
		end)
		local s = math.clamp(cam.scale * 1.8, 14, 26)
		local visible = lod >= 1 or mine
		-- glide between the 0.4 s server updates
		if item.x == nil then
			-- First update must not tween from the top-left of the screen.
			item.icon.Position = self:posXY(x, y)
			item.bar.Position = self:posXY(x, y + 0.9)
		elseif item.x ~= x or item.y ~= y then
			local info = TweenInfo.new(self.Config.Tick.PublicOrders, Enum.EasingStyle.Linear)
			TweenService:Create(item.icon, info, { Position = self:posXY(x, y) }):Play()
			TweenService:Create(item.bar, info, { Position = self:posXY(x, y + 0.9) }):Play()
		end
		item.x, item.y = x, y
		item.icon.Size = UDim2.fromOffset(s, s)
		item.icon.Visible = visible
		item.bar.Size = UDim2.fromOffset(s, 3)
		item.bar.Visible = visible
		item.bar.Fill.Size = UDim2.fromScale(math.clamp(health / self.Config.Naval.BoatHealth, 0, 1), 1)
		item.bar.Fill.BackgroundColor3 = rgb(state:nationColor(nation))
		-- our own boats show their patrol circle
		item.ring.Visible = mine and patrol ~= nil
		if patrol then
			local r = self.Config.Naval.BoatOrbit + 1
			item.ring.Position = self:pos(patrol)
			item.ring.Size = UDim2.fromScale(r * 2 / self.Map.W, r * 2 / self.Map.H)
			item.ring.Stroke.Color = rgb(state:nationColor(nation))
		end
	end
	release(self.shipItems)

	-- fires: a translucent blaze that grows with the server's radius
	for _, f in ipairs(state.fires or {}) do
		local id, center, radius = f[1], f[2], f[3]
		local item = pool(self.fireItems, id, function()
			local it = { glow = make("Frame", self.layer, { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(255, 120, 30), BackgroundTransparency = 0.45, ZIndex = 4 }) }
			make("UICorner", it.glow, { CornerRadius = UDim.new(1, 0) })
			make("UIStroke", it.glow, { Color = Color3.fromRGB(255, 70, 20), Thickness = 2 })
			local core = make("Frame", it.glow, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.55, 0.55), BackgroundColor3 = Color3.fromRGB(255, 200, 60), BackgroundTransparency = 0.35, ZIndex = 4 })
			make("UICorner", core, { CornerRadius = UDim.new(1, 0) })
			return it
		end)
		item.glow.Position = self:pos(center)
		item.glow.Size = UDim2.fromScale(radius * 2 / self.Map.W, radius * 2 / self.Map.H)
	end
	release(self.fireItems)

	-- cargo ships carrying gold home
	for _, c in ipairs(state.cargos or {}) do
		local id, nation, cell = c[1], c[2], c[3]
		local item = pool(self.cargoItems, id, function()
			local icon = make("Frame", self.layer, {
				Name = "TradeVessel", AnchorPoint = Vector2.new(0.5, 0.5),
				BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(170, 205, 229),
				ZIndex = 5,
			})
			make("UICorner", icon, { CornerRadius = UDim.new(0, 3) })
			return { icon = icon }
		end)
		local size = math.clamp(cam.scale * 1.3, 10, 18)
		item.icon.Size = UDim2.fromOffset(size, size)
		item.icon.Visible = lod >= 1 or nation == state.you
		if item.cell == nil then
			item.icon.Position = self:pos(cell)
		elseif item.cell ~= cell then
			TweenService:Create(item.icon, TweenInfo.new(self.Config.Tick.PublicOrders, Enum.EasingStyle.Linear), { Position = self:pos(cell) }):Play()
		end
		item.cell = cell
	end
	release(self.cargoItems)
end

-- Fleets and missiles move every frame between server updates.
-- Combat numbers use a stable map-space goal, updated by the server,
-- with lightweight frame interpolation (no repeated Tween objects).
function OverlayRenderer:animate(dt)
	local state, Map = self.state, self.Map
	local now = os.clock()
	local step = math.max(0, math.min(dt or 0, 0.15))
	local blend = 1 - math.exp(-8 * step)
	for _, item in pairs(self.orderItems) do
		if item.label.Visible and item.targetX then
			item.visualX = item.visualX + (item.targetX - item.visualX) * blend
			item.visualY = item.visualY + (item.targetY - item.visualY) * blend
			item.label.Position = self:posXY(item.visualX, item.visualY - 0.6)
		end
	end
	for id, f in pairs(state.fleets) do
		local own = f.nation == state.you
		local targetOwner = state.owner[f.target] or 0
		-- Unrelated seaborne wars do not create GUI instances on the client.
		if f.air or state:shouldShowOrder(f.nation, targetOwner) then
			local item = pool(self.fleetItems, id, function()
				local it = {
					icon = make("TextLabel", self.layer, {
						AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 1,
						TextColor3 = WHITE, TextStrokeColor3 = Color3.new(0, 0, 0),
						TextStrokeTransparency = 0, Font = FONT, TextSize = 12,
						ZIndex = 9, AutomaticSize = Enum.AutomaticSize.X,
						Size = UDim2.fromOffset(0, 18),
					}),
					route = make("Frame", self.layer, {
						BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 3,
					}),
					segments = {},
				}
				if f.air then
					-- Airlift visuals are unchanged; only troop boats get the new wake.
					make("UICorner", it.icon, { CornerRadius = UDim.new(0, 4) })
					local path = f.path
					local prev = path[1]
					for k = 7, #path + 5, 6 do
						local cell = path[math.min(k, #path)]
						local seg = make("Frame", it.route, {
							BorderSizePixel = 0, BackgroundColor3 = rgb(state:nationColor(f.nation)),
							BackgroundTransparency = 0.35, ZIndex = 4,
						})
						local ax, ay = self:center(prev)
						local bx, by = self:center(cell)
						self:line(seg, ax, ay, bx, by, 2)
						prev = cell
					end
				else
					it.dot = make("Frame", self.layer, {
						Name = "TroopTransportDot", AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(90, 185, 255),
						BorderSizePixel = 0, Size = UDim2.fromOffset(9, 9), ZIndex = 8,
					})
					make("UICorner", it.dot, { CornerRadius = UDim.new(1, 0) })
					make("UIStroke", it.dot, {
						Color = Color3.fromRGB(7, 16, 28), Thickness = 1.5,
					})
					for _, section in ipairs(TransportTrail.sections(Map, f.path, f.port)) do
						local frame = make("Frame", it.route, {
							Name = "TravelledWake", BorderSizePixel = 0,
							BackgroundTransparency = 0.12,
							BackgroundColor3 = Color3.fromRGB(90, 185, 255),
							Visible = false, ZIndex = 4,
						})
						it.segments[#it.segments + 1] = { line = frame, data = section }
					end
				end
				return it
			end)
			-- Limit extrapolation when the server is quiet, then reconcile its
			-- next snapshot without backwards jumps or long forward teleports.
			local elapsed = math.min(math.max(0, now - f.t0), self.Config.Tick.PublicOrders + 0.2)
			local predicted = math.min(#f.path, f.progress + elapsed * f.speed)
			local progress = predicted
			if not f.air then
				progress = TransportTrail.advanceProgress(
					item.displayProgress, predicted, f.speed, dt, #f.path)
				item.displayProgress = progress
			end
			local px, py = TransportTrail.position(Map, f.path, progress)
			if px then
				if f.air then
					item.icon.AnchorPoint = Vector2.new(0.5, 0.5)
					item.icon.BackgroundTransparency = 0.2
					item.icon.BackgroundColor3 = INK
					item.icon.TextStrokeTransparency = 1
					item.icon.TextColor3 = WHITE
					item.icon.Position = self:posXY(px, py)
					item.icon.Text = "AIR " .. self.Protocol.formatK(f.troops)
					item.route.Visible = own or self.camera:lod() >= 1
				else
					local color = own and Color3.fromRGB(90, 185, 255)
						or Color3.fromRGB(255, 100, 111)
					item.route.Visible = true
					item.dot.Position = self:posXY(px, py)
					item.dot.BackgroundColor3 = color
					item.icon.Position = self:posXY(px, py - 0.48)
					item.icon.Text = self.Protocol.formatK(f.troops)
					item.icon.TextColor3 = color
					-- The trail grows strictly behind the head. A completed straight
					-- section is drawn once; only the current tip changes every frame.
					for _, seg in ipairs(item.segments) do
						local x, y, complete = TransportTrail.traversedEnd(seg.data, progress)
						seg.line.Visible = x ~= nil
						if x and (not complete or not seg.complete) then
							self:line(seg.line, seg.data.ax, seg.data.ay, x, y, 2)
							seg.complete = complete
						end
						seg.line.BackgroundColor3 = color
					end
				end
			end
		end
		-- The landing is already resolved on the server. Hold the marker only
		-- until it visually reaches the coastline (plus a brief readable beat).
		-- A timeout also cleans up a fleet that stops being relevant to us.
		if f.finishing then
			local item = self.fleetItems[id]
			if item and item.displayProgress and item.displayProgress >= #f.path - 0.001 then
				item.atCoastAt = item.atCoastAt or now
			end
			if (item and item.atCoastAt and now - item.atCoastAt >= 0.15)
				or now - f.finishedAt >= 3 then
				state.fleets[id] = nil
			end
		end
	end
	release(self.fleetItems)
	for id, m in pairs(state.missiles) do
		local item = pool(self.missileItems, id, function()
			local it = {
				icon = make("TextLabel", self.layer, { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Text = "M", TextColor3 = Color3.fromRGB(255, 230, 120), TextStrokeTransparency = 0, Font = FONT, TextSize = 20, ZIndex = 9 }),
				target = make("Frame", self.layer, { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 8 }),
			}
			make("UICorner", it.target, { CornerRadius = UDim.new(1, 0) })
			make("UIStroke", it.target, { Color = Color3.fromRGB(230, 60, 50), Thickness = 2 })
			return it
		end)
		local ax, ay = self:center(m.from)
		local bx, by = self:center(m.to)
		local dist = math.max(1, math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2))
		local t = math.min(1, (m.progress + (now - m.t0) * m.speed) / dist)
		item.icon.Position = self:posXY(ax + (bx - ax) * t, ay + (by - ay) * t)
		local radius = (self.Config.Weapons[m.kind] or { radius = 3 }).radius
		item.target.Position = self:pos(m.to)
		item.target.Size = UDim2.fromScale(radius * 2 / Map.W, radius * 2 / Map.H)
	end
	release(self.missileItems)
end

function OverlayRenderer:flash(kind, cell, stopped)
	local radius = (self.Config.Weapons[kind] or { radius = 3 }).radius
	local ring = make("Frame", self.layer, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = self:pos(cell), ZIndex = 9,
		BackgroundColor3 = stopped and Color3.fromRGB(120, 200, 255) or Color3.fromRGB(255, 210, 120),
		BackgroundTransparency = 0.1, Size = UDim2.fromScale(0, 0),
	})
	make("UICorner", ring, { CornerRadius = UDim.new(1, 0) })
	local target = UDim2.fromScale(radius * 2.4 / self.Map.W, radius * 2.4 / self.Map.H)
	local tween = TweenService:Create(ring, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = target, BackgroundTransparency = 1 })
	tween:Play()
	tween.Completed:Connect(function() ring:Destroy() end)
end

-- A temporary structure marker is separate from replicated, completed buildings.
-- Show it even for structures without a defensive radius (city, factory, etc.).
function OverlayRenderer:setBuildingPreview(cell, kind)
	if not cell or not kind or not MilitaryIcons.Items[kind] then
		if self.buildingPreview then self.buildingPreview.Visible = false end
		return
	end
	if not self.buildingPreview then
		local icon = make("Frame", self.layer, {
			Name = "BuildingPlacementPreview", AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(23, 32, 42), BackgroundTransparency = 0.18,
			BorderSizePixel = 0, ZIndex = 12,
		})
		make("UICorner", icon, { CornerRadius = UDim.new(0, 5) })
		make("UIStroke", icon, { Color = Color3.fromRGB(255, 209, 97), Thickness = 2 })
		self.buildingPreview = icon
	end
	if self.previewKind ~= kind then
		if self.previewGraphic then self.previewGraphic:Destroy() end
		local graphic = make("Frame", self.buildingPreview, {
			Name = "PreviewSilhouette", BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.12, 0.12),
			Size = UDim2.fromScale(0.76, 0.76), ZIndex = 13,
		})
		MilitaryIcons.attach(graphic, kind):setColor(Color3.fromRGB(255, 226, 142))
		self.previewGraphic = graphic
		self.previewKind = kind
	end
	self.buildingPreview.Position = self:pos(cell)
	local size = math.clamp(self.camera.scale * 0.65, 24, 46)
	self.buildingPreview.Size = UDim2.fromOffset(size, size)
	self.buildingPreview.Visible = true
end

-- Reach circles: { { cell, radius, color } } (build preview, selected building, own defences).
function OverlayRenderer:setRanges(list)
	self.rangeItems = self.rangeItems or {}
	for k, r in ipairs(list) do
		local ring = self.rangeItems[k]
		if not ring then
			ring = make("Frame", self.layer, { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 0.88, ZIndex = 3 })
			make("UICorner", ring, { CornerRadius = UDim.new(1, 0) })
			make("UIStroke", ring, { Name = "Stroke", Thickness = 1.5, Transparency = 0.15 })
			self.rangeItems[k] = ring
		end
		ring.Visible = true
		ring.Position = self:pos(r[1])
		ring.Size = UDim2.fromScale(r[2] * 2 / self.Map.W, r[2] * 2 / self.Map.H)
		ring.BackgroundColor3 = r[3]
		ring.Stroke.Color = r[3]
	end
	for k = #list + 1, #self.rangeItems do self.rangeItems[k].Visible = false end
end

-- Clicking/confirming still uses the exact same client command flow.
-- Only the preview text remains; the old arrow/circle have been removed.
function OverlayRenderer:setAim(fromCell, toCell, text, color)
	if not self.aim then
		self.aim = {
			label = make("TextLabel", self.layer, {
				AnchorPoint = Vector2.new(0.5, 1), BackgroundColor3 = INK,
				BackgroundTransparency = 0.1, TextColor3 = WHITE,
				Font = FONT, TextSize = 13, ZIndex = 9,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromOffset(0, 22),
			}),
		}
		make("UICorner", self.aim.label, { CornerRadius = UDim.new(0, 5) })
		make("UIPadding", self.aim.label, {
			PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
		})
	end
	local label = self.aim.label
	label.Visible = toCell ~= nil
	if not toCell then return end
	label.Text = text or ""
	label.TextColor3 = color or WHITE
	label.Position = self:pos(toCell, 0, -1.2)
end

return OverlayRenderer
