local A=require('core.assets')
local U=require('core.ui')
local S=require('core.save')
local C=require('core.catalog')
local App={name='boot',elapsed=0,selection=1,difficulty=2,practice=false}
function App:load(args)
    S.load()
    love.window.setFullscreen(S.settings.fullscreen==1,'desktop')
    U.resize()
    A.prepare()
    self.bootFont=love.graphics.newFont(18)
    for i,v in ipairs(args or {}) do if v=='--test' then self.test=true end end
    if self.test and os.getenv('SLIDEBEAT_TEST_SIZE') then
        local w,h=os.getenv('SLIDEBEAT_TEST_SIZE'):match('(%d+)x(%d+)')
        if w and h then love.window.setMode(tonumber(w),tonumber(h),{resizable=true}) U.resize() end
    end
end
function App:switch(name,data)
    if self.screen and self.screen.leave then self.screen:leave(self) end
    self.name=name
    self.screen=setmetatable({}, {__index=require('screens.'..name)})
    U.focus=1
    U.buttons={}
    self.transition=0.18
    if self.screen.enter then self.screen:enter(self,data) end
end
function App:error(message)
    self:switch('error',tostring(message))
end
function App:menuMusic()
    if self.songs[2] then A.music(self.songs[2].path..'music.ogg',true,8) end
end
function App:play()
    if not self.songs[self.selection] then return end
    self:switch('load',{song=self.songs[self.selection],difficulty=({'easy','normal','hard'})[self.difficulty],practice=self.practice})
end
function App:update(dt)
    self.elapsed=self.elapsed+dt
    self.transition=math.max(0,(self.transition or 0)-dt)
    if self.name=='boot' then
        if A.error then return end
        if A.step() then
            self.songs,self.catalogErrors=C.scan()
            if #self.songs==0 then self:error('No valid songs were found.') else self:switch('title') end
        end
    elseif self.screen and self.screen.update then self.screen:update(self,dt) end
    if self.test then
        local ok,err=pcall(require('tests.runtime').update,self,dt)
        if not ok then print('FAIL: '..tostring(err)..'\n'..debug.traceback()) love.event.quit(1) end
    end
end
function App:draw()
    U.begin()
    if self.name=='boot' then
        love.graphics.setFont(self.bootFont)
        love.graphics.setColor(0.8,0.9,1)
        love.graphics.printf('SLIDEBEAT\n\n'..(A.error or A.phase or 'Preparing assets'),20,U.h*0.4,U.w-40,'center')
        love.graphics.rectangle('line',40,U.h*0.65,U.w-80,6)
        love.graphics.rectangle('fill',40,U.h*0.65,(U.w-80)*A.done/math.max(1,#A.tasks),6)
    elseif self.screen then self.screen:draw(self) end
    if self.transition and self.transition>0 then
        love.graphics.setColor(0.02,0.03,0.05,self.transition/0.18)
        love.graphics.rectangle('fill',0,0,U.w,U.h)
    end
    if S.error then U.center('Save failed: '..S.error,U.h-28,14,{1,0.4,0.4}) end
    U.finish()
    if self.test then require('tests.runtime').afterDraw(self) end
end
function App:key(key,repeated)
    if key=='f11' then
        local f=not love.window.getFullscreen()
        love.window.setFullscreen(f,'desktop')
        S.settings.fullscreen=f and 1 or 0
        S.write()
        return
    end
    if self.name=='boot' then return end
    if key=='escape' or key=='acback' then
        if self.screen.back then self.screen:back(self) end
        return
    end
    if self.screen.key and self.screen:key(self,key,repeated) then return end
    U.key(key)
end
function App:press(id,x,y)
    if self.name=='boot' then return end
    x,y=U.point(x,y)
    if self.screen.press and self.screen:press(self,id,x,y) then return end
    U.click(x,y)
end
function App:move(id,x,y)
    if self.screen and self.screen.move then self.screen:move(self,id,U.point(x,y)) end
end
function App:release(id,x,y)
    if self.screen and self.screen.release then self.screen:release(self,id,U.point(x,y)) end
end
function App:wheel(y) if self.screen and self.screen.wheel then self.screen:wheel(self,y) end end
function App:suspend() if self.screen and self.screen.suspend then self.screen:suspend(self) end end
function App:resize()
    U.resize()
    if self.screen and self.screen.resize then self.screen:resize(self) end
end
return App
