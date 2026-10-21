local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local StarterGui=game:GetService("StarterGui")
local UserInputService=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local Config=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local claimCell=ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ClaimCell")
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false); StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health,false); StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false); StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu,false) end)
require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls():Disable()
local function hideTouch(g) if g.Name=="TouchGui" and g:IsA("ScreenGui") then g.Enabled=false end end
for _,g in ipairs(player.PlayerGui:GetChildren()) do hideTouch(g) end; player.PlayerGui.ChildAdded:Connect(hideTouch)

local camera=workspace.CurrentCamera; camera.CameraType=Enum.CameraType.Scriptable; camera.FieldOfView=50
local mapW,mapH=Config.Map.Width*Config.Map.CellSize,Config.Map.Height*Config.Map.CellSize
local focus=Vector3.new(Config.Map.Origin.X,0,Config.Map.Origin.Z); local height=Config.Camera.StartHeight
local touches={}; local mouseDragging=false; local mouseStart,lastMousePosition; local pinchActive=false; local lastPinchDistance

local function viewportGroundHalfExtents(h)
    local vp=camera.ViewportSize
    local halfZ=h*math.tan(math.rad(camera.FieldOfView/2))
    local halfX=halfZ*(vp.X/math.max(vp.Y,1))
    return halfX,halfZ
end
local function minFitHeight()
    local vp=camera.ViewportSize
    local f=math.tan(math.rad(camera.FieldOfView/2))
    local byH=(mapH/2)/(f*Config.Camera.Overscan)
    local byW=(mapW/2)/(f*(vp.X/math.max(vp.Y,1))*Config.Camera.Overscan)
    return math.min(byH,byW)
end
local function clampFocus()
    local hx,hz=viewportGroundHalfExtents(height)
    local maxX=math.max(0,mapW/2-hx); local maxZ=math.max(0,mapH/2-hz)
    focus=Vector3.new(math.clamp(focus.X,Config.Map.Origin.X-maxX,Config.Map.Origin.X+maxX),0,math.clamp(focus.Z,Config.Map.Origin.Z-maxZ,Config.Map.Origin.Z+maxZ))
end
local function setZoom(v)
    height=math.clamp(v,Config.Camera.MinHeight,math.min(Config.Camera.MaxHeight,minFitHeight()))
    clampFocus()
end
local function pan(delta)
    local scale=height*Config.Camera.PanSpeed
    focus+=Vector3.new(-delta.X*scale,0,-delta.Y*scale); clampFocus()
end
local function claimAt(pos)
    local map=workspace:FindFirstChild("PixelWarMap"); local folder=map and map:FindFirstChild("Cells"); if not folder then return end
    local ray=camera:ViewportPointToRay(pos.X,pos.Y); local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Include; params.FilterDescendantsInstances={folder}
    local result=workspace:Raycast(ray.Origin,ray.Direction*1000,params); if result then claimCell:FireServer(result.Instance) end
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
setZoom(Config.Camera.StartHeight)
RunService:BindToRenderStep("PixelWarMapCamera",Enum.RenderPriority.Camera.Value+1,function()
    camera.CFrame=CFrame.lookAt(Vector3.new(focus.X,height,focus.Z),Vector3.new(focus.X,0,focus.Z),Vector3.new(0,0,-1))
end)
