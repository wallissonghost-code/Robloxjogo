local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local GOLD_PER_SECOND = 1
local SAVE_INTERVAL = 30
local GoldStore = DataStoreService:GetDataStore("PlayerGold_v1")

local sessions = {}

local function keyFor(player)
	return "user_" .. player.UserId
end

local function savePlayer(player)
	local session = sessions[player]
	if not session then return end

	local ok, err = pcall(function()
		GoldStore:UpdateAsync(keyFor(player), function(old)
			old = tonumber(old) or 0
			return math.max(old, session.gold)
		end)
	end)

	if not ok then
		warn("[Gold] Falha ao salvar " .. player.Name .. ": " .. tostring(err))
	end
end

local function setupPlayer(player)
	local loadedGold = 0
	local ok, data = pcall(function()
		return GoldStore:GetAsync(keyFor(player))
	end)
	if ok and type(data) == "number" then
		loadedGold = math.max(0, math.floor(data))
	elseif not ok then
		warn("[Gold] Falha ao carregar " .. player.Name .. ": " .. tostring(data))
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local gold = Instance.new("IntValue")
	gold.Name = "Ouro"
	gold.Value = loadedGold
	gold.Parent = leaderstats

	sessions[player] = {gold = loadedGold, value = gold}

	task.spawn(function()
		while player.Parent == Players and sessions[player] do
			task.wait(1)
			local session = sessions[player]
			if session and player.Parent == Players then
				session.gold += GOLD_PER_SECOND
				session.value.Value = session.gold
			end
		end
	end)

	task.spawn(function()
		while player.Parent == Players and sessions[player] do
			task.wait(SAVE_INTERVAL)
			if player.Parent == Players and sessions[player] then
				savePlayer(player)
			end
		end
	end)
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
	savePlayer(player)
	sessions[player] = nil
end)

game:BindToClose(function()
	for player in pairs(sessions) do
		savePlayer(player)
	end
end)
