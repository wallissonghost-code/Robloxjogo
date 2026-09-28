local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui");gui.Name="ItemHotbar";gui.ResetOnSpawn=false;gui.DisplayOrder=50;gui.Parent=player:WaitForChild("PlayerGui")

local function styleRoot(name)
	local root=Instance.new("Frame");root.Name=name;root.AnchorPoint=Vector2.new(.5,1);root.Position=UDim2.new(.5,0,1,-12)
	root.BackgroundColor3=Color3.fromRGB(12,17,14);root.BackgroundTransparency=.08;root.BorderSizePixel=0;root.ClipsDescendants=true;root.Parent=gui
	Instance.new("UICorner",root).CornerRadius=UDim.new(0,8)
	local stroke=Instance.new("UIStroke",root);stroke.Color=Color3.fromRGB(67,82,72);stroke.Thickness=1
	local layout=Instance.new("UIListLayout",root);layout.FillDirection=Enum.FillDirection.Horizontal;layout.HorizontalAlignment=Enum.HorizontalAlignment.Center;layout.VerticalAlignment=Enum.VerticalAlignment.Center;layout.SortOrder=Enum.SortOrder.LayoutOrder
	return root
end
local normalRoot=styleRoot("NormalBar")
local buildRoot=styleRoot("BuildBar");buildRoot.Visible=false
local variantRoot=styleRoot("FoundationVariants");variantRoot.Position=UDim2.new(.5,0,1,-66);variantRoot.Visible=false

local function line(parent,pos,size,color)
	local f=Instance.new("Frame");f.Position=pos;f.Size=size;f.BackgroundColor3=color or Color3.fromRGB(220,230,223);f.BorderSizePixel=0;f.Parent=parent;return f
end
local function drawIcon(holder,kind)
	holder:ClearAllChildren()
	if kind=="bag" then
		local body=line(holder,UDim2.fromScale(.25,.34),UDim2.fromScale(.5,.48));Instance.new("UICorner",body).CornerRadius=UDim.new(0,4)
		line(holder,UDim2.fromScale(.36,.20),UDim2.fromScale(.28,.18))
	elseif kind=="foundation" or kind=="roof" then
		local p=line(holder,UDim2.fromScale(.18,.34),UDim2.fromScale(.64,.34));p.Rotation=kind=="roof" and -8 or 0
	elseif kind=="wall" then
		line(holder,UDim2.fromScale(.2,.2),UDim2.fromScale(.6,.6))
		for i=1,2 do line(holder,UDim2.fromScale(.2,.2+i*.18),UDim2.fromScale(.6,.025),Color3.fromRGB(80,95,85)) end
	elseif kind=="door" then
		line(holder,UDim2.fromScale(.27,.14),UDim2.fromScale(.46,.7))
		line(holder,UDim2.fromScale(.39,.31),UDim2.fromScale(.22,.53),Color3.fromRGB(16,22,18))
	elseif kind=="build" then
		local a=line(holder,UDim2.fromScale(.43,.16),UDim2.fromScale(.14,.68));a.Rotation=40
		local h=line(holder,UDim2.fromScale(.23,.18),UDim2.fromScale(.48,.14));h.Rotation=40
	end
end
local function makeSlot(parent,index,kind)
	local b=Instance.new("TextButton");b.Name="Slot"..index;b.LayoutOrder=index;b.AutoButtonColor=false;b.Text="";b.BackgroundColor3=Color3.fromRGB(16,22,18);b.BackgroundTransparency=.1;b.BorderSizePixel=0;b.Parent=parent
	if index>1 then local d=line(b,UDim2.new(0,0,.14,0),UDim2.new(0,1,.72,0),Color3.fromRGB(64,78,69));d.BackgroundTransparency=.28 end
	local border=Instance.new("Frame");border.Name="SelectedBorder";border.Size=UDim2.fromScale(1,1);border.BackgroundTransparency=1;border.Visible=false;border.ZIndex=5;border.Parent=b
	local st=Instance.new("UIStroke",border);st.Color=Color3.fromRGB(95,255,140);st.Thickness=2
	local icon=Instance.new("Frame");icon.Name="Icon";icon.AnchorPoint=Vector2.new(.5,.5);icon.Position=UDim2.fromScale(.5,.5);icon.Size=UDim2.fromScale(.68,.68);icon.BackgroundTransparency=1;icon.Parent=b
	if kind then drawIcon(icon,kind) end
	return b
end

local normalSlots={}
normalSlots[1]=makeSlot(normalRoot,1,"bag")
for i=2,8 do normalSlots[i]=makeSlot(normalRoot,i,nil) end

local foundationLevels={"Low","Medium","High"}
local variantSlots={}
for i,level in ipairs(foundationLevels) do
	local b=makeSlot(variantRoot,i,"foundation")
	local icon=b.Icon
	local scale=({Low=.45,Medium=.65,High=.85})[level]
	icon.Size=UDim2.fromScale(.68,scale)
	icon.Position=UDim2.fromScale(.5,1-scale/2-.08)
	variantSlots[i]=b
end

local buildKinds={"foundation","door","wall","roof"}
local buildPieces={"Foundation","Door","Wall","Roof"}
local buildSlots={}
for i,kind in ipairs(buildKinds) do buildSlots[i]=makeSlot(buildRoot,i,kind) end

local buildToggle=Instance.new("TextButton");buildToggle.Name="BuildToggle";buildToggle.AnchorPoint=Vector2.new(1,1);buildToggle.Position=UDim2.new(1,-16,1,-12);buildToggle.Size=UDim2.fromOffset(46,46);buildToggle.Text="";buildToggle.AutoButtonColor=false;buildToggle.BackgroundColor3=Color3.fromRGB(15,22,18);buildToggle.BorderSizePixel=0;buildToggle.Parent=gui
Instance.new("UICorner",buildToggle).CornerRadius=UDim.new(1,0)
local toggleStroke=Instance.new("UIStroke",buildToggle);toggleStroke.Color=Color3.fromRGB(67,82,72);toggleStroke.Thickness=1
local toggleIcon=Instance.new("Frame");toggleIcon.AnchorPoint=Vector2.new(.5,.5);toggleIcon.Position=UDim2.fromScale(.5,.5);toggleIcon.Size=UDim2.fromScale(.62,.62);toggleIcon.BackgroundTransparency=1;toggleIcon.Parent=buildToggle;drawIcon(toggleIcon,"build")

local mode="normal";local selectedBuild=0
local function setMode(nextMode)
	mode=nextMode
	normalRoot.Visible=mode=="normal"
	buildRoot.Visible=mode=="build"
	selectedBuild=0
	gui:SetAttribute("Mode",mode)
	gui:SetAttribute("BuildPiece","")
	gui:SetAttribute("FoundationLevel","Medium")
	variantRoot.Visible=false
	for _,b in ipairs(buildSlots) do b.SelectedBorder.Visible=false end
	toggleStroke.Color=mode=="build" and Color3.fromRGB(95,255,140) or Color3.fromRGB(67,82,72)
	toggleStroke.Thickness=mode=="build" and 2 or 1
end

normalSlots[1].Activated:Connect(function() gui:SetAttribute("BackpackRequested",os.clock()) end)
for i=2,8 do
	normalSlots[i].Activated:Connect(function()
		gui:SetAttribute("SelectedInventorySlot",i-1)
		for j=2,8 do normalSlots[j].SelectedBorder.Visible=(j==i) end
	end)
end
for i,b in ipairs(buildSlots) do
	b.Activated:Connect(function()
		selectedBuild=i
		for j,s in ipairs(buildSlots) do s.SelectedBorder.Visible=(j==i) end
		if buildPieces[i]=="Foundation" then
			variantRoot.Visible=true
			gui:SetAttribute("BuildPiece","")
		else
			variantRoot.Visible=false
			gui:SetAttribute("BuildPiece",buildPieces[i])
		end
	end)
end
for i,b in ipairs(variantSlots) do
	b.Activated:Connect(function()
		for j,s in ipairs(variantSlots) do s.SelectedBorder.Visible=(j==i) end
		gui:SetAttribute("FoundationLevel",foundationLevels[i])
		gui:SetAttribute("BuildPiece","Foundation")
	end)
end
buildToggle.Activated:Connect(function() setMode(mode=="normal" and "build" or "normal") end)

UserInputService.InputBegan:Connect(function(input,processed)
	if processed then return end
	local n=tonumber(input.KeyCode.Name)
	if mode=="normal" and n and n>=1 and n<=7 then
		gui:SetAttribute("SelectedInventorySlot",n)
		for j=2,8 do normalSlots[j].SelectedBorder.Visible=(j-1==n) end
	elseif mode=="build" and n and n>=1 and n<=4 then
		buildSlots[n]:Activate()
	end
end)

local cameraConnection
local function resize()
	local c=workspace.CurrentCamera;if not c then return end
	local available=math.max(240,c.ViewportSize.X-24)
	local normalSize=math.clamp(math.floor(available/8),32,48)
	local buildSize=math.clamp(math.floor(available/8),36,50)
	normalRoot.Size=UDim2.fromOffset(normalSize*8,normalSize)
	for _,b in ipairs(normalSlots) do b.Size=UDim2.fromOffset(normalSize,normalSize) end
	buildRoot.Size=UDim2.fromOffset(buildSize*4,buildSize)
	for _,b in ipairs(buildSlots) do b.Size=UDim2.fromOffset(buildSize,buildSize) end
	variantRoot.Size=UDim2.fromOffset(buildSize*3,buildSize)
	for _,b in ipairs(variantSlots) do b.Size=UDim2.fromOffset(buildSize,buildSize) end
	local toggleSize=math.clamp(normalSize,38,48);buildToggle.Size=UDim2.fromOffset(toggleSize,toggleSize)
end
local function watch()
	if cameraConnection then cameraConnection:Disconnect() end
	local c=workspace.CurrentCamera;if c then cameraConnection=c:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
	resize()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watch)
watch();setMode("normal")
