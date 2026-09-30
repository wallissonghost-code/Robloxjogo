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
diag.Size=UDim2.new(.94,0,0,190)
diag.Position=UDim2.new(.03,0,.05,0)
diag.BackgroundColor3=Color3.fromRGB(10,12,16)
diag.BackgroundTransparency=.08
diag.TextColor3=Color3.new(1,1,1)
diag.TextWrapped=true
diag.TextXAlignment=Enum.TextXAlignment.Left
diag.TextYAlignment=Enum.TextYAlignment.Top
diag.Font=Enum.Font.Code
diag.TextSize=14
diag.Text="GOJO DIAGNOSTICO\nAguardando clique..."
diag.Parent=gui
local dc=Instance.new("UICorner"); dc.CornerRadius=UDim.new(0,10); dc.Parent=diag
local history={}
local function addDiag(step,message)
	table.insert(history,os.date("%H:%M:%S").."  "..step.."  "..message)
	while #history>8 do table.remove(history,1) end
	diag.Text="GOJO DIAGNOSTICO\n"..table.concat(history,"\n")
end
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
button.Size=UDim2.fromOffset(180,56)
button.Position=UDim2.new(1,-22,1,-92)
button.BackgroundColor3=Color3.fromRGB(35,105,255)
button.TextColor3=Color3.new(1,1,1)
button.Font=Enum.Font.GothamBold
button.TextSize=18
button.Text="BLUE ARREMESSAR"
button.AutoButtonColor=true
button.Parent=gui

local corner=Instance.new("UICorner")
corner.CornerRadius=UDim.new(0,14)
corner.Parent=button

local teleportButton=button:Clone()
teleportButton.Name="RedRush"
teleportButton.Position=UDim2.new(1,-22,1,-24)
teleportButton.Text="RED CORRIDA"
teleportButton.Parent=gui

local busy=false
button.Activated:Connect(function()
	if busy then return end
	busy=true
	addDiag("CLIQUE LOCAL","botao acionado; enviando RemoteEvent")
	remote:FireServer("blueThrow")
	button.Text="LANCANDO!"
	task.wait(.6)
	button.Text="BLUE ARREMESSAR"
	busy=false
end)


local redThrowButton=button:Clone()
redThrowButton.Name="RedThrow"
redThrowButton.Position=UDim2.new(1,-214,1,-24)
redThrowButton.Text="RED ARREMESSAR"
redThrowButton.BackgroundColor3=Color3.fromRGB(210,35,45)
redThrowButton.Parent=gui
redThrowButton.Activated:Connect(function()
	addDiag("CLIQUE LOCAL","Red arremessado")
	remote:FireServer("redThrow")
end)

local rigButton=button:Clone()
rigButton.Name="RigDiagnostic"
rigButton.Position=UDim2.new(0,22,1,-24)
rigButton.AnchorPoint=Vector2.new(0,1)
rigButton.Text="DIAGNOSTICO GERAL"
rigButton.Parent=gui
rigButton.Activated:Connect(function()
	addDiag("DIAGNOSTICO","solicitando mapa completo do rig")
	remote:FireServer("diagnostic")
end)

local legsButton=button:Clone()
legsButton.Name="LegsTest"
legsButton.Position=UDim2.new(1,-22,1,-160)
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
	addDiag("CLIQUE LOCAL","teleporte acionado; enviando RemoteEvent")
	remote:FireServer("redRush")
	teleportButton.Text="RED RUSH!"
	task.wait(.6)
	teleportButton.Text="RED CORRIDA"
	teleportBusy=false
end)
