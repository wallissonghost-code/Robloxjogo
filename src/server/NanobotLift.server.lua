local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local remote=RS:FindFirstChild("NanobotLift") or Instance.new("RemoteEvent");remote.Name="NanobotLift";remote.Parent=RS
local HEIGHT=34
local states={}
local function rayGround(root,char,support)
 local p=RaycastParams.new();p.FilterType=Enum.RaycastFilterType.Exclude;p.FilterDescendantsInstances={char,support}
 local hit=workspace:Raycast(root.Position+Vector3.new(0,2,0),Vector3.new(0,-300,0),p)
 return hit and hit.Position.Y or nil
end
local function stop(plr)
 local s=states[plr];if not s then return end;states[plr]=nil
 if s.c then s.c:Disconnect()end;if s.support then s.support:Destroy()end
 remote:FireAllClients("off",plr)
end
local function start(plr)
 if states[plr] then states[plr].mode="up";return end
 local ch=plr.Character;local hum=ch and ch:FindFirstChildOfClass("Humanoid");local root=ch and ch:FindFirstChild("HumanoidRootPart")
 if not hum or hum.Health<=0 or not root then return end
 local support=Instance.new("Part");support.Name="NanobotSupport";support.Size=Vector3.new(10,.8,10);support.Anchored=true;support.CanCollide=true;support.CanTouch=false;support.Transparency=1;support.Parent=workspace
 local ground=rayGround(root,ch,support);if not ground then support:Destroy();return end
 support.Position=Vector3.new(root.Position.X,ground+.4,root.Position.Z)
 local s={ch=ch,hum=hum,root=root,support=support,ground=ground,height=0,mode="up"};states[plr]=s
 remote:FireAllClients("on",plr)
 s.c=RunService.Heartbeat:Connect(function(dt)
  if states[plr]~=s or not ch.Parent or hum.Health<=0 or not root.Parent then stop(plr);return end
  dt=math.min(dt,.05)
  local g=rayGround(root,ch,support)
  if g then s.ground=g end
  local target=s.mode=="up" and HEIGHT or 0
  local speed=s.mode=="up" and 8 or 7
  s.height += math.clamp(target-s.height,-speed*dt,speed*dt)
  s.height=math.clamp(s.height,0,HEIGHT)
  local y=s.ground+s.height+.4
  support.Position=Vector3.new(root.Position.X,y,root.Position.Z)
  -- Only the support moves. Roblox physics carries the character naturally.
  remote:FireAllClients("state",plr,support.Position,s.height,target)
  if s.mode=="down" and s.height<=.02 then
   support.Position=Vector3.new(root.Position.X,s.ground+.4,root.Position.Z)
   task.defer(stop,plr)
  end
 end)
end
remote.OnServerEvent:Connect(function(plr,cmd)
 if cmd=="subir" then start(plr)
 elseif cmd=="descer" then local s=states[plr];if s then s.mode="down" end end
end)
Players.PlayerRemoving:Connect(stop)
