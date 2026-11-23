local U=require('core.ui')
local A=require('core.assets')
local C=require('core.catalog')
local L={}
function L:enter(app,data)
    A.stopMusic()
    self.data,self.step,self.elapsed=data,0,0
end
function L:update(app,dt)
    self.elapsed=self.elapsed+dt
    if self.step==0 then
        self.notes,self.error=C.load(self.data.song,self.data.difficulty)
        self.step=1
    elseif self.step==1 then
        if not self.notes then app:error(self.error) return end
        local ok,source=pcall(love.audio.newSource,self.data.song.path..'music.ogg','stream')
        if not ok then app:error(source) return end
        self.data.source=source
        self.data.notes=self.notes
        self.step=2
    elseif self.step==2 then
        self.step=3
    elseif self.elapsed>0.15 then
        local data=self.data
        self.data=nil
        app:switch('play',data)
    end
end
function L:draw()
    U.background(self.data.song.color,0.86)
    U.center('LOADING',U.h*0.33,40)
    U.center(self.data.song.title,U.h*0.43,28)
    U.center(({'Reading chart','Opening audio stream','Preparing playfield','Ready'})[self.step+1],U.h*0.51,18,{0.7,0.8,0.9})
    love.graphics.setColor(0.25,0.4,0.6)
    love.graphics.rectangle('fill',40,U.h*0.62,U.w-80,6)
    love.graphics.setColor(0.4,0.85,1)
    love.graphics.rectangle('fill',40,U.h*0.62,(U.w-80)*self.step/3,6)
end
function L:back(app) app:switch('select') end
function L:leave()
    if self.data and self.data.source then self.data.source:release() end
end
return L
