// Runs the real Mundial War server rules (Lua) in a Web Worker. Prefers Lua 5.4 compiled to
// WebAssembly (near-native speed); falls back to the pure-JS Lua VM if WebAssembly is unavailable.
self.window = self;
/*__WASMOON__*/
/*__FENGARI__*/
const SOURCES = /*__LUA__*/;
const WASM_B64 = "/*__WASM__*/";

function fail(msg) { postMessage({ t: "error", error: String(msg) }); }

async function wasmEngine() {
  if (typeof WebAssembly !== "object" || !self.wasmoon) throw new Error("no WebAssembly");
  const bin = atob(WASM_B64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  const realFetch = self.fetch ? self.fetch.bind(self) : null;
  // serve the embedded binary instead of downloading it (the page cannot fetch other hosts)
  self.fetch = (url, opts) => String(url).endsWith("mw-glue.wasm")
    ? Promise.resolve(new Response(bytes, { headers: { "Content-Type": "application/wasm" } }))
    : realFetch(url, opts);
  const factory = new self.wasmoon.LuaFactory("mw-glue.wasm");
  const lua = await factory.createEngine({ openStandardLibs: true, injectObjects: false, enableProxy: false });
  return {
    name: "wasm",
    load(name, src) { lua.global.set("__src", src); lua.doStringSync(`chunk_${name} = assert(load(__src, "@${name}"))`); },
    run(code) { lua.doStringSync(code); },
    call(name, ...args) { const fn = lua.global.get(name); return fn(...args.map((a) => a === null ? undefined : a)); },
  };
}

function jsEngine() {
  const { lua, lauxlib, lualib, to_luastring } = self.fengari;
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  return {
    name: "js",
    load(name, src) {
      if (lauxlib.luaL_loadbuffer(L, to_luastring(src), null, to_luastring("@" + name)) !== 0) throw new Error(lua.lua_tojsstring(L, -1));
      lua.lua_setglobal(L, to_luastring("chunk_" + name));
    },
    run(code) { if (lauxlib.luaL_dostring(L, to_luastring(code)) !== 0) throw new Error(lua.lua_tojsstring(L, -1)); },
    call(name, ...args) {
      lua.lua_getglobal(L, to_luastring(name));
      for (const a of args) {
        if (a === null || a === undefined) lua.lua_pushnil(L);
        else if (typeof a === "number") lua.lua_pushnumber(L, a);
        else lua.lua_pushstring(L, to_luastring(String(a)));
      }
      if (lua.lua_pcall(L, args.length, 1, 0) !== 0) { const err = lua.lua_tojsstring(L, -1); lua.lua_pop(L, 1); throw new Error(err); }
      const s = lua.lua_tojsstring(L, -1);
      lua.lua_pop(L, 1);
      return s;
    },
  };
}

const BOOT = `
local S = {}
for _, n in ipairs({"TerritoryService","NationService","EconomyService","CombatService","BuildingService","ExpansionService","FrontlineService","NavalService","StrategicService","DiplomacyService","BotService","MatchService","CommandService"}) do S[n] = _G["chunk_" .. n]() end
local World = chunk_World()
local Config, Palette = chunk_GameConfig(), chunk_Palette()
local Stats = chunk_BuildingStats()
-- single-player preview: the mode menu waits for the player instead of a 15 s countdown
Config.Match.VoteSeconds = 1e9
math.randomseed(os.time())
world = World.new({ Config = Config, Palette = Palette, Protocol = chunk_Protocol(), MapGrid = chunk_MapGrid(), MapData = chunk_MapData(), BuildingStats = Stats, random = math.random,
  Services = { Territory = S.TerritoryService, Nations = S.NationService, Economy = S.EconomyService, Combat = S.CombatService,
    Buildings = S.BuildingService, Expansion = S.ExpansionService, Frontline = S.FrontlineService, Naval = S.NavalService, Strategic = S.StrategicService,
    Diplomacy = S.DiplomacyService, Bots = S.BotService, Match = S.MatchService, Commands = S.CommandService } })
ctx = world.ctx
local USER = 1

local function esc(s)
  return (s:gsub('[%c"\\\\]', function(c)
    if c == '"' then return '\\\\"' elseif c == '\\\\' then return '\\\\\\\\' end
    return string.format("\\\\u%04x", string.byte(c))
  end))
end
function json(v)
  local t = type(v)
  if t == "nil" then return "null"
  elseif t == "boolean" then return v and "true" or "false"
  elseif t == "number" then
    if v ~= v or v == math.huge or v == -math.huge then return "0" end
    if math.floor(v) == v and math.abs(v) < 1e15 then return string.format("%d", math.floor(v)) end
    return string.format("%.6g", v)
  elseif t == "string" then return '"' .. esc(v) .. '"'
  elseif t == "table" then
    local n, count = #v, 0
    for k, x in pairs(v) do if type(x) ~= "function" then count = count + 1 end end
    local parts = {}
    if n > 0 and count == n then
      for i = 1, n do parts[i] = json(v[i]) end
      return "[" .. table.concat(parts, ",") .. "]"
    end
    if count == 0 then return "[]" end
    for k, x in pairs(v) do
      if type(x) ~= "function" then parts[#parts + 1] = '"' .. esc(tostring(k)) .. '":' .. json(x) end
    end
    return "{" .. table.concat(parts, ",") .. "}"
  end
  return "null"
end

function boot()
  world:step(0.1, 1)
  ctx.fullResync = false
  world:drainOutbox()
  world:deltaPayload()
  local C = ctx.Config
  -- per-level texts, reach and upgrade costs so the page can explain every building
  local info = {}
  for kind in pairs(C.Buildings) do
    local lines, reach, upgrade = {}, {}, {}
    for level = 1, C.MaxBuildingLevel do
      lines[level] = table.concat(Stats.lines(C, kind, level), " · ")
      reach[level] = Stats.reach(C, kind, level) or 0
      upgrade[level] = Stats.upgradeCost(C, kind, level) or 0
    end
    info[kind] = { lines = lines, reach = reach, upgrade = upgrade }
  end
  return json({ init = world:initPayload(USER), palette = Palette,
    config = { Buildings = C.Buildings, BuildingOrder = C.BuildingOrder, BuildingInfo = info, MaxBuildingLevel = C.MaxBuildingLevel,
      Weapons = C.Weapons, WeaponOrder = C.WeaponOrder, TroopPercents = C.TroopPercents, Modes = C.Modes, ModeOrder = C.ModeOrder,
      DefaultTroopPercent = C.DefaultTroopPercent, VictoryPercent = C.Match.VictoryPercent,
      View = C.View, Naval = C.Naval, SpawnPhaseSeconds = C.Match.SpawnPhaseSeconds } })
end

local frameNo = 0
function frame()
  local t0 = os.clock()
  world:step(0.2, 1)
  frameNo = frameNo + 1
  local me = ctx.Nations.forUser(USER)
  local events = {}
  for _, item in ipairs(world:drainOutbox()) do
    if item.to == nil or (me and item.to == me.id) then events[#events + 1] = item.payload end
  end
  local res = { events = events }
  if ctx.fullResync then
    ctx.fullResync = false
    world:deltaPayload()
    res.init = world:initPayload(USER)
  end
  res.delta = world:deltaPayload()
  if frameNo % 5 == 0 then res.nations = world:nationsPayload() end
  if frameNo % 2 == 0 then res.orders = world:ordersPayload() end
  res.me = world:privatePayload(USER)
  res.cpu = os.clock() - t0
  return json(res)
end

function cmd(action, a, b, c)
  if action == "sync" then return json({ init = world:initPayload(USER) }) end
  if action == "__skip" then ctx.Match.startPlaying() return json({ ok = true }) end
  if action == "__menu" then ctx.Match.beginRound() return json({ ok = true, msg = "Nova partida: escolha o modo." }) end
  local ok, msg = ctx.Commands.handle(USER, "Você", action, a, b, ctx.now(), c)
  return json({ ok = ok, msg = msg })
end
`;

let engine = null;
const ready = (async () => {
  try { engine = await wasmEngine(); }
  catch (e) { console.warn("[MundialWar] WebAssembly Lua indisponível, usando motor JS:", e && (e.stack || e.message) || e); engine = jsEngine(); }
  for (const [name, src] of Object.entries(SOURCES)) engine.load(name, src);
  engine.run(BOOT);
})();

function call(name, ...args) {
  try { return engine.call(name, ...args); }
  catch (e) { fail(e && e.message || e); return null; }
}

// The simulation advances 0.2 s per step. If the device cannot keep up, the game slows
// down instead of piling up work (no catch-up bursts that freeze the page).
let timer = null, busy = false;
function run() {
  if (timer) return;
  timer = setInterval(() => {
    if (busy) return;
    busy = true;
    const s = call("frame");
    if (s) postMessage({ t: "frame", data: s });
    busy = false;
  }, 200);
}

onmessage = async (e) => {
  const m = e.data;
  try { await ready; } catch (err) { fail(err && err.message || err); return; }
  if (m.t === "start") {
    const s = call("boot");
    if (s) postMessage({ t: "boot", data: s, engine: engine.name });
    run();
  } else if (m.t === "cmd") {
    const s = call("cmd", m.action, m.a, m.b, m.c);
    if (s) postMessage({ t: "reply", data: s, action: m.action });
  } else if (m.t === "pause") {
    if (m.paused) { clearInterval(timer); timer = null; } else run();
  }
};
