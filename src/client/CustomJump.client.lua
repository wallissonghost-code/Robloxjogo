local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
if not UIS.TouchEnabled then return end
local player=Players.LocalPlayer
local pg=player:WaitForChild("PlayerGui")

local function hideNative()
 local touch=pg:FindFirstChild("TouchGui")
 if not touch then return end
 local frame=touch:FindFirstChild("TouchControlFrame")
 local jump=frame and frame:FindFirstChild("JumpButton")
 if jump then jump.Visible=false end
end
task.spawn(function()
 for _=1,30 do hideNative();task.wait(.2) end
end)
pg.ChildAdded:Connect(function(c) if c.Name=="TouchGui" then task.wait(.2);hideNative() end end)

local gui=Instance.new("ScreenGui")
gui.Name="CustomJumpHUD";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.ScreenInsets=Enum.ScreenInsets.None;gui.DisplayOrder=21;gui.Parent=pg
local b=Instance.new("TextButton")
b.Name="JumpButton";b.AnchorPoint=Vector2.new(1,1);b.Position=UDim2.new(1,-22,1,-96);b.Size=UDim2.fromOffset(72,72)
b.BackgroundColor3=Color3.fromRGB(30,33,39);b.BackgroundTransparency=.18;b.Text="↑";b.TextColor3=Color3.fromRGB(245,245,245);b.TextSize=34;b.Font=Enum.Font.GothamBold;b.BorderSizePixel=0;b.Parent=gui
local c=Instance.new("UICorner");c.CornerRadius=UDim.new(1,0);c.Parent=b
local st=Instance.new("UIStroke");st.Color=Color3.fromRGB(105,110,120);st.Transparency=.35;st.Thickness=1.5;st.Parent=b
b.Activated:Connect(function()
 local char=player.Character
 local hum=char and char:FindFirstChildOfClass("Humanoid")
 if hum and hum.Health>0 then hum.Jump=true end
end)
