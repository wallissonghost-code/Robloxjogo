-- Mundial War · paints the territory map.
-- "image" mode: one pixel per cell in a single EditableImage (one draw call). Needs
--   "Enable Mesh / Image APIs" in the experience settings; without it Roblox shows a
--   pink/blue checkerboard instead of the picture.
-- "frames" mode: pooled Frames, one per run of equal colour in a row, water left to the
--   ocean-coloured background. Works everywhere.
local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")

local MapRenderer = {}
MapRenderer.__index = MapRenderer

local BORDER_SHADE = 0.58
local COUNTRY_SHADE = 0.9
-- Terrain look (image mode only): how much of the real satellite/relief colour
-- shows through a nation's fill, and how dark country lines are on free land.
local TERRAIN_SHOW_THROUGH = 0.36
local TERRAIN_LINE_SHADE = 0.8
-- Each 64x64 region is an independent repaint unit. The logical map remains
-- 640x320; chunks affect rendering only, not simulation or territory rules.
local DEFAULT_CHUNK_SIZE = 64
local FRAME_CHUNKS_PER_FRAME = 1
local IMAGE_CHUNKS_PER_FRAME = 8

-- Decodes the client-only terrain layer (src/shared/MapTerrain.lua) once per Map.
-- Returns nil when the module is missing or does not match the grid; the map then
-- falls back to the flat colours.
local B62 = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
local function loadTerrain(Map)
	if Map.terrainCodes ~= nil then
		return Map.terrainCodes or nil, Map.terrainData
	end
	local ok, data = pcall(function()
		local shared = game:GetService("ReplicatedStorage"):FindFirstChild("MundialWarShared")
		local mod = shared and shared:FindFirstChild("MapTerrain")
		return mod and require(mod)
	end)
	if not ok or type(data) ~= "table" or data.W ~= Map.W or data.H ~= Map.H then
		Map.terrainCodes = false
		return nil
	end
	local lookup = {}
	for k = 1, #B62 do lookup[string.byte(B62, k)] = k - 1 end
	local codes, W = {}, Map.W
	for y = 0, Map.H - 1 do
		local row, x = data.Rows[y + 1], 0
		for k = 1, #row, 3 do
			local b1, b2, b3 = string.byte(row, k, k + 2)
			local v = lookup[b1]
			local len = lookup[b2] * 62 + lookup[b3]
			for c = x, x + len - 1 do codes[y * W + c + 1] = v end
			x = x + len
		end
		if x ~= W then
			Map.terrainCodes = false
			return nil
		end
	end
	Map.terrainCodes, Map.terrainData = codes, data
	return codes, data
end

function MapRenderer.new(state, parent, opts)
	opts = opts or {}
	local self = setmetatable({}, MapRenderer)
	self.state = state
	self.Map = state.Map
	self.Palette = state.Palette
	self.fullDirty = true
	local W, H = self.Map.W, self.Map.H
	self.chunkSize = math.clamp(math.floor(tonumber(state.Config.View.ChunkSize) or DEFAULT_CHUNK_SIZE), 16, 128)
	self.chunksX = math.ceil(W / self.chunkSize)
	self.chunksY = math.ceil(H / self.chunkSize)
	self.dirtyChunks = {} -- key -> bounds + dirty rows; coalesced until painted
	self.chunkQueue = {}
	self.queueHead = 1

	local image = Instance.new("ImageLabel")
	image.Name = "Territory"
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(1, 1)
	image.ResampleMode = Enum.ResamplerMode.Pixelated
	image.ZIndex = 1
	image.Parent = parent
	self.image = image

	local ok, editable = false, nil
	if not opts.frames then
		ok, editable = pcall(function()
			return AssetService:CreateEditableImage({ Size = Vector2.new(W, H) })
		end)
	end
	if ok and editable then
		local bound = pcall(function()
			image.ImageContent = Content.fromObject(editable)
		end)
		if bound then
			self.editable = editable
			self.buffer = buffer.create(W * H * 4)
		end
	end
	if self.editable then
		-- Real-world look: satellite colours, relief and sea depth. Frames mode keeps
		-- flat colours because every colour change there costs another Frame.
		self.terrain, self.terrainData = loadTerrain(self.Map)
	end
	if not self.editable then
		if not opts.frames then
			warn("[MundialWar] EditableImage indisponível; usando renderizador de Frames. Ative 'Enable Mesh / Image APIs' nas configurações da experiência para o modo rápido.")
		end
		image.Visible = false
		self.rowsFrame = Instance.new("Frame")
		self.rowsFrame.Name = "TerritoryRows"
		self.rowsFrame.BackgroundTransparency = 1
		self.rowsFrame.Size = UDim2.fromScale(1, 1)
		self.rowsFrame.ZIndex = 1
		self.rowsFrame.Parent = parent
		self.rowPools = {} -- row -> chunk-column -> reusable UI runs
	end
	self:recolor()

	state:on("init", function()
		if self.disposed then return end
		self:recolor()
		self.fullDirty = true
	end)
	state:on("nationList", function()
		if self.disposed then return end
		-- colours only; the cells of a new or removed nation arrive as territory deltas
		self:recolor()
	end)
	state:on("owners", function(cells)
		if self.disposed then return end
		for _, i in ipairs(cells) do self:markAround(i) end
	end)
	self.connection = RunService.RenderStepped:Connect(function()
		self:flush()
	end)
	return self
end

function MapRenderer:mode()
	return self.editable and "image" or "frames"
end

-- Removes everything this renderer created (used when the player switches map mode).
function MapRenderer:dispose()
	self.disposed = true
	if self.connection then self.connection:Disconnect() end
	if self.image then self.image:Destroy() end
	if self.rowsFrame then self.rowsFrame:Destroy() end
	if self.editable then pcall(function() self.editable:Destroy() end) end
	self.editable, self.rowPools, self.dirtyChunks = nil, nil, nil
	self.chunkQueue = nil
end

-- Pre-computes fill/border/country-line colours for every nation id.
function MapRenderer:recolor()
	local P = self.Palette
	self.colors = {}
	for id in pairs(self.state.nations) do
		-- Use the display colour, not the server-side colour index: tribes are
		-- beige-grey in both EditableImage and low-graphics Frames renderers.
		local base = self.state:nationColor(id)
		self.colors[id] = {
			fill = base,
			border = P.shade(base, BORDER_SHADE),
			line = P.shade(base, COUNTRY_SHADE),
		}
	end
	self.neutralColors = {
		fill = P.Neutral, line = P.CountryLine,
		water = P.Water, waterCoast = P.WaterCoast,
	}
	if self.terrain then
		local T = self.terrainData
		self.terrainColors, self.terrainLines = {}, {}
		for k = 0, 4 do self.terrainColors[k] = T.Water[k + 1] end
		for t = 0, #T.Tones - 1 do
			for sh = 0, 2 do
				local code = 5 + t * 3 + sh
				local c = P.shade(T.Tones[t + 1], T.Shade[sh + 1])
				self.terrainColors[code] = c
				self.terrainLines[code] = P.shade(c, TERRAIN_LINE_SHADE)
			end
		end
		-- per nation: fill/line mixed with each terrain colour, built on first use
		for _, nc in pairs(self.colors) do nc.terrain = {} end
	end
	-- free land fades smoothly toward snow at high latitudes (no hard line at the polar circle)
	self.rowNeutral = {}
	for y = 0, self.Map.H - 1 do
		local t = math.max(0, math.min(1, (math.abs(self.Map.latitude[y]) - 56) / 24))
		self.rowNeutral[y] = P.mix(P.Neutral, P.NeutralPolar, t)
	end
end

-- Mark a changed cell's chunk. Merge multiple edits into a single dirty
-- rectangle and collect affected rows for the low-graphics Frames fallback.
function MapRenderer:markCell(i)
	local W = self.Map.W
	local x, y = (i - 1) % W, math.floor((i - 1) / W)
	local cx, cy = math.floor(x / self.chunkSize), math.floor(y / self.chunkSize)
	local key = cy * self.chunksX + cx + 1
	local entry = self.dirtyChunks[key]
	if not entry then
		entry = { cx = cx, cy = cy, minX = x, maxX = x, minY = y, maxY = y, rows = {} }
		self.dirtyChunks[key] = entry
		self.chunkQueue[#self.chunkQueue + 1] = key
	else
		entry.minX = math.min(entry.minX, x)
		entry.maxX = math.max(entry.maxX, x)
		entry.minY = math.min(entry.minY, y)
		entry.maxY = math.max(entry.maxY, y)
	end
	entry.rows[y] = true
end

function MapRenderer:markAround(i)
	local W, N = self.Map.W, self.Map.N
	if i < 1 or i > N then return end
	-- Border pixels depend on their four neighbours: mark adjacent chunks when
	-- a capture touches a chunk boundary, without wrapping at the map edge.
	self:markCell(i)
	if i > W then self:markCell(i - W) end
	if i <= N - W then self:markCell(i + W) end
	local x = (i - 1) % W
	if x > 0 then self:markCell(i - 1) end
	if x < W - 1 then self:markCell(i + 1) end
end

function MapRenderer:markAllChunks()
	for cy = 0, self.chunksY - 1 do
		for cx = 0, self.chunksX - 1 do
			local x0, y0 = cx * self.chunkSize, cy * self.chunkSize
			local key = cy * self.chunksX + cx + 1
			self.dirtyChunks[key] = {
				cx = cx, cy = cy, full = true,
				minX = x0, minY = y0,
				maxX = math.min(self.Map.W - 1, x0 + self.chunkSize - 1),
				maxY = math.min(self.Map.H - 1, y0 + self.chunkSize - 1),
			}
			self.chunkQueue[#self.chunkQueue + 1] = key
		end
	end
end

-- Colour of one cell: water, neutral land (with faint country lines), or a nation
-- (darker band on its outer border so neighbouring empires read as separate shapes).
function MapRenderer:cellColor(i)
	local Map, owner = self.Map, self.state.owner
	local W, N = Map.W, Map.N
	local o = owner[i]
	local x = (i - 1) % W
	local c = self.neutralColors
	local terrain = not self.plain and self.terrain
	if o == -1 then
		if terrain then return self.terrainColors[terrain[i]] or c.water end
		return Map.landNear and Map.landNear[i] and c.waterCoast or c.water
	end
	local country = Map.country[i]
	local otherOwner, otherCountry = false, false
	local j, oj
	for k = 1, 4 do
		if k == 1 then j = x > 0 and i - 1 or nil
		elseif k == 2 then j = x < W - 1 and i + 1 or nil
		elseif k == 3 then j = i > W and i - W or nil
		else j = i <= N - W and i + W or nil end
		if j then
			oj = owner[j]
			if oj ~= -1 then
				if oj ~= o then otherOwner = true end
				if Map.country[j] ~= country then otherCountry = true end
			end
		end
	end
	if self.plain then otherCountry = false end
	if terrain then
		local code = terrain[i]
		local base = self.terrainColors[code]
		if base and code >= 5 then
			if o == 0 then
				return otherCountry and self.terrainLines[code] or base
			end
			local nc = self.colors[o]
			if not nc then return base end
			if otherOwner then return nc.border end
			-- the nation's colour over the real terrain, like a tinted overlay
			local key = otherCountry and -code or code
			local mixed = nc.terrain[key]
			if not mixed then
				mixed = self.Palette.mix(otherCountry and nc.line or nc.fill, base, TERRAIN_SHOW_THROUGH)
				nc.terrain[key] = mixed
			end
			return mixed
		end
	end
	if o == 0 then
		if otherCountry then return c.line end
		return self.rowNeutral[(i - 1 - x) / W]
	end
	local nc = self.colors[o]
	if not nc then return c.fill end
	if otherOwner then return nc.border end
	if otherCountry then return nc.line end
	return nc.fill
end

function MapRenderer:paintFull()
	local Map = self.Map
	if not Map.landNear then
		Map.landNear = {}
		for i = 1, Map.N do
			if not Map.land[i] then
				local x = (i - 1) % Map.W
				if (x > 0 and Map.land[i - 1]) or (x < Map.W - 1 and Map.land[i + 1])
					or (i > Map.W and Map.land[i - Map.W]) or (i <= Map.N - Map.W and Map.land[i + Map.W]) then
					Map.landNear[i] = true
				end
			end
		end
	end
	if self.editable then
		local buf = self.buffer
		for i = 1, Map.N do
			local c = self:cellColor(i)
			local o = (i - 1) * 4
			buffer.writeu8(buf, o, c[1])
			buffer.writeu8(buf, o + 1, c[2])
			buffer.writeu8(buf, o + 2, c[3])
			buffer.writeu8(buf, o + 3, 255)
		end
		self.editable:WritePixelsBuffer(Vector2.zero, Vector2.new(Map.W, Map.H), buf)
	else
		-- Progressive first draw: 50 independently rendered chunks for 640x320,
		-- never thousands of 3D Parts. Unchanged chunks are left untouched.
		self:markAllChunks()
	end
end

-- EditableImage receives only the dirty rectangle INSIDE a chunk. Distant
-- simultaneous captures no longer force one huge bounding-box texture upload.
function MapRenderer:paintImageChunk(entry)
	local x0, x1 = entry.minX, entry.maxX
	local y0, y1 = entry.minY, entry.maxY
	local w, h = x1 - x0 + 1, y1 - y0 + 1
	local rect = buffer.create(w * h * 4)
	local W = self.Map.W
	for y = y0, y1 do
		for x = x0, x1 do
			local c = self:cellColor(y * W + x + 1)
			local off = ((y - y0) * w + (x - x0)) * 4
			buffer.writeu8(rect, off, c[1])
			buffer.writeu8(rect, off + 1, c[2])
			buffer.writeu8(rect, off + 2, c[3])
			buffer.writeu8(rect, off + 3, 255)
		end
	end
	self.editable:WritePixelsBuffer(Vector2.new(x0, y0), Vector2.new(w, h), rect)
end

-- Compatible fallback: each chunk owns reusable run-length Frames for its
-- rows. Capturing one cell redraws only its own (and adjacent border) rows,
-- rather than rebuilding an entire 640-cell strip across the world.
function MapRenderer:paintRowChunk(y, cx)
	local Map = self.Map
	local W, H = Map.W, Map.H
	local pool = self.rowPools[y]
	if not pool then pool = {} self.rowPools[y] = pool end
	local segments = pool[cx]
	if not segments then segments = {} pool[cx] = segments end
	local owner = self.state.owner
	local x = cx * self.chunkSize
	local xEnd = math.min(W, x + self.chunkSize)
	local used = 0
	self.plain = true -- avoid extra country-line frames at low settings
	while x < xEnd do
		local i = y * W + x + 1
		local stop = x + 1
		if owner[i] == -1 then
			while stop < xEnd and owner[y * W + stop + 1] == -1 do stop = stop + 1 end
		else
			local c = self:cellColor(i)
			while stop < xEnd do
				local j = y * W + stop + 1
				if owner[j] == -1 then break end
				local d = self:cellColor(j)
				if d[1] ~= c[1] or d[2] ~= c[2] or d[3] ~= c[3] then break end
				stop = stop + 1
			end
			used = used + 1
			local frame = segments[used]
			if not frame then
				frame = Instance.new("Frame")
				frame.BorderSizePixel = 0
				frame.ZIndex = 1
				frame.Parent = self.rowsFrame
				segments[used] = frame
			end
			frame.Position = UDim2.fromScale(x / W, y / H)
			-- Do not bleed a pixel into another chunk's territory.
			frame.Size = UDim2.new((stop - x) / W, stop < xEnd and 1 or 0, 1 / H, 1)
			frame.BackgroundColor3 = Color3.fromRGB(c[1], c[2], c[3])
			frame.Visible = true
		end
		x = stop
	end
	self.plain = false
	for k = used + 1, #segments do segments[k].Visible = false end
end

function MapRenderer:paintFrameChunk(entry)
	local y0 = entry.cy * self.chunkSize
	local y1 = math.min(self.Map.H - 1, y0 + self.chunkSize - 1)
	for y = y0, y1 do
		if entry.full or entry.rows[y] then
			self:paintRowChunk(y, entry.cx)
		end
	end
end

function MapRenderer:flush()
	if self.disposed then return end
	if self.fullDirty then
		self.fullDirty = false
		self.dirtyChunks, self.chunkQueue, self.queueHead = {}, {}, 1
		self:paintFull()
	end
	local budget = self.editable and IMAGE_CHUNKS_PER_FRAME or FRAME_CHUNKS_PER_FRAME
	for _ = 1, budget do
		local key = self.chunkQueue[self.queueHead]
		if not key then break end
		self.queueHead = self.queueHead + 1
		local entry = self.dirtyChunks[key]
		self.dirtyChunks[key] = nil
		if entry then
			if self.editable then
				self:paintImageChunk(entry)
			else
				self:paintFrameChunk(entry)
			end
		end
	end
	if self.queueHead > #self.chunkQueue then
		self.chunkQueue, self.queueHead = {}, 1
	end
end

return MapRenderer
