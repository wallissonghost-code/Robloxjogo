local DataStoreService = game:GetService("DataStoreService")

local STORE = DataStoreService:GetDataStore("PersistentWorldStateV1")
local WorldState = {}

local function key(worldId)
	return "world:" .. worldId
end

local function empty(worldId)
	return {
		version = 1,
		worldId = worldId,
		bases = {},
		updatedAt = os.time(),
	}
end

function WorldState.load(worldId)
	assert(type(worldId) == "string" and worldId ~= "", "WorldState.load requires worldId")
	local ok, data = pcall(function()
		return STORE:GetAsync(key(worldId))
	end)
	if not ok then
		return nil, "DataStore read failed"
	end
	if type(data) ~= "table" then
		data = empty(worldId)
	end
	data.version = tonumber(data.version) or 1
	data.worldId = worldId
	data.bases = type(data.bases) == "table" and data.bases or {}
	return data
end

function WorldState.update(worldId, transform)
	assert(type(worldId) == "string" and worldId ~= "", "WorldState.update requires worldId")
	assert(type(transform) == "function", "WorldState.update requires transform")
	local result
	local ok, err = pcall(function()
		result = STORE:UpdateAsync(key(worldId), function(current)
			current = type(current) == "table" and current or empty(worldId)
			current.version = tonumber(current.version) or 1
			current.worldId = worldId
			current.bases = type(current.bases) == "table" and current.bases or {}
			local nextState = transform(current) or current
			nextState.worldId = worldId
			nextState.updatedAt = os.time()
			return nextState
		end)
	end)
	if not ok then return nil, tostring(err) end
	return result
end

return WorldState
