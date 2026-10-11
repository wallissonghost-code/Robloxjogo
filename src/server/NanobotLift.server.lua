local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local remote=RS:FindFirstChild("NanobotLift") or Instance.new("RemoteEvent")
remote.Name="NanobotLift"; remote.Parent=RS
local HEIGHT,UP,DOWN=34,10,11
local states={}
local function floorY(pos,char)
 local p=RaycastParams.new(); p.FilterType=Enum.RaycastFilterType.Exclude;p.FilterDescendantsInstances={char}
 local hit=workspace:Raycast(pos+Vector3.new(0,4,0),Vector3.new(0,-250,0),p)
 return hit and hit.Position.Y or 0
end
local function stop(plr)
 local s=states[plr];if not s then return end
 states[plr]=nil;if s.c then s.c:Disconnect() end;if s.part then s.part:Destroy() end
 remote:FireAllClients("off",plr)
end
local function start(plr)
 if states[plr] then states[plr].mode="up";return end
 local ch=plr.Character;local hum=ch and ch:FindFirstChildOfClass("Humanoid");local root=ch and ch:FindFirstChild("HumanoidRootPart")
 if not hum or hum.Health<=0 or not root then return end
 local part=Instance.new("Part");part.Name="NanobotSupport";part.Size=Vector3.new(9,.7,9);part.Anchored=true;part.CanCollide=true;part.Transparency=1;part.Parent=workspace
 local s={ch=ch,hum=hum,root=root,part=part,height=0,mode="up",ground=floorY(root.Position,ch)};states[plr]=s
 remote:FireAllClients("on",plr)
 s.c=RunService.Heartbeat:Connect(function(dt)
  if states[plr]~=s or not ch.Parent or hum.Health<=0 or not root.Parent then stop(plr);return end
  dt=math.min(dt,.05)
  local gy=floorY(root.Position,ch);s.ground+=math.clamp(gy-s.ground,-6*dt,6*dt)
  local target=s.mode=="up" and HEIGHT or 0;local speed=s.mode=="up" and UP or DOWN;local old=s.height
  if s.height<target then s.height=math.min(target,s.height+speed*dt) else s.height=math.max(target,s.height-speed*dt) end
  part.Position=Vector3.new(root.Position.X,s.ground+s.height+.35,root.Position.Z)
  local dy=s.height-old;if math.abs(dy)>.0001 then ch:PivotTo(ch:GetPivot()+Vector3.new(0,dy,0)) end
  remote:FireAllClients("state",plr,part.Position,s.height,target)
  if s.mode=="down" and s.height<=.05 then stop(plr) end
 end)
end
remote.OnServerEvent:Connect(function(plr,cmd)
 if cmd=="subir" then start(plr) elseif cmd=="descer" and states[plr] then states[plr].mode="down" end
end)
Players.PlayerRemoving:Connect(stop)
