local InsertService=game:GetService("InsertService")
local id=113280926555931
local ok,item=pcall(function() return InsertService:LoadAsset(id) end)
if not ok then return end
item.Name="HalloweenLobby"
item.Parent=workspace
local spots={Vector3.new(-24,2,-20),Vector3.new(0,2,-28),Vector3.new(24,2,-20),Vector3.new(-28,2,0),Vector3.new(28,2,0),Vector3.new(-24,2,20),Vector3.new(0,2,28),Vector3.new(24,2,20)}
local n=0
for _,o in ipairs(item:GetChildren()) do
 if o:IsA("Model") or o:IsA("BasePart") then
  n=n+1
  local p=spots[((n-1)%#spots)+1]
  if o:IsA("Model") then o:PivotTo(CFrame.new(p)) else o.CFrame=CFrame.new(p) end
 end
end
