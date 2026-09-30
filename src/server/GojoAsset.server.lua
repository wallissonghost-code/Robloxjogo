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

local function clearBlueLock(player)
	local ch=player and player.Character
	local ph=ch and ch:FindFirstChildOfClass("Humanoid")
	local pr=ch and ch:FindFirstChild("HumanoidRootPart")
	if pr then
		local align=pr:FindFirstChild("BlueGravityHold")
		local orient=pr:FindFirstChild("BlueNoSpin")
		local att=pr:FindFirstChild("BlueLockAttachment")
		if align then align:Destroy() end
		if orient then orient:Destroy() end
		if att then att:Destroy() end
		pr.AssemblyLinearVelocity=Vector3.zero
		pr.AssemblyAngularVelocity=Vector3.zero
	end
	local target=workspace:FindFirstChild("BlueGravityTarget_"..tostring(player.UserId))
	if target then target:Destroy() end
	if ph then
		local walk=ph:GetAttribute("BlueSavedWalkSpeed")
		local jump=ph:GetAttribute("BlueSavedJumpPower")
		if walk then ph.WalkSpeed=walk end
		if jump then ph.JumpPower=jump end
		ph.AutoRotate=true
		ph.PlatformStand=false
	end
end

local function comboPlayer(player)
	if attacking then diag(player,"BLOQUEADO","attacking=true"); return end
	local ch=player and player.Character
	local ph=ch and ch:FindFirstChildOfClass("Humanoid")
	local pr=ch and ch:FindFirstChild("HumanoidRootPart")
	if not pr or not ph or ph.Health<=0 then return end
	attacking=true
	local okCombo,err=pcall(function()
		diag(player,"COMBO","BLUE -> LOCK -> RED")
		local gp=gojo:GetPivot()
		local look=Vector3.new(pr.Position.X,gp.Position.Y,pr.Position.Z)
		if (look-gp.Position).Magnitude>.1 then gojo:PivotTo(CFrame.lookAt(gp.Position,look)) end

		-- Confirmed casting pose.
		if leftShoulder and leftBase then leftShoulder.C0=leftBase end
		if rightHip and rightHipBase then rightHip.C0=rightHipBase end
		if leftHip and leftHipBase then leftHip.C0=leftHipBase end
		if rootJoint and rootBase then rootJoint.C0=rootBase*CFrame.Angles(math.rad(-3),0,0) end
		if rightShoulder and rightBase then
			rightShoulder.C0=rightBase*CFrame.Angles(math.rad(18),0,math.rad(18))
			task.wait(.18)
			local target=rightBase*CFrame.Angles(math.rad(-72),0,math.rad(6))
			local tw=TweenService:Create(rightShoulder,TweenInfo.new(.32,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{C0=target})
			tw:Play(); tw.Completed:Wait()
		end

		local blue=makeBlue(handPosition())
		for i=1,18 do
			blue.Position=handPosition()
			local size=1.2+4.2*(i/18)
			blue.Size=Vector3.new(size,size,size)
			task.wait(.025)
		end
		local start=blue.Position
		for i=1,28 do
			if not pr.Parent then break end
			blue.Position=start:Lerp(pr.Position+Vector3.new(0,2,0),i/28)
			task.wait(.022)
		end

		-- Lock only the selected player, low and stable.
		ph:SetAttribute("BlueSavedWalkSpeed",ph.WalkSpeed)
		ph:SetAttribute("BlueSavedJumpPower",ph.JumpPower)
		ph.WalkSpeed=0; ph.JumpPower=0; ph.AutoRotate=false; ph.PlatformStand=true
		local rootAtt=Instance.new("Attachment"); rootAtt.Name="BlueLockAttachment"; rootAtt.Parent=pr
		local target=Instance.new("Part")
		target.Name="BlueGravityTarget_"..tostring(player.UserId)
		target.Size=Vector3.new(.5,.5,.5); target.Transparency=1; target.Anchored=true
		target.CanCollide=false; target.CanTouch=false; target.CanQuery=false
		target.Position=Vector3.new(blue.Position.X,math.min(blue.Position.Y,pr.Position.Y+4),blue.Position.Z)
		target.Parent=workspace
		local targetAtt=Instance.new("Attachment"); targetAtt.Parent=target
		local align=Instance.new("AlignPosition"); align.Name="BlueGravityHold"
		align.Attachment0=rootAtt; align.Attachment1=targetAtt; align.MaxForce=100000
		align.MaxVelocity=18; align.Responsiveness=12; align.Parent=pr
		local orient=Instance.new("AlignOrientation"); orient.Name="BlueNoSpin"
		orient.Attachment0=rootAtt; orient.Mode=Enum.OrientationAlignmentMode.OneAttachment
		orient.CFrame=pr.CFrame.Rotation; orient.MaxTorque=100000; orient.Responsiveness=20; orient.Parent=pr
		pr.AssemblyLinearVelocity=Vector3.zero; pr.AssemblyAngularVelocity=Vector3.zero
		diag(player,"COMBO BLUE","alvo preso")
		task.wait(.75)

		-- Red forms while Blue is still holding the target.
		local red,aura=makeRed(handPosition())
		for i=1,14 do
			red.Position=handPosition()
			if aura and aura.Parent then
				aura.Position=red.Position
				local pulse=7+math.sin(i*.9)*1.4
				aura.Size=Vector3.new(pulse,pulse,pulse)
			end
			task.wait(.03)
		end
		local rs=red.Position
		for i=1,24 do
			if not pr.Parent then break end
			local t=i/24
			red.Position=rs:Lerp(pr.Position+Vector3.new(0,1,0),t)
			local grow=math.clamp((t-.48)/.52,0,1)
			local growSmooth=grow*grow*(3-2*grow)
			local coreSize=1.35+(14.65*growSmooth)
			red.Size=Vector3.new(coreSize,coreSize,coreSize)
			if aura and aura.Parent then
				aura.Position=red.Position
				local auraSize=7+(17*growSmooth)
				aura.Size=Vector3.new(auraSize,auraSize,auraSize)
				aura.Transparency=.78-(.13*growSmooth)
			end
			task.wait(.02)
		end

		-- Red explicitly breaks Blue before applying repulsion.
		clearBlueLock(player)
		if blue and blue.Parent then blue:Destroy() end
		local impact=red.Position
		TweenService:Create(red,TweenInfo.new(.18,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(24,24,24),Transparency=.32}):Play()
		if aura and aura.Parent then
			TweenService:Create(aura,TweenInfo.new(.22,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(58,58,58),Transparency=.9}):Play()
		end
		local away=pr.Position-impact
		local horizontal=Vector3.new(away.X,0,away.Z)
		if horizontal.Magnitude<.1 then horizontal=gojo:GetPivot().LookVector end
		pr.AssemblyLinearVelocity=horizontal.Unit*560+Vector3.new(0,55,0)
		diag(player,"COMBO RED","lock quebrado + repulsao")
		task.wait(.2)
		TweenService:Create(red,TweenInfo.new(.12),{Size=Vector3.new(50,50,50),Transparency=1}):Play()
		Debris:AddItem(red,.15)
		if aura then Debris:AddItem(aura,.15) end
	end)
	clearBlueLock(player)
	resetPose()
	if not okCombo then diag(player,"ERRO COMBO",err); warn("[Gojo Combo]",err) end
	task.wait(.35)
	attacking=false
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
			blue=makeBlue(handPosition())
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
			if not blue or not blue.Parent then
				error("Blue projectile ausente antes do arremesso")
			end
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
						local delta=blue.Position-pr.Position
						local horizontal=Vector3.new(delta.X,0,delta.Z)
						local dist=horizontal.Magnitude
						if dist>1.5 and dist<55 then
							local speed=math.clamp(90+(55-dist)*2.4,90,210)
							local currentY=pr.AssemblyLinearVelocity.Y
							pr.AssemblyLinearVelocity=Vector3.new(horizontal.Unit.X*speed,math.max(currentY,42),horizontal.Unit.Z*speed)
						elseif dist<=1.5 then
							pr.AssemblyLinearVelocity=Vector3.new(0,42,0)
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
				-- Red becomes visually overwhelming as it closes in on the target.
				-- Keep the core concentrated at launch, then swell to roughly 2-3x player height.
				local grow=math.clamp((t-.48)/.52,0,1)
				local growSmooth=grow*grow*(3-2*grow)
				local coreSize=1.35+(14.65*growSmooth)
				blue.Size=Vector3.new(coreSize,coreSize,coreSize)
				if redAura and redAura.Parent then
					redAura.Position=blue.Position
					local auraSize=7+(17*growSmooth)
					redAura.Size=Vector3.new(auraSize,auraSize,auraSize)
					redAura.Transparency=.78-(.13*growSmooth)
				end
				task.wait(.022)
			end
			if blue and blue.Parent then
				diag(player,"5 RED IMPACT","explosao expansiva + repulsao")
				local impactPos=blue.Position
				-- Destructive-looking expansion: small concentrated core becomes a huge blast.
				TweenService:Create(blue,TweenInfo.new(.18,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
					Size=Vector3.new(24,24,24),
					Transparency=.32
				}):Play()
				if redAura and redAura.Parent then
					TweenService:Create(redAura,TweenInfo.new(.22,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
						Size=Vector3.new(58,58,58),
						Transparency=.9
					}):Play()
				end
				-- Repel every living player in the blast radius once, hard.
				for _,p in ipairs(Players:GetPlayers()) do
					local ch=p.Character
					local pr=ch and ch:FindFirstChild("HumanoidRootPart")
					local ph=ch and ch:FindFirstChildOfClass("Humanoid")
					if pr and ph and ph.Health>0 then
						local away=pr.Position-impactPos
						local dist=away.Magnitude
						if dist<34 then
							local horizontal=Vector3.new(away.X,0,away.Z)
							if horizontal.Magnitude<.1 then horizontal=Vector3.new(0,0,-1) end
							local strength=math.clamp(560-dist*7,330,560)
							pr.AssemblyLinearVelocity=horizontal.Unit*strength+Vector3.new(0,70,0)
						end
					end
				end
				task.wait(.20)
				TweenService:Create(blue,TweenInfo.new(.12),{Size=Vector3.new(50,50,50),Transparency=1}):Play()
				Debris:AddItem(blue,.15)
				if redAura and redAura.Parent then Debris:AddItem(redAura,.15) end
			end
		end
		if mode=="blueThrow" and blue and blue.Parent then
			diag(player,"5 BLUE IMPACT","esfera expandindo + puxao forte")
			local impactPos=blue.Position
			-- Blue suspension: use constraints instead of repeatedly writing CFrame.
			-- This avoids camera jitter and keeps the player only a few studs off the ground.
			local locked={}
			local holdY=impactPos.Y
			for _,p in ipairs(Players:GetPlayers()) do
				local ch=p.Character
				local ph=ch and ch:FindFirstChildOfClass("Humanoid")
				local pr=ch and ch:FindFirstChild("HumanoidRootPart")
				if pr and ph and ph.Health>0 then
					local delta=impactPos-pr.Position
					local horizontal=Vector3.new(delta.X,0,delta.Z)
					if horizontal.Magnitude<52 then
						local state={
							walk=ph.WalkSpeed,
							jump=ph.JumpPower,
							autoRotate=ph.AutoRotate,
							platformStand=ph.PlatformStand,
							root=pr
						}
						locked[p]=state

						-- Never lift the player more than ~6 studs from their current ground level.
						holdY=math.min(holdY,pr.Position.Y+6)
						local target=Instance.new("Part")
						target.Name="BlueGravityTarget"
						target.Size=Vector3.new(.5,.5,.5)
						target.Transparency=1
						target.Anchored=true
						target.CanCollide=false
						target.CanTouch=false
						target.CanQuery=false
						target.Position=Vector3.new(impactPos.X,holdY,impactPos.Z)
						target.Parent=workspace
						state.target=target

						local rootAtt=Instance.new("Attachment")
						rootAtt.Name="BlueLockAttachment"
						rootAtt.Parent=pr

						local targetAtt=Instance.new("Attachment")
						targetAtt.Name="BlueTargetAttachment"
						targetAtt.Parent=target

						local align=Instance.new("AlignPosition")
						align.Name="BlueGravityHold"
						align.Attachment0=rootAtt
						align.Attachment1=targetAtt
						align.MaxForce=100000
						align.MaxVelocity=35
						align.Responsiveness=18
						align.RigidityEnabled=false
						align.Parent=pr

						local orient=Instance.new("AlignOrientation")
						orient.Name="BlueNoSpin"
						orient.Attachment0=rootAtt
						orient.Mode=Enum.OrientationAlignmentMode.OneAttachment
						orient.CFrame=pr.CFrame.Rotation
						orient.MaxTorque=100000
						orient.Responsiveness=25
						orient.RigidityEnabled=false
						orient.Parent=pr

						ph.WalkSpeed=0
						ph.JumpPower=0
						ph.AutoRotate=false
						ph.PlatformStand=true
						pr.AssemblyLinearVelocity=Vector3.zero
						pr.AssemblyAngularVelocity=Vector3.zero
					end
				end
			end

			task.wait(3)

			for p,state in pairs(locked) do
				local ch=p.Character
				local ph=ch and ch:FindFirstChildOfClass("Humanoid")
				local pr=state.root
				if state.target then state.target:Destroy() end
				if pr then
					local align=pr:FindFirstChild("BlueGravityHold")
					local orient=pr:FindFirstChild("BlueNoSpin")
					local att=pr:FindFirstChild("BlueLockAttachment")
					if align then align:Destroy() end
					if orient then orient:Destroy() end
					if att then att:Destroy() end
					pr.AssemblyLinearVelocity=Vector3.zero
					pr.AssemblyAngularVelocity=Vector3.zero
				end
				if ph and ph.Health>0 then
					ph.WalkSpeed=state.walk
					ph.JumpPower=state.jump
					ph.AutoRotate=state.autoRotate
					ph.PlatformStand=state.platformStand
				end
			end
			TweenService:Create(blue,TweenInfo.new(.13),{Transparency=1}):Play()
			Debris:AddItem(blue,.16)
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
	if mode=="combo" then
		diag(player,"REMOTE OK","modo=combo")
		task.spawn(comboPlayer,player)
		return
	end
	if mode~="blueThrow" and mode~="redThrow" then mode="blueThrow" end
	diag(player,"REMOTE OK","modo="..mode)
	task.spawn(attackPlayer,player,mode)
end)

print("[Gojo] R6 Blue rush ready")
