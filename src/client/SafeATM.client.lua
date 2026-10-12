local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remote = RS:WaitForChild("ATMTransaction")
local openEvent = RS:WaitForChild("ATMOpen")

local old = playerGui:FindFirstChild("SafeATMGui")
if old then old:Destroy() end

local gui=Instance.new("ScreenGui")
gui.Name="SafeATMGui"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=false
gui.DisplayOrder=10000
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=playerGui

local shade=Instance.new("Frame")
shade.Name="Shade"
shade.Size=UDim2.fromScale(1,1)
shade.BackgroundColor3=Color3.fromRGB(0,0,0)
shade.BackgroundTransparency=.38
shade.BorderSizePixel=0
shade.Visible=false
shade.ZIndex=10
shade.Parent=gui

local panel=Instance.new("Frame")
panel.Name="ATMPanel"
panel.AnchorPoint=Vector2.new(.5,.5)
panel.Position=UDim2.fromScale(.5,.53)
panel.Size=UDim2.new(.78,0,0,400)
panel.BackgroundColor3=Color3.fromRGB(12,14,18)
panel.BorderSizePixel=0
panel.ZIndex=20
panel.Parent=shade
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,22)
local stroke=Instance.new("UIStroke",panel)
stroke.Color=Color3.fromRGB(58,62,72)
stroke.Transparency=.35
stroke.Thickness=1

local sizeConstraint=Instance.new("UISizeConstraint",panel)
sizeConstraint.MaxSize=Vector2.new(720,400)
sizeConstraint.MinSize=Vector2.new(320,380)

local function text(parent,value,pos,size,fontSize,bold,color,align)
	local x=Instance.new("TextLabel")
	x.BackgroundTransparency=1
	x.Position=pos
	x.Size=size
	x.Text=value
	x.TextColor3=color or Color3.fromRGB(238,240,244)
	x.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
	x.TextSize=fontSize
	x.TextXAlignment=align or Enum.TextXAlignment.Left
	x.ZIndex=22
	x.Parent=parent
	return x
end

local coin=Instance.new("Frame")
coin.Position=UDim2.fromOffset(24,22)
coin.Size=UDim2.fromOffset(38,38)
coin.BackgroundColor3=Color3.fromRGB(255,197,47)
coin.BorderSizePixel=0
coin.ZIndex=22
coin.Parent=panel
Instance.new("UICorner",coin).CornerRadius=UDim.new(1,0)
text(coin,"O",UDim2.fromScale(0,0),UDim2.fromScale(1,1),18,true,Color3.fromRGB(25,25,27),Enum.TextXAlignment.Center)

text(panel,"BANCO DE OURO",UDim2.fromOffset(74,19),UDim2.new(1,-140,0,28),22,true)
text(panel,"Gerencie seu ouro com segurança",UDim2.fromOffset(74,46),UDim2.new(1,-140,0,20),12,false,Color3.fromRGB(145,150,160))

local close=Instance.new("TextButton")
close.AnchorPoint=Vector2.new(1,0)
close.Position=UDim2.new(1,-20,0,22)
close.Size=UDim2.fromOffset(38,38)
close.BackgroundColor3=Color3.fromRGB(31,34,41)
close.Text="×"
close.TextColor3=Color3.fromRGB(210,213,220)
close.Font=Enum.Font.GothamBold
close.TextSize=24
close.BorderSizePixel=0
close.ZIndex=24
close.Parent=panel
Instance.new("UICorner",close).CornerRadius=UDim.new(0,11)

local divider=Instance.new("Frame")
divider.Position=UDim2.fromOffset(24,78)
divider.Size=UDim2.new(1,-48,0,1)
divider.BackgroundColor3=Color3.fromRGB(45,48,57)
divider.BorderSizePixel=0
divider.ZIndex=21
divider.Parent=panel

local function balanceCard(title,x)
	local card=Instance.new("Frame")
	card.Position=UDim2.new(x,x==0 and 24 or 8,0,88)
	card.Size=UDim2.new(.5,-32,0,76)
	card.BackgroundColor3=Color3.fromRGB(22,25,31)
	card.BorderSizePixel=0
	card.ZIndex=21
	card.Parent=panel
	Instance.new("UICorner",card).CornerRadius=UDim.new(0,14)
	local cs=Instance.new("UIStroke",card);cs.Color=Color3.fromRGB(53,57,67);cs.Transparency=.5
	text(card,title,UDim2.fromOffset(16,12),UDim2.new(1,-32,0,18),11,true,Color3.fromRGB(145,150,160))
	local value=text(card,"0",UDim2.fromOffset(16,33),UDim2.new(1,-32,0,32),23,true,Color3.fromRGB(255,205,62))
	return value
end

local walletValue=balanceCard("CARTEIRA",0)
local bankValue=balanceCard("NO BANCO",.5)

local input=Instance.new("TextBox")
input.Position=UDim2.fromOffset(24,178)
input.Size=UDim2.new(1,-48,0,46)
input.BackgroundColor3=Color3.fromRGB(24,27,33)
input.TextColor3=Color3.fromRGB(245,246,248)
input.PlaceholderColor3=Color3.fromRGB(115,120,130)
input.PlaceholderText="Quantidade de Ouro"
input.Text=""
input.ClearTextOnFocus=false
input.Font=Enum.Font.Gotham
input.TextSize=15
input.BorderSizePixel=0
input.ZIndex=22
input.Parent=panel
Instance.new("UICorner",input).CornerRadius=UDim.new(0,12)

local shortcuts={"25%","50%","MAX"}
local shortcutButtons={}
for i,name in ipairs(shortcuts) do
	local b=Instance.new("TextButton")
	local left=24
	local right=24
	local gap=8
	local widthScale=1/3
	local offsetX=left + (i-1)*gap/3
	b.Position=UDim2.new((i-1)*widthScale,offsetX,0,236)
	b.Size=UDim2.new(widthScale,-((left+right+2*gap)/3),0,32)
	b.BackgroundColor3=Color3.fromRGB(28,31,38)
	b.TextColor3=Color3.fromRGB(190,194,202)
	b.Text=name
	b.Font=Enum.Font.GothamBold
	b.TextSize=12
	b.BorderSizePixel=0
	b.ZIndex=22
	b.Parent=panel
	Instance.new("UICorner",b).CornerRadius=UDim.new(0,9)
	shortcutButtons[i]=b
end

local function actionButton(name,x)
	local b=Instance.new("TextButton")
	b.Position=UDim2.new(x,x==0 and 24 or 8,0,280)
	b.Size=UDim2.new(.5,-32,0,50)
	b.BackgroundColor3=Color3.fromRGB(255,197,47)
	b.TextColor3=Color3.fromRGB(22,22,24)
	b.Text=name
	b.Font=Enum.Font.GothamBold
	b.TextSize=15
	b.BorderSizePixel=0
	b.ZIndex=22
	b.Parent=panel
	Instance.new("UICorner",b).CornerRadius=UDim.new(0,13)
	return b
end

local deposit=actionButton("DEPOSITAR",0)
local withdraw=actionButton("SACAR",.5)
local status=text(panel,"Pronto para transacionar",UDim2.fromOffset(24,344),UDim2.new(1,-48,0,28),12,false,Color3.fromRGB(135,141,151))
status.TextXAlignment=Enum.TextXAlignment.Center

local function values()
	local ls=player:FindFirstChild("leaderstats")
	return ls and ls:FindFirstChild("Ouro"),player:FindFirstChild("Banco")
end

local function refresh()
	local gold,bank=values()
	walletValue.Text=(gold and tostring(gold.Value) or "—").." Ouro"
	bankValue.Text=(bank and tostring(bank.Value) or "—").." Ouro"
end

local function openATM()
	refresh()
	status.Text="Pronto para transacionar"
	shade.Visible=true
end

local selectedAction="deposit"
local busy=false
local function transact(action)
	if busy then return end
	local n=tonumber(input.Text)
	if not n or n<1 then status.Text="Digite uma quantidade válida.";return end
	busy=true
	status.Text="Processando..."
	local ok,success,msg=pcall(function() return remote:InvokeServer(action,n) end)
	busy=false
	if not ok then status.Text="Falha de comunicação.";return end
	status.Text=msg or (success and "Operação concluída." or "Operação recusada.")
	if success then input.Text="" end
	refresh()
end

local function sourceBalance()
	local gold,bank=values()
	return selectedAction=="withdraw" and bank or gold
end

local function setFraction(frac)
	local source=sourceBalance()
	if source then input.Text=tostring(math.max(1,math.floor(source.Value*frac))) end
end
shortcutButtons[1].Activated:Connect(function() setFraction(.25) end)
shortcutButtons[2].Activated:Connect(function() setFraction(.5) end)
shortcutButtons[3].Activated:Connect(function()
	local source=sourceBalance()
	if source then input.Text=tostring(source.Value) end
end)

local function selectAction(action)
	selectedAction=action
	if action=="deposit" then
		deposit.BackgroundColor3=Color3.fromRGB(255,197,47)
		withdraw.BackgroundColor3=Color3.fromRGB(48,52,61)
		withdraw.TextColor3=Color3.fromRGB(220,223,230)
		status.Text="Modo depósito — atalhos usam sua carteira."
	else
		withdraw.BackgroundColor3=Color3.fromRGB(255,197,47)
		withdraw.TextColor3=Color3.fromRGB(22,22,24)
		deposit.BackgroundColor3=Color3.fromRGB(48,52,61)
		deposit.TextColor3=Color3.fromRGB(220,223,230)
		status.Text="Modo saque — atalhos usam seu banco."
	end
end

deposit.Activated:Connect(function()
	if selectedAction~="deposit" then selectAction("deposit") else transact("deposit") end
end)
withdraw.Activated:Connect(function()
	if selectedAction~="withdraw" then selectAction("withdraw") else transact("withdraw") end
end)
close.Activated:Connect(function() shade.Visible=false end)
openEvent.OnClientEvent:Connect(openATM)

local leaderstats=player:WaitForChild("leaderstats")
local liveGold=leaderstats:WaitForChild("Ouro")
local liveBank=player:WaitForChild("Banco")
liveGold:GetPropertyChangedSignal("Value"):Connect(refresh)
liveBank:GetPropertyChangedSignal("Value"):Connect(refresh)
selectAction("deposit")
refresh()
