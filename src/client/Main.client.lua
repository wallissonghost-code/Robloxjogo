local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local claimCell = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ClaimCell")

local function disableCore()
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false) end)
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false) end)
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false) end)
end
disableCore()

local controls = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
controls:Disable()

local function disableTouchGui(gui)
    if gui.Name == "TouchGui" and gui:IsA("ScreenGui") then gui.Enabled = false end
end
for _, gui in ipairs(player.PlayerGui:GetChildren()) do disableTouchGui(gui) end
player.PlayerGui.ChildAdded:Connect(disableTouchGui)

local camera = workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Scriptable
camera.FieldOfView = 50

local mapWidth = Config.Map.Width * Config.Map.CellSize
local mapHeight = Config.Map.Height * Config.Map.CellSize
local halfX = mapWidth / 2
local halfZ = mapHeight / 2
local focus = Vector3.new(Config.Map.Origin.X, 0, Config.Map.Origin.Z)
local height = Config.Camera.StartHeight

local touches = {}
local mouseDragging = false
local mouseStart = nil
local lastMousePosition = nil
local pinchActive = false
local lastPinchDistance = nil

local function clampFocus()
    local padding = Config.Camera.EdgePadding
    focus = Vector3.new(
        math.clamp(focus.X, Config.Map.Origin.X-halfX+padding, Config.Map.Origin.X+halfX-padding),
        0,
        math.clamp(focus.Z, Config.Map.Origin.Z-halfZ+padding, Config.Map.Origin.Z+halfZ-padding)
    )
end

local function setZoom(value)
    height = math.clamp(value, Config.Camera.MinHeight, Config.Camera.MaxHeight)
end

local function pan(delta)
    local scale = height * Config.Camera.PanSpeed
    focus += Vector3.new(-delta.X * scale, 0, -delta.Y * scale)
    clampFocus()
end

local function claimAt(screenPosition)
    local ray = camera:ViewportPointToRay(screenPosition.X, screenPosition.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    local map = workspace:FindFirstChild("PixelWarMap")
    local cells = map and map:FindFirstChild("Cells")
    if not cells then return end
    params.FilterDescendantsInstances = {cells}
    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
    if result and result.Instance then
        claimCell:FireServer(result.Instance)
    end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.Touch then
        touches[input] = {position=input.Position, start=input.Position, moved=false}
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        mouseDragging = true
        mouseStart = input.Position
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
        local data = touches[input]
        local previous = data.position
        data.position = input.Position
        if (data.position-data.start).Magnitude > 10 then data.moved = true end

        local active = {}
        for touch, info in pairs(touches) do
            if touch.UserInputState ~= Enum.UserInputState.End then
                table.insert(active, info)
            end
        end

        if #active == 1 and not pinchActive then
            pan(input.Position - previous)
        elseif #active >= 2 then
            pinchActive = true
            active[1].moved = true
            active[2].moved = true
            local distance = (active[1].position-active[2].position).Magnitude
            if lastPinchDistance and lastPinchDistance > 0 then
                setZoom(height * (lastPinchDistance/math.max(distance,1)))
            end
            lastPinchDistance = distance
        end
    elseif input.UserInputType == Enum.UserInputType.MouseMovement and mouseDragging and lastMousePosition then
        pan(input.Position-lastMousePosition)
        lastMousePosition = input.Position
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        local data = touches[input]
        touches[input] = nil
        local remaining = 0
        for _ in pairs(touches) do remaining += 1 end
        if data and not data.moved and not pinchActive then
            claimAt(input.Position)
        end
        if remaining == 0 then
            pinchActive = false
            lastPinchDistance = nil
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        if mouseStart and (input.Position-mouseStart).Magnitude < 8 then
            claimAt(input.Position)
        end
        mouseDragging = false
        mouseStart = nil
        lastMousePosition = nil
    end
end)

RunService:BindToRenderStep("PixelWarMapCamera", Enum.RenderPriority.Camera.Value+1, function()
    camera.CFrame = CFrame.lookAt(
        Vector3.new(focus.X, height, focus.Z),
        Vector3.new(focus.X, 0, focus.Z),
        Vector3.new(0,0,-1)
    )
end)
