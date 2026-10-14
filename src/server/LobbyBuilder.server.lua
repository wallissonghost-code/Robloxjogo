-- LobbyBuilder.server.lua
-- Runtime creative-mode backend for decorating the lobby from mobile.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")

local OWNER_USER_ID = 9538436641
local HALLOWEEN_ASSET_ID = 113280926555931

local remotes = ReplicatedStorage:FindFirstChild("LobbyBuilderRemotes") or Instance.new("Folder")
remotes.Name = "LobbyBuilderRemotes"; remotes.Parent = ReplicatedStorage
local request = remotes:FindFirstChild("Request") or Instance.new("RemoteFunction")
request.Name = "Request"; request.Parent = remotes

local catalog = ReplicatedStorage:FindFirstChild("HalloweenCatalog") or Instance.new("Folder")
catalog.Name = "HalloweenCatalog"; catalog.Parent = ReplicatedStorage
local placed = workspace:FindFirstChild("LobbyDecor") or Instance.new("Folder")
placed.Name = "LobbyDecor"; placed.Parent = workspace

local function authorized(player) return player.UserId == OWNER_USER_ID end
local function sanitizeTemplate(inst)
	for _,d in ipairs(inst:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then d:Destroy()
		elseif d:IsA("BasePart") then d.Anchored=true; d.CanCollide=true end
	end
end
local function loadCatalog()
	catalog:ClearAllChildren()
	local ok, pack = pcall(function() return InsertService:LoadAsset(HALLOWEEN_ASSET_ID) end)
	if not ok or not pack then warn("[LobbyBuilder] Halloween asset failed:", pack); return end
	local source = pack:GetChildren()
	if #source == 1 and (source[1]:IsA("Model") or source[1]:IsA("Folder")) then source = source[1]:GetChildren() end
	for i,item in ipairs(source) do
		if item:IsA("Model") or item:IsA("BasePart") then
			local clone=item:Clone(); clone.Name=string.format("%02d_%s",i,item.Name); sanitizeTemplate(clone); clone.Parent=catalog
		end
	end
	pack:Destroy()
	print("[LobbyBuilder] catalog items:", #catalog:GetChildren())
end
loadCatalog()

local function pivot(inst, cf)
	if inst:IsA("Model") then inst:PivotTo(cf) else inst.CFrame=cf end
end
request.OnServerInvoke=function(player, action, data)
	if not authorized(player) then return {ok=false,error="Sem permissão"} end
	if action=="catalog" then
		local out={}; for _,v in ipairs(catalog:GetChildren()) do table.insert(out,v.Name) end; table.sort(out); return {ok=true,items=out}
	elseif action=="place" then
		local t=catalog:FindFirstChild(data.name); if not t then return {ok=false,error="Item inválido"} end
		local p=data.position
		if math.abs(p.X)>62 or math.abs(p.Z)>62 then return {ok=false,error="Fora do lobby"} end
		local obj=t:Clone(); obj.Name="Decor_"..data.name; obj:SetAttribute("PlacedBy",player.UserId); obj.Parent=placed
		pivot(obj,CFrame.new(p)*CFrame.Angles(0,math.rad(data.rotation or 0),0)); return {ok=true}
	elseif action=="deleteNearest" then
		local p=data.position; local best,dist
		for _,obj in ipairs(placed:GetChildren()) do
			local pos=obj:IsA("Model") and obj:GetPivot().Position or obj.Position
			local d=(pos-p).Magnitude; if not dist or d<dist then best,dist=obj,d end
		end
		if best and dist<=12 then best:Destroy(); return {ok=true} end
		return {ok=false,error="Nenhum item próximo"}
	elseif action=="clear" then placed:ClearAllChildren(); return {ok=true} end
	return {ok=false,error="Ação inválida"}
end
