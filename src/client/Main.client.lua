local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

local function disableCore()
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false) end)
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health,false) end)
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false) end)
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu,false) end)
end
disableCore()

local playerScripts = player:WaitForChild("PlayerScripts")
local playerModule = require(playerScripts:WaitForChild("PlayerModule"))
local controls = playerModule:GetControls()
controls:Disable()

-- Explicitly disable mobile touch controls (joystick/jump).
local touchGui = player:WaitForChild("PlayerGui"):FindFirstChild("TouchGui")
if touchGui then touchGui.Enabled = false end
player.PlayerGui.ChildAdded:Connect(function(child)
    if child.Name == "TouchGui" and child:IsA("ScreenGui") then child.Enabled = false end
end)

-- Strategic map camera: independent from the Roblox character.
-- Flat top-down view, drag to pan and pinch/mouse-wheel to zoom.
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local camera = workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Scriptable
camera.FieldOfView = 50

local MAP_CENTER = Vector3.new(0, 0, 0)
local MAP_HALF_X = 110
local MAP_HALF_Z = 70
local MIN_HEIGHT = 55
local MAX_HEIGHT = 360
local PAN_SPEED = 0.0024

local focus = Vector3.new(MAP_CENTER.X, 0, MAP_CENTER.Z)
local height = 150
local touches = {}
local mouseDragging = false
local lastMousePosition = nil
local lastPinchDistance = nil

local function clampFocus()
    focus = Vector3.new(
        math.clamp(focus.X, MAP_CENTER.X - MAP_HALF_X, MAP_CENTER.X + MAP_HALF_X),
        0,
        math.clamp(focus.Z, MAP_CENTER.Z - MAP_HALF_Z, MAP_CENTER.Z + MAP_HALF_Z)
    )
end

local function panByPixels(delta)
    local scale = height * PAN_SPEED
    -- Dragging the map follows the finger; camera focus moves opposite to the drag.
    focus += Vector3.new(-delta.X * scale, 0, -delta.Y * scale)
    clampFocus()
end

local function setZoom(newHeight)
    height = math.clamp(newHeight, MIN_HEIGHT, MAX_HEIGHT)
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.Touch then
        touches[input] = input.Position
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        mouseDragging = true
        lastMousePosition = input.Position
    end
end)

UserInputService.InputChanged:Connect(function(input, processed)
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        setZoom(height * (input.Position.Z > 0 and 0.88 or 1.12))
        return
    end
    if processed then return end

    if input.UserInputType == Enum.UserInputType.Touch and touches[input] then
        local previous = touches[input]
        touches[input] = input.Position

        local active = {}
        for touch, position in pairs(touches) do
            if touch.UserInputState ~= Enum.UserInputState.End then
                table.insert(active, {touch = touch, position = position})
            end
        end

        if #active == 1 then
            lastPinchDistance = nil
            panByPixels(input.Position - previous)
        elseif #active >= 2 then
            local p1, p2 = active[1].position, active[2].position
            local distance = (p1 - p2).Magnitude
            if lastPinchDistance and lastPinchDistance > 0 then
                -- Fingers spreading apart zoom in; pinching together zooms out.
                setZoom(height * (lastPinchDistance / math.max(distance, 1)))
            end
            lastPinchDistance = distance
        end
    elseif input.UserInputType == Enum.UserInputType.MouseMovement and mouseDragging and lastMousePosition then
        local current = input.Position
        panByPixels(current - lastMousePosition)
        lastMousePosition = current
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        touches[input] = nil
        lastPinchDistance = nil
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        mouseDragging = false
        lastMousePosition = nil
    end
end)

RunService:BindToRenderStep("PixelWarMapCamera", Enum.RenderPriority.Camera.Value + 1, function()
    -- Looking straight down removes the unwanted perspective tilt.
    camera.CFrame = CFrame.lookAt(
        Vector3.new(focus.X, height, focus.Z),
        Vector3.new(focus.X, 0, focus.Z),
        Vector3.new(0, 0, -1)
    )
end)

local old = player.PlayerGui:FindFirstChild("PixelWarHUD")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "PixelWarHUD"
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui

local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(.5,0)
card.Position = UDim2.fromScale(.5,.055)
card.Size = UDim2.fromOffset(300,58)
card.BackgroundTransparency = 1
card.Parent = gui

local avatar = Instance.new("ImageLabel")
avatar.Size = UDim2.fromOffset(48,48)
avatar.Position = UDim2.fromOffset(0,5)
avatar.BackgroundTransparency = 1
avatar.Parent = card
local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1,0); corner.Parent = avatar
task.spawn(function()
    local image = Players:GetUserThumbnailAsync(player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)
    avatar.Image = image
end)

local name = Instance.new("TextLabel")
name.Position = UDim2.fromOffset(56,0); name.Size = UDim2.fromOffset(244,34)
name.BackgroundTransparency = 1; name.Font = Enum.Font.GothamBold; name.TextSize = 25
name.TextXAlignment = Enum.TextXAlignment.Left; name.TextColor3 = Color3.new(1,1,1)
name.TextStrokeTransparency = .15; name.Text = player.DisplayName; name.Parent = card

local troops = Instance.new("TextLabel")
troops.Position = UDim2.fromOffset(56,31); troops.Size = UDim2.fromOffset(244,23)
troops.BackgroundTransparency = 1; troops.Font = Enum.Font.GothamBold; troops.TextSize = 18
troops.TextXAlignment = Enum.TextXAlignment.Left; troops.TextColor3 = Color3.new(1,1,1)
troops.TextStrokeTransparency = .2; troops.Parent = card

local function fmt(v)
    v = tonumber(v) or 0
    if v >= 1e6 then return string.format("%.2fM",v/1e6) end
    if v >= 1e3 then return string.format("%.2fK",v/1e3) end
    return tostring(math.floor(v))
end
local function refresh() troops.Text = fmt(player:GetAttribute("Troops")) end
player:GetAttributeChangedSignal("Troops"):Connect(refresh)
refresh()
