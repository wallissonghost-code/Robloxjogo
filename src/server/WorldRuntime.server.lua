local WorldState = require(script.Parent.World.WorldState)

local worldId = game:GetAttribute("WorldId")
if type(worldId) ~= "string" or worldId == "" then
	return
end

local state, err = WorldState.load(worldId)
if not state then
	warn("Persistent world state unavailable:", worldId, err)
	return
end

game:SetAttribute("PersistentWorldId", worldId)
game:SetAttribute("PersistentWorldVersion", state.version)
game:SetAttribute("PersistentBaseCount", #state.bases)

-- BuildingService will consume state.bases in the next construction phase.
-- Keeping loading here makes world persistence independent from any player being online.
