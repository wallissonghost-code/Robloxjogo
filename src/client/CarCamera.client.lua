local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local controlEvent=ReplicatedStorage:WaitForChild("TrendCarControl")

local player=Players.LocalPlayer
local camera=workspace.CurrentCamera
local activeSeat=nil
local CAMERA_HEIGHT=8
local CAMERA_DISTANCE=14
local LOOK_HEIGHT=2

local function currentSeat()
 local char=player.Character
 local hum=char and char:FindFirstChildOfClass("Humanoid")
 local seat=hum and hum.SeatPart
 if seat and seat:IsA("VehicleSeat") and seat:GetAttribute("TrendCarDriverSeat") then return seat end
end

RunService:BindToRenderStep("TrendCarCamera",Enum.RenderPriority.Camera.Value+1,function(dt)
 local seat=currentSeat()
 if seat then
  activeSeat=seat
  camera.CameraType=Enum.CameraType.Scriptable
  local cf=seat.CFrame
  local desired=cf.Position-cf.LookVector*CAMERA_DISTANCE+Vector3.new(0,CAMERA_HEIGHT,0)
  local look=cf.Position+cf.LookVector*5+Vector3.new(0,LOOK_HEIGHT,0)
  local target=CFrame.lookAt(desired,look)
  camera.CFrame=camera.CFrame:Lerp(target,1-math.exp(-10*dt))
 elseif activeSeat then
  activeSeat=nil
  camera.CameraType=Enum.CameraType.Custom
  local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if hum then camera.CameraSubject=hum end
 end
end)


-- Mobile driving HUD
local gui=Instance.new("ScreenGui")
gui.Name="TrendCarMobileHUD"; gui.ResetOnSpawn=false; gui.Enabled=false; gui.Parent=player:WaitForChild("PlayerGui")
local accel=Instance.new("TextButton"); accel.Name="Accelerate"; accel.Size=UDim2.fromOffset(92,92); accel.Position=UDim2.new(1,-112,1,-118); accel.AnchorPoint=Vector2.new(0,0); accel.Text="ACELERAR"; accel.TextScaled=true; accel.BackgroundTransparency=.2; accel.Parent=gui
local reverse=Instance.new("TextButton"); reverse.Name="Reverse"; reverse.Size=UDim2.fromOffset(76,76); reverse.Position=UDim2.new(1,-202,1,-104); reverse.Text="RÉ"; reverse.TextScaled=true; reverse.BackgroundTransparency=.2; reverse.Parent=gui
local pad=Instance.new("Frame"); pad.Name="Steering"; pad.Size=UDim2.fromOffset(140,140); pad.Position=UDim2.new(0,24,1,-164); pad.BackgroundTransparency=.35; pad.Parent=gui
local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(1,0); corner.Parent=pad
local knob=Instance.new("Frame"); knob.Size=UDim2.fromOffset(58,58); knob.AnchorPoint=Vector2.new(.5,.5); knob.Position=UDim2.fromScale(.5,.5); knob.Parent=pad
local kc=Instance.new("UICorner"); kc.CornerRadius=UDim.new(1,0); kc.Parent=knob
local throttle,steer=0,0
local accelDown,reverseDown=false,false
local steeringTouch=nil
local function send() controlEvent:FireServer(throttle,steer) end
local function setThrottle() throttle=accelDown and 1 or (reverseDown and -1 or 0); send() end
accel.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then accelDown=true; setThrottle() end end)
accel.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then accelDown=false; setThrottle() end end)
reverse.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then reverseDown=true; setThrottle() end end)
reverse.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then reverseDown=false; setThrottle() end end)
local function updateStick(pos)
 local center=pad.AbsolutePosition+pad.AbsoluteSize/2
 local dx=math.clamp((pos.X-center.X)/(pad.AbsoluteSize.X*.42),-1,1)
 steer=dx
 knob.Position=UDim2.new(.5,dx*pad.AbsoluteSize.X*.28,.5,0)
 send()
end
pad.InputBegan:Connect(function(i)
 if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then steeringTouch=i; updateStick(i.Position) end
end)
UIS.InputChanged:Connect(function(i) if steeringTouch and (i==steeringTouch or i.UserInputType==Enum.UserInputType.Touch) then updateStick(i.Position) end end)
UIS.InputEnded:Connect(function(i)
 if i==steeringTouch then steeringTouch=nil; steer=0; knob.Position=UDim2.fromScale(.5,.5); send() end
end)

RunService.RenderStepped:Connect(function()
 local driving=currentSeat()~=nil
 gui.Enabled=driving and UIS.TouchEnabled
 if not driving and (throttle~=0 or steer~=0) then throttle=0; steer=0; accelDown=false; reverseDown=false; send() end
end)
