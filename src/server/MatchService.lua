-- Mundial War · round life cycle:
-- waiting → vote (choose the game mode) → spawn → playing → ended → vote …
local MatchService = {}

local ctx, Config
local phase, phaseEnds, round, winner = "waiting", 0, 0, nil
local votes = {}          -- userId -> mode

function MatchService.init(context)
	ctx = context
	Config = ctx.Config
	ctx.mode = ctx.mode or Config.ModeOrder[1]
end

function MatchService.phase()
	return phase
end

function MatchService.round()
	return round
end

function MatchService.winner()
	return winner
end

function MatchService.mode()
	return ctx.mode
end

function MatchService.isPlaying()
	return phase == "playing"
end

function MatchService.canSpawn()
	return phase == "spawn" or (phase == "playing" and Config.Match.AllowRespawn)
end

function MatchService.timeLeft()
	return math.max(0, phaseEnds - ctx.now())
end

local function tally()
	local counts = {}
	for _, m in ipairs(Config.ModeOrder) do counts[m] = 0 end
	for _, m in pairs(votes) do counts[m] = (counts[m] or 0) + 1 end
	return counts
end

function MatchService.publicView()
	return { phase = phase, round = round, left = MatchService.timeLeft(), winner = winner, mode = ctx.mode, votes = tally() }
end

local function announce()
	local view = MatchService.publicView()
	view.k = ctx.Protocol.Events.Match
	ctx.emit(nil, view)
end

local function resetWorld()
	ctx.Territory.reset()
	ctx.Nations.reset()
	ctx.Buildings.reset()
	ctx.Expansion.reset()
	ctx.Naval.reset()
	ctx.Strategic.reset()
	ctx.Diplomacy.reset()
	ctx.Combat.reset()
	ctx.Bots.reset()
end

-- Places the AI for the chosen mode and opens the spawn phase.
local function startSpawn()
	phase = "spawn"
	phaseEnds = ctx.now() + Config.Match.SpawnPhaseSeconds
	if ctx.mode == "extreme" then
		ctx.Bots.spawnCountries()
	else
		ctx.Bots.spawnAll()
	end
	ctx.fullResync = true
	announce()
end

function MatchService.beginRound()
	resetWorld()
	round = round + 1
	winner = nil
	votes = {}
	if (Config.Match.VoteSeconds or 0) <= 0 then
		startSpawn()
		return
	end
	phase = "vote"
	phaseEnds = ctx.now() + Config.Match.VoteSeconds
	ctx.fullResync = true
	announce()
end

function MatchService.vote(userId, mode)
	if phase ~= "vote" then return false, "A votação já terminou." end
	if not Config.Modes[mode] then return false, "Modo inválido." end
	votes[userId] = mode
	announce()
	return true, "Voto registrado: " .. Config.Modes[mode].name .. "."
end

local function closeVote()
	local counts = tally()
	local best, bestCount = Config.ModeOrder[1], -1
	for _, m in ipairs(Config.ModeOrder) do
		if counts[m] > bestCount then best, bestCount = m, counts[m] end
	end
	ctx.mode = best
	startSpawn()
end

-- Tests and tools: choose the mode directly.
function MatchService.setMode(mode)
	assert(Config.Modes[mode], "unknown mode " .. tostring(mode))
	ctx.mode = mode
	if phase == "vote" then
		votes = {}
		closeVote()
	end
end

function MatchService.toWaiting()
	resetWorld()
	phase = "waiting"
	winner = nil
	votes = {}
	ctx.fullResync = true
	announce()
end

-- Place connected players who did not confirm a capital before the timer expires.
local function autoPlace()
	if not ctx.connectedPlayers then return end
	local map = ctx.Map
	for _, player in ipairs(ctx.connectedPlayers()) do
		if not ctx.Nations.forUser(player.userId) and ctx.Nations.canRespawn(player.userId) then
			local placed = false
			local name = string.sub(player.name or "Jogador", 1, 24)
			if ctx.mode == "extreme" then
				local candidates = {}
				for _, n in pairs(ctx.Nations.all()) do
					if n.alive and n.kind == "bot" then candidates[#candidates + 1] = n.capital end
				end
				while #candidates > 0 and not placed do
					local index = math.random(1, #candidates)
					placed = ctx.Nations.takeover(player.userId, name, table.remove(candidates, index)) ~= nil
				end
			else
				local start = math.random(1, map.N)
				for offset = 0, map.N - 1 do
					local cell = (start + offset - 1) % map.N + 1
					if ctx.Nations.canSpawnAt(cell) then
						placed = ctx.Nations.create("player", name, cell, { userId = player.userId }) ~= nil
						if placed then break end
					end
				end
			end
			if not placed then
				ctx.notify(nil, "Não há espaço livre para o nascimento automático de " .. name .. ".", "info")
			end
		end
	end
end

-- Skips the rest of the vote/spawn phases (tests, and the preview's "start now" button).
function MatchService.startPlaying()
	if phase == "vote" then closeVote() end
	if phase == "spawn" then
		autoPlace()
		phase = "playing"
		phaseEnds = 0
		announce()
	end
end

function MatchService.tick(humanCount)
	local now = ctx.now()
	if phase == "waiting" then
		if humanCount > 0 then MatchService.beginRound() end
		return
	end
	if humanCount == 0 and ctx.realPlayers then
		MatchService.toWaiting()
		return
	end
	if phase == "vote" then
		local voted = 0
		for _ in pairs(votes) do voted = voted + 1 end
		if now >= phaseEnds or (humanCount > 0 and voted >= humanCount) then closeVote() end
	elseif phase == "spawn" then
		if now >= phaseEnds then MatchService.startPlaying() end
	elseif phase == "playing" then
		ctx.Nations.checkEliminations()
		local landCount = ctx.Map.landCount
		for _, n in pairs(ctx.Nations.all()) do
			if n.alive and n.land / landCount >= Config.Match.VictoryPercent then
				winner = { id = n.id, name = n.name, share = n.land / landCount }
				phase = "ended"
				phaseEnds = now + Config.Match.EndScreenSeconds
				ctx.Expansion.reset()
				announce()
				return
			end
		end
	elseif phase == "ended" then
		if now >= phaseEnds then MatchService.beginRound() end
	end
end

return MatchService
