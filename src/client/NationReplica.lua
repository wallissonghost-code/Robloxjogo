-- Read-only projection of authoritative server messages; never predicts ownership.
local NationReplica = {}
NationReplica.__index = NationReplica

function NationReplica.new(grid)
    return setmetatable({Grid = grid, Revision = -1, Ready = false,
        Nations = {}, Owners = {}}, NationReplica)
end

function NationReplica:Apply(packet)
    if packet.Kind ~= "Snapshot" and packet.Kind ~= "Delta" then return nil, "Ignored" end
    if packet.Revision < self.Revision then return nil, "Stale" end
    if packet.Kind == "Delta" then
        if not self.Ready then return nil, "Resync" end
        if packet.Revision == self.Revision then return nil, "Stale" end
        if packet.Revision ~= self.Revision + 1 then return nil, "Resync" end
    end
    local dirty = {}
    if packet.Kind == "Snapshot" then
        for cellId in pairs(self.Owners) do dirty[self.Grid:GetChunkId(cellId)] = true end
        self.Nations, self.Owners = {}, {}
    end
    for _, nation in ipairs(packet.Nations) do self.Nations[nation.Id] = nation end
    for _, id in ipairs(packet.RemovedNations or {}) do self.Nations[id] = nil end
    for _, change in ipairs(packet.Cells) do
        if change.OwnerId == false then self.Owners[change.Id] = nil
        else self.Owners[change.Id] = change.OwnerId end
        dirty[self.Grid:GetChunkId(change.Id)] = true
    end
    self.Revision, self.Ready = packet.Revision, true
    return dirty, "Applied"
end

return NationReplica
