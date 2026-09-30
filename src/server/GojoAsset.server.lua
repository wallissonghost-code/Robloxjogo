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

-- Complete runtime rig diagnostic. Read-only: it does not change the Gojo.
local function buildRigDiagnostic(instance)
	local lines={}
	local function add(k,v) table.insert(lines,k..": "..tostring(v)) end
	local humanoid=instance:FindFirstChildOfClass("Humanoid") or instance:FindFirstChildWhichIsA("Humanoid",true)
	local controller=instance:FindFirstChildOfClass("AnimationController") or instance:FindFirstChildWhichIsA("AnimationController",true)
	local animator=instance:FindFirstChildWhichIsA("Animator",true)
	local rootPart=instance:FindFirstChild("HumanoidRootPart",true)
	local motors,welds,parts,attachments,scripts,animations=0,0,0,0,0,0
	local motorNames={}
	local bodyNames={}
	for _,v in ipairs(instance:GetDescendants()) do
		if v:IsA("Motor6D") then
			motors+=1
			if #motorNames<30 then table.insert(motorNames,v.Name.." ["..(v.Part0 and v.Part0.Name or "nil").." -> "..(v.Part1 and v.Part1.Name or "nil").."]") end
		elseif v:IsA("Weld") or v:IsA("WeldConstraint") then welds+=1
		elseif v:IsA("BasePart") then
			parts+=1
			if #bodyNames<40 then table.insert(bodyNames,v.Name) end
		elseif v:IsA("Attachment") then attachments+=1
		elseif v:IsA("Script") or v:IsA("LocalScript") or v:IsA("ModuleScript") then scripts+=1
		elseif v:IsA("Animation") then animations+=1 end
	end
	add("Asset",ASSET_ID)
	add("Root class",instance.ClassName)
	add("Humanoid",humanoid and humanoid:GetFullName() or "NAO")
	add("RigType",humanoid and humanoid.RigType.Name or "N/A")
	add("Health",humanoid and (humanoid.Health.."/"..humanoid.MaxHealth) or "N/A")
	add("AnimationController",controller and controller:GetFullName() or "NAO")
	add("Animator",animator and animator:GetFullName() or "NAO")
	add("HumanoidRootPart",rootPart and rootPart:GetFullName() or "NAO")
	add("Motor6D",motors)
	add("Weld/WeldConstraint",welds)
	add("BaseParts",parts)
	add("Attachments",attachments)
	add("Animations embedded",animations)
	add("Scripts embedded",scripts)
	add("PrimaryPart",instance:IsA("Model") and (instance.PrimaryPart and instance.PrimaryPart.Name or "NAO") or "N/A")
	add("Motor map",#motorNames>0 and table.concat(motorNames," | ") or "NENHUM")
	add("Part names",#bodyNames>0 and table.concat(bodyNames,", ") or "NENHUMA")
	return table.concat(lines,"\n")
end

local rigDiagnostic=buildRigDiagnostic(gojo)
print("[GOJO RIG DIAGNOSTIC]\n"..rigDiagnostic)

local function showRigDiagnostic(player)
	local pg=player:WaitForChild("PlayerGui",10)
	if not pg then return end
	local oldGui=pg:FindFirstChild("GojoRigDiagnostic")
	if oldGui then oldGui:Destroy() end
	local gui=Instance.new("ScreenGui")
	gui.Name="GojoRigDiagnostic"
	gui.ResetOnSpawn=false
	gui.DisplayOrder=999999
	gui.Parent=pg
	local frame=Instance.new("Frame")
	frame.Size=UDim2.new(.94,0,.72,0)
	frame.Position=UDim2.new(.03,0,.03,0)
	frame.BackgroundColor3=Color3.fromRGB(12,14,18)
	frame.BackgroundTransparency=.04
	frame.Parent=gui
	local corner=Instance.new("UICorner")
	corner.CornerRadius=UDim.new(0,12)
	corner.Parent=frame
	local title=Instance.new("TextLabel")
	title.Size=UDim2.new(1,-24,0,42)
	title.Position=UDim2.new(0,12,0,8)
	title.BackgroundTransparency=1
	title.Text="GOJO — DIAGNOSTICO COMPLETO DO RIG"
	title.TextColor3=Color3.new(1,1,1)
	title.Font=Enum.Font.GothamBold
	title.TextSize=18
	title.TextXAlignment=Enum.TextXAlignment.Left
	title.Parent=frame
	local scroll=Instance.new("ScrollingFrame")
	scroll.Size=UDim2.new(1,-24,1,-62)
	scroll.Position=UDim2.new(0,12,0,52)
	scroll.BackgroundTransparency=1
	scroll.BorderSizePixel=0
	scroll.ScrollBarThickness=7
	scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
	scroll.CanvasSize=UDim2.new()
	scroll.Parent=frame
	local label=Instance.new("TextLabel")
	label.Size=UDim2.new(1,-12,0,0)
	label.AutomaticSize=Enum.AutomaticSize.Y
	label.BackgroundTransparency=1
	label.Text=rigDiagnostic
	label.TextWrapped=true
	label.TextColor3=Color3.fromRGB(225,232,242)
	label.Font=Enum.Font.Code
	label.TextSize=14
	label.TextXAlignment=Enum.TextXAlignment.Left
	label.TextYAlignment=Enum.TextYAlignment.Top
	label.Parent=scroll
end

Players.PlayerAdded:Connect(function(player)
	task.delay(2,function() showRigDiagnostic(player) end)
end)
for _,player in ipairs(Players:GetPlayers()) do task.spawn(showRigDiagnostic,player) end

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

local function fireSphere(player, shouldPush)
	local character=player and player.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local origin=gojoOrigin()
	local target=root.Position
	local direction=target-origin
	if direction.Magnitude<.01 then return end

	-- 2x the LiveParkour impact sphere presentation.
	local radius=5
	local ball=Instance.new("Part")
	ball.Name="GojoImpactSphere"
	ball.Shape=Enum.PartType.Ball
	ball.Size=Vector3.new(radius*2,radius*2,radius*2)
	ball.Material=Enum.Material.Neon
	ball.Color=Color3.fromRGB(75,145,255)
	ball.Transparency=.12
	ball.Anchored=true
	ball.CanCollide=false
	ball.CanTouch=false
	ball.CanQuery=false
	ball.Position=origin
	ball.Parent=workspace

	local light=Instance.new("PointLight")
	light.Color=ball.Color
	light.Brightness=6
	light.Range=30
	light.Parent=ball

	local attachment=Instance.new("Attachment")
	attachment.Parent=ball
	local particles=Instance.new("ParticleEmitter")
	particles.Color=ColorSequence.new(ball.Color:Lerp(Color3.new(1,1,1),.55),ball.Color)
	particles.LightEmission=1
	particles.Rate=120
	particles.Lifetime=NumberRange.new(.25,.5)
	particles.Speed=NumberRange.new(1,4)
	particles.SpreadAngle=Vector2.new(180,180)
	particles.Size=NumberSequence.new({
		NumberSequenceKeypoint.new(0,.9),
		NumberSequenceKeypoint.new(1,0),
	})
	particles.Parent=attachment

	local distance=direction.Magnitude
	local travelTime=math.clamp(distance/42,.25,1.4)
	local tween=TweenService:Create(ball,TweenInfo.new(travelTime,Enum.EasingStyle.Quart,Enum.EasingDirection.In),{Position=target})
	tween:Play()
	tween.Completed:Connect(function()
		-- Optional test push: only the button-triggered sphere applies a small impulse.
		if shouldPush and root.Parent then
			local flat=Vector3.new(direction.X,0,direction.Z)
			if flat.Magnitude>.01 then
				root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + flat.Unit*32 + Vector3.new(0,8,0)
			end
		end
		if ball.Parent then
			TweenService:Create(ball,TweenInfo.new(.18),{Transparency=1,Size=ball.Size*1.15}):Play()
			Debris:AddItem(ball,.22)
		end
	end)
	Debris:AddItem(ball,3)
end

pushRemote.OnServerEvent:Connect(function(player)
	fireSphere(player,true)
end)

print("[Gojo] loaded, scale x2.5; spheres fire only from test button")
