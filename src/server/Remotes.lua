local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

function Remotes.Init()
    local folder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
    folder.Name = "Remotes"
    folder.Parent = ReplicatedStorage

    local claim = folder:FindFirstChild("ClaimCell") or Instance.new("RemoteEvent")
    claim.Name = "ClaimCell"
    claim.Parent = folder
    Remotes.ClaimCell = claim
end

return Remotes
