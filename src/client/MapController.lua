local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local MapController = {}

local function point(input)
    return Vector2.new(input.Position.X, input.Position.Y)
end

function MapController.connect(view, onInspect)
    local connections, touches, order = {}, {}, {}
    local mouse, mouseStart, dragged, pinched = nil, nil, false, false
    local firstTouchStart
    local function connect(signal, callback)
        connections[#connections + 1] = signal:Connect(callback)
    end
    connect(view.Viewport.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            touches[input] = point(input)
            order[#order + 1] = input
            if #order == 1 then
                firstTouchStart, dragged, pinched = point(input), false, false
            else
                pinched = true
            end
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            mouse, mouseStart, dragged = point(input), point(input), false
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if touches[input] then
            local before = touches[input]
            local oldFirst, oldSecond = touches[order[1]], touches[order[2]]
            touches[input] = point(input)
            if #order >= 2 then
                local newFirst, newSecond = touches[order[1]], touches[order[2]]
                local oldDistance = (oldFirst - oldSecond).Magnitude
                local newDistance = (newFirst - newSecond).Magnitude
                local oldCenter, newCenter = (oldFirst + oldSecond) / 2, (newFirst + newSecond) / 2
                if oldDistance > 4 and newDistance > 4 then
                    view:SetZoom(view.Zoom * newDistance / oldDistance, oldCenter)
                    view:PanBy(newCenter - oldCenter)
                end
            else
                if (point(input) - firstTouchStart).Magnitude > view.Config.DragThreshold then dragged = true end
                view:PanBy(point(input) - before)
            end
        elseif input.UserInputType == Enum.UserInputType.MouseMovement and mouse then
            local nextPoint = point(input)
            if (nextPoint - mouseStart).Magnitude > view.Config.DragThreshold then dragged = true end
            view:PanBy(nextPoint - mouse)
            mouse = nextPoint
        end
    end)
    connect(view.Viewport.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            local inset = GuiService:GetGuiInset()
            view:SetZoom(view.Zoom * view.Config.ZoomStep ^ input.Position.Z,
                UserInputService:GetMouseLocation() - inset)
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if touches[input] then
            if #order == 1 and not dragged and not pinched then onInspect(touches[input]) end
            touches[input] = nil
            for i, item in ipairs(order) do
                if item == input then table.remove(order, i) break end
            end
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 and mouse then
            if not dragged then onInspect(point(input)) end
            mouse = nil
        end
    end)
    connect(UserInputService.WindowFocusReleased, function()
        touches, order, mouse = {}, {}, nil
    end)
    return function()
        for _, connection in ipairs(connections) do connection:Disconnect() end
    end
end

return MapController
