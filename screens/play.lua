local U=require('core.ui')
local A=require('core.assets')
local S=require('core.save')
local Model=require('core.model')
local Gesture=require('core.gesture')
local P={}
function P:enter(app,data)
    self.data=data
    self.source=data.source
    self.game=Model.new(data.notes,data.practice)
    self.gesture=Gesture.new()
    self.clock,self.feedbackTime,self.particles=0,0,{}
    self.mode='countdown'
    self.countdown=3*60/data.song.bpm
    self.source:setVolume(S.settings.music)
end
function P:pause()
    if self.mode=='playing' or self.mode=='countdown' or self.mode=='resume' then
        self.previousMode=self.mode
        self.mode='pause'
        self.source:pause()
        self.gesture:release()
    end
end
function P:resume()
    if self.previousMode=='countdown' then self.mode='countdown'
    else self.mode='resume' self.resumeTime=1 end
end
function P:finish(app)
    if self.finished then return end
    self.finished=true
    self.source:stop()
    app:switch('results',{song=self.data.song,difficulty=self.data.difficulty,practice=self.data.practice,game=self.game})
end
function P:update(app,dt)
    self.feedbackTime=math.max(0,self.feedbackTime-dt)
    for i=#self.particles,1,-1 do
        local p=self.particles[i]
        p.life=p.life-dt
        p.x,p.y=p.x+p.vx*dt,p.y+p.vy*dt
        if p.life<=0 then table.remove(self.particles,i) end
    end
    if self.mode=='countdown' then
        self.countdown=self.countdown-dt
        if self.countdown<=0 then self.source:play() self.mode='playing' end
    elseif self.mode=='resume' then
        self.resumeTime=self.resumeTime-dt
        if self.resumeTime<=0 then self.source:play() self.mode='playing' end
    elseif self.mode=='playing' then
        local playing=self.source:isPlaying()
        if playing then self.clock=self.source:tell('seconds') end
        local missed=Model.update(self.game,self.clock-S.settings.offset)
        if missed>0 then self.feedback=4 self.feedbackTime=0.3 end
        if self.game.failed then
            self.mode='failed'
            self.source:pause()
            self.gesture:release()
        elseif (not playing and self.clock>0) or self.clock>=self.source:getDuration()-0.03 then
            Model.update(self.game,self.data.song.duration+1)
            if self.game.failed then self.mode='failed' self.source:stop()
            else self:finish(app) end
        end
    end
end
function P:hit(dir)
    local grade,error=Model.hit(self.game,dir,self.source:tell('seconds')-S.settings.offset)
    if not grade then return end
    self.feedback,self.feedbackTime,self.errorMs=grade,0.45,error
    if grade<4 then
        if S.settings.hitsound==1 then A.sound('hitsound') end
        if S.settings.motion==1 then
            local cx,cy,r=U.layout()
            local v=({{0,-1},{0,1},{-1,0},{1,0}})[dir]
            for i=1,8 do
                local angle=i*math.pi/4
                self.particles[#self.particles+1]={x=cx+v[1]*r,y=cy+v[2]*r,vx=math.cos(angle)*90,vy=math.sin(angle)*90,life=0.32,color=U.colors[dir]}
            end
        end
    end
end
function P:press(app,id,x,y)
    if self.mode~='playing' then return false end
    local cx,cy,r,c=U.layout()
    return self.gesture:press(id,x,y,cx,cy,c)
end
function P:move(app,id,x,y)
    if self.mode~='playing' then return end
    local cx,cy,r,c=U.layout()
    local dir=self.gesture:move(id,x,y,cx,cy,r*0.70,c)
    if dir then self:hit(dir) end
end
function P:release(app,id) if self.gesture.id==id then self.gesture:release() end end
function P:draw(app)
    local g=self.game
    U.background(self.data.song.color,S.settings.dim)
    U.text(self.data.song.title,26,24,28,self.data.song.color,U.w-110)
    U.text(self.data.difficulty:upper()..(self.data.practice and ' / PRACTICE' or ''),28,60,14,{0.7,0.8,0.9})
    U.text(string.format('%07d  /  %.2f%%',g.score,Model.accuracy(g)),26,92,22)
    U.text(g.combo..' COMBO',26,122,18,{0.6,0.8,0.95})
    if self.mode=='playing' or self.mode=='countdown' or self.mode=='resume' then
        U.button('II',U.w-90,25,64,48,function() self:pause() end)
    end
    local time=self.clock-S.settings.offset
    U.field(time,g.notes[g.index],self.gesture)
    for _,p in ipairs(self.particles) do
        love.graphics.setColor(p.color[1],p.color[2],p.color[3],p.life/0.32)
        love.graphics.circle('fill',p.x,p.y,4)
    end
    if self.mode=='countdown' then
        local n=math.ceil(self.countdown/(60/self.data.song.bpm))
        A.picture(n>=3 and 'ready' or n==2 and 'set' or 'go',U.w/2,U.h*0.48,math.min(280,U.w-60),110)
    elseif self.mode=='resume' then U.center('READY',U.h*0.48,40) end
    if self.feedbackTime>0 and self.mode=='playing' then
        A.picture(({'sick','good','bad','shit'})[self.feedback],U.w/2,U.h*0.70,135,52)
        if self.errorMs and self.feedback<4 then U.center(string.format('%+d ms',self.errorMs),U.h*0.73+24,14,{0.7,0.8,0.9}) end
    end
    for i=g.index,math.min(#g.notes,g.index+5) do
        local x=U.w/2+(i-g.index-2.5)*42
        A.arrow(g.notes[i].dir,x,U.h*0.81,24,true,U.colors[g.notes[i].dir])
    end
    local healthImage=A.images.healthBar
    love.graphics.setColor(1,1,1)
    love.graphics.draw(healthImage,36,U.h*0.88-10,0,(U.w-72)/healthImage:getWidth(),20/healthImage:getHeight())
    love.graphics.setColor(0.35,0.87,0.68)
    love.graphics.rectangle('fill',36,U.h*0.88-4,(U.w-72)*g.health,8,3)
    U.center(string.format('LIFE %d%%   /   MISSES %d',math.floor(g.health*100),g.counts[4]),U.h*0.88+18,14,{0.65,0.78,0.88})
    local duration=self.source:getDuration()
    love.graphics.setColor(0.2,0.3,0.45)
    love.graphics.rectangle('fill',26,U.h-26,U.w-52,3)
    love.graphics.setColor(self.data.song.color)
    love.graphics.rectangle('fill',26,U.h-26,(U.w-52)*math.min(1,self.clock/duration),3)
    if self.mode=='pause' or self.mode=='failed' then self:overlay(app) end
end
function P:overlay(app)
    love.graphics.setColor(0.015,0.025,0.05,0.96)
    love.graphics.rectangle('fill',0,0,U.w,U.h)
    U.buttons={}
    U.center(self.mode=='failed' and 'TRACK FAILED' or 'PAUSED',U.h*0.15,40)
    U.center(self.data.song.title,U.h*0.15+62,22,self.data.song.color)
    local width=math.min(440,U.w-52)
    local x=(U.w-width)/2
    local y=U.h*0.34
    if self.mode=='pause' then
        U.button('RESUME',x,y,width,54,function() self:resume() end)
        U.button('RESTART TRACK',x,y+70,width,54,function() app:play() end)
        U.button('DIFFICULTY: '..self.data.difficulty:upper(),x,y+140,width,54,function() app.difficulty=app.difficulty%3+1 app:play() end)
        U.button('HIT SOUNDS: '..(S.settings.hitsound==1 and 'ON' or 'OFF'),x,y+210,width,54,function() S.settings.hitsound=1-S.settings.hitsound S.write() end)
        U.button('MUSIC SELECT',x,y+280,width,54,function() app:switch('select') end)
    else
        U.center('Take a breath. The next run is yours.',y-32,14,{0.7,0.8,0.9})
        U.button('TRY AGAIN',x,y+20,width,54,function() app:play() end)
        U.button('RETRY IN PRACTICE',x,y+90,width,54,function() app.practice=true app:play() end)
        U.button('MUSIC SELECT',x,y+160,width,54,function() app:switch('select') end)
    end
end
function P:key(app,k)
    if k=='space' or k=='p' then
        if self.mode=='pause' then self:resume() elseif self.mode=='playing' or self.mode=='countdown' or self.mode=='resume' then self:pause() end
        return true
    end
    if k=='r' and (self.mode=='pause' or self.mode=='failed') then app:play() return true end
    if self.mode=='playing' or self.mode=='countdown' or self.mode=='resume' then return true end
end
function P:back(app)
    if self.mode=='pause' then self:resume()
    elseif self.mode=='failed' then app:switch('select')
    else self:pause() end
end
function P:suspend() self:pause() end
function P:resize() self.gesture:release() self:pause() end
function P:leave()
    self.gesture:release()
    self.source:stop()
    self.source:release()
end
return P
