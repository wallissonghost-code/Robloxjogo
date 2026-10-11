local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remote = RS:WaitForChild("ATMTransaction")
local openEvent = RS:WaitForChild("ATMOpen")

local old = playerGui:FindFirstChild("SafeATMGui")
if old then old:Destroy() end
local oldBoot = playerGui:FindFirstChild("ATMClientBootV20")
if oldBoot then oldBoot:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "SafeATMGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10000
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "ATMPanel"
panel.AnchorPoint = Vector2.new(.5,.5)
panel.Position = UDim2.fromScale(.5,.5)
panel.Size = UDim2.new(.88,0,0,390)
panel.BackgroundColor3 = Color3.fromRGB(15,17,20)
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 20
panel.Parent = gui
Instance.new("UICorner",panel).CornerRadius = UDim.new(0,18)

local function label(text,pos,size,fontSize,bold)
	local x=Instance.new("TextLabel")
	x.BackgroundTransparency=1
	x.Position=pos
	x.Size=size
	x.Text=text
	x.TextColor3=Color3.fromRGB(240,240,244)
	x.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
	x.TextSize=fontSize
	x.TextXAlignment=Enum.TextXAlignment.Left
	x.ZIndex=21
	x.Parent=panel
	return x
end

label("BANCO DE OURO",UDim2.fromOffset(20,18),UDim2.new(1,-80,0,32),24,true)

local close=Instance.new("TextButton")
close.AnchorPoint=Vector2.new(1,0)
close.Position=UDim2.new(1,-16,0,16)
close.Size=UDim2.fromOffset(42,42)
close.BackgroundColor3=Color3.fromRGB(40,43,49)
close.Text="X"
close.TextColor3=Color3.new(1,1,1)
close.Font=Enum.Font.GothamBold
close.TextSize=16
close.BorderSizePixel=0
close.ZIndex=22
close.Parent=panel
Instance.new("UICorner",close).CornerRadius=UDim.new(0,10)

local walletLabel=label("",UDim2.fromOffset(20,72),UDim2.new(.5,-25,0,45),18,true)
local bankLabel=label("",UDim2.new(.5,5,0,72),UDim2.new(.5,-25,0,45),18,true)

local input=Instance.new("TextBox")
input.Position=UDim2.fromOffset(20,132)
input.Size=UDim2.new(1,-40,0,52)
input.BackgroundColor3=Color3.fromRGB(29,32,37)
input.TextColor3=Color3.new(1,1,1)
input.PlaceholderText="Digite a quantidade de Ouro"
input.Text=""
input.ClearTextOnFocus=false
input.Font=Enum.Font.Gotham
input.TextSize=16
input.BorderSizePixel=0
input.ZIndex=21
input.Parent=panel
Instance.new("UICorner",input).CornerRadius=UDim.new(0,12)

local function makeButton(text,x)
	local b=Instance.new("TextButton")
	b.Position=UDim2.new(x,x==0 and 20 or 5,0,202)
	b.Size=UDim2.new(.5,-25,0,54)
	b.BackgroundColor3=Color3.fromRGB(255,205,55)
	b.TextColor3=Color3.fromRGB(20,20,22)
	b.Text=text
	b.Font=Enum.Font.GothamBold
	b.TextSize=16
	b.BorderSizePixel=0
	b.ZIndex=22
	b.Parent=panel
	Instance.new("UICorner",b).CornerRadius=UDim.new(0,12)
	return b
end

local deposit=makeButton("DEPOSITAR",0)
local withdraw=makeButton("SACAR",.5)
local status=label("ATM PRONTO",UDim2.fromOffset(20,278),UDim2.new(1,-40,0,70),14,false)
status.TextColor3=Color3.fromRGB(175,180,188)
status.TextWrapped=true

local function values()
	local ls=player:FindFirstChild("leaderstats")
	return ls and ls:FindFirstChild("Ouro"), player:FindFirstChild("Banco")
end

local function refresh()
	local gold,bank=values()
	walletLabel.Text="CARTEIRA\n"..(gold and gold.Value or "?").." Ouro"
	bankLabel.Text="BANCO\n"..(bank and bank.Value or "?").." Ouro"
end

local function openATM(source)
	refresh()
	status.Text="ATM ABERTO"
	panel.Visible=true
end

local busy=false
local function transact(action)
	if busy then return end
	local n=tonumber(input.Text)
	if not n or n<1 then status.Text="Digite um valor valido."; return end
	busy=true
	local ok,success,msg=pcall(function() return remote:InvokeServer(action,n) end)
	busy=false
	if not ok then status.Text="Falha de comunicacao."; return end
	status.Text=msg or (success and "Operacao concluida." or "Operacao recusada.")
	if success then input.Text="" end
	refresh()
end

deposit.Activated:Connect(function() transact("deposit") end)
withdraw.Activated:Connect(function() transact("withdraw") end)
close.Activated:Connect(function() panel.Visible=false end)
openEvent.OnClientEvent:Connect(function() openATM("PROMPT") end)

refresh()
