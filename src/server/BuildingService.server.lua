local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local HttpService=game:GetService("HttpService")
local Workspace=game:GetService("Workspace")

local World=script.Parent.World
local WorldState=require(World.WorldState)
local Catalog=require(ReplicatedStorage.Building.PieceCatalog)
local Validator=require(script.Parent.Building.PlacementValidator)
local Resolver=require(script.Parent.Building.SocketResolver)
local Factory=require(script.Parent.Building.PieceFactory)

local function waitForWorldId()
	local id=game:GetAttribute("WorldId")
	while type(id)~="string" or id=="" do game:GetAttributeChangedSignal("WorldId"):Wait();id=game:GetAttribute("WorldId") end
	return id
end

local worldId=waitForWorldId()
local builds=Workspace:FindFirstChild("PersistentBuilds") or Instance.new("Folder")
builds.Name="PersistentBuilds";builds.Parent=Workspace
local remotes=ReplicatedStorage:FindFirstChild("BuildingRemotes") or Instance.new("Folder")
remotes.Name="BuildingRemotes";remotes.Parent=ReplicatedStorage
local place=Instance.new("RemoteFunction");place.Name="PlacePiece";place.Parent=remotes
local resolve=Instance.new("RemoteFunction");resolve.Name="ResolvePlacement";resolve.Parent=remotes

local state,loadError=WorldState.load(worldId)
if not state then warn("Building state unavailable:",loadError);state={bases={}} end
local function baseFor(current,userId,create)
	local id="base:"..tostring(userId)
	for _,b in ipairs(current.bases or {}) do if b.id==id then return Resolver.withLegacySockets(b) end end
	if create then
		local b={id=id,ownerUserId=userId,pieces={},createdAt=os.time(),lastActive=os.time()}
		table.insert(current.bases,b);return b
	end
end
for _,base in ipairs(state.bases or {}) do
	Resolver.withLegacySockets(base)
	for _,piece in ipairs(base.pieces or {}) do local d=Catalog[piece.type];if d then Factory.create(piece,d,builds) end end
end

resolve.OnServerInvoke=function(player,pieceType,rawPosition)
	if not Catalog[pieceType] or typeof(rawPosition)~="Vector3" then return {ok=false} end
	local base=baseFor(state,player.UserId,false) or {pieces={}}
	local r,msg=Resolver.resolve(base,pieceType,rawPosition)
	if not r then return {ok=false,message=msg} end
	local ok,reason=Validator.validate(player,Catalog[pieceType],r)
	if not ok then return {ok=false,message=reason} end
	return {ok=true,position=r.position,rotation=r.rotation,socketKey=r.socketKey}
end

local lastRequest={}
place.OnServerInvoke=function(player,pieceType,rawPosition)
	local now=os.clock();if now-(lastRequest[player] or 0)<.12 then return {ok=false,message="Muito rápido."} end
	lastRequest[player]=now
	local definition=Catalog[pieceType]
	if not definition or typeof(rawPosition)~="Vector3" then return {ok=false,message="Peça ou posição inválida."} end

	local live,err=WorldState.load(worldId)
	if not live then return {ok=false,message="Estado do mundo indisponível."} end
	local base=baseFor(live,player.UserId,false) or {pieces={}}
	local resolved,msg=Resolver.resolve(base,pieceType,rawPosition)
	if not resolved then return {ok=false,message=msg} end
	local valid,reason=Validator.validate(player,definition,resolved)
	if not valid then return {ok=false,message=reason} end

	local record={
		id=HttpService:GenerateGUID(false),baseId="base:"..tostring(player.UserId),ownerUserId=player.UserId,
		type=pieceType,x=resolved.position.X,y=resolved.position.Y,z=resolved.position.Z,
		rotation=resolved.rotation,socketKey=resolved.socketKey,foundationHeight=resolved.foundationHeight,schemaVersion=resolved.schemaVersion,createdAt=os.time()
	}
	local saved,saveErr=WorldState.update(worldId,function(current)
		local b=baseFor(current,player.UserId,true)
		local check,why=Resolver.resolve(b,pieceType,rawPosition)
		if not check or check.socketKey~=record.socketKey then return current end
		record.x,record.y,record.z=check.position.X,check.position.Y,check.position.Z
		record.rotation=check.rotation
		record.foundationHeight=check.foundationHeight
		record.schemaVersion=check.schemaVersion
		b.lastActive=os.time();table.insert(b.pieces,record);return current
	end)
	if not saved then return {ok=false,message="Falha ao salvar: "..tostring(saveErr)} end

	local confirmed=false
	local savedBase=baseFor(saved,player.UserId,false)
	for _,p in ipairs(savedBase and savedBase.pieces or {}) do if p.id==record.id then confirmed=true break end end
	if not confirmed then return {ok=false,message="Encaixe já foi ocupado."} end

	state=saved
	Factory.create(record,definition,builds)
	game:SetAttribute("PersistentBaseCount",#(saved.bases or {}))
	return {ok=true}
end
Players.PlayerRemoving:Connect(function(player) lastRequest[player]=nil end)
