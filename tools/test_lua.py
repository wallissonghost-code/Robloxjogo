"""Run pure logic tests using an installed Lua 5.4 shared library (no pip deps).

Normal `lua tests/map_spec.lua` is also supported. This runner does not emulate
Roblox APIs; client scripts still require Studio/device verification.
"""
import ctypes
import ctypes.util
import os
from pathlib import Path

os.chdir(Path(__file__).resolve().parents[1])
library = ctypes.util.find_library("lua5.4")
if not library:
    raise SystemExit("Install Lua 5.4 and run: lua tests/map_spec.lua")
lua = ctypes.CDLL(library)
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
lua.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
lua.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int,
                         ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_settop.argtypes = [ctypes.c_void_p, ctypes.c_int]
lua.lua_close.argtypes = [ctypes.c_void_p]
state = lua.luaL_newstate()
lua.luaL_openlibs(state)
try:
    # These new modules intentionally use syntax common to Lua 5.4 and Luau.
    paths = list(Path("src/shared").glob("*.lua"))
    paths += list(Path("src/client").glob("*.lua"))
    paths += [Path("src/server/MapService.lua")]
    bootstrap = Path("src/server/Bootstrap.server.lua")
    if bootstrap.exists():
        paths.append(bootstrap)
    for path in paths:
        if lua.luaL_loadfilex(state, str(path).encode(), None):
            raise RuntimeError(lua.lua_tolstring(state, -1, None).decode())
        lua.lua_settop(state, 0)
    print(f"Syntax OK: {len(paths)} new source files", flush=True)
    status = lua.luaL_loadfilex(state, b"tests/map_spec.lua", None)
    if not status:
        status = lua.lua_pcallk(state, 0, -1, 0, 0, None)
    if status:
        raise RuntimeError(lua.lua_tolstring(state, -1, None).decode())
finally:
    lua.lua_close(state)
