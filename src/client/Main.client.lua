local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local StarterGui=game:GetService("StarterGui")
local UserInputService=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local Config=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local mapCommand=nil
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false); StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health,false); StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false); StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu,false) end)
require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls():Disable()
local function hideTouch(g) if g.Name=="TouchGui" and g:IsA("ScreenGui") then g.Enabled=false end end
for _,g in ipairs(player.PlayerGui:GetChildren()) do hideTouch(g) end; player.PlayerGui.ChildAdded:Connect(hideTouch)

local camera=workspace.CurrentCamera; camera.CameraType=Enum.CameraType.Scriptable; camera.FieldOfView=50
local mapW,mapH=Config.Map.Width*Config.Map.CellSize,Config.Map.Height*Config.Map.CellSize
local focus=Vector3.new(Config.Map.Origin.X,0,Config.Map.Origin.Z); local height=Config.Camera.StartHeight
local touches={}; local mouseDragging=false; local mouseStart,lastMousePosition; local pinchActive=false; local lastPinchDistance

local selectedPercent=Config.Territory.DefaultSendPercent or 50

-- Render the strategic map as one large SurfaceGui-backed plane on the client.
-- The server Parts remain the authoritative grid and raycast targets, but no
-- longer need to be individually drawn at long distance.
task.spawn(function()
    local map=workspace:WaitForChild("PixelWarMap",30)
    local folder=map and map:WaitForChild("Cells",30)
    if not folder then return end

    local visual=Instance.new("Part")
    visual.Name="StrategicMapVisual"
    visual.Anchored=true
    visual.CanCollide=false
    visual.CanQuery=false
    visual.CanTouch=false
    visual.CastShadow=false
    visual.Transparency=1
    visual.Size=Vector3.new(mapW,0.05,mapH)
    visual.Position=Vector3.new(Config.Map.Origin.X,Config.Map.Origin.Y+Config.Map.CellHeight+0.04,Config.Map.Origin.Z)
    visual.Parent=map

    local surface=Instance.new("SurfaceGui")
    surface.Name="MapSurface"
    surface.Face=Enum.NormalId.Top
    surface.AlwaysOnTop=false
    surface.LightInfluence=0
    surface.Brightness=1
    surface.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
    surface.CanvasSize=Vector2.new(Config.Map.Width,Config.Map.Height)
    surface.ClipsDescendants=true
    surface.Parent=visual

    local canvas=Instance.new("Frame")
    canvas.Name="Canvas"
    canvas.Size=UDim2.fromScale(1,1)
    canvas.BackgroundTransparency=1
    canvas.BorderSizePixel=0
    canvas.Parent=surface

    local function attachCell(part)
        if not part:IsA("BasePart") then return end
        local x,z=part:GetAttribute("GridX"),part:GetAttribute("GridZ")
        if not x or not z then return end

        local pixel=Instance.new("Frame")
        pixel.Name=part.Name
        pixel.BorderSizePixel=0
        pixel.Position=UDim2.fromOffset(x-1,z-1)
        pixel.Size=UDim2.fromOffset(1,1)
        pixel.BackgroundColor3=part.Color
        pixel.Parent=canvas

        -- Hide only the local 3D rendering. The Part still exists for raycasts
        -- and server ownership, while the consolidated surface draws its color.
        part.LocalTransparencyModifier=1
        part:GetPropertyChangedSignal("Color"):Connect(function()
            if pixel.Parent then pixel.BackgroundColor3=part.Color end
        end)
    end

    for _,part in ipairs(folder:GetChildren()) do attachCell(part) end
    folder.ChildAdded:Connect(attachCell)
end)

task.spawn(function()
    local remotes=ReplicatedStorage:WaitForChild("Remotes",15)
    if remotes then mapCommand=remotes:WaitForChild("MapCommand",15) end
end)
local hud=Instance.new("ScreenGui")
hud.Name="StrategyHUD"; hud.ResetOnSpawn=false; hud.IgnoreGuiInset=true; hud.Parent=player.PlayerGui
local bar=Instance.new("Frame"); bar.Name="BottomBar"; bar.AnchorPoint=Vector2.new(.5,1); bar.Position=UDim2.new(.5,0,1,-16); bar.Size=UDim2.new(0,620,0,74); bar.BackgroundColor3=Color3.fromRGB(20,29,48); bar.BackgroundTransparency=.08; bar.Parent=hud
local barCorner=Instance.new("UICorner"); barCorner.CornerRadius=UDim.new(0,18); barCorner.Parent=bar
local stroke=Instance.new("UIStroke"); stroke.Color=Color3.fromRGB(45,60,85); stroke.Thickness=2; stroke.Parent=bar

local troopsLabel=Instance.new("TextLabel"); troopsLabel.BackgroundTransparency=1; troopsLabel.Position=UDim2.fromOffset(18,8); troopsLabel.Size=UDim2.fromOffset(145,30); troopsLabel.Font=Enum.Font.GothamBold; troopsLabel.TextColor3=Color3.fromRGB(235,239,250); troopsLabel.TextSize=22; troopsLabel.TextXAlignment=Enum.TextXAlignment.Left; troopsLabel.Parent=bar
local rateLabel=Instance.new("TextLabel"); rateLabel.BackgroundTransparency=1; rateLabel.Position=UDim2.fromOffset(18,39); rateLabel.Size=UDim2.fromOffset(145,22); rateLabel.Font=Enum.Font.GothamBold; rateLabel.TextColor3=Color3.fromRGB(255,145,79); rateLabel.TextSize=16; rateLabel.TextXAlignment=Enum.TextXAlignment.Left; rateLabel.Text="+0/s"; rateLabel.Parent=bar

local sendLabel=Instance.new("TextLabel"); sendLabel.BackgroundTransparency=1; sendLabel.Position=UDim2.fromOffset(500,8); sendLabel.Size=UDim2.fromOffset(105,52); sendLabel.Font=Enum.Font.GothamBold; sendLabel.TextColor3=Color3.fromRGB(225,232,248); sendLabel.TextSize=15; sendLabel.TextWrapped=true; sendLabel.Parent=bar
local percentButtons={}
for i,pct in ipairs(Config.Territory.SendPercents) do
    local button=Instance.new("TextButton"); button.Name="P"..pct; button.Position=UDim2.fromOffset(165+(i-1)*66,14); button.Size=UDim2.fromOffset(60,46); button.BackgroundColor3=Color3.fromRGB(30,41,63); button.TextColor3=Color3.fromRGB(190,199,220); button.Font=Enum.Font.GothamBold; button.TextSize=18; button.Text=tostring(pct).."%"; button.Parent=bar
    local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,12); corner.Parent=button
    percentButtons[pct]=button
    button.Activated:Connect(function() selectedPercent=pct end)
end
local function compact(v)
    if v>=1000000 then return string.format("%.2fM",v/1000000) end
    if v>=1000 then return string.format(v>=10000 and "%.1fK" or "%.2fK",v/1000) end
    return tostring(math.floor(v))
end
local function refreshHud()
    local troops=player:GetAttribute("Troops") or 0
    troopsLabel.Text="♟  "..compact(troops)
    sendLabel.Text="Envia\n"..compact(math.floor(troops*selectedPercent/100))
    for pct,b in pairs(percentButtons) do
        local active=pct==selectedPercent
        b.BackgroundColor3=active and Color3.fromRGB(255,183,67) or Color3.fromRGB(30,41,63)
        b.TextColor3=active and Color3.fromRGB(20,24,31) or Color3.fromRGB(190,199,220)
    end
end
player:GetAttributeChangedSignal("Troops"):Connect(refreshHud)
RunService.Heartbeat:Connect(refreshHud)

local function viewportGroundHalfExtents(h)
    local vp=camera.ViewportSize
    local halfZ=h*math.tan(math.rad(camera.FieldOfView/2))
    local halfX=halfZ*(vp.X/math.max(vp.Y,1))
    return halfX,halfZ
end
local function worldFitHeight()
    local vp=camera.ViewportSize
    local aspect=vp.X/math.max(vp.Y,1)
    local f=math.tan(math.rad(camera.FieldOfView/2))
    local fit=Config.Camera.Overscan or 0.96
    local byH=((mapH*fit)/2)/f
    local byW=((mapW*fit)/2)/(f*aspect)
    return math.max(byH,byW)
end
local function clampFocus()
    local hx,hz=viewportGroundHalfExtents(height)
    local maxX=math.max(0,mapW/2-hx); local maxZ=math.max(0,mapH/2-hz)
    focus=Vector3.new(math.clamp(focus.X,Config.Map.Origin.X-maxX,Config.Map.Origin.X+maxX),0,math.clamp(focus.Z,Config.Map.Origin.Z-maxZ,Config.Map.Origin.Z+maxZ))
end
local function setZoom(v)
    height=math.clamp(v,Config.Camera.MinHeight,worldFitHeight())
    clampFocus()
end
local function pan(delta)
    local scale=height*Config.Camera.PanSpeed
    focus+=Vector3.new(-delta.X*scale,0,-delta.Y*scale); clampFocus()
end
local function claimAt(pos)
    local map=workspace:FindFirstChild("PixelWarMap"); local folder=map and map:FindFirstChild("Cells"); if not folder then return end
    local ray=camera:ViewportPointToRay(pos.X,pos.Y); local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Include; params.FilterDescendantsInstances={folder}
    local result=workspace:Raycast(ray.Origin,ray.Direction*1000,params); if result and mapCommand then mapCommand:FireServer(result.Instance,selectedPercent) end
end
UserInputService.InputBegan:Connect(function(input,processed)
    if processed then return end
    if input.UserInputType==Enum.UserInputType.Touch then touches[input]={position=input.Position,start=input.Position,moved=false}
    elseif input.UserInputType==Enum.UserInputType.MouseButton1 then mouseDragging=true; mouseStart=input.Position; lastMousePosition=input.Position end
end)
UserInputService.InputChanged:Connect(function(input,processed)
    if input.UserInputType==Enum.UserInputType.MouseWheel then setZoom(height*(input.Position.Z>0 and .86 or 1.14)); return end
    if processed then return end
    if input.UserInputType==Enum.UserInputType.Touch and touches[input] then
        local d=touches[input]; local prev=d.position; d.position=input.Position; if (d.position-d.start).Magnitude>10 then d.moved=true end
        local active={}; for touch,info in pairs(touches) do if touch.UserInputState~=Enum.UserInputState.End then table.insert(active,info) end end
        if #active==1 and not pinchActive then pan(input.Position-prev)
        elseif #active>=2 then pinchActive=true; active[1].moved=true; active[2].moved=true; local dist=(active[1].position-active[2].position).Magnitude; if lastPinchDistance and lastPinchDistance>0 then setZoom(height*(lastPinchDistance/math.max(dist,1))) end; lastPinchDistance=dist end
    elseif input.UserInputType==Enum.UserInputType.MouseMovement and mouseDragging and lastMousePosition then pan(input.Position-lastMousePosition); lastMousePosition=input.Position end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.Touch then
        local d=touches[input]; touches[input]=nil; local remaining=0; for _ in pairs(touches) do remaining+=1 end
        if d and not d.moved and not pinchActive then claimAt(input.Position) end
        if remaining==0 then pinchActive=false; lastPinchDistance=nil end
    elseif input.UserInputType==Enum.UserInputType.MouseButton1 then
        if mouseStart and (input.Position-mouseStart).Magnitude<8 then claimAt(input.Position) end
        mouseDragging=false; mouseStart=nil; lastMousePosition=nil
    end
end)
-- Start with the complete world centered and visible.
focus=Vector3.new(Config.Map.Origin.X,0,Config.Map.Origin.Z)
setZoom(worldFitHeight())
RunService:BindToRenderStep("PixelWarMapCamera",Enum.RenderPriority.Camera.Value+1,function()
    local target=Vector3.new(focus.X,Config.Map.Origin.Y,focus.Z)
    local cameraPosition=Vector3.new(focus.X,height,focus.Z)
    camera.CFrame=CFrame.lookAt(cameraPosition,target,Vector3.new(0,0,-1))
    -- Keep Roblox's render-interest point on the world surface. On low graphics,
    -- a stale Camera.Focus can cause distant top-down geometry to be culled.
    camera.Focus=CFrame.new(target)
    local map=workspace:FindFirstChild("PixelWarMap")
    local markers=map and map:FindFirstChild("Markers")
    if markers then
        for _,marker in ipairs(markers:GetChildren()) do
            local gui=marker:FindFirstChild("Label")
            if gui and gui:IsA("BillboardGui") then
                local count=gui:GetAttribute("TerritoryCells") or 0
                local minCells=Config.Marker.NearMinCells
                if height>=Config.Marker.FarHeight then minCells=Config.Marker.FarMinCells
                elseif height>=Config.Marker.MediumHeight then minCells=Config.Marker.MediumMinCells end
                gui.Enabled=count>=minCells
            end
        end
    end
end)
