local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local StarterGui=game:GetService("StarterGui")
local player=Players.LocalPlayer
local event=ReplicatedStorage:WaitForChild("InventoryUpdate")
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false) end)
local gui=Instance.new("ScreenGui");gui.Name="InventoryUI";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.Parent=player:WaitForChild("PlayerGui")
local hotbar=Instance.new("Frame");hotbar.AnchorPoint=Vector2.new(.5,1);hotbar.Position=UDim2.new(.5,0,1,-18);hotbar.Size=UDim2.fromOffset(230,64);hotbar.BackgroundColor3=Color3.fromRGB(18,20,22);hotbar.BackgroundTransparency=.08;hotbar.Parent=gui
local hc=Instance.new("UICorner");hc.CornerRadius=UDim.new(0,16);hc.Parent=hotbar
local hs=Instance.new("UIStroke");hs.Color=Color3.fromRGB(255,255,255);hs.Transparency=.78;hs.Thickness=1.5;hs.Parent=hotbar
local layout=Instance.new("UIListLayout");layout.FillDirection=Enum.FillDirection.Horizontal;layout.HorizontalAlignment=Enum.HorizontalAlignment.Center;layout.VerticalAlignment=Enum.VerticalAlignment.Center;layout.Padding=UDim.new(0,8);layout.Parent=hotbar
local function slot(icon,name)
 local b=Instance.new("TextButton");b.Name=name.."Slot";b.Size=UDim2.fromOffset(58,48);b.BackgroundColor3=Color3.fromRGB(34,37,40);b.Text="";b.AutoButtonColor=false;b.Parent=hotbar
 local co=Instance.new("UICorner");co.CornerRadius=UDim.new(0,12);co.Parent=b
 local i=Instance.new("TextLabel");i.Size=UDim2.fromScale(1,1);i.BackgroundTransparency=1;i.Text=icon;i.TextScaled=true;i.Font=Enum.Font.GothamBold;i.Parent=b
 local n=Instance.new("TextLabel");n.Name="Count";n.AnchorPoint=Vector2.new(1,1);n.Position=UDim2.new(1,-5,1,-3);n.Size=UDim2.fromOffset(30,18);n.BackgroundTransparency=1;n.Text="0";n.TextColor3=Color3.new(1,1,1);n.TextStrokeTransparency=.35;n.TextScaled=true;n.Font=Enum.Font.GothamBold;n.Parent=b
 return b,n
end
local _,grass=slot("▦","Grass")
local _,dirt=slot("■","Dirt")
local bag,bagCount=slot("🎒","Bag");bagCount.Visible=false
local panel=Instance.new("Frame");panel.AnchorPoint=Vector2.new(.5,1);panel.Position=UDim2.new(.5,0,1,-92);panel.Size=UDim2.fromOffset(300,190);panel.BackgroundColor3=Color3.fromRGB(18,20,22);panel.BackgroundTransparency=.04;panel.Visible=false;panel.Parent=gui
local pc=Instance.new("UICorner");pc.CornerRadius=UDim.new(0,18);pc.Parent=panel
local ps=Instance.new("UIStroke");ps.Color=Color3.new(1,1,1);ps.Transparency=.82;ps.Parent=panel
local title=Instance.new("TextLabel");title.Position=UDim2.fromOffset(18,12);title.Size=UDim2.new(1,-36,0,30);title.BackgroundTransparency=1;title.Text="MOCHILA";title.TextColor3=Color3.new(1,1,1);title.TextXAlignment=Enum.TextXAlignment.Left;title.Font=Enum.Font.GothamBold;title.TextSize=18;title.Parent=panel
local body=Instance.new("TextLabel");body.Name="Items";body.Position=UDim2.fromOffset(18,52);body.Size=UDim2.new(1,-36,1,-66);body.BackgroundTransparency=1;body.TextColor3=Color3.fromRGB(225,228,230);body.TextXAlignment=Enum.TextXAlignment.Left;body.TextYAlignment=Enum.TextYAlignment.Top;body.Font=Enum.Font.GothamMedium;body.TextSize=17;body.Parent=panel
bag.MouseButton1Click:Connect(function() panel.Visible=not panel.Visible end)
local function render(data)
 grass.Text=tostring(data.Grass or 0);dirt.Text=tostring(data.Dirt or 0)
 body.Text=("Grama    × %d\n\nTerra     × %d"):format(data.Grass or 0,data.Dirt or 0)
end
event.OnClientEvent:Connect(render)
render({Grass=0,Dirt=0})
