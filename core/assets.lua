local A={iconQuads={},images={},fonts={},sounds={},frames={},tasks={},done=0}
local base='assets/light/'
function A.prepare()
    for _,name in ipairs({'menuBG','menuDesat','notes','ready','set','go','sick','good','bad','shit','healthBar','bf','pico','dad'}) do
        local key=name
        A.tasks[#A.tasks+1]={name='Texture: '..key,run=function() A.images[key]=love.graphics.newImage(base..'images/'..key..'.png') end}
    end
    for _,size in ipairs({14,18,22,28,40,64}) do
        local n=size
        A.tasks[#A.tasks+1]={name='Font: '..n,run=function() A.fonts[n]=love.graphics.newFont(base..'fonts/vcr.ttf',n) end}
    end
    for _,name in ipairs({'scrollMenu','confirmMenu','cancelMenu','hitsound'}) do
        local key=name
        A.tasks[#A.tasks+1]={name='Sound: '..key,run=function() A.sounds[key]=love.audio.newSource(base..'sounds/'..key..'.ogg','static') end}
    end
    A.tasks[#A.tasks+1]={name='Arrow atlas',run=function()
        local text=assert(love.filesystem.read(base..'images/notes.xml'))
        local image=A.images.notes
        for block in text:gmatch('<SubTexture%s+(.-)/>') do
            local p={}
            for k,v in block:gmatch('(%w+)="([^"]+)"') do p[k]=tonumber(v) or v end
            A.frames[p.name]={quad=love.graphics.newQuad(p.x,p.y,p.width,p.height,image:getDimensions()),w=p.width,h=p.height}
        end
    end}
end
function A.step()
    local task=A.tasks[A.done+1]
    if not task then return true end
    A.phase=task.name
    local ok,err=pcall(task.run)
    if not ok then A.error=tostring(err) return false end
    A.done=A.done+1
    return A.done==#A.tasks
end
function A.sound(name)
    local s=A.sounds[name]
    if s then s:stop() s:setVolume(require('core.save').settings.sfx) s:play() end
end
function A.stopMusic()
    if A.current then A.current:stop() A.current:release() A.current=nil end
end
function A.music(path,loop,position)
    A.stopMusic()
    local ok,source=pcall(love.audio.newSource,path,'stream')
    if not ok then return nil,tostring(source) end
    A.current=source
    source:setLooping(loop or false)
    source:setVolume(require('core.save').settings.music)
    if position then source:seek(math.max(0,math.min(source:getDuration()-0.1,position)),'seconds') end
    source:play()
    return source
end
function A.picture(name,x,y,w,h,color)
    local image=A.images[name]
    if not image then return end
    local iw,ih=image:getDimensions()
    local scale=math.min(w/iw,(h or w)/ih)
    love.graphics.setColor(color or {1,1,1})
    love.graphics.draw(image,x,y,0,scale,scale,iw/2,ih/2)
end
function A.arrow(dir,x,y,size,active,color)
    local f=A.frames['confirm0000']
    if not f then return end
    love.graphics.setColor(color[1],color[2],color[3],active and 1 or 0.42)
    love.graphics.draw(A.images.notes,f.quad,x,y,({0,math.pi,-math.pi/2,math.pi/2})[dir],size/f.w,size/f.h,f.w/2,f.h/2)
end
function A.icon(name,x,y,size)
    local im=A.images[name] or A.images.bf
    if not im then return end
    local w,h=im:getDimensions()
    local quad=A.iconQuads[name]
    if not quad then quad=love.graphics.newQuad(0,0,math.min(w,h),h,w,h) A.iconQuads[name]=quad end
    love.graphics.setColor(1,1,1)
    love.graphics.draw(im,quad,x,y,0,size/h,size/h,h/2,h/2)
end
return A
