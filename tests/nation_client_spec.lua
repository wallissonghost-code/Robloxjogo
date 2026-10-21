-- Exercise the real client controller against the real server gateway with a fake
-- transport/timer. This checks UI/network flow, not Roblox rendering or device input.
local saved = {game=game, script=script, require=require, task=task, Color3=Color3}
local function signal()
    local s = {listeners={}}
    function s:Connect(callback)
        local connection = {active=true}
        function connection:Disconnect() self.active=false end
        self.listeners[#self.listeners+1] = {callback=callback,connection=connection}
        return connection
    end
    function s:Fire(...)
        for _, listener in ipairs(self.listeners) do
            if listener.connection.active then listener.callback(...) end
        end
    end
    return s
end
local Config = dofile("src/shared/Config.lua")
local grid = dofile("src/shared/MapGrid.lua").new(Config.Map, dofile("src/shared/WorldDefinition.lua"))
local nations = dofile("src/server/NationService.lua").new(dofile("src/server/MapService.lua").new(grid),Config.Nations)
local now, timers = 0, {}
local gateway = dofile("src/server/CommandService.lua").new(nations,Config.Network,function() return now end)
local transport = {OnClientEvent=signal(), sent={}}
function transport:FireServer(...)
    self.sent[#self.sent+1] = {...}
end
local userId = 80
local services = {
    Players={LocalPlayer={UserId=userId}},
    ReplicatedStorage={WaitForChild=function(_,name) assert(name=="NationProtocol"); return transport end},
}
game = {GetService=function(_,name) return assert(services[name]) end}
script = {Parent={NationReplica="Replica"}}
require = function(name) assert(name=="Replica"); return dofile("src/client/NationReplica.lua") end
task = {delay=function(delay,callback) timers[#timers+1]={at=now+delay,callback=callback} end}
Color3 = {fromRGB=function(r,g,b) return {r,g,b} end}
local function advance(seconds)
    now=now+seconds
    local due, pending = {}, {}
    for _, timer in ipairs(timers) do
        if timer.at<=now then due[#due+1]=timer else pending[#pending+1]=timer end
    end
    timers=pending
    for _,timer in ipairs(due) do timer.callback() end
end
local view = {FocusCell=function(self,id) self.focus=id end,
    SetSelection=function(self,id) self.selection=id end,
    ApplyNationState=function(self,replica) self.owners=replica.Owners end}
local status,hint,action = {},{},{Activated=signal()}
local client = dofile("src/client/NationClient.lua").new(view,grid,Config,status,hint,action)
local count = 0
local function check(value,message) count=count+1; assert(value,message) end
local function deliverNext(dropResult)
    local args=table.remove(transport.sent,1)
    local reply,delta=gateway:Handle(userId,"Test player",table.unpack(args))
    if delta then transport.OnClientEvent:Fire(delta) end
    if reply and not (dropResult and reply.Kind=="Result") then transport.OnClientEvent:Fire(reply) end
end
check(not action.Active and #transport.sent==1, "Founding disabled until sync")
deliverNext()
check(client.Synced and not action.Active, "Synced spectator still needs valid selection")
local a,b=grid.LandIds[150],grid.LandIds[300]
client:Inspect(a)
check(action.Active and view.selection==a, "Land selection enables confirmation")
check(nations:GetOwner(a)==nil, "Selection alone cannot claim")
-- Another client wins the selected cell before confirmation reaches server.
local delta=assert(nations:Create(81,"Opponent",a))
transport.OnClientEvent:Fire(delta)
check(not action.Active, "Remote occupancy invalidates confirmation")
client:Inspect(b)
action.Activated:Fire()
check(client.Pending and not action.Active, "Pending command blocks repeated taps")
local requests=#transport.sent
action.Activated:Fire()
check(#transport.sent==requests, "No duplicate pending command")
check(view.owners[b]==nil, "No optimistic ownership")
deliverNext(true)
check(view.owners[b]==userId and view.focus==b, "Authoritative ownership colors and focuses capital")
check(client.Pending~=nil, "Missing result is still pending")
advance(8)
check(not client.Pending and not client.Synced and not action.Active, "Timeout requests resync")
deliverNext()
check(client.Synced and action.Active and action.Text=="Minha capital", "Snapshot restores usable controls")
action.Activated:Fire()
check(#transport.sent==0, "My capital action is local focus only")
transport.OnClientEvent:Fire({Kind="Result",RequestId=999,Code="InvalidLand"})
check(client.Synced and action.Text=="Minha capital", "Unrelated result ignored")
client:RequestSync()
local sent=#transport.sent
client:Destroy()
advance(12)
check(#transport.sent==sent, "Destroyed client stops retries")
game,script,require,task,Color3 = saved.game,saved.script,saved.require,saved.task,saved.Color3
print(string.format("PASS: %d founding client/server flow checks",count))
