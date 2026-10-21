local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NationReplica = require(script.Parent.NationReplica)
local NationClient = {}
NationClient.__index = NationClient

local messages = {
    Founded = "Capital fundada! Seu território está marcado com uma estrela.",
    AlreadyFounded = "Você já possui uma capital nesta partida.",
    InvalidLand = "Escolha uma célula de terra. Água não pode ser ocupada.",
    Occupied = "Essa célula acabou de ser ocupada. Escolha outra.",
    InvalidIdentity = "Não foi possível identificar o jogador. Entre novamente.",
}

function NationClient.new(view, grid, config, status, hint, action)
    local self = setmetatable({View = view, Grid = grid, Config = config,
        Status = status, Hint = hint, Action = action, Replica = NationReplica.new(grid),
        UserId = Players.LocalPlayer.UserId, Running = true, Synced = false,
        RequestId = 0, Connections = {}}, NationClient)
    self:Refresh()
    local remote = ReplicatedStorage:WaitForChild("NationProtocol", 30)
    if not remote then
        self.Notice = "Conexão indisponível. Entre novamente."
        self:Refresh()
        return self
    end
    self.Remote = remote
    self.Connections[#self.Connections + 1] = remote.OnClientEvent:Connect(function(packet)
        if not self.Running then return end
        if packet.Kind == "Result" then
            if packet.RequestId ~= self.Pending then return end
            self.Pending = nil
            self.Notice = messages[packet.Code] or "Não foi possível fundar a capital."
        else
            local hadNation = self.Replica.Nations[self.UserId] ~= nil
            local dirty, reason = self.Replica:Apply(packet)
            if reason == "Resync" then self:RequestSync(); return end
            if dirty then
                if packet.Kind == "Snapshot" then self.Synced = true end
                view:ApplyNationState(self.Replica, dirty)
                local nation = self.Replica.Nations[self.UserId]
                if nation and not hadNation then
                    self.SelectedId = nation.CapitalId
                    view:SetSelection(nation.CapitalId)
                    view:FocusCell(nation.CapitalId)
                end
            end
        end
        self:Refresh()
    end)
    self.Connections[#self.Connections + 1] = action.Activated:Connect(function()
        if not self.Synced or self.Pending then return end
        local nation = self.Replica.Nations[self.UserId]
        if nation then view:FocusCell(nation.CapitalId); return end
        local id = self.SelectedId
        if not grid:IsLand(id) or self.Replica.Owners[id] ~= nil then return end
        self.RequestId = self.RequestId + 1
        self.Pending = self.RequestId
        self.Notice = nil
        self:Refresh()
        remote:FireServer("ChooseCapital", id, self.Pending)
        local sent = self.Pending
        task.delay(8, function()
            if not self.Running or self.Pending ~= sent then return end
            self.Pending = nil
            self.Notice = "A resposta demorou. Verificando o estado no servidor…"
            self:RequestSync()
        end)
    end)
    self:RequestSync()
    return self
end

function NationClient:RequestSync()
    self.Synced = false
    self:Refresh()
    if self.RetryScheduled or not self.Remote then return end
    self.RetryScheduled = true
    local function retry()
        if not self.Running or self.Synced then self.RetryScheduled = false; return end
        self.Remote:FireServer("Sync")
        task.delay(3, retry)
    end
    retry()
end

function NationClient:Inspect(cellId)
    if self.Pending then return end
    self.SelectedId, self.Notice = cellId, nil
    self.View:SetSelection(cellId)
    self:Refresh()
end

function NationClient:Refresh()
    local nation = self.Replica.Nations[self.UserId]
    local count = 0
    for _ in pairs(self.Replica.Nations) do count = count + 1 end
    self.Status.Text = self.Config.Version .. " • " .. count .. " nações"
    if nation then
        self.Status.Text = self.Status.Text .. string.format(" • %d célula(s) • %.2f%% do mundo",
            nation.TerritoryCount, nation.TerritoryCount / self.Grid.LandCount * 100)
    end
    local enabled = false
    local hint = "Toque em terra livre e confirme sua capital."
    if not self.Synced then
        self.Action.Text = "Sincronizando…"
    elseif self.Pending then
        self.Action.Text = "Fundando…"
    elseif nation then
        self.Action.Text, enabled = "Minha capital", true
        hint = "Capital fundada • Expansão chega na próxima etapa."
    elseif self.SelectedId and self.Grid:IsLand(self.SelectedId)
        and self.Replica.Owners[self.SelectedId] == nil then
        self.Action.Text, enabled = "Fundar capital aqui", true
    else
        self.Action.Text = "Selecione terra livre"
    end
    if self.SelectedId then
        local owner = self.Replica.Owners[self.SelectedId]
        local selectedNation = owner ~= nil and self.Replica.Nations[owner]
        local x, y = self.Grid:ToCoordinates(self.SelectedId)
        if selectedNation then
            hint = string.format("%s • %d célula(s) • %s", selectedNation.Name,
                selectedNation.TerritoryCount, owner == self.UserId and "Seu território" or "Outra nação")
        elseif not self.Grid:IsLand(self.SelectedId) then
            hint = "Água: escolha terra para fundar sua capital."
        elseif x then
            hint = string.format("Terra livre (%d, %d) • %s", x, y,
                nation and "Expansão ainda indisponível" or "Confirme no botão abaixo")
        end
    end
    self.Hint.Text = self.Notice or hint
    self.Action.Active = enabled
    self.Action.AutoButtonColor = enabled
    self.Action.BackgroundColor3 = enabled and Color3.fromRGB(38, 112, 97) or Color3.fromRGB(44, 55, 64)
end

function NationClient:Destroy()
    self.Running = false
    for _, connection in ipairs(self.Connections) do connection:Disconnect() end
end

return NationClient
