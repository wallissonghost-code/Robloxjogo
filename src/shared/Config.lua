-- Shared public configuration only. Never put credentials or authority here.
local Config = {
    Version = "0.2.0-nations",
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
    Nations = {
        Palette = {
            {67, 169, 242}, {240, 113, 99}, {234, 191, 72}, {169, 127, 229},
            {75, 203, 171}, {241, 149, 68}, {219, 119, 183}, {151, 195, 79},
            {112, 139, 239}, {211, 182, 143}, {89, 199, 218}, {225, 219, 206},
        },
    },
    Network = {Burst = 6, RefillPerSecond = 2, SyncInterval = 2},
}

return Config
