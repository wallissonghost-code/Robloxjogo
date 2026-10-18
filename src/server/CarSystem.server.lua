local InsertService=game:GetService("InsertService")
local Players=game:GetService("Players")

local CAR_ASSET_ID=4520224711
local SPAWN=CFrame.new(0,4,0)

local function partsOf(root)
 local t={}
 if root:IsA("BasePart") then table.insert(t,root) end
 for _,d in ipairs(root:GetDescendants()) do if d:IsA("BasePart") then table.insert(t,d) end end
 return t
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
 local seat=car:FindFirstChildWhichIsA("VehicleSeat",true)
 if not seat then
  seat=Instance.new("VehicleSeat"); seat.Name="DriverSeat"; seat.Size=Vector3.new(2,1,2)
  seat.Parent=car
  local min,max=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
  for _,p in ipairs(parts) do min=Vector3.new(math.min(min.X,p.Position.X),math.min(min.Y,p.Position.Y),math.min(min.Z,p.Position.Z)); max=Vector3.new(math.max(max.X,p.Position.X),math.max(max.Y,p.Position.Y),math.max(max.Z,p.Position.Z)) end
  seat.CFrame=CFrame.new((min+max)*.5+Vector3.new(0,1,0))
  table.insert(parts,seat)
 end
 local root=seat
 for _,p in ipairs(parts) do
  p.Anchored=false
  if p~=root then
   local w=Instance.new("WeldConstraint"); w.Part0=root; w.Part1=p; w.Parent=root
  end
 end
 root.Anchored=false
 seat.MaxSpeed=70; seat.Torque=45000; seat.TurnSpeed=2.2
 if car:IsA("Model") then car.PrimaryPart=root; car:PivotTo(SPAWN) else root.CFrame=SPAWN end
 seat:SetAttribute("TrendCarDriverSeat",true)
 seat:GetPropertyChangedSignal("Occupant"):Connect(function()
  local hum=seat.Occupant
  if hum then
   local plr=Players:GetPlayerFromCharacter(hum.Parent)
   if plr then pcall(function() root:SetNetworkOwner(plr) end) end
  else pcall(function() root:SetNetworkOwnershipAuto() end) end
 end)
 print("[CarSystem] Carro pronto asset "..CAR_ASSET_ID)
end

task.spawn(prepareCar)
