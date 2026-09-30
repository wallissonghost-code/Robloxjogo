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
local startupStage="BOOT"
pushRemote.OnServerEvent:Connect(function(player)
	if not serverReady then
		diagnosticRemote:FireClient(player,"REMOTE OK / SERVER NAO PRONTO",(startupError or "travou na etapa: "..startupStage))
	end
end)

local old=workspace:FindFirstChild(NAME)
if old then old:Destroy() end

startupStage="LOADASSET"
local ok,container=pcall(function()
	return InsertService:LoadAsset(ASSET_ID)
end)
if not ok then
	startupError="LoadAsset falhou: "..tostring(container)
	warn("[Gojo] LoadAsset failed:",container)
	return
end

startupStage="LOADASSET OK / CHILDREN"
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
startupStage="MODELO OK / SCALE"

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

	-- Parts alone are not enough: once the R6 is unanchored, Motor6D/Weld
	-- offsets become authoritative. Scale their positional offsets too.
	local function scaleJointCF(cf)
		local p=cf.Position
		local rotation=cf-p
		return CFrame.new(p*2.5)*rotation
	end
	for _,joint in ipairs(instance:GetDescendants()) do
		if joint:IsA("Motor6D") or joint:IsA("Weld") then
			joint.C0=scaleJointCF(joint.C0)
			joint.C1=scaleJointCF(joint.C1)
		end
	end
end

scaleGojo(gojo)
startupStage="SCALE OK / POSITION"

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

-- Convert the imported statue into a real R6 assembly after scaling/positioning.
local humanoid=gojo:FindFirstChildOfClass("Humanoid")
local hrp=gojo:FindFirstChild("HumanoidRootPart",true)
if humanoid and hrp and hrp:IsA("BasePart") then
	humanoid.PlatformStand=false
	humanoid.AutoRotate=true
	humanoid.WalkSpeed=34
	humanoid.JumpPower=50
	humanoid.HipHeight=0
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	for _,v in ipairs(gojo:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Anchored=false
			v.Massless=(v~=hrp)
			v.CanCollide=false
		end
	end
	hrp.CanCollide=true
	pcall(function() hrp:SetNetworkOwner(nil) end)
end
startupStage="POSITION OK / FUNCOES"

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

startupStage="FUNCOES BASE OK / MOTORS"
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
local rightHip=motor("Right Hip")
local leftHip=motor("Left Hip")
local rootJoint=motor("RootJoint")
local rightBase=rightShoulder and rightShoulder.C0
startupStage="MOTORS OK / ATTACK SETUP"
local leftBase=leftShoulder and leftShoulder.C0

local rightHipBase=rightHip and rightHip.C0
local leftHipBase=leftHip and leftHip.C0
local rootBase=rootJoint and rootJoint.C0

local function setMotorOffset(m,base,offset)
	if m and base then m.C0=base*offset end
end

local function resetPose()
	if rightShoulder and rightBase then rightShoulder.C0=rightBase end
	if leftShoulder and leftBase then leftShoulder.C0=leftBase end
	if rightHip and rightHipBase then rightHip.C0=rightHipBase end
	if leftHip and leftHipBase then leftHip.C0=leftHipBase end
	if rootJoint and rootBase then rootJoint.C0=rootBase end
end

local function setLegSwing(joint,base,angle)
	if not joint or not base then return end
	-- Imported rig uses an unusual hip basis. Rotate the joint attachment in torso space
	-- around torso RightVector, which is the physical hinge axis for forward/back leg swing.
	local torso=joint.Part0
	if not torso then return end
	local worldAxis=torso.CFrame.RightVector
	local localAxis=base:VectorToObjectSpace(torso.CFrame:VectorToObjectSpace(worldAxis))
	joint.C0=base*CFrame.fromAxisAngle(localAxis,angle)
end

local function runPose(phase)
	local swing=math.sin(phase)
	-- Keep the proven hip-axis solution, but remove all lateral/bounce motion.
	-- Legs alternate only forward/back. Arms stay neutral for now so we can
	-- validate a clean lower-body run before adding arm swing back.
	setLegSwing(rightHip,rightHipBase,math.rad(24*swing))
	setLegSwing(leftHip,leftHipBase,math.rad(-24*swing))
	if rightShoulder and rightBase then rightShoulder.C0=rightBase end
	if leftShoulder and leftBase then leftShoulder.C0=leftBase end
	if rootJoint and rootBase then rootJoint.C0=rootBase*CFrame.Angles(math.rad(-3),0,0) end
end

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

local function makeRed(position)
	local core=Instance.new("Part")
	core.Name="GojoRed"
	core.Shape=Enum.PartType.Ball
	core.Size=Vector3.new(1.35,1.35,1.35)
	core.Material=Enum.Material.Neon
	core.Color=Color3.fromRGB(255,35,45)
	core.Transparency=.02
	core.Anchored=true
	core.CanCollide=false
	core.CanTouch=false
	core.CanQuery=false
	core.Position=position
	core.Parent=workspace
	local light=Instance.new("PointLight")
	light.Color=core.Color
	light.Brightness=12
	light.Range=45
	light.Parent=core
	local aura=Instance.new("Part")
	aura.Name="RedAura"
	aura.Shape=Enum.PartType.Ball
	aura.Size=Vector3.new(7,7,7)
	aura.Material=Enum.Material.Neon
	aura.Color=Color3.fromRGB(255,55,65)
	aura.Transparency=.78
	aura.Anchored=true
	aura.CanCollide=false
	aura.CanTouch=false
	aura.CanQuery=false
	aura.Position=position
	aura.Parent=workspace
	local att=Instance.new("Attachment"); att.Parent=core
	local particles=Instance.new("ParticleEmitter")
	particles.Color=ColorSequence.new(Color3.fromRGB(255,220,220),core.Color)
	particles.LightEmission=1
	particles.Rate=190
	particles.Lifetime=NumberRange.new(.15,.35)
	particles.Speed=NumberRange.new(5,12)
	particles.SpreadAngle=Vector2.new(180,180)
	particles.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,1.3),NumberSequenceKeypoint.new(1,0)})
	particles.Parent=att
	return core,aura
end

local function handPosition()
	local hand=gojo:FindFirstChild("Right Arm",true)
	if hand and hand:IsA("BasePart") then
		return hand.Position-hand.CFrame.UpVector*(hand.Size.Y*.55)
	end
	return gojoOrigin()
end

local function attackPlayer(player,mode)
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
	if mode=="redThrow" then diag(player,"ATAQUE","Red arremessado") end
	local okAttack,err=pcall(function()
		diag(player,"1 FACE","virando para o player")
		-- Face player first.
		local gp=gojo:GetPivot()
		local look=Vector3.new(root.Position.X,gp.Position.Y,root.Position.Z)
		if (look-gp.Position).Magnitude>.1 then gojo:PivotTo(CFrame.lookAt(gp.Position,look)) end

		diag(player,"2 BRACOS","conjuracao Blue limpa")
		-- Clean test pose: lower body and left arm stay neutral.
		-- Only the right arm performs the Blue casting motion.
		if leftShoulder and leftBase then leftShoulder.C0=leftBase end
		if rightHip and rightHipBase then rightHip.C0=rightHipBase end
		if leftHip and leftHipBase then leftHip.C0=leftHipBase end
		if rootJoint and rootBase then rootJoint.C0=rootBase*CFrame.Angles(math.rad(-3),0,0) end
		if rightShoulder and rightBase then
			-- Pull the casting arm back, then smoothly extend it.
			rightShoulder.C0=rightBase*CFrame.Angles(math.rad(18),0,math.rad(18))
			task.wait(.18)
			local from=rightShoulder.C0
			local target=rightBase*CFrame.Angles(math.rad(-72),0,math.rad(6))
			local tw=TweenService:Create(rightShoulder,TweenInfo.new(.32,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{C0=target})
			tw:Play()
			tw.Completed:Wait()
		end
		task.wait(.12)

		-- Blue is intentionally spawned above/in front of Gojo so the test is unmistakable.
		local blue
		local redAura
		if mode=="redThrow" then
			diag(player,"3 RED","nucleo concentrado + aura")
			blue,redAura=makeRed(handPosition())
			for i=1,16 do
				if not blue.Parent then break end
				blue.Position=handPosition()
				if redAura and redAura.Parent then
					redAura.Position=blue.Position
					local pulse=7+math.sin(i*.9)*1.4
					redAura.Size=Vector3.new(pulse,pulse,pulse)
				end
				task.wait(.03)
			end
			task.wait(.12)
		else
			diag(player,"3 BLUE","criando esfera")
			local blue=makeBlue(handPosition())
			for i=1,24 do
				if not blue.Parent then break end
				blue.Position=handPosition()
				local t=i/24
				local smooth=t*t*(3-2*t)
				local size=1.2+(6.8*smooth)
				blue.Size=Vector3.new(size,size,size)
				task.wait(.03)
			end
			task.wait(.18)
	
	
		end

		if mode=="blueThrow" then
			diag(player,"4 BLUE THROW","arremessando + atracao controlada")
			local startPos=blue.Position
			for i=1,36 do
				if not blue.Parent or not root.Parent then break end
				local targetPos=root.Position+Vector3.new(0,2,0)
				local t=i/36
				local smooth=1-(1-t)*(1-t)
				blue.Position=startPos:Lerp(targetPos,smooth)
				for _,p in ipairs(Players:GetPlayers()) do
					local ch=p.Character
					local pr=ch and ch:FindFirstChild("HumanoidRootPart")
					local ph=ch and ch:FindFirstChildOfClass("Humanoid")
					if pr and ph and ph.Health>0 then
						local pull=blue.Position-pr.Position
						local dist=pull.Magnitude
						if dist>2 and dist<48 then
							local desired=pull.Unit*math.clamp(24+(48-dist)*1.15,24,72)
							pr.AssemblyLinearVelocity=pr.AssemblyLinearVelocity:Lerp(desired,.22)
						end
					end
				end
				task.wait(.025)
			end
		elseif mode=="redThrow" then
			diag(player,"4 RED THROW","arremessando")
			local startPos=blue.Position
			for i=1,30 do
				if not blue.Parent or not root.Parent then break end
				local targetPos=root.Position+Vector3.new(0,2,0)
				local t=i/30
				local smooth=1-(1-t)*(1-t)
				blue.Position=startPos:Lerp(targetPos,smooth)
				if redAura and redAura.Parent then redAura.Position=blue.Position end
				task.wait(.022)
			end
			if root.Parent then
				local away=root.Position-blue.Position
				if away.Magnitude<14 then
					local horizontal=Vector3.new(away.X,0,away.Z)
					if horizontal.Magnitude>.01 then
						root.AssemblyLinearVelocity=horizontal.Unit*420+Vector3.new(0,42,0)
					end
				end
			end
		end
		if redAura and redAura.Parent then
			TweenService:Create(redAura,TweenInfo.new(.14),{Size=Vector3.new(16,16,16),Transparency=1}):Play()
			Debris:AddItem(redAura,.18)
		end
		diag(player,"5 BLUE","finalizando atracao")
		if blue.Parent then
			TweenService:Create(blue,TweenInfo.new(.16),{Size=Vector3.new(12,12,12),Transparency=1}):Play()
			Debris:AddItem(blue,.22)
		end
	end)

	resetPose()
	if not okAttack then
		warn("[Gojo Blue] attack failed:",err)
		diag(player,"ERRO LUA",err)
	else
		diag(player,"CONCLUIDO","ataque terminou sem erro Lua")
	end
	task.wait(.35)
	attacking=false
end

local function sendRigDiagnostic(player)
	local lines={}
	local function add(x) table.insert(lines,tostring(x)) end
	local hum=gojo:FindFirstChildOfClass("Humanoid")
	local animator=hum and hum:FindFirstChildOfClass("Animator")
	local motors,welds,parts,attachments=0,0,0,0
	add("=== GOJO RIG DIAGNOSTICO ===")
	add("Asset: "..ASSET_ID)
	add("Classe raiz: "..gojo.ClassName)
	add("Humanoid: "..tostring(hum~=nil))
	add("RigType: "..tostring(hum and hum.RigType or "N/A"))
	add("Animator: "..tostring(animator~=nil))
	for _,v in ipairs(gojo:GetDescendants()) do
		if v:IsA("Motor6D") then motors+=1
		elseif v:IsA("Weld") or v:IsA("WeldConstraint") then welds+=1
		elseif v:IsA("BasePart") then parts+=1
		elseif v:IsA("Attachment") then attachments+=1 end
	end
	add("Parts: "..parts.." | Motor6D: "..motors.." | Welds: "..welds.." | Attach: "..attachments)
	add("")
	add("--- MOTOR6D ---")
	for _,v in ipairs(gojo:GetDescendants()) do
		if v:IsA("Motor6D") then
			add(v.Name.." | "..(v.Part0 and v.Part0.Name or "nil").." -> "..(v.Part1 and v.Part1.Name or "nil"))
		end
	end
	add("")
	add("--- WELDS / CONSTRAINTS ---")
	for _,v in ipairs(gojo:GetDescendants()) do
		if v:IsA("Weld") then
			add("Weld "..v.Name.." | "..(v.Part0 and v.Part0.Name or "nil").." -> "..(v.Part1 and v.Part1.Name or "nil"))
		elseif v:IsA("WeldConstraint") then
			add("Constraint "..v.Name.." | "..(v.Part0 and v.Part0.Name or "nil").." <-> "..(v.Part1 and v.Part1.Name or "nil"))
		end
	end
	add("")
	add("--- PARTES VISUAIS ---")
	for _,v in ipairs(gojo:GetDescendants()) do
		if v:IsA("BasePart") then
			add(v.Name.." ["..v.ClassName.."] A="..tostring(v.Anchored).." C="..tostring(v.CanCollide).." size="..string.format("%.1f,%.1f,%.1f",v.Size.X,v.Size.Y,v.Size.Z))
		end
	end
	diagnosticRemote:FireClient(player,"RIG_FULL",table.concat(lines,"\n"))
end

local function testLegs(player)
	if attacking then diag(player,"BLOQUEADO","ataque em andamento"); return end
	attacking=true
	diag(player,"TESTE PERNAS","alternando pernas R6 lentamente")
	local okLegs,err=pcall(function()
		resetPose()
		for cycle=1,6 do
			-- Hold each extreme long enough to be unmistakable.
			setLegSwing(rightHip,rightHipBase,math.rad(75))
			setLegSwing(leftHip,leftHipBase,math.rad(-75))
			task.wait(.55)
			setLegSwing(rightHip,rightHipBase,math.rad(-75))
			setLegSwing(leftHip,leftHipBase,math.rad(75))
			task.wait(.55)
		end
	end)
	resetPose()
	if not okLegs then diag(player,"ERRO PERNAS",err) else diag(player,"TESTE PERNAS","concluido") end
	attacking=false
end

startupStage="READY"
serverReady=true
pushRemote.OnServerEvent:Connect(function(player,mode)
	if mode=="diagnostic" then
		sendRigDiagnostic(player)
		return
	end
	if mode=="legs" then
		diag(player,"REMOTE OK","modo=legs")
		task.spawn(testLegs,player)
		return
	end
	if mode~="blueThrow" and mode~="redThrow" then mode="blueThrow" end
	diag(player,"REMOTE OK","modo="..mode)
	task.spawn(attackPlayer,player,mode)
end)

print("[Gojo] R6 Blue rush ready")
