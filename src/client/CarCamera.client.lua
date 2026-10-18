local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")

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
