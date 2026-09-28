local Factory = {}

local function part(parent, name, size, cf)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = true
	p.Material = Enum.Material.WoodPlanks
	p.Color = Color3.fromRGB(119, 88, 59)
	p.Parent = parent
	return p
end

function Factory.create(record, definition, parent)
	local model = Instance.new("Model")
	model.Name = record.type .. "_" .. record.id
	model:SetAttribute("BuildId", record.id)
	model:SetAttribute("BaseId", record.baseId)
	model:SetAttribute("OwnerUserId", record.ownerUserId)
	model:SetAttribute("PieceType", record.type)

	local cf = CFrame.new(record.x, record.y, record.z) * CFrame.Angles(0, math.rad(record.rotation or 0), 0)
	if definition.doorway then
		part(model, "Left", Vector3.new(3,8,1), cf * CFrame.new(-4.5,0,0))
		part(model, "Right", Vector3.new(3,8,1), cf * CFrame.new(4.5,0,0))
		part(model, "Top", Vector3.new(6,2,1), cf * CFrame.new(0,3,0))
	else
		part(model, "Body", definition.size, cf)
	end
	model.Parent = parent
	return model
end

return Factory
