local Players = game:GetService("Players")

local player = Players.LocalPlayer
local ATM_NAME = "QuarantinedATM_119678628566456"

local gui = Instance.new("ScreenGui")
gui.Name = "SafeATMGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 500
gui.Parent = player:WaitForChild("PlayerGui")

local overlay = Instance.new("Frame")
overlay.Size = UDim2.fromScale(1,1)
overlay.BackgroundColor3 = Color3.new(0,0,0)
overlay.BackgroundTransparency = 0.35
overlay.Visible = false
overlay.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(.5,.5)
panel.Position = UDim2.fromScale(.5,.5)
panel.Size = UDim2.new(.88,0,0,310)
panel.BackgroundColor3 = Color3.fromRGB(17,19,22)
panel.BorderSizePixel = 0
panel.Parent = overlay
local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,16); corner.Parent=panel

local title=Instance.new("TextLabel")
title.BackgroundTransparency=1
title.Position=UDim2.fromOffset(20,18)
title.Size=UDim2.new(1,-80,0,32)
title.Font=Enum.Font.GothamBold
title.TextSize=24
title.TextColor3=Color3.fromRGB(255,211,74)
title.TextXAlignment=Enum.TextXAlignment.Left
title.Text="CAIXA ELETRONICO"
title.Parent=panel

local close=Instance.new("TextButton")
close.AnchorPoint=Vector2.new(1,0)
close.Position=UDim2.new(1,-16,0,16)
close.Size=UDim2.fromOffset(40,40)
close.BackgroundColor3=Color3.fromRGB(40,42,48)
close.Text="X"
close.TextColor3=Color3.new(1,1,1)
close.Font=Enum.Font.GothamBold
close.TextSize=16
close.BorderSizePixel=0
close.Parent=panel
local cc=Instance.new("UICorner"); cc.CornerRadius=UDim.new(0,10); cc.Parent=close

local balance=Instance.new("TextLabel")
balance.BackgroundTransparency=1
balance.Position=UDim2.fromOffset(20,70)
balance.Size=UDim2.new(1,-40,0,70)
balance.Font=Enum.Font.GothamBold
balance.TextSize=30
balance.TextColor3=Color3.new(1,1,1)
balance.TextXAlignment=Enum.TextXAlignment.Left
balance.Parent=panel

local note=Instance.new("TextLabel")
note.BackgroundTransparency=1
note.Position=UDim2.fromOffset(20,150)
note.Size=UDim2.new(1,-40,0,100)
note.Font=Enum.Font.Gotham
note.TextSize=15
note.TextColor3=Color3.fromRGB(190,193,200)
note.TextWrapped=true
note.TextXAlignment=Enum.TextXAlignment.Left
note.TextYAlignment=Enum.TextYAlignment.Top
note.Text="ATM SEGURO V8\nInterface propria do jogo. Os 3 scripts originais do modelo continuam desativados."
note.Parent=panel

local gold=player:WaitForChild("leaderstats"):WaitForChild("Ouro")
local function refreshBalance()
	balance.Text="SALDO: "..tostring(gold.Value).." OURO"
end
refreshBalance()
gold:GetPropertyChangedSignal("Value"):Connect(refreshBalance)

close.Activated:Connect(function() overlay.Visible=false end)

local connected={}
local function connectPrompt(prompt)
	if connected[prompt] then return end
	connected[prompt]=true
	prompt.Triggered:Connect(function(triggeringPlayer)
		-- On the client, only react to this player's prompt.
		if triggeringPlayer == nil or triggeringPlayer == player then
			refreshBalance()
			overlay.Visible=true
		end
	end)
end

local function scan()
	local atm=workspace:FindFirstChild(ATM_NAME)
	if not atm then return end
	for _,obj in ipairs(atm:GetDescendants()) do
		if obj:IsA("ProximityPrompt") then connectPrompt(obj) end
	end
end

scan()
workspace.ChildAdded:Connect(function(child)
	if child.Name==ATM_NAME then
		task.wait(.25)
		scan()
	end
end)
