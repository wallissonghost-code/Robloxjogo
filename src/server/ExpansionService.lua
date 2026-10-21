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
    if not self.Nations:IsAdjacent(userId, targetId) then return nil, "NotAdjacent" end
    local sent = math.floor(nation.Troops * percentage / 100)
    if sent < self.Config.CostPerCell then return nil, "InsufficientTroops" end

    nation.Troops = nation.Troops - sent
    nation.ExpansionActive, nation.ExpansionRemaining, nation.ExpansionClaimed = true, sent, 0
    self._orders[userId] = {Queue = {targetId}, Head = 1, Seen = {[targetId] = true},
        Remaining = sent, Claimed = 0}
    return self.Nations:Publish({[userId] = true}, {}), "ExpansionStarted", sent
end

function ExpansionService:_finish(userId, nation, order)
    -- Only unused escrow returns; generation never includes troops committed to an order.
    nation.Troops = math.min(nation.MaxTroops, nation.Troops + order.Remaining)
    nation.ExpansionActive, nation.ExpansionRemaining = false, 0
    nation.ExpansionClaimed = order.Claimed
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
                    for _, neighbor in ipairs(self.Nations.Map.Grid:GetNeighbors(cellId)) do
                        if not order.Seen[neighbor] and self.Nations:GetOwner(neighbor) == nil then
                            order.Seen[neighbor] = true
                            order.Queue[#order.Queue + 1] = neighbor
                        end
                    end
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
