local Flight = {}

function Flight.bind(player, controls, services)
	local flying = false
	local speed = 70
	local attachment, velocity, orientation
	local vertical = 0

	local function stop()
		flying = false
		controls.fly.Text = "VOO  •  OFF"
		controls.fly.BackgroundColor3 = Color3.fromRGB(36,40,45)
		if velocity then velocity:Destroy(); velocity=nil end
		if orientation then orientation:Destroy(); orientation=nil end
		if attachment then attachment:Destroy(); attachment=nil end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.AutoRotate = true end
	end

	local function start()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid then return end
		flying = true
		controls.fly.Text = "VOO  •  ON"
		controls.fly.BackgroundColor3 = Color3.fromRGB(46,86,62)
		humanoid.AutoRotate = false
		attachment = Instance.new("Attachment"); attachment.Name="AdminFlight"; attachment.Parent=root
		velocity = Instance.new("LinearVelocity"); velocity.Name="AdminFlightVelocity"; velocity.Attachment0=attachment; velocity.MaxForce=math.huge; velocity.VectorVelocity=Vector3.zero; velocity.Parent=root
		orientation = Instance.new("AlignOrientation"); orientation.Name="AdminFlightOrientation"; orientation.Attachment0=attachment; orientation.Mode=Enum.OrientationAlignmentMode.OneAttachment; orientation.MaxTorque=math.huge; orientation.Responsiveness=18; orientation.Parent=root
	end

	controls.fly.MouseButton1Click:Connect(function() if flying then stop() else start() end end)
	local function updateSpeed(delta)
		speed = math.clamp(speed + delta, 30, 180)
		controls.speedLabel.Text = "VELOCIDADE  " .. speed
	end
	controls.minus.MouseButton1Click:Connect(function() updateSpeed(-10) end)
	controls.plus.MouseButton1Click:Connect(function() updateSpeed(10) end)

	services.UserInputService.JumpRequest:Connect(function()
		if flying then vertical=1; task.delay(.22,function() if vertical==1 then vertical=0 end end) end
	end)

	services.RunService.RenderStepped:Connect(function()
		if not flying or not velocity or not orientation then return end
		local character=player.Character
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		local root=character and character:FindFirstChild("HumanoidRootPart")
		local camera=services.Workspace.CurrentCamera
		if not humanoid or not root or not camera then stop(); return end
		local direction=humanoid.MoveDirection + Vector3.new(0,vertical,0)
		if direction.Magnitude>1 then direction=direction.Unit end
		velocity.VectorVelocity=direction*speed
		local look=camera.CFrame.LookVector
		local flat=Vector3.new(look.X,0,look.Z)
		if flat.Magnitude>.05 then orientation.CFrame=CFrame.lookAt(Vector3.zero,flat.Unit) end
	end)

	player.CharacterAdded:Connect(function() if flying then stop() end end)
end

return Flight
