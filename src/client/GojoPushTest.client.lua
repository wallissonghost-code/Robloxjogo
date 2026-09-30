local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")

local remote=ReplicatedStorage:WaitForChild("GojoPushTest")
local diagnosticRemote=ReplicatedStorage:WaitForChild("GojoDiagnostic")
local player=Players.LocalPlayer

local gui=Instance.new("ScreenGui")
gui.Name="GojoPushTestGui"
gui.ResetOnSpawn=false
gui.Parent=player:WaitForChild("PlayerGui")


local diag=Instance.new("TextLabel")
diag.Name="Diagnostic"
diag.Size=UDim2.fromOffset(310,72)
diag.Position=UDim2.new(.02,0,.13,0)
diag.BackgroundColor3=Color3.fromRGB(10,12,16)
diag.BackgroundTransparency=.08
diag.TextColor3=Color3.new(1,1,1)
diag.TextWrapped=true
diag.TextXAlignment=Enum.TextXAlignment.Left
diag.TextYAlignment=Enum.TextYAlignment.Top
diag.Font=Enum.Font.Code
diag.TextSize=9
diag.Text="GOJO DIAGNOSTICO\nAguardando clique..."
diag.Parent=gui
local dc=Instance.new("UICorner"); dc.CornerRadius=UDim.new(0,10); dc.Parent=diag
local history={}
local function addDiag(step,message)
	table.insert(history,os.date("%H:%M:%S").."  "..step.."  "..message)
	while #history>2 do table.remove(history,1) end
	diag.Text="GOJO DIAGNOSTICO\n"..table.concat(history,"\n")
end
local diagToggle=Instance.new("TextButton")
diagToggle.Name="DiagnosticToggle"
diagToggle.Size=UDim2.fromOffset(82,28)
diagToggle.Position=UDim2.new(.02,316,.13,0)
diagToggle.BackgroundColor3=Color3.fromRGB(25,28,34)
diagToggle.TextColor3=Color3.new(1,1,1)
diagToggle.Font=Enum.Font.GothamBold
diagToggle.TextSize=10
diagToggle.Text="OCULTAR DIAG"
diagToggle.Parent=gui
local dtc=Instance.new("UICorner"); dtc.CornerRadius=UDim.new(0,8); dtc.Parent=diagToggle

local diagVisible=true
diagToggle.Activated:Connect(function()
	diagVisible=not diagVisible
	diag.Visible=diagVisible
	diagToggle.Text=diagVisible and "OCULTAR DIAG" or "MOSTRAR DIAG"
	diagToggle.Position=diagVisible and UDim2.new(.02,0,.025,116) or UDim2.new(.02,0,.025,0)
end)

local fullFrame=Instance.new("ScrollingFrame")
fullFrame.Name="FullRigDiagnostic"
fullFrame.Size=UDim2.new(.94,0,.82,0)
fullFrame.Position=UDim2.new(.03,0,.03,0)
fullFrame.BackgroundColor3=Color3.fromRGB(7,9,12)
fullFrame.BackgroundTransparency=.03
fullFrame.BorderSizePixel=0
fullFrame.Visible=false
fullFrame.AutomaticCanvasSize=Enum.AutomaticSize.Y
fullFrame.CanvasSize=UDim2.new()
fullFrame.ScrollBarThickness=8
fullFrame.ZIndex=20
fullFrame.Parent=gui
local fc=Instance.new("UICorner"); fc.CornerRadius=UDim.new(0,12); fc.Parent=fullFrame
local fullText=Instance.new("TextLabel")
fullText.Size=UDim2.new(1,-24,0,0)
fullText.Position=UDim2.fromOffset(12,12)
fullText.AutomaticSize=Enum.AutomaticSize.Y
fullText.BackgroundTransparency=1
fullText.TextColor3=Color3.new(1,1,1)
fullText.Font=Enum.Font.Code
fullText.TextSize=13
fullText.TextXAlignment=Enum.TextXAlignment.Left
fullText.TextYAlignment=Enum.TextYAlignment.Top
fullText.TextWrapped=false
fullText.ZIndex=21
fullText.Parent=fullFrame
local close=Instance.new("TextButton")
close.Size=UDim2.fromOffset(90,38)
close.Position=UDim2.new(1,-14,0,10)
close.AnchorPoint=Vector2.new(1,0)
close.Text="FECHAR"
close.Font=Enum.Font.GothamBold
close.TextSize=14
close.ZIndex=22
close.Parent=fullFrame
close.Activated:Connect(function() fullFrame.Visible=false end)

diagnosticRemote.OnClientEvent:Connect(function(step,message)
	if step=="RIG_FULL" then
		fullText.Text=message
		fullFrame.CanvasPosition=Vector2.zero
		fullFrame.Visible=true
	else
		addDiag(step,message)
	end
end)
local button=Instance.new("TextButton")
button.Name="PushSphere"
button.AnchorPoint=Vector2.new(1,1)
button.Size=UDim2.fromOffset(128,40)
button.Position=UDim2.new(1,-12,1,-58)
button.BackgroundColor3=Color3.fromRGB(35,105,255)
button.TextColor3=Color3.new(1,1,1)
button.Font=Enum.Font.GothamBold
button.TextSize=12
button.Text="BLUE ARREMESSAR"
button.AutoButtonColor=true
button.Parent=gui

local corner=Instance.new("UICorner")
corner.CornerRadius=UDim.new(0,14)
corner.Parent=button

local teleportButton=button:Clone()
teleportButton.Name="RedTeleport"
teleportButton.Position=UDim2.new(1,-12,1,-12)
teleportButton.Text="RED TELEPORTE"
teleportButton.Parent=gui

local busy=false
button.Activated:Connect(function()
	if busy then return end
	busy=true
	addDiag("CLIQUE LOCAL","botao acionado; enviando RemoteEvent")
	remote:FireServer("blueThrow")
	button.Text="ARREMESSANDO!"
	task.wait(.6)
	button.Text="BLUE ARREMESSAR"
	busy=false
end)


local redButton=button:Clone()
redButton.Name="RedThrow"
redButton.Position=UDim2.new(1,-148,1,-58)
redButton.BackgroundColor3=Color3.fromRGB(220,35,45)
redButton.Text="RED ARREMESSAR"
redButton.Parent=gui

local redBusy=false
redButton.Activated:Connect(function()
	if redBusy then return end
	redBusy=true
	addDiag("CLIQUE LOCAL","Red arremessado")
	remote:FireServer("redThrow")
	redButton.Text="REPELINDO!"
	task.wait(.7)
	redButton.Text="RED ARREMESSAR"
	redBusy=false
end)

local comboButton=button:Clone()
comboButton.Name="BlueRedCombo"
comboButton.Position=UDim2.new(1,-148,1,-106)
comboButton.BackgroundColor3=Color3.fromRGB(125,55,190)
comboButton.Text="BLUE + RED"
comboButton.Parent=gui

local comboBusy=false
comboButton.Activated:Connect(function()
	if comboBusy then return end
	comboBusy=true
	addDiag("COMBO","Blue prende -> Red explode")
	remote:FireServer("combo")
	comboButton.Text="COMBO!"
	task.wait(2.5)
	comboButton.Text="BLUE + RED"
	comboBusy=false
end)

local rigButton=button:Clone()
rigButton.Name="RigDiagnostic"
rigButton.Position=UDim2.new(0,12,1,-12)
rigButton.AnchorPoint=Vector2.new(0,1)
rigButton.Text="DIAGNOSTICO GERAL"
rigButton.Parent=gui
rigButton.Activated:Connect(function()
	addDiag("DIAGNOSTICO","solicitando mapa completo do rig")
	remote:FireServer("diagnostic")
end)

local legsButton=button:Clone()
legsButton.Name="LegsTest"
legsButton.Position=UDim2.new(1,-12,1,-106)
legsButton.Text="TESTAR PERNAS"
legsButton.Parent=gui

local legsBusy=false
legsButton.Activated:Connect(function()
	if legsBusy then return end
	legsBusy=true
	addDiag("CLIQUE LOCAL","teste isolado das pernas")
	remote:FireServer("legs")
	legsButton.Text="MEXENDO..."
	task.wait(6.8)
	legsButton.Text="TESTAR PERNAS"
	legsBusy=false
end)

local teleportBusy=false
teleportButton.Activated:Connect(function()
	if teleportBusy then return end
	teleportBusy=true
	addDiag("CLIQUE LOCAL","Red teleporte acionado")
	remote:FireServer("redTeleport")
	teleportButton.Text="RED!"
	task.wait(.6)
	teleportButton.Text="RED TELEPORTE"
	teleportBusy=false
end)
