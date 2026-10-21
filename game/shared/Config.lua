local Config = {}

Config.Map = {
	Columns = 64,
	Rows = 34,
	CellSize = 6,
	CellGap = 0.18,
	OceanColor = Color3.fromRGB(59, 132, 181),
	NeutralColors = {
		Color3.fromRGB(207, 218, 173),
		Color3.fromRGB(221, 211, 168),
		Color3.fromRGB(194, 218, 158),
		Color3.fromRGB(226, 220, 194),
	},
}

Config.Economy = {
	StartTroops = 120,
	StartGold = 3000,
	BaseTroopsPerSecond = 5,
	TroopsPerCellPerSecond = 0.8,
	BaseGoldPerSecond = 8,
	GoldPerCellPerSecond = 0.35,
	BaseTroopCap = 600,
	TroopCapPerCell = 20,
}

Config.Territory = {
	StartRadius = 1,
	NeutralCaptureCost = 8,
	AttackMinTroops = 12,
	MaxCellsPerAttack = 7,
}

Config.SendPercents = {0.10, 0.25, 0.35, 0.50, 0.75}
Config.DefaultSendPercent = 0.25

Config.Buildings = {
	City = {
		DisplayName = "Cidade",
		Cost = 2500,
		Max = 6,
		TroopCap = 450,
		TroopRate = 1.5,
		Icon = "C",
	},
	Port = {
		DisplayName = "Porto",
		Cost = 1500,
		Max = 6,
		GoldRate = 2,
		RequiresCoast = true,
		Icon = "P",
	},
	Factory = {
		DisplayName = "Fábrica",
		Cost = 1800,
		Max = 8,
		GoldRate = 5,
		TroopRate = 2,
		Icon = "F",
	},
	Defense = {
		DisplayName = "Defesa",
		Cost = 1200,
		Max = 12,
		Defense = 0.08,
		Icon = "D",
	},
}

Config.Bot = {
	Count = 18,
	ActionInterval = 1.35,
	BuildChance = 0.08,
}

return Config
