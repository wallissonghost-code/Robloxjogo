-- Shared public configuration only. Never put credentials or authority here.
local Config = {
    Version = "0.1.0-map-foundation",
    Map = {
        Version = 1,
        Width = 240,
        Height = 120,
        ChunkSize = 16,
        MinLongitude = -180,
        MaxLongitude = 180,
        MinLatitude = -60,
        MaxLatitude = 85,
    },
    View = {
        MinZoom = 1,
        MaxZoom = 8,
        ZoomStep = 1.4,
        DragThreshold = 8,
        WaterColor = {19, 43, 62},
        LandColor = {137, 167, 143},
    },
    -- Reserved for the next stages; these values do not start an economy yet.
    SendPercentages = {10, 25, 35, 50, 75},
}

return Config
