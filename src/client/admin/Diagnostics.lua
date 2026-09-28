local Diagnostics = {}

local function currentRoot(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

function Diagnostics.bind(player, controls, runService)
	local markCount = 0

	controls.mark.MouseButton1Click:Connect(function()
		local root = currentRoot(player)
		if not root then return end
		markCount += 1
		local p = root.Position
		controls.mark.Text = string.format("#%d  X %.1f  Y %.1f  Z %.1f", markCount, p.X, p.Y, p.Z)
	end)

	runService.RenderStepped:Connect(function()
		local root = currentRoot(player)
		if root then
			local p = root.Position
			controls.coords.Text = string.format("X: %.1f   Y: %.1f   Z: %.1f", p.X, p.Y, p.Z)
		else
			controls.coords.Text = "X: --  Y: --  Z: --"
		end
	end)
end

return Diagnostics
