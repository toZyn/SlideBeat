local Factory={}
local host=game
local ipairs_=ipairs
local mouseAPI=love.mouse
function Factory.create(id)
    local Model=requireAddon(id,'chart')
    local Gesture=requireAddon(id,'gesture')
    local Profile=requireAddon(id,'profile')
    local View=requireAddon(id,'view')
    local Input=requireAddon(id,'input')
    local Mode=State:extend('SlideBeatState')
    function Mode:new(owner,mode,request)
        Mode.super.new(self)
        self.owner,self.mode,self.request=owner,mode,request
        self.skipTransIn,self.skipTransOut=true,true
        self.gesture=Gesture.new()
        self.sources={}
        self.clock,self.flash=0,0
        self.loadingStep=0
    end
    function Mode:enter()
        self.cursorVisible=mouseAPI.isVisible()
        mouseAPI.setVisible(true)
        self.view=View.new()
        self.bridge=Input.new(self)
        if self.mode=='song' then self.mode='loading'
        else util.playMenuMusic() end
    end
    function Mode:stopAudio()
        for _,source in ipairs_(self.sources) do source:stop() source:release() end
        self.sources={}
        self.instrument=nil
    end
    function Mode:dispose()
        if self.disposed then return end
        self.disposed=true
        if self.bridge then self.bridge:close() self.bridge=nil end
        self.gesture:clear()
        self:stopAudio()
        self.view=nil
        if self.cursorVisible~=nil then mouseAPI.setVisible(self.cursorVisible) end
    end
    function Mode:leave() self:dispose() end
    function Mode:loadStep()
        if self.loadingStep==0 then
            local chart,err=Parser.getChart(self.request.song,self.request.difficulty,{strict=true})
            if not chart then self.message=tostring(err) self.mode='error' return end
            local notes,reason=Model.convert(chart)
            if not notes then self.message=reason self.mode='error' return end
            self.chart=chart
            self.run=Model.new(notes,Profile.get().practice)
            self.bpm=tonumber(chart.bpm) or 100
            self.title=self.request.metadata and self.request.metadata.displayName or self.request.song
            self.loadingStep=1
        elseif self.loadingStep==1 then
            local asset=paths.getInst(self.request.song,self.request.difficulty) or paths.getInst(self.request.song)
            if not asset then self.message='No instrumental audio was found for '..self.request.song self.mode='error' return end
            self.instrument=asset:clone()
            self.sources[1]=self.instrument
            self.duration=self.instrument:getDuration()
            if self.run.notes[#self.run.notes].time>self.duration+0.16 then self.message='Player chart extends beyond the instrumental audio.' self:stopAudio() self.mode='error' return end
            self.loadingStep=2
        elseif self.loadingStep==2 then
            local used={}
            local chart=self.chart
            local difficulty=self.request.difficulty
            for _,name in ipairs_({chart.player1 or 'Player',chart.player2 or 'Opponent'}) do
                local asset=paths.getVoices(self.request.song,name..'-'..difficulty)
                    or paths.getVoices(self.request.song,name)
                    or paths.getVoices(self.request.song,name==chart.player1 and 'Player' or 'Opponent')
                if asset and not used[asset] then used[asset]=true self.sources[#self.sources+1]=asset:clone() end
            end
            if #self.sources==1 then
                local asset=paths.getVoices(self.request.song)
                if asset then self.sources[#self.sources+1]=asset:clone() end
            end
            self.loadingStep=3
        else
            if host.sound.music then host.sound.music:stop() end
            self.countdown=3*60/self.bpm
            self.mode='countdown'
        end
    end
    function Mode:startAudio()
        for i,source in ipairs_(self.sources) do
            source:setVolume((i==1 and ClientPrefs.data.musicVolume or ClientPrefs.data.vocalVolume or 100)/100)
            source:play()
        end
    end
    function Mode:pause()
        if self.mode~='playing' and self.mode~='countdown' and self.mode~='resume' then return end
        self.previousMode=self.mode
        self.mode='paused'
        self.gesture:clear()
        for _,source in ipairs_(self.sources) do source:pause() end
        self.view.focus=1
    end
    function Mode:resume()
        if self.previousMode=='countdown' then self.mode='countdown'
        else self.resumeTime=1 self.needsRegrip=#self.run.holds>0 self.mode='resume' end
    end
    function Mode:retry(practice)
        if practice~=nil then Profile.get().practice=practice Profile.save() end
        host.switchState(Mode(self.owner,'song',self.request))
    end
    function Mode:back()
        if self.mode=='playing' or self.mode=='countdown' or self.mode=='resume' then self:pause()
        elseif self.mode=='paused' then self:resume()
        elseif self.mode=='home' then host.switchState(MainMenuState())
        elseif self.mode=='loading' or self.mode=='error' or self.mode=='failed' or self.mode=='results' then self.owner:select()
        else self.mode='home' self.gesture:clear() end
    end
    function Mode:key(key)
        if key=='escape' or key=='acback' then self:back() return end
        if self.mode=='playing' or self.mode=='countdown' or self.mode=='resume' then
            if key=='space' or key=='p' or key=='return' then self:pause() end
            return
        end
        if self.mode=='paused' and (key=='p' or key=='space') then self:resume() return end
        self.view:key(key)
    end
    function Mode:update(dt)
        Mode.super.update(self,dt)
        self.flash=math.max(0,self.flash-dt)
        if self.mode=='loading' then
            local ok,err=pcall(self.loadStep,self)
            if not ok then self:stopAudio() self.message=tostring(err) self.mode='error' end
        elseif self.mode=='countdown' then
            self.countdown=self.countdown-dt
            if self.countdown<=0 then self:startAudio() self.mode='playing' end
        elseif self.mode=='resume' then
            if self.needsRegrip and not self.gesture.id then self.resumeTime=1
            else
                self.resumeTime=self.resumeTime-dt
                if self.resumeTime<=0 then self:startAudio() self.mode='playing' self.needsRegrip=false end
            end
        elseif self.mode=='playing' then
            local playing=self.instrument:isPlaying()
            if playing then self.clock=self.instrument:tell('seconds') end
            local missed=Model.update(self.run,self.clock-Profile.get().offset,self.gesture.id~=nil)
            if missed>0 then self.feedback,self.flash=4,0.35 end
            if self.run.failed then
                for _,source in ipairs_(self.sources) do source:pause() end
                self.mode='failed'
                self.gesture:clear()
            elseif not playing and self.clock>0 or self.clock>=self.duration-0.02 then
                Model.update(self.run,self.duration+1,self.gesture.id~=nil)
                for _,source in ipairs_(self.sources) do source:stop() end
                self.mode=self.run.failed and 'failed' or 'results'
                self.gesture:clear()
                if self.mode=='results' then self.record=Profile.record(self.request.song,self.request.difficulty,self.run,Model.accuracy(self.run)) end
            end
            if not love.window.hasFocus() then self:pause() end
        end
        if self.mode~='options' then
            if controls:pressed('back') then self:key('escape')
            elseif controls:pressed('pause') and (self.mode=='playing' or self.mode=='countdown' or self.mode=='resume') then self:pause()
            elseif controls:pressed('ui_up') then self:key('up')
            elseif controls:pressed('ui_down') then self:key('down')
            elseif controls:pressed('accept') then self:key('return') end
        end
    end
    function Mode:press(pointer,x,y)
        if not self.view then return end
        x,y=self.view:point(x,y)
        if self.view:click(x,y) then return end
        if self.mode=='playing' or self.mode=='tutorial' or self.mode=='resume' then
            local cx,cy,r,c=self.view:layout(Profile.get().size)
            self.gesture:press(pointer,x,y,cx,cy,c)
        end
    end
    function Mode:move(pointer,x,y)
        if not self.view then return end
        x,y=self.view:point(x,y)
        if self.mode~='playing' and self.mode~='tutorial' then return end
        local cx,cy,r,c=self.view:layout(Profile.get().size)
        local direction=self.gesture:move(pointer,x,y,cx,cy,r*0.70,c)
        if not direction then return end
        if self.mode=='tutorial' then
            if direction==self.lesson[self.lessonIndex] then self.lessonIndex=self.lessonIndex+1 end
        else
            self.feedback,self.errorMs=Model.hit(self.run,direction,self.instrument:tell('seconds')-Profile.get().offset,true)
            self.flash=self.feedback and 0.4 or 0
        end
    end
    function Mode:release(pointer,x,y)
        if self.gesture.id~=pointer then return end
        self:move(pointer,x,y)
        self.gesture:clear()
        if self.mode=='playing' then Model.update(self.run,self.instrument:tell('seconds')-Profile.get().offset,false) end
    end
    function Mode:resize()
        if self.view then self.view:resize() end
        self.gesture:clear()
        self:pause()
    end
    function Mode:focus(focused) if not focused then self:pause() end end
    function Mode:options()
        self.mode='options'
        local panel
        panel=Options(true,function()
            self.mode='home'
        end)
        panel:screenCenter()
        self:add(panel)
    end
    function Mode:draw()
        Mode.super.draw(self)
        local v=self.view
        if not v then return end
        v:begin()
        local mode=self.mode
        if mode=='home' then
            v:center('SLIDEBEAT',64,64)
            v:center('A radial rhythm mode for Light-Engine',145,18,{0.65,0.8,0.95})
            v:button('SELECT MUSIC',230,function() self.owner:select() end)
            v:button('HOW TO PLAY',300,function() self.mode='tutorial' self.lesson={1,2,3,4,1,4,2,3} self.lessonIndex=1 self.gesture:clear() end)
            v:button('SETTINGS',370,function() self.mode='settings' end)
            v:button('ENGINE OPTIONS',440,function() self:options() end)
            v:button('RECORDS',510,function() self.mode='records' self.recordPage=0 end)
            v:button('MAIN MENU',580,function() self:back() end)
            v:center('Uses your installed songs, difficulties and engine assets.',v.h-58,14)
        elseif mode=='loading' then
            v:center('LOADING SLIDEBEAT',v.h*0.34,40)
            v:center(self.request.song..' / '..self.request.difficulty,v.h*0.45,22)
            v:center(({'Parsing player chart','Opening instrumental','Opening vocals','Ready'})[self.loadingStep+1],v.h*0.53,18)
            love.graphics.setColor(0.4,0.85,1)
            love.graphics.rectangle('fill',28,v.h*0.65,(v.w-56)*self.loadingStep/3,6)
        elseif mode=='settings' then self:drawSettings()
        elseif mode=='records' then self:drawRecords()
        elseif mode=='tutorial' then
            v:center('HOW TO PLAY',30,40)
            local direction=self.lesson[self.lessonIndex]
            if direction then
                v:field(0,{time=0,dirs={[direction]=true}},self.gesture,Profile.get().size)
                v:center('STEP '..self.lessonIndex..' / '..#self.lesson,v.h*0.78,22)
                v:center('Hold the center. Slide to the bright arrow.\nReturn through the center without releasing.',v.h*0.84,18)
            else
                v:picture('sick',v.w/2,v.h*0.38,250,110)
                v:center('YOU HAVE THE MOVEMENT.',v.h*0.53,28)
                v:button('SELECT MUSIC',v.h-160,function() self.owner:select() end)
            end
            v:button('BACK',v.h-86,function() self:back() end)
        elseif mode=='results' then self:drawResults()
        elseif mode=='error' then
            v:center('CANNOT PLAY CHART',50,40)
            v:text(self.message,30,160,18,v.w-60)
            v:button('MUSIC SELECT',v.h-94,function() self.owner:select() end)
        elseif mode=='options' then
            v:center('ENGINE OPTIONS',24,28)
        else self:drawPlay() end
        v:finish()
    end
    function Mode:drawSettings()
        local v,p=self.view,Profile.get()
        v:center('SLIDEBEAT SETTINGS',42,28)
        v:center('Audio offset: '..math.floor(p.offset*1000+0.5)..' ms',136,22)
        v:button('- 10 MS',190,function() p.offset=math.max(-0.3,p.offset-0.01) Profile.save() end)
        v:button('+ 10 MS',256,function() p.offset=math.min(0.3,p.offset+0.01) Profile.save() end)
        v:button('PRACTICE: '..(p.practice and 'ON / NO RECORDS' or 'OFF'),340,function() p.practice=not p.practice Profile.save() end)
        v:button('PLAYFIELD SIZE: '..math.floor(p.size*100)..'%',410,function() p.size=p.size>=1.19 and 0.75 or math.min(1.2,p.size+0.05) Profile.save() end)
        v:center('Positive offset: gesture later than the beat.\nVolumes and display options use engine preferences.',500,14)
        v:button('BACK',v.h-92,function() self.mode='home' end)
    end
    function Mode:drawRecords()
        local v=self.view
        v:center('SLIDEBEAT RECORDS',38,28)
        local rows={}
        for key,value in pairs(Profile.get().records) do rows[#rows+1]={key=key,value=value} end
        table.sort(rows,function(a,b) return a.key<b.key end)
        if #rows==0 then v:center('Finish a track outside practice to set a record.',200,18) end
        for i=1,5 do
            local row=rows[self.recordPage*5+i]
            if row then
                local y=118+(i-1)*92
                v:panel(26,y,v.w-52,80)
                v:text(row.key,42,y+12,18,v.w-84)
                v:text(string.format('%07d / %.2f%% / %d combo',row.value.score,row.value.accuracy,row.value.combo),42,y+44,14,v.w-84)
            end
        end
        if #rows>5 then v:button('NEXT PAGE',v.h-162,function() self.recordPage=(self.recordPage+1)%math.ceil(#rows/5) end) end
        v:button('BACK',v.h-92,function() self.mode='home' end)
    end
    function Mode:drawPlay()
        local v,g=self.view,self.run
        v:text(self.title:sub(1,24),26,22,22,v.w-126)
        v:text(self.request.difficulty:upper()..(g.practice and ' / PRACTICE' or ''),28,60,14)
        v:text(string.format('%07d / %.2f%%',g.score,Model.accuracy(g)),26,98,22)
        v:text(g.combo..' COMBO',26,130,18)
        local time=self.clock-Profile.get().offset
        v:field(time,g.notes[g.index],self.gesture,Profile.get().size)
        if self.mode=='countdown' then
            local n=math.ceil(self.countdown/(60/self.bpm))
            v:picture(n>=3 and 'ready' or n==2 and 'set' or 'go',v.w/2,v.h*0.49,260,120)
        elseif self.mode=='resume' then v:center(self.needsRegrip and not self.gesture.id and 'HOLD CENTER' or 'READY',v.h*0.48,28) end
        if self.flash>0 and self.feedback then v:picture(({'sick','good','bad','shit'})[self.feedback],v.w/2,v.h*0.74,130,48) end
        local nextNote=g.notes[g.index]
        if nextNote and self.mode=='playing' then v:center(string.format('NEXT IN %.2f s',math.max(0,nextNote.time-time)),v.h*0.81,14) end
        if #g.holds>0 then v:center('KEEP HOLDING / '..#g.holds..' SUSTAIN',v.h*0.85,18,{0.45,0.95,0.7}) end
        love.graphics.setColor(0.15,0.25,0.35)
        love.graphics.rectangle('fill',28,v.h-64,v.w-56,8)
        love.graphics.setColor(0.4,0.9,0.7)
        love.graphics.rectangle('fill',28,v.h-64,(v.w-56)*g.health,8)
        v:center('MISSES '..g.counts[4]..' / '..math.floor(self.clock)..'s / '..math.floor(self.duration)..'s',v.h-42,14)
        if self.mode=='playing' or self.mode=='countdown' or self.mode=='resume' then
            v:button('II',18,function() self:pause() end,v.w-90,64)
        elseif self.mode=='paused' or self.mode=='failed' then
            love.graphics.setColor(0.015,0.025,0.05,0.97)
            love.graphics.rectangle('fill',0,0,v.w,v.h)
            v.buttons={}
            v:center(self.mode=='failed' and 'TRACK FAILED' or 'PAUSED',v.h*0.18,40)
            local y=v.h*0.36
            if self.mode=='paused' then v:button('RESUME',y,function() self:resume() end)
            else v:button('RETRY IN PRACTICE',y,function() self:retry(true) end) end
            v:button('RESTART TRACK',y+74,function() self:retry() end)
            v:button('MUSIC SELECT',y+148,function() self.owner:select() end)
        end
    end
    function Mode:drawResults()
        local v,g=self.view,self.run
        v:center('TRACK COMPLETE',36,40)
        v:center(self.title..' / '..self.request.difficulty,94,18)
        v:center(Model.rank(g),145,64,{0.4,0.85,1})
        v:center(string.format('%07d',g.score),232,40)
        v:center(string.format('%.2f%% / %d MAX COMBO',Model.accuracy(g),g.maxCombo),294,22)
        v:center(g.practice and 'PRACTICE / RECORD NOT SAVED' or self.record and 'NEW PERSONAL BEST' or 'SLIDEBEAT RECORD',338,14)
        for i,label in ipairs({'PERFECT','GOOD','EARLY / LATE','MISS'}) do
            v:text(label,42,396+(i-1)*34,18,v.w-160)
            v:text(g.counts[i],v.w-100,396+(i-1)*34,18,60,'right')
        end
        v:button('REPLAY',v.h-164,function() self:retry() end)
        v:button('MUSIC SELECT',v.h-90,function() self.owner:select() end)
    end
    return Mode
end
return Factory
