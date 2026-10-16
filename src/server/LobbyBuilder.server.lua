local ReplicatedStorage=game:GetService("ReplicatedStorage")
local InsertService=game:GetService("InsertService")
local Players=game:GetService("Players")
local DataStoreService=game:GetService("DataStoreService")

local OWNER_USER_ID=9538436641
local HALLOWEEN_ASSET_ID=113280926555931
local BUILD_STORE=DataStoreService:GetDataStore("LobbyCreativeBuild_V1")
local BUILD_KEY="HalloweenLobby"

local remotes=ReplicatedStorage:FindFirstChild("LobbyBuilderRemotes") or Instance.new("Folder")
remotes.Name="LobbyBuilderRemotes"; remotes.Parent=ReplicatedStorage
local request=remotes:FindFirstChild("Request") or Instance.new("RemoteFunction")
request.Name="Request"; request.Parent=remotes
local catalog=ReplicatedStorage:FindFirstChild("HalloweenCatalog") or Instance.new("Folder")
catalog.Name="HalloweenCatalog"; catalog.Parent=ReplicatedStorage
local placed=workspace:FindFirstChild("LobbyDecor") or Instance.new("Folder")
placed.Name="LobbyDecor"; placed.Parent=workspace

local catalogLoaded=false
local catalogLoading=false
local catalogStatus="Ainda nao carregado"

local function enforceSolo(joining)
	for _,other in ipairs(Players:GetPlayers()) do
		if other~=joining then joining:Kick("Servidor de construcao em modo solo."); return end
	end
end
Players.PlayerAdded:Connect(enforceSolo)
for _,p in ipairs(Players:GetPlayers()) do enforceSolo(p) end

local function authorized(p) return p.UserId==OWNER_USER_ID end

local function sanitize(inst)
	for _,d in ipairs(inst:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then d:Destroy()
		elseif d:IsA("BasePart") then d.Anchored=true; d.CanCollide=true end
	end
	if inst:IsA("BasePart") then inst.Anchored=true; inst.CanCollide=true end
end

local function containsPart(inst)
	return inst:IsA("BasePart") or inst:FindFirstChildWhichIsA("BasePart",true)~=nil
end

local function loadCatalog()
	if catalogLoaded then return true end
	if catalogLoading then return false end
	catalogLoading=true; catalogStatus="Carregando..."; catalog:ClearAllChildren()
	local ok,pack=pcall(function() return InsertService:LoadAsset(HALLOWEEN_ASSET_ID) end)
	if not ok or not pack then
		catalogLoading=false; catalogStatus="Falha ao carregar asset: "..tostring(pack); warn("[LobbyBuilder] "..catalogStatus); return false
	end
	local serial=0
	local function add(item)
		if not containsPart(item) then return end
		serial+=1
		local clone=item:Clone(); clone.Name=string.format("%03d_%s",serial,item.Name); sanitize(clone); clone.Parent=catalog
	end
	local function scan(container)
		for _,item in ipairs(container:GetChildren()) do
			if item:IsA("Folder") then scan(item)
			elseif item:IsA("Model") or item:IsA("Accessory") or item:IsA("BasePart") or containsPart(item) then add(item) end
		end
	end
	scan(pack); pack:Destroy()
	local count=#catalog:GetChildren()
	catalogLoaded=count>0; catalogLoading=false
	catalogStatus=catalogLoaded and (tostring(count).." itens carregados") or "Asset sem pecas 3D utilizaveis"
	return catalogLoaded
end

local function getParts(obj)
	local parts={}
	if obj:IsA("BasePart") then table.insert(parts,obj) end
	for _,d in ipairs(obj:GetDescendants()) do if d:IsA("BasePart") then table.insert(parts,d) end end
	return parts
end

local function worldBounds(obj)
	local parts=getParts(obj)
	if #parts==0 then return Vector3.zero,Vector3.zero end
	local minV=Vector3.new(math.huge,math.huge,math.huge)
	local maxV=Vector3.new(-math.huge,-math.huge,-math.huge)
	for _,p in ipairs(parts) do
		local cf=p.CFrame; local h=p.Size*.5
		local ax=cf.RightVector; local ay=cf.UpVector; local az=cf.LookVector
		local ex=math.abs(ax.X)*h.X+math.abs(ay.X)*h.Y+math.abs(az.X)*h.Z
		local ey=math.abs(ax.Y)*h.X+math.abs(ay.Y)*h.Y+math.abs(az.Y)*h.Z
		local ez=math.abs(ax.Z)*h.X+math.abs(ay.Z)*h.Y+math.abs(az.Z)*h.Z
		local e=Vector3.new(ex,ey,ez)
		minV=Vector3.new(math.min(minV.X,p.Position.X-e.X),math.min(minV.Y,p.Position.Y-e.Y),math.min(minV.Z,p.Position.Z-e.Z))
		maxV=Vector3.new(math.max(maxV.X,p.Position.X+e.X),math.max(maxV.Y,p.Position.Y+e.Y),math.max(maxV.Z,p.Position.Z+e.Z))
	end
	return minV,maxV
end

local function translate(obj,delta)
	for _,p in ipairs(getParts(obj)) do p.CFrame=p.CFrame+delta end
end

local function rotateAroundCenter(obj,yaw)
	if yaw==0 then return end
	local minV,maxV=worldBounds(obj); local center=(minV+maxV)*.5
	local rot=CFrame.Angles(0,math.rad(yaw),0)
	for _,p in ipairs(getParts(obj)) do
		local localCF=CFrame.new(center):ToObjectSpace(p.CFrame)
		p.CFrame=CFrame.new(center)*rot*localCF
	end
end

local function placeByVisualBounds(obj,base,yaw)
	rotateAroundCenter(obj,yaw)
	local minV,maxV=worldBounds(obj)
	local center=(minV+maxV)*.5
	translate(obj,Vector3.new(base.X-center.X,base.Y-minV.Y,base.Z-center.Z))
	minV,maxV=worldBounds(obj)
	local finalCenter=(minV+maxV)*.5
	return finalCenter,Vector3.new(finalCenter.X,maxV.Y,finalCenter.Z)
end


local saveQueued=false
local saving=false

local function snapshotBuild()
	local rows={}
	for _,obj in ipairs(placed:GetChildren()) do
		local minV,maxV=worldBounds(obj)
		local center=(minV+maxV)*.5
		table.insert(rows,{
			order=obj:GetAttribute("PlacedOrder") or 999999,
			name=obj:GetAttribute("AssetName") or obj.Name:gsub("^Decor_",""),
			x=center.X, y=minV.Y, z=center.Z,
			rotation=obj:GetAttribute("RotationY") or 0
		})
	end
	table.sort(rows,function(a,b) return a.order<b.order end)
	return {version=1,updated=os.time(),items=rows}
end

local function saveNow()
	if saving then saveQueued=true; return end
	saving=true
	local payload=snapshotBuild()
	local ok,err=pcall(function() BUILD_STORE:SetAsync(BUILD_KEY,payload) end)
	saving=false
	if not ok then warn("[LobbyBuilder] Falha ao salvar build: "..tostring(err)) end
	if saveQueued then saveQueued=false; task.defer(saveNow) end
end

local function restoreBuild()
	local ok,data=pcall(function() return BUILD_STORE:GetAsync(BUILD_KEY) end)
	if not ok then warn("[LobbyBuilder] Falha ao carregar build: "..tostring(data)); return end
	if type(data)~="table" or type(data.items)~="table" or #data.items==0 then return end
	if not loadCatalog() then warn("[LobbyBuilder] Build salvo existe, mas catalogo nao carregou"); return end
	placed:ClearAllChildren()
	for i,row in ipairs(data.items) do
		local template=catalog:FindFirstChild(row.name)
		if template and type(row.x)=="number" and type(row.y)=="number" and type(row.z)=="number" then
			local obj=template:Clone(); obj.Name="Decor_"..row.name
			obj:SetAttribute("PlacedBy",OWNER_USER_ID); obj:SetAttribute("AssetName",row.name)
			obj:SetAttribute("RotationY",row.rotation or 0); obj:SetAttribute("PlacedOrder",row.order or i)
			obj.Parent=placed
			local base=Vector3.new(row.x,row.y,row.z)
			placeByVisualBounds(obj,base,row.rotation or 0)
			obj:SetAttribute("BaseX",row.x); obj:SetAttribute("BaseY",row.y); obj:SetAttribute("BaseZ",row.z)
		end
	end
	print("[LobbyBuilder] Build persistente restaurado: "..#placed:GetChildren().." pecas")
end

task.spawn(restoreBuild)
game:BindToClose(function()
	if #placed:GetChildren()>0 then
		local payload=snapshotBuild()
		pcall(function() BUILD_STORE:SetAsync(BUILD_KEY,payload) end)
	end
end)

request.OnServerInvoke=function(player,action,data)
	if not authorized(player) then return {ok=false,error="Sem permissao"} end
	data=data or {}
	if action=="catalog" then
		loadCatalog()
		local items={}; for _,item in ipairs(catalog:GetChildren()) do table.insert(items,item.Name) end; table.sort(items)
		return {ok=catalogLoaded,items=items,status=catalogStatus}
	elseif action=="place" then
		local template=catalog:FindFirstChild(data.name)
		if not template then return {ok=false,error="Item invalido"} end
		local base=data.basePosition
		if typeof(base)~="Vector3" then return {ok=false,error="Posicao invalida"} end
		if math.abs(base.X)>62 or math.abs(base.Z)>62 or base.Y < -20 or base.Y > 60 then return {ok=false,error="Fora do lobby"} end
		local obj=template:Clone(); obj.Name="Decor_"..data.name
		obj:SetAttribute("PlacedBy",player.UserId)
		obj:SetAttribute("AssetName",data.name)
		obj:SetAttribute("RotationY",data.rotation or 0)
		obj:SetAttribute("PlacedOrder",#placed:GetChildren()+1)
		obj.Parent=placed
		local center,top=placeByVisualBounds(obj,base,data.rotation or 0)
		obj:SetAttribute("BaseX",base.X); obj:SetAttribute("BaseY",base.Y); obj:SetAttribute("BaseZ",base.Z)
		task.defer(saveNow)
		return {ok=true,center=center,top=top}
	elseif action=="export" then
		local rows={}
		for _,obj in ipairs(placed:GetChildren()) do
			local minV,maxV=worldBounds(obj)
			local center=(minV+maxV)*.5
			table.insert(rows,{
				order=obj:GetAttribute("PlacedOrder") or 999999,
				name=obj:GetAttribute("AssetName") or obj.Name:gsub("^Decor_",""),
				x=obj:GetAttribute("BaseX") or center.X,
				y=obj:GetAttribute("BaseY") or minV.Y,
				z=obj:GetAttribute("BaseZ") or center.Z,
				rotation=obj:GetAttribute("RotationY") or 0
			})
		end
		table.sort(rows,function(a,b) return a.order<b.order end)
		if #rows==0 then return {ok=false,error="Nenhuma peca colocada"} end
		local origin=Vector3.new(rows[1].x,rows[1].y,rows[1].z)
		local lines={"LOBBY_BUILD_V1",string.format("ORIGIN|%.3f|%.3f|%.3f",origin.X,origin.Y,origin.Z)}
		for i,row in ipairs(rows) do
			table.insert(lines,string.format("%03d|%s|ABS|%.3f|%.3f|%.3f|ROT|%.1f|REL|%.3f|%.3f|%.3f",
				i,row.name,row.x,row.y,row.z,row.rotation,row.x-origin.X,row.y-origin.Y,row.z-origin.Z))
		end
		return {ok=true,text=table.concat(lines,"\n"),count=#rows}
	elseif action=="deleteNearest" then
		local pos=data.position
		if typeof(pos)~="Vector3" then return {ok=false,error="Posicao invalida"} end
		local best,bestDist
		for _,obj in ipairs(placed:GetChildren()) do
			local minV,maxV=worldBounds(obj); local center=(minV+maxV)*.5; local d=(center-pos).Magnitude
			if not bestDist or d<bestDist then best,bestDist=obj,d end
		end
		if best and bestDist<=12 then best:Destroy(); task.defer(saveNow); return {ok=true} end
		return {ok=false,error="Nenhum item proximo"}
	end
	return {ok=false,error="Acao invalida"}
end
