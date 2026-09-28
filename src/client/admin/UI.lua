local UI = {}

local function corner(parent, radius)
	local item = Instance.new("UICorner")
	item.CornerRadius = UDim.new(0, radius)
	item.Parent = parent
end

function UI.create(player)
	local gui = Instance.new("ScreenGui")
	gui.Name = "PrivateAdmin"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	local open = Instance.new("TextButton")
	open.Name="AdminButton"; open.AnchorPoint=Vector2.new(1,0); open.Position=UDim2.new(1,-18,0,74); open.Size=UDim2.fromOffset(86,38)
	open.BackgroundColor3=Color3.fromRGB(20,23,27); open.Text="ADMIN"; open.TextColor3=Color3.fromRGB(240,243,246)
	open.Font=Enum.Font.GothamBold; open.TextSize=13; open.AutoButtonColor=false; open.Parent=gui; corner(open,11)
	local os=Instance.new("UIStroke"); os.Color=Color3.fromRGB(255,255,255); os.Transparency=.78; os.Parent=open

	local panel=Instance.new("Frame")
	panel.AnchorPoint=Vector2.new(1,0); panel.Position=UDim2.new(1,-18,0,120); panel.Size=UDim2.fromOffset(260,250)
	panel.BackgroundColor3=Color3.fromRGB(16,18,21); panel.BackgroundTransparency=.04; panel.Visible=false; panel.Parent=gui; corner(panel,16)
	local ps=Instance.new("UIStroke"); ps.Color=Color3.fromRGB(255,255,255); ps.Transparency=.82; ps.Parent=panel

	local title=Instance.new("TextLabel")
	title.Position=UDim2.fromOffset(16,12); title.Size=UDim2.new(1,-32,0,24); title.BackgroundTransparency=1
	title.Text="CONTROLE ADMIN"; title.TextColor3=Color3.fromRGB(238,241,244); title.TextXAlignment=Enum.TextXAlignment.Left
	title.Font=Enum.Font.GothamBold; title.TextSize=14; title.Parent=panel

	local fly=Instance.new("TextButton")
	fly.Position=UDim2.fromOffset(16,48); fly.Size=UDim2.new(1,-32,0,42); fly.BackgroundColor3=Color3.fromRGB(36,40,45)
	fly.Text="VOO  •  OFF"; fly.TextColor3=Color3.fromRGB(238,241,244); fly.Font=Enum.Font.GothamBold; fly.TextSize=13
	fly.AutoButtonColor=false; fly.Parent=panel; corner(fly,11)

	local speedLabel=Instance.new("TextLabel")
	speedLabel.Position=UDim2.fromOffset(16,102); speedLabel.Size=UDim2.new(1,-32,0,20); speedLabel.BackgroundTransparency=1
	speedLabel.Text="VELOCIDADE  70"; speedLabel.TextColor3=Color3.fromRGB(190,196,202); speedLabel.TextXAlignment=Enum.TextXAlignment.Left
	speedLabel.Font=Enum.Font.GothamMedium; speedLabel.TextSize=12; speedLabel.Parent=panel

	local minus=Instance.new("TextButton")
	minus.Position=UDim2.fromOffset(150,98); minus.Size=UDim2.fromOffset(28,28); minus.Text="−"; minus.TextSize=20
	minus.Font=Enum.Font.GothamBold; minus.TextColor3=Color3.new(1,1,1); minus.BackgroundColor3=Color3.fromRGB(36,40,45); minus.Parent=panel; corner(minus,8)
	local plus=minus:Clone(); plus.Text="+"; plus.Position=UDim2.fromOffset(184,98); plus.Parent=panel

	local coords=Instance.new("TextLabel")
	coords.Position=UDim2.fromOffset(16,136); coords.Size=UDim2.new(1,-32,0,34); coords.BackgroundColor3=Color3.fromRGB(25,28,32)
	coords.Text="X: --  Y: --  Z: --"; coords.TextColor3=Color3.fromRGB(225,229,233); coords.Font=Enum.Font.Code; coords.TextSize=12; coords.Parent=panel; corner(coords,9)

	local mark=Instance.new("TextButton")
	mark.Position=UDim2.fromOffset(16,180); mark.Size=UDim2.new(1,-32,0,38); mark.BackgroundColor3=Color3.fromRGB(55,59,65)
	mark.Text="MARCAR POSIÇÃO"; mark.TextColor3=Color3.fromRGB(245,247,249); mark.Font=Enum.Font.GothamBold; mark.TextSize=12
	mark.AutoButtonColor=false; mark.Parent=panel; corner(mark,10)

	open.MouseButton1Click:Connect(function() panel.Visible=not panel.Visible end)
	return { gui=gui, panel=panel, fly=fly, speedLabel=speedLabel, minus=minus, plus=plus, coords=coords, mark=mark }
end

return UI
