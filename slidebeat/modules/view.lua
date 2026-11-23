local V={}
V.__index=V
V.colors={{0.35,0.84,1},{1,0.55,0.55},{0.76,0.53,1},{0.4,0.95,0.68}}
function V.new()
    local self=setmetatable({fonts={},images={},buttons={},focus=1},V)
    for _,size in ipairs({14,18,22,28,40,64}) do self.fonts[size]=assert(paths.getFont('vcr.ttf',size),'Light-Engine VCR font is unavailable') end
    for _,name in ipairs({'sick','good','bad','shit','ready','set','go'}) do self.images[name]=paths.getImage('skins/default/'..name) end
    self.background=paths.getImage('menus/menuDesat')
    self.arrows=assert(paths.getImage('skins/default/NOTE_assets'),'Default arrow texture is unavailable')
    local xml=assert(love.filesystem.read(paths.getPath('images/skins/default/NOTE_assets.xml')))
    local frame
    for block in xml:gmatch('<SubTexture%s+(.-)/>') do
        if block:match('name="confirm0000"') then
            frame={}
            for k,v in block:gmatch('(%w+)="([^"]+)"') do frame[k]=tonumber(v) or v end
            break
        end
    end
    assert(frame,'Default arrow frame confirm0000 is unavailable')
    self.frame=frame
    self.quad=love.graphics.newQuad(frame.x,frame.y,frame.width,frame.height,self.arrows:getDimensions())
    self:resize()
    return self
end
function V:resize()
    local w,h=love.graphics.getDimensions()
    self.scale=math.min(w/480,h/760)
    self.w,self.h=w/self.scale,h/self.scale
end
function V:point(x,y) return x/self.scale,y/self.scale end
function V:begin()
    self.buttons={}
    love.graphics.push('all')
    love.graphics.origin()
    love.graphics.setScissor()
    love.graphics.scale(self.scale)
    if self.background then
        local w,h=self.background:getDimensions()
        local scale=math.max(self.w/w,self.h/h)
        love.graphics.setColor(0.48,0.67,0.85)
        love.graphics.draw(self.background,self.w/2,self.h/2,0,scale,scale,w/2,h/2)
    end
    love.graphics.setColor(0.015,0.025,0.045,0.86)
    love.graphics.rectangle('fill',0,0,self.w,self.h)
end
function V:finish() love.graphics.pop() end
function V:text(text,x,y,size,width,align,color)
    love.graphics.setFont(self.fonts[size or 22])
    love.graphics.setColor(color or {0.93,0.96,1})
    love.graphics.printf(tostring(text),x,y,width or self.w-x-26,align or 'left')
end
function V:center(text,y,size,color) self:text(text,20,y,size,self.w-40,'center',color) end
function V:panel(x,y,w,h)
    love.graphics.setColor(0.025,0.045,0.075,0.95)
    love.graphics.rectangle('fill',x,y,w,h,12)
    love.graphics.setColor(0.3,0.5,0.7,0.4)
    love.graphics.rectangle('line',x,y,w,h,12)
end
function V:button(label,y,action,x,width)
    width=width or math.min(460,self.w-52)
    x=x or (self.w-width)/2
    local index=#self.buttons+1
    self.buttons[index]={x=x,y=y,w=width,h=54,action=action}
    self:panel(x,y,width,54)
    if self.focus==index then
        love.graphics.setColor(0.4,0.85,1)
        love.graphics.rectangle('fill',x,y+10,3,34)
    end
    self:text(label,x+12,y+16,22,width-24,'center')
end
function V:click(x,y)
    for i,b in ipairs(self.buttons) do
        if x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then self.focus=i self.buttons={} b.action() return true end
    end
end
function V:key(key)
    if #self.buttons==0 then return end
    if key=='up' or key=='down' then self.focus=(self.focus-1+(key=='up' and -1 or 1))%#self.buttons+1 return true end
    if key=='return' or key=='space' then
        local action=(self.buttons[self.focus] or self.buttons[1]).action
        self.buttons={}
        action()
        return true
    end
end
function V:picture(name,x,y,w,h)
    local image=self.images[name]
    if not image then return end
    local iw,ih=image:getDimensions()
    local scale=math.min(w/iw,h/ih)
    love.graphics.setColor(1,1,1)
    love.graphics.draw(image,x,y,0,scale,scale,iw/2,ih/2)
end
function V:arrow(dir,x,y,size,bright)
    local color=V.colors[dir]
    love.graphics.setColor(color[1],color[2],color[3],bright and 1 or 0.35)
    love.graphics.draw(self.arrows,self.quad,x,y,({0,math.pi,-math.pi/2,math.pi/2})[dir],size/self.frame.width,size/self.frame.height,self.frame.width/2,self.frame.height/2)
end
function V:layout(size)
    return self.w/2,self.h*0.49,math.min(self.w*0.27,self.h*0.20)*(size or 1),math.max(30,math.min(40,self.w*0.07))
end
function V:field(time,note,gesture,size)
    local cx,cy,r,c=self:layout(size)
    for dir,v in ipairs({{0,-1},{0,1},{-1,0},{1,0}}) do
        local x,y=cx+v[1]*r,cy+v[2]*r
        local bright=note and note.dirs[dir] and note.time-time<1.2
        self:arrow(dir,x,y,c*1.7,bright)
        if bright then
            love.graphics.setColor(V.colors[dir])
            love.graphics.setLineWidth(2)
            love.graphics.circle('line',x,y,c*(1.15+math.min(1.2,math.max(0,note.time-time))*0.7))
        end
    end
    love.graphics.setColor(0.4,0.85,1,gesture.id and 1 or 0.4)
    love.graphics.circle('line',cx,cy,c)
    if gesture.id then love.graphics.line(cx,cy,gesture.x,gesture.y) end
    self:text(gesture.armed and 'SLIDE' or gesture.id and 'RETURN' or 'HOLD',cx-c-8,cy-7,14,c*2+16,'center')
end
return V
