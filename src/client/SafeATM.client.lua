local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local pg=player:WaitForChild("PlayerGui")
local remote=RS:WaitForChild("ATMTransaction")
local openEvent=RS:WaitForChild("ATMOpen")

local old=pg:FindFirstChild("SafeATMGui"); if old then old:Destroy() end
local gui=Instance.new("ScreenGui"); gui.Name="SafeATMGui"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=false; gui.DisplayOrder=10000; gui.Parent=pg
local shade=Instance.new("Frame"); shade.Size=UDim2.fromScale(1,1); shade.BackgroundTransparency=1; shade.Visible=false; shade.Parent=gui

local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
local compact=vp.X<900 or vp.Y<600
local W=compact and .76 or .72
local H=compact and 270 or 390

local panel=Instance.new("Frame"); panel.AnchorPoint=Vector2.new(.5,.5); panel.Position=UDim2.fromScale(.5,.52); panel.Size=UDim2.new(W,0,0,H); panel.BackgroundColor3=Color3.fromRGB(8,10,14); panel.BorderSizePixel=0; panel.Parent=shade
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,18)
local ps=Instance.new("UIStroke",panel); ps.Color=Color3.fromRGB(222,166,36); ps.Thickness=1.5; ps.Transparency=.15
local c=Instance.new("UISizeConstraint",panel); c.MaxSize=compact and Vector2.new(650,270) or Vector2.new(900,390); c.MinSize=compact and Vector2.new(330,260) or Vector2.new(500,350)

local function sy(n) return compact and math.floor(n*.70) or n end
local function fs(n) return compact and math.max(10,math.floor(n*.78)) or n end
local function corner(o,r) Instance.new("UICorner",o).CornerRadius=UDim.new(0,r) end
local function txt(parent,t,pos,size,n,bold,col,align)
 local x=Instance.new("TextLabel"); x.BackgroundTransparency=1;x.Position=pos;x.Size=size;x.Text=t;x.TextColor3=col or Color3.fromRGB(238,240,244);x.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham;x.TextSize=fs(n);x.TextXAlignment=align or Enum.TextXAlignment.Left;x.Parent=parent;return x
end
local gold=Color3.fromRGB(255,194,45); local dim=Color3.fromRGB(145,151,164); local card=Color3.fromRGB(18,21,27)

-- header
local logo=Instance.new("Frame");logo.Position=UDim2.fromOffset(22,sy(18));logo.Size=UDim2.fromOffset(sy(44),sy(44));logo.BackgroundColor3=gold;logo.Parent=panel;corner(logo,10)
txt(logo,"▰",UDim2.fromScale(0,0),UDim2.fromScale(1,1),22,true,Color3.fromRGB(25,22,12),Enum.TextXAlignment.Center)
txt(panel,"BANCO DE OURO",UDim2.fromOffset(compact and 64 or 80,sy(15)),UDim2.new(1,-160,0,sy(30)),24,true)
txt(panel,"GERENCIE SEU OURO COM SEGURANÇA",UDim2.fromOffset(compact and 64 or 80,sy(44)),UDim2.new(1,-180,0,sy(20)),11,false,dim)
local secure=txt(panel,"▣  SEU SALDO ESTÁ SEGURO",UDim2.new(1,-260,0,sy(31)),UDim2.fromOffset(190,sy(20)),10,true,gold,Enum.TextXAlignment.Right); secure.Visible=not compact
local close=Instance.new("TextButton");close.AnchorPoint=Vector2.new(1,0);close.Position=UDim2.new(1,-18,0,sy(16));close.Size=UDim2.fromOffset(sy(42),sy(42));close.BackgroundColor3=Color3.fromRGB(25,28,35);close.Text="×";close.TextColor3=Color3.new(1,1,1);close.TextSize=fs(26);close.Font=Enum.Font.GothamBold;close.BorderSizePixel=0;close.Parent=panel;corner(close,10)
local line=Instance.new("Frame");line.Position=UDim2.fromOffset(20,sy(76));line.Size=UDim2.new(1,-40,0,1);line.BackgroundColor3=Color3.fromRGB(170,126,28);line.BorderSizePixel=0;line.Parent=panel

-- sidebar
local side=Instance.new("Frame");side.Position=UDim2.fromOffset(20,sy(91));side.Size=UDim2.new(compact and .27 or .25,-25,1,-sy(111));side.BackgroundTransparency=1;side.Parent=panel
local navLayout=Instance.new("UIListLayout",side);navLayout.Padding=UDim.new(0,sy(10))
local navs={}
local function nav(name)
 local b=Instance.new("TextButton");b.Size=UDim2.new(1,0,0,sy(56));b.BackgroundColor3=Color3.fromRGB(22,25,31);b.Text=name;b.TextColor3=Color3.fromRGB(220,223,230);b.TextSize=fs(13);b.Font=Enum.Font.GothamBold;b.BorderSizePixel=0;b.Parent=side;corner(b,11)
 local st=Instance.new("UIStroke",b);st.Color=Color3.fromRGB(55,59,68);st.Transparency=.4
 navs[name]=b;return b
end
nav("INÍCIO");nav("DEPOSITAR");nav("SACAR")

local main=Instance.new("Frame");main.Position=UDim2.new(compact and .29 or .27,12,0,sy(91));main.Size=UDim2.new(compact and .71 or .73,-32,1,-sy(111));main.BackgroundTransparency=1;main.Parent=panel

local home=Instance.new("Frame");home.Size=UDim2.fromScale(1,1);home.BackgroundTransparency=1;home.Parent=main
local transactPage=Instance.new("Frame");transactPage.Size=UDim2.fromScale(1,1);transactPage.BackgroundTransparency=1;transactPage.Visible=false;transactPage.Parent=main

txt(home,"BEM-VINDO",UDim2.fromOffset(4,sy(8)),UDim2.new(1,-8,0,sy(35)),27,true)
txt(home,"SELECIONE UMA OPÇÃO AO LADO",UDim2.fromOffset(4,sy(43)),UDim2.new(1,-8,0,sy(24)),12,false,dim)

local function balanceCard(parent,title,sub,x)
 local f=Instance.new("Frame");f.Position=UDim2.new(x,x==0 and 4 or 8,0,sy(82));f.Size=UDim2.new(.5,-12,0,sy(112));f.BackgroundColor3=card;f.BorderSizePixel=0;f.Parent=parent;corner(f,14)
 local st=Instance.new("UIStroke",f);st.Color=gold;st.Transparency=.2
 txt(f,title,UDim2.fromOffset(16,sy(14)),UDim2.new(1,-32,0,sy(24)),15,true)
 txt(f,sub,UDim2.fromOffset(16,sy(38)),UDim2.new(1,-32,0,sy(20)),11,false,dim)
 local v=txt(f,"0",UDim2.fromOffset(16,sy(64)),UDim2.new(1,-32,0,sy(42)),25,true,gold)
 return v
end
local homeWallet=balanceCard(home,"CARTEIRA","Ouro em mãos",0)
local homeBank=balanceCard(home,"NO BANCO","Ouro guardado",.5)

local pageTitle=txt(transactPage,"DEPOSITAR OURO",UDim2.fromOffset(4,sy(5)),UDim2.new(1,-8,0,sy(32)),23,true)
local pageSub=txt(transactPage,"Transfira ouro da carteira para o banco.",UDim2.fromOffset(4,sy(36)),UDim2.new(1,-8,0,sy(22)),11,false,dim)

local summary=Instance.new("Frame");summary.Position=UDim2.fromOffset(4,sy(62));summary.Size=UDim2.new(1,-8,0,sy(50));summary.BackgroundColor3=card;summary.BorderSizePixel=0;summary.Parent=transactPage;corner(summary,11)
local available=txt(summary,"DISPONÍVEL  0 Ouro",UDim2.fromOffset(16,0),UDim2.new(1,-32,1,0),14,true,gold)

local shortcuts={"25%","50%","MAX"};local shortcutButtons={}
local row=Instance.new("Frame");row.Position=UDim2.fromOffset(4,sy(122));row.Size=UDim2.new(1,-8,0,sy(38));row.BackgroundTransparency=1;row.Parent=transactPage
local rl=Instance.new("UIListLayout",row);rl.FillDirection=Enum.FillDirection.Horizontal;rl.Padding=UDim.new(0,8)
for i,n in ipairs(shortcuts) do local b=Instance.new("TextButton");b.Size=UDim2.new(1/3,-6,1,0);b.BackgroundColor3=Color3.fromRGB(25,28,35);b.Text=n;b.TextColor3=Color3.fromRGB(215,218,225);b.Font=Enum.Font.GothamBold;b.TextSize=fs(12);b.BorderSizePixel=0;b.Parent=row;corner(b,9);shortcutButtons[i]=b end

local input=Instance.new("TextBox");input.Position=UDim2.fromOffset(4,sy(170));input.Size=UDim2.new(1,-8,0,sy(44));input.BackgroundColor3=Color3.fromRGB(18,21,27);input.TextColor3=Color3.new(1,1,1);input.PlaceholderColor3=dim;input.PlaceholderText="Digite a quantidade";input.Text="";input.ClearTextOnFocus=false;input.Font=Enum.Font.Gotham;input.TextSize=fs(14);input.BorderSizePixel=0;input.Parent=transactPage;corner(input,10)

local confirm=Instance.new("TextButton");confirm.Position=UDim2.fromOffset(4,sy(224));confirm.Size=UDim2.new(1,-8,0,sy(46));confirm.BackgroundColor3=gold;confirm.TextColor3=Color3.fromRGB(20,18,12);confirm.Text="CONFIRMAR DEPÓSITO";confirm.Font=Enum.Font.GothamBold;confirm.TextSize=fs(14);confirm.BorderSizePixel=0;confirm.Parent=transactPage;corner(confirm,11)
local status=txt(transactPage,"",UDim2.fromOffset(4,sy(275)),UDim2.new(1,-8,0,sy(22)),10,false,dim,Enum.TextXAlignment.Center)

local action="deposit"
local function vals() local ls=player:FindFirstChild("leaderstats");return ls and ls:FindFirstChild("Ouro"),player:FindFirstChild("Banco") end
local function refresh()
 local w,b=vals();local wv=w and w.Value or 0;local bv=b and b.Value or 0
 homeWallet.Text=tostring(wv).." Ouro";homeBank.Text=tostring(bv).." Ouro"
 available.Text="DISPONÍVEL  "..tostring(action=="deposit" and wv or bv).." Ouro"
end
local function setNav(active)
 for n,b in pairs(navs) do b.BackgroundColor3=n==active and gold or Color3.fromRGB(22,25,31);b.TextColor3=n==active and Color3.fromRGB(20,18,12) or Color3.fromRGB(220,223,230) end
end
local function showHome() home.Visible=true;transactPage.Visible=false;setNav("INÍCIO");refresh() end
local function showAction(a)
 action=a;home.Visible=false;transactPage.Visible=true;input.Text="";status.Text=""
 if a=="deposit" then pageTitle.Text="DEPOSITAR OURO";pageSub.Text="Transfira ouro da carteira para o banco.";confirm.Text="CONFIRMAR DEPÓSITO";setNav("DEPOSITAR")
 else pageTitle.Text="SACAR OURO";pageSub.Text="Transfira ouro do banco para sua carteira.";confirm.Text="CONFIRMAR SAQUE";setNav("SACAR") end
 refresh()
end
navs["INÍCIO"].Activated:Connect(showHome);navs["DEPOSITAR"].Activated:Connect(function()showAction("deposit")end);navs["SACAR"].Activated:Connect(function()showAction("withdraw")end)
local function source() local w,b=vals();return action=="deposit" and w or b end
shortcutButtons[1].Activated:Connect(function()local v=source();if v then input.Text=tostring(math.max(1,math.floor(v.Value*.25)))end end)
shortcutButtons[2].Activated:Connect(function()local v=source();if v then input.Text=tostring(math.max(1,math.floor(v.Value*.5)))end end)
shortcutButtons[3].Activated:Connect(function()local v=source();if v then input.Text=tostring(v.Value)end end)

local busy=false
confirm.Activated:Connect(function()
 if busy then return end
 local n=tonumber(input.Text);if not n or n<1 then status.Text="Digite uma quantidade válida.";return end
 busy=true;status.Text="Processando..."
 local ok,success,msg=pcall(function()return remote:InvokeServer(action,n)end);busy=false
 if not ok then status.Text="Falha de comunicação.";return end
 status.Text=msg or (success and "Transação concluída." or "Operação recusada.")
 if success then input.Text="" end;refresh()
end)
close.Activated:Connect(function()shade.Visible=false end)
openEvent.OnClientEvent:Connect(function()showHome();shade.Visible=true end)
local ls=player:WaitForChild("leaderstats");local liveGold=ls:WaitForChild("Ouro");local liveBank=player:WaitForChild("Banco")
liveGold:GetPropertyChangedSignal("Value"):Connect(refresh);liveBank:GetPropertyChangedSignal("Value"):Connect(refresh)
showHome()
