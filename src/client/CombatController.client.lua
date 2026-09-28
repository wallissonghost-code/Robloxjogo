local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local Debris=game:GetService("Debris")
local player=Players.LocalPlayer
local remotes=ReplicatedStorage:WaitForChild("CombatRemotes")
local fire=remotes:WaitForChild("Fire");local reload=remotes:WaitForChild("Reload");local feedback=remotes:WaitForChild("Feedback")
local equippedTool
local gui=Instance.new("ScreenGui");gui.Name="CombatHUD";gui.ResetOnSpawn=false;gui.DisplayOrder=55;gui.Parent=player:WaitForChild("PlayerGui")
local ammoLabel=Instance.new("TextLabel");ammoLabel.AnchorPoint=Vector2.new(1,1);ammoLabel.Position=UDim2.new(1,-20,1,-72);ammoLabel.Size=UDim2.fromOffset(130,34);ammoLabel.BackgroundColor3=Color3.fromRGB(10,14,12);ammoLabel.BackgroundTransparency=.18;ammoLabel.TextColor3=Color3.new(1,1,1);ammoLabel.Font=Enum.Font.GothamBold;ammoLabel.TextSize=18;ammoLabel.Visible=false;ammoLabel.Parent=gui
Instance.new("UICorner",ammoLabel).CornerRadius=UDim.new(0,8)
local cross=Instance.new("TextLabel");cross.AnchorPoint=Vector2.new(.5,.5);cross.Position=UDim2.fromScale(.5,.5);cross.Size=UDim2.fromOffset(24,24);cross.BackgroundTransparency=1;cross.Text="+";cross.TextColor3=Color3.new(1,1,1);cross.TextSize=22;cross.Font=Enum.Font.GothamBold;cross.Visible=false;cross.Parent=gui
local function update()
	if not equippedTool then ammoLabel.Visible=false;cross.Visible=false;return end
	ammoLabel.Visible=true;cross.Visible=true
	ammoLabel.Text=string.format("%d / %d",equippedTool:GetAttribute("Ammo") or 0,equippedTool:GetAttribute("ReserveAmmo") or 0)
end
local function shoot()
	if not equippedTool or equippedTool:GetAttribute("Reloading") then return end
	local camera=workspace.CurrentCamera;if not camera then return end
	local center=camera.ViewportSize/2;local ray=camera:ViewportPointToRay(center.X,center.Y)
	fire:FireServer(ray.Origin,ray.Direction)
end
local function watchTool(tool)
	if not tool:IsA("Tool") or tool:GetAttribute("WeaponId")~="BasicPistol" then return end
	tool.Equipped:Connect(function() equippedTool=tool;update() end)
	tool.Unequipped:Connect(function() if equippedTool==tool then equippedTool=nil;update() end end)
	tool.Activated:Connect(shoot)
	tool:GetAttributeChangedSignal("Ammo"):Connect(update);tool:GetAttributeChangedSignal("ReserveAmmo"):Connect(update)
end
local function hookCharacter(c)
	for _,x in ipairs(c:GetChildren()) do watchTool(x) end
	c.ChildAdded:Connect(watchTool)
end
player.CharacterAdded:Connect(hookCharacter);if player.Character then hookCharacter(player.Character) end
player:WaitForChild("Backpack").ChildAdded:Connect(watchTool)
for _,x in ipairs(player.Backpack:GetChildren()) do watchTool(x) end
UserInputService.InputBegan:Connect(function(input,processed)
	if processed or not equippedTool then return end
	if input.KeyCode==Enum.KeyCode.R then reload:FireServer() end
end)
feedback.OnClientEvent:Connect(function(kind,a,b,c,d,e,f)
	if kind=="Shot" then
		local shooterId=a;local origin=b;local hitPosition=c
		local beamPart=Instance.new("Part");beamPart.Name="Tracer";beamPart.Anchored=true;beamPart.CanCollide=false;beamPart.CanTouch=false;beamPart.CanQuery=false;beamPart.Material=Enum.Material.Neon
		local distance=(hitPosition-origin).Magnitude;beamPart.Size=Vector3.new(.035,.035,distance);beamPart.CFrame=CFrame.lookAt((origin+hitPosition)/2,hitPosition);beamPart.Parent=workspace;Debris:AddItem(beamPart,.06)
		if shooterId==player.UserId then update() end
	elseif kind=="Reloaded" or kind=="Reloading" or kind=="Empty" then update() end
end)
