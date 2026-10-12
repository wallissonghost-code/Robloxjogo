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
local settingsX,settingsY=-87,0
local hudX,hudY,activePreset=0,-4,"hud1"
local ok,got,slot,x,y=pcall(function() return hudRemote:InvokeServer("get") end)
if ok and got then activePreset=slot or "hud1";hudX=math.min(x or 0,0);hudY=y or -4 end

local function applyPosition()
 frame.Position=UDim2.new(1,hudX,0,hudY)
 frame:SetAttribute("HUDX",hudX);frame:SetAttribute("HUDY",hudY)
end
applyPosition()

-- Settings button is intentionally fixed to the screen, never parented to movable HUD.
local settingsButton=Instance.new("TextButton")
settingsButton.Name="SettingsButton";settingsButton.AnchorPoint=Vector2.new(1,0)
settingsButton.Position=UDim2.new(1,settingsX,0,settingsY);settingsButton.Size=UDim2.fromOffset(38,38)
settingsButton.BackgroundColor3=Color3.fromRGB(13,15,18);settingsButton.Text="";settingsButton.BorderSizePixel=0;settingsButton.Parent=gui
local settingsMove=Instance.new("BindableEvent");settingsMove.Name="SettingsMove";settingsMove.Parent=gui
settingsMove.Event:Connect(function(dx,dy)
 settingsX=math.clamp(settingsX+dx,-500,-38);settingsY=math.clamp(settingsY+dy,0,500)
 settingsButton.Position=UDim2.new(1,settingsX,0,settingsY)
 settingsButton:SetAttribute("HUDX",settingsX);settingsButton:SetAttribute("HUDY",settingsY)
end)
settingsButton:SetAttribute("HUDX",settingsX);settingsButton:SetAttribute("HUDY",settingsY)
local sbc=Instance.new("UICorner");sbc.CornerRadius=UDim.new(0,10);sbc.Parent=settingsButton
local sbs=Instance.new("UIStroke");sbs.Color=Color3.fromRGB(255,194,45);sbs.Transparency=.25;sbs.Thickness=1;sbs.Parent=settingsButton
local gear=Instance.new("Frame");gear.AnchorPoint=Vector2.new(.5,.5);gear.Position=UDim2.fromScale(.5,.5);gear.Size=UDim2.fromOffset(15,15);gear.BackgroundColor3=Color3.fromRGB(255,199,47);gear.BorderSizePixel=0;gear.Parent=settingsButton
local gc=Instance.new("UICorner");gc.CornerRadius=UDim.new(1,0);gc.Parent=gear
local hole=Instance.new("Frame");hole.AnchorPoint=Vector2.new(.5,.5);hole.Position=UDim2.fromScale(.5,.5);hole.Size=UDim2.fromOffset(6,6);hole.BackgroundColor3=Color3.fromRGB(13,15,18);hole.BorderSizePixel=0;hole.Parent=gear
local hc=Instance.new("UICorner");hc.CornerRadius=UDim.new(1,0);hc.Parent=hole

local panel=Instance.new("Frame");panel.Name="SettingsPanel";panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5);panel.Size=UDim2.fromScale(.68,.72);panel.BackgroundColor3=Color3.fromRGB(9,11,15);panel.BorderSizePixel=0;panel.Visible=false;panel.Parent=gui
local limit=Instance.new("UISizeConstraint");limit.MinSize=Vector2.new(560,360);limit.MaxSize=Vector2.new(720,500);limit.Parent=panel
local pc=Instance.new("UICorner");pc.CornerRadius=UDim.new(0,16);pc.Parent=panel
local ps=Instance.new("UIStroke");ps.Color=Color3.fromRGB(222,166,36);ps.Transparency=.12;ps.Thickness=1.5;ps.Parent=panel
local function label(parent,t,pos,size,ts,bold,col)
 local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Position=pos;l.Size=size;l.Text=t;l.TextColor3=col or Color3.fromRGB(238,240,244);l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham;l.TextSize=ts;l.TextXAlignment=Enum.TextXAlignment.Left;l.TextYAlignment=Enum.TextYAlignment.Center;l.Parent=parent;return l
end
label(panel,"CONFIGURAÇÕES",UDim2.fromOffset(26,16),UDim2.new(1,-90,0,30),22,true)
label(panel,"Personalize sua experiência",UDim2.fromOffset(26,46),UDim2.new(1,-90,0,20),12,false,Color3.fromRGB(145,151,164))
local close=Instance.new("TextButton");close.AnchorPoint=Vector2.new(1,0);close.Position=UDim2.new(1,-18,0,18);close.Size=UDim2.fromOffset(36,36);close.BackgroundColor3=Color3.fromRGB(28,31,38);close.Text="×";close.TextColor3=Color3.new(1,1,1);close.TextSize=25;close.Font=Enum.Font.GothamBold;close.BorderSizePixel=0;close.Parent=panel
local cc=Instance.new("UICorner");cc.CornerRadius=UDim.new(0,9);cc.Parent=close

local nav=Instance.new("Frame");nav.Position=UDim2.fromOffset(22,84);nav.Size=UDim2.new(0,150,1,-106);nav.BackgroundColor3=Color3.fromRGB(14,17,22);nav.BorderSizePixel=0;nav.Parent=panel
local nc=Instance.new("UICorner");nc.CornerRadius=UDim.new(0,11);nc.Parent=nav
local function navItem(text,y,active)
 local b=Instance.new("TextButton");b.Position=UDim2.fromOffset(8,y);b.Size=UDim2.new(1,-16,0,46);b.BackgroundColor3=active and Color3.fromRGB(255,195,43) or Color3.fromRGB(25,28,35);b.Text=text;b.TextColor3=active and Color3.fromRGB(18,18,18) or Color3.fromRGB(190,194,203);b.Font=Enum.Font.GothamBold;b.TextSize=12;b.BorderSizePixel=0;b.Parent=nav;local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=b;return b
end
navItem("HUD",10,true);navItem("ÁUDIO",64,false).AutoButtonColor=false;navItem("GRÁFICOS",118,false).AutoButtonColor=false

local content=Instance.new("Frame");content.Position=UDim2.fromOffset(194,84);content.Size=UDim2.new(1,-218,1,-106);content.BackgroundTransparency=1;content.Parent=panel
label(content,"CONFIGURAR HUD",UDim2.fromOffset(0,0),UDim2.new(1,0,0,25),18,true)
label(content,"Ajuste cada elemento individualmente.",UDim2.fromOffset(0,28),UDim2.new(1,0,0,24),11,false,Color3.fromRGB(150,155,166))

local profileTitle=label(content,"PERFIL",UDim2.fromOffset(0,60),UDim2.new(1,0,0,18),10,true,Color3.fromRGB(150,155,166))
local profileRow=Instance.new("Frame");profileRow.Position=UDim2.fromOffset(0,82);profileRow.Size=UDim2.new(1,0,0,38);profileRow.BackgroundTransparency=1;profileRow.Parent=content
local profileButtons={}
for i,n in ipairs({"HUD 1","HUD 2"}) do
 local b=Instance.new("TextButton");b.Position=UDim2.new((i-1)*.5,0,0,0);b.Size=UDim2.new(.5,-6,1,0);b.BackgroundColor3=Color3.fromRGB(28,31,38);b.Text=n;b.TextColor3=Color3.new(1,1,1);b.Font=Enum.Font.GothamBold;b.TextSize=11;b.BorderSizePixel=0;b.Parent=profileRow;local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=b;profileButtons[i]=b
end

label(content,"ELEMENTO",UDim2.fromOffset(0,128),UDim2.new(1,0,0,18),10,true,Color3.fromRGB(150,155,166))
local element=Instance.new("TextButton");element.Position=UDim2.fromOffset(0,150);element.Size=UDim2.new(1,0,0,38);element.BackgroundColor3=Color3.fromRGB(255,195,43);element.Text="OURO";element.TextColor3=Color3.fromRGB(18,18,18);element.Font=Enum.Font.GothamBold;element.TextSize=11;element.BorderSizePixel=0;element.Parent=content;local ec=Instance.new("UICorner");ec.CornerRadius=UDim.new(0,8);ec.Parent=element

local coord=label(content,"",UDim2.fromOffset(0,196),UDim2.new(1,0,0,20),11,true,Color3.fromRGB(255,199,47))
local adjustRow=Instance.new("Frame");adjustRow.Position=UDim2.fromOffset(0,220);adjustRow.Size=UDim2.new(1,0,0,40);adjustRow.BackgroundTransparency=1;adjustRow.Parent=content
local defs={{"←",-5,0},{"→",5,0},{"↑",0,-5},{"↓",0,5}}
for i,d in ipairs(defs) do
 local b=Instance.new("TextButton");b.Position=UDim2.new((i-1)*.25,0,0,0);b.Size=UDim2.new(.25,-6,1,0);b.BackgroundColor3=Color3.fromRGB(28,31,38);b.Text=d[1];b.TextColor3=Color3.new(1,1,1);b.Font=Enum.Font.GothamBold;b.TextSize=18;b.BorderSizePixel=0;b.Parent=adjustRow;local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=b
 b.Activated:Connect(function()hudX=math.clamp(hudX+d[2],-500,0);hudY=math.clamp(hudY+d[3],-100,500);applyPosition();coord.Text="POSIÇÃO  X "..hudX.."  Y "..hudY end)
end

local sizeScale=1
local sizeLabel=label(content,"TAMANHO  100%",UDim2.fromOffset(0,268),UDim2.new(.48,0,0,36),11,true)
local minus=Instance.new("TextButton");minus.Position=UDim2.new(.50,0,0,268);minus.Size=UDim2.new(.23,-4,0,36);minus.BackgroundColor3=Color3.fromRGB(28,31,38);minus.Text="−";minus.TextColor3=Color3.new(1,1,1);minus.Font=Enum.Font.GothamBold;minus.TextSize=20;minus.BorderSizePixel=0;minus.Parent=content;local mc=Instance.new("UICorner");mc.CornerRadius=UDim.new(0,8);mc.Parent=minus
local plus=Instance.new("TextButton");plus.Position=UDim2.new(.75,0,0,268);plus.Size=UDim2.new(.25,0,0,36);plus.BackgroundColor3=Color3.fromRGB(28,31,38);plus.Text="+";plus.TextColor3=Color3.new(1,1,1);plus.Font=Enum.Font.GothamBold;plus.TextSize=18;plus.BorderSizePixel=0;plus.Parent=content;local plc=Instance.new("UICorner");plc.CornerRadius=UDim.new(0,8);plc.Parent=plus
local function applyScale() frame.Size=UDim2.fromOffset(math.max(86,112*sizeScale),38*sizeScale);sizeLabel.Text="TAMANHO  "..math.floor(sizeScale*100).."%";frame:SetAttribute("HUDScale",sizeScale) end
minus.Activated:Connect(function()sizeScale=math.max(.7,sizeScale-.1);applyScale()end)
plus.Activated:Connect(function()sizeScale=math.min(1.4,sizeScale+.1);applyScale()end)

local reset=Instance.new("TextButton");reset.AnchorPoint=Vector2.new(0,1);reset.Position=UDim2.new(0,0,1,0);reset.Size=UDim2.new(.48,0,0,38);reset.BackgroundColor3=Color3.fromRGB(28,31,38);reset.Text="REDEFINIR HUD";reset.TextColor3=Color3.fromRGB(225,228,234);reset.Font=Enum.Font.GothamBold;reset.TextSize=10;reset.BorderSizePixel=0;reset.Parent=content;local rc=Instance.new("UICorner");rc.CornerRadius=UDim.new(0,8);rc.Parent=reset
local save=Instance.new("TextButton");save.AnchorPoint=Vector2.new(1,1);save.Position=UDim2.new(1,0,1,0);save.Size=UDim2.new(.48,0,0,38);save.BackgroundColor3=Color3.fromRGB(255,199,47);save.Text="SALVAR HUD";save.TextColor3=Color3.fromRGB(20,18,12);save.Font=Enum.Font.GothamBold;save.TextSize=10;save.BorderSizePixel=0;save.Parent=content;local sc=Instance.new("UICorner");sc.CornerRadius=UDim.new(0,8);sc.Parent=save

local function refreshSettings()
 coord.Text="POSIÇÃO  X "..hudX.."  Y "..hudY
 for i,b in ipairs(profileButtons) do local on=(activePreset==("hud"..i));b.BackgroundColor3=on and Color3.fromRGB(255,195,43) or Color3.fromRGB(28,31,38);b.TextColor3=on and Color3.fromRGB(18,18,18) or Color3.new(1,1,1) end
end
for i,b in ipairs(profileButtons) do b.Activated:Connect(function()
 local wanted="hud"..i;local pok,yes,newslot,nx,ny=pcall(function()return hudRemote:InvokeServer("load",wanted)end)
 if pok and yes then activePreset=newslot;hudX=nx;hudY=ny;applyPosition();refreshSettings()end
end) end
save.Activated:Connect(function()
 local pok,yes,newslot,nx,ny=pcall(function()return hudRemote:InvokeServer("save",activePreset,hudX,hudY)end)
 if pok and yes then activePreset=newslot;hudX=nx;hudY=ny;applyPosition();refreshSettings()end
end)
reset.Activated:Connect(function()
 local pok,yes,newslot,nx,ny=pcall(function()return hudRemote:InvokeServer("reset",activePreset)end)
 if pok and yes then activePreset=newslot;hudX=nx;hudY=ny;sizeScale=1;applyPosition();applyScale();refreshSettings()end
end)
settingsButton.Activated:Connect(function()panel.Visible=not panel.Visible;refreshSettings()end)
close.Activated:Connect(function()panel.Visible=false end)

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
