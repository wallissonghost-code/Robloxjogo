-- Transport-independent command gateway. userId/name MUST come from Player.
local CommandService = {}
CommandService.__index = CommandService

function CommandService.new(nations, config, clock, expansion)
    return setmetatable({Nations = nations, Config = config,
        Clock = clock or os.clock, Expansion = expansion, _limits = {}}, CommandService)
end

function CommandService:Handle(userId, displayName, action, cellId, requestId, percentage)
    local now = self.Clock()
    local limit = self._limits[userId]
    if not limit then
        limit = {Tokens = self.Config.Burst, Updated = now, LastSync = -math.huge}
        self._limits[userId] = limit
    end
    limit.Tokens = math.min(self.Config.Burst,
        limit.Tokens + math.max(0, now - limit.Updated) * self.Config.RefillPerSecond)
    limit.Updated = now
    -- Drop excess traffic before inspecting payloads or producing responses.
    if limit.Tokens < 1 then return nil end
    limit.Tokens = limit.Tokens - 1

    if action == "Sync" then
        if now - limit.LastSync < self.Config.SyncInterval then return nil end
        limit.LastSync = now
        return self.Nations:Snapshot()
    end
    if action ~= "ChooseCapital" and action ~= "Expand" then return nil end
    if type(requestId) ~= "number" or requestId ~= requestId
        or requestId < 1 or requestId > 1e9 or requestId % 1 ~= 0 then return nil end
    if requestId <= (limit.LastRequestId or 0) then
        return {Kind = "Result", RequestId = requestId, Code = "DuplicateRequest"}
    end
    limit.LastRequestId = requestId
    local delta, code, sent
    if action == "ChooseCapital" then delta, code = self.Nations:Create(userId, displayName, cellId)
    elseif self.Expansion then delta, code, sent = self.Expansion:Start(userId, cellId, percentage)
    else code = "Unavailable" end
    return {Kind = "Result", RequestId = requestId, Code = code, Sent = sent or 0}, delta
end

function CommandService:Forget(userId)
    self._limits[userId] = nil
end

return CommandService
