-- Lobby-only service. Public servers host the menu; reserved servers host matches.
-- Uses the current PlaceId for both routes: no extra published place is required.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local HttpService = game:GetService("HttpService")

local LobbyService = {}
local REMOTE_FOLDER = "MW_LobbyRemotes"
local ROOM_MAP = "MW_PublicMatchRooms_v2"
local ROOM_LIFETIME = 180
local INVITE_LIFETIME = 30

local function newRemote(folder, name)
    local r = Instance.new("RemoteEvent")
    r.Name = name
    r.Parent = folder
    return r
end

function LobbyService.start(config)
    local folder = Instance.new("Folder")
    folder.Name = REMOTE_FOLDER
    folder.Parent = ReplicatedStorage
    local command = newRemote(folder, "Command")
    local event = newRemote(folder, "Event")
    local rooms = MemoryStoreService:GetSortedMap(ROOM_MAP)
    local parties = {} -- leader userId -> {leader, members, mode, private}
    local membership = {} -- userId -> leader userId
    local invites = {} -- target userId -> {from, expires}
    local busy = {}
    local lastInvite = {}

    local function send(player, payload)
        if player and player.Parent == Players then
            event:FireClient(player, payload)
        end
    end

    local function groupFor(player)
        local leader = membership[player.UserId]
        return leader and parties[leader] or nil
    end

    local function makeSolo(player)
        local id = player.UserId
        parties[id] = {leader = id, members = {[id] = true}, mode = config.ModeOrder[1], private = false}
        membership[id] = id
    end

    local function roster()
        local entries = {}
        for _, player in ipairs(Players:GetPlayers()) do
            entries[#entries + 1] = {userId = player.UserId, name = player.DisplayName}
        end
        table.sort(entries, function(a, b) return a.name < b.name end)
        return entries
    end

    local function syncPlayer(player, list)
        local party = groupFor(player)
        if not party then makeSolo(player); party = groupFor(player) end
        local members = {}
        for id in pairs(party.members) do
            local member = Players:GetPlayerByUserId(id)
            if member then
                members[#members + 1] = {userId = id, name = member.DisplayName}
            end
        end
        table.sort(members, function(a, b)
            if a.userId == party.leader then return true end
            if b.userId == party.leader then return false end
            return a.userId < b.userId
        end)
        send(player, {
            kind = "State",
            players = list,
            members = members,
            leader = party.leader,
            mode = party.mode,
            private = party.private,
            maxPlayers = config.Match.MaxPlayers,
        })
    end

    local function syncAll()
        local list = roster()
        for _, player in ipairs(Players:GetPlayers()) do syncPlayer(player, list) end
    end

    local function message(player, text, good)
        send(player, {kind = "Notice", text = text, good = good == true})
    end

    local function playGroup(leader)
        local party = groupFor(leader)
        if not party or party.leader ~= leader.UserId then return end
        local team = {}
        for id in pairs(party.members) do
            local player = Players:GetPlayerByUserId(id)
            if player and player.Parent == Players and not busy[id] then
                team[#team + 1] = player
            end
        end
        if #team == 0 then return end
        for _, player in ipairs(team) do busy[player.UserId] = true end
        for _, player in ipairs(team) do
            send(player, {kind = "Starting", text = "Procurando partida " .. (party.private and "privada" or "pública") .. "..."})
        end

        task.spawn(function()
            local mode = party.mode
            local private = party.private
            local roomId, reservedId, created = nil, nil, false
            local nonce = HttpService:GenerateGUID(false)
            if not private then
                -- Reserve slots atomically so two lobby servers do not overfill a room.
                local ok, list = pcall(function()
                    return rooms:GetRangeAsync(Enum.SortDirection.Descending, 30)
                end)
                if ok and list then
                    for _, entry in ipairs(list) do
                        local value = entry.value
                        if type(value) == "table" and value.mode == mode
                            and type(value.reservedId) == "string" and value.reservedId ~= ""
                            and (value.slots or 0) + #team <= config.Match.MaxPlayers
                            and os.time() - (value.createdAt or 0) < ROOM_LIFETIME - 25 then
                            local updatedOk, updated = pcall(function()
                                return rooms:UpdateAsync(entry.key, function(current, sortKey)
                                    if type(current) ~= "table" or current.mode ~= mode
                                        or (current.slots or 0) + #team > config.Match.MaxPlayers
                                        or os.time() - (current.createdAt or 0) >= ROOM_LIFETIME - 25 then
                                        return nil
                                    end
                                    current.slots = current.slots + #team
                                    current.nonce = nonce
                                    return current, sortKey
                                end, ROOM_LIFETIME)
                            end)
                            if updatedOk and updated and updated.nonce == nonce then
                                roomId, reservedId = entry.key, updated.reservedId
                                break
                            end
                        end
                    end
                end
            end

            -- Current Roblox API: GUID-based reserved server IDs; no deprecated
            -- ReserveServer() call or extra place is required.
            if not reservedId then
                reservedId = HttpService:GenerateGUID(false)
                if not private then
                    roomId = HttpService:GenerateGUID(false)
                    local stored = pcall(function()
                        rooms:SetAsync(roomId, {
                            reservedId = reservedId, mode = mode, slots = #team,
                            createdAt = os.time(), nonce = nonce,
                        }, ROOM_LIFETIME, os.time())
                    end)
                    created = stored
                end
            end

            local teleported, teleportError = false, nil
            if reservedId then
                local options = Instance.new("TeleportOptions")
                options.ReservedServerId = reservedId
                local partyIds = {}
                for _, player in ipairs(team) do partyIds[#partyIds + 1] = player.UserId end
                options:SetTeleportData({
                    mwSession = "match", mode = mode, roomId = roomId,
                    partyId = #partyIds > 1 and ("party_" .. leader.UserId .. "_" .. nonce) or nil,
                    partyUserIds = #partyIds > 1 and partyIds or nil,
                })
                teleported, teleportError = pcall(function()
                    TeleportService:TeleportAsync(game.PlaceId, team, options)
                end)
            end
            if not teleported then
                if created and roomId then
                    pcall(function() rooms:RemoveAsync(roomId) end)
                elseif roomId then
                    pcall(function()
                        rooms:UpdateAsync(roomId, function(value, sortKey)
                            if not value then return nil end
                            value.slots = math.max(0, (value.slots or #team) - #team)
                            return value, sortKey
                        end, ROOM_LIFETIME)
                    end)
                end
                warn("[MundialWar] matchmaking/teleport failed: " .. tostring(teleportError))
                for _, player in ipairs(team) do
                    message(player, "Não foi possível entrar na partida. Tente novamente.", false)
                    send(player, {kind = "Starting", text = ""})
                end
            end
            for _, player in ipairs(team) do busy[player.UserId] = nil end
        end)
    end

    command.OnServerEvent:Connect(function(player, action, data)
        if type(action) ~= "string" or busy[player.UserId] then return end
        local group = groupFor(player)
        if not group then return end
        if action == "Sync" then
            syncPlayer(player, roster())
        elseif action == "Mode" then
            if group.leader == player.UserId and type(data) == "string" and config.Modes[data] then
                group.mode = data
                syncAll()
            end
        elseif action == "Privacy" then
            if group.leader == player.UserId and type(data) == "boolean" then
                group.private = data
                syncAll()
            end
        elseif action == "Invite" then
            if group.leader ~= player.UserId or type(data) ~= "number" or data == player.UserId then return end
            if (lastInvite[player.UserId] or 0) + 2 > os.clock() then return end
            lastInvite[player.UserId] = os.clock()
            local target = Players:GetPlayerByUserId(data)
            local targetGroup = target and groupFor(target)
            local count, targetCount = 0, 0
            for _ in pairs(group.members) do count = count + 1 end
            if targetGroup then
                for _ in pairs(targetGroup.members) do targetCount = targetCount + 1 end
            end
            if not target or not targetGroup or count >= 2
                or targetGroup.leader ~= target.UserId or targetCount ~= 1 then
                message(player, "Convite indisponível. O Party permite até 2 jogadores.", false)
                return
            end
            invites[data] = {from = player.UserId, expires = os.clock() + INVITE_LIFETIME}
            send(target, {kind = "Invite", from = player.UserId, name = player.DisplayName})
            message(player, "Convite enviado para " .. target.DisplayName .. ".", true)
        elseif action == "Accept" then
            local invite = invites[player.UserId]
            invites[player.UserId] = nil
            if not invite or invite.expires < os.clock() then return end
            local host = Players:GetPlayerByUserId(invite.from)
            local destination = host and groupFor(host)
            if not destination or destination.leader ~= invite.from or group.leader ~= player.UserId then return end
            local count = 0
            for _ in pairs(destination.members) do count = count + 1 end
            if count >= 2 then return end
            parties[player.UserId] = nil
            destination.members[player.UserId] = true
            membership[player.UserId] = invite.from
            syncAll()
            message(host, player.DisplayName .. " entrou no Party!", true)
        elseif action == "Decline" then
            invites[player.UserId] = nil
        elseif action == "Leave" then
            if group.leader == player.UserId then
                -- Disband the old party safely, preserving each player's ability to play.
                parties[group.leader] = nil
                for id in pairs(group.members) do
                    local member = Players:GetPlayerByUserId(id)
                    if member then makeSolo(member) end
                end
            else
                group.members[player.UserId] = nil
                makeSolo(player)
            end
            syncAll()
        elseif action == "Play" then
            if group.leader == player.UserId then playGroup(player) end
        end
    end)

    Players.PlayerAdded:Connect(function(player)
        makeSolo(player)
        syncAll()
    end)
    Players.PlayerRemoving:Connect(function(player)
        invites[player.UserId] = nil
        lastInvite[player.UserId] = nil
        local group = groupFor(player)
        if group then
            if group.leader == player.UserId then
                parties[group.leader] = nil
                for id in pairs(group.members) do
                    if id ~= player.UserId then
                        local member = Players:GetPlayerByUserId(id)
                        if member then makeSolo(member) end
                    end
                end
            else
                group.members[player.UserId] = nil
            end
        end
        membership[player.UserId] = nil
        busy[player.UserId] = nil
        task.defer(syncAll)
    end)

    for _, player in ipairs(Players:GetPlayers()) do makeSolo(player) end
    syncAll()
    print("[MundialWar] Lobby ativo: salas públicas, privadas e Party de 2 jogadores.")
end

return LobbyService
