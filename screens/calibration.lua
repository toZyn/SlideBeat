local U=require('core.ui')
local A=require('core.assets')
local S=require('core.save')
local C={}
function C:enter()
    A.stopMusic()
    self.elapsed,self.lastBeat,self.samples,self.value=0,-1,{},nil
end
function C:update(app,dt)
    self.elapsed=self.elapsed+dt
    local beat=math.floor(self.elapsed/0.5)
    if beat~=self.lastBeat then self.lastBeat=beat A.sound('hitsound') end
end
function C:tap()
    if self.elapsed<2 then return end
    local delta=self.elapsed-math.floor(self.elapsed/0.5+0.5)*0.5
    if math.abs(delta)>0.22 then return end
    self.samples[#self.samples+1]=delta
    if #self.samples>16 then table.remove(self.samples,1) end
    local sorted={}
    for i,v in ipairs(self.samples) do sorted[i]=v end
    table.sort(sorted)
    local n=#sorted
    self.value=n%2==1 and sorted[(n+1)/2] or (sorted[n/2]+sorted[n/2+1])/2
end
function C:draw(app)
    U.background({0.5,0.7,0.95},0.90)
    U.header('CALIBRATE','Listen first. Tap in rhythm.',function() app:switch('settings') end)
    local pulse=1-(self.elapsed%0.5)/0.5
    love.graphics.setColor(0.4,0.84,1,0.15+pulse*0.6)
    love.graphics.circle('fill',U.w/2,U.h*0.40,65+pulse*10)
    A.arrow(1,U.w/2,U.h*0.40,75,true,U.colors[1])
    U.center(self.elapsed<2 and 'LISTEN...' or 'TAP / SPACE',U.h*0.56,28)
    U.center('Match the click rather than reacting to the picture.',U.h*0.65,14,{0.7,0.8,0.9})
    U.center(#self.samples..' taps  /  '..(self.value and string.format('%+d ms',self.value*1000) or '--'),U.h*0.71,22)
    if #self.samples>=8 then
        U.button('APPLY OFFSET',26,U.h-90,U.w-52,56,function() S.settings.offset=math.max(-0.3,math.min(0.3,self.value)) S.write() app:switch('settings') end)
    else U.center('At least 8 taps to apply',U.h-72,18,{0.6,0.7,0.85}) end
end
function C:press(app,id,x,y)
    if y>=150 and y<U.h-150 then self:tap() return true end
end
function C:key(app,k) if k=='space' then self:tap() return true end end
function C:back(app) app:switch('settings') end
function C:leave(app) app:menuMusic() end
return C
