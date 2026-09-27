local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local StarterGui=game:GetService("StarterGui")
local UserInputService=game:GetService("UserInputService")
local Workspace=game:GetService("Workspace")

local player=Players.LocalPlayer
local inventoryUpdate=ReplicatedStorage:WaitForChild("InventoryUpdate")
local placeBlock=ReplicatedStorage:WaitForChild("PlaceBlock")
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false) end)

local selectedItem=nil
local counts={Grass=0,Dirt=0}
local SLOT_COUNT=7
local slots={}

local gui=Instance.new("ScreenGui")
gui.Name="InventoryUI";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.Parent=player:WaitForChild("PlayerGui")

local hotbar=Instance.new("Frame")
hotbar.Name="Hotbar";hotbar.AnchorPoint=Vector2.new(.5,1);hotbar.Position=UDim2.new(.5,0,1,-16)
hotbar.BackgroundColor3=Color3.fromRGB(15,17,19);hotbar.BackgroundTransparency=.08;hotbar.Parent=gui
local hc=Instance.new("UICorner");hc.CornerRadius=UDim.new(0,14);hc.Parent=hotbar
local hs=Instance.new("UIStroke");hs.Color=Color3.fromRGB(210,215,220);hs.Transparency=.72;hs.Thickness=1;hs.Parent=hotbar
local layout=Instance.new("UIListLayout");layout.FillDirection=Enum.FillDirection.Horizontal;layout.HorizontalAlignment=Enum.HorizontalAlignment.Center;layout.VerticalAlignment=Enum.VerticalAlignment.Center;layout.Padding=UDim.new(0,6);layout.Parent=hotbar

local function makeSlot(index)
 local b=Instance.new("TextButton");b.Name="Slot"..index;b.Text="";b.AutoButtonColor=false;b.BackgroundColor3=Color3.fromRGB(30,33,36);b.Parent=hotbar
 local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,10);c.Parent=b
 local s=Instance.new("UIStroke");s.Name="Selection";s.Color=Color3.fromRGB(245,245,245);s.Transparency=.88;s.Thickness=1.2;s.Parent=b
 local sw=Instance.new("Frame");sw.Name="Swatch";sw.AnchorPoint=Vector2.new(.5,.5);sw.Position=UDim2.fromScale(.5,.46);sw.Size=UDim2.fromScale(.48,.48);sw.BorderSizePixel=0;sw.BackgroundTransparency=1;sw.Parent=b
 local sc=Instance.new("UICorner");sc.CornerRadius=UDim.new(0,5);sc.Parent=sw
 local n=Instance.new("TextLabel");n.Name="Count";n.AnchorPoint=Vector2.new(1,1);n.Position=UDim2.new(1,-4,1,-3);n.Size=UDim2.fromOffset(26,15);n.BackgroundTransparency=1;n.Text="";n.TextColor3=Color3.new(1,1,1);n.TextStrokeTransparency=.3;n.Font=Enum.Font.GothamBold;n.TextSize=12;n.Parent=b
 slots[index]={button=b,swatch=sw,count=n,stroke=s}
 return b
end
for i=1,SLOT_COUNT do makeSlot(i) end

local bag=Instance.new("TextButton")
bag.Name="InventoryButton";bag.AnchorPoint=Vector2.new(0,1);bag.Position=UDim2.new(1,10,1,0);bag.Size=UDim2.fromOffset(44,44);bag.Text="";bag.AutoButtonColor=false;bag.BackgroundColor3=Color3.fromRGB(20,23,25);bag.Parent=hotbar
local bc=Instance.new("UICorner");bc.CornerRadius=UDim.new(0,12);bc.Parent=bag
local bs=Instance.new("UIStroke");bs.Color=Color3.fromRGB(220,225,230);bs.Transparency=.68;bs.Parent=bag
local top=Instance.new("Frame");top.AnchorPoint=Vector2.new(.5,.5);top.Position=UDim2.fromScale(.5,.38);top.Size=UDim2.fromScale(.42,.14);top.BackgroundColor3=Color3.fromRGB(220,225,230);top.BorderSizePixel=0;top.Parent=bag
local bodyIcon=Instance.new("Frame");bodyIcon.AnchorPoint=Vector2.new(.5,.5);bodyIcon.Position=UDim2.fromScale(.5,.58);bodyIcon.Size=UDim2.fromScale(.5,.38);bodyIcon.BackgroundColor3=Color3.fromRGB(220,225,230);bodyIcon.BorderSizePixel=0;bodyIcon.Parent=bag
local bic=Instance.new("UICorner");bic.CornerRadius=UDim.new(0,4);bic.Parent=bodyIcon

local panel=Instance.new("Frame")
panel.Name="InventoryPanel";panel.AnchorPoint=Vector2.new(.5,1);panel.Position=UDim2.new(.5,0,1,-86);panel.Size=UDim2.fromOffset(420,260);panel.BackgroundColor3=Color3.fromRGB(15,17,19);panel.BackgroundTransparency=.03;panel.Visible=false;panel.Parent=gui
local pc=Instance.new("UICorner");pc.CornerRadius=UDim.new(0,18);pc.Parent=panel
local ps=Instance.new("UIStroke");ps.Color=Color3.fromRGB(220,225,230);ps.Transparency=.78;ps.Parent=panel
local title=Instance.new("TextLabel");title.Position=UDim2.fromOffset(18,14);title.Size=UDim2.new(1,-36,0,26);title.BackgroundTransparency=1;title.Text="INVENTÁRIO";title.TextColor3=Color3.fromRGB(242,244,246);title.TextXAlignment=Enum.TextXAlignment.Left;title.Font=Enum.Font.GothamBold;title.TextSize=17;title.Parent=panel
local grid=Instance.new("Frame");grid.Position=UDim2.fromOffset(18,52);grid.Size=UDim2.new(1,-36,1,-70);grid.BackgroundTransparency=1;grid.Parent=panel
local gl=Instance.new("UIGridLayout");gl.CellSize=UDim2.fromOffset(82,70);gl.CellPadding=UDim2.fromOffset(8,8);gl.Parent=grid

local function inventoryCard(name,label,color)
 local b=Instance.new("TextButton");b.Name=name;b.Text="";b.AutoButtonColor=false;b.BackgroundColor3=Color3.fromRGB(28,31,34);b.Parent=grid
 local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,11);c.Parent=b
 local sw=Instance.new("Frame");sw.Position=UDim2.fromOffset(9,9);sw.Size=UDim2.fromOffset(25,25);sw.BackgroundColor3=color;sw.BorderSizePixel=0;sw.Parent=b
 local sc=Instance.new("UICorner");sc.CornerRadius=UDim.new(0,5);sc.Parent=sw
 local l=Instance.new("TextLabel");l.Position=UDim2.fromOffset(9,39);l.Size=UDim2.new(1,-18,0,20);l.BackgroundTransparency=1;l.Text=label;l.TextColor3=Color3.fromRGB(230,233,235);l.TextXAlignment=Enum.TextXAlignment.Left;l.Font=Enum.Font.GothamMedium;l.TextSize=12;l.Parent=b
 local n=Instance.new("TextLabel");n.Name="Count";n.AnchorPoint=Vector2.new(1,0);n.Position=UDim2.new(1,-8,0,10);n.Size=UDim2.fromOffset(34,20);n.BackgroundTransparency=1;n.TextColor3=Color3.new(1,1,1);n.TextXAlignment=Enum.TextXAlignment.Right;n.Font=Enum.Font.GothamBold;n.TextSize=13;n.Parent=b
 b.MouseButton1Click:Connect(function() selectedItem=name;panel.Visible=false end)
 return n
end
local grassCard=inventoryCard("Grass","Grama",Color3.fromRGB(75,136,55))
local dirtCard=inventoryCard("Dirt","Terra",Color3.fromRGB(101,67,33))

local function select(item)
 selectedItem=item
 for i,v in ipairs(slots) do v.stroke.Transparency=((i==1 and item=="Grass") or (i==2 and item=="Dirt")) and .15 or .88 end
end
slots[1].button.MouseButton1Click:Connect(function() if counts.Grass>0 then select("Grass") end end)
slots[2].button.MouseButton1Click:Connect(function() if counts.Dirt>0 then select("Dirt") end end)
bag.MouseButton1Click:Connect(function() panel.Visible=not panel.Visible end)

local function resize()
 local camera=Workspace.CurrentCamera;if not camera then return end
 local width=camera.ViewportSize.X
 local slot=width<600 and 38 or (width<1000 and 44 or 48)
 for _,v in ipairs(slots) do v.button.Size=UDim2.fromOffset(slot,slot) end
 hotbar.Size=UDim2.fromOffset(SLOT_COUNT*slot+(SLOT_COUNT-1)*6+20,slot+14)
 local panelWidth=math.min(420,width-28);panel.Size=UDim2.fromOffset(panelWidth,260)
end
resize()
if Workspace.CurrentCamera then Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end

local function render(data)
 counts.Grass=data.Grass or 0;counts.Dirt=data.Dirt or 0
 slots[1].swatch.BackgroundTransparency=0;slots[1].swatch.BackgroundColor3=Color3.fromRGB(75,136,55);slots[1].count.Text=tostring(counts.Grass)
 slots[2].swatch.BackgroundTransparency=0;slots[2].swatch.BackgroundColor3=Color3.fromRGB(101,67,33);slots[2].count.Text=tostring(counts.Dirt)
 for i=3,SLOT_COUNT do slots[i].swatch.BackgroundTransparency=1;slots[i].count.Text="" end
 grassCard.Text=tostring(counts.Grass);dirtCard.Text=tostring(counts.Dirt)
 if selectedItem and (counts[selectedItem] or 0)<=0 then select(nil) end
end
inventoryUpdate.OnClientEvent:Connect(render);render(counts)

UserInputService.InputBegan:Connect(function(input,processed)
 if processed or not selectedItem or (counts[selectedItem] or 0)<=0 then return end
 if input.UserInputType~=Enum.UserInputType.Touch and input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
 local camera=Workspace.CurrentCamera;if not camera then return end
 local pos=input.Position
 local ray=camera:ViewportPointToRay(pos.X,pos.Y)
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances=player.Character and {player.Character} or {}
 local hit=Workspace:Raycast(ray.Origin,ray.Direction*18,params)
 if hit and hit.Instance and hit.Instance.Parent==Workspace:FindFirstChild("StarterIsland") then
  local normal=hit.Normal
  local target=hit.Instance.Position+Vector3.new(math.round(normal.X),math.round(normal.Y),math.round(normal.Z))*3.84
  placeBlock:FireServer(selectedItem,target)
 end
end)
