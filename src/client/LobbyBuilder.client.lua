-- LobbyBuilder.client.lua
-- Mobile-first creative HUD.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer
if player.UserId~=9538436641 then return end
local request=RS:WaitForChild("LobbyBuilderRemotes"):WaitForChild("Request")

local gui=Instance.new("ScreenGui"); gui.Name="LobbyCreativeHUD"; gui.ResetOnSpawn=false; gui.Parent=player:WaitForChild("PlayerGui")
local open=Instance.new("TextButton"); open.Size=UDim2.fromOffset(116,42); open.Position=UDim2.new(0,12,1,-58); open.Text="CONSTRUIR"; open.Parent=gui
local panel=Instance.new("Frame"); panel.Size=UDim2.new(1,-20,0,112); panel.Position=UDim2.new(0,10,1,-122); panel.Visible=false; panel.Parent=gui
local title=Instance.new("TextLabel"); title.Visible=false; title.Parent=panel
local scroll=Instance.new("ScrollingFrame"); scroll.Size=UDim2.new(1,-12,0,58); scroll.Position=UDim2.fromOffset(6,5); scroll.AutomaticCanvasSize=Enum.AutomaticSize.X; scroll.CanvasSize=UDim2.new(); scroll.ScrollingDirection=Enum.ScrollingDirection.X; scroll.Parent=panel
local layout=Instance.new("UIListLayout"); layout.FillDirection=Enum.FillDirection.Horizontal; layout.Padding=UDim.new(0,6); layout.Parent=scroll
local controls=Instance.new("Frame"); controls.BackgroundTransparency=1; controls.Size=UDim2.new(1,-12,0,40); controls.Position=UDim2.fromOffset(6,67); controls.Parent=panel

local selected=nil; local rotation=0
local status=Instance.new("TextLabel"); status.Size=UDim2.new(.34,0,1,0); status.BackgroundTransparency=1; status.Text="Selecione um item"; status.TextScaled=true; status.Parent=controls
local function button(text,x,w,fn)
 local b=Instance.new("TextButton"); b.Text=text; b.Size=UDim2.new(w,-4,1,0); b.Position=UDim2.new(x,0,0,0); b.Parent=controls; b.Activated:Connect(fn); return b
end
button("↻",.55,.10,function() rotation=(rotation+45)%360; status.Text=(selected or "Item").."  "..rotation.."°" end)
button("APAGAR",.65,.18,function()
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart"); if root then local r=request:InvokeServer("deleteNearest",{position=root.Position}); status.Text=r.ok and "Item removido" or (r.error or "Erro") end
end)
button("X",.83,.17,function() clearPreview(); panel.Visible=false end)


local preview=nil
local previewPosition=nil
local function clearPreview()
 if preview then preview:Destroy(); preview=nil end
 previewPosition=nil
end
local function setGhost(obj)
 for _,d in ipairs(obj:GetDescendants()) do
  if d:IsA("BasePart") then d.Anchored=true; d.CanCollide=false; d.CanTouch=false; d.CanQuery=false; d.Transparency=math.max(d.Transparency,0.55) end
 end
 if obj:IsA("BasePart") then obj.Anchored=true; obj.CanCollide=false; obj.CanTouch=false; obj.CanQuery=false; obj.Transparency=math.max(obj.Transparency,0.55) end
end
local function moveGhost(obj,cf)
 if obj:IsA("Model") then obj:PivotTo(cf)
 elseif obj:IsA("BasePart") then obj.CFrame=cf
 else local p=obj:FindFirstChildWhichIsA("BasePart",true); if p then p.CFrame=cf end end
end
local function makePreview(name)
 clearPreview()
 local template=RS:WaitForChild("HalloweenCatalog"):FindFirstChild(name)
 if not template then return end
 preview=template:Clone(); preview.Name="CreativePreview"; setGhost(preview); preview.Parent=workspace
end

local function load()
 local r=request:InvokeServer("catalog"); if not r.ok then status.Text=r.error or "Erro"; return end
 if #r.items==0 then status.Text="Asset sem itens utilizáveis"; return end
 for _,name in ipairs(r.items) do
  local b=Instance.new("TextButton"); b.Size=UDim2.fromOffset(96,54); b.Text=name:gsub("^%d+_",""); b.TextWrapped=true; b.TextScaled=true; b.Parent=scroll
  b.Activated:Connect(function() selected=name; makePreview(name); status.Text=name:gsub("^%d+_","").."  "..rotation.."°" end)
 end
end
open.Activated:Connect(function() panel.Visible=not panel.Visible; if panel.Visible and #scroll:GetChildren()<=1 then load() end end)

local function pointPreview(screenPos)
 if not panel.Visible or not selected or not preview then return end
 local cam=workspace.CurrentCamera
 local ray=cam:ViewportPointToRay(screenPos.X,screenPos.Y)
 local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={player.Character,preview}
 local hit=workspace:Raycast(ray.Origin,ray.Direction*500,params)
 if hit then
  previewPosition=hit.Position
  moveGhost(preview,CFrame.new(previewPosition)*CFrame.Angles(0,math.rad(rotation),0))
  status.Text="Prévia pronta"
 end
end
UIS.TouchTap:Connect(function(points,processed) if not processed and points[1] then pointPreview(points[1]) end end)
UIS.InputBegan:Connect(function(input,processed) if not processed and input.UserInputType==Enum.UserInputType.MouseButton1 then pointPreview(input.Position) end end)

local placeButton=Instance.new("TextButton")
placeButton.Text="COLOCAR"; placeButton.TextScaled=true
placeButton.Size=UDim2.new(.2,-4,1,0); placeButton.Position=UDim2.new(.35,0,0,0); placeButton.Parent=controls
placeButton.Activated:Connect(function()
 if selected and previewPosition then
  local r=request:InvokeServer("place",{name=selected,position=previewPosition,rotation=rotation})
  status.Text=r.ok and "Colocado ✓" or (r.error or "Erro")
 end
end)
