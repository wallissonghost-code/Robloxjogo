local InsertService=game:GetService("InsertService")
local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local pushRemote=ReplicatedStorage:FindFirstChild("GojoPushTest") or Instance.new("RemoteEvent")
local diagnosticRemote=ReplicatedStorage:FindFirstChild("GojoDiagnostic") or Instance.new("RemoteEvent")
diagnosticRemote.Name="GojoDiagnostic"
diagnosticRemote.Parent=ReplicatedStorage
pushRemote.Name="GojoPushTest"
pushRemote.Parent=ReplicatedStorage

local ASSET_ID=14034779103
local NAME="ImportedGojo_"..ASSET_ID
local POS=Vector3.new(0,0,3)

local serverReady=false
local startupError=nil
pushRemote.OnServerEvent:Connect(function(player)
	if not serverReady then
		diagnosticRemote:FireClient(player,"REMOTE OK / SERVER NAO PRONTO",startupError or "Gojo ainda carregando")
	end
end)

local old=workspace:FindFirstChild(NAME)
if old then old:Destroy() end

local ok,container=pcall(function()
	return InsertService:LoadAsset(ASSET_ID)
end)
if not ok then
	startupError="LoadAsset falhou: "..tostring(container)
	warn("[Gojo] LoadAsset failed:",container)
	return
end

local children=container:GetChildren()
if #children==0 then
	warn("[Gojo] Asset returned 0 objects")
	startupError="LoadAsset retornou 0 objetos"
	container:Destroy()
	return
end

local gojo
if #children==1 then
	gojo=children[1]
	gojo.Parent=workspace
	container:Destroy()
else
	gojo=Instance.new("Model")
	for _,child in ipairs(children) do child.Parent=gojo end
	gojo.Parent=workspace
	container:Destroy()
end
gojo.Name=NAME

-- Keep the imported character static and scale him proportionally to 2.5x.
local function scaleGojo(instance)
	local parts={}
	if instance:IsA("BasePart") then table.insert(parts,instance) end
	for _,v in ipairs(instance:GetDescendants()) do
		if v:IsA("BasePart") then table.insert(parts,v) end
	end
	if #parts==0 then return end

	local pivot=instance:IsA("Model") and instance:GetPivot() or instance.CFrame
	for _,part in ipairs(parts) do
		part.Anchored=true
		local localCF=pivot:ToObjectSpace(part.CFrame)
		local p=localCF.Position
		local rotation=localCF-p
		part.Size=part.Size*2.5
		part.CFrame=pivot*CFrame.new(p*2.5)*rotation
	end
end

scaleGojo(gojo)

-- Put the scaled Gojo back on the floor.
if gojo:IsA("Model") then
	local cf,size=gojo:GetBoundingBox()
	local pivot=gojo:GetPivot()
	local bottom=cf.Position.Y-size.Y/2
	gojo:PivotTo(pivot+Vector3.new(POS.X-pivot.Position.X,POS.Y-bottom,POS.Z-pivot.Position.Z))
elseif gojo:IsA("BasePart") then
	gojo.Position=Vector3.new(POS.X,POS.Y+gojo.Size.Y/2,POS.Z)
end
gojo:SetAttribute("SourceAssetId",ASSET_ID)

local function gojoOrigin()
	if gojo:IsA("Model") then
		local cf,size=gojo:GetBoundingBox()
		-- Fire roughly from the upper torso/hand zone.
		return cf.Position+Vector3.new(0,size.Y*.18,0)
	elseif gojo:IsA("BasePart") then
		return gojo.Position+Vector3.new(0,gojo.Size.Y*.2,0)
	end
	return POS+Vector3.new(0,8,0)
end

local function nearestPlayer()
	local origin=gojoOrigin()
	local best,bestDistance
	for _,player in ipairs(Players:GetPlayers()) do
		local character=player.Character
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		local root=character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health>0 and root then
			local distance=(root.Position-origin).Magnitude
			if not bestDistance or distance<bestDistance then
				best=player
				bestDistance=distance
			end
		end
	end
	return best
end

local attacking=false
local function diag(player,step,message)
	print("[GojoDiag]",step,message or "")
	if player then diagnosticRemote:FireClient(player,step,tostring(message or "")) end
end

local function motor(name)
	for _,v in ipairs(gojo:GetDescendants()) do
		if v:IsA("Motor6D") and v.Name==name then return v end
	end
end

local rightShoulder=motor("Right Shoulder")
local leftShoulder=motor("Left Shoulder")
local rightBase=rightShoulder and rightShoulder.C0
local leftBase=leftShoulder and leftShoulder.C0

local function tweenMotor(m,c0,t)
	if not m then return end
	TweenService:Create(m,TweenInfo.new(t,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{C0=c0}):Play()
end

local function makeBlue(position)
	local ball=Instance.new("Part")
	ball.Name="GojoBlue"
	ball.Shape=Enum.PartType.Ball
	ball.Size=Vector3.new(1.2,1.2,1.2)
	ball.Material=Enum.Material.Neon
	ball.Color=Color3.fromRGB(55,135,255)
	ball.Transparency=.08
	ball.Anchored=true
	ball.CanCollide=false
	ball.CanTouch=false
	ball.CanQuery=false
	ball.Position=position
	ball.Parent=workspace
	local light=Instance.new("PointLight")
	light.Color=ball.Color
	light.Brightness=7
	light.Range=32
	light.Parent=ball
	local att=Instance.new("Attachment"); att.Parent=ball
	local p=Instance.new("ParticleEmitter")
	p.Color=ColorSequence.new(Color3.new(1,1,1),ball.Color)
	p.LightEmission=1
	p.Rate=150
	p.Lifetime=NumberRange.new(.2,.45)
	p.Speed=NumberRange.new(2,6)
	p.SpreadAngle=Vector2.new(180,180)
	p.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.8),NumberSequenceKeypoint.new(1,0)})
	p.Parent=att
	return ball
end

local function handPosition()
	local hand=gojo:FindFirstChild("Right Arm",true)
	if hand and hand:IsA("BasePart") then
		return hand.Position-hand.CFrame.UpVector*(hand.Size.Y*.55)
	end
	return gojoOrigin()
end

local function attackPlayer(player)
	if attacking then diag(player,"BLOQUEADO","attacking=true"); return end
	local character=player and player.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	local hum=character and character:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health<=0 or not gojo:IsA("Model") then
	diag(player,"ALVO INVALIDO","root="..tostring(root~=nil).." humanoid="..tostring(hum~=nil).." health="..tostring(hum and hum.Health).." gojoModel="..tostring(gojo:IsA("Model")))
	return
end
diag(player,"ALVO OK","player="..player.Name.." motors R/L="..tostring(rightShoulder~=nil).."/"..tostring(leftShoulder~=nil))
	attacking=true

	diag(player,"ATAQUE","iniciando")
	local okAttack,err=pcall(function()
		diag(player,"1 FACE","virando para o player")
		-- Face player first.
		local gp=gojo:GetPivot()
		local look=Vector3.new(root.Position.X,gp.Position.Y,root.Position.Z)
		if (look-gp.Position).Magnitude>.1 then gojo:PivotTo(CFrame.lookAt(gp.Position,look)) end

		diag(player,"2 BRACOS","aplicando pose R6")
		-- Pose both R6 shoulders directly. Transform is safer for a runtime pose.
		if rightShoulder then rightShoulder.Transform=CFrame.Angles(math.rad(-95),0,math.rad(12)) end
		if leftShoulder then leftShoulder.Transform=CFrame.Angles(math.rad(-35),0,math.rad(-10)) end

		-- Blue is intentionally spawned above/in front of Gojo so the test is unmistakable.
		diag(player,"3 BLUE","criando esfera")
		local blue=makeBlue(handPosition())
		for i=1,18 do
			if not blue.Parent then break end
			blue.Position=handPosition()
			local size=1.2+(6.8*(i/18))
			blue.Size=Vector3.new(size,size,size)
			task.wait(.04)
		end

		diag(player,"4 CORRIDA","iniciando PivotTo")
		-- Move the anchored model toward the live player. PivotTo works even while parts are anchored.
		for _=1,55 do
			if not root.Parent or not gojo.Parent then break end
			local current=gojo:GetPivot()
			local delta=Vector3.new(root.Position.X-current.Position.X,0,root.Position.Z-current.Position.Z)
			if delta.Magnitude<=8 then break end
			local step=math.min(1.15,math.max(0,delta.Magnitude-7.5))
			local newPos=current.Position+delta.Unit*step
			gojo:PivotTo(CFrame.lookAt(newPos,Vector3.new(root.Position.X,newPos.Y,root.Position.Z)))
			if blue.Parent then blue.Position=handPosition() end
			task.wait(.03)
		end

		diag(player,"5 IMPACTO","tentando empurrar")
		if root.Parent then
			local gp2=gojo:GetPivot().Position
			local away=Vector3.new(root.Position.X-gp2.X,0,root.Position.Z-gp2.Z)
			if away.Magnitude>.01 then
				root.AssemblyLinearVelocity=away.Unit*55+Vector3.new(0,12,0)
			end
		end
		if blue.Parent then
			TweenService:Create(blue,TweenInfo.new(.16),{Size=Vector3.new(12,12,12),Transparency=1}):Play()
			Debris:AddItem(blue,.22)
		end
	end)

	if rightShoulder then rightShoulder.Transform=CFrame.new() end
	if leftShoulder then leftShoulder.Transform=CFrame.new() end
	if not okAttack then
		warn("[Gojo Blue] attack failed:",err)
		diag(player,"ERRO LUA",err)
	else
		diag(player,"CONCLUIDO","ataque terminou sem erro Lua")
	end
	task.wait(.35)
	attacking=false
end

pushRemote.OnServerEvent:Connect(function(player)
	fireSphere(player,true)
end)

print("[Gojo] loaded, scale x2.5; spheres fire only from test button")
