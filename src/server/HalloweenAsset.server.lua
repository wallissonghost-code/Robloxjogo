local InsertService=game:GetService("InsertService")
local id=113280926555931
local ok,item=pcall(function() return InsertService:LoadAsset(id) end)
if not ok then return end
item.Name="Halloween_"..id
item.Parent=workspace
item:PivotTo(CFrame.new(14,4,-6))
