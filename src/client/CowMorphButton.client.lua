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

local rigFrame=Instance.new("ScrollingFrame")
rigFrame.Name="CowRigDiagnostic"
rigFrame.Size=UDim2.new(.92,0,.78,0)
rigFrame.Position=UDim2.new(.04,0,.08,0)
rigFrame.BackgroundColor3=Color3.fromRGB(8,10,13)
rigFrame.BackgroundTransparency=.04
rigFrame.BorderSizePixel=0
rigFrame.AutomaticCanvasSize=Enum.AutomaticSize.Y
rigFrame.CanvasSize=UDim2.new()
rigFrame.ScrollBarThickness=7
rigFrame.Visible=false
rigFrame.ZIndex=50
rigFrame.Parent=gui
Instance.new("UICorner",rigFrame).CornerRadius=UDim.new(0,12)

local rigText=Instance.new("TextLabel")
rigText.Size=UDim2.new(1,-24,0,0)
rigText.Position=UDim2.fromOffset(12,48)
rigText.AutomaticSize=Enum.AutomaticSize.Y
rigText.BackgroundTransparency=1
rigText.TextColor3=Color3.new(1,1,1)
rigText.Font=Enum.Font.Code
rigText.TextSize=12
rigText.TextWrapped=false
rigText.TextXAlignment=Enum.TextXAlignment.Left
rigText.TextYAlignment=Enum.TextYAlignment.Top
rigText.ZIndex=51
rigText.Parent=rigFrame

local closeRig=Instance.new("TextButton")
closeRig.Size=UDim2.fromOffset(82,32)
closeRig.Position=UDim2.new(1,-94,0,8)
closeRig.BackgroundColor3=Color3.fromRGB(55,58,64)
closeRig.TextColor3=Color3.new(1,1,1)
closeRig.Font=Enum.Font.GothamBold
closeRig.TextSize=12
closeRig.Text="FECHAR"
closeRig.ZIndex=52
closeRig.Parent=rigFrame
Instance.new("UICorner",closeRig).CornerRadius=UDim.new(0,8)
closeRig.Activated:Connect(function() rigFrame.Visible=false end)


local busy=false
button.Activated:Connect(function()
	if busy then return end
	busy=true
	status.Text="VACA: transformando..."
	remote:FireServer("toggle")
	task.delay(1,function() busy=false end)
end)

remote.OnClientEvent:Connect(function(state,message,extra)
	busy=false
	if state=="STATUS" then
		status.Text="VACA: "..tostring(message)
		return
	elseif state=="RIG" then
		rigText.Text=tostring(message)
		rigFrame.Visible=true
		return
	elseif state=="ON" then
		button.Text="VOLTAR NORMAL"
		status.Text="VACA: "..tostring(message)
	elseif state=="OFF" then
		button.Text="VIRAR VACA"
		status.Text="VACA: "..tostring(message)
	else
		status.Text="VACA ERRO: "..tostring(message)
	end
end)
