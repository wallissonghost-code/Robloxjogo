local Players=game:GetService("Players")
local DataStoreService=game:GetService("DataStoreService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local GOLD_PER_SECOND,SAVE_INTERVAL=1,30
local GoldStore=DataStoreService:GetDataStore("PlayerGold_v1")
local remote=ReplicatedStorage:FindFirstChild("ATMTransaction") or Instance.new("RemoteFunction")
remote.Name="ATMTransaction"; remote.Parent=ReplicatedStorage
local sessions={}
local function keyFor(p)return"user_"..p.UserId end
local function savePlayer(p)
 local s=sessions[p]; if not s then return end
 local ok,err=pcall(function() GoldStore:UpdateAsync(keyFor(p),function()return{wallet=s.wallet,bank=s.bank}end)end)
 if not ok then warn("[Gold] Falha ao salvar "..p.Name..": "..tostring(err))end
end
local function setupPlayer(p)
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
Players.PlayerRemoving:Connect(function(p)savePlayer(p);sessions[p]=nil end)
game:BindToClose(function()for p in pairs(sessions)do savePlayer(p)end end)
