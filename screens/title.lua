local U=require('core.ui')
local A=require('core.assets')
local T={}
function T:enter(app) app:menuMusic() end
function T:draw(app)
    U.backgroundImage='menuBG'
    U.background({0.55,0.7,1},0.70)
    U.backgroundImage=nil
    local cx,cy=U.w/2,U.h*0.35
    local size=math.min(110,U.w*0.2)
    local motion=require('core.save').settings.motion==1 and math.sin(app.elapsed*2)*8 or 0
    A.arrow(1,cx,cy-size-motion,76,true,U.colors[1])
    A.arrow(2,cx,cy+size+motion,76,true,U.colors[2])
    A.arrow(3,cx-size-motion,cy,76,true,U.colors[3])
    A.arrow(4,cx+size+motion,cy,76,true,U.colors[4])
    U.center('SLIDEBEAT',U.h*0.60,64)
    U.center('HOLD THE CENTER. FOLLOW THE BEAT.',U.h*0.60+75,14,{0.65,0.85,1})
    local bw=math.min(360,U.w-64)
    U.button('ENTER / TAP TO START',(U.w-bw)/2,U.h*0.80,bw,58,function() app:switch('menu') end)
    U.center('v2.0.0  /  Built by Zyn',U.h-30,14,{0.6,0.7,0.8})
end
function T:key(app,k) if k=='space' or k=='return' then app:switch('menu') return true end end
function T:back(app) love.event.quit() end
return T
