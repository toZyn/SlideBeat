io.stdout:setvbuf('no')
require 'loxel'
require 'funkin'
local host=require('loxel.lib.gamestate')
local elapsed,phase,resultTime=0,0,0
local addonScript,controller,current
local originalMouse,originalTouch
local function ensure()
    assert(addonScript and not addonScript.closed,'addon global script closed unexpectedly')
    assert(next(addonScript.__failedfunc)==nil,'addon callback failed')
end
local function enter(state)
    game.switchState(state,true)
    game.update(0.016)
    return game.getState()
end
local function frame(name)
    love.filesystem.createDirectory('captures')
    love.graphics.captureScreenshot('captures/'..name..'.png')
end
function love.load()
    if os.getenv('SLIDEBEAT_PORTRAIT_TEST') then love.window.setMode(360,800,{vsync=0})
    else love.window.setMode(1000,760,{vsync=0}) end
    controls=require('lib.baton').new({controls=table.clone(ClientPrefs.controls)})
    Toast.showPrints=false
    ClientPrefs.data.flashingLights=false
    ClientPrefs.data.menuMusicVolume=0
    game.init(Project,State)
    AtlasText.defaultFont=AtlasText.getFont('default',1)
    Addons.root='addons'
    Addons.all={{path='slidebeat',active=true}}
    Mods.currentMod=nil
    originalMouse,originalTouch=love.mousepressed,love.touchpressed
    game.onPreStateEnter=function(state) GlobalScripts.call('preStateEnter',state) end
    GlobalScripts.reload()
    addonScript=assert(GlobalScripts.scripts[1])
    ensure()
    current=enter(MainMenuState())
    GlobalScripts.call('update',0.016)
    assert(current.triggerChoices.slidebeat,'native main menu entry was not installed')
    local count=#current.menuItems
    GlobalScripts.call('update',0.016)
    assert(#current.menuItems==count,'menu entry duplicated')
    current.triggerChoices.slidebeat[2](current)
    game.update(0.016)
    current=game.getState()
    controller=current.owner
    assert(controller and current.mode=='home','menu did not open addon lobby')
    print('PASS: native Script, addon modules, main menu and lobby')
end
function love.update(dt)
    local ok,err=xpcall(function()
        elapsed=elapsed+dt
        if elapsed>45 then error('native test timeout at phase '..phase) end
        controls:update()
        GlobalScripts.call('update',dt)
        game.update(dt)
        if phase<8 then ensure() end
        current=game.getState()
        if phase==0 and elapsed>0.3 then
            current:options()
            phase=0.25
        elseif phase==0.25 then
            assert(current.mode=='options' and #current.members>0,'native options panel failed')
            current:remove(current.members[#current.members])
            print('PASS: native engine options panel')
            phase=0.5
        elseif phase==0.5 then
            phase=1
            local scale=current.view.scale
            love.mousepressed(current.view.w/2*scale,327*scale,1,false)
            assert(current.mode=='tutorial','tutorial button failed')
            local v=current.view
            local cx,cy,r=v:layout(1)
            for _,dir in ipairs(current.lesson) do
                local vector=({{0,-1},{0,1},{-1,0},{1,0}})[dir]
                love.touchpressed('test',cx*v.scale,cy*v.scale,0,0,1)
                love.touchmoved('test',(cx+vector[1]*r)*v.scale,(cy+vector[2]*r)*v.scale,0,0,1)
                love.touchreleased('test',cx*v.scale,cy*v.scale,0,0,0)
            end
            assert(current.lessonIndex==9,'touch tutorial failed')
            print('PASS: native touch events and tutorial')
        elseif phase==1 then
            phase=2
            controller:select()
        elseif phase==2 and current:is(FreeplayState) then
            local song=current.songs:getSelected()
            assert(song.songName=='sb-fixture','native selector did not discover fixture song')
            current:openSong(song)
            phase=3
        elseif phase==3 and current.owner==controller and current.mode=='playing' then
            assert(#current.run.notes==4,'native chart parser/group conversion failed')
            current:focus(false)
            assert(current.mode=='paused' and not current.instrument:isPlaying())
            current:resume()
            phase=4
        elseif phase==4 and current.mode=='playing' then
            local n=current.run.notes[current.run.index]
            if n then
                current.instrument:seek(n.time,'seconds')
                local dir=next(n.dirs)
                local v=current.view
                local cx,cy,r=v:layout(1)
                local vec=({{0,-1},{0,1},{-1,0},{1,0}})[dir]
                love.mousepressed(cx*v.scale,cy*v.scale,1,false)
                love.mousemoved((cx+vec[1]*r)*v.scale,(cy+vec[2]*r)*v.scale,0,0,false)
                if n.time==1 then
                    assert(#current.run.holds==1)
                    current:pause()
                    current:resume()
                    current:update(0.25)
                    assert(current.mode=='resume' and not current.instrument:isPlaying(),'sustain resume must wait for center contact')
                    love.mousepressed(cx*v.scale,cy*v.scale,1,false)
                    current.resumeTime=0
                    current:update(0)
                    assert(current.mode=='playing','sustain resume did not accept center contact')
                    current.instrument:seek(1.5,'seconds')
                    current:update(0)
                end
                love.mousereleased((cx+vec[1]*r)*v.scale,(cy+vec[2]*r)*v.scale,1,false)
                assert(current.run.counts[4]==0,'native gesture or sustain failed')
            elseif not current.testEnding then
                current.testEnding=true
                current.instrument:seek(current.duration-0.1,'seconds')
            end
        elseif phase==4 and current.mode=='results' then
            assert(current.run.score==5000 and current.run.counts[4]==0,'native result score incorrect')
            assert(game.save.data.slidebeat and next(game.save.data.slidebeat.records),'addon record was not saved')
            assert(Highscore.getScore('sb-fixture','normal')==0,'normal FNF score was polluted')
            print('PASS: native Freeplay, Parser, instrumental, mouse, hold, pause/resume, results and isolated record')
            resultTime=elapsed
            phase=4.5
        elseif phase==4.5 and elapsed-resultTime>0.3 then
            current:retry()
            phase=5
        elseif phase==5 and current.mode=='playing' then
            current.instrument:seek(current.duration-0.1,'seconds')
            current.run.practice=true
            current:update(0)
            current.testEnding=true
            phase=6
        elseif phase==6 and current.mode=='results' then
            print('PASS: consecutive addon runs reach results')
            current.mode='settings'
            phase=7
        elseif phase==7 then
            addonScript:close()
            assert(love.mousepressed==originalMouse and love.touchpressed==originalTouch,'input callbacks were not restored')
            for state in pairs(controller.menus) do
                if state.triggerChoices then assert(not state.triggerChoices.slidebeat,'menu entry remained after disabling') end
            end
            assert(not controller.active)
            print('PASS: disabling addon restores native input and removes integration')
            phase=8
        elseif phase==8 then
            assert(current:is(MainMenuState),'disabled addon did not return to the native main menu')
            assert(not current.triggerChoices.slidebeat,'disabled addon was reinstalled')
            local normal=FreeplayState()
            controller:beforeState(normal)
            assert(normal.openSong==FreeplayState.openSong,'ordinary Freeplay was changed after disabling')
            paths.async.stop()
            print('PASS: native state switching remains functional after sandbox closure')
            love.event.quit(0)
        end
    end,debug.traceback)
    if not ok then print('NATIVE ADDON FAIL '..err) love.event.quit(1) end
end
function love.draw()
    local ok,err=xpcall(function()
        game.draw()
        local st=game.getState()
        if st and st.owner then
            st.snapshots=st.snapshots or {}
            if not st.snapshots[st.mode] then st.snapshots[st.mode]=true frame(st.mode) end
        end
        if st and st.mode=='results' then frame('results') end
    end,debug.traceback)
    if not ok then print('NATIVE DRAW FAIL '..err) love.event.quit(1) end
end
function love.mousepressed() end
function love.mousemoved() end
function love.mousereleased() end
function love.touchpressed() end
function love.touchmoved() end
function love.touchreleased() end
function love.quit() end
function love.errorhandler(err) print('NATIVE BOOT FAIL '..tostring(err));return function() return 1 end end
