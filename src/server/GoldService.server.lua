local Players=game:GetService("Players")
local DataStoreService=game:GetService("DataStoreService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local GOLD_PER_SECOND,SAVE_INTERVAL=1,30
local GoldStore=DataStoreService:GetDataStore("PlayerGold_v1")
local HudStore=DataStoreService:GetDataStore("PlayerHUD_v2")
local remote=ReplicatedStorage:FindFirstChild("ATMTransaction") or Instance.new("RemoteFunction")
remote.Name="ATMTransaction"; remote.Parent=ReplicatedStorage
local hudRemote=ReplicatedStorage:FindFirstChild("HUDPosition") or Instance.new("RemoteFunction")
hudRemote.Name="HUDPosition";hudRemote.Parent=ReplicatedStorage
local sessions={}
local hudSessions={}
local function keyFor(p)return"user_"..p.UserId end
local function savePlayer(p)
 local s=sessions[p]; if not s then return end
 local ok,err=pcall(function() GoldStore:UpdateAsync(keyFor(p),function()return{wallet=s.wallet,bank=s.bank}end)end)
 if not ok then warn("[Gold] Falha ao salvar "..p.Name..": "..tostring(err))end
end
local function setupPlayer(p)
 local presets={hud1={x=0,y=-4,scale=1,sx=-87,sy=0,ss=1,jx=-28,jy=-110,js=1},hud2={x=0,y=-4,scale=1,sx=-87,sy=0,ss=1,jx=-28,jy=-110,js=1}}
 local active="hud1"
 local hok,hdata=pcall(function()return HudStore:GetAsync(keyFor(p))end)
 if hok and type(hdata)=="table" then
  if hdata.hud1 then presets.hud1={x=math.clamp(math.floor(tonumber(hdata.hud1.x) or 0),-500,0),y=math.clamp(math.floor(tonumber(hdata.hud1.y) or -4),-100,500),scale=math.clamp(tonumber(hdata.hud1.scale) or 1,.7,1.4),sx=math.clamp(math.floor(tonumber(hdata.hud1.sx) or -87),-500,0),sy=math.clamp(math.floor(tonumber(hdata.hud1.sy) or 0),0,500),ss=math.clamp(tonumber(hdata.hud1.ss) or 1,.7,1.4),jx=math.clamp(math.floor(tonumber(hdata.hud1.jx) or -28),-1000,0),jy=math.clamp(math.floor(tonumber(hdata.hud1.jy) or -110),-1000,0),js=math.clamp(tonumber(hdata.hud1.js) or 1,.7,1.4)} end
  if hdata.hud2 then presets.hud2={x=math.clamp(math.floor(tonumber(hdata.hud2.x) or 0),-500,0),y=math.clamp(math.floor(tonumber(hdata.hud2.y) or -4),-100,500),scale=math.clamp(tonumber(hdata.hud2.scale) or 1,.7,1.4),sx=math.clamp(math.floor(tonumber(hdata.hud2.sx) or -87),-500,0),sy=math.clamp(math.floor(tonumber(hdata.hud2.sy) or 0),0,500),ss=math.clamp(tonumber(hdata.hud2.ss) or 1,.7,1.4),jx=math.clamp(math.floor(tonumber(hdata.hud2.jx) or -28),-1000,0),jy=math.clamp(math.floor(tonumber(hdata.hud2.jy) or -110),-1000,0),js=math.clamp(tonumber(hdata.hud2.js) or 1,.7,1.4)} end
  if hdata.active=="hud2" then active="hud2" end
 end
 hudSessions[p]={presets=presets,active=active}
 local wallet,bank=0,0
 local ok,data=pcall(function()return GoldStore:GetAsync(keyFor(p))end)
 if ok then
  if type(data)=="table"then wallet=math.max(0,math.floor(tonumber(data.wallet)or 0));bank=math.max(0,math.floor(tonumber(data.bank)or 0))
  elseif type(data)=="number"then wallet=math.max(0,math.floor(data))end
 else warn("[Gold] Falha ao carregar "..p.Name..": "..tostring(data))end
 local ls=Instance.new("Folder");ls.Name="leaderstats";ls.Parent=p
 local g=Instance.new("IntValue");g.Name="Ouro";g.Value=wallet;g.Parent=ls
 local b=Instance.new("IntValue");b.Name="Banco";b.Value=bank;b.Parent=p
 sessions[p]={wallet=wallet,bank=bank,goldValue=g,bankValue=b,lastTransaction=0}
 task.spawn(function()while p.Parent==Players and sessions[p]do task.wait(1);local s=sessions[p];if s then s.wallet+=GOLD_PER_SECOND;s.goldValue.Value=s.wallet end end end)
 task.spawn(function()while p.Parent==Players and sessions[p]do task.wait(SAVE_INTERVAL);if sessions[p]then savePlayer(p)end end end)
end
hudRemote.OnServerInvoke=function(p,action,a,b,c,d,e,f,g,jx,jy,js)
 local h=hudSessions[p]
 if not h then return false,"hud1",0,-4 end
 if action=="get" then local q=h.presets[h.active];return true,h.active,q.x,q.y,q.scale,q.sx,q.sy,q.ss,q.jx,q.jy,q.js end
 if action=="save" then
  local slot=(a=="hud2") and "hud2" or "hud1"
  local x=math.clamp(math.floor(tonumber(b) or 0),-500,0)
  local y=math.clamp(math.floor(tonumber(c) or -4),-100,500)
  local scale=math.clamp(tonumber(d) or 1,.7,1.4)
  local sx=math.clamp(math.floor(tonumber(e) or -87),-500,0);local sy=math.clamp(math.floor(tonumber(f) or 0),0,500);local ss=math.clamp(tonumber(g) or 1,.7,1.4)
  local px=math.clamp(math.floor(tonumber(jx) or -28),-1000,0);local py=math.clamp(math.floor(tonumber(jy) or -110),-1000,0);local ps=math.clamp(tonumber(js) or 1,.7,1.4)
  h.presets[slot]={x=x,y=y,scale=scale,sx=sx,sy=sy,ss=ss,jx=px,jy=py,js=ps};h.active=slot
  local ok=pcall(function()HudStore:SetAsync(keyFor(p),{active=h.active,hud1=h.presets.hud1,hud2=h.presets.hud2})end)
  return ok,slot,x,y,scale,sx,sy,ss,px,py,ps
 end
 if action=="load" then
  local slot=(a=="hud2") and "hud2" or "hud1";h.active=slot;local q=h.presets[slot]
  return true,slot,q.x,q.y,q.scale,q.sx,q.sy,q.ss,q.jx,q.jy,q.js
 end
 if action=="reset" then
  local slot=(a=="hud2") and "hud2" or "hud1";h.presets[slot]={x=0,y=-4,scale=1,sx=-87,sy=0,ss=1,jx=-28,jy=-110,js=1};h.active=slot
  local ok=pcall(function()HudStore:SetAsync(keyFor(p),{active=h.active,hud1=h.presets.hud1,hud2=h.presets.hud2})end)
  return ok,slot,0,-4,1,-87,0,1,-28,-110,1
 end
 return false,h.active,0,-4
end

remote.OnServerInvoke=function(p,action,raw)
 local s=sessions[p];if not s then return false,"Sessao indisponivel"end
 local now=os.clock();if now-s.lastTransaction<.25 then return false,"Aguarde um instante"end;s.lastTransaction=now
 local n=tonumber(raw);if not n or n~=n or n==math.huge or n==-math.huge then return false,"Valor invalido"end;n=math.floor(n)
 if n<1 or n>1000000000 then return false,"Valor invalido"end
 if action=="deposit"then if n>s.wallet then return false,"Ouro insuficiente na carteira"end;s.wallet-=n;s.bank+=n
 elseif action=="withdraw"then if n>s.bank then return false,"Saldo insuficiente no banco"end;s.bank-=n;s.wallet+=n
 else return false,"Operacao invalida"end
 s.goldValue.Value=s.wallet;s.bankValue.Value=s.bank;task.spawn(savePlayer,p)
 return true,"Operacao concluida"
end
Players.PlayerAdded:Connect(setupPlayer)
for _,p in ipairs(Players:GetPlayers()) do
 task.spawn(setupPlayer,p)
end
Players.PlayerRemoving:Connect(function(p)savePlayer(p);sessions[p]=nil;hudSessions[p]=nil end)
game:BindToClose(function()for p in pairs(sessions)do savePlayer(p)end end)
