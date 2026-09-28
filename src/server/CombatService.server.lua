local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage.Combat.WeaponConfig)

local remotes=ReplicatedStorage:FindFirstChild("CombatRemotes") or Instance.new("Folder")
remotes.Name="CombatRemotes";remotes.Parent=ReplicatedStorage
local fire=Instance.new("RemoteEvent");fire.Name="Fire";fire.Parent=remotes
local reload=Instance.new("RemoteEvent");reload.Name="Reload";reload.Parent=remotes
local feedback=Instance.new("RemoteEvent");feedback.Name="Feedback";feedback.Parent=remotes
local lastShot={}
local reloading={}

local function makeTool(player)
	local backpack=player:FindFirstChildOfClass("Backpack");if not backpack then return end
	if backpack:FindFirstChild(Config.Name) or (player.Character and player.Character:FindFirstChild(Config.Name)) then return end
	local tool=Instance.new("Tool");tool.Name=Config.Name;tool.CanBeDropped=false;tool.RequiresHandle=true
	tool:SetAttribute("WeaponId","BasicPistol");tool:SetAttribute("Ammo",Config.MagazineSize);tool:SetAttribute("ReserveAmmo",Config.ReserveAmmo);tool:SetAttribute("Reloading",false)
	local handle=Instance.new("Part");handle.Name="Handle";handle.Size=Vector3.new(.45,.75,1.6);handle.Material=Enum.Material.Metal;handle.Color=Color3.fromRGB(45,48,46);handle.CanCollide=false;handle.Massless=true;handle.Parent=tool
	local muzzle=Instance.new("Attachment");muzzle.Name="Muzzle";muzzle.Position=Vector3.new(0,.12,-.82);muzzle.Parent=handle
	tool.Parent=backpack
end
local function give(player)
	task.defer(function()
		local backpack=player:WaitForChild("Backpack",10);if backpack then makeTool(player) end
	end)
end
local function hook(player)
	player.CharacterAdded:Connect(function() task.wait(.15);give(player) end)
	if player.Character then give(player) end
end
Players.PlayerAdded:Connect(hook)
for _,p in ipairs(Players:GetPlayers()) do hook(p) end

local function equipped(player)
	local c=player.Character;if not c then return end
	local tool=c:FindFirstChild(Config.Name)
	if tool and tool:IsA("Tool") and tool:GetAttribute("WeaponId")=="BasicPistol" then return tool end
end
local function finite(v) return typeof(v)=="Vector3" and v.X==v.X and v.Y==v.Y and v.Z==v.Z end
fire.OnServerEvent:Connect(function(player,origin,direction)
	local tool=equipped(player);if not tool or reloading[player] then return end
	if not finite(origin) or not finite(direction) or direction.Magnitude<.9 then return end
	local now=os.clock();if now-(lastShot[player] or 0)<Config.FireInterval then return end
	local character=player.Character;local head=character and character:FindFirstChild("Head");local root=character and character:FindFirstChild("HumanoidRootPart")
	if not head or not root or (origin-head.Position).Magnitude>7 then return end
	local ammo=tool:GetAttribute("Ammo") or 0;if ammo<=0 then feedback:FireClient(player,"Empty",ammo,tool:GetAttribute("ReserveAmmo") or 0);return end
	lastShot[player]=now;ammo-=1;tool:SetAttribute("Ammo",ammo)
	local dir=direction.Unit*Config.Range
	local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={character};params.IgnoreWater=false
	local hit=workspace:Raycast(origin,dir,params)
	local hitPosition=hit and hit.Position or origin+dir
	local didHit=false
	if hit then
		local model=hit.Instance:FindFirstAncestorOfClass("Model");local humanoid=model and model:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health>0 and model~=character then
			local damage=Config.Damage
			if hit.Instance.Name=="Head" then damage*=Config.HeadshotMultiplier end
			humanoid:TakeDamage(damage);didHit=true
		end
	end
	feedback:FireAllClients("Shot",player.UserId,origin,hitPosition,didHit,ammo,tool:GetAttribute("ReserveAmmo") or 0)
end)
reload.OnServerEvent:Connect(function(player)
	local tool=equipped(player);if not tool or reloading[player] then return end
	local ammo=tool:GetAttribute("Ammo") or 0;local reserve=tool:GetAttribute("ReserveAmmo") or 0
	if ammo>=Config.MagazineSize or reserve<=0 then return end
	reloading[player]=true;tool:SetAttribute("Reloading",true);feedback:FireClient(player,"Reloading",ammo,reserve)
	task.delay(Config.ReloadTime,function()
		if not player.Parent then return end
		local current=equipped(player)
		if current==tool then
			local need=Config.MagazineSize-ammo;local take=math.min(need,reserve)
			tool:SetAttribute("Ammo",ammo+take);tool:SetAttribute("ReserveAmmo",reserve-take)
			feedback:FireClient(player,"Reloaded",ammo+take,reserve-take)
		end
		reloading[player]=nil;if tool.Parent then tool:SetAttribute("Reloading",false) end
	end)
end)
Players.PlayerRemoving:Connect(function(p) lastShot[p]=nil;reloading[p]=nil end)
