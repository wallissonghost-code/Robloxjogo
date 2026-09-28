local Workspace=game:GetService("Workspace")
local Config=require(script.Parent.World.Config)
local TerrainShape=require(script.Parent.World.Terrain)

local worldId
repeat worldId=game:GetAttribute("WorldId");if not worldId then game:GetAttributeChangedSignal("WorldId"):Wait() end until type(worldId)=="string" and worldId~=""

local resourceConfig=Config.RESOURCES
local root=Workspace:FindFirstChild("WorldResources") or Instance.new("Folder")
root.Name="WorldResources";root.Parent=Workspace
local builds=Workspace:FindFirstChild("PersistentBuilds")
if not builds then builds=Workspace:WaitForChild("PersistentBuilds",15) end
local seed=Config.SEED
for i=1,#worldId do seed+=string.byte(worldId,i)*i end
local rng=Random.new(seed)
local clusters={}

local function terrainY(x,z) return TerrainShape.heightAt(x,z) end
local function insideWater(x,z,y)
	if y<=Config.WATER_LEVEL+1 then return true end
	for _,lake in ipairs(Config.LAKES) do
		local d=((x-lake.x)/lake.rx)^2+((z-lake.z)/lake.rz)^2
		if d<1 and y<=lake.level+2 then return true end
	end
	return false
end
local function slopeOK(x,z)
	local y=terrainY(x,z);local d=5
	local maxDelta=math.max(math.abs(terrainY(x+d,z)-y),math.abs(terrainY(x-d,z)-y),math.abs(terrainY(x,z+d)-y),math.abs(terrainY(x,z-d)-y))
	return maxDelta<=5
end
local function nearBuild(pos,radius)
	if not builds then return false end
	for _,m in ipairs(builds:GetChildren()) do
		local cf,size=m:GetBoundingBox()
		local dx=math.max(math.abs(pos.X-cf.Position.X)-size.X/2,0)
		local dz=math.max(math.abs(pos.Z-cf.Position.Z)-size.Z/2,0)
		if dx*dx+dz*dz<radius*radius then return true end
	end
	return false
end
local function nearResource(pos,minSpacing)
	for _,m in ipairs(root:GetChildren()) do
		local p=m:GetAttribute("ResourcePosition")
		if typeof(p)=="Vector3" and (Vector3.new(p.X,0,p.Z)-Vector3.new(pos.X,0,pos.Z)).Magnitude<minSpacing then return true end
	end
	return false
end
local function candidate(kind,def)
	local half=Config.LAND_HALF-resourceConfig.EDGE_MARGIN
	local center=clusters[kind]
	local x,z
	if center and rng:NextNumber()<def.clusterChance then
		local a=rng:NextNumber(0,math.pi*2);local r=math.sqrt(rng:NextNumber())*def.clusterRadius
		x=math.clamp(center.X+math.cos(a)*r,-half,half);z=math.clamp(center.Z+math.sin(a)*r,-half,half)
	else
		x=rng:NextNumber(-half,half);z=rng:NextNumber(-half,half)
		if rng:NextNumber()<.28 then clusters[kind]=Vector2.new(x,z) end
	end
	local y=terrainY(x,z)
	if insideWater(x,z,y) or not slopeOK(x,z) then return nil end
	local pos=Vector3.new(x,y,z)
	if nearBuild(pos,resourceConfig.BASE_EXCLUSION_RADIUS) or nearResource(pos,def.minSpacing) then return nil end
	return pos
end
local function baseModel(kind,pos)
	local m=Instance.new("Model");m.Name=kind;m:SetAttribute("ResourceType",kind);m:SetAttribute("ResourcePosition",pos);m:SetAttribute("WorldId",worldId);return m
end
local function part(parent,name,size,cf,material)
	local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Anchored=true;p.Material=material;p.Parent=parent;return p
end
local function spawnResource(kind,pos)
	local m=baseModel(kind,pos)
	if kind=="Tree" then
		local scale=rng:NextNumber(.8,1.2);local trunk=part(m,"Trunk",Vector3.new(2.2,9,2.2)*scale,CFrame.new(pos+Vector3.new(0,4.5*scale,0)),Enum.Material.Wood)
		trunk.Color=Color3.fromRGB(91,63,42)
		local crown=part(m,"Crown",Vector3.new(8,7,8)*scale,CFrame.new(pos+Vector3.new(0,9.5*scale,0)),Enum.Material.Grass);crown.Shape=Enum.PartType.Ball;crown.CanCollide=false;crown.Color=Color3.fromRGB(48,102,48)
	elseif kind=="Rock" then
		local s=rng:NextNumber(3.8,6.5);local p=part(m,"Rock",Vector3.new(s,s*.72,s*.88),CFrame.new(pos+Vector3.new(0,s*.3,0))*CFrame.Angles(0,rng:NextNumber(0,6.28),rng:NextNumber(-.15,.15)),Enum.Material.Slate);p.Color=Color3.fromRGB(92,96,91)
	elseif kind=="Stick" then
		local p=part(m,"Stick",Vector3.new(.35,.35,rng:NextNumber(2.2,3.8)),CFrame.new(pos+Vector3.new(0,.22,0))*CFrame.Angles(0,rng:NextNumber(0,6.28),rng:NextNumber(-.08,.08)),Enum.Material.Wood);p.CanCollide=false;p.Color=Color3.fromRGB(105,76,48)
	else
		local s=rng:NextNumber(.65,1.25);local p=part(m,"SmallStone",Vector3.new(s,s*.55,s*.8),CFrame.new(pos+Vector3.new(0,s*.25,0))*CFrame.Angles(0,rng:NextNumber(0,6.28),0),Enum.Material.Slate);p.CanCollide=false;p.Color=Color3.fromRGB(110,113,108)
	end
	m.Parent=root
end
local function counts()
	local c={Tree=0,Rock=0,Stick=0,SmallStone=0}
	for _,m in ipairs(root:GetChildren()) do local k=m:GetAttribute("ResourceType");if c[k]~=nil then c[k]+=1 end end
	return c
end
local function maintenance(initial)
	local c=counts();local budget=initial and math.huge or resourceConfig.MAX_SPAWNS_PER_CYCLE
	local attempts=0
	for kind,def in pairs(resourceConfig.TYPES) do
		local missing=math.max(0,def.target-c[kind])
		while missing>0 and budget>0 and attempts<resourceConfig.MAX_ATTEMPTS_PER_CYCLE do
			attempts+=1
			local pos=candidate(kind,def)
			if pos then spawnResource(kind,pos);missing-=1;budget-=1 end
		end
		if budget<=0 or attempts>=resourceConfig.MAX_ATTEMPTS_PER_CYCLE then break end
	end
end

maintenance(true)
while true do task.wait(resourceConfig.MAINTENANCE_SECONDS);maintenance(false) end
