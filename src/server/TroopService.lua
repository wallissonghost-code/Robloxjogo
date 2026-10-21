local TroopService = {}

local Config

function TroopService.Init(config)
    Config = config
end

function TroopService.SetupPlayer(player)
    player:SetAttribute("Troops", Config.Player.StartingTroops)
    player:SetAttribute("MaxTroops", Config.Player.BaseTroopCapacity)
    player:SetAttribute("TerritoryCells", 0)
end

function TroopService.Get(player)
    return player:GetAttribute("Troops") or 0
end

function TroopService.GetCapacity(player)
    return player:GetAttribute("MaxTroops") or Config.Player.BaseTroopCapacity
end

function TroopService.Spend(player, amount)
    amount = math.max(0, math.floor(amount))
    local current = TroopService.Get(player)
    if amount > current then return false end
    player:SetAttribute("Troops", current - amount)
    return true
end

function TroopService.Start()
    task.spawn(function()
        while true do
            task.wait(Config.Player.RegenInterval)
            for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
                local current = TroopService.Get(player)
                local capacity = TroopService.GetCapacity(player)
                if current < capacity then
                    player:SetAttribute("Troops", math.min(capacity, current + Config.Player.TroopsPerTick))
                end
            end
        end
    end)
end

return TroopService
