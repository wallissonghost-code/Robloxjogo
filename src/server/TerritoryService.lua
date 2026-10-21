local Players = game:GetService("Players")

local TerritoryService = {}
local Config
local TroopService
local cells = {}
local owned = {}

local function key(x,z) return x..":"..z end
local function colorFor(player)
    local h=(player.UserId*0.61803398875)%1
    return Color3.fromHSV(h,0.55,0.92)
end
local function neighbors(cell)
    return {cells[key(cell.X+1,cell.Z)],cells[key(cell.X-1,cell.Z)],cells[key(cell.X,cell.Z+1)],cells[key(cell.X,cell.Z-1)]}
end
local function isAdjacentToPlayer(cell,player)
    for _,n in ipairs(neighbors(cell)) do if n and n.Owner==player then return true end end
    return false
end
local function largestComponent(player)
    local list=owned[player]
    if not list then return nil,0 end
    local visited,best,bestCount={},nil,0
    for _,start in pairs(list) do
        if not visited[start] then
            local q,head,component={start},1,{}
            visited[start]=true
            while q[head] do
                local current=q[head]; head+=1; table.insert(component,current)
                for _,n in ipairs(neighbors(current)) do
                    if n and n.Owner==player and not visited[n] then visited[n]=true; table.insert(q,n) end
                end
            end
            if #component>bestCount then best,bestCount=component,#component end
        end
    end
    return best,bestCount
end
local function formatNumber(v)
    if v>=1e6 then return string.format("%.2fM",v/1e6) end
    if v>=1e3 then return string.format(v>=10000 and "%.1fK" or "%.2fK",v/1e3) end
    return tostring(math.floor(v))
end
local function markerCell(component)
    local set={}
    local sx,sz=0,0
    for _,c in ipairs(component) do set[key(c.X,c.Z)]=true; sx+=c.X; sz+=c.Z end
    local cx,cz=sx/#component,sz/#component
    local best,bestScore=nil,-math.huge
    for _,c in ipairs(component) do
        local depth=0
        for radius=1,5 do
            local ok=true
            for dx=-radius,radius do
                if not set[key(c.X+dx,c.Z-radius)] or not set[key(c.X+dx,c.Z+radius)] then ok=false break end
            end
            if ok then
                for dz=-radius+1,radius-1 do
                    if not set[key(c.X-radius,c.Z+dz)] or not set[key(c.X+radius,c.Z+dz)] then ok=false break end
                end
            end
            if ok then depth=radius else break end
        end
        local dist=(c.X-cx)^2+(c.Z-cz)^2
        local score=depth*100-dist
        if score>bestScore then bestScore,best=score,c end
    end
    return best
end
local function updateMarker(player)
    local component,count=largestComponent(player)
    local map=workspace:FindFirstChild("PixelWarMap")
    if not map then return end
    local marker=map.Markers:FindFirstChild(tostring(player.UserId))
    if not component or count==0 then if marker then marker:Destroy() end return end
    local center=markerCell(component)
    if not marker then
        marker=Instance.new("Part"); marker.Name=tostring(player.UserId); marker.Anchored=true; marker.CanCollide=false; marker.CanQuery=false; marker.Transparency=1; marker.Size=Vector3.new(1,1,1); marker.Parent=map.Markers
        local gui=Instance.new("BillboardGui"); gui.Name="Label"; gui.AlwaysOnTop=true; gui.Size=UDim2.fromOffset(210,54); gui.StudsOffsetWorldSpace=Vector3.new(0,0.5,0); gui.Parent=marker
        local avatar=Instance.new("ImageLabel"); avatar.Name="Avatar"; avatar.BackgroundTransparency=1; avatar.Size=UDim2.fromOffset(34,34); avatar.Position=UDim2.fromOffset(0,8); avatar.Parent=gui
        local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(1,0); corner.Parent=avatar
        task.spawn(function()
            local ok,image=pcall(Players.GetUserThumbnailAsync,Players,player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)
            if ok and avatar.Parent then avatar.Image=image end
        end)
        local name=Instance.new("TextLabel"); name.Name="PlayerName"; name.BackgroundTransparency=1; name.Position=UDim2.fromOffset(40,0); name.Size=UDim2.fromOffset(170,30); name.Font=Enum.Font.GothamBold; name.TextColor3=Color3.new(1,1,1); name.TextStrokeTransparency=0.1; name.TextXAlignment=Enum.TextXAlignment.Left; name.Text=player.DisplayName; name.Parent=gui
        local troops=Instance.new("TextLabel"); troops.Name="Troops"; troops.BackgroundTransparency=1; troops.Position=UDim2.fromOffset(40,29); troops.Size=UDim2.fromOffset(170,22); troops.Font=Enum.Font.GothamBold; troops.TextColor3=Color3.new(1,1,1); troops.TextStrokeTransparency=0.15; troops.TextXAlignment=Enum.TextXAlignment.Left; troops.Parent=gui
    end
    marker.Position=Vector3.new(center.Part.Position.X,Config.Map.CellHeight+0.8,center.Part.Position.Z)
    local scale=math.clamp(0.52+math.log(count+1)/6,0.52,1.25)
    marker.Label.Size=UDim2.fromOffset(210*scale,54*scale)
    marker.Label.PlayerName.TextSize=math.floor(18*scale)
    marker.Label.Troops.TextSize=math.floor(14*scale)
end

function TerritoryService.Init(config,troopService) Config=config; TroopService=troopService end

function TerritoryService.BuildMap()
    local old=workspace:FindFirstChild("PixelWarMap"); if old then old:Destroy() end
    local map=Instance.new("Folder"); map.Name="PixelWarMap"; map.Parent=workspace
    local folder=Instance.new("Folder"); folder.Name="Cells"; folder.Parent=map
    local markers=Instance.new("Folder"); markers.Name="Markers"; markers.Parent=map
    table.clear(cells); table.clear(owned)
    local W,H=Config.Map.Width,Config.Map.Height
    local widthStuds,heightStuds=W*Config.Map.CellSize,H*Config.Map.CellSize
    local startX=Config.Map.Origin.X-widthStuds/2+Config.Map.CellSize/2
    local startZ=Config.Map.Origin.Z-heightStuds/2+Config.Map.CellSize/2
    local water=Instance.new("Part"); water.Name="Water"; water.Anchored=true; water.CanCollide=false; water.CanQuery=false; water.Size=Vector3.new(widthStuds,Config.Map.CellHeight*0.45,heightStuds); water.Position=Vector3.new(Config.Map.Origin.X,Config.Map.Origin.Y-Config.Map.CellHeight*0.65,Config.Map.Origin.Z); water.Material=Enum.Material.SmoothPlastic; water.Color=Config.Map.WaterColor; water.Parent=map

    local function ellipse(u,v,cx,cy,rx,ry)
        local dx=(u-cx)/rx; local dy=(v-cy)/ry
        return dx*dx+dy*dy<=1
    end
    local function landAt(x,z)
        local u=(x-0.5)/W; local v=(z-0.5)/H
        -- recognizable low-resolution world silhouette, intentionally generated
        -- from continent masses so no external/copyrighted map asset is required.
        local northAmerica=ellipse(u,v,.20,.31,.15,.20) or ellipse(u,v,.14,.22,.09,.09) or ellipse(u,v,.28,.38,.09,.11)
        northAmerica=northAmerica and not ellipse(u,v,.29,.25,.075,.075)
        local central=ellipse(u,v,.285,.49,.035,.11)
        local southAmerica=ellipse(u,v,.36,.66,.075,.23) or ellipse(u,v,.33,.57,.055,.09)
        local greenland=ellipse(u,v,.39,.13,.055,.09)
        local europe=ellipse(u,v,.52,.30,.075,.10) or ellipse(u,v,.48,.27,.04,.05)
        local africa=ellipse(u,v,.53,.52,.105,.22) or ellipse(u,v,.58,.61,.045,.13)
        local asia=ellipse(u,v,.68,.31,.19,.16) or ellipse(u,v,.78,.39,.13,.15) or ellipse(u,v,.62,.38,.10,.12)
        asia=asia and not ellipse(u,v,.69,.48,.07,.07)
        local india=ellipse(u,v,.66,.49,.045,.11)
        local seAsia=ellipse(u,v,.76,.53,.06,.10)
        local japan=ellipse(u,v,.845,.37,.018,.065)
        local australia=ellipse(u,v,.80,.72,.09,.105) or ellipse(u,v,.85,.70,.04,.06)
        local madagascar=ellipse(u,v,.61,.69,.018,.07)
        local uk=ellipse(u,v,.465,.285,.018,.04)
        local iceland=ellipse(u,v,.45,.20,.022,.018)
        return northAmerica or central or southAmerica or greenland or europe or africa or asia or india or seAsia or japan or australia or madagascar or uk or iceland
    end
    local mask={}
    for z=1,H do mask[z]={}; for x=1,W do mask[z][x]=landAt(x,z) end end
    local function coast(x,z)
        if not mask[z][x] then return false end
        for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do local xx,zz=x+d[1],z+d[2]; if xx<1 or xx>W or zz<1 or zz>H or not mask[zz][xx] then return true end end
        return false
    end
    for z=1,H do for x=1,W do if mask[z][x] then
        local part=Instance.new("Part"); part.Name=string.format("C_%d_%d",x,z); part.Anchored=true; part.CanCollide=false
        part.Size=Vector3.new(Config.Map.CellSize-Config.Map.CellGap,Config.Map.CellHeight,Config.Map.CellSize-Config.Map.CellGap)
        part.Position=Vector3.new(startX+(x-1)*Config.Map.CellSize,Config.Map.Origin.Y,startZ+(z-1)*Config.Map.CellSize); part.Material=Enum.Material.SmoothPlastic
        part.Color=coast(x,z) and Config.Map.CoastColor or Config.Map.NeutralColor; part:SetAttribute("BaseColor",part.Color); part:SetAttribute("GridX",x); part:SetAttribute("GridZ",z); part.Parent=folder
        cells[key(x,z)]={X=x,Z=z,Part=part,Owner=nil}
    end end end
end

function TerritoryService.TryClaim(player,part)
    local map=workspace:FindFirstChild("PixelWarMap"); if not map or not part or part.Parent~=map.Cells then return false end
    local x,z=part:GetAttribute("GridX"),part:GetAttribute("GridZ"); local cell=x and z and cells[key(x,z)]
    if not cell or cell.Owner then return false end
    local list=owned[player]; local first=not list or next(list)==nil
    if not first and not isAdjacentToPlayer(cell,player) then return false end
    local cost=first and 0 or Config.Territory.NeutralClaimCost
    if cost>0 and not TroopService.Spend(player,cost) then return false end
    cell.Owner=player; cell.Part.Color=colorFor(player); cell.Part:SetAttribute("OwnerUserId",player.UserId)
    owned[player]=owned[player] or {}; owned[player][key(x,z)]=cell
    local count=0; for _ in pairs(owned[player]) do count+=1 end
    player:SetAttribute("TerritoryCells",count); updateMarker(player); return true
end

function TerritoryService.RemovePlayer(player)
    local list=owned[player]
    if list then for _,cell in pairs(list) do cell.Owner=nil; cell.Part.Color=cell.Part:GetAttribute("BaseColor") or Config.Map.NeutralColor; cell.Part:SetAttribute("OwnerUserId",nil) end end
    owned[player]=nil
    local map=workspace:FindFirstChild("PixelWarMap"); local marker=map and map.Markers:FindFirstChild(tostring(player.UserId)); if marker then marker:Destroy() end
end
function TerritoryService.RefreshTroops(player)
    local map=workspace:FindFirstChild("PixelWarMap"); local marker=map and map.Markers:FindFirstChild(tostring(player.UserId))
    if marker and marker:FindFirstChild("Label") then marker.Label.Troops.Text=formatNumber(TroopService.Get(player)) end
end
return TerritoryService
