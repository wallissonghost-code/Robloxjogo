local Catalog = {
	Foundation = { family="FOUNDATION", size=Vector3.new(12,4,12), offsetY=2 },
	Wall = { family="EDGE", size=Vector3.new(12,8,1), offsetY=4 },
	Door = { family="EDGE", size=Vector3.new(12,8,1), offsetY=4, doorway=true },
	Roof = { family="ROOF", size=Vector3.new(12,1,12), offsetY=.5 },
}
return Catalog
