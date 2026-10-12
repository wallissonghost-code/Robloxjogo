local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local GuiService = game:GetService("GuiService")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "GoldHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ScreenInsets = Enum.ScreenInsets.None
gui.ClipToDeviceSafeArea = false
gui.DisplayOrder = 20
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "Balance"
frame.AnchorPoint = Vector2.new(1, 0)
frame.Position = UDim2.new(1, 0, 0, 6)
frame.Size = UDim2.fromOffset(112, 38)
frame.BackgroundColor3 = Color3.fromRGB(13, 15, 18)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(72, 76, 84)
stroke.Transparency = 0.45
stroke.Thickness = 1
stroke.Parent = frame

local coin = Instance.new("Frame")
coin.Name = "Coin"
coin.AnchorPoint = Vector2.new(0, 0.5)
coin.Position = UDim2.new(0, 10, 0.5, 0)
coin.Size = UDim2.fromOffset(16, 16)
coin.BackgroundColor3 = Color3.fromRGB(255, 199, 47)
coin.BorderSizePixel = 0
coin.Parent = frame

local coinCorner = Instance.new("UICorner")
coinCorner.CornerRadius = UDim.new(1, 0)
coinCorner.Parent = coin

local coinInner = Instance.new("Frame")
coinInner.AnchorPoint = Vector2.new(0.5, 0.5)
coinInner.Position = UDim2.fromScale(0.5, 0.5)
coinInner.Size = UDim2.fromOffset(7, 7)
coinInner.BackgroundTransparency = 1
coinInner.BorderSizePixel = 0
coinInner.Parent = coin
local coinStroke = Instance.new("UIStroke")
coinStroke.Color = Color3.fromRGB(126, 88, 12)
coinStroke.Thickness = 1.5
coinStroke.Parent = coinInner
local coinInnerCorner = Instance.new("UICorner")
coinInnerCorner.CornerRadius = UDim.new(1, 0)
coinInnerCorner.Parent = coinInner

local amount = Instance.new("TextLabel")
amount.BackgroundTransparency = 1
amount.Position = UDim2.fromOffset(34, 0)
amount.Size = UDim2.new(1, -44, 1, 0)
amount.Font = Enum.Font.GothamBold
amount.TextColor3 = Color3.fromRGB(255, 211, 74)
amount.TextSize = 17
amount.TextXAlignment = Enum.TextXAlignment.Left
amount.TextYAlignment = Enum.TextYAlignment.Center
amount.Parent = frame


local hudRemote=RS:WaitForChild("HUDPosition")
local hudX,hudY=0,-4
local ok,got,x,y=pcall(function() return hudRemote:InvokeServer("get") end)
if ok and got then hudX=math.min(x or 0,0);hudY=y or -4 end

local function applyPosition()
	frame.Position=UDim2.new(1,hudX,0,hudY)
	frame:SetAttribute("HUDX",hudX)
	frame:SetAttribute("HUDY",hudY)
end
applyPosition()

local function moveEvent()
	local ev=gui:FindFirstChild("HUDMove") or Instance.new("BindableEvent")
	ev.Name="HUDMove";ev.Parent=gui
	return ev
end
local mover=moveEvent()
mover.Event:Connect(function(dx,dy,save)
	hudX=math.clamp(hudX+dx,-500,500);hudY=math.clamp(hudY+dy,-100,500);applyPosition()
	if save then
		local sok,saved,sx,sy=pcall(function()return hudRemote:InvokeServer("save",hudX,hudY)end)
		if sok and saved then hudX=sx;hudY=sy;applyPosition() end
	end
end)

-- V41 settings launcher (drawn with Roblox UI; no emoji/image dependency)
local settingsButton=Instance.new("TextButton")
settingsButton.Name="SettingsButton"
settingsButton.AnchorPoint=Vector2.new(1,0)
settingsButton.Position=UDim2.new(0,-6,0,0)
settingsButton.Size=UDim2.fromOffset(38,38)
settingsButton.BackgroundColor3=Color3.fromRGB(13,15,18)
settingsButton.Text=""
settingsButton.BorderSizePixel=0
settingsButton.Parent=frame
local sbc=Instance.new("UICorner");sbc.CornerRadius=UDim.new(0,10);sbc.Parent=settingsButton
local sbs=Instance.new("UIStroke");sbs.Color=Color3.fromRGB(255,194,45);sbs.Transparency=.25;sbs.Thickness=1;sbs.Parent=settingsButton

local gear=Instance.new("Frame")
gear.AnchorPoint=Vector2.new(.5,.5);gear.Position=UDim2.fromScale(.5,.5);gear.Size=UDim2.fromOffset(18,18)
gear.BackgroundColor3=Color3.fromRGB(255,199,47);gear.BorderSizePixel=0;gear.Parent=settingsButton
local gc=Instance.new("UICorner");gc.CornerRadius=UDim.new(1,0);gc.Parent=gear
local hole=Instance.new("Frame");hole.AnchorPoint=Vector2.new(.5,.5);hole.Position=UDim2.fromScale(.5,.5);hole.Size=UDim2.fromOffset(7,7);hole.BackgroundColor3=Color3.fromRGB(13,15,18);hole.BorderSizePixel=0;hole.Parent=gear
local hc=Instance.new("UICorner");hc.CornerRadius=UDim.new(1,0);hc.Parent=hole
for i=0,7 do
 local tooth=Instance.new("Frame");tooth.AnchorPoint=Vector2.new(.5,.5);tooth.Position=UDim2.fromScale(.5,.5);tooth.Size=UDim2.fromOffset(4,24);tooth.Rotation=i*45;tooth.BackgroundColor3=Color3.fromRGB(255,199,47);tooth.BorderSizePixel=0;tooth.ZIndex=gear.ZIndex-1;tooth.Parent=settingsButton
end
gear.ZIndex=3;hole.ZIndex=4

local settingsPanel=Instance.new("Frame")
settingsPanel.Name="SettingsPanel";settingsPanel.AnchorPoint=Vector2.new(1,0);settingsPanel.Position=UDim2.new(1,0,0,44)
settingsPanel.Size=UDim2.fromOffset(270,176);settingsPanel.BackgroundColor3=Color3.fromRGB(10,12,16);settingsPanel.BorderSizePixel=0;settingsPanel.Visible=false;settingsPanel.Parent=gui
local spc=Instance.new("UICorner");spc.CornerRadius=UDim.new(0,12);spc.Parent=settingsPanel
local sps=Instance.new("UIStroke");sps.Color=Color3.fromRGB(222,166,36);sps.Transparency=.18;sps.Thickness=1.3;sps.Parent=settingsPanel
local function stxt(t,p,z,size,bold,col)
 local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Position=p;l.Size=z;l.Text=t;l.TextColor3=col or Color3.fromRGB(238,240,244);l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham;l.TextSize=size;l.TextXAlignment=Enum.TextXAlignment.Left;l.Parent=settingsPanel;return l
end
stxt("CONFIGURAÇÕES",UDim2.fromOffset(16,12),UDim2.new(1,-32,0,24),17,true)
stxt("HUD • posição do Ouro",UDim2.fromOffset(16,34),UDim2.new(1,-32,0,18),10,false,Color3.fromRGB(145,151,164))
local coord=stxt("",UDim2.fromOffset(16,62),UDim2.new(1,-32,0,20),12,true,Color3.fromRGB(255,199,47))
local controls=Instance.new("Frame");controls.Position=UDim2.fromOffset(16,88);controls.Size=UDim2.new(1,-32,0,32);controls.BackgroundTransparency=1;controls.Parent=settingsPanel
local defs={{"←",-5,0},{"→",5,0},{"↑",0,-5},{"↓",0,5}}
for i,d in ipairs(defs) do
 local b=Instance.new("TextButton");b.Position=UDim2.new((i-1)*.25,0,0,0);b.Size=UDim2.new(.25,-5,1,0);b.BackgroundColor3=Color3.fromRGB(28,31,38);b.Text=d[1];b.TextColor3=Color3.new(1,1,1);b.Font=Enum.Font.GothamBold;b.TextSize=16;b.BorderSizePixel=0;b.Parent=controls
 local cc=Instance.new("UICorner");cc.CornerRadius=UDim.new(0,7);cc.Parent=b
 b.Activated:Connect(function() mover:Fire(d[2],d[3],false);coord.Text="X "..hudX.."   Y "..hudY end)
end
local reset=Instance.new("TextButton");reset.Position=UDim2.fromOffset(16,132);reset.Size=UDim2.new(.48,-18,0,30);reset.BackgroundColor3=Color3.fromRGB(28,31,38);reset.Text="PADRÃO";reset.TextColor3=Color3.fromRGB(225,228,234);reset.Font=Enum.Font.GothamBold;reset.TextSize=10;reset.BorderSizePixel=0;reset.Parent=settingsPanel;local rc=Instance.new("UICorner");rc.CornerRadius=UDim.new(0,7);rc.Parent=reset
local save=Instance.new("TextButton");save.AnchorPoint=Vector2.new(1,0);save.Position=UDim2.new(1,-16,0,132);save.Size=UDim2.new(.48,-18,0,30);save.BackgroundColor3=Color3.fromRGB(255,199,47);save.Text="SALVAR";save.TextColor3=Color3.fromRGB(20,18,12);save.Font=Enum.Font.GothamBold;save.TextSize=10;save.BorderSizePixel=0;save.Parent=settingsPanel;local svc=Instance.new("UICorner");svc.CornerRadius=UDim.new(0,7);svc.Parent=save
local function updateSettings()coord.Text="X "..hudX.."   Y "..hudY end
settingsButton.Activated:Connect(function()settingsPanel.Visible=not settingsPanel.Visible;updateSettings()end)
reset.Activated:Connect(function()hudX=0;hudY=-4;applyPosition();updateSettings()end)
save.Activated:Connect(function()mover:Fire(0,0,true);updateSettings()end)

local function formatNumber(n)
	local s = tostring(math.floor(n))
	while true do
		local formatted, count = s:gsub("^(-?%d+)(%d%d%d)", "%1.%2")
		s = formatted
		if count == 0 then break end
	end
	return s
end

local gold = player:WaitForChild("leaderstats"):WaitForChild("Ouro")

local function update()
	local value = formatNumber(gold.Value)
	amount.Text = value
	local width = TextService:GetTextSize(value, amount.TextSize, amount.Font, Vector2.new(1000, 38)).X
	frame.Size = UDim2.fromOffset(math.max(86, math.ceil(width) + 52), 38)
end

update()
gold:GetPropertyChangedSignal("Value"):Connect(update)
