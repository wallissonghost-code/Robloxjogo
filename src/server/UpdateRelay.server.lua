local MessagingService=game:GetService("MessagingService")
local TeleportService=game:GetService("TeleportService")
local Players=game:GetService("Players")

local TOPIC="Robloxjogo_Update_v1"
local BUILD="2026-09-29-update-relay-1"
local restarting=false

local function reconnectAll()
	if restarting then return end
	restarting=true
	task.wait(2)
	local list=Players:GetPlayers()
	if #list==0 then return end
	local options=Instance.new("TeleportOptions")
	options.ShouldReserveServer=false
	local ok,err=pcall(function()
		TeleportService:TeleportAsync(game.PlaceId,list,options)
	end)
	if not ok then warn("[UpdateRelay] reconnect failed",err); restarting=false end
end

local ok,err=pcall(function()
	MessagingService:SubscribeAsync(TOPIC,function(message)
		local incoming=tostring(message.Data or "")
		if incoming~="" and incoming~=BUILD then reconnectAll() end
	end)
end)
if not ok then warn("[UpdateRelay] subscribe failed",err) end
print("[UpdateRelay] ready",BUILD)
