local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Remotes={}
function Remotes.Init()
    local folder=ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
    folder.Name="Remotes"; folder.Parent=ReplicatedStorage
    local command=folder:FindFirstChild("MapCommand") or Instance.new("RemoteEvent")
    command.Name="MapCommand"; command.Parent=folder
    Remotes.MapCommand=command
    local old=folder:FindFirstChild("ClaimCell"); if old then old:Destroy() end
end
return Remotes
