local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
if not UIS.TouchEnabled then return end
local player=Players.LocalPlayer
local pg=player:WaitForChild("PlayerGui")

local function hideNative()
 local touch=pg:FindFirstChild("TouchGui")
 if not touch then return false end
 local found=false
 for _,obj in ipairs(touch:GetDescendants()) do
  if obj:IsA("GuiObject") and (obj.Name=="JumpButton" or string.find(string.lower(obj.Name),"jump")) then
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
 if obj:IsA("GuiObject") and (obj.Name=="JumpButton" or string.find(string.lower(obj.Name),"jump")) then
  task.defer(function() if obj.Parent then obj.Visible=false;obj.Active=false end end)
 end
end)

local gui=Instance.new("ScreenGui")
gui.Name="CustomJumpHUD";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.ScreenInsets=Enum.ScreenInsets.None;gui.DisplayOrder=21;gui.Parent=pg
local b=Instance.new("TextButton")
b.Name="JumpButton";b.AnchorPoint=Vector2.new(1,1);b.Position=UDim2.new(1,-22,1,-96);b.Size=UDim2.fromOffset(72,72)
b.BackgroundColor3=Color3.fromRGB(30,33,39);b.BackgroundTransparency=.05;b.Text="NOSSO\n↑";b.TextColor3=Color3.fromRGB(245,245,245);b.TextSize=15;b.TextWrapped=true;b.Font=Enum.Font.GothamBold;b.BorderSizePixel=0;b.Parent=gui
local c=Instance.new("UICorner");c.CornerRadius=UDim.new(1,0);c.Parent=b
local st=Instance.new("UIStroke");st.Color=Color3.fromRGB(105,110,120);st.Transparency=.35;st.Thickness=1.5;st.Parent=b
b.Activated:Connect(function()
 local char=player.Character
 local hum=char and char:FindFirstChildOfClass("Humanoid")
 if hum and hum.Health>0 then hum.Jump=true end
end)
