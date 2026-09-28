local Workspace = game:GetService("Workspace")
local Config = require(script.Parent.Parent.World.Config)

local Validator = {}

local function finite(n)
	return type(n) == "number" and n == n and math.abs(n) < 100000
end

function Validator.validate(player, definition, position, rotation)
	if typeof(position) ~= "Vector3" or not finite(position.X) or not finite(position.Y) or not finite(position.Z) then
		return false, "Posição inválida."
	end
	if not finite(rotation) then return false, "Rotação inválida." end
	if math.abs(position.X) > Config.LAND_HALF - 20 or math.abs(position.Z) > Config.LAND_HALF - 20 then
		return false, "Fora da área de construção."
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - position).Magnitude > 45 then
		return false, "Muito longe para construir."
	end
	local box = definition.size - Vector3.new(.35,.15,.35)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local hits = Workspace:GetPartBoundsInBox(CFrame.new(position) * CFrame.Angles(0, math.rad(rotation), 0), box, params)
	for _, hit in ipairs(hits) do
		if hit.CanCollide and not hit:IsDescendantOf(Workspace.Terrain) and hit.Name ~= "SpawnLocation" then
			return false, "Espaço ocupado."
		end
	end
	return true
end

return Validator
