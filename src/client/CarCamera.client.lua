local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local player=Players.LocalPlayer
local controlEvent=ReplicatedStorage:WaitForChild("TrendCarControl")
local playerControls=nil
pcall(function()
 local PlayerModule=require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
 playerControls=PlayerModule:GetControls()
end)
local camera=workspace.CurrentCamera
local activeSeat=nil
local CAMERA_HEIGHT=8
local CAMERA_DISTANCE=14
local LOOK_HEIGHT=2
local zoomDistance=14
local MIN_ZOOM=0
local MAX_ZOOM=22
local COCKPIT_THRESHOLD=2.2
local lastPinchDistance=nil

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
  local car=seat:FindFirstAncestor("TrendFlyingCar")
  local driveRoot=car and car:FindFirstChild("DriveRoot",true)
  local cf=(driveRoot and driveRoot.CFrame) or seat.CFrame
  if zoomDistance<=COCKPIT_THRESHOLD then
   -- First-person/cockpit view. The avatar is already hidden locally.
   local eye=seat.Position+Vector3.new(0,1.25,0)+cf.LookVector*.35
   local target=CFrame.lookAt(eye,eye+cf.LookVector*12+Vector3.new(0,.15,0))
   camera.CFrame=camera.CFrame:Lerp(target,1-math.exp(-14*dt))
  else
   local t=(zoomDistance-COCKPIT_THRESHOLD)/(MAX_ZOOM-COCKPIT_THRESHOLD)
   local distance=4+(zoomDistance-COCKPIT_THRESHOLD)
   local height=3.2+t*7
   local desired=cf.Position-cf.LookVector*distance+Vector3.new(0,height,0)
   local look=cf.Position+cf.LookVector*6+Vector3.new(0,1.7,0)
   local target=CFrame.lookAt(desired,look)
   camera.CFrame=camera.CFrame:Lerp(target,1-math.exp(-11*dt))
  end
 elseif activeSeat then
  activeSeat=nil
  camera.CameraType=Enum.CameraType.Custom
  local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if hum then camera.CameraSubject=hum end
 end
end)


-- Camera zoom: pinch on mobile, mouse wheel on desktop.
UIS.TouchPinch:Connect(function(touchPositions,scale,velocity,state)
 if not currentSeat() then lastPinchDistance=nil return end
 if state==Enum.UserInputState.Begin then
  lastPinchDistance=scale
 elseif state==Enum.UserInputState.Change then
  if lastPinchDistance then
   local delta=scale-lastPinchDistance
   zoomDistance=math.clamp(zoomDistance-delta*9,MIN_ZOOM,MAX_ZOOM)
  end
  lastPinchDistance=scale
 else
  lastPinchDistance=nil
 end
end)

UIS.InputChanged:Connect(function(input)
 if currentSeat() and input.UserInputType==Enum.UserInputType.MouseWheel then
  zoomDistance=math.clamp(zoomDistance-input.Position.Z*2.2,MIN_ZOOM,MAX_ZOOM)
 end
end)

local hiddenCharacter={}
local function setDriverHidden(hidden)
 local char=player.Character
 if not char then return end
 if hidden then
  table.clear(hiddenCharacter)
  for _,d in ipairs(char:GetDescendants()) do
   if d:IsA("BasePart") then
    hiddenCharacter[d]=d.LocalTransparencyModifier
    d.LocalTransparencyModifier=1
   elseif d:IsA("Decal") then
    hiddenCharacter[d]=d.Transparency
    d.Transparency=1
   end
  end
 else
  for obj,value in pairs(hiddenCharacter) do
   if obj and obj.Parent then
    if obj:IsA("BasePart") then obj.LocalTransparencyModifier=value
    elseif obj:IsA("Decal") then obj.Transparency=value end
   end
  end
  table.clear(hiddenCharacter)
 end
end

local savedTouchGuiEnabled=nil
local function forceTouchGuiOff()
 local playerGui=player:FindFirstChildOfClass("PlayerGui")
 if not playerGui then return end
 for _,child in ipairs(playerGui:GetChildren()) do
  if child.Name=="TouchGui" and child:IsA("ScreenGui") then
   if savedTouchGuiEnabled==nil then savedTouchGuiEnabled=child.Enabled end
   child.Enabled=false
  end
 end
end

local function setDefaultMobileControlsHidden(hidden)
 if hidden then
  if playerControls then pcall(function() playerControls:Disable() end) end
  forceTouchGuiOff()
 else
  if playerControls then pcall(function() playerControls:Enable() end) end
  local playerGui=player:FindFirstChildOfClass("PlayerGui")
  if playerGui then
   for _,child in ipairs(playerGui:GetChildren()) do
    if child.Name=="TouchGui" and child:IsA("ScreenGui") then
     child.Enabled=(savedTouchGuiEnabled~=false)
    end
   end
  end
  savedTouchGuiEnabled=nil
 end
end

local wasDriving=false
RunService.RenderStepped:Connect(function()
 local driving=currentSeat()~=nil
 if driving~=wasDriving then
  wasDriving=driving
  setDriverHidden(driving)
  setDefaultMobileControlsHidden(driving)
 end
 if driving then
  -- PlayerModule/TouchGui can be rebuilt by Roblox after seating; enforce the
  -- driving state continuously so jump/movement controls cannot reappear.
  forceTouchGuiOff()
  if playerControls then pcall(function() playerControls:Disable() end) end
  local char=player.Character
  if char then
   for _,d in ipairs(char:GetDescendants()) do
    if d:IsA("BasePart") then d.LocalTransparencyModifier=1 end
   end
  end
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
