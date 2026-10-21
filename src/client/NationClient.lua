local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NationReplica = require(script.Parent.NationReplica)
local NationClient = {}
NationClient.__index = NationClient

local messages = {
    Founded = "Capital fundada! Selecione terra junto à sua fronteira para expandir.",
    AlreadyFounded = "Você já possui uma capital nesta partida.",
    InvalidLand = "Escolha uma célula de terra. Água não pode ser ocupada.",
    Occupied = "Essa célula já foi ocupada. Escolha terra livre.",
    InvalidIdentity = "Não foi possível identificar o jogador. Entre novamente.",
    InvalidPercent = "Escolha 10, 25, 35, 50 ou 75%.",
    InsufficientTroops = "Tropas insuficientes para esse envio. Aguarde a geração.",
    NotAdjacent = "Selecione terra livre encostada na sua fronteira.",
    ExpansionBusy = "Sua expansão já está em andamento.",
    NoNation = "Funde sua capital primeiro.",
    DuplicateRequest = "Este comando já foi processado.",
    Unavailable = "Esta ação ainda não está disponível.",
}

function NationClient.new(view, grid, config, status, hint, action, hud)
    local self = setmetatable({View = view, Grid = grid, Config = config,
        Status = status, Hint = hint, Action = action, Hud = hud, Replica = NationReplica.new(grid),
        UserId = Players.LocalPlayer.UserId, Running = true, Synced = false,
        Percent = config.DefaultSendPercent, RequestId = 0, Connections = {}}, NationClient)
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
            self.Notice = packet.Code == "ExpansionStarted"
                and string.format("Envio confirmado pelo servidor: %d tropas.", packet.Sent)
                or messages[packet.Code] or "Não foi possível executar a ação."
        else
            local prior = self.Replica.Nations[self.UserId]
            local dirty, reason = self.Replica:Apply(packet)
            if reason == "Resync" then self:RequestSync(); return end
            if dirty then
                if packet.Kind == "Snapshot" then self.Synced = true end
                view:ApplyNationState(self.Replica, dirty)
                local nation = self.Replica.Nations[self.UserId]
                if nation and not prior then
                    self.SelectedId = nation.CapitalId
                    view:SetSelection(nation.CapitalId)
                    view:FocusCell(nation.CapitalId)
                elseif prior and prior.ExpansionActive and nation and not nation.ExpansionActive then
                    self.Notice = string.format("Expansão concluída: %d células. Sobra devolvida.", nation.ExpansionClaimed)
                elseif nation and nation.ExpansionActive and not self.Pending then
                    self.Notice = nil
                end
            end
        end
        self:Refresh()
    end)
    self.Connections[#self.Connections + 1] = action.Activated:Connect(function()
        local intent = self:GetIntent()
        if not intent then return end
        local nation = self.Replica.Nations[self.UserId]
        if intent == "Focus" then view:FocusCell(nation.CapitalId); return end
        self.RequestId = self.RequestId + 1
        self.Pending = self.RequestId
        self.Notice = nil
        self:Refresh()
        remote:FireServer(intent, self.SelectedId, self.Pending, self.Percent)
        local sent = self.Pending
        task.delay(8, function()
            if not self.Running or self.Pending ~= sent then return end
            self.Pending = nil
            self.Notice = "A resposta demorou. Verificando o estado no servidor…"
            self:RequestSync()
        end)
    end)
    if hud then
        for percentage, item in pairs(hud.Percentages) do
            self.Connections[#self.Connections + 1] = item.Activated:Connect(function() self:SelectPercent(percentage) end)
        end
    end
    self:RequestSync()
    return self
end

function NationClient:SelectPercent(percentage)
    if self.Pending then return end
    for _, allowed in ipairs(self.Config.SendPercentages) do
        if percentage == allowed then self.Percent = percentage; self.Notice = nil; self:Refresh(); return end
    end
end

function NationClient:GetIntent()
    if not self.Synced then return nil, "Sync" end
    if self.Pending then return nil, "Pending" end
    local nation, id = self.Replica.Nations[self.UserId], self.SelectedId
    if not nation then
        if self.Grid:IsLand(id) and self.Replica.Owners[id] == nil then return "ChooseCapital" end
        return nil, "SelectLand"
    end
    if nation.ExpansionActive then return nil, "ExpansionBusy" end
    if not id or self.Replica.Owners[id] == self.UserId then return "Focus" end
    if not self.Grid:IsLand(id) then return nil, "InvalidLand" end
    if self.Replica.Owners[id] ~= nil then return nil, "Enemy" end
    local adjacent = false
    for _, other in ipairs(self.Grid:GetNeighbors(id)) do
        if self.Replica.Owners[other] == self.UserId then adjacent = true; break end
    end
    if not adjacent then return nil, "NotAdjacent" end
    if math.floor(nation.Troops * self.Percent / 100) < self.Config.Expansion.CostPerCell then
        return nil, "InsufficientTroops"
    end
    return "Expand"
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
        self.Status.Text = self.Status.Text .. string.format(" • %d células • %.2f%% do mundo",
            nation.TerritoryCount, nation.TerritoryCount / self.Grid.LandCount * 100)
    end
    local intent, reason = self:GetIntent()
    local texts = {Focus = "Minha capital", ChooseCapital = "Fundar capital aqui", Expand = "Expandir", Sync = "Sincronizando…",
        Pending = "Enviando…", SelectLand = "Selecione terra livre", ExpansionBusy = "Expandindo…",
        InvalidLand = "Escolha terra", Enemy = "Combate na próxima etapa", NotAdjacent = "Escolha sua fronteira",
        InsufficientTroops = "Aguarde mais tropas"}
    self.Action.Text = texts[intent or reason] or "Selecione uma célula"
    local hint = nation and "Toque em terra livre na sua fronteira e escolha o envio." or "Toque em terra livre e confirme sua capital."
    if self.SelectedId then
        local owner = self.Replica.Owners[self.SelectedId]
        local selectedNation = owner ~= nil and self.Replica.Nations[owner]
        if selectedNation then
            hint = string.format("%s • %d tropas • %d células", selectedNation.Name, selectedNation.Troops, selectedNation.TerritoryCount)
        elseif reason == "NotAdjacent" or reason == "InvalidLand" or reason == "InsufficientTroops" then
            hint = messages[reason]
        elseif intent == "Expand" then
            local sent = math.floor(nation.Troops * self.Percent / 100)
            hint = string.format("Até %d células • %d tropas/célula • sobra retorna",
                math.min(self.Config.Expansion.MaxCellsPerOrder, math.floor(sent / self.Config.Expansion.CostPerCell)), self.Config.Expansion.CostPerCell)
        elseif intent == "ChooseCapital" then
            hint = "Terra livre • Confirme a capital no botão abaixo"
        end
    end
    self.Hint.Text = self.Notice or hint
    self.Action.Active = intent ~= nil
    self.Action.AutoButtonColor = intent ~= nil
    self.Action.BackgroundColor3 = intent and Color3.fromRGB(38, 112, 97) or Color3.fromRGB(44, 55, 64)
    if self.Hud then self.Hud:UpdateEconomy(nation, self.Percent) end
end

function NationClient:Destroy()
    self.Running = false
    for _, connection in ipairs(self.Connections) do connection:Disconnect() end
end

return NationClient
