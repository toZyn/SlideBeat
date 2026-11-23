local U=require('core.ui')
local A=require('core.assets')
local G=require('core.gesture')
local T={}
local sequence={1,2,3,4,1,4,2,3}
function T:enter()
    self.gesture=G.new()
    self.index=1
    self.message='Press and hold inside the center circle.'
end
function T:draw(app)
    U.background({0.4,0.7,1},0.88)
    U.header('HOW TO PLAY','An interactive lesson',function() app:switch('menu') end)
    if self.index<=#sequence then
        U.center('STEP '..self.index..' / '..#sequence,132,22,{0.4,0.85,1})
        U.field(app.elapsed,{time=app.elapsed,dir=sequence[self.index]},self.gesture)
        U.center(self.message,U.h*0.78,18)
        U.center('Hold > slide > return to center > slide again.\nYou may also release and press the center again.',U.h*0.87,14,{0.65,0.75,0.88})
    else
        A.picture('sick',U.w/2,U.h*0.34,250,120)
        U.center('YOU HAVE THE MOVEMENT.',U.h*0.48,28)
        U.center('In a song, match the shrinking ring to the beat.\nThe next arrows appear below the playfield.',U.h*0.56,18,{0.7,0.8,0.9})
        U.button('PLAY FIRST STEPS',26,U.h-164,U.w-52,56,function() app.selection=1 app.difficulty=1 app.practice=true app:play() end)
        U.button('MUSIC SELECT',26,U.h-94,U.w-52,56,function() app:switch('select') end)
    end
end
function T:press(app,id,x,y)
    if self.index>#sequence then return false end
    local cx,cy,r,c=U.layout()
    if self.gesture:press(id,x,y,cx,cy,c) then self.message='Keep holding. Slide toward the bright arrow.' return true end
end
function T:move(app,id,x,y)
    if self.index>#sequence then return end
    local cx,cy,r,c=U.layout()
    local dir=self.gesture:move(id,x,y,cx,cy,r*0.70,c)
    if dir then
        if dir==sequence[self.index] then
            self.index=self.index+1
            A.sound('hitsound')
            self.message='Good. Return to the center, then follow the next arrow.'
        else self.message='Try the bright arrow. Return to center first.' end
    end
end
function T:release(app,id) if self.gesture.id==id then self.gesture:release() end end
function T:resize() self.gesture:release() end
function T:back(app) app:switch('menu') end
return T
