local InsertService = game:GetService("InsertService")

-- Halloween lobby V75: dissolve showcase stands and build themed zones
local oldHalloween=workspace:FindFirstChild("Halloween_113280926555931");if oldHalloween then oldHalloween:Destroy() end
local oldBase=workspace:FindFirstChild("Baseplate");if oldBase then oldBase:Destroy() end
local oldFloor=workspace:FindFirstChild("HalloweenLobbyFloor");if oldFloor then oldFloor:Destroy() end
local lobby=Instance.new("Part");lobby.Name="HalloweenLobbyFloor";lobby.Anchored=true;lobby.Size=Vector3.new(240,1,240);lobby.Position=Vector3.new(0,0,0);lobby.Material=Enum.Material.Slate;lobby.Color=Color3.fromRGB(30,24,38);lobby.Parent=workspace

local halloweenOk,halloween=pcall(function() return InsertService:LoadAsset(113280926555931) end)
if halloweenOk and halloween then
 halloween.Name="Halloween_113280926555931";halloween.Parent=workspace
 -- V76: remove catalog/showcase altar geometry before using props
 local altarWords={"lighting","ligitchuing","pumpkins","architecture","nature","graveyard"}
 local remove={}
 for _,o in ipairs(halloween:GetDescendants()) do
  local n=string.lower(o.Name)
  local named=false
  for _,w in ipairs(altarWords) do if string.find(n,w,1,true) and string.match(n,"%d+") then named=true break end end
  if named then
   for _,d in ipairs(o:GetDescendants()) do
    if d:IsA("BasePart") then
     local flat=d.Size.Y<=3 and (d.Size.X>=12 or d.Size.Z>=12)
     local neon=d.Material==Enum.Material.Neon
     if flat or neon then table.insert(remove,d) end
    elseif d:IsA("SurfaceGui") or d:IsA("BillboardGui") then table.insert(remove,d) end
   end
  end
 end
 for _,o in ipairs(remove) do if o.Parent then o:Destroy() end end
 local usable={}
 for _,o in ipairs(halloween:GetDescendants()) do
  if o:IsA("Model") then
   local n=string.lower(o.Name)
   local parts=0
   for _,d in ipairs(o:GetDescendants()) do if d:IsA("BasePart") then parts+=1 end end
   if parts>0 and parts<80 and not string.find(n,"nature") and not string.find(n,"graveyard") and not string.find(n,"lighting") then table.insert(usable,o) end
  end
 end
 table.sort(usable,function(x,y) return #x:GetDescendants()<#y:GetDescendants() end)
 local originals={}
 for i,o in ipairs(usable) do
  local nested=false
  for _,q in ipairs(originals) do if o:IsDescendantOf(q) then nested=true break end end
  if not nested then table.insert(originals,o) end
  if #originals>=60 then break end
 end
 for _,o in ipairs(originals) do o.Parent=halloween end
 for _,o in ipairs(halloween:GetChildren()) do if o:IsA("Model") and not table.find(originals,o) then o:Destroy() end end
 local function place(src,x,z,rot)
  local c=src:Clone();c.Parent=halloween;c:PivotTo(CFrame.new(x,0.5,z)*CFrame.Angles(0,math.rad(rot),0))
 end
 for i,o in ipairs(originals) do
  local angle=math.rad((i*137.5)%360);local r=38+((i*17)%65)
  o:PivotTo(CFrame.new(math.cos(angle)*r,0.5,math.sin(angle)*r)*CFrame.Angles(0,-angle,0))
 end
 if #originals>0 then
  for i=1,36 do local o=originals[((i*7-1)%#originals)+1];local a=math.rad((i*47)%360);place(o,math.cos(a)*(55+(i%4)*12),math.sin(a)*(55+(i%4)*12),(i*31)%360) end
 end
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
root:SetAttribute("ServerBuild", "V76")

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
txt.Text = "BUILD V76"
txt.Font = Enum.Font.GothamBold
txt.TextSize = 16
txt.Parent = tag
