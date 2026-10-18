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
local ACCEL=105
local BRAKE=85
local COAST_DRAG=18
local TURN_RATE_LOW=115
local TURN_RATE_HIGH=58
local LATERAL_GRIP=10

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
 seat.CanTouch=false
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
 chassis.CustomPhysicalProperties=PhysicalProperties.new(1.2,.85,.05,100,100)
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

 -- Explicit interaction: touching the invisible seat must never auto-enter.
 local promptPart=Instance.new("Part")
 promptPart.Name="DrivePrompt"
 promptPart.Size=Vector3.new(2.2,2.2,2.2)
 promptPart.Transparency=1
 promptPart.CanCollide=false
 promptPart.CanTouch=false
 promptPart.CanQuery=true
 promptPart.Anchored=false
 promptPart.CFrame=seat.CFrame* CFrame.new(-2.3,0,0)
 promptPart.Parent=car
 local pw=Instance.new("WeldConstraint"); pw.Part0=chassis; pw.Part1=promptPart; pw.Parent=chassis
 local prompt=Instance.new("ProximityPrompt")
 prompt.Name="PilotPrompt"
 prompt.ActionText="Pilotar"
 prompt.ObjectText="Veículo"
 prompt.KeyboardKeyCode=Enum.KeyCode.E
 prompt.GamepadKeyCode=Enum.KeyCode.ButtonX
 prompt.HoldDuration=0
 prompt.MaxActivationDistance=9
 prompt.RequiresLineOfSight=false
 prompt.Parent=promptPart
 prompt.Triggered:Connect(function(plr)
  if seat.Occupant then return end
  local char=plr.Character
  local hum=char and char:FindFirstChildOfClass("Humanoid")
  local root=char and char:FindFirstChild("HumanoidRootPart")
  if not hum or hum.Health<=0 or not root then return end
  if (root.Position-promptPart.Position).Magnitude>12 then return end
  seat:Sit(hum)
 end)

 local speed=0
 local heading=math.atan2(-chassis.CFrame.LookVector.X,-chassis.CFrame.LookVector.Z)
 controlEvent.OnServerEvent:Connect(function(player,throttle,steer)
  if seat.Occupant and Players:GetPlayerFromCharacter(seat.Occupant.Parent)==player then
   mobileControls[player]={throttle=math.clamp(tonumber(throttle) or 0,-1,1),steer=math.clamp(tonumber(steer) or 0,-1,1)}
  end
 end)
 seat:GetPropertyChangedSignal("Occupant"):Connect(function()
  local hum=seat.Occupant
  prompt.Enabled=(hum==nil)
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
  if throttle>0.05 then target=-FORWARD_SPEED*throttle
  elseif throttle<-.05 then target=-REVERSE_SPEED*throttle end

  -- Arcade-mobile throttle: quick response without instant speed snapping.
  local reversing=(speed~=0 and target~=0 and math.sign(speed)~=math.sign(target))
  local rate=reversing and BRAKE or (target==0 and COAST_DRAG or ACCEL)
  speed += math.clamp(target-speed,-rate*dt,rate*dt)
  if target==0 and math.abs(speed)<.12 then speed=0 end

  local cf=chassis.CFrame
  local forward=cf.LookVector
  local right=cf.RightVector
  local velocity=chassis.AssemblyLinearVelocity

  -- Strong lateral grip keeps the car pointed where the player steers.
  local verticalY=velocity.Y
  local lateralSpeed=velocity:Dot(right)
  local grip=1-math.exp(-LATERAL_GRIP*dt)
  local planar=Vector3.new(velocity.X,0,velocity.Z)-right*lateralSpeed*grip
  local desired=Vector3.new(forward.X,0,forward.Z)*speed
  planar=planar:Lerp(desired,1-math.exp(-14*dt))
  chassis.AssemblyLinearVelocity=Vector3.new(planar.X,verticalY,planar.Z)

  -- Steering responds from almost zero speed. High speed only reduces it
  -- moderately, which feels much better with a touchscreen analog stick.
  local absSpeed=math.abs(speed)
  local ratio=math.clamp(absSpeed/FORWARD_SPEED,0,1)
  local turnDeg=TURN_RATE_LOW+(TURN_RATE_HIGH-TURN_RATE_LOW)*ratio
  local direction=speed>=0 and 1 or -1
  local movementAuthority=math.clamp(absSpeed/2.5,.55,1)
  local yaw=0
  if math.abs(steer)>.025 and absSpeed>.08 then
   yaw=math.rad(turnDeg)*steer*direction*movementAuthority
  end

  local av=chassis.AssemblyAngularVelocity
  chassis.AssemblyAngularVelocity=Vector3.new(av.X*.45,yaw,av.Z*.45)
 end)

 print("[CarSystem] Carro dirigivel pronto | frente/re/volante | asset "..CAR_ASSET_ID)
end

task.spawn(prepareCar)
