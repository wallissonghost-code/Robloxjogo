local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local player=Players.LocalPlayer
local remote=ReplicatedStorage:WaitForChild("CowMorphToggle")

local gui=Instance.new("ScreenGui")
gui.Name="CowMorphGui"
gui.ResetOnSpawn=false
gui.Parent=player:WaitForChild("PlayerGui")

local button=Instance.new("TextButton")
button.Name="CowButton"
button.AnchorPoint=Vector2.new(0,1)
button.Size=UDim2.fromOffset(112,42)
button.Position=UDim2.new(0,18,1,-22)
button.BackgroundColor3=Color3.fromRGB(35,35,35)
button.TextColor3=Color3.new(1,1,1)
button.Font=Enum.Font.GothamBold
button.TextSize=14
button.Text="VIRAR VACA"
button.AutoButtonColor=true
button.Parent=gui

local corner=Instance.new("UICorner")
corner.CornerRadius=UDim.new(0,10)
corner.Parent=button

local stroke=Instance.new("UIStroke")
stroke.Thickness=1.5
stroke.Transparency=.35
stroke.Parent=button

local status=Instance.new("TextLabel")
status.AnchorPoint=Vector2.new(0,1)
status.Size=UDim2.fromOffset(230,26)
status.Position=UDim2.new(0,18,1,-68)
status.BackgroundTransparency=1
status.TextColor3=Color3.new(1,1,1)
status.TextStrokeTransparency=.45
status.Font=Enum.Font.Code
status.TextSize=11
status.TextXAlignment=Enum.TextXAlignment.Left
status.Text="VACA: pronta"
status.Parent=gui

local busy=false
button.Activated:Connect(function()
	if busy then return end
	busy=true
	status.Text="VACA: transformando..."
	remote:FireServer("toggle")
	task.delay(1,function() busy=false end)
end)

remote.OnClientEvent:Connect(function(state,message)
	busy=false
	if state=="ON" then
		button.Text="VOLTAR NORMAL"
		status.Text="VACA: "..tostring(message)
	elseif state=="OFF" then
		button.Text="VIRAR VACA"
		status.Text="VACA: "..tostring(message)
	else
		status.Text="VACA ERRO: "..tostring(message)
	end
end)
