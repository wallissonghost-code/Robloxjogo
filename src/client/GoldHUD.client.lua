local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local GuiService = game:GetService("GuiService")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "GoldHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ScreenInsets = Enum.ScreenInsets.None
gui.ClipToDeviceSafeArea = false
gui.DisplayOrder = 20
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "Balance"
frame.AnchorPoint = Vector2.new(1, 0)
frame.Position = UDim2.new(1, 0, 0, 6)
frame.Size = UDim2.fromOffset(112, 38)
frame.BackgroundColor3 = Color3.fromRGB(13, 15, 18)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(72, 76, 84)
stroke.Transparency = 0.45
stroke.Thickness = 1
stroke.Parent = frame

local coin = Instance.new("Frame")
coin.Name = "Coin"
coin.AnchorPoint = Vector2.new(0, 0.5)
coin.Position = UDim2.new(0, 10, 0.5, 0)
coin.Size = UDim2.fromOffset(16, 16)
coin.BackgroundColor3 = Color3.fromRGB(255, 199, 47)
coin.BorderSizePixel = 0
coin.Parent = frame

local coinCorner = Instance.new("UICorner")
coinCorner.CornerRadius = UDim.new(1, 0)
coinCorner.Parent = coin

local coinInner = Instance.new("Frame")
coinInner.AnchorPoint = Vector2.new(0.5, 0.5)
coinInner.Position = UDim2.fromScale(0.5, 0.5)
coinInner.Size = UDim2.fromOffset(7, 7)
coinInner.BackgroundTransparency = 1
coinInner.BorderSizePixel = 0
coinInner.Parent = coin
local coinStroke = Instance.new("UIStroke")
coinStroke.Color = Color3.fromRGB(126, 88, 12)
coinStroke.Thickness = 1.5
coinStroke.Parent = coinInner
local coinInnerCorner = Instance.new("UICorner")
coinInnerCorner.CornerRadius = UDim.new(1, 0)
coinInnerCorner.Parent = coinInner

local amount = Instance.new("TextLabel")
amount.BackgroundTransparency = 1
amount.Position = UDim2.fromOffset(34, 0)
amount.Size = UDim2.new(1, -44, 1, 0)
amount.Font = Enum.Font.GothamBold
amount.TextColor3 = Color3.fromRGB(255, 211, 74)
amount.TextSize = 17
amount.TextXAlignment = Enum.TextXAlignment.Left
amount.TextYAlignment = Enum.TextYAlignment.Center
amount.Parent = frame


local hudRemote=RS:WaitForChild("HUDPosition")
local settingsX,settingsY=-87,0
local hudX,hudY,activePreset=0,-4,"hud1"
local sizeScale=1
local settingsScale=1
local jumpX,jumpY,jumpScale=-28,-110,1
local localPresets={hud1={x=0,y=-4,scale=1},hud2={x=0,y=-4,scale=1}}
local ok,got,slot,x,y,savedScale,savedSX,savedSY,savedSS,savedJX,savedJY,savedJS=pcall(function() return hudRemote:InvokeServer("get") end)
if ok and got then activePreset=slot or "hud1";hudX=math.min(x or 0,0);hudY=y or -4;sizeScale=math.clamp(tonumber(savedScale) or 1,.7,1.4);settingsX=savedSX or -87;settingsY=savedSY or 0;settingsScale=math.clamp(tonumber(savedSS) or 1,.7,1.4);jumpX=savedJX or -28;jumpY=savedJY or -110;jumpScale=math.clamp(tonumber(savedJS) or 1,.7,1.4);localPresets[activePreset]={x=hudX,y=hudY,scale=sizeScale} end

local function applyPosition()
 frame.Position=UDim2.new(1,hudX,0,hudY)
 frame:SetAttribute("HUDX",hudX);frame:SetAttribute("HUDY",hudY)
end
applyPosition()

-- Settings button is intentionally fixed to the screen, never parented to movable HUD.
local settingsButton=Instance.new("TextButton")
settingsButton.Name="SettingsButton";settingsButton.AnchorPoint=Vector2.new(1,0)
settingsButton.Position=UDim2.new(1,settingsX,0,settingsY);settingsButton.Size=UDim2.fromOffset(38*settingsScale,38*settingsScale)
settingsButton.BackgroundColor3=Color3.fromRGB(13,15,18);settingsButton.Text="";settingsButton.BorderSizePixel=0;settingsButton.Parent=gui
local settingsMove=Instance.new("BindableEvent");settingsMove.Name="SettingsMove";settingsMove.Parent=gui
settingsMove.Event:Connect(function(dx,dy)
 settingsX=math.clamp(settingsX+dx,-500,0);settingsY=math.clamp(settingsY+dy,0,500)
 settingsButton.Position=UDim2.new(1,settingsX,0,settingsY)
 settingsButton:SetAttribute("HUDX",settingsX);settingsButton:SetAttribute("HUDY",settingsY)
end)
settingsButton:SetAttribute("HUDX",settingsX);settingsButton:SetAttribute("HUDY",settingsY)
local sbc=Instance.new("UICorner");sbc.CornerRadius=UDim.new(0,10);sbc.Parent=settingsButton
local sbs=Instance.new("UIStroke");sbs.Color=Color3.fromRGB(72,76,84);sbs.Transparency=.45;sbs.Thickness=1;sbs.Parent=settingsButton
local gear=Instance.new("Frame");gear.AnchorPoint=Vector2.new(.5,.5);gear.Position=UDim2.fromScale(.5,.5);gear.Size=UDim2.fromOffset(15,15);gear.BackgroundColor3=Color3.fromRGB(255,199,47);gear.BorderSizePixel=0;gear.Parent=settingsButton
local gc=Instance.new("UICorner");gc.CornerRadius=UDim.new(1,0);gc.Parent=gear
local hole=Instance.new("Frame");hole.AnchorPoint=Vector2.new(.5,.5);hole.Position=UDim2.fromScale(.5,.5);hole.Size=UDim2.fromOffset(6,6);hole.BackgroundColor3=Color3.fromRGB(13,15,18);hole.BorderSizePixel=0;hole.Parent=gear
local hc=Instance.new("UICorner");hc.CornerRadius=UDim.new(1,0);hc.Parent=hole

local panel=Instance.new("Frame");panel.Name="SettingsPanel";panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5);panel.Size=UDim2.fromScale(.64,.68);panel.BackgroundColor3=Color3.fromRGB(9,11,15);panel.BorderSizePixel=0;panel.Visible=false;panel.Parent=gui
local limit=Instance.new("UISizeConstraint");limit.MinSize=Vector2.new(300,280);limit.MaxSize=Vector2.new(680,460);limit.Parent=panel
local pc=Instance.new("UICorner");pc.CornerRadius=UDim.new(0,16);pc.Parent=panel
local ps=Instance.new("UIStroke");ps.Color=Color3.fromRGB(222,166,36);ps.Transparency=.12;ps.Thickness=1.5;ps.Parent=panel
local function label(parent,t,pos,size,ts,bold,col)
 local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Position=pos;l.Size=size;l.Text=t;l.TextColor3=col or Color3.fromRGB(238,240,244);l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham;l.TextSize=ts;l.TextXAlignment=Enum.TextXAlignment.Left;l.TextYAlignment=Enum.TextYAlignment.Center;l.Parent=parent;return l
end
label(panel,"CONFIGURAÇÕES",UDim2.fromOffset(24,14),UDim2.new(1,-80,0,28),21,true)
label(panel,"Personalize sua experiência",UDim2.fromOffset(24,42),UDim2.new(1,-80,0,20),11,false,Color3.fromRGB(145,151,164))
local close=Instance.new("TextButton");close.AnchorPoint=Vector2.new(1,0);close.Position=UDim2.new(1,-16,0,16);close.Size=UDim2.fromOffset(34,34);close.BackgroundColor3=Color3.fromRGB(28,31,38);close.Text="×";close.TextColor3=Color3.new(1,1,1);close.TextSize=24;close.Font=Enum.Font.GothamBold;close.BorderSizePixel=0;close.Parent=panel
local cc=Instance.new("UICorner");cc.CornerRadius=UDim.new(0,9);cc.Parent=close

local nav=Instance.new("Frame");nav.Position=UDim2.fromOffset(20,76);nav.Size=UDim2.new(0,142,1,-96);nav.BackgroundColor3=Color3.fromRGB(14,17,22);nav.BorderSizePixel=0;nav.Parent=panel
local nc=Instance.new("UICorner");nc.CornerRadius=UDim.new(0,11);nc.Parent=nav
local function navItem(text,y,active)
 local bt=Instance.new("TextButton");bt.Position=UDim2.fromOffset(8,y);bt.Size=UDim2.new(1,-16,0,42);bt.BackgroundColor3=active and Color3.fromRGB(255,195,43) or Color3.fromRGB(25,28,35);bt.Text=text;bt.TextColor3=active and Color3.fromRGB(18,18,18) or Color3.fromRGB(190,194,203);bt.Font=Enum.Font.GothamBold;bt.TextSize=12;bt.BorderSizePixel=0;bt.Parent=nav;local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=bt;return bt
end
navItem("HUD",8,true);navItem("ÁUDIO",58,false).AutoButtonColor=false;navItem("GRÁFICOS",108,false).AutoButtonColor=false

local content=Instance.new("Frame");content.Position=UDim2.fromOffset(178,76);content.Size=UDim2.new(1,-198,1,-96);content.BackgroundTransparency=1;content.BorderSizePixel=0;content.Parent=panel
label(content,"CONFIGURAR HUD",UDim2.fromOffset(0,0),UDim2.new(1,-10,0,24),17,true)
label(content,"Escolha um perfil e entre no modo de edição.",UDim2.fromOffset(0,25),UDim2.new(1,-10,0,22),10,false,Color3.fromRGB(150,155,166))
label(content,"PERFIL",UDim2.fromOffset(0,56),UDim2.new(1,-10,0,18),10,true,Color3.fromRGB(150,155,166))
local profileRow=Instance.new("Frame");profileRow.Position=UDim2.fromOffset(0,78);profileRow.Size=UDim2.new(1,-8,0,38);profileRow.BackgroundTransparency=1;profileRow.Parent=content
local profileButtons={}
for i,n in ipairs({"HUD 1","HUD 2"}) do
 local bt=Instance.new("TextButton");bt.Position=UDim2.new((i-1)*.5,0,0,0);bt.Size=UDim2.new(.5,-5,1,0);bt.BackgroundColor3=Color3.fromRGB(28,31,38);bt.Text=n;bt.TextColor3=Color3.new(1,1,1);bt.Font=Enum.Font.GothamBold;bt.TextSize=11;bt.BorderSizePixel=0;bt.Parent=profileRow;local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=bt;profileButtons[i]=bt
end
label(content,"EDIÇÃO",UDim2.fromOffset(0,128),UDim2.new(1,-10,0,18),10,true,Color3.fromRGB(150,155,166))
local modify=Instance.new("TextButton");modify.Position=UDim2.fromOffset(0,150);modify.Size=UDim2.new(1,-8,0,42);modify.BackgroundColor3=Color3.fromRGB(255,195,43);modify.Text="MODIFICAR HUD";modify.TextColor3=Color3.fromRGB(18,18,18);modify.Font=Enum.Font.GothamBold;modify.TextSize=11;modify.BorderSizePixel=0;modify.Parent=content;local mc=Instance.new("UICorner");mc.CornerRadius=UDim.new(0,8);mc.Parent=modify
label(content,"Entre no modo de edição e toque no elemento que deseja ajustar.",UDim2.fromOffset(0,198),UDim2.new(1,-12,0,34),10,false,Color3.fromRGB(150,155,166))
local reset=Instance.new("TextButton");reset.Position=UDim2.fromOffset(0,242);reset.Size=UDim2.new(1,-8,0,36);reset.BackgroundColor3=Color3.fromRGB(28,31,38);reset.Text="REDEFINIR HUD";reset.TextColor3=Color3.fromRGB(225,228,234);reset.Font=Enum.Font.GothamBold;reset.TextSize=10;reset.BorderSizePixel=0;reset.Parent=content;local rc=Instance.new("UICorner");rc.CornerRadius=UDim.new(0,8);rc.Parent=reset
local editShield=Instance.new("TextButton");editShield.Name="HUDEditShield";editShield.Position=UDim2.fromScale(0,0);editShield.Size=UDim2.fromScale(1,1);editShield.BackgroundTransparency=1;editShield.Text="";editShield.AutoButtonColor=false;editShield.Active=false;editShield.Modal=false;editShield.ZIndex=90;editShield.Parent=gui
local editor=Instance.new("Frame");editor.Name="HUDEditor";editor.ZIndex=100;editor.AnchorPoint=Vector2.new(.5,1);editor.Position=UDim2.new(.5,0,1,-24);editor.Size=UDim2.fromOffset(430,104);editor.BackgroundColor3=Color3.fromRGB(9,11,15);editor.BorderSizePixel=0;editor.Visible=false;editor.Parent=gui
local elimit=Instance.new("UISizeConstraint");elimit.MinSize=Vector2.new(330,104);elimit.MaxSize=Vector2.new(430,104);elimit.Parent=editor
local edc=Instance.new("UICorner");edc.CornerRadius=UDim.new(0,14);edc.Parent=editor
local eds=Instance.new("UIStroke");eds.Color=Color3.fromRGB(222,166,36);eds.Transparency=.12;eds.Thickness=1.5;eds.Parent=editor
local editTitle=label(editor,"TOQUE EM UM ELEMENTO",UDim2.fromOffset(14,8),UDim2.new(1,-110,0,22),11,true,Color3.fromRGB(255,199,47))
local editInfo=label(editor,"",UDim2.fromOffset(14,30),UDim2.new(1,-28,0,18),9,false,Color3.fromRGB(165,170,180))
local selectedElement=nil
local diagX,diagY,diagScale=12,12,1
local buildX,buildY,buildScale=0,0,1
local diagProxy=Instance.new("TextButton");diagProxy.Name="DiagnosticEditProxy";diagProxy.BackgroundTransparency=1;diagProxy.Text="";diagProxy.Visible=false;diagProxy.ZIndex=110;diagProxy.Parent=gui
local buildProxy=Instance.new("TextButton");buildProxy.Name="BuildEditProxy";buildProxy.BackgroundTransparency=1;buildProxy.Text="";buildProxy.Visible=false;buildProxy.ZIndex=110;buildProxy.Parent=gui
local function syncEditProxies()
 local dg=player.PlayerGui:FindFirstChild("BuildDiagnostic")
 local db=dg and dg:FindFirstChild("OpenDiagnostic")
 if db then diagProxy.Position=db.Position;diagProxy.Size=db.Size end
 -- build tag is world-space, so we provide a screen editor target around its usual top-center visual area
 buildProxy.AnchorPoint=Vector2.new(.5,0);buildProxy.Position=UDim2.new(.5,buildX,0,90+buildY);buildProxy.Size=UDim2.fromOffset(150*buildScale,34*buildScale)
end

local selectionStroke=Instance.new("UIStroke");selectionStroke.Name="EditSelection";selectionStroke.Color=Color3.fromRGB(70,255,120);selectionStroke.Thickness=2.5;selectionStroke.Transparency=1;selectionStroke.Parent=frame
local settingsSelection=Instance.new("UIStroke");settingsSelection.Name="EditSelection";settingsSelection.Color=Color3.fromRGB(70,255,120);settingsSelection.Thickness=3;settingsSelection.Transparency=1;settingsSelection.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;settingsSelection.Parent=settingsButton
local function jumpButton()
 local jg=player.PlayerGui:FindFirstChild("CustomJumpHUD");return jg and jg:FindFirstChild("CustomJumpButton")
end
local function applyJump()
 local jb=jumpButton();if jb then jb.Position=UDim2.new(1,jumpX,1,jumpY);jb.Size=UDim2.fromOffset(76*jumpScale,76*jumpScale) end
 local jg=player.PlayerGui:FindFirstChild("CustomJumpHUD");local ev=jg and jg:FindFirstChild("JumpHUDEdit");if ev then ev:Fire(jumpX,jumpY,jumpScale) end
end
local jumpSelection
local function clearSelection() selectionStroke.Transparency=1;settingsSelection.Transparency=1;if jumpSelection then jumpSelection.Transparency=1 end end
local controls=Instance.new("Frame");controls.Position=UDim2.fromOffset(12,54);controls.Size=UDim2.new(1,-24,0,38);controls.BackgroundTransparency=1;controls.ZIndex=101;controls.Parent=editor
local defs={{"←",-5,0},{"→",5,0},{"↑",0,-5},{"↓",0,5}}
for i,d in ipairs(defs) do
 local bt=Instance.new("TextButton");bt.Position=UDim2.new((i-1)*.14,0,0,0);bt.Size=UDim2.new(.13,-3,1,0);bt.BackgroundColor3=Color3.fromRGB(28,31,38);bt.Text=d[1];bt.TextColor3=Color3.new(1,1,1);bt.Font=Enum.Font.GothamBold;bt.TextSize=17;bt.BorderSizePixel=0;bt.ZIndex=102;bt.Parent=controls;local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=bt
 bt.Activated:Connect(function()if selectedElement=="diagnostic" then diagX=math.clamp(diagX+d[2],0,1000);diagY=math.clamp(diagY+d[3],0,700);local dg=player.PlayerGui:FindFirstChild("BuildDiagnostic");local db=dg and dg:FindFirstChild("OpenDiagnostic");if db then db.Position=UDim2.fromOffset(diagX,diagY);diagProxy.Position=db.Position end;editInfo.Text="X "..diagX.."  Y "..diagY.."  •  tamanho "..math.floor(diagScale*100).."%";return elseif selectedElement=="build" then buildX=buildX+d[2];buildY=buildY+d[3];syncEditProxies();editInfo.Text="X "..buildX.."  Y "..buildY.."  •  tamanho "..math.floor(buildScale*100).."%";return elseif selectedElement=="jump" then jumpX=math.clamp(jumpX+d[2],-1000,0);jumpY=math.clamp(jumpY+d[3],-1000,0);applyJump();editInfo.Text="X "..jumpX.."  Y "..jumpY.."  •  tamanho "..math.floor(jumpScale*100).."%";return elseif selectedElement=="settings" then settingsX=math.clamp(settingsX+d[2],-500,0);settingsY=math.clamp(settingsY+d[3],0,500);settingsButton.Position=UDim2.new(1,settingsX,0,settingsY);settingsButton:SetAttribute("HUDX",settingsX);settingsButton:SetAttribute("HUDY",settingsY);editInfo.Text="X "..settingsX.."  Y "..settingsY.."  •  tamanho "..math.floor(settingsScale*100).."%";return elseif selectedElement~="gold" then return end;hudX=math.clamp(hudX+d[2],-500,0);hudY=math.clamp(hudY+d[3],-100,500);applyPosition();editInfo.Text="X "..hudX.."  Y "..hudY.."  •  tamanho "..math.floor((frame:GetAttribute("HUDScale") or 1)*100).."%" end)
end
local function applyScale()
 local baseW=math.max(86,frame:GetAttribute("BaseWidth") or 112)
 frame.Size=UDim2.fromOffset(baseW*sizeScale,38*sizeScale);frame:SetAttribute("HUDScale",sizeScale)
 editInfo.Text="X "..hudX.."  Y "..hudY.."  •  tamanho "..math.floor(sizeScale*100).."%"
end
for i,d in ipairs({{"−",-.1},{"+",.1}}) do
 local bt=Instance.new("TextButton");bt.Position=UDim2.new(.56+(i-1)*.14,0,0,0);bt.Size=UDim2.new(.13,-3,1,0);bt.BackgroundColor3=Color3.fromRGB(28,31,38);bt.Text=d[1];bt.TextColor3=Color3.new(1,1,1);bt.Font=Enum.Font.GothamBold;bt.TextSize=18;bt.BorderSizePixel=0;bt.ZIndex=102;bt.Parent=controls;local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=bt
 bt.Activated:Connect(function() if selectedElement=="diagnostic" then diagScale=math.clamp(diagScale+d[2],.7,1.4);local dg=player.PlayerGui:FindFirstChild("BuildDiagnostic");local db=dg and dg:FindFirstChild("OpenDiagnostic");if db then db.Size=UDim2.fromOffset(118*diagScale,34*diagScale);diagProxy.Size=db.Size end;editInfo.Text="X "..diagX.."  Y "..diagY.."  •  tamanho "..math.floor(diagScale*100).."%";return elseif selectedElement=="build" then buildScale=math.clamp(buildScale+d[2],.7,1.4);syncEditProxies();editInfo.Text="X "..buildX.."  Y "..buildY.."  •  tamanho "..math.floor(buildScale*100).."%";return elseif selectedElement=="jump" then jumpScale=math.clamp(jumpScale+d[2],.7,1.4);applyJump();editInfo.Text="X "..jumpX.."  Y "..jumpY.."  •  tamanho "..math.floor(jumpScale*100).."%";return elseif selectedElement=="settings" then settingsScale=math.clamp(settingsScale+d[2],.7,1.4);settingsButton.Size=UDim2.fromOffset(38*settingsScale,38*settingsScale);editInfo.Text="X "..settingsX.."  Y "..settingsY.."  •  tamanho "..math.floor(settingsScale*100).."%";return elseif selectedElement~="gold" then return end;sizeScale=math.clamp(sizeScale+d[2],.7,1.4);applyScale()end)
end
local done=Instance.new("TextButton");done.AnchorPoint=Vector2.new(1,0);done.Position=UDim2.new(1,0,0,0);done.Size=UDim2.new(.16,-2,1,0);done.BackgroundColor3=Color3.fromRGB(255,199,47);done.Text="OK";done.TextColor3=Color3.fromRGB(18,18,18);done.Font=Enum.Font.GothamBold;done.TextSize=11;done.BorderSizePixel=0;done.ZIndex=102;done.Parent=controls;local dc=Instance.new("UICorner");dc.CornerRadius=UDim.new(0,8);dc.Parent=done

local function refreshSettings()
 for i,bt in ipairs(profileButtons) do local on=(activePreset==("hud"..i));bt.BackgroundColor3=on and Color3.fromRGB(255,195,43) or Color3.fromRGB(28,31,38);bt.TextColor3=on and Color3.fromRGB(18,18,18) or Color3.new(1,1,1) end
end
for i,bt in ipairs(profileButtons) do bt.Activated:Connect(function()
 localPresets[activePreset]={x=hudX,y=hudY,scale=sizeScale};local wanted="hud"..i;local pok,yes,newslot,nx,ny,ns,nsx,nsy,nss,njx,njy,njs=pcall(function()return hudRemote:InvokeServer("load",wanted)end)
 if pok and yes then activePreset=newslot;hudX=nx;hudY=ny;sizeScale=math.clamp(tonumber(ns) or 1,.7,1.4);settingsX=nsx or -87;settingsY=nsy or 0;settingsScale=math.clamp(tonumber(nss) or 1,.7,1.4);settingsButton.Position=UDim2.new(1,settingsX,0,settingsY);settingsButton.Size=UDim2.fromOffset(38*settingsScale,38*settingsScale);jumpX=njx or -28;jumpY=njy or -110;jumpScale=math.clamp(tonumber(njs) or 1,.7,1.4);applyJump();localPresets[activePreset]={x=hudX,y=hudY,scale=sizeScale};applyPosition();applyScale();refreshSettings()end
end) end
modify.Activated:Connect(function()
 panel.Visible=false;editor.Visible=true;selectedElement=nil;clearSelection()
 syncEditProxies();diagProxy.Visible=true;buildProxy.Visible=true;editTitle.Text="TOQUE EM UM ELEMENTO";editInfo.Text="Selecione um HUD na tela para editar"
end)
task.spawn(function()
 local jg=player.PlayerGui:WaitForChild("CustomJumpHUD",10);local jb=jg and jg:FindFirstChild("CustomJumpButton")
 if jb then
  jumpSelection=Instance.new("UIStroke");jumpSelection.Name="EditSelection";jumpSelection.Color=Color3.fromRGB(70,255,120);jumpSelection.Thickness=3;jumpSelection.Transparency=1;jumpSelection.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;jumpSelection.Parent=jb
  jb.Activated:Connect(function()if editor.Visible then clearSelection();selectedElement="jump";jumpSelection.Transparency=0;editTitle.Text="EDITANDO: PULO";editInfo.Text="X "..jumpX.."  Y "..jumpY.."  •  tamanho "..math.floor(jumpScale*100).."%" end end)
 end
end)
-- The edited HUD itself can also be tapped while edit mode is active.
frame.Active=true
frame.InputBegan:Connect(function(input)
 if editor.Visible and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1) then selectedElement="gold";clearSelection();selectionStroke.Transparency=0;editTitle.Text="EDITANDO: OURO";editInfo.Text="X "..hudX.."  Y "..hudY.."  •  tamanho "..math.floor(sizeScale*100).."%" end
end)
diagProxy.Activated:Connect(function() if editor.Visible then selectedElement="diagnostic";editTitle.Text="EDITANDO: DIAGNÓSTICO";editInfo.Text="X "..diagX.."  Y "..diagY.."  •  tamanho "..math.floor(diagScale*100).."%" end end)
buildProxy.Activated:Connect(function() if editor.Visible then selectedElement="build";editTitle.Text="EDITANDO: BUILD";editInfo.Text="X "..buildX.."  Y "..buildY.."  •  tamanho "..math.floor(buildScale*100).."%" end end)
done.Activated:Connect(function()
 if selectedElement=="jump" or selectedElement=="settings" then local pok,yes,newslot,nx,ny,ns,nsx,nsy,nss=pcall(function()return hudRemote:InvokeServer("save",activePreset,hudX,hudY,sizeScale,settingsX,settingsY,settingsScale,jumpX,jumpY,jumpScale)end);if pok and yes then activePreset=newslot or activePreset;settingsX=nsx or settingsX;settingsY=nsy or settingsY;settingsScale=math.clamp(tonumber(nss) or settingsScale,.7,1.4) end;editor.Visible=false;diagProxy.Visible=false;buildProxy.Visible=false;panel.Visible=true;selectedElement=nil;clearSelection();refreshSettings();return elseif selectedElement=="diagnostic" or selectedElement=="build" then editor.Visible=false;diagProxy.Visible=false;buildProxy.Visible=false;panel.Visible=true;selectedElement=nil;clearSelection();refreshSettings();return elseif selectedElement~="gold" then editor.Visible=false;frame.ZIndex=1;settingsButton.ZIndex=1;panel.Visible=true;clearSelection();refreshSettings();return end
 local pok,yes,newslot,nx,ny,ns=pcall(function()return hudRemote:InvokeServer("save",activePreset,hudX,hudY,sizeScale,settingsX,settingsY,settingsScale,jumpX,jumpY,jumpScale)end)
 if pok and yes then activePreset=newslot;hudX=nx;hudY=ny;sizeScale=math.clamp(tonumber(ns) or sizeScale,.7,1.4);applyPosition();applyScale()end
 editor.Visible=false;diagProxy.Visible=false;buildProxy.Visible=false;frame.ZIndex=1;settingsButton.ZIndex=1;panel.Visible=true;selectedElement=nil;clearSelection();refreshSettings()
end)
-- legacy save removed
local save={Activated={Connect=function()end}}
reset.Activated:Connect(function()
 hudX,hudY,sizeScale=0,-4,1
 settingsX,settingsY,settingsScale=-87,0,1
 jumpX,jumpY,jumpScale=-28,-110,1
 applyJump()
 settingsButton.Position=UDim2.new(1,settingsX,0,settingsY);settingsButton.Size=UDim2.fromOffset(38,38)
 localPresets[activePreset]={x=0,y=-4,scale=1}
 applyPosition();applyScale()
 reset.Text="REDEFINIDO"
 task.delay(.7,function() if reset and reset.Parent then reset.Text="REDEFINIR HUD" end end)
 task.spawn(function()
  local pok,yes,newslot,nx,ny,ns,nsx,nsy,nss,njx,njy,njs=pcall(function()return hudRemote:InvokeServer("reset",activePreset)end)
  if pok and yes then activePreset=newslot or activePreset;hudX=nx or hudX;hudY=ny or hudY;sizeScale=math.clamp(tonumber(ns) or sizeScale,.7,1.4);settingsX=nsx or settingsX;settingsY=nsy or settingsY;settingsScale=math.clamp(tonumber(nss) or settingsScale,.7,1.4);settingsButton.Position=UDim2.new(1,settingsX,0,settingsY);settingsButton.Size=UDim2.fromOffset(38*settingsScale,38*settingsScale);jumpX=njx or jumpX;jumpY=njy or jumpY;jumpScale=math.clamp(tonumber(njs) or jumpScale,.7,1.4);applyJump();applyPosition();applyScale();refreshSettings() end
 end)
end)
settingsButton.Activated:Connect(function()
 if editor.Visible then selectedElement="settings";clearSelection();settingsSelection.Transparency=0;editTitle.Text="EDITANDO: CONFIGURAÇÕES";editInfo.Text="X "..settingsX.."  Y "..settingsY.."  •  tamanho "..math.floor(settingsScale*100).."%";return end
 editor.Visible=false;selectedElement=nil;clearSelection();panel.Visible=not panel.Visible;refreshSettings()
end)
close.Activated:Connect(function()panel.Visible=false end)

local function formatNumber(n)
	local s = tostring(math.floor(n))
	while true do
		local formatted, count = s:gsub("^(-?%d+)(%d%d%d)", "%1.%2")
		s = formatted
		if count == 0 then break end
	end
	return s
end

local gold = player:WaitForChild("leaderstats"):WaitForChild("Ouro")

local function update()
	local value = formatNumber(gold.Value)
	amount.Text = value
	local width = TextService:GetTextSize(value, amount.TextSize, amount.Font, Vector2.new(1000, 38)).X
	local baseWidth = math.max(86, math.ceil(width) + 52)
	frame:SetAttribute("BaseWidth", baseWidth)
	local scale = frame:GetAttribute("HUDScale") or 1
	frame.Size = UDim2.fromOffset(baseWidth * scale, 38 * scale)
end

update()
gold:GetPropertyChangedSignal("Value"):Connect(update)
