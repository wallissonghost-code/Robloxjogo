local Players = game:GetService("Players")

local BUILD_VERSION = "V81"
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
panel.Size=UDim2.fromOffset(280,330)
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
title.TextSize=16
title.TextColor3=Color3.fromRGB(255,211,74)
title.TextXAlignment=Enum.TextXAlignment.Left
title.Text="BUILD "..BUILD_VERSION
title.Parent=panel

local info=Instance.new("TextLabel")
info.BackgroundTransparency=1
info.Position=UDim2.fromOffset(14,40)
info.Size=UDim2.new(1,-28,0,150)
info.Font=Enum.Font.Code
info.TextSize=10
info.TextColor3=Color3.fromRGB(225,225,230)
info.TextWrapped=true
info.TextXAlignment=Enum.TextXAlignment.Left
info.TextYAlignment=Enum.TextYAlignment.Top
info.Parent=panel

local reportText = ""
local atmOpenReceived = 0
local traceOpenEvent = game:GetService("ReplicatedStorage"):WaitForChild("ATMOpen",10)
if traceOpenEvent then traceOpenEvent.OnClientEvent:Connect(function() atmOpenReceived += 1 end) end

local function refresh()
	local atm=workspace:FindFirstChild(ATM_NAME)
	if not atm then
		info.Text="ATM LOADER: NAO ENCONTRADO\n\nNome esperado:\n"..ATM_NAME.."\n\nSe existe outro caixa visivel no mapa, ele NAO e a instancia carregada pelo nosso script."
		return
	end
	local atmGui=player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("SafeATMGui")
	local guiChildren={}
	local guiDescendants=0
	if atmGui then
		for _,v in ipairs(atmGui:GetChildren()) do
			table.insert(guiChildren, v.Name..":"..v.ClassName)
		end
		guiDescendants=#atmGui:GetDescendants()
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
		"Quarentena: " .. tostring(atm:GetAttribute("Quarantined")),
		"Prompt seguro: " .. tostring(atm:GetAttribute("SafePromptReady")),
		"Server build: " .. tostring(atm:GetAttribute("ServerBuild")),
		"ATMOpen: " .. tostring(game:GetService("ReplicatedStorage"):FindFirstChild("ATMOpen") ~= nil),
		"ATMTransaction: " .. tostring(game:GetService("ReplicatedStorage"):FindFirstChild("ATMTransaction") ~= nil),
		"InteractionPart: " .. tostring(atm:FindFirstChild("SafeATMInteraction", true) ~= nil),
		"SafePrompt client: " .. tostring(atm:FindFirstChild("SafeATMPrompt", true) ~= nil),
		"Prompt enabled: " .. tostring((atm:FindFirstChild("SafeATMPrompt", true) and atm:FindFirstChild("SafeATMPrompt", true).Enabled) or false),
		"leaderstats: " .. tostring(player:FindFirstChild("leaderstats") ~= nil),
		"Ouro: " .. tostring(player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Ouro") ~= nil),
		"Banco: " .. tostring(player:FindFirstChild("Banco") ~= nil),
		"PlayerScripts: " .. tostring(player:FindFirstChild("PlayerScripts") ~= nil),
		"SafeATM script: " .. tostring(player:FindFirstChild("PlayerScripts") and player.PlayerScripts:FindFirstChild("SafeATM") ~= nil),
		"SafeATM disabled: " .. tostring(player:FindFirstChild("PlayerScripts") and player.PlayerScripts:FindFirstChild("SafeATM") and player.PlayerScripts.SafeATM.Disabled or "N/A"),
		"SafeATMGui: " .. tostring(atmGui ~= nil),
		"GUI filhos: " .. tostring(atmGui and #atmGui:GetChildren() or 0),
		"GUI descendentes: " .. tostring(guiDescendants),
		"GUI lista: " .. (#guiChildren > 0 and table.concat(guiChildren,", ") or "VAZIA"),
		"ATMPanel: " .. tostring(atmGui and atmGui:FindFirstChild("ATMPanel") ~= nil),
		"Fallback V21: " .. tostring(atmGui and atmGui:FindFirstChild("ATMV21Fallback") ~= nil),
		"Prompt Triggered: " .. tostring(atm:GetAttribute("PromptTriggerCount") or 0),
		"ATMOpen enviado: " .. tostring(atm:GetAttribute("ATMOpenFireCount") or 0),
		"ATMOpen recebido: " .. tostring(atmOpenReceived),
		"--- PULO MOBILE ---",
		"TouchEnabled: " .. tostring(game:GetService("UserInputService").TouchEnabled),
		"CustomJump script: " .. tostring(player:FindFirstChild("PlayerScripts") and player.PlayerScripts:FindFirstChild("CustomJump") ~= nil),
		"CustomJumpHUD: " .. tostring(player.PlayerGui:FindFirstChild("CustomJumpHUD") ~= nil),
		"Nosso JumpButton: " .. tostring(player.PlayerGui:FindFirstChild("CustomJumpHUD") and player.PlayerGui.CustomJumpHUD:FindFirstChild("CustomJumpButton") ~= nil),
		"TouchGui: " .. tostring(player.PlayerGui:FindFirstChild("TouchGui") ~= nil),
		"Jump nativo: " .. tostring(player.PlayerGui:FindFirstChild("TouchGui") and player.PlayerGui.TouchGui:FindFirstChild("JumpButton",true) ~= nil)
	}, "\n")
	info.Text=reportText
end

local adjust=Instance.new("Frame")
adjust.Position=UDim2.fromOffset(14,198)
adjust.Size=UDim2.new(1,-28,0,76)
adjust.BackgroundColor3=Color3.fromRGB(28,28,33)
adjust.BorderSizePixel=0
adjust.Parent=panel
local ac=Instance.new("UICorner");ac.CornerRadius=UDim.new(0,8);ac.Parent=adjust
local coord=Instance.new("TextLabel");coord.BackgroundTransparency=1;coord.Position=UDim2.fromOffset(6,3);coord.Size=UDim2.new(1,-12,0,18);coord.TextColor3=Color3.fromRGB(255,211,74);coord.Font=Enum.Font.GothamBold;coord.TextSize=10;coord.Parent=adjust
local function hudFrame()local g=player.PlayerGui:FindFirstChild("GoldHUD");return g and g:FindFirstChild("SettingsButton")end
local function updateCoord()local h=hudFrame();coord.Text=h and ("CONFIG X "..tostring(h:GetAttribute("HUDX") or -87).."  Y "..tostring(h:GetAttribute("HUDY") or 0)) or "HUD indisponivel"end
local function move(dx,dy,save)local g=player.PlayerGui:FindFirstChild("GoldHUD");local e=g and g:FindFirstChild("SettingsMove");if e then e:Fire(dx,dy);task.delay(.05,updateCoord)end end
local defs={{"←",-5,0},{"→",5,0},{"↑",0,-5},{"↓",0,5}}
for i,d in ipairs(defs) do local b=Instance.new("TextButton");b.Position=UDim2.fromOffset(6+(i-1)*45,27);b.Size=UDim2.fromOffset(39,25);b.BackgroundColor3=Color3.fromRGB(48,48,56);b.Text=d[1];b.TextColor3=Color3.new(1,1,1);b.Font=Enum.Font.GothamBold;b.TextSize=14;b.BorderSizePixel=0;b.Parent=adjust;local cc=Instance.new("UICorner");cc.CornerRadius=UDim.new(0,6);cc.Parent=b;b.Activated:Connect(function()move(d[2],d[3],false)end)end
local save=Instance.new("TextButton");save.Position=UDim2.new(1,-62,0,27);save.Size=UDim2.fromOffset(56,25);save.BackgroundColor3=Color3.fromRGB(255,199,47);save.TextColor3=Color3.fromRGB(20,20,20);save.Text="FIXAR";save.Font=Enum.Font.GothamBold;save.TextSize=9;save.BorderSizePixel=0;save.Parent=adjust;local sc=Instance.new("UICorner");sc.CornerRadius=UDim.new(0,6);sc.Parent=save
save.Activated:Connect(function()move(0,0,true)end)

local copyBox=Instance.new("TextBox")
copyBox.Name="CopyDiagnostic"
copyBox.Position=UDim2.new(0,14,1,-42)
copyBox.Size=UDim2.new(1,-28,0,30)
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
	if panel.Visible then refresh();updateCoord() end
end)
