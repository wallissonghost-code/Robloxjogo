local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")

local player=Players.LocalPlayer
if player.UserId~=9538436641 then return end
local request=ReplicatedStorage:WaitForChild("LobbyBuilderRemotes"):WaitForChild("Request")
local catalogFolder=ReplicatedStorage:WaitForChild("HalloweenCatalog")

local selected,preview,previewBase
local rotation=0
local catalogLoaded=false
local distance=4
local height=0
local joinLast=false
local lastTop

local function getParts(obj)
	local parts={}
	if obj:IsA("BasePart") then table.insert(parts,obj) end
	for _,d in ipairs(obj:GetDescendants()) do if d:IsA("BasePart") then table.insert(parts,d) end end
	return parts
end

local function worldBounds(obj)
	local parts=getParts(obj)
	if #parts==0 then return Vector3.zero,Vector3.zero end
	local minV=Vector3.new(math.huge,math.huge,math.huge)
	local maxV=Vector3.new(-math.huge,-math.huge,-math.huge)
	for _,p in ipairs(parts) do
		local cf=p.CFrame; local h=p.Size*.5
		local ax=cf.RightVector; local ay=cf.UpVector; local az=cf.LookVector
		local e=Vector3.new(
			math.abs(ax.X)*h.X+math.abs(ay.X)*h.Y+math.abs(az.X)*h.Z,
			math.abs(ax.Y)*h.X+math.abs(ay.Y)*h.Y+math.abs(az.Y)*h.Z,
			math.abs(ax.Z)*h.X+math.abs(ay.Z)*h.Y+math.abs(az.Z)*h.Z
		)
		minV=Vector3.new(math.min(minV.X,p.Position.X-e.X),math.min(minV.Y,p.Position.Y-e.Y),math.min(minV.Z,p.Position.Z-e.Z))
		maxV=Vector3.new(math.max(maxV.X,p.Position.X+e.X),math.max(maxV.Y,p.Position.Y+e.Y),math.max(maxV.Z,p.Position.Z+e.Z))
	end
	return minV,maxV
end

local function translate(obj,delta)
	for _,p in ipairs(getParts(obj)) do p.CFrame=p.CFrame+delta end
end

local function placeVisual(obj,base)
	local minV,maxV=worldBounds(obj)
	local center=(minV+maxV)*.5
	translate(obj,Vector3.new(base.X-center.X,base.Y-minV.Y,base.Z-center.Z))
end

local function clearPreview()
	if preview then preview:Destroy(); preview=nil end
	previewBase=nil
end

local function ghost(obj)
	for _,p in ipairs(getParts(obj)) do
		p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Transparency=math.max(p.Transparency,.45)
	end
end

local gui=Instance.new("ScreenGui")
gui.Name="LobbyCreativeHUD"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=false; gui.Parent=player:WaitForChild("PlayerGui")

local exportPanel=Instance.new("Frame")
exportPanel.Size=UDim2.new(1,-24,0.48,0); exportPanel.Position=UDim2.new(0,12,0.26,0); exportPanel.Visible=false; exportPanel.ZIndex=20; exportPanel.Parent=gui
local exportTitle=Instance.new("TextLabel")
exportTitle.Size=UDim2.new(1,-48,0,32); exportTitle.Position=UDim2.fromOffset(8,4); exportTitle.BackgroundTransparency=1; exportTitle.Text="DIAGNOSTICO / EXPORT"; exportTitle.TextXAlignment=Enum.TextXAlignment.Left; exportTitle.TextScaled=true; exportTitle.ZIndex=21; exportTitle.Parent=exportPanel
local exportClose=Instance.new("TextButton")
exportClose.Size=UDim2.fromOffset(36,30); exportClose.Position=UDim2.new(1,-40,0,4); exportClose.Text="X"; exportClose.TextScaled=true; exportClose.ZIndex=21; exportClose.Parent=exportPanel
local exportBox=Instance.new("TextBox")
exportBox.Size=UDim2.new(1,-16,1,-82); exportBox.Position=UDim2.fromOffset(8,40); exportBox.ClearTextOnFocus=false; exportBox.MultiLine=true; exportBox.TextEditable=true; exportBox.TextWrapped=true; exportBox.TextXAlignment=Enum.TextXAlignment.Left; exportBox.TextYAlignment=Enum.TextYAlignment.Top; exportBox.TextSize=14; exportBox.Text=""; exportBox.ZIndex=21; exportBox.Parent=exportPanel
local exportNav=Instance.new("Frame")
exportNav.Size=UDim2.new(1,-16,0,30); exportNav.Position=UDim2.new(0,8,1,-36); exportNav.ZIndex=21; exportNav.Parent=exportPanel
local exportPrev=Instance.new("TextButton"); exportPrev.Size=UDim2.new(.25,-2,1,0); exportPrev.Text="<"; exportPrev.TextScaled=true; exportPrev.ZIndex=22; exportPrev.Parent=exportNav
local exportPage=Instance.new("TextLabel"); exportPage.Size=UDim2.new(.5,-4,1,0); exportPage.Position=UDim2.new(.25,2,0,0); exportPage.Text="1/1"; exportPage.TextScaled=true; exportPage.ZIndex=22; exportPage.Parent=exportNav
local exportNext=Instance.new("TextButton"); exportNext.Size=UDim2.new(.25,-2,1,0); exportNext.Position=UDim2.new(.75,2,0,0); exportNext.Text=">"; exportNext.TextScaled=true; exportNext.ZIndex=22; exportNext.Parent=exportNav
local exportPages={}
local exportIndex=1
local function showExportPage()
	exportBox.Text=exportPages[exportIndex] or ""
	exportPage.Text=tostring(exportIndex).."/"..tostring(math.max(1,#exportPages))
	exportBox.CursorPosition=1
end
local function paginateExport(text)
	exportPages={}
	local header={}
	local blocks={}
	local current=nil
	for line in (text.."\n"):gmatch("(.-)\n") do
		if line:match("^%d%d%d|") then
			local id,name,ax,ay,az,rot,rx,ry,rz=line:match("^(%d+)|([^|]+)|ABS|([^|]+)|([^|]+)|([^|]+)|ROT|([^|]+)|REL|([^|]+)|([^|]+)|([^|]+)$")
			if id then
				table.insert(blocks,table.concat({
					id.." | "..name,
					"ABS  X="..ax.."  Y="..ay.."  Z="..az,
					"ROT  Y="..rot,
					"REL  X="..rx.."  Y="..ry.."  Z="..rz
				},"\n"))
			else
				table.insert(blocks,line)
			end
		else
			table.insert(header,line)
		end
	end
	local prefix=table.concat(header,"\n")
	local page=prefix
	for _,block in ipairs(blocks) do
		local candidate=(page=="" and block) or (page.."\n\n"..block)
		if #page>0 and #candidate>650 then
			table.insert(exportPages,page)
			page=prefix.."\n\n"..block
		else
			page=candidate
		end
	end
	if page~="" then table.insert(exportPages,page) end
	if #exportPages==0 then exportPages={text} end
	exportIndex=1; showExportPage()
end
exportPrev.Activated:Connect(function() if exportIndex>1 then exportIndex-=1; showExportPage() end end)
exportNext.Activated:Connect(function() if exportIndex<#exportPages then exportIndex+=1; showExportPage() end end)
exportClose.Activated:Connect(function() exportPanel.Visible=false end)

local toggle=Instance.new("TextButton")
toggle.Size=UDim2.fromOffset(48,48); toggle.Position=UDim2.new(1,-60,0,8); toggle.Text="BUILD"; toggle.TextScaled=true; toggle.Parent=gui

local dock=Instance.new("Frame")
dock.Size=UDim2.fromOffset(300,154); dock.Position=UDim2.new(1,-312,0,62); dock.Visible=false; dock.Parent=gui

local header=Instance.new("Frame"); header.Size=UDim2.new(1,-8,0,30); header.Position=UDim2.fromOffset(4,4); header.Parent=dock
local title=Instance.new("TextLabel"); title.Size=UDim2.new(1,-68,1,0); title.BackgroundTransparency=1; title.Text="BUILDER"; title.TextXAlignment=Enum.TextXAlignment.Left; title.TextScaled=true; title.Parent=header
local collapse=Instance.new("TextButton"); collapse.Size=UDim2.fromOffset(30,26); collapse.Position=UDim2.new(1,-62,0,2); collapse.Text="_"; collapse.TextScaled=true; collapse.Parent=header
local close=Instance.new("TextButton"); close.Size=UDim2.fromOffset(28,26); close.Position=UDim2.new(1,-30,0,2); close.Text="X"; close.TextScaled=true; close.Parent=header

local catalog=Instance.new("ScrollingFrame")
catalog.Size=UDim2.new(1,-8,0,44); catalog.Position=UDim2.fromOffset(4,38); catalog.AutomaticCanvasSize=Enum.AutomaticSize.X; catalog.CanvasSize=UDim2.new()
catalog.ScrollingDirection=Enum.ScrollingDirection.X; catalog.ScrollBarThickness=2; catalog.Parent=dock
local list=Instance.new("UIListLayout"); list.FillDirection=Enum.FillDirection.Horizontal; list.Padding=UDim.new(0,3); list.Parent=catalog

local bar=Instance.new("Frame"); bar.Size=UDim2.new(1,-8,0,30); bar.Position=UDim2.fromOffset(4,86); bar.Parent=dock
local status=Instance.new("TextLabel"); status.Size=UDim2.new(.25,-2,1,0); status.BackgroundTransparency=1; status.Text="Selecione"; status.TextScaled=true; status.Parent=bar

local function btn(parent,text,x,w,fn)
	local b=Instance.new("TextButton"); b.Size=UDim2.new(w,-2,1,0); b.Position=UDim2.new(x,0,0,0); b.Text=text; b.TextScaled=true; b.Parent=parent; b.Activated:Connect(fn); return b
end

local placeBtn=btn(bar,"OK",.25,.15,function()
	if not selected or not previewBase then return end
	local r=request:InvokeServer("place",{name=selected,basePosition=previewBase,rotation=rotation})
	if r and r.ok then lastTop=r.top; status.Text="OK" else status.Text=(r and r.error) or "Erro" end
end)
btn(bar,"↻",.40,.12,function() rotation=(rotation+45)%360; status.Text=rotation.."°" end)
btn(bar,"DEL",.52,.15,function()
	local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart"); if not root then return end
	local r=request:InvokeServer("deleteNearest",{position=root.Position}); status.Text=r.ok and "Apagado" or "Nada perto"
end)
btn(bar,"RST",.67,.13,function() distance=4; height=0; joinLast=false; status.Text="Reset" end)
btn(bar,"EXP",.80,.20,function()
	local r=request:InvokeServer("export")
	if not r or not r.ok then status.Text=(r and r.error) or "Erro export"; return end
	paginateExport(r.text)
	exportTitle.Text="EXPORT - "..tostring(r.count).." PECAS"
	exportPanel.Visible=true
	status.Text="Exportado"
end)

local adjust=Instance.new("Frame"); adjust.Size=UDim2.new(1,-8,0,30); adjust.Position=UDim2.fromOffset(4,120); adjust.Parent=dock
btn(adjust,"D-",0,.14,function() distance=math.max(.5,distance-.5) end)
btn(adjust,"D+",.14,.14,function() distance=math.min(20,distance+.5) end)
btn(adjust,"Y-",.28,.14,function() height=math.max(-20,height-.25) end)
btn(adjust,"Y+",.42,.14,function() height=math.min(30,height+.25) end)
local joinBtn
joinBtn=btn(adjust,"JOIN",.56,.22,function()
	joinLast=not joinLast
	if joinLast and lastTop then distance=0; height=0 end
	joinBtn.Text=joinLast and "JOIN ✓" or "JOIN"
end)
btn(adjust,"MIN",.78,.22,function() dock.Visible=false; toggle.Visible=true end)

local collapsed=false
collapse.Activated:Connect(function()
	collapsed=not collapsed
	catalog.Visible=not collapsed; bar.Visible=not collapsed; adjust.Visible=not collapsed
	dock.Size=collapsed and UDim2.fromOffset(300,38) or UDim2.fromOffset(300,154)
	collapse.Text=collapsed and "+" or "_"
end)
close.Activated:Connect(function() clearPreview(); dock.Visible=false; toggle.Visible=true end)

local function selectItem(name)
	selected=name; clearPreview(); height=0
	if not (joinLast and lastTop) then distance=4 end
	local template=catalogFolder:FindFirstChild(name)
	if not template then status.Text="Erro item"; return end
	preview=template:Clone(); preview.Name="CreativePreview"; ghost(preview); preview.Parent=workspace
	status.Text=name:gsub("^%d+_","")
end

local function loadCatalog()
	if catalogLoaded then return end
	status.Text="..."
	local r=request:InvokeServer("catalog")
	if not r or not r.ok then status.Text=(r and (r.status or r.error)) or "Erro"; return end
	for _,name in ipairs(r.items) do
		local b=Instance.new("TextButton"); b.Size=UDim2.fromOffset(68,40); b.Text=name:gsub("^%d+_",""); b.TextWrapped=true; b.TextScaled=true; b.Parent=catalog
		b.Activated:Connect(function() selectItem(name) end)
	end
	catalogLoaded=true; status.Text=#r.items.." itens"
end

toggle.Activated:Connect(function()
	toggle.Visible=false; dock.Visible=true; loadCatalog()
end)

local function update()
	if not dock.Visible or not preview then return end
	local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local look=root.CFrame.LookVector
	local flat=Vector3.new(look.X,0,look.Z)
	if flat.Magnitude<.01 then flat=Vector3.new(0,0,-1) else flat=flat.Unit end
	local base
	if joinLast and lastTop then
		base=lastTop+flat*distance+Vector3.new(0,height,0)
	else
		local origin=Vector3.new(root.Position.X,root.Position.Y-3,root.Position.Z)
		base=origin+flat*distance+Vector3.new(0,height,0)
	end
	previewBase=base
	placeVisual(preview,base)
end
RunService.RenderStepped:Connect(update)
