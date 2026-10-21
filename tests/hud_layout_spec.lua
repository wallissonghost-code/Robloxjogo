-- Exercise actual responsive layout over safe-area dimensions, without Roblox rendering.
local saved=UDim2
UDim2={fromOffset=function(x,y) return {X=x,Y=y} end}
local Hud=dofile("src/client/StrategyHud.lua")
local checks=0
local function check(v,m) checks=checks+1; assert(v,m) end
for _,size in ipairs({{320,460},{390,760},{768,980},{844,350},{1366,690},{620,250}}) do
    local hud={Root={AbsoluteSize={X=size[1],Y=size[2]}},Panel={},Viewport={}}
    Hud.Layout(hud)
    local p,v=hud.Panel,hud.Viewport
    for _,r in ipairs({p,v}) do
        check(r.Position.X>=0 and r.Position.Y>=54,"HUD inside safe area")
        check(r.Position.X+r.Size.X<=size[1] and r.Position.Y+r.Size.Y<=size[2],"No clipped map or panel")
        check(r.Size.X>0 and r.Size.Y>0,"Positive viewport sizes")
    end
    check(v.Position.X+v.Size.X<=p.Position.X or v.Position.Y+v.Size.Y<=p.Position.Y,"Map and controls do not overlap")
    check(p.Size.X/5-8>=44,"Percent buttons retain mobile touch width")
end
UDim2=saved
print(string.format("PASS: %d mobile HUD geometry checks",checks))
