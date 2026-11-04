-- Mundial War · paints the territory map.
-- "image" mode: one pixel per cell in a single EditableImage (one draw call). Needs
--   "Enable Mesh / Image APIs" in the experience settings; without it Roblox shows a
--   pink/blue checkerboard instead of the picture.
-- "frames" mode: pooled rectangular runs merged across short row bands, grouped
--   by chunk for camera culling; water uses the ocean backdrop. Works everywhere.
local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")

local MapRenderer = {}
MapRenderer.__index = MapRenderer

local BORDER_SHADE = 0.58
local COUNTRY_SHADE = 0.9
-- Each 64x64 region is an independent repaint unit. The logical map remains
-- 640x320; chunks affect rendering only, not simulation or territory rules.
local DEFAULT_CHUNK_SIZE = 64
local FRAME_CHUNKS_PER_FRAME = 1
local IMAGE_CHUNKS_PER_FRAME = 8
-- Merge horizontally identical runs across eight rows, but only rebuild
-- affected bands when cells change.
local FRAME_BAND_HEIGHT = 8

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
		self.frameChunks = {} -- chunk -> pooled rectangles grouped by band
		self.frameColors = {} -- packed RGB -> cached Color3
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
	self.editable, self.frameChunks, self.frameColors, self.dirtyChunks = nil, nil, nil
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
	if o == -1 then
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

-- Culling only groups Frames; camera changes never repaint territory.
function MapRenderer:chunkOnscreen(chunk)
	if not self.viewMinX then return true end
	return chunk.x1 >= self.viewMinX and chunk.x0 <= self.viewMaxX
		and chunk.y1 >= self.viewMinY and chunk.y0 <= self.viewMaxY
end

-- Camera reports map-space bounds when pan, zoom, or viewport size changes.
-- One extra cell protects against rounding seams near the viewport edge.
function MapRenderer:setView(cx, cy, scale, viewportSize)
	if self.disposed or not self.frameChunks then return end
	if not scale or scale <= 0 or not viewportSize
		or viewportSize.X <= 0 or viewportSize.Y <= 0 then return end
	local dx = viewportSize.X / (2 * scale) + 1
	local dy = viewportSize.Y / (2 * scale) + 1
	self.viewMinX, self.viewMaxX = cx - dx, cx + dx
	self.viewMinY, self.viewMaxY = cy - dy, cy + dy
	for _, chunk in pairs(self.frameChunks) do
		local visible = self:chunkOnscreen(chunk)
		if chunk.root.Visible ~= visible then chunk.root.Visible = visible end
	end
end

local function packedColor(color)
	return color[1] * 65536 + color[2] * 256 + color[3]
end

-- Draw one horizontal band as maximal vertical rectangles where each row
-- has identical pixel runs. This reduces GUI count without reducing map detail.
-- Bands are small so one captured cell never repaints an entire 64x64 chunk.
function MapRenderer:paintFrameBand(chunk, band)
	local W = self.Map.W
	local x0, xEnd = chunk.x0, chunk.x1 + 1
	local y0 = chunk.y0 + band * FRAME_BAND_HEIGHT
	local yEnd = math.min(chunk.y1 + 1, y0 + FRAME_BAND_HEIGHT)
	local owner = self.state.owner
	local rectangles, above = {}, {}
	self.plain = true -- same low-graphics colours as the old row renderer
	for y = y0, yEnd - 1 do
		local nextRow = {}
		local x = x0
		while x < xEnd do
			local idx = y * W + x + 1
			local stop = x + 1
			if owner[idx] == -1 then
				-- The ocean backdrop already paints the water.
				while stop < xEnd and owner[y * W + stop + 1] == -1 do stop = stop + 1 end
			else
				local color = self:cellColor(idx)
				local rgb = packedColor(color)
				while stop < xEnd do
					local j = y * W + stop + 1
					if owner[j] == -1 then break end
					if packedColor(self:cellColor(j)) ~= rgb then break end
					stop = stop + 1
				end
				local rect = above[x]
				if rect and rect.stop == stop and rect.rgb == rgb then
					rect.height = rect.height + 1
				else
					rect = { x = x, y = y, stop = stop, height = 1, color = color, rgb = rgb }
					rectangles[#rectangles + 1] = rect
				end
				nextRow[x] = rect
			end
			x = stop
		end
		above = nextRow
	end
	self.plain = false

	local pool = chunk.bands[band]
	if not pool then pool = {} chunk.bands[band] = pool end
	local width, height = chunk.x1 - chunk.x0 + 1, chunk.y1 - chunk.y0 + 1
	for n, rect in ipairs(rectangles) do
		local frame = pool[n]
		if not frame then
			frame = Instance.new("Frame")
			frame.Name = "TerritoryRect"
			frame.BorderSizePixel = 0
			frame.ZIndex = 1
			frame.Parent = chunk.root
			pool[n] = frame
		end
		frame.Position = UDim2.fromScale((rect.x - chunk.x0) / width, (rect.y - chunk.y0) / height)
		-- Original 1-pixel overhang prevents hairline gaps at fractional scales.
		frame.Size = UDim2.new((rect.stop - rect.x) / width,
			rect.stop < xEnd and 1 or 0, rect.height / height, 1)
		local tint = self.frameColors[rect.rgb]
		if not tint then
			tint = Color3.fromRGB(rect.color[1], rect.color[2], rect.color[3])
			self.frameColors[rect.rgb] = tint
		end
		frame.BackgroundColor3 = tint
		if not frame.Visible then frame.Visible = true end
	end
	for n = #rectangles + 1, #pool do
		if pool[n].Visible then pool[n].Visible = false end
	end
end

function MapRenderer:paintFrameChunk(entry)
	local key = entry.cy * self.chunksX + entry.cx + 1
	local chunk = self.frameChunks[key]
	if not chunk then
		local x0, y0 = entry.cx * self.chunkSize, entry.cy * self.chunkSize
		local x1 = math.min(self.Map.W - 1, x0 + self.chunkSize - 1)
		local y1 = math.min(self.Map.H - 1, y0 + self.chunkSize - 1)
		local root = Instance.new("Frame")
		root.Name = "TerritoryChunk"
		root.BackgroundTransparency = 1
		root.BorderSizePixel = 0
		root.ZIndex = 1
		root.Position = UDim2.fromScale(x0 / self.Map.W, y0 / self.Map.H)
		root.Size = UDim2.fromScale((x1 - x0 + 1) / self.Map.W, (y1 - y0 + 1) / self.Map.H)
		root.Parent = self.rowsFrame
		chunk = { root = root, bands = {}, x0 = x0, x1 = x1, y0 = y0, y1 = y1 }
		self.frameChunks[key] = chunk
		root.Visible = self:chunkOnscreen(chunk)
	end
	local dirtyBands = {}
	if entry.full then
		for band = 0, math.floor((chunk.y1 - chunk.y0) / FRAME_BAND_HEIGHT) do
			dirtyBands[band] = true
		end
	else
		for row in pairs(entry.rows or {}) do
			dirtyBands[math.floor((row - chunk.y0) / FRAME_BAND_HEIGHT)] = true
		end
	end
	for band in pairs(dirtyBands) do self:paintFrameBand(chunk, band) end
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
