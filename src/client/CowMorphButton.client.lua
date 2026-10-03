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

local selector=Instance.new("Frame")
selector.Name="CowNumberSelector"
selector.Size=UDim2.fromOffset(238,190)
selector.Position=UDim2.new(0,12,.5,-95)
selector.BackgroundColor3=Color3.fromRGB(14,16,20)
selector.BackgroundTransparency=.12
selector.Visible=false
selector.ZIndex=30
selector.Parent=gui
Instance.new("UICorner",selector).CornerRadius=UDim.new(0,10)
local title=Instance.new("TextLabel")
title.Size=UDim2.new(1,-12,0,24) title.Position=UDim2.fromOffset(6,4)
title.BackgroundTransparency=1 title.Text="PECAS DA VACA" title.TextColor3=Color3.new(1,1,1)
title.Font=Enum.Font.GothamBold title.TextSize=12 title.ZIndex=31 title.Parent=selector
local gridFrame=Instance.new("Frame")
gridFrame.Size=UDim2.new(1,-12,1,-34) gridFrame.Position=UDim2.fromOffset(6,30)
gridFrame.BackgroundTransparency=1 gridFrame.ZIndex=31 gridFrame.Parent=selector
local grid=Instance.new("UIGridLayout")
grid.CellSize=UDim2.fromOffset(28,24) grid.CellPadding=UDim2.fromOffset(4,4)
grid.FillDirectionMaxCells=7 grid.SortOrder=Enum.SortOrder.LayoutOrder grid.Parent=gridFrame
local numberButtons={}
for i=1,34 do
	local n=i
	local b=Instance.new("TextButton")
	b.Name="N"..i b.LayoutOrder=i b.Text=tostring(i)
	b.BackgroundColor3=Color3.fromRGB(45,48,55) b.TextColor3=Color3.fromRGB(150,150,150)
	b.Font=Enum.Font.GothamBold b.TextSize=11 b.ZIndex=32 b.Parent=gridFrame
	Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
	numberButtons[i]=b
	b.Activated:Connect(function() remote:FireServer("number",n) end)
end

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
	if state=="NUMBER" then
		local n=tonumber(message)
		local b=n and numberButtons[n]
		if b then
			b.BackgroundColor3=extra and Color3.fromRGB(35,120,255) or Color3.fromRGB(45,48,55)
			b.TextColor3=extra and Color3.new(1,1,1) or Color3.fromRGB(150,150,150)
		end
		return
	elseif state=="STATUS" then
		status.Text="VACA: "..tostring(message)
		return
	elseif state=="RIG" then
		rigText.Text=tostring(message)
		rigFrame.Visible=true
		return
	elseif state=="ON" then
		selector.Visible=true
		button.Text="VOLTAR NORMAL"
		status.Text="VACA: "..tostring(message)
	elseif state=="OFF" then
		selector.Visible=false
		for _,b in pairs(numberButtons) do b.BackgroundColor3=Color3.fromRGB(45,48,55) b.TextColor3=Color3.fromRGB(150,150,150) end
		button.Text="VIRAR VACA"
		status.Text="VACA: "..tostring(message)
	else
		status.Text="VACA ERRO: "..tostring(message)
	end
end)
