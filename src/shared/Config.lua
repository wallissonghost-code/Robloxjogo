local Config = {}

Config.Map = {
    Width = 72,
    Height = 36,
    CellSize = 3,
    CellHeight = 0.35,
    CellGap = 0.03,
    Origin = Vector3.new(0, 0, 0),
    NeutralColor = Color3.fromRGB(218, 216, 207),
    WaterColor = Color3.fromRGB(67, 137, 183),
    CoastColor = Color3.fromRGB(231, 225, 190),
}

Config.Player = {
    StartingTroops = 1000,
    BaseTroopCapacity = 5000,
    TroopsPerTick = 30,
    RegenInterval = 1,
}

Config.Territory = {
    NeutralClaimCost = 100,
}

Config.Camera = {
    MinHeight = 24,
    MaxHeight = 150,
    StartHeight = 112,
    PanSpeed = 0.0024,
    EdgePadding = 0,
    Overscan = 1.08,
}

Config.Debug = true
return Config
