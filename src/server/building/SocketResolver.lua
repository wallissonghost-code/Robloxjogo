local Workspace = game:GetService("Workspace")
local Resolver = {}
local CELL=12
local EDGES={N={dx=0,dz=-6,rot=0},S={dx=0,dz=6,rot=0},W={dx=-6,dz=0,rot=90},E={dx=6,dz=0,rot=90}}
local function pieces(base) return base and base.pieces or {} end
local function foundations(base) local out={} for _,p in ipairs(pieces(base)) do if p.type=="Foundation" then table.insert(out,p) end end return out end
local function occupied(base,key) for _,p in ipairs(pieces(base)) do if p.socketKey==key then return true,p end end return false end
local function nearest(list,pos,maxDist) local best,bestD for _,c in ipairs(list) do local d=(c.position-pos).Magnitude if not bestD or d<bestD then best,bestD=c,d end end return best,bestD and bestD<=maxDist end
local function groundAt(x,z,yHint)
	local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
	local builds=Workspace:FindFirstChild("PersistentBuilds");params.FilterDescendantsInstances=builds and {builds} or {}
	local ray=Workspace:Raycast(Vector3.new(x,(yHint or 0)+35,z),Vector3.new(0,-100,0),params)
	if not ray or ray.Material==Enum.Material.Water then return nil end return ray.Position.Y
end
local function foundationKey(x,z) return string.format("F:%d:%d",math.round(x*10),math.round(z*10)) end
local function edgeKey(x,z,rotation)
	local axis=rotation==0 and "H" or "V"
	return string.format("EDGE:%s:%d:%d",axis,math.round(x*10),math.round(z*10))
end

function Resolver.resolve(base,pieceType,rawPosition)
	local fs=foundations(base)
	if pieceType=="Foundation" then
		if #fs==0 then
			local x=math.floor(rawPosition.X/CELL+.5)*CELL;local z=math.floor(rawPosition.Z/CELL+.5)*CELL
			local ground=groundAt(x,z,rawPosition.Y);if not ground then return nil,"Terreno inválido." end
			local key=foundationKey(x,z);if occupied(base,key) then return nil,"Fundação já ocupa este encaixe." end
			return {position=Vector3.new(x,ground+.5,z),rotation=0,socketKey=key}
		end
		local candidates={}
		for _,f in ipairs(fs) do for _,e in pairs(EDGES) do
			local x,z=f.x+e.dx*2,f.z+e.dz*2;local key=foundationKey(x,z)
			if not occupied(base,key) then table.insert(candidates,{position=Vector3.new(x,f.y,z),rotation=0,socketKey=key}) end
		end end
		local c,ok=nearest(candidates,rawPosition,9);if not ok then return nil,"Aproxime da lateral de uma fundação." end return c
	end
	if #fs==0 then return nil,"Coloque uma fundação primeiro." end
	if pieceType=="Wall" or pieceType=="Door" then
		local candidates={}
		for _,f in ipairs(fs) do for name,e in pairs(EDGES) do
			local ex,ez=f.x+e.dx,f.z+e.dz;local key=edgeKey(ex,ez,e.rot)
			if not occupied(base,key) then table.insert(candidates,{position=Vector3.new(ex,f.y+3.5,ez),rotation=e.rot,socketKey=key,foundationKey=f.socketKey or foundationKey(f.x,f.z),edge=name}) end
		end end
		local c,ok=nearest(candidates,rawPosition,8);if not ok then return nil,"Mire em uma borda livre da fundação." end return c
	end
	if pieceType=="Roof" then
		local candidates={}
		for _,f in ipairs(fs) do
			local fkey=f.socketKey or foundationKey(f.x,f.z);local roofKey=fkey..":ROOF"
			if not occupied(base,roofKey) then
				local complete=true
				for _,e in pairs(EDGES) do if not occupied(base,edgeKey(f.x+e.dx,f.z+e.dz,e.rot)) then complete=false break end end
				if complete then table.insert(candidates,{position=Vector3.new(f.x,f.y+8,f.z),rotation=0,socketKey=roofKey,foundationKey=fkey}) end
			end
		end
		local c,ok=nearest(candidates,rawPosition,10);if not ok then return nil,"Complete as quatro laterais antes do teto." end return c
	end
	return nil,"Peça inválida."
end

function Resolver.withLegacySockets(base)
	for _,p in ipairs(pieces(base)) do
		if p.type=="Foundation" and not p.socketKey then p.socketKey=foundationKey(p.x,p.z)
		elseif (p.type=="Wall" or p.type=="Door") and not p.socketKey then p.socketKey=edgeKey(p.x,p.z,p.rotation or 0) end
	end
	return base
end
return Resolver
