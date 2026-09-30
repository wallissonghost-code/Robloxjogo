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
diagnosticRemote.OnClientEvent:Connect(addDiag)
local button=Instance.new("TextButton")
button.Name="PushSphere"
button.AnchorPoint=Vector2.new(1,1)
button.Size=UDim2.fromOffset(180,56)
button.Position=UDim2.new(1,-22,1,-92)
button.BackgroundColor3=Color3.fromRGB(35,105,255)
button.TextColor3=Color3.new(1,1,1)
button.Font=Enum.Font.GothamBold
button.TextSize=18
button.Text="BLUE CORRIDA 2X"
button.AutoButtonColor=true
button.Parent=gui

local corner=Instance.new("UICorner")
corner.CornerRadius=UDim.new(0,14)
corner.Parent=button

local teleportButton=button:Clone()
teleportButton.Name="TeleportBlue"
teleportButton.Position=UDim2.new(1,-22,1,-24)
teleportButton.Text="GOJO TELEPORTE"
teleportButton.Parent=gui

local busy=false
button.Activated:Connect(function()
	if busy then return end
	busy=true
	addDiag("CLIQUE LOCAL","botao acionado; enviando RemoteEvent")
	remote:FireServer("rush")
	button.Text="CORRENDO!"
	task.wait(.6)
	button.Text="BLUE CORRIDA 2X"
	busy=false
end)


local teleportBusy=false
teleportButton.Activated:Connect(function()
	if teleportBusy then return end
	teleportBusy=true
	addDiag("CLIQUE LOCAL","teleporte acionado; enviando RemoteEvent")
	remote:FireServer("teleport")
	teleportButton.Text="TELEPORTANDO!"
	task.wait(.6)
	teleportButton.Text="GOJO TELEPORTE"
	teleportBusy=false
end)
