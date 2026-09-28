local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local bootstrap = playerGui:FindFirstChild("WorldBootstrap")
local remotes = ReplicatedStorage:WaitForChild("WorldRemotes")
local getWorlds = remotes:WaitForChild("GetWorlds")
local joinWorld = remotes:WaitForChild("JoinWorld")

local ok, payload = pcall(function() return getWorlds:InvokeServer() end)
if not ok or type(payload) ~= "table" then
	if bootstrap then bootstrap:Destroy() end
	return
end
if payload.inWorld then
	if bootstrap then bootstrap:Destroy() end
	return
end

local gui = Instance.new("ScreenGui")
gui.Name = "WorldBrowser"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000
gui.Parent = playerGui

local bg = Instance.new("Frame")
bg.Size = UDim2.fromScale(1,1)
bg.BackgroundColor3 = Color3.fromRGB(7,10,8)
bg.BorderSizePixel = 0
bg.Parent = gui

if bootstrap then
	bootstrap:Destroy()
	bootstrap = nil
end

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(.5,.5)
panel.Position = UDim2.fromScale(.5,.5)
panel.Size = UDim2.new(.9,0,.84,0)
panel.BackgroundTransparency = 1
panel.Parent = bg
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(720,700)
limit.MinSize = Vector2.new(300,420)
limit.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,44)
title.BackgroundTransparency = 1
title.Text = "ESCOLHA SEU MUNDO"
title.TextColor3 = Color3.fromRGB(240,246,242)
title.Font = Enum.Font.GothamBold
title.TextSize = 26
title.Parent = panel

local sub = Instance.new("TextLabel")
sub.Position = UDim2.fromOffset(0,48)
sub.Size = UDim2.new(1,0,0,24)
sub.BackgroundTransparency = 1
sub.Text = "Até 10 jogadores ativos por mundo"
sub.TextColor3 = Color3.fromRGB(137,153,143)
sub.Font = Enum.Font.Gotham
sub.TextSize = 14
sub.Parent = panel

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(0,88)
list.Size = UDim2.new(1,0,1,-122)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 0
list.ScrollingDirection = Enum.ScrollingDirection.Y
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.fromOffset(0,0)
list.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
list.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,12)
layout.Parent = list

local status = Instance.new("TextLabel")
status.AnchorPoint = Vector2.new(.5,1)
status.Position = UDim2.new(.5,0,1,0)
status.Size = UDim2.new(1,0,0,24)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(190,200,193)
status.Font = Enum.Font.Gotham
status.TextSize = 13
status.Parent = panel

local busy = false
local cards = {}

local function cardFor(world)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1,0,0,80)
	button.BackgroundColor3 = Color3.fromRGB(18,24,20)
	button.BorderSizePixel = 0
	button.Text = ""
	button.AutoButtonColor = false
	button.Parent = list
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0,12)
	corner.Parent = button
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(47,62,52)
	stroke.Parent = button

	local name = Instance.new("TextLabel")
	name.Position = UDim2.fromOffset(18,12)
	name.Size = UDim2.new(.6,0,0,27)
	name.BackgroundTransparency = 1
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Text = world.name
	name.TextColor3 = Color3.fromRGB(240,246,242)
	name.Font = Enum.Font.GothamBold
	name.TextSize = 20
	name.Parent = button

	local visited = Instance.new("TextLabel")
	visited.AnchorPoint = Vector2.new(1,0)
	visited.Position = UDim2.new(1,-138,0,13)
	visited.Size = UDim2.fromOffset(120,22)
	visited.BackgroundTransparency = 1
	visited.TextXAlignment = Enum.TextXAlignment.Right
	visited.TextColor3 = Color3.fromRGB(143,166,150)
	visited.Font = Enum.Font.GothamBold
	visited.TextSize = 10
	visited.Parent = button

	local count = Instance.new("TextLabel")
	count.Position = UDim2.fromOffset(18,43)
	count.Size = UDim2.new(.6,0,0,20)
	count.BackgroundTransparency = 1
	count.TextXAlignment = Enum.TextXAlignment.Left
	count.Font = Enum.Font.GothamMedium
	count.TextSize = 14
	count.Parent = button

	local action = Instance.new("TextLabel")
	action.AnchorPoint = Vector2.new(1,.5)
	action.Position = UDim2.new(1,-16,.5,0)
	action.Size = UDim2.fromOffset(104,40)
	action.BorderSizePixel = 0
	action.Font = Enum.Font.GothamBold
	action.TextSize = 13
	action.Parent = button
	local ac = Instance.new("UICorner")
	ac.CornerRadius = UDim.new(0,9)
	ac.Parent = action

	local function render(data)
		local full = data.players >= data.maxPlayers
		count.Text = string.format("%d/%d JOGADORES",data.players,data.maxPlayers)
		if type(data.lastJoined) == "number" then
			local elapsed = math.max(0, os.time() - data.lastJoined)
			local when
			if elapsed < 60 then when = "AGORA"
			elseif elapsed < 3600 then when = tostring(math.floor(elapsed/60)).." MIN"
			elseif elapsed < 86400 then when = tostring(math.floor(elapsed/3600)).." H"
			else when = tostring(math.floor(elapsed/86400)).." D" end
			visited.Text = "ÚLTIMA ENTRADA · "..when
		else
			visited.Text = ""
		end
		count.TextColor3 = full and Color3.fromRGB(255,120,120) or Color3.fromRGB(105,235,145)
		action.Text = full and "LOTADO" or "ENTRAR"
		action.BackgroundColor3 = full and Color3.fromRGB(48,48,48) or Color3.fromRGB(88,255,135)
		action.TextColor3 = full and Color3.fromRGB(150,150,150) or Color3.fromRGB(6,20,10)
		button.Active = not full
	end
	render(world)
	cards[world.id] = render

	button.Activated:Connect(function()
		if busy or not button.Active then return end
		busy = true
		status.Text = "Entrando em "..world.name.."..."
		local transition = Instance.new("Frame")
		transition.Name = "Transition"
		transition.Size = UDim2.fromScale(1,1)
		transition.BackgroundColor3 = Color3.fromRGB(7,10,8)
		transition.BorderSizePixel = 0
		transition.ZIndex = 5000
		transition.Parent = gui
		local callOk,result = pcall(function() return joinWorld:InvokeServer(world.id) end)
		if not callOk or type(result) ~= "table" or not result.ok then
			status.Text = type(result)=="table" and result.message or "Não foi possível entrar agora."
			local transition = gui:FindFirstChild("Transition")
			if transition then transition:Destroy() end
			busy = false
		end
	end)
end

for _,world in ipairs(payload.worlds or {}) do cardFor(world) end

task.spawn(function()
	while gui.Parent do
		task.wait(8)
		if busy then continue end
		local refreshedOk,refreshed = pcall(function() return getWorlds:InvokeServer() end)
		if refreshedOk and type(refreshed)=="table" then
			for _,world in ipairs(refreshed.worlds or {}) do
				if cards[world.id] then cards[world.id](world) end
			end
		end
	end
end)
