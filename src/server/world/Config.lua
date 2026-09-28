return {
	WORLD = 5200,
	CELL = 20,
	WATER_LEVEL = 4,
	RIVER_HALF_WIDTH = 34,
	LAND_HALF = 2480,
	BOUNDARY_HEIGHT = 220,
	BOUNDARY_THICKNESS = 80,
	BOUNDARY_SEGMENT_LENGTH = 512,
	BOUNDARY_SEAM_OVERLAP = 2,
	SEED = 2709,

	LAKES = {
		{ x = 850, z = -850, rx = 230, rz = 165, level = 6 },
		{ x = -1250, z = 1050, rx = 290, rz = 205, level = 3 },
		{ x = 1450, z = 1250, rx = 190, rz = 250, level = 8 },
		{ x = -1550, z = -1150, rx = 240, rz = 180, level = 5 },
	},

	RESOURCES = {
		MAINTENANCE_SECONDS = 60,
		MAX_SPAWNS_PER_CYCLE = 60,
		MAX_ATTEMPTS_PER_CYCLE = 240,
		BASE_EXCLUSION_RADIUS = 24,
		EDGE_MARGIN = 120,
		TYPES = {
			Tree = { target = 420, minSpacing = 13, clusterRadius = 85, clusterChance = .62 },
			Rock = { target = 170, minSpacing = 15, clusterRadius = 70, clusterChance = .48 },
			Stick = { target = 300, minSpacing = 4, clusterRadius = 45, clusterChance = .72 },
			SmallStone = { target = 260, minSpacing = 4, clusterRadius = 42, clusterChance = .68 },
		},
	},

	FLAT_ZONES = {
		{ x = 0, z = 0, radius = 180, height = 18 },
		{ x = 820, z = -620, radius = 240, height = 24 },
		{ x = -1050, z = 760, radius = 280, height = 20 },
		{ x = 1250, z = 1150, radius = 220, height = 28 },
		{ x = -1450, z = -1050, radius = 260, height = 22 },
	},
}
