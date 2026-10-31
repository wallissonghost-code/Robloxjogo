-- Visible battle roles: own attack and incoming threats to the player or allies.
local ClientState = dofile("src/client/ClientState.lua")
local state = ClientState.new({ N = 1, land = { true } }, {}, { DefaultTroopPercent = 0.75 }, {}, {})
local ok = function(cond, msg) if not cond then error("ASSERT: " .. msg, 2) end end

state.you = 1
state.relations["1:2"] = "ally"
ok(state:shouldShowOrder(1, 3), "our attacks are visible")
ok(state:shouldShowOrder(1, 0), "our neutral expansion remains visible")
ok(state:shouldShowOrder(3, 1), "attacks against us are visible")
ok(state:shouldShowOrder(3, 2), "attacks against direct allies are visible")
ok(not state:shouldShowOrder(2, 3), "outgoing ally attacks stay hidden")
ok(not state:shouldShowOrder(3, 4), "unrelated wars stay hidden")
ok(not state:shouldShowOrder(3, 0), "unrelated neutral expansion stays hidden")
state.relations["1:2"] = nil
ok(not state:shouldShowOrder(3, 2), "ending the alliance hides former allies' incoming attacks")
state.you = nil
ok(not state:shouldShowOrder(3, 1), "spectators without a nation see no battle labels")
print("PASS player-and-allies-only combat indicators")
