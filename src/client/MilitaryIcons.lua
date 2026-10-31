-- Mundial War: centralized, original monochrome military card icons.
-- The 25-image source atlas is assets/military/military-atlas.png.
-- Do not invent Roblox asset IDs; leave nil until the image has been published.
-- Map sprites and colored world models are deliberately separate.
local MilitaryIcons = {}
MilitaryIcons.TILE_SIZE = 64
MilitaryIcons.ATLAS_ASSET_ID = nil -- Paste verified Creator Dashboard IMAGE asset ID.
MilitaryIcons.DEFAULT_COLOR = Color3.fromRGB(184, 191, 204) -- #B8BFCC
MilitaryIcons.LOCKED_COLOR = Color3.fromRGB(99, 109, 124)
MilitaryIcons.SELECTED_COLOR = Color3.fromRGB(245, 199, 92)

MilitaryIcons.Items = {
    city = { assetId = nil, atlasIndex = 0, source = "assets/military/icons/city.png", bitmap = {"0000", "0000", "0000", "03C0", "07E0", "07E0", "07E0", "07E8", "1FFC", "3FFC", "3FFC", "3FBC", "3FFC", "3FFC", "1FF8", "0000"}, },
    factory = { assetId = nil, atlasIndex = 1, source = "assets/military/icons/factory.png", bitmap = {"0000", "0000", "0000", "1800", "1C60", "1C70", "1CF0", "3FF8", "3FFC", "3FFC", "3FFC", "3ADC", "3FFC", "3FFC", "3FFC", "0000"}, },
    port = { assetId = nil, atlasIndex = 2, source = "assets/military/icons/port.png", bitmap = {"0000", "0180", "03C0", "03C0", "07E0", "07E0", "0180", "0180", "3FFC", "3FFC", "1998", "1C38", "0E70", "0660", "0000", "0000"}, },
    bunker = { assetId = nil, atlasIndex = 3, source = "assets/military/icons/bunker.png", bitmap = {"0000", "0000", "0000", "0000", "0000", "0000", "0FE0", "1FF8", "3FFC", "3FFC", "381C", "3FFC", "3F3C", "3FFC", "3FFC", "0000"}, },
    tower = { assetId = nil, atlasIndex = 4, source = "assets/military/icons/tower.png", bitmap = {"0000", "0000", "0000", "03C0", "0FF0", "1FF8", "1FF8", "1E78", "1FF8", "1FF8", "0660", "0FF0", "0FF0", "0C30", "0810", "0000"}, },
    machinegun = { assetId = nil, atlasIndex = 5, source = "assets/military/icons/machinegun.png", bitmap = {"0000", "0000", "0000", "0000", "000E", "1FBE", "3FFE", "3FFC", "1FC0", "0780", "0180", "03C0", "0760", "0E30", "0C10", "0000"}, },
    artillery = { assetId = nil, atlasIndex = 6, source = "assets/military/icons/artillery.png", bitmap = {"000F", "001F", "003E", "003C", "00F8", "01E0", "07C0", "0FC0", "0FC0", "0FE0", "1FFC", "33CC", "13C8", "3FFC", "3FFC", "0000"}, },
    tankfactory = { assetId = nil, atlasIndex = 7, source = "assets/military/icons/tankfactory.png", bitmap = {"0000", "0000", "0000", "1800", "1FC0", "1FE0", "1FFE", "1FFE", "1FF0", "0FF0", "0FF0", "3FFC", "37EC", "3FFC", "0000", "0000"}, },
    airfield = { assetId = nil, atlasIndex = 8, source = "assets/military/icons/airfield.png", bitmap = {"0000", "0000", "0000", "0180", "0180", "07E0", "0FF0", "1FF8", "3FFC", "3C3C", "3C3C", "3C3C", "3C3C", "3FFC", "0000", "0000"}, },
    airdefense = { assetId = nil, atlasIndex = 9, source = "assets/military/icons/airdefense.png", bitmap = {"0000", "0000", "0180", "0FF0", "1FF8", "1C38", "1998", "1FF8", "1FF8", "1DB8", "0E70", "0FF0", "07E0", "03C0", "0000", "0000"}, },
    silo = { assetId = nil, atlasIndex = 10, source = "assets/military/icons/silo.png", bitmap = {"0000", "0000", "0180", "0180", "03C0", "03C0", "0240", "03C0", "03C0", "07E0", "0FF0", "0FF0", "03C0", "1FF8", "1FF8", "0000"}, },
    wall = { assetId = nil, atlasIndex = 11, source = "assets/military/icons/wall.png", bitmap = {"0000", "0000", "0000", "0000", "0000", "3BB8", "3FF8", "3FFC", "3FFC", "3FFC", "0000", "3FDC", "3FDC", "3FFC", "3FFC", "0000"}, },
    trench = { assetId = nil, atlasIndex = 12, source = "assets/military/icons/trench.png", bitmap = {"0000", "0000", "0000", "0000", "0C60", "3FF8", "3FFC", "3FFC", "0FE0", "0FA0", "3FF8", "3FFC", "3FFC", "0380", "0000", "0000"}, },
    antinaval = { assetId = nil, atlasIndex = 13, source = "assets/military/icons/antinaval.png", bitmap = {"0000", "0000", "0000", "000E", "007E", "01FC", "07F0", "07C0", "0FE0", "1FE0", "1FE0", "1FC0", "3FFC", "3FFC", "3FFC", "3FFC"}, },
    flak = { assetId = nil, atlasIndex = 14, source = "assets/military/icons/flak.png", bitmap = {"0000", "1008", "381C", "1818", "1C38", "0C30", "0E70", "0FF0", "0FF0", "07E0", "0FF0", "1FF8", "3FFC", "3FFC", "3FFC", "0000"}, },
    oilwell = { assetId = nil, atlasIndex = 15, source = "assets/military/icons/oilwell.png", bitmap = {"0000", "0180", "0180", "03C0", "03C0", "0340", "07E0", "0FF0", "0660", "07E0", "0FF0", "0FF0", "0E70", "0FF0", "3FFC", "0000"}, },
    airlift = { assetId = nil, atlasIndex = 16, source = "assets/military/icons/airlift.png", bitmap = {"0000", "0000", "07E0", "1FF0", "1FF8", "3FFC", "3FFC", "318C", "1998", "0DB0", "05A0", "03C0", "03C0", "03C0", "0180", "0000"}, },
    airstrike = { assetId = nil, atlasIndex = 17, source = "assets/military/icons/airstrike.png", bitmap = {"0000", "0000", "0180", "0180", "0180", "0180", "07E0", "0FF0", "1FF8", "3FFC", "318C", "0180", "0180", "07E0", "0660", "0000"}, },
    cluster = { assetId = nil, atlasIndex = 18, source = "assets/military/icons/cluster.png", bitmap = {"0000", "1000", "3800", "0C00", "0E00", "0700", "0780", "07F0", "03F0", "03B0", "03F0", "01F8", "00FC", "000C", "0000", "0000"}, },
    firebomb = { assetId = nil, atlasIndex = 19, source = "assets/military/icons/firebomb.png", bitmap = {"0000", "0000", "0180", "0180", "03C0", "03D0", "03F0", "03F8", "0FF8", "1E78", "1E38", "1C78", "0E70", "07E0", "03C0", "0000"}, },
    emp = { assetId = nil, atlasIndex = 20, source = "assets/military/icons/emp.png", bitmap = {"0000", "00F0", "09E0", "39E0", "23C0", "07C0", "07F0", "0FF0", "0FF0", "01E0", "03C0", "0380", "0304", "0202", "0000", "0000"}, },
    atomic = { assetId = nil, atlasIndex = 21, source = "assets/military/icons/atomic.png", bitmap = {"0000", "0000", "03C0", "03C0", "03C0", "0180", "0180", "03C0", "3BDC", "3DBC", "1C38", "1C38", "0810", "0000", "0000", "0000"}, },
    hydrogen = { assetId = nil, atlasIndex = 22, source = "assets/military/icons/hydrogen.png", bitmap = {"0000", "0000", "0000", "1188", "0990", "07E0", "07E0", "1FF8", "1FF8", "07E0", "07E0", "0990", "1188", "0000", "0000", "0000"}, },
    endofera = { assetId = nil, atlasIndex = 23, source = "assets/military/icons/endofera.png", bitmap = {"0000", "03C0", "07E0", "1FF8", "3FFC", "3FFC", "3FFC", "1FF8", "0FF0", "03C0", "03C0", "03C0", "07E0", "1FF8", "3FFC", "0180"}, },
    biohazard = { assetId = nil, atlasIndex = 24, source = "assets/military/icons/biohazard.png", bitmap = {"0000", "03C0", "07E0", "0660", "07E0", "07E0", "0DB0", "3DBC", "7FFE", "6E76", "63C6", "7FFE", "3E7C", "0810", "0000", "0000"}, },
}

local function validId(value)
    local n = tonumber(value)
    if n and n > 0 and n == math.floor(n) then return n end
    return nil
end

-- Direct (individually published) asset IDs take precedence over an atlas ID.
function MilitaryIcons.source(kind)
    local info = MilitaryIcons.Items[kind]
    if not info then return nil, nil end
    local id = validId(info.assetId)
    if id then return "rbxassetid://" .. id, nil end
    local atlasId = validId(MilitaryIcons.ATLAS_ASSET_ID)
    if atlasId then
        local index = info.atlasIndex
        return "rbxassetid://" .. atlasId,
            Vector2.new((index % 5) * 64, math.floor(index / 5) * 64)
    end
    return nil, nil
end

-- When no published atlas ID exists, create a SINGLE shared 320x320 texture
-- from the exact 25 silhouettes already used by the Construir catalog.
-- This avoids dozens of individual GUI Frames for every icon on supported
-- clients. The existing frame-run fallback remains for devices/API restrictions.
local atlasAttempted, atlasContent = false, nil
local function ensureRuntimeAtlas()
    if atlasAttempted then return atlasContent end
    atlasAttempted = true
    local ok, result = pcall(function()
        local size, tile, pixelScale = 320, 64, 4
        local editable = game:GetService("AssetService"):CreateEditableImage({
            Size = Vector2.new(size, size),
        })
        if not editable then return nil end
        local pixels = buffer.create(size * size * 4) -- transparent by default
        for _, item in pairs(MilitaryIcons.Items) do
            local ox = (item.atlasIndex % 5) * tile
            local oy = math.floor(item.atlasIndex / 5) * tile
            for y = 1, 16 do
                local mask = tonumber(item.bitmap[y], 16) or 0
                for x = 1, 16 do
                    if bit32.band(bit32.rshift(mask, 16 - x), 1) ~= 0 then
                        for sy = 0, pixelScale - 1 do
                            for sx = 0, pixelScale - 1 do
                                local xx = ox + (x - 1) * pixelScale + sx
                                local yy = oy + (y - 1) * pixelScale + sy
                                local idx = (yy * size + xx) * 4
                                buffer.writeu8(pixels, idx, 255)
                                buffer.writeu8(pixels, idx + 1, 255)
                                buffer.writeu8(pixels, idx + 2, 255)
                                buffer.writeu8(pixels, idx + 3, 255)
                            end
                        end
                    end
                end
            end
        end
        editable:WritePixelsBuffer(Vector2.zero, Vector2.new(size, size), pixels)
        return Content.fromObject(editable)
    end)
    if ok then atlasContent = result end
    return atlasContent
end

-- Texture-ready icons use one GUI per silhouette. Unsupported clients
-- keep the identical Frame-run drawings, but show fewer at once on the map.
function MilitaryIcons.mapTextureReady()
    return validId(MilitaryIcons.ATLAS_ASSET_ID) ~= nil
        or ensureRuntimeAtlas() ~= nil
end

-- Attach a real ImageLabel. Until asset moderation/upload is complete, draw
-- the exact same silhouette from a tiny local bitmap using frame runs.
-- This explicit fallback does not rely on emojis, external URLs or Image APIs.
function MilitaryIcons.attach(parent, kind)
    local source, offset = MilitaryIcons.source(kind)
    local runtimeContent = nil
    if not source then
        runtimeContent = ensureRuntimeAtlas()
        if runtimeContent and MilitaryIcons.Items[kind] then
            local index = MilitaryIcons.Items[kind].atlasIndex
            offset = Vector2.new((index % 5) * 64, math.floor(index / 5) * 64)
        end
    end
    local image = Instance.new("ImageLabel")
    image.Name = "MonochromeIcon"
    image.BackgroundTransparency = 1
    image.Size = UDim2.fromScale(1, 1)
    image.ImageColor3 = MilitaryIcons.DEFAULT_COLOR
    image.ScaleType = Enum.ScaleType.Fit
    image.ZIndex = parent.ZIndex + 1
    local hasTexture = source ~= nil or runtimeContent ~= nil
    image.Visible = hasTexture
    if source then image.Image = source end
    if runtimeContent and not source then
        -- Runtime atlas is shared across ALL ImageLabels; one texture in memory.
        image.ImageContent = runtimeContent
    end
    if hasTexture and offset then
        image.ImageRectOffset = offset
        image.ImageRectSize = Vector2.new(64, 64)
    end
    image.Parent = parent

    local runs = {}
    if not hasTexture then
        local fallback = Instance.new("Frame")
        fallback.Name = "PendingAtlasFallback"
        fallback.Size = UDim2.fromScale(1, 1)
        fallback.BackgroundTransparency = 1
        fallback.ZIndex = parent.ZIndex + 1
        fallback.Parent = parent
        local info = MilitaryIcons.Items[kind]
        for y = 1, 16 do
            local mask = tonumber(info and info.bitmap[y] or "0000", 16) or 0
            local x = 1
            while x <= 16 do
                if bit32.band(bit32.rshift(mask, 16 - x), 1) ~= 0 then
                    local start = x
                    repeat
                        x = x + 1
                    until x > 16 or bit32.band(bit32.rshift(mask, 16 - x), 1) == 0
                    local run = Instance.new("Frame")
                    run.Name = "SilhouetteRun"
                    run.BorderSizePixel = 0
                    run.BackgroundColor3 = MilitaryIcons.DEFAULT_COLOR
                    run.Position = UDim2.fromScale((start - 1) / 16, (y - 1) / 16)
                    run.Size = UDim2.fromScale((x - start) / 16, 1 / 16)
                    run.ZIndex = fallback.ZIndex + 1
                    run.Parent = fallback
                    runs[#runs + 1] = run
                else
                    x = x + 1
                end
            end
        end
    end
    local handle = {}
    function handle:setColor(color)
        image.ImageColor3 = color
        for _, run in ipairs(runs) do run.BackgroundColor3 = color end
    end
    function handle:isPublished() return source ~= nil end
    function handle:usesTexture() return hasTexture end
    return handle
end

return MilitaryIcons
