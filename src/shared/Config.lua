local Config = {}

Config.Map = {
    Width = 64,
    Height = 36,
    CellSize = 3,
    CellHeight = 0.35,
    CellGap = 0.08,
    Origin = Vector3.new(0, 0, 0),
    NeutralColor = Color3.fromRGB(218, 216, 207),
    WaterColor = Color3.fromRGB(79, 151, 199),
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
    MinHeight = 55,
    MaxHeight = 235,
    StartHeight = 150,
    PanSpeed = 0.0024,
    EdgePadding = 6,
}

Config.Debug = true
return Config
