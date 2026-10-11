-- Nanobot Lift V1: push-to-talk STT + mobile test button + local cascade visuals.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("NanobotLift")

local gui = Instance.new("ScreenGui")
gui.Name = "NanobotControls"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function button(label, x)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(122, 46)
    b.Position = UDim2.new(1, x, 1, -112)
    b.AnchorPoint = Vector2.new(1, 0)
    b.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextScaled = true
    b.Font = Enum.Font.GothamBold
    b.Text = label
    b.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = b
    return b
end

local testButton = button("SUBIR", -18)
local talkButton = button("SEGURE P/ FALAR", -150)
local status = Instance.new("TextLabel")
status.Size = UDim2.fromOffset(265, 30)
status.Position = UDim2.new(1, -18, 1, -145)
status.AnchorPoint = Vector2.new(1, 0)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(190, 220, 255)
status.TextScaled = true
status.Font = Enum.Font.Gotham
status.Text = "Nanobots prontos"
status.Parent = gui

local function command()
    remote:FireServer("subir")
end
testButton.Activated:Connect(command)
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.E then command() end
end)

local stt, input, wire
local ok, err = pcall(function()
    input = Instance.new("AudioDeviceInput")
    input.Player = player
    input.Parent = player
    stt = Instance.new("AudioSpeechToText")
    stt.Enabled = false
    stt.Parent = player
    wire = Instance.new("Wire")
    wire.SourceInstance = input
    wire.TargetInstance = stt
    wire.Parent = stt
end)
if not ok then
    status.Text = "Voz indisponível; use SUBIR"
    warn("[Nanobots] Speech-to-text unavailable:", err)
end

local function normalize(s)
    s = string.lower(s)
    s = s:gsub("[áàâã]", "a"):gsub("[éê]", "e"):gsub("[í]", "i"):gsub("[óôõ]", "o"):gsub("[ú]", "u")
    return s
end
if stt then
    stt:GetPropertyChangedSignal("Text"):Connect(function()
        local text = stt.Text
        if text == "" then return end
        status.Text = "Ouvi: " .. string.sub(text, 1, 35)
        if normalize(text):find("%f[%a]subir%f[%A]") then command() end
        stt.Text = ""
    end)
end
local function listening(value)
    if not stt then return end
    stt.Enabled = value
    talkButton.Text = value and "OUVINDO..." or "SEGURE P/ FALAR"
    status.Text = value and "Diga: SUBIR" or "Nanobots prontos"
end
talkButton.MouseButton1Down:Connect(function() listening(true) end)
talkButton.MouseButton1Up:Connect(function() listening(false) end)
talkButton.MouseLeave:Connect(function() listening(false) end)

-- All visual bots are local, non-colliding and pooled per active animation.
local swarms = {}
local BOT_COUNT = 220
local function stop(owner)
    local state = swarms[owner]
    if not state then return end
    swarms[owner] = nil
    if state.connection then state.connection:Disconnect() end
    for _, part in ipairs(state.parts) do part:Destroy() end
end
local function start(owner, origin, height, duration)
    stop(owner)
    local parts = {}
    local rng = Random.new(owner.UserId + math.floor(os.clock() * 100))
    local spread = {}
    for i = 1, BOT_COUNT do
        local bot = Instance.new("Part")
        bot.Name = "Nanobot"
        bot.Size = Vector3.new(0.27, 0.18, 0.38)
        bot.Material = Enum.Material.Metal
        bot.Color = Color3.fromRGB(7 + rng:NextInteger(0, 13), 9, 15)
        bot.Anchored = true
        bot.CanCollide = false
        bot.CanTouch = false
        bot.CanQuery = false
        bot.CastShadow = false
        bot.Parent = workspace
        parts[i] = bot
        local angle = rng:NextNumber(0, math.pi * 2)
        local radius = math.sqrt(rng:NextNumber()) * 14
        spread[i] = {angle = angle, radius = radius, phase = rng:NextNumber(0, math.pi * 2), delay = rng:NextNumber(0, 0.32)}
    end
    local state = {parts = parts}
    swarms[owner] = state
    local begun = os.clock()
    state.connection = RunService.RenderStepped:Connect(function()
        local t = math.clamp((os.clock() - begun) / duration, 0, 1)
        local eased = t * t * (3 - 2 * t)
        local top = height * eased
        for i, bot in ipairs(parts) do
            local d = spread[i]
            local converge = math.clamp((t - d.delay) * 3.1, 0, 1)
            local radius = d.radius * (1 - converge) + (0.35 + (i % 19) / 19 * 2.6) * converge
            local angle = d.angle + t * (1.5 + i % 3)
            local y = (i % 31) / 31 * top
            local ripple = math.sin(t * 25 + d.phase) * 0.35
            local p = origin + Vector3.new(math.cos(angle) * radius, -3 + y + ripple, math.sin(angle) * radius)
            bot.CFrame = CFrame.new(p) * CFrame.Angles(t * 4 + d.phase, angle, t * 3)
        end
    end)
    task.delay(duration + 3, function() if swarms[owner] == state then stop(owner) end end)
end
remote.OnClientEvent:Connect(function(action, owner, origin, height, duration)
    if action == "start" then start(owner, origin, height, duration) end
    if action == "finish" then
        task.delay(2, function() stop(owner) end)
    end
end)
