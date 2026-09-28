local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
if player:GetAttribute("IsGameAdmin") == nil then
	player:GetAttributeChangedSignal("IsGameAdmin"):Wait()
end
if player:GetAttribute("IsGameAdmin") ~= true then
	return
end

local gui = Instance.new("ScreenGui")
gui.Name = "PrivateAdmin"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local open = Instance.new("TextButton")
open.Name = "AdminButton"
open.AnchorPoint = Vector2.new(1, 0)
open.Position = UDim2.new(1, -18, 0, 74)
open.Size = UDim2.fromOffset(86, 38)
open.BackgroundColor3 = Color3.fromRGB(20, 23, 27)
open.Text = "ADMIN"
open.TextColor3 = Color3.fromRGB(240, 243, 246)
open.Font = Enum.Font.GothamBold
open.TextSize = 13
open.AutoButtonColor = false
open.Parent = gui
local oc = Instance.new("UICorner"); oc.CornerRadius = UDim.new(0, 11); oc.Parent = open
local os = Instance.new("UIStroke"); os.Color = Color3.fromRGB(255,255,255); os.Transparency = .78; os.Parent = open

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -18, 0, 120)
panel.Size = UDim2.fromOffset(230, 164)
panel.BackgroundColor3 = Color3.fromRGB(16, 18, 21)
panel.BackgroundTransparency = .04
panel.Visible = false
panel.Parent = gui
local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 16); pc.Parent = panel
local ps = Instance.new("UIStroke"); ps.Color = Color3.fromRGB(255,255,255); ps.Transparency = .82; ps.Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(16, 12)
title.Size = UDim2.new(1, -32, 0, 24)
title.BackgroundTransparency = 1
title.Text = "CONTROLE ADMIN"
title.TextColor3 = Color3.fromRGB(238, 241, 244)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = panel

local fly = Instance.new("TextButton")
fly.Position = UDim2.fromOffset(16, 48)
fly.Size = UDim2.new(1, -32, 0, 42)
fly.BackgroundColor3 = Color3.fromRGB(36, 40, 45)
fly.Text = "VOO  •  OFF"
fly.TextColor3 = Color3.fromRGB(238, 241, 244)
fly.Font = Enum.Font.GothamBold
fly.TextSize = 13
fly.AutoButtonColor = false
fly.Parent = panel
local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(0, 11); fc.Parent = fly

local speedLabel = Instance.new("TextLabel")
speedLabel.Position = UDim2.fromOffset(16, 102)
speedLabel.Size = UDim2.new(1, -32, 0, 20)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "VELOCIDADE  70"
speedLabel.TextColor3 = Color3.fromRGB(190, 196, 202)
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Font = Enum.Font.GothamMedium
speedLabel.TextSize = 12
speedLabel.Parent = panel

local minus = Instance.new("TextButton")
minus.Position = UDim2.fromOffset(150, 98); minus.Size = UDim2.fromOffset(28, 28)
minus.Text = "−"; minus.TextSize = 20; minus.Font = Enum.Font.GothamBold
minus.TextColor3 = Color3.new(1,1,1); minus.BackgroundColor3 = Color3.fromRGB(36,40,45); minus.Parent = panel
local mc=Instance.new("UICorner");mc.CornerRadius=UDim.new(0,8);mc.Parent=minus
local plus = minus:Clone(); plus.Text = "+"; plus.Position = UDim2.fromOffset(184,98); plus.Parent = panel

local flying = false
local speed = 70
local attachment, velocity, orientation
local vertical = 0

local function stopFly()
	flying = false
	fly.Text = "VOO  •  OFF"
	fly.BackgroundColor3 = Color3.fromRGB(36,40,45)
	if velocity then velocity:Destroy(); velocity=nil end
	if orientation then orientation:Destroy(); orientation=nil end
	if attachment then attachment:Destroy(); attachment=nil end
	local character=player.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.AutoRotate=true end
end

local function startFly()
	local character=player.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then return end
	flying=true
	fly.Text="VOO  •  ON"
	fly.BackgroundColor3=Color3.fromRGB(46,86,62)
	humanoid.AutoRotate=false
	attachment=Instance.new("Attachment");attachment.Name="AdminFlight";attachment.Parent=root
	velocity=Instance.new("LinearVelocity");velocity.Name="AdminFlightVelocity";velocity.Attachment0=attachment;velocity.MaxForce=math.huge;velocity.VectorVelocity=Vector3.zero;velocity.Parent=root
	orientation=Instance.new("AlignOrientation");orientation.Name="AdminFlightOrientation";orientation.Attachment0=attachment;orientation.Mode=Enum.OrientationAlignmentMode.OneAttachment;orientation.MaxTorque=math.huge;orientation.Responsiveness=18;orientation.Parent=root
end

open.MouseButton1Click:Connect(function() panel.Visible=not panel.Visible end)
fly.MouseButton1Click:Connect(function() if flying then stopFly() else startFly() end end)
local function updateSpeed(delta)
	speed=math.clamp(speed+delta,30,180)
	speedLabel.Text="VELOCIDADE  "..speed
end
minus.MouseButton1Click:Connect(function() updateSpeed(-10) end)
plus.MouseButton1Click:Connect(function() updateSpeed(10) end)

UserInputService.JumpRequest:Connect(function()
	if flying then vertical=1; task.delay(.22,function() if vertical==1 then vertical=0 end end) end
end)

RunService.RenderStepped:Connect(function()
	if not flying or not velocity or not orientation then return end
	local character=player.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	local root=character and character:FindFirstChild("HumanoidRootPart")
	local camera=Workspace.CurrentCamera
	if not humanoid or not root or not camera then stopFly(); return end
	local move=humanoid.MoveDirection
	local horizontal=move
	local direction=horizontal + Vector3.new(0,vertical,0)
	if direction.Magnitude>1 then direction=direction.Unit end
	velocity.VectorVelocity=direction*speed
	local look=camera.CFrame.LookVector
	local flat=Vector3.new(look.X,0,look.Z)
	if flat.Magnitude>.05 then orientation.CFrame=CFrame.lookAt(Vector3.zero,flat.Unit) end
end)

player.CharacterAdded:Connect(function() if flying then stopFly() end end)
