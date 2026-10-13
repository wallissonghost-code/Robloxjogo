local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local RS=game:GetService("ReplicatedStorage")
if not UIS.TouchEnabled then return end
local player=Players.LocalPlayer
local pg=player:WaitForChild("PlayerGui")
local hudRemote=RS:WaitForChild("HUDPosition")

local function hideNative()
 local touch=pg:FindFirstChild("TouchGui")
 if not touch then return false end
 local found=false
 for _,obj in ipairs(touch:GetDescendants()) do
  if obj:IsA("GuiObject") and obj.Name=="JumpButton" then
   obj.Visible=false
   obj.Active=false
   found=true
  end
 end
 return found
end
task.spawn(function()
 while true do
  hideNative()
  task.wait(.25)
 end
end)
pg.DescendantAdded:Connect(function(obj)
 if obj:IsA("GuiObject") and obj.Name=="JumpButton" and not obj:IsDescendantOf(gui) then
  task.defer(function() if obj.Parent then obj.Visible=false;obj.Active=false end end)
 end
end)

local gui=Instance.new("ScreenGui")
gui.Name="CustomJumpHUD";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.ScreenInsets=Enum.ScreenInsets.None;gui.DisplayOrder=9999;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=pg
local b=Instance.new("TextButton")
b.Name="CustomJumpButton";b.AnchorPoint=Vector2.new(1,1);b.Position=UDim2.new(1,-28,1,-110);b.Size=UDim2.fromOffset(76,76);b.ZIndex=100
local jumpX,jumpY,jumpScale=-28,-110,1
local function applyJumpHUD()
 b.Position=UDim2.new(1,jumpX,1,jumpY)
 b.Size=UDim2.fromOffset(76*jumpScale,76*jumpScale)
 b:SetAttribute("HUDX",jumpX);b:SetAttribute("HUDY",jumpY);b:SetAttribute("HUDScale",jumpScale)
end
local jumpEdit=Instance.new("BindableEvent");jumpEdit.Name="JumpHUDEdit";jumpEdit.Parent=gui
jumpEdit.Event:Connect(function(x,y,scale)
 jumpX=tonumber(x) or jumpX;jumpY=tonumber(y) or jumpY;jumpScale=math.clamp(tonumber(scale) or jumpScale,.7,1.4);applyJumpHUD()
end)
task.spawn(function()
 local ok,yes,slot,x,y,sc,sx,sy,ss,jx,jy,js=pcall(function()return hudRemote:InvokeServer("get")end)
 if ok and yes then jumpX=jx or -28;jumpY=jy or -110;jumpScale=math.clamp(tonumber(js) or 1,.7,1.4);applyJumpHUD() end
end)
b.BackgroundColor3=Color3.fromRGB(35,38,45);b.BackgroundTransparency=.12;b.Text="↑";b.TextColor3=Color3.fromRGB(255,255,255);b.TextSize=34;b.TextWrapped=true;b.Font=Enum.Font.GothamBold;b.BorderSizePixel=0;b.Parent=gui
local c=Instance.new("UICorner");c.CornerRadius=UDim.new(1,0);c.Parent=b
local st=Instance.new("UIStroke");st.Color=Color3.fromRGB(105,110,120);st.Transparency=.35;st.Thickness=1.5;st.Parent=b
local function jump()
 local char=player.Character
 local hum=char and char:FindFirstChildOfClass("Humanoid")
 if hum and hum.Health>0 and hum:GetState()~=Enum.HumanoidStateType.Dead then
  if hum.FloorMaterial~=Enum.Material.Air then
   hum.Jump=true
   hum:ChangeState(Enum.HumanoidStateType.Jumping)
  end
 end
end
b.Activated:Connect(jump)

