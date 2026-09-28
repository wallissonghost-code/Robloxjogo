local WorldState = require(script.Parent.World.WorldState)

local function waitForWorldId()
	local id = game:GetAttribute("WorldId")
	while type(id) ~= "string" or id == "" do
		game:GetAttributeChangedSignal("WorldId"):Wait()
		id = game:GetAttribute("WorldId")
	end
	return id
end

local worldId = waitForWorldId()
local state, err = WorldState.load(worldId)
if not state then
	warn("Persistent world state unavailable:", worldId, err)
	return
end

game:SetAttribute("PersistentWorldId", worldId)
game:SetAttribute("PersistentWorldVersion", state.version)
game:SetAttribute("PersistentBaseCount", #state.bases)
