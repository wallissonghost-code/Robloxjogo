local InsertService=game:GetService("InsertService")
local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local pushRemote=ReplicatedStorage:FindFirstChild("GojoPushTest") or Instance.new("RemoteEvent")
pushRemote.Name="GojoPushTest"
pushRemote.Parent=ReplicatedStorage

local ASSET_ID=14034779103
local NAME="ImportedGojo_"..ASSET_ID
local POS=Vector3.new(0,0,3)

local old=workspace:FindFirstChild(NAME)
if old then old:Destroy() end

local ok,container=pcall(function()
	return InsertService:LoadAsset(ASSET_ID)
end)
if not ok then
	warn("[Gojo] LoadAsset failed:",container)
	return
end

local children=container:GetChildren()
if #children==0 then
	warn("[Gojo] Asset returned 0 objects")
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
	if attacking then return end
	local character=player and player.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	local hum=character and character:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health<=0 or not gojo:IsA("Model") then return end
	attacking=true

	-- Face the target and raise the right arm while the Blue charges.
	local pivot=gojo:GetPivot()
	local flatTarget=Vector3.new(root.Position.X,pivot.Position.Y,root.Position.Z)
	if (flatTarget-pivot.Position).Magnitude>.1 then
		gojo:PivotTo(CFrame.lookAt(pivot.Position,flatTarget))
	end
	if rightShoulder and rightBase then
		tweenMotor(rightShoulder,rightBase*CFrame.Angles(math.rad(-80),0,math.rad(12)),.28)
	end
	if leftShoulder and leftBase then
		tweenMotor(leftShoulder,leftBase*CFrame.Angles(math.rad(-20),0,math.rad(-8)),.28)
	end

	local blue=makeBlue(handPosition())
	local chargeStart=os.clock()
	while blue.Parent and os.clock()-chargeStart<.75 do
		blue.Position=handPosition()
		local a=math.clamp((os.clock()-chargeStart)/.75,0,1)
		blue.Size=Vector3.new(1,1,1):Lerp(Vector3.new(7,7,7),a)
		task.wait()
	end

	-- Rush toward the player's current position while keeping the Blue at the hand.
	local rushStart=os.clock()
	while gojo.Parent and root.Parent and os.clock()-rushStart<1.6 do
		local gp=gojo:GetPivot()
		local delta=Vector3.new(root.Position.X-gp.Position.X,0,root.Position.Z-gp.Position.Z)
		local distance=delta.Magnitude
		if distance<=8 then break end
		local step=math.min(distance-7,28*task.wait())
		if step>0 and delta.Magnitude>0 then
			local newPos=gp.Position+delta.Unit*step
			gojo:PivotTo(CFrame.lookAt(newPos,Vector3.new(root.Position.X,newPos.Y,root.Position.Z)))
		end
		if blue.Parent then blue.Position=handPosition() end
	end

	-- Contact blast: push away from Gojo.
	if root.Parent then
		local gp=gojo:GetPivot().Position
		local away=Vector3.new(root.Position.X-gp.X,0,root.Position.Z-gp.Z)
		if away.Magnitude>.01 then
			root.AssemblyLinearVelocity=root.AssemblyLinearVelocity+away.Unit*48+Vector3.new(0,10,0)
		end
	end
	if blue.Parent then
		TweenService:Create(blue,TweenInfo.new(.16),{Size=Vector3.new(11,11,11),Transparency=1}):Play()
		Debris:AddItem(blue,.2)
	end

	if rightShoulder and rightBase then tweenMotor(rightShoulder,rightBase,.3) end
	if leftShoulder and leftBase then tweenMotor(leftShoulder,leftBase,.3) end
	task.wait(.35)
	attacking=false
end

pushRemote.OnServerEvent:Connect(function(player)
	fireSphere(player,true)
end)

print("[Gojo] loaded, scale x2.5; spheres fire only from test button")
