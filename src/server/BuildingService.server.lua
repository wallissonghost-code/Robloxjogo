local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local World = script.Parent.World
local WorldState = require(World.WorldState)
local Catalog = require(ReplicatedStorage.Building.PieceCatalog)
local Validator = require(script.Parent.Building.PlacementValidator)
local Factory = require(script.Parent.Building.PieceFactory)

local function waitForWorldId()
	local id = game:GetAttribute("WorldId")
	while type(id) ~= "string" or id == "" do
		game:GetAttributeChangedSignal("WorldId"):Wait()
		id = game:GetAttribute("WorldId")
	end
	return id
end

local worldId = waitForWorldId()
local builds = Workspace:FindFirstChild("PersistentBuilds") or Instance.new("Folder")
builds.Name = "PersistentBuilds"
builds.Parent = Workspace

local remotes = ReplicatedStorage:FindFirstChild("BuildingRemotes") or Instance.new("Folder")
remotes.Name = "BuildingRemotes"
remotes.Parent = ReplicatedStorage
local place = Instance.new("RemoteFunction")
place.Name = "PlacePiece"
place.Parent = remotes

local state, loadError = WorldState.load(worldId)
if not state then
	warn("Building state unavailable:", loadError)
	state = { bases = {} }
end

local function allPieces(current)
	local pieces = {}
	for _, base in ipairs(current.bases or {}) do
		for _, piece in ipairs(base.pieces or {}) do table.insert(pieces, piece) end
	end
	return pieces
end

for _, piece in ipairs(allPieces(state)) do
	local definition = Catalog[piece.type]
	if definition then Factory.create(piece, definition, builds) end
end

local lastRequest = {}
place.OnServerInvoke = function(player, pieceType, rawPosition, rotation)
	local now = os.clock()
	if now - (lastRequest[player] or 0) < .12 then return { ok=false, message="Muito rápido." } end
	lastRequest[player] = now

	local definition = Catalog[pieceType]
	if not definition then return { ok=false, message="Peça inválida." } end
	if typeof(rawPosition) ~= "Vector3" then return { ok=false, message="Posição inválida." } end

	rotation = math.floor((tonumber(rotation) or 0) / 90 + .5) * 90 % 360
	local grid = 2
	local x = math.floor(rawPosition.X / grid + .5) * grid
	local z = math.floor(rawPosition.Z / grid + .5) * grid

	local rayOrigin = Vector3.new(x, rawPosition.Y + 30, z)
	local ray = Workspace:Raycast(rayOrigin, Vector3.new(0,-80,0))
	if not ray or ray.Material == Enum.Material.Water then return { ok=false, message="Terreno inválido." } end
	local y = ray.Position.Y + definition.offsetY
	if pieceType == "Wall" or pieceType == "Door" then y = ray.Position.Y + definition.offsetY end
	local position = Vector3.new(x,y,z)

	local valid, reason = Validator.validate(player, definition, position, rotation)
	if not valid then return { ok=false, message=reason } end

	local baseId = "base:" .. tostring(player.UserId)
	local record = {
		id = HttpService:GenerateGUID(false),
		baseId = baseId,
		ownerUserId = player.UserId,
		type = pieceType,
		x = position.X, y = position.Y, z = position.Z,
		rotation = rotation,
		createdAt = os.time(),
	}

	local saved, err = WorldState.update(worldId, function(current)
		local base
		for _, candidate in ipairs(current.bases) do
			if candidate.id == baseId then base = candidate break end
		end
		if not base then
			base = { id=baseId, ownerUserId=player.UserId, pieces={}, createdAt=os.time(), lastActive=os.time() }
			table.insert(current.bases, base)
		end
		base.lastActive = os.time()
		table.insert(base.pieces, record)
		return current
	end)
	if not saved then return { ok=false, message="Falha ao salvar construção: "..tostring(err) } end

	Factory.create(record, definition, builds)
	game:SetAttribute("PersistentBaseCount", #(saved.bases or {}))
	return { ok=true }
end

Players.PlayerRemoving:Connect(function(player) lastRequest[player]=nil end)
