local Config = dofile("src/shared/Config.lua")
local MapGrid = dofile("src/shared/MapGrid.lua")
local MapService = dofile("src/server/MapService.lua")
local NationService = dofile("src/server/NationService.lua")
local EconomyService = dofile("src/server/EconomyService.lua")
local ExpansionService = dofile("src/server/ExpansionService.lua")
local MatchService = dofile("src/server/MatchService.lua")
local CommandService = dofile("src/server/CommandService.lua")
local Replica = dofile("src/client/NationReplica.lua")
local grid = MapGrid.new({Width=12,Height=12,ChunkSize=4,Version=1,
    MinLongitude=0,MaxLongitude=12,MinLatitude=0,MaxLatitude=12}, {
    Land={{Points={{0,0},{12,0},{12,12},{0,12}}}},
    Water={{Points={{10,0},{12,0},{12,2},{10,2}}}},
})
local checks = 0
local function check(value,message) checks=checks+1; assert(value,message) end
local function close(a,b) return math.abs(a-b)<0.00001 end
local function setup(g)
    g = g or grid
    local economy = EconomyService.new(Config.Economy)
    local nations = NationService.new(MapService.new(g),Config.Nations,economy)
    local expansion = ExpansionService.new(nations,Config.Expansion,Config.SendPercentages)
    local match = MatchService.new(nations,economy,expansion,Config.Tick)
    return nations,economy,expansion,match
end
local function invariants(nations)
    local count=0
    nations:ForEachState(function(nation)
        local size=0
        for id in pairs(nation.Cells) do
            size=size+1
            check(nations:GetOwner(id)==nation.Id,"Owned set matches owner index")
            local frontier=false
            for _,other in ipairs(nations.Map.Grid:GetNeighbors(id)) do
                if nations:GetOwner(other)~=nation.Id then frontier=true end
            end
            check((nation.Frontier[id]==true)==frontier,"Cached frontier matches topology")
        end
        check(size==nation.TerritoryCount,"O(1) territory count")
        check(nation.Cells[nation.CapitalId],"Capital stays owned")
        check(nation.Troops>=0 and nation.Troops+(nation.ExpansionRemaining or 0)<=nation.MaxTroops+0.00001,"Troops incl escrow bounded")
        check(nation.Gold>=0 and nation.Gold<=Config.Economy.MaxGold,"Gold bounded")
        count=count+size
    end)
    check(#nations:Snapshot().Cells==count,"Snapshot matches ownership indices")
end
local n,e,x,m=setup()
local capital,target=grid:ToId(4,4),grid:ToId(5,4)
n:Create(1,"One",capital)
local state=n:GetState(1)
check(state.Troops==100 and state.Gold==50,"Starting economy")
check(state.MaxTroops==175 and state.TroopsPerSecond==4 and close(state.GoldPerSecond,1.2),"Initial rates")
local rep=Replica.new(grid); rep:Apply(n:Snapshot())
local revision=n.Revision
for _,pct in ipairs({0,1,100,51,50.1,"50",{},0/0,math.huge}) do
    local delta,code=x:Start(1,target,pct)
    check(not delta and code=="InvalidPercent","Percent whitelist")
end
for _,id in ipairs({grid:ToId(12,12),grid:ToId(9,9),capital,{},0/0,1.5}) do
    check(x:Start(1,id,50)==nil,"Water/non-adjacent/owned/malformed rejected")
end
check(n.Revision==revision and state.Troops==100,"Rejected orders do not spend or publish")
check(select(2,x:Start(99,target,50))=="NoNation","Spectator cannot expand")
local start,code,sent=x:Start(1,target,50)
rep:Apply(start)
check(code=="ExpansionStarted" and sent==50 and state.Troops==50,"Percentage computed by server")
check(n:GetOwner(target)==nil and state.ExpansionRemaining==50,"Progressive not instant transfer")
check(select(2,x:Start(1,target,25))=="ExpansionBusy","One active order per nation")
local delta=m:Step(0.25); rep:Apply(delta)
check(#delta.Cells==2 and state.TerritoryCount==3,"Bounded first pulse")
check(state.Troops==50 and state.ExpansionRemaining==30,"Escrow cost per conquered cell")
invariants(n)
rep:Apply(m:Step(0.25)); rep:Apply(m:Step(0.25))
check(not state.ExpansionActive and state.TerritoryCount==6,"Five connected cells conquered")
check(state.Troops==50 and state.ExpansionRemaining==0,"Exact full-spend accounting")
local tick=m:Step(0.25)
local dirty=rep:Apply(tick)
check(#tick.Cells==0 and next(dirty)==nil,"Economy tick never redraws terrain")
check(state.Troops==59 and close(state.Gold,52.2),"Higher territory income")
check(state.MaxTroops==300 and rep.Nations[1].Troops==59,"Capacity and HUD replication")
invariants(n)

-- Low balance and exact percent rounding. Isolation makes spend/refund measurable.
local n2,e2,x2,m2=setup(); n2:Create(2,"Two",capital)
local s2=n2:GetState(2); s2.Troops=9
check(select(2,x2:Start(2,target,75))=="InsufficientTroops" and s2.Troops==9,"No tiny orders")
s2.Troops=103
local _,_,sent2=x2:Start(2,target,35)
check(sent2==36 and s2.Troops==67,"Floor percentage")
for _=1,2 do m2:Step(0.25) end
check(s2.TerritoryCount==4 and s2.Troops==73,"Unused six troops refunded")
invariants(n2)
-- Cap and elapsed-time batching, including invalid dt and severe stalls.
e2:Step(n2,100000,{})
check(s2.Troops==s2.MaxTroops,"Regeneration cap")
local troops,gold,rev=s2.Troops,s2.Gold,n2.Revision
for _,dt in ipairs({0,-1,0/0,math.huge,"1"}) do check(m2:Step(dt)==nil,"Reject invalid elapsed") end
check(s2.Troops==troops and s2.Gold==gold and n2.Revision==rev,"Invalid tick no mutation")
m2:Step(10000)
check(close(s2.Gold-gold,5*s2.GoldPerSecond),"Catchup bounded after stall")

-- Rival wins queued target before pulse: full refund and no crossing enemy land.
local n3,e3,x3,m3=setup(); n3:Create(3,"Three",capital)
local s3=n3:GetState(3)
x3:Start(3,target,50)
n3:Create(4,"Rival",target)
m3:Step(0.25)
check(s3.Troops==100 and not s3.ExpansionActive and s3.TerritoryCount==1,"Contested target full refund")
check(n3:GetOwner(target)==4,"Never captures an enemy in neutral expansion")
invariants(n3)

-- Narrow island: cannot jump water to another component.
local island=MapGrid.new({Width=6,Height=1,ChunkSize=2,Version=1,
    MinLongitude=0,MaxLongitude=6,MinLatitude=0,MaxLatitude=1},{
    Land={{Points={{0,0},{6,0},{6,1},{0,1}}}},Water={{Points={{2,0},{4,0},{4,1},{2,1}}}},
})
local ni,ei,xi,mi=setup(island); ni:Create(5,"Island",1)
xi:Start(5,2,75); mi:Step(0.25)
check(ni:GetState(5).TerritoryCount==2 and ni:GetState(5).Troops==90,"Island stops and refunds")
check(ni:GetOwner(5)==nil and ni:GetOwner(6)==nil,"No sea teleport")

-- Limit per order, no free cells, and no phantom expansion after departure.
local n4,e4,x4,m4=setup(); n4:Create(6,"Six",capital)
local s4=n4:GetState(6); s4.MaxTroops=10000; s4.Troops=10000
x4:Start(6,target,75)
for _=1,12 do
    local changed,cells={},{}; x4:Step(changed,cells); n4:Publish(changed,cells)
end
check(s4.ExpansionClaimed==24 and not s4.ExpansionActive,"Max cells/order enforced")
-- Artificially high balance above derived cap is intentionally clamped on refund.
check(s4.Troops<=s4.MaxTroops,"Refund respects derived cap")
local front
for id in pairs(s4.Frontier) do
    for _,other in ipairs(grid:GetNeighbors(id)) do if n4:GetOwner(other)==nil then front=other;break end end
    if front then break end
end
x4:Start(6,front,50)
x4:Forget(6); n4:Remove(6)
m4:Step(1)
check(#n4:Snapshot().Cells==0 and next(x4._orders)==nil,"Exit clears orders and all cells")

-- Gateway deduplicates successful commands even after they finish.
local ng,eg,xg,mg=setup(); ng:Create(7,"Seven",capital)
local time=0
local gateway=CommandService.new(ng,Config.Network,function() return time end,xg)
local reply=gateway:Handle(7,"Seven","Expand",target,1,25)
check(reply.Code=="ExpansionStarted" and reply.Sent==25,"Expand routed through validated gateway")
mg:Step(0.25); time=1
local before=ng:GetState(7).Troops
check(gateway:Handle(7,"Seven","Expand",target,1,75).Code=="DuplicateRequest","Replay rejected")
check(ng:GetState(7).Troops==before,"Replay cannot spend twice")
invariants(ng)
print(string.format("PASS: %d expansion/economy checks",checks))
