local Players = game:GetService("Players")

local BUILD_VERSION = "V10"
local ASSET_ID = 119678628566456
local ATM_NAME = "QuarantinedATM_" .. ASSET_ID

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "BuildDiagnostic"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10000
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Name = "OpenDiagnostic"
button.Size = UDim2.fromOffset(118, 34)
button.Position = UDim2.fromOffset(12, 12)
button.BackgroundColor3 = Color3.fromRGB(24,24,28)
button.TextColor3 = Color3.fromRGB(235,235,240)
button.Text = "DIAGNOSTICO"
button.TextSize = 12
button.Font = Enum.Font.GothamBold
button.BorderSizePixel = 0
button.Parent = gui
local bc=Instance.new("UICorner"); bc.CornerRadius=UDim.new(0,9); bc.Parent=button

local panel=Instance.new("Frame")
panel.Size=UDim2.fromOffset(330,310)
panel.Position=UDim2.fromOffset(12,54)
panel.BackgroundColor3=Color3.fromRGB(16,16,19)
panel.BackgroundTransparency=.04
panel.BorderSizePixel=0
panel.Visible=false
panel.Parent=gui
local pc=Instance.new("UICorner"); pc.CornerRadius=UDim.new(0,12); pc.Parent=panel

local title=Instance.new("TextLabel")
title.BackgroundTransparency=1
title.Position=UDim2.fromOffset(14,10)
title.Size=UDim2.new(1,-28,0,30)
title.Font=Enum.Font.GothamBold
title.TextSize=22
title.TextColor3=Color3.fromRGB(255,211,74)
title.TextXAlignment=Enum.TextXAlignment.Left
title.Text="BUILD "..BUILD_VERSION
title.Parent=panel

local info=Instance.new("TextLabel")
info.BackgroundTransparency=1
info.Position=UDim2.fromOffset(14,44)
info.Size=UDim2.new(1,-28,1,-112)
info.Font=Enum.Font.Code
info.TextSize=13
info.TextColor3=Color3.fromRGB(225,225,230)
info.TextWrapped=true
info.TextXAlignment=Enum.TextXAlignment.Left
info.TextYAlignment=Enum.TextYAlignment.Top
info.Parent=panel

local reportText = ""

local function refresh()
	local atm=workspace:FindFirstChild(ATM_NAME)
	if not atm then
		info.Text="ATM LOADER: NAO ENCONTRADO\n\nNome esperado:\n"..ATM_NAME.."\n\nSe existe outro caixa visivel no mapa, ele NAO e a instancia carregada pelo nosso script."
		return
	end
	local parts=0
	for _,v in ipairs(atm:GetDescendants()) do
		if v:IsA("BasePart") then parts+=1 end
	end
	local minX,minY,minZ=math.huge,math.huge,math.huge
	local maxX,maxY,maxZ=-math.huge,-math.huge,-math.huge
	for _,v in ipairs(atm:GetDescendants()) do
		if v:IsA("BasePart") then
			local half=v.Size*0.5
			local p=v.Position
			minX=math.min(minX,p.X-half.X); maxX=math.max(maxX,p.X+half.X)
			minY=math.min(minY,p.Y-half.Y); maxY=math.max(maxY,p.Y+half.Y)
			minZ=math.min(minZ,p.Z-half.Z); maxZ=math.max(maxZ,p.Z+half.Z)
		end
	end
	local pos=Vector3.new((minX+maxX)/2,(minY+maxY)/2,(minZ+maxZ)/2)
	local bottomY=minY
	local topY=maxY
	reportText = table.concat({
		"BUILD " .. BUILD_VERSION,
		"ATM LOADER: ENCONTRADO",
		"Asset: " .. tostring(ASSET_ID),
		string.format("Centro visual: X %.2f | Y %.2f | Z %.2f", pos.X, pos.Y, pos.Z),
		string.format("BottomY: %.2f", bottomY),
		string.format("TopY: %.2f", topY),
		"Partes: " .. tostring(parts),
		"Scripts desativados: " .. tostring(atm:GetAttribute("DisabledScriptCount")),
		"Interacoes: " .. tostring(atm:GetAttribute("InteractionCount")),
		"Quarentena: " .. tostring(atm:GetAttribute("Quarantined"))
	}, "\n")
	info.Text=reportText
end

local copyBox=Instance.new("TextBox")
copyBox.Name="CopyDiagnostic"
copyBox.Position=UDim2.new(0,14,1,-52)
copyBox.Size=UDim2.new(1,-28,0,38)
copyBox.BackgroundColor3=Color3.fromRGB(35,35,41)
copyBox.TextColor3=Color3.fromRGB(255,255,255)
copyBox.PlaceholderText="COPIAR DIAGNOSTICO"
copyBox.Text="COPIAR DIAGNOSTICO"
copyBox.ClearTextOnFocus=true
copyBox.MultiLine=true
copyBox.TextEditable=true
copyBox.Font=Enum.Font.GothamBold
copyBox.TextSize=12
copyBox.BorderSizePixel=0
copyBox.Parent=panel
local cc=Instance.new("UICorner"); cc.CornerRadius=UDim.new(0,9); cc.Parent=copyBox

copyBox.Focused:Connect(function()
	refresh()
	copyBox.Text=reportText
	copyBox.CursorPosition=1
	copyBox.SelectionStart=#reportText+1
end)

copyBox.FocusLost:Connect(function()
	copyBox.Text="COPIAR DIAGNOSTICO"
end)

button.Activated:Connect(function()
	panel.Visible=not panel.Visible
	button.Text=panel.Visible and "FECHAR" or "DIAGNOSTICO"
	if panel.Visible then refresh() end
end)
