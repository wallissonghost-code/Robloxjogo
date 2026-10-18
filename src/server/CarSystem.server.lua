local InsertService=game:GetService("InsertService")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local controlEvent=ReplicatedStorage:FindFirstChild("TrendCarControl") or Instance.new("RemoteEvent")
controlEvent.Name="TrendCarControl"; controlEvent.Parent=ReplicatedStorage
local mobileControls={}

local CAR_ASSET_ID=4520224711
local SPAWN=CFrame.new(0,4,0)
local FORWARD_SPEED=55
local REVERSE_SPEED=28
local ACCEL=42
local BRAKE=65
local TURN_RATE=105

local function partsOf(root)
 local t={}
 if root:IsA("BasePart") then table.insert(t,root) end
 for _,d in ipairs(root:GetDescendants()) do if d:IsA("BasePart") then table.insert(t,d) end end
 return t
end

local function bounds(parts)
 local mn=Vector3.new(math.huge,math.huge,math.huge)
 local mx=Vector3.new(-math.huge,-math.huge,-math.huge)
 for _,p in ipairs(parts) do
  local pos=p.Position
  mn=Vector3.new(math.min(mn.X,pos.X-p.Size.X*.5),math.min(mn.Y,pos.Y-p.Size.Y*.5),math.min(mn.Z,pos.Z-p.Size.Z*.5))
  mx=Vector3.new(math.max(mx.X,pos.X+p.Size.X*.5),math.max(mx.Y,pos.Y+p.Size.Y*.5),math.max(mx.Z,pos.Z+p.Size.Z*.5))
 end
 return mn,mx
end

local function prepareCar()
 local ok,pack=pcall(function() return InsertService:LoadAsset(CAR_ASSET_ID) end)
 if not ok or not pack then warn("[CarSystem] Falha asset "..tostring(pack)); return end
 local car=pack:GetChildren()[1]
 if not car then pack:Destroy(); return end
 car.Parent=workspace; car.Name="TrendFlyingCar"; pack:Destroy()

 for _,d in ipairs(car:GetDescendants()) do
  if d:IsA("Script") or d:IsA("LocalScript") then d.Disabled=true end
 end

 local parts=partsOf(car)
 if #parts==0 then warn("[CarSystem] Asset sem BasePart"); return end
 local mn,mx=bounds(parts)
 local center=(mn+mx)*.5
 local size=mx-mn

 -- Dedicated invisible driver's seat placed inside the cabin.
 local oldSeat=car:FindFirstChildWhichIsA("VehicleSeat",true)
 if oldSeat then oldSeat:Destroy() end
 local seat=Instance.new("VehicleSeat")
 seat.Name="DriverSeat"
 seat.Size=Vector3.new(1.8,.6,1.8)
 seat.Transparency=1
 seat.CanCollide=false
 seat.Anchored=false
 seat.MaxSpeed=FORWARD_SPEED
 seat.Torque=100000
 seat.TurnSpeed=2
 seat.Parent=car
 -- Approximate cabin: centered, slightly above the lower half of the body.
 seat.CFrame=CFrame.new(center.X,mn.Y+math.max(1.4,size.Y*.48),center.Z+size.Z*.06)*CFrame.Angles(0,math.rad(180),0)
 table.insert(parts,seat)

 -- Invisible chassis/root gives predictable custom movement.
 local chassis=Instance.new("Part")
 chassis.Name="DriveRoot"
 chassis.Size=Vector3.new(math.max(3,size.X*.72),.5,math.max(5,size.Z*.72))
 chassis.Transparency=1
 chassis.CanCollide=true
 chassis.Anchored=false
 chassis.CFrame=CFrame.new(center.X,mn.Y+.55,center.Z)
 chassis.Parent=car
 table.insert(parts,chassis)

 for _,p in ipairs(parts) do
  p.Anchored=false
  if p~=chassis then
   -- Visual shell must not fight the chassis physics.
   if p~=seat then p.CanCollide=false end
   local w=Instance.new("WeldConstraint"); w.Part0=chassis; w.Part1=p; w.Parent=chassis
  end
 end
 if car:IsA("Model") then car.PrimaryPart=chassis; car:PivotTo(SPAWN) else chassis.CFrame=SPAWN end
 seat:SetAttribute("TrendCarDriverSeat",true)

 local speed=0
 local heading=math.atan2(-chassis.CFrame.LookVector.X,-chassis.CFrame.LookVector.Z)
 controlEvent.OnServerEvent:Connect(function(player,throttle,steer)
  if seat.Occupant and Players:GetPlayerFromCharacter(seat.Occupant.Parent)==player then
   mobileControls[player]={throttle=math.clamp(tonumber(throttle) or 0,-1,1),steer=math.clamp(tonumber(steer) or 0,-1,1)}
  end
 end)
 seat:GetPropertyChangedSignal("Occupant"):Connect(function()
  local hum=seat.Occupant
  if hum then
   local plr=Players:GetPlayerFromCharacter(hum.Parent)
   if plr then pcall(function() chassis:SetNetworkOwner(nil) end) end
  else
   speed=0
   table.clear(mobileControls)
  end
 end)

 RunService.Heartbeat:Connect(function(dt)
  if not car.Parent or not chassis.Parent then return end
  local hum=seat.Occupant
  local throttle=hum and seat.ThrottleFloat or 0
  local steer=hum and seat.SteerFloat or 0
  if hum then
   local driver=Players:GetPlayerFromCharacter(hum.Parent)
   local input=driver and mobileControls[driver]
   if input then throttle=input.throttle; steer=input.steer end
  end
  local target=0
  if throttle>0.05 then target=FORWARD_SPEED*throttle
  elseif throttle<-.05 then target=REVERSE_SPEED*throttle end

  local rate=(math.abs(target)>math.abs(speed)) and ACCEL or BRAKE
  speed += math.clamp(target-speed,-rate*dt,rate*dt)

  -- Steering reverses naturally while backing up.
  if math.abs(speed)>.35 and math.abs(steer)>.02 then
   local direction=speed>=0 and 1 or -1
   local speedFactor=math.clamp(math.abs(speed)/12,.25,1)
   heading += math.rad(TURN_RATE)*steer*direction*speedFactor*dt
  end

  local pos=chassis.Position
  local forward=Vector3.new(math.sin(heading),0,math.cos(heading))
  local horizontal=forward*speed
  chassis.AssemblyLinearVelocity=Vector3.new(horizontal.X,chassis.AssemblyLinearVelocity.Y,horizontal.Z)
  chassis.AssemblyAngularVelocity=Vector3.zero
  -- Keep car upright while allowing vertical physics/gravity.
  local targetCF=CFrame.lookAt(pos,pos+forward,Vector3.yAxis)
  chassis.CFrame=chassis.CFrame:Lerp(targetCF,math.clamp(dt*10,0,1))
 end)

 print("[CarSystem] Carro dirigivel pronto | frente/re/volante | asset "..CAR_ASSET_ID)
end

task.spawn(prepareCar)
