local Players = game:GetService("Players")

local TerritoryService = {}
local Config
local TroopService
local cells = {}
local owned = {}\nlocal countryBots = {}

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
        local name=Instance.new("TextLabel"); name.Name="PlayerName"; name.BackgroundTransparency=1; name.Position=UDim2.fromOffset(40,0); name.Size=UDim2.fromOffset(170,30); name.Font=Enum.Font.GothamBold; name.TextColor3=Color3.new(1,1,1); name.TextStrokeTransparency=0.1; name.TextXAlignment=Enum.TextXAlignment.Left; name.Text=player.DisplayName or player.Name; name.Parent=gui
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
        local u=(x-0.5)/W
        local v=(z-0.5)/H
        -- Higher-resolution world layout with deliberate ocean separation.
        -- Continents are composed from overlapping masses; ownership remains
        -- cell-based so borders can later emerge dynamically between players.
        local northAmerica =
            ellipse(u,v,.145,.265,.105,.145) or
            ellipse(u,v,.205,.315,.105,.145) or
            ellipse(u,v,.255,.375,.075,.105) or
            ellipse(u,v,.095,.205,.055,.070)
        -- Hudson Bay / Great Lakes / Gulf help break the silhouette.
        northAmerica = northAmerica
            and not ellipse(u,v,.205,.235,.038,.050)
            and not ellipse(u,v,.265,.335,.030,.024)
            and not ellipse(u,v,.275,.445,.055,.050)

        local centralAmerica =
            ellipse(u,v,.282,.475,.025,.070) or
            ellipse(u,v,.305,.515,.030,.045)

        local southAmerica =
            ellipse(u,v,.350,.615,.068,.130) or
            ellipse(u,v,.385,.695,.055,.155) or
            ellipse(u,v,.365,.555,.055,.070)
        southAmerica = southAmerica and not ellipse(u,v,.315,.720,.030,.090)

        local greenland = ellipse(u,v,.385,.135,.045,.075)
        local caribbean = ellipse(u,v,.325,.505,.010,.010) or ellipse(u,v,.342,.515,.009,.008)

        local europe =
            ellipse(u,v,.515,.290,.060,.075) or
            ellipse(u,v,.555,.300,.075,.075) or
            ellipse(u,v,.485,.335,.030,.050)
        local uk = ellipse(u,v,.475,.285,.014,.030)
        local iceland = ellipse(u,v,.455,.215,.015,.012)

        local africa =
            ellipse(u,v,.545,.495,.082,.150) or
            ellipse(u,v,.565,.585,.060,.135)
        africa = africa
            and not ellipse(u,v,.625,.425,.045,.055)
            and not ellipse(u,v,.485,.600,.025,.060)

        local asia =
            ellipse(u,v,.650,.285,.115,.105) or
            ellipse(u,v,.735,.300,.125,.115) or
            ellipse(u,v,.810,.325,.090,.115) or
            ellipse(u,v,.675,.390,.105,.100)
        asia = asia
            and not ellipse(u,v,.610,.410,.050,.045)
            and not ellipse(u,v,.770,.440,.055,.050)

        local india = ellipse(u,v,.675,.455,.035,.085)
        local seAsia =
            ellipse(u,v,.755,.475,.045,.085) or
            ellipse(u,v,.790,.515,.035,.070)
        local japan = ellipse(u,v,.865,.335,.012,.050)
        local philippines = ellipse(u,v,.815,.500,.012,.045)
        local indonesia =
            ellipse(u,v,.785,.565,.050,.025) or
            ellipse(u,v,.840,.575,.055,.025)

        local australia =
            ellipse(u,v,.835,.705,.075,.090) or
            ellipse(u,v,.875,.680,.045,.070)
        local newZealand = ellipse(u,v,.925,.760,.010,.045)
        local madagascar = ellipse(u,v,.625,.660,.012,.055)

        return northAmerica or centralAmerica or southAmerica or greenland or caribbean
            or europe or uk or iceland or africa or asia or india or seAsia
            or japan or philippines or indonesia or australia or newZealand or madagascar
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

local function setOwner(player,cell)
    cell.Owner=player
    cell.Part.Color=colorFor(player)
    cell.Part:SetAttribute("OwnerUserId",player.UserId)
    owned[player]=owned[player] or {}
    owned[player][key(cell.X,cell.Z)]=cell
end

local function territoryCount(player)
    local n=0
    for _ in pairs(owned[player] or {}) do n+=1 end
    return n
end

local function distanceScore(cell,tx,tz)
    local dx=cell.X-tx; local dz=cell.Z-tz
    return dx*dx+dz*dz
end

function TerritoryService.SpawnPlayer(player,part)
    local map=workspace:FindFirstChild("PixelWarMap")
    if not map or not part or part.Parent~=map.Cells or territoryCount(player)>0 then return false end
    local x,z=part:GetAttribute("GridX"),part:GetAttribute("GridZ")
    local cell=x and z and cells[key(x,z)]
    if not cell or cell.Owner then return false end
    setOwner(player,cell)
    player:SetAttribute("TerritoryCells",1)
    updateMarker(player)
    return true
end

function TerritoryService.ExpandToward(player,part,percent)
    local map=workspace:FindFirstChild("PixelWarMap")
    if not map or not part or part.Parent~=map.Cells then return false end
    if territoryCount(player)==0 then return TerritoryService.SpawnPlayer(player,part) end
    local tx,tz=part:GetAttribute("GridX"),part:GetAttribute("GridZ")
    if not tx or not tz then return false end
    local force=TroopService.SendPercent(player,percent)
    if force<=0 then return false end

    task.spawn(function()
        local budget=force
        local claimed=0
        while budget>=Config.Territory.TroopsPerNeutralCell and claimed<Config.Territory.MaxCellsPerOrder do
            local candidates={}
            local seen={}
            for _,ownCell in pairs(owned[player] or {}) do
                for _,n in ipairs(neighbors(ownCell)) do
                    if n and not n.Owner and not seen[n] then
                        seen[n]=true
                        table.insert(candidates,n)
                    end
                end
            end
            if #candidates==0 then break end
            table.sort(candidates,function(a,b)
                local da=distanceScore(a,tx,tz)
                local db=distanceScore(b,tx,tz)
                if da==db then
                    -- Prefer cells supported by more friendly neighbours.
                    local aa,bb=0,0
                    for _,n in ipairs(neighbors(a)) do if n and n.Owner==player then aa+=1 end end
                    for _,n in ipairs(neighbors(b)) do if n and n.Owner==player then bb+=1 end end
                    return aa>bb
                end
                return da<db
            end)
            -- Advance a small front each pulse instead of drawing a single-cell snake.
            local pulse=math.min(3,#candidates,math.floor(budget/Config.Territory.TroopsPerNeutralCell))
            if pulse<=0 then break end
            for i=1,pulse do
                local cell=candidates[i]
                if cell and not cell.Owner then
                    setOwner(player,cell)
                    budget-=Config.Territory.TroopsPerNeutralCell
                    claimed+=1
                end
            end
            player:SetAttribute("TerritoryCells",territoryCount(player))
            updateMarker(player)
            task.wait(Config.Territory.ExpansionStepDelay)
        end
    end)
    return true
end

function TerritoryService.TryClaim(player,part)
    if territoryCount(player)==0 then return TerritoryService.SpawnPlayer(player,part) end
    return TerritoryService.ExpandToward(player,part,Config.Territory.DefaultSendPercent)
end

local function nearestFreeCellForWorld(longitude,latitude)
    local W,H=Config.Map.Width,Config.Map.Height
    local targetX=math.clamp(math.floor(((longitude+180)/360)*W)+1,1,W)
    local targetZ=math.clamp(math.floor(((90-latitude)/180)*H)+1,1,H)
    local best,bestD=nil,math.huge
    for _,cell in pairs(cells) do
        if not cell.Owner then
            local d=(cell.X-targetX)^2+(cell.Z-targetZ)^2
            if d<bestD then bestD,best=d,cell end
        end
    end
    return best
end

local function botFront(bot,internalOnly)
    local candidates,seen={},{}
    for _,ownCell in pairs(owned[bot] or {}) do
        for _,n in ipairs(neighbors(ownCell)) do
            if n and not n.Owner and not seen[n] then
                local d=(n.X-bot.HomeX)^2+(n.Z-bot.HomeZ)^2
                if not internalOnly or d<=bot.HomeRadius*bot.HomeRadius then
                    seen[n]=true; table.insert(candidates,n)
                end
            end
        end
    end
    table.sort(candidates,function(a,b)
        local da=(a.X-bot.HomeX)^2+(a.Z-bot.HomeZ)^2
        local db=(b.X-bot.HomeX)^2+(b.Z-bot.HomeZ)^2
        return da<db
    end)
    return candidates
end

function TerritoryService.CreateCountryBots(definitions)
    for i,data in ipairs(definitions) do
        local seed=nearestFreeCellForWorld(data[2],data[3])
        if seed then
            local bot={Name=data[1],DisplayName=data[1],UserId=-(10000+i),Troops=Config.Bot.StartingTroops,HomeRadius=math.max(3,math.floor(math.sqrt(Config.Map.Width*Config.Map.Height/195)*0.72))}
            bot.HomeX,bot.HomeZ=seed.X,seed.Z
            countryBots[#countryBots+1]=bot
            setOwner(bot,seed)
            updateMarker(bot)
        end
    end
    task.spawn(function()
        while true do
            task.wait(Config.Bot.ThinkInterval)
            for _,bot in ipairs(countryBots) do
                bot.Troops=math.min(Config.Bot.BaseTroopCapacity,bot.Troops+Config.Bot.TroopsPerTick)
                local homeArea=math.pi*bot.HomeRadius*bot.HomeRadius
                local internal=territoryCount(bot)<homeArea*Config.Bot.InternalExpansionTarget
                local front=botFront(bot,internal)
                if #front>0 and bot.Troops>=Config.Territory.TroopsPerNeutralCell then
                    local steps=math.min(2,#front,math.floor(bot.Troops/Config.Territory.TroopsPerNeutralCell))
                    for n=1,steps do
                        local cell=front[n]
                        if cell and not cell.Owner then
                            setOwner(bot,cell)
                            bot.Troops-=Config.Territory.TroopsPerNeutralCell
                        end
                    end
                    updateMarker(bot)
                else
                    updateMarker(bot)
                end
            end
        end
    end)
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
