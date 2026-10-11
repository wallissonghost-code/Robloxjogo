-- Nanobot Lift V1: server-authoritative lift, visual swarm rendered locally.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local remote = Instance.new("RemoteEvent")
remote.Name = "NanobotLift"
remote.Parent = ReplicatedStorage

local HEIGHT = 42
local DURATION = 3.2
local COOLDOWN = 7
local lastUse = {}
local active = {}

local function lift(player)
    local now = os.clock()
    if active[player] or (lastUse[player] and now - lastUse[player] < COOLDOWN) then return end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not root or not root:IsDescendantOf(workspace) then return end
    if humanoid.Sit then return end
    lastUse[player] = now
    active[player] = true

    local origin = root.Position
    local platform = Instance.new("Part")
    platform.Name = "NanobotLiftSupport"
    platform.Size = Vector3.new(6, 0.6, 6)
    platform.Anchored = true
    platform.CanCollide = true
    platform.Transparency = 1
    platform.Position = Vector3.new(origin.X, origin.Y - 3.2, origin.Z)
    platform.Parent = workspace

    remote:FireAllClients("start", player, origin, HEIGHT, DURATION)
    local started = os.clock()
    local previous = 0
    while active[player] and player.Parent and character.Parent and humanoid.Health > 0 do
        local elapsed = os.clock() - started
        local t = math.clamp(elapsed / DURATION, 0, 1)
        local eased = t * t * (3 - 2 * t)
        local height = HEIGHT * eased
        local delta = height - previous
        previous = height
        platform.Position += Vector3.new(0, delta, 0)
        -- Move character with the rising surface, without imparting a huge impulse.
        if root.Parent then
            character:PivotTo(character:GetPivot() + Vector3.new(0, delta, 0))
        end
        if t >= 1 then break end
        RunService.Heartbeat:Wait()
    end
    active[player] = nil
    -- Keep the invisible physical surface briefly so the player can step off.
    task.delay(2.5, function()
        if platform.Parent then platform:Destroy() end
    end)
    remote:FireAllClients("finish", player)
end

remote.OnServerEvent:Connect(function(player, command)
    if command ~= "subir" then return end
    task.spawn(lift, player)
end)

Players.PlayerRemoving:Connect(function(player)
    active[player] = nil
    lastUse[player] = nil
end)
