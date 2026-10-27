-- Orders expand a bounded breadth-first front rooted at the selected border cell.
-- No coroutine per order. MatchService drives every active order in one batch.
local ExpansionService = {}
ExpansionService.__index = ExpansionService

function ExpansionService.new(nations, config, percentages)
    local allowed = {}
    for _, percentage in ipairs(percentages) do allowed[percentage] = true end
    return setmetatable({Nations = nations, Config = config, Allowed = allowed,
        _orders = {}, _pulse = 0}, ExpansionService)
end

function ExpansionService:Start(userId, targetId, percentage)
    local nation = self.Nations:GetState(userId)
    if not nation then return nil, "NoNation" end
    if type(percentage) ~= "number" or percentage ~= percentage or not self.Allowed[percentage] then
        return nil, "InvalidPercent"
    end
    if self._orders[userId] then return nil, "ExpansionBusy" end
    if not self.Nations.Map:IsValidLandCell(targetId) then return nil, "InvalidLand" end
    if self.Nations:GetOwner(targetId) ~= nil then return nil, "Occupied" end
    local tx, ty = self.Nations.Map.Grid:ToCoordinates(targetId)
    local startId, bestDistance
    if self.Nations:IsAdjacent(userId, targetId) then
        startId = targetId
    else
        for cellId in pairs(nation.Frontier) do
            for _, neighbor in ipairs(self.Nations.Map.Grid:GetNeighbors(cellId)) do
                if self.Nations:GetOwner(neighbor) == nil then
                    local x, y = self.Nations.Map.Grid:ToCoordinates(neighbor)
                    local distance = (x - tx)^2 + (y - ty)^2
                    if not bestDistance or distance < bestDistance then
                        startId, bestDistance = neighbor, distance
                    end
                end
            end
        end
    end
    if not startId then return nil, "NotAdjacent" end
    local sent = math.floor(nation.Troops * percentage / 100)
    if sent < self.Config.CostPerCell then return nil, "InsufficientTroops" end

    nation.Troops = nation.Troops - sent
    nation.ExpansionActive, nation.ExpansionRemaining, nation.ExpansionClaimed = true, sent, 0
    self._orders[userId] = {Queue = {startId}, Head = 1, Seen = {[startId] = true},
        Remaining = sent, Claimed = 0, TargetX = tx, TargetY = ty}
    return self.Nations:Publish({[userId] = true}, {}), "ExpansionStarted", sent
end

function ExpansionService:StartNaval(userId, targetId, percentage)
    local nation = self.Nations:GetState(userId)
    if not nation then return nil, "NoNation" end
    if type(percentage) ~= "number" or not self.Allowed[percentage] then return nil, "InvalidPercent" end
    if self._orders[userId] then return nil, "ExpansionBusy" end
    if not self.Nations.Map:IsValidLandCell(targetId) then return nil, "InvalidLand" end
    if self.Nations:GetOwner(targetId) ~= nil then return nil, "Occupied" end
    if self.Nations:IsAdjacent(userId, targetId) then return self:Start(userId, targetId, percentage) end
    local grid = self.Nations.Map.Grid
    if not grid:IsCoastal(targetId) then return nil, "NoSeaLane" end
    local tx, ty = grid:ToCoordinates(targetId)
    local best, bestDistance
    for cellId in pairs(nation.Cells) do
        if grid:IsCoastal(cellId) then
            local x, y = grid:ToCoordinates(cellId)
            local d = math.sqrt((x - tx)^2 + (y - ty)^2)
            local mx, my = math.floor((x + tx) / 2 + .5), math.floor((y + ty) / 2 + .5)
            local middle = grid:ToId(mx, my)
            if middle and not grid:IsLand(middle) and (not bestDistance or d < bestDistance) then
                best, bestDistance = cellId, d
            end
        end
    end
    if not best then return nil, "NoSeaLane" end
    local sent = math.floor(nation.Troops * percentage / 100)
    if sent < self.Config.CostPerCell then return nil, "InsufficientTroops" end
    nation.Troops = nation.Troops - sent
    local interval = 0.25
    local speed = math.max(0.1, self.Config.NavalCellsPerSecond or 12)
    local pulses = math.max(1, math.ceil((bestDistance / speed) / interval))
    nation.ExpansionActive, nation.ExpansionRemaining, nation.ExpansionClaimed = true, sent, 0
    nation.NavalActive, nation.NavalFrom, nation.NavalTo, nation.NavalProgress = true, best, targetId, 0
    self._orders[userId] = {Naval = true, From = best, Target = targetId, Remaining = sent,
        Claimed = 0, Pulses = pulses, Elapsed = 0}
    return self.Nations:Publish({[userId] = true}, {}), "NavalStarted", sent
end

function ExpansionService:_finish(userId, nation, order)
    -- Only unused escrow returns; generation never includes troops committed to an order.
    nation.Troops = math.min(nation.MaxTroops, nation.Troops + order.Remaining)
    nation.ExpansionActive, nation.ExpansionRemaining = false, 0
    nation.ExpansionClaimed = order.Claimed
    nation.NavalActive, nation.NavalFrom, nation.NavalTo, nation.NavalProgress = false, nil, nil, 0
    self._orders[userId] = nil
end

function ExpansionService:Step(changed, cells)
    self._pulse = self._pulse + 1
    local ids = {}
    for id in pairs(self._orders) do ids[#ids + 1] = id end
    table.sort(ids)
    -- Rotate priority each pulse so simultaneous frontiers do not always favor one ID.
    for index = 1, #ids do
        local userId = ids[(index + self._pulse - 2) % #ids + 1]
        local nation, order = self.Nations:GetState(userId), self._orders[userId]
        if not nation then
            self._orders[userId] = nil
        else
            if order.Naval then
                order.Elapsed = order.Elapsed + 1
                nation.NavalProgress = math.min(1, order.Elapsed / order.Pulses)
                nation.ExpansionRemaining = order.Remaining
                if order.Elapsed >= order.Pulses then
                    if self.Nations:ClaimRemoteNeutral(userId, order.Target) then
                        order.Remaining = math.max(0, order.Remaining - self.Config.CostPerCell)
                        order.Claimed = 1
                        cells[#cells + 1] = {Id = order.Target, OwnerId = userId}
                    end
                    self:_finish(userId, nation, order)
                end
                changed[userId] = true
                continue
            end
            local claimed, examined = 0, 0
            while order.Head <= #order.Queue and order.Remaining >= self.Config.CostPerCell
                and order.Claimed < self.Config.MaxCellsPerOrder
                and claimed < self.Config.CellsPerPulse and examined < self.Config.MaxCandidatesPerPulse do
                local cellId = order.Queue[order.Head]
                order.Head, examined = order.Head + 1, examined + 1
                -- Revalidate ownership and adjacency now: another order may have won.
                if self.Nations:ClaimNeutral(userId, cellId) then
                    order.Remaining = order.Remaining - self.Config.CostPerCell
                    order.Claimed, claimed = order.Claimed + 1, claimed + 1
                    cells[#cells + 1] = {Id = cellId, OwnerId = userId}
                    local candidates = {}
                    for _, neighbor in ipairs(self.Nations.Map.Grid:GetNeighbors(cellId)) do
                        if not order.Seen[neighbor] and self.Nations:GetOwner(neighbor) == nil then
                            order.Seen[neighbor] = true
                            local x, y = self.Nations.Map.Grid:ToCoordinates(neighbor)
                            local dx, dy = x - order.TargetX, y - order.TargetY
                            candidates[#candidates + 1] = {Id = neighbor, Score = dx * dx + dy * dy + math.random() * (self.Config.WaveLateralWeight or .55)}
                        end
                    end
                    table.sort(candidates, function(a, b) return a.Score < b.Score end)
                    for _, candidate in ipairs(candidates) do order.Queue[#order.Queue + 1] = candidate.Id end
                end
            end
            nation.ExpansionRemaining, nation.ExpansionClaimed = order.Remaining, order.Claimed
            if order.Head > #order.Queue or order.Remaining < self.Config.CostPerCell
                or order.Claimed >= self.Config.MaxCellsPerOrder then self:_finish(userId, nation, order) end
            changed[userId] = true
        end
    end
end

function ExpansionService:Forget(userId)
    -- Called when the nation is removed; escrow belongs to that ended session.
    self._orders[userId] = nil
end

return ExpansionService
