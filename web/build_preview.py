"""Build index.html (browser preview) from src/ Lua and web/template.html.

  cd web && npm install && cd .. && python3 web/build_preview.py

The preview runs the same server rules as the Roblox game inside a Web Worker:
Lua 5.4 in WebAssembly (wasmoon), falling back to fengari (pure JS) when needed.
"""
from pathlib import Path
import base64
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
MODULES = HERE / "node_modules"

lua = {}
for name in ["GameConfig", "Palette", "Protocol", "MapGrid", "MapData", "BuildingStats"]:
    lua[name] = (ROOT / "src/shared" / f"{name}.lua").read_text(encoding="utf-8")
for name in ["TerritoryService", "NationService", "EconomyService", "CombatService", "BuildingService", "ExpansionService",
             "NavalService", "StrategicService", "DiplomacyService", "BotService", "MatchService", "CommandService", "World"]:
    lua[name] = (ROOT / "src/server" / f"{name}.lua").read_text(encoding="utf-8")

worker = (HERE / "worker.js").read_text(encoding="utf-8")
worker = (worker
          .replace("/*__WASMOON__*/", (MODULES / "wasmoon/dist/index.js").read_text(encoding="utf-8"))
          .replace("/*__FENGARI__*/", (MODULES / "fengari-web/dist/fengari-web.js").read_text(encoding="utf-8"))
          .replace("/*__LUA__*/", json.dumps(lua, ensure_ascii=False))
          .replace("/*__WASM__*/", base64.b64encode((MODULES / "wasmoon/dist/glue.wasm").read_bytes()).decode()))

world = json.loads((ROOT / "data/world-map.json").read_text(encoding="utf-8"))
mapdata = {"W": world["width"], "H": world["height"], "rows": world["rows"]}

html = (HERE / "template.html").read_text(encoding="utf-8")
html = html.replace('/*__WORKER__*/""', json.dumps(worker, ensure_ascii=False).replace("</", "<\\/").replace("�", "\\ufffd"))
html = html.replace("/*__MAP__*/null", json.dumps(mapdata))
assert "/*__" not in html.replace("/*__WORKER__*/", "")
html = "<!doctype html>\n<html lang=\"pt-BR\">\n<head>\n<meta charset=\"utf-8\">\n<meta name=\"viewport\" content=\"width=device-width, initial-scale=1, viewport-fit=cover\">\n<style>body{margin:0;font:14px system-ui,sans-serif}[hidden]{display:none!important}</style>\n" + html.replace("<canvas id=\"map\"", "</head>\n<body>\n<canvas id=\"map\"", 1) + "\n</body>\n</html>\n"
(ROOT / "index.html").write_text(html, encoding="utf-8")
print("index.html", len(html.encode()) // 1024, "KB")
