local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui");gui.Name="ItemHotbar";gui.ResetOnSpawn=false;gui.DisplayOrder=50;gui.Parent=player:WaitForChild("PlayerGui")
local root=Instance.new("Frame");root.Name="Root";root.AnchorPoint=Vector2.new(.5,1);root.Position=UDim2.new(.5,0,1,-12);root.BackgroundColor3=Color3.fromRGB(12,17,14);root.BackgroundTransparency=.08;root.BorderSizePixel=0;root.ClipsDescendants=true;root.Parent=gui
Instance.new("UICorner",root).CornerRadius=UDim.new(0,8)
local rs=Instance.new("UIStroke",root);rs.Color=Color3.fromRGB(67,82,72);rs.Thickness=1
local layout=Instance.new("UIListLayout",root);layout.FillDirection=Enum.FillDirection.Horizontal;layout.HorizontalAlignment=Enum.HorizontalAlignment.Center;layout.VerticalAlignment=Enum.VerticalAlignment.Center;layout.SortOrder=Enum.SortOrder.LayoutOrder
local slots={};local MAX=8;local mode="normal";local selected=0

local function line(parent,pos,size)
	local f=Instance.new("Frame");f.Position=pos;f.Size=size;f.BackgroundColor3=Color3.fromRGB(220,230,223);f.BorderSizePixel=0;f.Parent=parent;return f
end
local function drawIcon(holder,kind)
	holder:ClearAllChildren()
	if kind=="bag" then
		local body=line(holder,UDim2.fromScale(.25,.34),UDim2.fromScale(.5,.48));Instance.new("UICorner",body).CornerRadius=UDim.new(0,4)
		line(holder,UDim2.fromScale(.36,.20),UDim2.fromScale(.28,.18))
	elseif kind=="build" then
		local a=line(holder,UDim2.fromScale(.43,.16),UDim2.fromScale(.14,.68));a.Rotation=40
		local h=line(holder,UDim2.fromScale(.23,.18),UDim2.fromScale(.48,.14));h.Rotation=40
	elseif kind=="foundation" or kind=="roof" then
		local p=line(holder,UDim2.fromScale(.18,.34),UDim2.fromScale(.64,.34));p.Rotation=kind=="roof" and -8 or 0
	elseif kind=="wall" then
		line(holder,UDim2.fromScale(.2,.2),UDim2.fromScale(.6,.6))
		for i=1,2 do local d=line(holder,UDim2.fromScale(.2,.2+i*.18),UDim2.fromScale(.6,.025));d.BackgroundColor3=Color3.fromRGB(80,95,85) end
	elseif kind=="door" then
		local p=line(holder,UDim2.fromScale(.27,.14),UDim2.fromScale(.46,.7));local cut=line(holder,UDim2.fromScale(.39,.31),UDim2.fromScale(.22,.53));cut.BackgroundColor3=Color3.fromRGB(16,22,18)
	elseif kind=="rotate" then
		local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text="↻";t.TextColor3=Color3.fromRGB(220,230,223);t.TextScaled=true;t.Font=Enum.Font.GothamBold;t.Parent=holder
	elseif kind=="exit" then
		local a=line(holder,UDim2.fromScale(.46,.18),UDim2.fromScale(.08,.64));a.Rotation=45;local b=line(holder,UDim2.fromScale(.46,.18),UDim2.fromScale(.08,.64));b.Rotation=-45
	end
end
local function makeSlot(i)
	local b=Instance.new("TextButton");b.Name="Slot"..i;b.LayoutOrder=i;b.AutoButtonColor=false;b.Text="";b.BackgroundColor3=Color3.fromRGB(16,22,18);b.BackgroundTransparency=.1;b.BorderSizePixel=0;b.Parent=root
	if i>1 then local d=line(b,UDim2.new(0,0,.14,0),UDim2.new(0,1,.72,0));d.BackgroundColor3=Color3.fromRGB(64,78,69);d.BackgroundTransparency=.28 end
	local border=Instance.new("Frame");border.Name="SelectedBorder";border.Size=UDim2.fromScale(1,1);border.BackgroundTransparency=1;border.Visible=false;border.ZIndex=5;border.Parent=b
	local st=Instance.new("UIStroke",border);st.Color=Color3.fromRGB(95,255,140);st.Thickness=2
	local icon=Instance.new("Frame");icon.Name="Icon";icon.AnchorPoint=Vector2.new(.5,.5);icon.Position=UDim2.fromScale(.5,.5);icon.Size=UDim2.fromScale(.68,.68);icon.BackgroundTransparency=1;icon.Parent=b
	slots[i]=b
end
for i=1,MAX do makeSlot(i) end

local normalIcons={[7]="bag",[8]="build"}
local buildIcons={[1]="foundation",[2]="wall",[3]="door",[4]="roof",[6]="rotate",[8]="exit"}
local pieceBySlot={[1]="Foundation",[2]="Wall",[3]="Door",[4]="Roof"}

local function render()
	for i,b in ipairs(slots) do
		local kind=(mode=="build" and buildIcons or normalIcons)[i]
		b.Visible=kind~=nil
		if kind then drawIcon(b.Icon,kind) end
		b.SelectedBorder.Visible=(i==selected)
	end
	gui:SetAttribute("Mode",mode);gui:SetAttribute("SelectedSlot",selected)
end
local function activate(i)
	if mode=="normal" then
		if i==8 then mode="build";selected=0;render();gui:SetAttribute("BuildPiece","")
		elseif i==7 then gui:SetAttribute("BackpackRequested",os.clock()) end
	else
		if pieceBySlot[i] then selected=i;gui:SetAttribute("BuildPiece",pieceBySlot[i])
		elseif i==6 then gui:SetAttribute("RotateRequested",os.clock())
		elseif i==8 then mode="normal";selected=0;gui:SetAttribute("BuildPiece","");render() end
	end
	render()
end
for i,b in ipairs(slots) do b.Activated:Connect(function() activate(i) end) end
UserInputService.InputBegan:Connect(function(input,processed) if processed then return end local n=tonumber(input.KeyCode.Name);if n and n>=1 and n<=MAX then activate(n) end end)

local cameraConnection
local function resize()
	local c=workspace.CurrentCamera;if not c then return end
	local slotSize=math.clamp(math.floor(math.max(240,c.ViewportSize.X-24)/MAX),32,48)
	root.Size=UDim2.fromOffset(slotSize*MAX,slotSize)
	for _,b in ipairs(slots) do b.Size=UDim2.fromOffset(slotSize,slotSize) end
end
local function watch() if cameraConnection then cameraConnection:Disconnect() end local c=workspace.CurrentCamera;if c then cameraConnection=c:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end resize() end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watch);watch();render()
