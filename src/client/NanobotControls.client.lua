local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local remote=RS:WaitForChild("NanobotLift")
local gui=Instance.new("ScreenGui");gui.Name="NanobotControls";gui.ResetOnSpawn=false;gui.Parent=player:WaitForChild("PlayerGui")
local status=Instance.new("TextLabel");status.Size=UDim2.fromOffset(250,30);status.Position=UDim2.new(.5,0,0,16);status.AnchorPoint=Vector2.new(.5,0);status.BackgroundColor3=Color3.fromRGB(12,14,18);status.TextColor3=Color3.new(1,1,1);status.TextScaled=true;status.Font=Enum.Font.GothamBold;status.Text="VOZ: INICIANDO";status.Parent=gui
local function btn(txt,x)local b=Instance.new("TextButton");b.Size=UDim2.fromOffset(105,44);b.Position=UDim2.new(1,x,1,-105);b.AnchorPoint=Vector2.new(1,0);b.BackgroundColor3=Color3.fromRGB(15,18,24);b.TextColor3=Color3.new(1,1,1);b.TextScaled=true;b.Font=Enum.Font.GothamBold;b.Text=txt;b.Parent=gui;return b end
btn("SUBIR",-18).Activated:Connect(function()remote:FireServer("subir")end)
btn("DESCER",-133).Activated:Connect(function()remote:FireServer("descer")end)
UIS.InputBegan:Connect(function(i,p)if p then return end;if i.KeyCode==Enum.KeyCode.E then remote:FireServer("subir")elseif i.KeyCode==Enum.KeyCode.Q then remote:FireServer("descer")end end)
local function norm(s)return string.lower(s):gsub("[áàâã]","a"):gsub("[éê]","e"):gsub("í","i"):gsub("[óôõ]","o"):gsub("ú","u")end
local ok,err=pcall(function()
 local input=Instance.new("AudioDeviceInput");input.Name="NanobotMic";input.Player=player;input.Parent=gui
 local stt=Instance.new("AudioSpeechToText");stt.Name="NanobotSTT";stt.Enabled=true;stt.Parent=gui
 local wire=Instance.new("Wire");wire.SourceInstance=input;wire.TargetInstance=stt;wire.Parent=gui
 status.Text="VOZ: OUVINDO"
 stt:GetPropertyChangedSignal("Text"):Connect(function()
  local raw=stt.Text;if raw==""then return end
  status.Text="OUVI: "..string.sub(raw,1,24);local t=norm(raw)
  if t:find("subir",1,true)then remote:FireServer("subir")elseif t:find("descer",1,true)then remote:FireServer("descer")end
  task.delay(1.5,function()if status.Parent then status.Text="VOZ: OUVINDO"end end)
 end)
end)
if not ok then status.Text="VOZ: FALHOU";warn("Nanobot voice:",err)end
local COUNT=650
local swarms={}
local function remove(owner)local s=swarms[owner];if not s then return end;swarms[owner]=nil;if s.c then s.c:Disconnect()end;if s.folder then s.folder:Destroy()end end
local function create(owner)
 remove(owner);local folder=Instance.new("Folder");folder.Name="Nanobots";folder.Parent=workspace;local rng=Random.new(owner.UserId+937);local parts,data={},{}
 for i=1,COUNT do local p=Instance.new("Part");p.Size=Vector3.new(.24,.16,.34)*rng:NextNumber(.7,1.3);p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Material=Enum.Material.Metal;local sh=rng:NextInteger(3,20);p.Color=Color3.fromRGB(sh,sh,sh+4);p.Parent=folder;parts[i]=p;data[i]={a=rng:NextNumber(0,6.283),r=math.sqrt(rng:NextNumber()),layer=rng:NextNumber(),lag=rng:NextNumber(),phase=rng:NextNumber(0,6.283)}end
 local s={folder=folder,parts=parts,data=data};swarms[owner]=s
 s.c=RunService.RenderStepped:Connect(function()
  if not s.pos then return end;local root=owner.Character and owner.Character:FindFirstChild("HumanoidRootPart");if not root then return end
  local v=root.AssemblyLinearVelocity;local flat=Vector3.new(v.X,0,v.Z);local look=root.CFrame.LookVector*Vector3.new(1,0,1);local dir=flat.Magnitude>.8 and flat.Unit or (look.Magnitude>.1 and look.Unit or Vector3.new(0,0,-1));local right=Vector3.new(-dir.Z,0,dir.X);local now=os.clock()
  for i,p in parts do local d=data[i];local flow=((d.lag+now*(.15+math.min(flat.Magnitude/20,.4)))%1)*2-1;local forward=flow*9;local side=math.sin(d.a+now*.45)*(1+d.r*5);local topBias=d.layer*d.layer;local y=s.pos.Y-s.height-1+topBias*math.max(s.height-2,1)+math.sin(now*5+d.phase)*.12;local tight=.65*topBias;side*=1-tight;forward*=1-tight;p.CFrame=CFrame.new(Vector3.new(s.pos.X,y,s.pos.Z)+right*side+dir*forward)end
 end)
end
remote.OnClientEvent:Connect(function(action,owner,pos,height)
 if action=="on"then create(owner)elseif action=="state"then local s=swarms[owner];if s then s.pos=pos;s.height=height or 0 end elseif action=="off"then task.delay(.5,function()remove(owner)end)end
end)
