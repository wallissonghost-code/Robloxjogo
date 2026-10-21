local Config = {}

Config.Map = {
    Width = 120,
    Height = 60,
    CellSize = 4,
    CellHeight = 0.35,
    CellGap = 0.025,
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
    SendPercents = {10, 25, 35, 50, 75},
    DefaultSendPercent = 50,
}

Config.Camera = {
    MinHeight = 38,
    MaxHeight = 310,
    StartHeight = 245,
    PanSpeed = 0.0024,
    EdgePadding = 0,
    Overscan = 1.03,
}

Config.Debug = true
return Config
