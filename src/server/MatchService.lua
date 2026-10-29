-- Mundial War · round life cycle:
-- waiting → vote (choose the game mode) → spawn → playing → ended → vote …
local MatchService = {}

local ctx, Config
local phase, phaseEnds, round, winner = "waiting", 0, 0, nil
local votes = {}          -- userId -> mode
local lastPartySync = -1
local roundStarted = nil
local finalResults = nil
local endReason = nil

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

function MatchService.publicView(includeResults)
	return {
		phase = phase, round = round, left = MatchService.timeLeft(),
		winner = winner, mode = ctx.mode, votes = tally(),
		endedBy = endReason,
		elapsed = roundStarted and math.max(0, ctx.now() - roundStarted) or 0,
		duration = Config.Match.MaxDurationSeconds or 0,
		results = includeResults ~= false and finalResults or nil,
	}
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
	finalResults, endReason, roundStarted = nil, nil, nil
	lastPartySync = -1
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
	finalResults, endReason, roundStarted = nil, nil, nil
	lastPartySync = -1
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
		roundStarted = ctx.now()
		local limit = Config.Match.MaxDurationSeconds or 0
		phaseEnds = limit > 0 and roundStarted + limit or 0
		announce()
	end
end

-- Each living nation scores on its own unless it has a valid two-player Party
-- identifier supplied by the server's lobby teleport. Independent alliances
-- do not combine score and cannot bypass the victory requirement.
local function buildStandings()
	local groups = {}
	local totalLand = math.max(1, ctx.Map.landCount)
	for _, nation in pairs(ctx.Nations.all()) do
		if nation.alive and nation.land > 0 then
			local partyId = nation.userId and ctx.partyOfUser and ctx.partyOfUser[nation.userId]
			local key = partyId and ("party:" .. partyId) or ("nation:" .. nation.id)
			local group = groups[key]
			if not group then
				group = { id = nation.id, name = nation.name, land = 0, troops = 0, captured = 0,
					claimed = 0, members = {}, isParty = false, key = key }
				groups[key] = group
			end
			group.land = group.land + math.max(0, nation.land)
			group.troops = group.troops + math.max(0, math.floor(nation.troops or 0))
			group.captured = group.captured + (nation.captured or 0)
			group.claimed = group.claimed + (nation.claimed or 0)
			group.members[#group.members + 1] = {
				id = nation.id, userId = nation.userId, name = nation.name,
				kind = nation.kind, land = nation.land,
				troops = math.floor(nation.troops or 0),
				captured = nation.captured or 0, claimed = nation.claimed or 0,
				peakLand = nation.peakLand or nation.land,
			}
		end
	end
	local list = {}
	for _, group in pairs(groups) do
		table.sort(group.members, function(a, b) return a.id < b.id end)
		group.id = group.members[1].id
		if #group.members > 1 then
			group.isParty = true
			local names = {}
			for _, member in ipairs(group.members) do names[#names + 1] = member.name end
			group.name = table.concat(names, " + ")
		end
		group.share = group.land / totalLand
		list[#list + 1] = group
	end
	table.sort(list, function(a, b)
		if a.land ~= b.land then return a.land > b.land end
		if a.troops ~= b.troops then return a.troops > b.troops end
		return a.id < b.id
	end)
	for index, group in ipairs(list) do group.rank = index end
	return list
end

local function finishMatch(reason, ranked)
	if phase ~= "playing" then return end
	ranked = ranked or buildStandings()
	local best = ranked[1]
	winner = best and {
		id = best.id, name = best.name, share = best.share, land = best.land,
		isParty = best.isParty, ids = {},
	} or nil
	if winner then
		for _, member in ipairs(best.members) do winner.ids[#winner.ids + 1] = member.id end
	end
	endReason = reason
	finalResults = {
		reason = reason, standings = ranked,
		duration = roundStarted and math.max(0, ctx.now() - roundStarted) or 0,
		landCount = ctx.Map.landCount,
	}
	phase = "ended"
	phaseEnds = ctx.now() + Config.Match.EndScreenSeconds
	ctx.Expansion.reset()
	announce()
end

function MatchService.tick(humanCount)
	local now = ctx.now()
	-- Party members can choose their capitals independently, but remain allies
	-- as soon as both nations exist. Check occasionally, never on every frame.
	if ctx.partyOfUser and (phase == "spawn" or phase == "playing") and now - lastPartySync >= 1 then
		lastPartySync = now
		local first = {}
		for userId, partyId in pairs(ctx.partyOfUser) do
			local nation = ctx.Nations.forUser(userId)
			if nation and nation.alive then
				if first[partyId] then
					ctx.Diplomacy.syncParty(first[partyId], nation.id)
				else
					first[partyId] = nation.id
				end
			end
		end
	end
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
		-- Sort by combined territory so teammates may reach the 80% threshold
		-- together. At the time limit, the largest team/nation wins.
		local ranked = buildStandings()
		if ranked[1] and ranked[1].share >= Config.Match.VictoryPercent then
			finishMatch("territory", ranked)
		elseif (Config.Match.MaxDurationSeconds or 0) > 0 and now >= phaseEnds then
			finishMatch("timeout", ranked)
		end
	elseif phase == "ended" then
		-- Dedicated matchmaking sessions stay on the results screen until
		-- players choose to return to the lobby. No forced next round.
		if not ctx.lobbyMatch and now >= phaseEnds then MatchService.beginRound() end
	end
end

return MatchService
