-- Client-side main menu for public lobby servers. The game HUD is only created in match servers.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local LobbyClient = {}
local GOLD = Color3.fromRGB(246, 182, 75)
local WHITE = Color3.fromRGB(240, 241, 247)
local MUTED = Color3.fromRGB(173, 186, 208)
local NAVY = Color3.fromRGB(20, 29, 45)
local CARD = Color3.fromRGB(29, 41, 61)

local function make(kind, parent, props)
    local instance = Instance.new(kind)
    for key, value in pairs(props or {}) do instance[key] = value end
    instance.Parent = parent
    return instance
end

local function rounded(parent, radius, strokeColor)
    make("UICorner", parent, {CornerRadius = UDim.new(0, radius or 10)})
    if strokeColor then
        make("UIStroke", parent, {Color = strokeColor, Thickness = 1.3, Transparency = 0.28})
    end
    return parent
end

local function label(parent, text, x, y, w, h, size, color, bold)
    return make("TextLabel", parent, {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(w, h), Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        Text = text, TextSize = size, TextColor3 = color or WHITE, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Center, ZIndex = math.max(23, parent.ZIndex + 1),
    })
end

local function button(parent, text, x, y, w, h, fill, textColor)
    local b = make("TextButton", parent, {
        Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
        BackgroundColor3 = fill or CARD, BorderSizePixel = 0, AutoButtonColor = true,
        Font = Enum.Font.GothamBold, TextSize = 17, TextColor3 = textColor or WHITE,
        Text = text, TextWrapped = true, ZIndex = math.max(27, parent.ZIndex + 2),
    })
    rounded(b, 10)
    return b
end

local function shade(parent)
    local f = make("Frame", parent, {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(5, 12, 24),
        BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 12,
    })
    return f
end

function LobbyClient.start(config, protocol)
    local player = Players.LocalPlayer
    local folder = ReplicatedStorage:WaitForChild("MW_LobbyRemotes")
    local command = folder:WaitForChild("Command")
    local event = folder:WaitForChild("Event")
    local shared = ReplicatedStorage:WaitForChild("MundialWarShared")

    local worldMap = require(shared.MapGrid).new(require(shared.MapData))
    local state = require(script.Parent.ClientState).new(worldMap, protocol, config,
        require(shared.Palette), require(shared.BuildingStats))
    local gui = make("ScreenGui", player:WaitForChild("PlayerGui"), {
        Name = "MundialWarLobby", ResetOnSpawn = false,
        IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    local ocean = require(shared.Palette).Water
    local viewport = make("Frame", gui, {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(ocean[1], ocean[2], ocean[3]),
        BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 1,
    })
    local mapWorld = make("Frame", viewport, {BackgroundTransparency = 1, ZIndex = 1})
    local cam3d = workspace.CurrentCamera
    cam3d.CameraType = Enum.CameraType.Scriptable
    cam3d.CFrame = CFrame.new(0, 10000, 0) * CFrame.Angles(math.rad(90), 0, 0)
    local camera = require(script.Parent.CameraController).new(viewport, mapWorld, worldMap, config)
    require(script.Parent.MapRenderer).new(state, mapWorld, {frames = true})
    camera:fit()
    shade(gui)

    local base = make("Frame", gui, {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.51),
        Size = UDim2.fromOffset(940, 600), BackgroundTransparency = 1, ZIndex = 20,
    })
    local scale = make("UIScale", base, {Scale = 1})
    local function resize()
        local size = gui.AbsoluteSize
        scale.Scale = math.min(1, math.max(0.42, math.min((size.X - 22) / 950, (size.Y - 18) / 610)))
    end
    gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
    resize()

    label(base, "MUNDIAL WAR", 170, 10, 600, 72, 56, GOLD, true)
    label(base, "DOMINE TERRITÓRIOS  ·  FORME ALIANÇAS  ·  CONQUISTE O MUNDO", 100, 80, 740, 25, 14, MUTED, true)
    local partyButton = button(base, "♟  PARTY", 0, 28, 155, 48, CARD)
    local shopButton = button(base, "🛍  LOJA", 785, 28, 155, 48, CARD)
    local notice = label(base, "", 140, 568, 660, 24, 14, GOLD, true)

    local heading = label(base, "ESCOLHA SEU MODO", 10, 132, 920, 30, 20, WHITE, true)
    local modeCards = {}
    local modes = {
        {key = "classic", title = "🌎  MUNDIAL", desc = "Comece com uma capital e conquiste novos territórios.", x = 0},
        {key = "extreme", title = "🔥  CONQUISTA EXTREMA", desc = "Domine países completos e libere defesas especiais.", x = 477},
    }
    for _, def in ipairs(modes) do
        local frame = rounded(make("Frame", base, {
            Position = UDim2.fromOffset(def.x, 177), Size = UDim2.fromOffset(463, 148),
            BackgroundColor3 = NAVY, BackgroundTransparency = 0.06, BorderSizePixel = 0, ZIndex = 21,
        }), 12)
        label(frame, def.title, 16, 10, 430, 41, 23, WHITE, true)
        label(frame, def.desc, 25, 58, 415, 50, 15, MUTED, false)
        local select = button(frame, "SELECIONAR", 22, 111, 419, 29, CARD)
        select.TextSize = 13
        modeCards[def.key] = {frame = frame, button = select}
        select.Activated:Connect(function() command:FireServer("Mode", def.key) end)
    end

    local public = button(base, "🌐 PARTIDA PÚBLICA", 0, 337, 463, 42, GOLD, Color3.fromRGB(32, 26, 18))
    local inviteGroup = button(base, "👥 CONVIDAR AMIGOS", 477, 337, 463, 42, NAVY)
    local partySummary = label(base, "Party: você", 0, 389, 940, 28, 16, MUTED, false)
    local matchStatus = label(base, "", 0, 418, 940, 25, 14, MUTED, false)
    local play = button(base, "▶  JOGAR AGORA", 0, 452, 940, 75, GOLD, Color3.fromRGB(31, 26, 17))
    play.TextSize = 29

    -- Party overlay: invitations are server-validated and restricted to this lobby.
    local dim = make("TextButton", gui, {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.36, BorderSizePixel = 0, Text = "", Visible = false, ZIndex = 60,
    })
    local party = rounded(make("Frame", dim, {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(540, 450), BackgroundColor3 = NAVY,
        BorderSizePixel = 0, ZIndex = 61,
    }), 16, GOLD)
    local partyScale = make("UIScale", party, {Scale = 1})
    local function resizeParty()
        local size = gui.AbsoluteSize
        partyScale.Scale = math.min(1, math.max(0.55, math.min((size.X - 24) / 540, (size.Y - 24) / 450)))
    end
    gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeParty)
    resizeParty()
    label(party, "👥  PARTY", 25, 18, 390, 46, 29, WHITE, true)
    local close = button(party, "X", 464, 22, 48, 42, CARD)
    label(party, "Convide um jogador do lobby para formar uma dupla.", 22, 75, 496, 40, 14, MUTED)
    local membersTitle = label(party, "Membros: você", 22, 121, 496, 42, 16, GOLD, true)
    local friends = button(party, "CONVIDAR AMIGOS DO ROBLOX", 20, 175, 500, 49, GOLD, Color3.fromRGB(30, 25, 16))
    local listTitle = label(party, "JOGADORES NESTE LOBBY", 20, 236, 500, 25, 15, WHITE, true)
    local scrolling = make("ScrollingFrame", party, {
        Position = UDim2.fromOffset(24, 267), Size = UDim2.fromOffset(490, 128),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5,
        ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.fromOffset(0, 0), ZIndex = 65,
    })
    local leave = button(party, "SAIR / DESFAZER PARTY", 22, 402, 496, 37, CARD)
    leave.TextSize = 14
    close.Activated:Connect(function() dim.Visible = false end)
    dim.Activated:Connect(function() dim.Visible = false end)
    partyButton.Activated:Connect(function() dim.Visible = true end)
    leave.Activated:Connect(function() command:FireServer("Leave") end)

    friends.Activated:Connect(function()
        local ok, allowed = pcall(function() return SocialService:CanSendGameInviteAsync(player) end)
        if not ok or not allowed then
            notice.Text = "Convites do Roblox indisponíveis neste dispositivo ou ambiente."
            return
        end
        local success = pcall(function() SocialService:PromptGameInvite(player) end)
        if not success then notice.Text = "Não foi possível abrir o convite do Roblox." end
    end)

    shopButton.Activated:Connect(function()
        notice.Text = "Loja e inventário: próxima etapa. Nenhuma compra ativa ainda."
    end)
    public.Activated:Connect(function() notice.Text = "Todas as partidas são públicas: jogue com amigos e outros jogadores." end)
    inviteGroup.Activated:Connect(function() dim.Visible = true end)
    play.Activated:Connect(function() command:FireServer("Play") end)

    local activeParty = nil
    local people = {}
    local starting = false
    local function draw()
        if not activeParty then return end
        for key, card in pairs(modeCards) do
            local selected = key == activeParty.mode
            card.button.Text = selected and "✓ SELECIONADO" or "SELECIONAR"
            card.button.BackgroundColor3 = selected and GOLD or CARD
            card.button.TextColor3 = selected and Color3.fromRGB(32, 26, 18) or WHITE
        end
        public.BackgroundColor3 = GOLD
        public.TextColor3 = Color3.fromRGB(32, 26, 18)
        local names = {}
        for _, member in ipairs(activeParty.members or {}) do names[#names + 1] = member.name end
        local summary = table.concat(names, " + ")
        partySummary.Text = "👥  PARTY: " .. summary .. "  (" .. #names .. "/2)"
        membersTitle.Text = "Membros: " .. summary
        local isLeader = activeParty.leader == player.UserId
        play.Text = starting and "CONECTANDO..." or (isLeader and "▶  JOGAR AGORA" or "AGUARDANDO LÍDER")
        play.Active = isLeader and not starting
        play.AutoButtonColor = play.Active
        play.BackgroundColor3 = play.Active and GOLD or Color3.fromRGB(106, 110, 116)
        matchStatus.Text = "Partida pública · seu Party entra junto com jogadores reais e bots"
        for _, child in ipairs(scrolling:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        local row = 0
        for _, user in ipairs(people) do
            if user.userId ~= player.UserId then
                local card = make("Frame", scrolling, {
                    Position = UDim2.fromOffset(0, row * 39), Size = UDim2.fromOffset(472, 35),
                    BackgroundColor3 = CARD, BorderSizePixel = 0, ZIndex = 66,
                })
                rounded(card, 7)
                label(card, user.name, 10, 1, 280, 32, 14, WHITE)
                local invite = button(card, "CONVIDAR", 345, 3, 112, 28, Color3.fromRGB(60, 89, 113))
                invite.TextSize = 12
                invite.ZIndex = 68
                invite.Activated:Connect(function() command:FireServer("Invite", user.userId) end)
                row = row + 1
            end
        end
        scrolling.CanvasSize = UDim2.fromOffset(0, row * 39)
        listTitle.Text = "JOGADORES NESTE LOBBY (" .. #people .. ")"
    end

    -- Invitation response dialog.
    local inviteWindow = rounded(make("Frame", gui, {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(430, 160), BackgroundColor3 = NAVY,
        BorderSizePixel = 0, Visible = false, ZIndex = 85,
    }), 12, GOLD)
    local inviteLabel = label(inviteWindow, "Convite para Party", 15, 12, 400, 65, 19, WHITE, true)
    inviteLabel.ZIndex = 86
    local yes = button(inviteWindow, "✓ ACEITAR", 22, 94, 186, 52, GOLD, Color3.fromRGB(30, 25, 16))
    local no = button(inviteWindow, "✕ RECUSAR", 223, 94, 186, 52, CARD)
    yes.ZIndex, no.ZIndex = 87, 87
    yes.Activated:Connect(function()
        inviteWindow.Visible = false
        command:FireServer("Accept")
    end)
    no.Activated:Connect(function()
        inviteWindow.Visible = false
        command:FireServer("Decline")
    end)

    event.OnClientEvent:Connect(function(data)
        if type(data) ~= "table" then return end
        if data.kind == "State" then
            activeParty = data
            people = data.players or {}
            draw()
        elseif data.kind == "Invite" then
            inviteLabel.Text = (data.name or "Jogador") .. " convidou você para um Party!"
            inviteWindow.Visible = true
            dim.Visible = false
        elseif data.kind == "Notice" then
            notice.Text = data.text or ""
        elseif data.kind == "Starting" then
            starting = data.text ~= ""
            notice.Text = data.text or ""
            draw()
        end
    end)
    command:FireServer("Sync")
end

return LobbyClient
