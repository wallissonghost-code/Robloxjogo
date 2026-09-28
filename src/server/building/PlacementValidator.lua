local Config = require(script.Parent.Parent.World.Config)
local Validator = {}
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<100000 end

function Validator.validate(player,definition,resolved)
	local position=resolved and resolved.position
	if typeof(position)~="Vector3" or not finite(position.X) or not finite(position.Y) or not finite(position.Z) then
		return false,"Posição inválida."
	end
	if math.abs(position.X)>Config.LAND_HALF-20 or math.abs(position.Z)>Config.LAND_HALF-20 then
		return false,"Fora da área de construção."
	end
	local character=player.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position-position).Magnitude>45 then return false,"Muito longe para construir." end
	return true
end
return Validator
