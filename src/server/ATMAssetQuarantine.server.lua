local InsertService = game:GetService("InsertService")

-- Halloween inventory V78: flatten visual models into a numbered grid
local oldHalloween=workspace:FindFirstChild("Halloween_113280926555931");if oldHalloween then oldHalloween:Destroy() end
local oldBase=workspace:FindFirstChild("Baseplate");if oldBase then oldBase:Destroy() end
local oldFloor=workspace:FindFirstChild("HalloweenLobbyFloor");if oldFloor then oldFloor:Destroy() end
local floor=Instance.new("Part");floor.Name="HalloweenLobbyFloor";floor.Anchored=true;floor.Size=Vector3.new(8000,4,300);floor.Position=Vector3.new(0,-2,0);floor.CanCollide=true;floor.CanTouch=true;floor.Transparency=0;floor.Material=Enum.Material.Slate;floor.Color=Color3.fromRGB(32,27,38);floor.Parent=workspace

local okHalloween,pack=pcall(function() return InsertService:LoadAsset(113280926555931) end)
if okHalloween and pack then
 pack.Name="Halloween_113280926555931";pack.Parent=workspace
 local items={}
 for _,m in ipairs(pack:GetDescendants()) do
  if m:IsA("Model") then
   local childModel=false
   local partCount=0
   for _,d in ipairs(m:GetDescendants()) do
    if d:IsA("Model") and d~=m then childModel=true end
    if d:IsA("BasePart") then partCount+=1 end
   end
   if partCount>0 and not childModel then table.insert(items,m) end
  end
 end
 for _,m in ipairs(items) do m.Parent=pack end
 for _,o in ipairs(pack:GetChildren()) do
  if o:IsA("Model") and not table.find(items,o) then o:Destroy() end
 end
 local gap=24
 for i,m in ipairs(items) do
  local x=(i-1)*gap;local z=0
  local boxCf,boxSize=m:GetBoundingBox();local bottom=boxCf.Position.Y-boxSize.Y/2;m:PivotTo(m:GetPivot()+Vector3.new(x-m:GetPivot().Position.X,0.05-bottom,z-m:GetPivot().Position.Z))
  m.Name=string.format("ITEM_%03d",i)
  local adornee=m:FindFirstChildWhichIsA("BasePart",true)
  if adornee then
   local tag=Instance.new("BillboardGui");tag.Name="ItemNumber";tag.Size=UDim2.fromOffset(78,24);tag.StudsOffset=Vector3.new(0,6,0);tag.AlwaysOnTop=true;tag.MaxDistance=9;tag.Adornee=adornee;tag.Parent=m
   local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundColor3=Color3.fromRGB(10,10,12);t.BackgroundTransparency=0;t.TextColor3=Color3.new(1,1,1);t.Font=Enum.Font.GothamBold;t.TextSize=11;t.Text=string.format("ITEM %03d",i);t.Parent=tag
  end
 end
 pack:SetAttribute("ItemCount",#items)
 print("[Halloween V78] Individual items:",#items)
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ASSET_ID = 119678628566456
local MODEL_NAME = "QuarantinedATM_" .. ASSET_ID
local POSITION = Vector3.new(0, 4.5, -18)

local openEvent = ReplicatedStorage:FindFirstChild("ATMOpen") or Instance.new("RemoteEvent")
openEvent.Name = "ATMOpen"
openEvent.Parent = ReplicatedStorage

local old = workspace:FindFirstChild(MODEL_NAME)
if old then old:Destroy() end

local ok, container = pcall(function()
	return InsertService:LoadAsset(ASSET_ID)
end)

if not ok then
	warn("[ATM Quarantine] LoadAsset failed: " .. tostring(container))
	return
end

-- Keep community code disabled. We inspect the interaction objects and rebuild
-- the ATM functionality ourselves instead of executing untrusted scripts.
local scriptCount = 0
local interactionCount = 0
local findings = {}

for _, obj in ipairs(container:GetDescendants()) do
	if obj:IsA("Script") or obj:IsA("LocalScript") then
		obj.Disabled = true
		scriptCount += 1
		table.insert(findings, "CODE(disabled) " .. obj.ClassName .. " :: " .. obj:GetFullName())
	elseif obj:IsA("ModuleScript") then
		scriptCount += 1
		table.insert(findings, "CODE(module-not-executed) :: " .. obj:GetFullName())
	elseif obj:IsA("ClickDetector") or obj:IsA("ProximityPrompt") then
		interactionCount += 1
		table.insert(findings, "INTERACTION " .. obj.ClassName .. " :: " .. obj:GetFullName())
	end
end

local children = container:GetChildren()
if #children == 0 then
	warn("[ATM Quarantine] Asset returned no usable objects.")
	container:Destroy()
	return
end

local root
if #children == 1 then
	root = children[1]
	root.Parent = workspace
	container:Destroy()
else
	root = Instance.new("Model")
	root.Parent = workspace
	for _, child in ipairs(children) do
		child.Parent = root
	end
	container:Destroy()
end

root.Name = MODEL_NAME
root:SetAttribute("SourceAssetId", ASSET_ID)
root:SetAttribute("Quarantined", true)
root:SetAttribute("DisabledScriptCount", scriptCount)
root:SetAttribute("InteractionCount", interactionCount)

-- Disable scripts again after reparenting as a defense-in-depth check.
for _, obj in ipairs(root:GetDescendants()) do
	if obj:IsA("Script") or obj:IsA("LocalScript") then
		obj.Disabled = true
	end
end

-- V7: this asset's root is a container, not a Model/BasePart.
-- Move every physical part together using their real world-space bounds.
local parts = {}
if root:IsA("BasePart") then table.insert(parts, root) end
for _, obj in ipairs(root:GetDescendants()) do
	if obj:IsA("BasePart") then table.insert(parts, obj) end
end

if #parts > 0 then
	local minX, minY, minZ = math.huge, math.huge, math.huge
	local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
	for _, part in ipairs(parts) do
		local half = part.Size * 0.5
		local p = part.Position
		minX = math.min(minX, p.X - half.X)
		minY = math.min(minY, p.Y - half.Y)
		minZ = math.min(minZ, p.Z - half.Z)
		maxX = math.max(maxX, p.X + half.X)
		maxY = math.max(maxY, p.Y + half.Y)
		maxZ = math.max(maxZ, p.Z + half.Z)
	end
	local center = Vector3.new((minX+maxX)/2, (minY+maxY)/2, (minZ+maxZ)/2)
	local targetBottomY = 0.65
	local delta = Vector3.new(POSITION.X-center.X, targetBottomY-minY, POSITION.Z-center.Z)
	for _, part in ipairs(parts) do
		part.CFrame = part.CFrame + delta
	end
	root:SetAttribute("VisualBottomY", targetBottomY)
	root:SetAttribute("MovedPartCount", #parts)
end

print(("[ATM Quarantine] Asset %d loaded; %d script(s) disabled; %d interaction object(s) found."):format(
	ASSET_ID, scriptCount, interactionCount
))
local interactionPart = Instance.new("Part")
interactionPart.Name = "SafeATMInteraction"
interactionPart.Size = Vector3.new(6, 6, 4)
interactionPart.Transparency = 1
interactionPart.CanCollide = false
interactionPart.CanTouch = false
interactionPart.CanQuery = false
interactionPart.Anchored = true
interactionPart.CFrame = CFrame.new(POSITION.X, 3.5, POSITION.Z + 3)
interactionPart.Parent = root

for _, obj in ipairs(root:GetDescendants()) do
	if obj:IsA("ProximityPrompt") then obj.Enabled = false end
end

local prompt = Instance.new("ProximityPrompt")
prompt.Name = "SafeATMPrompt"
prompt.ActionText = "Acessar"
prompt.ObjectText = "Caixa Eletronico"
prompt.HoldDuration = 0
prompt.MaxActivationDistance = 12
prompt.RequiresLineOfSight = false
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.Parent = interactionPart
prompt.Triggered:Connect(function(player)
	local count = (root:GetAttribute("PromptTriggerCount") or 0) + 1
	root:SetAttribute("PromptTriggerCount", count)
	root:SetAttribute("LastPromptUserId", player.UserId)
	root:SetAttribute("LastPromptServerTime", math.floor(workspace:GetServerTimeNow() * 100) / 100)
	openEvent:FireClient(player)
	root:SetAttribute("ATMOpenFireCount", (root:GetAttribute("ATMOpenFireCount") or 0) + 1)
end)

root:SetAttribute("SafePromptReady", true)
root:SetAttribute("PromptTriggerCount", 0)
root:SetAttribute("ATMOpenFireCount", 0)
root:SetAttribute("LastPromptUserId", 0)
root:SetAttribute("ServerBuild", "V83")

local tag = Instance.new("BillboardGui")
tag.Name = "ServerBuildTag"
tag.Size = UDim2.fromOffset(150, 34)
tag.StudsOffset = Vector3.new(0, 5, 0)
tag.AlwaysOnTop = true
tag.Parent = interactionPart
local txt = Instance.new("TextLabel")
txt.Size = UDim2.fromScale(1,1)
txt.BackgroundColor3 = Color3.fromRGB(15,15,18)
txt.BackgroundTransparency = 0.15
txt.TextColor3 = Color3.new(1,1,1)
txt.Text = "BUILD V83"
txt.Font = Enum.Font.GothamBold
txt.TextSize = 16
txt.Parent = tag
