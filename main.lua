local rhythm = require('rhythm')
local state, level, game, music = 'menu', 1
local clock, held, armed, pointer, px, py = 0, false, false, nil, 0, 0
local offset, volume, feedback, flash = 0, 0.65, '', 0
local best = {0, 0, 0}
local fonts, buttons = {}, {}
local colors = {{0.40,0.86,1},{1,0.61,0.39},{0.75,0.60,1},{0.49,0.94,0.70}}
local vectors = {{0,-1},{0,1},{-1,0},{1,0}}
local names = {'PULSE', 'FLOW', 'FLICK'}
local function layout()
    local w,h = love.graphics.getDimensions()
    return w/2, h*0.53, math.min(w*0.31,h*0.19), math.min(w,h)*0.065
end
local function text(s,y,font,color)
    love.graphics.setFont(fonts[font or 2])
    love.graphics.setColor(color or {0.90,0.93,0.96})
    love.graphics.printf(s,0,y,love.graphics.getWidth(),'center')
end
local function save()
    love.filesystem.write('settings.txt',table.concat({volume,offset,best[1],best[2],best[3]},' '))
end
local function release()
    held,armed,pointer = false,false,nil
end
local function start()
    music:stop()
    game = rhythm.new(level)
    clock, feedback, flash = 0, '', 0
    release()
    state = 'play'
    music:play()
end
local function pause()
    if state == 'play' then state = 'pause' music:pause() release()
    elseif state == 'pause' then state = 'play' music:play() release() end
end
local function button(label,x,y,w,h,action)
    buttons[#buttons+1] = {x=x,y=y,w=w,h=h,action=action}
    love.graphics.setColor(0.11,0.15,0.20)
    love.graphics.rectangle('fill',x,y,w,h,12,12)
    love.graphics.setColor(0.28,0.37,0.45)
    love.graphics.rectangle('line',x,y,w,h,12,12)
    love.graphics.setFont(fonts[2])
    love.graphics.setColor(0.92,0.96,1)
    love.graphics.printf(label,x,y+(h-fonts[2]:getHeight())/2,w,'center')
end
function love.load()
    love.graphics.setBackgroundColor(0.035,0.05,0.075)
    for i,size in ipairs({52,19,13,32}) do fonts[i] = love.graphics.newFont(size) end
    local data = love.filesystem.read('settings.txt')
    if data then
        local values = {}
        for n in data:gmatch('%S+') do values[#values+1] = tonumber(n) end
        volume = math.max(0,math.min(1,values[1] or volume))
        offset = math.max(-0.3,math.min(0.3,values[2] or offset))
        for i=1,3 do best[i] = values[i+2] or 0 end
    end
    music = love.audio.newSource('assets/pulse.ogg','stream')
    music:setVolume(volume)
    if os.getenv('SLIDEBEAT_SMOKE') then start() end
end
function love.update(dt)
    flash = math.max(0,flash-dt)
    if state == 'play' then
        if music:isPlaying() then clock = music:tell('seconds') end
        if rhythm.update(game,clock-offset)>0 then feedback,flash = 'MISS',0.35 end
        if clock >= 45 or (not music:isPlaying() and clock > 0) then
            state = 'results'
            music:stop()
            release()
            best[level] = math.max(best[level],game.score)
            save()
        end
    end
    if os.getenv('SLIDEBEAT_SMOKE') and love.timer.getTime() > (tonumber(os.getenv('SLIDEBEAT_SMOKE')) or 3) then love.event.quit() end
end
local function move(x,y)
    px,py = x,y
    if state ~= 'play' or not held then return end
    local cx,cy,r,center = layout()
    local dx,dy = x-cx,y-cy
    if dx*dx+dy*dy <= center*center then armed = true end
    if armed then
        local direction = rhythm.direction(dx,dy,r*0.70)
        if direction then
            feedback = rhythm.hit(game,direction,music:tell('seconds')-offset)
            flash,armed = 0.35,false
        end
    end
end
local function press(id,x,y)
    for _,b in ipairs(buttons) do
        if x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then b.action() return end
    end
    if state ~= 'play' or pointer then return end
    local cx,cy,r,center = layout()
    if (x-cx)^2+(y-cy)^2 <= center^2 then
        held,armed,pointer = true,true,id
        move(x,y)
    end
end
function love.mousepressed(x,y,b,touch) if b==1 and not touch then press('mouse',x,y) end end
function love.mousemoved(x,y,dx,dy,touch) if pointer=='mouse' and not touch then move(x,y) end end
function love.mousereleased(x,y,b,touch) if b==1 and pointer=='mouse' and not touch then release() end end
function love.touchpressed(id,x,y) press(id,x,y) end
function love.touchmoved(id,x,y) if pointer==id then move(x,y) end end
function love.touchreleased(id) if pointer==id then release() end end
function love.resize() release() end
function love.focus(focused) if not focused and state=='play' then pause() end end
function love.keypressed(key)
    if key=='escape' then
        if state=='play' or state=='pause' then pause() else state='menu' end
    elseif key=='space' then
        if state=='menu' or state=='results' then start() elseif state=='play' or state=='pause' then pause() end
    elseif key=='r' and (state=='results' or state=='pause') then start()
    elseif state=='menu' and (key=='left' or key=='right') then level=(level-1+(key=='right' and 1 or -1))%3+1 end
end
local function arrow(x,y,size,dir,color,active)
    love.graphics.push()
    love.graphics.translate(x,y)
    love.graphics.rotate(({0,math.pi,-math.pi/2,math.pi/2})[dir])
    love.graphics.setColor(color[1],color[2],color[3],active and 1 or 0.30)
    love.graphics.polygon('fill',0,-size,size*0.8,-size*0.1,size*0.32,-size*0.1,size*0.32,size,-size*0.32,size,-size*0.32,-size*0.1,-size*0.8,-size*0.1)
    love.graphics.pop()
end
function love.draw()
    buttons = {}
    local w,h = love.graphics.getDimensions()
    local bw = math.min(320,w-40)
    if state=='menu' then
        text('SLIDEBEAT',h*0.12,1)
        text('HOLD. SLIDE. REPEAT.',h*0.12+67,3,{0.49,0.75,0.85})
        text('Original track / 120 BPM / 46 seconds',h*0.30,3)
        button('<   '..names[level]..'   >',(w-bw)/2,h*0.38,bw,54,function() level=level%3+1 end)
        text(({'One beat at a time','Half-beat sequences','Fast quarter-beat flicks'})[level],h*0.38+66,3)
        button('PLAY',(w-bw)/2,h*0.55,bw,58,start)
        button('SETTINGS',(w-bw)/2,h*0.55+74,bw,48,function() state='settings' end)
        text('Hold in the center. Slide to the lit arrow on the beat.\nReturn to the center while holding for the next note.',h*0.82,3)
    elseif state=='settings' then
        text('SETTINGS',h*0.12,4)
        button('Volume: '..math.floor(volume*100)..'%',(w-bw)/2,h*0.30,bw,54,function() volume=(math.floor(volume*10+0.5)+1)%11/10 music:setVolume(volume) save() end)
        text('Timing offset: '..math.floor(offset*1000+0.5)..' ms',h*0.45,2)
        button('- 10 ms',w/2-bw/2,h*0.52,bw/2-6,50,function() offset=math.max(-0.3,offset-0.01) save() end)
        button('+ 10 ms',w/2+6,h*0.52,bw/2-6,50,function() offset=math.min(0.3,offset+0.01) save() end)
        text('Positive offset places the hit after the audio beat.',h*0.65,3)
        button('BACK',(w-bw)/2,h*0.77,bw,50,function() state='menu' end)
    elseif state=='results' then
        text('TRACK COMPLETE',h*0.12,4)
        text(string.format('%07d',game.score),h*0.27,1)
        text(string.format('Accuracy %.2f%%   /   Best combo %d',rhythm.accuracy(game),game.best),h*0.42,2)
        text(string.format('%d hits    %d misses\nPersonal best %d',game.hits,game.misses,best[level]),h*0.50,2)
        button('PLAY AGAIN',(w-bw)/2,h*0.67,bw,54,start)
        button('MENU',(w-bw)/2,h*0.67+68,bw,48,function() state='menu' end)
    else
        local cx,cy,r,center = layout()
        text(string.format('%07d   /   %.1f%%',game.score,rhythm.accuracy(game)),22,2)
        text(names[level]..'    /    '..game.combo..' COMBO',54,3)
        love.graphics.setColor(0.12,0.17,0.22)
        love.graphics.rectangle('fill',20,85,w-40,3)
        love.graphics.setColor(0.49,0.85,1)
        love.graphics.rectangle('fill',20,85,(w-40)*math.min(clock/45,1),3)
        local time = clock-offset
        local note = game.notes[game.index]
        for i,v in ipairs(vectors) do
            local x,y = cx+v[1]*r,cy+v[2]*r
            local active = note and note.direction==i and note.time-time<1.2
            love.graphics.setColor(0.12,0.16,0.21)
            love.graphics.circle('fill',x,y,center*0.88)
            arrow(x,y,center*0.48,i,colors[i],active)
            if active then
                love.graphics.setLineWidth(2)
                love.graphics.setColor(colors[i])
                love.graphics.circle('line',x,y,center*(0.92+math.max(0,note.time-time)*0.6))
            end
        end
        love.graphics.setColor(held and 0.48 or 0.2,held and 0.83 or 0.3,held and 0.94 or 0.4)
        love.graphics.circle('line',cx,cy,center)
        if held then love.graphics.setColor(0.5,0.85,1,0.6) love.graphics.line(cx,cy,px,py) end
        text(armed and 'SLIDE' or held and 'RETURN' or 'HOLD',cy-8,3)
        local upcoming = {}
        for i=game.index,math.min(#game.notes,game.index+5) do upcoming[#upcoming+1]=game.notes[i] end
        for i,n in ipairs(upcoming) do arrow(w/2+(i-(#upcoming+1)/2)*36,h*0.85,10,n.direction,colors[n.direction],true) end
        text(time<4 and tostring(math.max(1,math.ceil(4-time))) or (flash>0 and feedback or 'Return to center between slides'),h*0.93,2)
        button('II',w-65,108,45,38,pause)
        if state=='pause' then
            love.graphics.setColor(0.025,0.04,0.06,0.96)
            love.graphics.rectangle('fill',0,0,w,h)
            buttons={}
            text('PAUSED',h*0.25,1)
            button('RESUME',(w-bw)/2,h*0.44,bw,54,pause)
            button('RESTART',(w-bw)/2,h*0.44+68,bw,48,start)
            button('MENU',(w-bw)/2,h*0.44+130,bw,48,function() music:stop() release() state='menu' end)
        end
    end
end
