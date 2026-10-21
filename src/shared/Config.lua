local Config = {}

Config.Map = {
    Width = 48,
    Height = 28,
    CellSize = 4,
    CellHeight = 0.35,
    CellGap = 0.08,
    Origin = Vector3.new(0, 0, 0),
    NeutralColor = Color3.fromRGB(229, 227, 220),
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
