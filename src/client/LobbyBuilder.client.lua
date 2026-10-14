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
local panel=Instance.new("Frame"); panel.Size=UDim2.new(1,-24,0,168); panel.Position=UDim2.new(0,12,1,-238); panel.Visible=false; panel.Parent=gui
local title=Instance.new("TextLabel"); title.Size=UDim2.new(1,0,0,30); title.BackgroundTransparency=1; title.Text="CATÁLOGO HALLOWEEN"; title.Parent=panel
local scroll=Instance.new("ScrollingFrame"); scroll.Size=UDim2.new(1,-12,0,78); scroll.Position=UDim2.fromOffset(6,32); scroll.AutomaticCanvasSize=Enum.AutomaticSize.X; scroll.CanvasSize=UDim2.new(); scroll.ScrollingDirection=Enum.ScrollingDirection.X; scroll.Parent=panel
local layout=Instance.new("UIListLayout"); layout.FillDirection=Enum.FillDirection.Horizontal; layout.Padding=UDim.new(0,6); layout.Parent=scroll
local controls=Instance.new("Frame"); controls.BackgroundTransparency=1; controls.Size=UDim2.new(1,-12,0,48); controls.Position=UDim2.fromOffset(6,114); controls.Parent=panel

local selected=nil; local rotation=0
local status=Instance.new("TextLabel"); status.Size=UDim2.new(.34,0,1,0); status.BackgroundTransparency=1; status.Text="Selecione um item"; status.TextScaled=true; status.Parent=controls
local function button(text,x,w,fn)
 local b=Instance.new("TextButton"); b.Text=text; b.Size=UDim2.new(w,-4,1,0); b.Position=UDim2.new(x,0,0,0); b.Parent=controls; b.Activated:Connect(fn); return b
end
button("↻ GIRAR",.35,.2,function() rotation=(rotation+45)%360; status.Text=(selected or "Item").."  "..rotation.."°" end)
button("APAGAR",.55,.2,function()
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart"); if root then local r=request:InvokeServer("deleteNearest",{position=root.Position}); status.Text=r.ok and "Item removido" or (r.error or "Erro") end
end)
button("FECHAR",.75,.25,function() panel.Visible=false end)

local function load()
 local r=request:InvokeServer("catalog"); if not r.ok then status.Text=r.error or "Erro"; return end
 if #r.items==0 then status.Text="Asset sem itens utilizáveis"; return end
 for _,name in ipairs(r.items) do
  local b=Instance.new("TextButton"); b.Size=UDim2.fromOffset(112,68); b.Text=name; b.TextWrapped=true; b.Parent=scroll
  b.Activated:Connect(function() selected=name; status.Text=name.."  "..rotation.."°" end)
 end
end
open.Activated:Connect(function() panel.Visible=not panel.Visible; if panel.Visible and #scroll:GetChildren()<=1 then load() end end)

local function placeAt(screenPos)
 if not panel.Visible or not selected then return end
 local cam=workspace.CurrentCamera
 local ray=cam:ViewportPointToRay(screenPos.X,screenPos.Y)
 local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={player.Character}
 local hit=workspace:Raycast(ray.Origin,ray.Direction*500,params)
 if hit then
  local r=request:InvokeServer("place",{name=selected,position=hit.Position,rotation=rotation})
  status.Text=r.ok and "Colocado ✓" or (r.error or "Erro")
 end
end
UIS.TouchTap:Connect(function(points,processed) if not processed and points[1] then placeAt(points[1]) end end)
UIS.InputBegan:Connect(function(input,processed) if not processed and input.UserInputType==Enum.UserInputType.MouseButton1 then placeAt(input.Position) end end)
