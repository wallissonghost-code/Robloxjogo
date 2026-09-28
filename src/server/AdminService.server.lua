local Players = game:GetService("Players")

local function isAuthorized(player)
	-- Private by default: only the owner of a user-owned experience.
	return game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId
end

local function configure(player)
	player:SetAttribute("IsGameAdmin", isAuthorized(player))
end

Players.PlayerAdded:Connect(configure)
for _, player in ipairs(Players:GetPlayers()) do
	configure(player)
end
