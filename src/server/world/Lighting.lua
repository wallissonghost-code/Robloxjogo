local Lighting = game:GetService("Lighting")

local WorldLighting = {}

function WorldLighting.apply()
	Lighting.ClockTime = 14.2
	Lighting.Brightness = 2
	Lighting.EnvironmentDiffuseScale = .35
	Lighting.EnvironmentSpecularScale = .45
	Lighting.Ambient = Color3.fromRGB(105, 112, 105)
	Lighting.OutdoorAmbient = Color3.fromRGB(135, 145, 140)

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = .28
	atmosphere.Offset = .12
	atmosphere.Color = Color3.fromRGB(205, 220, 225)
	atmosphere.Decay = Color3.fromRGB(100, 125, 110)
	atmosphere.Glare = .08
	atmosphere.Haze = 1.2
	atmosphere.Parent = Lighting
end

return WorldLighting
