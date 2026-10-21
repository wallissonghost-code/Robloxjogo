local Config = {}

Config.Map = {
    Width = 160,
    Height = 80,
    CellSize = 6,
    CellHeight = 0.18,
    CellGap = 0,
    Origin = Vector3.new(0,0,0),
    NeutralColor = Color3.fromRGB(205,205,196),
    WaterColor = Color3.fromRGB(67,137,183),
    CoastColor = Color3.fromRGB(205,205,196),
}
Config.Player = {
    StartingTroops = 2500,
    BaseTroopCapacity = 250000,
    TroopsPerTick = 35,
    RegenInterval = 1,
}
Config.Bot = {
    StartingTroops = 1500,
    BaseTroopCapacity = 180000,
    TroopsPerTick = 24,
    ThinkInterval = 1.2,
    InternalExpansionTarget = 0.78,
}
Config.Territory = {
    SendPercents = {10,25,35,50,75},
    DefaultSendPercent = 50,
    ExpansionStepDelay = 0.045,
    TroopsPerNeutralCell = 18,
    MaxCellsPerOrder = 90,
}
Config.Camera = {
    MinHeight = 52,
    MaxHeight = 650,
    StartHeight = 475,
    PanSpeed = 0.0024,
    EdgePadding = 0,
    Overscan = 1.02,
}
Config.Debug=true
return Config
