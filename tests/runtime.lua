io.stdout:setvbuf('no')
local U=require('core.ui')
local A=require('core.assets')
local T={index=1,elapsed=0,started=false,steps={}}
local function point(x,y) return U.x+x*U.scale,U.y+y*U.scale end
local function add(action,ready,capture,wait)
    T.steps[#T.steps+1]={action=action,ready=ready,capture=capture,wait=wait or 0.35}
end
add(function(app) assert(app.name=='title') end,nil,'01-title')
add(function(app) app:switch('menu') end,nil,'02-menu')
add(function(app) app.selection=2 app:switch('select') end,nil,'03-music')
add(function(app) app:switch('settings') end,nil,'04-settings')
add(function(app) app:switch('calibration') end,function(app)
    local s=app.screen
    for i=1,12 do s.elapsed=2+i*0.5+0.04 s:tap() end
    assert(math.abs(s.value-0.04)<0.001)
    return true
end,'05-calibration')
add(function(app) app:switch('records') end,nil,'06-records')
add(function(app) app:switch('credits') end,nil,'07-credits')
add(function(app) app:switch('tutorial') end,nil,'08-tutorial')
add(function(app)
    local cx,cy,r=U.layout()
    local vec={{0,-1},{0,1},{-1,0},{1,0}}
    for _,dir in ipairs({1,2,3,4,1,4,2,3}) do
        app:press('test',point(cx,cy))
        local v=vec[dir]
        app:move('test',point(cx+v[1]*r,cy+v[2]*r))
        app:release('test',point(cx,cy))
    end
    assert(app.screen.index==9,'interactive tutorial must complete')
end,nil,'09-tutorial-complete')
add(function(app) app.selection=1 app.difficulty=2 app.practice=false app:play() end,function(app) return app.name=='play' and app.screen.mode=='playing' end,nil,0)
add(function(app) app.screen.source:seek(20,'seconds') end,function(app) return app.screen.mode=='failed' end,'10-failed',0.3)
add(function(app) app.practice=true app:play() end,function(app) return app.name=='play' and app.screen.mode=='playing' end,nil,0)
add(function(app)
    local cx,cy=U.layout()
    app:press('test',point(cx,cy))
    app:suspend()
    assert(app.screen.mode=='pause' and not app.screen.source:isPlaying())
    assert(not app.screen.gesture.id,'suspend clears touch')
end,nil,'11-paused')
add(function(app) app:key('p') end,function(app) return app.screen.mode=='playing' end,nil,0)
for track=1,(os.getenv('SLIDEBEAT_TEST_SHORT') and 1 or 4) do
    local selected=track
    add(function(app) app.selection=selected app.difficulty=3 app.practice=true app:play() end,function(app) return app.name=='play' and app.screen.mode=='playing' end,'12-play-'..track,0.3)
    add(function() end,function(app)
        if app.name=='results' then
            assert(app.screen.data.game.counts[4]==0,'full runtime run must have zero misses')
            assert(app.screen.data.game.score==#app.screen.data.game.notes*1000,'all runtime notes must be perfect')
            return true
        end
        local s=app.screen
        if s.mode~='playing' then return false end
        local note=s.game.notes[s.game.index]
        if not note then
            if not s.testEndSeek then s.source:seek(s.source:getDuration()-0.1,'seconds') s.testEndSeek=true end
            return false
        end
        if s.game.index%100==0 then print('Playing '..s.data.song.title..' note '..s.game.index..'/'..#s.game.notes) end
        s.source:seek(note.time,'seconds')
        local cx,cy,r=U.layout()
        local v=({{0,-1},{0,1},{-1,0},{1,0}})[note.dir]
        app:press('test',point(cx,cy))
        app:move('test',point(cx+v[1]*r,cy+v[2]*r))
        app:release('test',point(cx,cy))
        assert(s.feedback==1,'runtime gesture must hit perfectly')
        return false
    end,'13-results-'..track,0)
end
add(function(app)
    app:switch('select')
    app.practice=false
    app:switch('records')
end,nil,'14-final-records')
function T.update(app,dt)
    if app.name=='boot' then return end
    local step=T.steps[T.index]
    if not step then print('PASS: real LOVE screen flow, tutorial, failure, pause/resume and '..(os.getenv('SLIDEBEAT_TEST_SHORT') and 'one complete hard chart run' or 'four complete hard chart runs')) love.event.quit(0) return end
    if not T.started then
        T.started=true
        T.elapsed=0
        T.captureAt=nil
        step.action(app)
        return
    end
    T.elapsed=T.elapsed+dt
    if T.elapsed>45 then error('Runtime step timeout: '..T.index..' / '..app.name..' / '..tostring(app.screen.mode)..' / '..tostring(app.screen.game and app.screen.game.index)) end
    if T.elapsed>=step.wait and (not step.ready or step.ready(app)) then
        if step.capture then
            T.captureAt=T.captureAt or T.elapsed+0.25
            if T.elapsed<T.captureAt then return end
        end
        T.capture=step.capture
        print('Runtime step '..T.index..' passed ('..app.name..')')
        T.index=T.index+1
        T.started=false
    end
end
function T.afterDraw()
    if T.capture then
        love.filesystem.createDirectory('test-captures')
        love.graphics.captureScreenshot('test-captures/'..T.capture..'.png')
        T.capture=nil
    end
end
return T
