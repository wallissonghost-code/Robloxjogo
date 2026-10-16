local ReplicatedStorage=game:GetService("ReplicatedStorage")
local InsertService=game:GetService("InsertService")
local Players=game:GetService("Players")
local OWNER_USER_ID=9538436641
local HALLOWEEN_ASSET_ID=113280926555931
local remotes=ReplicatedStorage:FindFirstChild("LobbyBuilderRemotes") or Instance.new("Folder"); remotes.Name="LobbyBuilderRemotes"; remotes.Parent=ReplicatedStorage
local request=remotes:FindFirstChild("Request") or Instance.new("RemoteFunction"); request.Name="Request"; request.Parent=remotes
local catalog=ReplicatedStorage:FindFirstChild("HalloweenCatalog") or Instance.new("Folder"); catalog.Name="HalloweenCatalog"; catalog.Parent=ReplicatedStorage
local placed=workspace:FindFirstChild("LobbyDecor") or Instance.new("Folder"); placed.Name="LobbyDecor"; placed.Parent=workspace
local catalogLoaded=false
local catalogLoading=false
local catalogStatus="Ainda nao carregado"

local function enforceSolo(joiningPlayer)
	for _,other in ipairs(Players:GetPlayers()) do
		if other ~= joiningPlayer then
			joiningPlayer:Kick("Servidor de construcao em modo solo.")
			return
		end
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
local function containsPart(inst) return inst:IsA("BasePart") or inst:FindFirstChildWhichIsA("BasePart",true)~=nil end
local function loadCatalog()
	if catalogLoaded then return true end
	if catalogLoading then return false end
	catalogLoading=true; catalogStatus="Carregando..."; catalog:ClearAllChildren()
	local ok,pack=pcall(function() return InsertService:LoadAsset(HALLOWEEN_ASSET_ID) end)
	if not ok or not pack then catalogStatus="Falha ao carregar asset: "..tostring(pack); catalogLoading=false; warn("[LobbyBuilder] "..catalogStatus); return false end
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
	local count=#catalog:GetChildren(); catalogLoaded=count>0; catalogLoading=false
	catalogStatus=catalogLoaded and (tostring(count).." itens carregados") or "Asset sem pecas 3D utilizaveis"
	return catalogLoaded
end
local function pivotTo(obj,cf)
	if obj:IsA("Model") then obj:PivotTo(cf)
	elseif obj:IsA("BasePart") then obj.CFrame=cf
	else
		local p=obj:FindFirstChildWhichIsA("BasePart",true)
		if p then
			local delta=cf*p.CFrame:Inverse()
			for _,d in ipairs(obj:GetDescendants()) do if d:IsA("BasePart") then d.CFrame=delta*d.CFrame end end
		end
	end
end
local function bounds(obj)
	if obj:IsA("Model") then return obj:GetBoundingBox() end
	if obj:IsA("BasePart") then return obj.CFrame,obj.Size end
	local parts={}
	for _,d in ipairs(obj:GetDescendants()) do if d:IsA("BasePart") then table.insert(parts,d) end end
	if #parts==0 then return CFrame.new(),Vector3.zero end
	local minV=Vector3.new(math.huge,math.huge,math.huge); local maxV=Vector3.new(-math.huge,-math.huge,-math.huge)
	for _,p in ipairs(parts) do
		local h=p.Size*.5
		minV=Vector3.new(math.min(minV.X,p.Position.X-h.X),math.min(minV.Y,p.Position.Y-h.Y),math.min(minV.Z,p.Position.Z-h.Z))
		maxV=Vector3.new(math.max(maxV.X,p.Position.X+h.X),math.max(maxV.Y,p.Position.Y+h.Y),math.max(maxV.Z,p.Position.Z+h.Z))
	end
	return CFrame.new((minV+maxV)*.5),maxV-minV
end
local function placeBaseAt(obj,base,yaw)
	pivotTo(obj,CFrame.new(base)*CFrame.Angles(0,math.rad(yaw),0))
	local boxCF,boxSize=bounds(obj)
	local dy=base.Y-(boxCF.Position.Y-boxSize.Y*.5)
	if math.abs(dy)>.001 then
		local current
		if obj:IsA("Model") then current=obj:GetPivot()
		elseif obj:IsA("BasePart") then current=obj.CFrame
		else local p=obj:FindFirstChildWhichIsA("BasePart",true); current=p and p.CFrame end
		if current then pivotTo(obj,current+Vector3.new(0,dy,0)) end
	end
end

request.OnServerInvoke=function(player,action,data)
	if not authorized(player) then return {ok=false,error="Sem permissao"} end
	data=data or {}
	if action=="catalog" then
		loadCatalog(); local items={}; for _,item in ipairs(catalog:GetChildren()) do table.insert(items,item.Name) end; table.sort(items)
		return {ok=catalogLoaded,items=items,status=catalogStatus}
	elseif action=="place" then
		local template=catalog:FindFirstChild(data.name); if not template then return {ok=false,error="Item invalido"} end
		local base=data.basePosition
		if typeof(base)~="Vector3" then return {ok=false,error="Posicao invalida"} end
		if math.abs(base.X)>62 or math.abs(base.Z)>62 or base.Y < -20 or base.Y > 60 then return {ok=false,error="Fora do lobby"} end
		local obj=template:Clone(); obj.Name="Decor_"..data.name; obj:SetAttribute("PlacedBy",player.UserId); obj.Parent=placed
		placeBaseAt(obj,base,data.rotation or 0)
		local placedCF,placedSize=bounds(obj)
		local top=Vector3.new(placedCF.Position.X,placedCF.Position.Y+placedSize.Y*.5,placedCF.Position.Z)
		return {ok=true,center=placedCF.Position,top=top}
	elseif action=="deleteNearest" then
		local p=data.position; if typeof(p)~="Vector3" then return {ok=false,error="Posicao invalida"} end
		local best,dist
		for _,obj in ipairs(placed:GetChildren()) do
			local cf=select(1,bounds(obj)); local d=(cf.Position-p).Magnitude
			if not dist or d<dist then best,dist=obj,d end
		end
		if best and dist<=12 then best:Destroy(); return {ok=true} end
		return {ok=false,error="Nenhum item proximo"}
	end
	return {ok=false,error="Acao invalida"}
end
