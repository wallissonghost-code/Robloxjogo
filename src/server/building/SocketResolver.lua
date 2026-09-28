local Workspace=game:GetService("Workspace")
local Resolver={}
local CELL=12
local FOUNDATION_HEIGHT=4
local HALF_FOUNDATION=FOUNDATION_HEIGHT/2
local SNAP_FOUNDATION=11
local SNAP_EDGE=11
local SNAP_ROOF=12
local FOUNDATION_LEVELS={Low=-3,Medium=0,High=4}
local EDGES={N={dx=0,dz=-6,rot=0},S={dx=0,dz=6,rot=0},W={dx=-6,dz=0,rot=90},E={dx=6,dz=0,rot=90}}

local function pieces(base) return base and base.pieces or {} end
local function foundations(base) local out={} for _,p in ipairs(pieces(base)) do if p.type=="Foundation" then table.insert(out,p) end end return out end
local function occupied(base,key) for _,p in ipairs(pieces(base)) do if p.socketKey==key then return true,p end end return false end
local function nearest(list,pos,maxDist) local best,bestD for _,c in ipairs(list) do local d=(c.position-pos).Magnitude if not bestD or d<bestD then best,bestD=c,d end end return best,bestD and bestD<=maxDist end
local function groundAt(x,z,yHint)
	local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
	local builds=Workspace:FindFirstChild("PersistentBuilds");params.FilterDescendantsInstances=builds and {builds} or {}
	local ray=Workspace:Raycast(Vector3.new(x,(yHint or 0)+45,z),Vector3.new(0,-140,0),params)
	if not ray or ray.Material==Enum.Material.Water then return nil end return ray.Position.Y
end
local function foundationKey(x,z) return string.format("F:%d:%d",math.round(x*10),math.round(z*10)) end
local function edgeKey(x,z,rotation) local axis=rotation==0 and "H" or "V";return string.format("EDGE:%s:%d:%d",axis,math.round(x*10),math.round(z*10)) end
local function foundationTop(f) local height=tonumber(f.foundationHeight) or (f.schemaVersion==2 and FOUNDATION_HEIGHT or 1);return f.y+height/2 end
local function normalizeLevel(level) return FOUNDATION_LEVELS[level] and level or "Medium" end
local function freeFoundation(base,raw,level)
	local x=math.floor(raw.X/CELL+.5)*CELL;local z=math.floor(raw.Z/CELL+.5)*CELL
	local ground=groundAt(x,z,raw.Y);if not ground then return nil,"Terreno inválido." end
	local key=foundationKey(x,z);if occupied(base,key) then return nil,"Fundação já ocupa este local." end
	level=normalizeLevel(level)
	local desiredTop=ground+FOUNDATION_LEVELS[level]
	return {position=Vector3.new(x,desiredTop-HALF_FOUNDATION,z),rotation=0,socketKey=key,foundationHeight=FOUNDATION_HEIGHT,foundationLevel=level,schemaVersion=2}
end

function Resolver.resolve(base,pieceType,rawPosition,options)
	options=type(options)=="table" and options or {}
	local fs=foundations(base)
	if pieceType=="Foundation" then
		local candidates={}
		for _,f in ipairs(fs) do for _,e in pairs(EDGES) do
			local x,z=f.x+e.dx*2,f.z+e.dz*2;local key=foundationKey(x,z)
			if not occupied(base,key) then table.insert(candidates,{position=Vector3.new(x,f.y,z),rotation=0,socketKey=key,foundationHeight=tonumber(f.foundationHeight) or (f.schemaVersion==2 and FOUNDATION_HEIGHT or 1),foundationLevel=f.foundationLevel or "Connected",schemaVersion=2}) end
		end end
		local snapped,ok=nearest(candidates,rawPosition,SNAP_FOUNDATION);if ok then return snapped end
		return freeFoundation(base,rawPosition,options.foundationLevel)
	end
	if #fs==0 then return nil,"Coloque uma fundação primeiro." end
	if pieceType=="Wall" or pieceType=="Door" then
		local candidates={}
		for _,f in ipairs(fs) do local top=foundationTop(f);for name,e in pairs(EDGES) do
			local ex,ez=f.x+e.dx,f.z+e.dz;local key=edgeKey(ex,ez,e.rot)
			if not occupied(base,key) then table.insert(candidates,{position=Vector3.new(ex,top+4,ez),rotation=e.rot,socketKey=key,foundationKey=f.socketKey or foundationKey(f.x,f.z),edge=name,schemaVersion=2}) end
		end end
		local c,ok=nearest(candidates,rawPosition,SNAP_EDGE);if not ok then return nil,"Aproxime de uma borda livre da fundação." end return c
	end
	if pieceType=="Roof" then
		local candidates={}
		for _,f in ipairs(fs) do local fkey=f.socketKey or foundationKey(f.x,f.z);local roofKey=fkey..":ROOF"
			if not occupied(base,roofKey) then
				local hasWall=false;for _,e in pairs(EDGES) do if occupied(base,edgeKey(f.x+e.dx,f.z+e.dz,e.rot)) then hasWall=true break end end
				if hasWall then table.insert(candidates,{position=Vector3.new(f.x,foundationTop(f)+8.5,f.z),rotation=0,socketKey=roofKey,foundationKey=fkey,schemaVersion=2}) end
			end
		end
		local c,ok=nearest(candidates,rawPosition,SNAP_ROOF);if not ok then return nil,"O teto precisa de fundação com pelo menos uma parede ou porta." end return c
	end
	return nil,"Peça inválida."
end

function Resolver.withLegacySockets(base)
	for _,p in ipairs(pieces(base)) do
		if p.type=="Foundation" and not p.socketKey then p.socketKey=foundationKey(p.x,p.z)
		elseif (p.type=="Wall" or p.type=="Door") and not p.socketKey then p.socketKey=edgeKey(p.x,p.z,p.rotation or 0)
		elseif p.type=="Roof" and not p.socketKey then
			local best,bestD;for _,f in ipairs(foundations(base)) do local d=(Vector3.new(f.x,foundationTop(f),f.z)-Vector3.new(p.x,p.y-8.5,p.z)).Magnitude;if not bestD or d<bestD then best,bestD=f,d end end
			if best and bestD<4 then p.socketKey=(best.socketKey or foundationKey(best.x,best.z))..":ROOF" end
		end
	end
	return base
end
return Resolver
