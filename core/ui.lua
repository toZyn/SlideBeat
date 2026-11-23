local A=require('core.assets')
local S=require('core.save')
local U={buttons={},focus=1,colors={{0.35,0.84,1},{1,0.55,0.55},{0.76,0.53,1},{0.4,0.95,0.68}}}
function U.resize()
    local sw,sh=love.graphics.getDimensions()
    local x,y,w,h=love.window.getSafeArea()
    if not w or w<=0 then x,y,w,h=0,0,sw,sh end
    U.scale=math.min(w/480,h/760)
    U.x,U.y,U.w,U.h=x,y,w/U.scale,h/U.scale
end
function U.point(x,y) return (x-U.x)/U.scale,(y-U.y)/U.scale end
function U.begin()
    U.buttons={}
    love.graphics.clear(0.025,0.03,0.05)
    love.graphics.push()
    love.graphics.translate(U.x,U.y)
    love.graphics.scale(U.scale)
end
function U.finish() love.graphics.pop() end
function U.text(s,x,y,size,color,width,align)
    love.graphics.setFont(A.fonts[size or 22] or love.graphics.getFont())
    love.graphics.setColor(color or {0.94,0.96,1})
    love.graphics.printf(tostring(s),x,y,width or U.w-x-24,align or 'left')
end
function U.center(s,y,size,color) U.text(s,20,y,size,color,U.w-40,'center') end
function U.panel(x,y,w,h,alpha)
    love.graphics.setColor(0.035,0.055,0.09,alpha or 0.94)
    love.graphics.rectangle('fill',x,y,w,h,14)
    love.graphics.setColor(0.3,0.5,0.68,0.28)
    love.graphics.rectangle('line',x,y,w,h,14)
end
function U.background(color,dim)
    local im=A.images[U.backgroundImage or "menuDesat"]
    if im then
        local iw,ih=im:getDimensions()
        local scale=math.max(U.w/iw,U.h/ih)*1.04
        love.graphics.setColor(color or {0.48,0.64,0.85})
        local motion=S.settings.motion==1 and math.sin(love.timer.getTime()*0.25)*6 or 0
        love.graphics.draw(im,U.w/2+motion,U.h/2,0,scale,scale,iw/2,ih/2)
    end
    love.graphics.setColor(0.015,0.025,0.045,dim or 0.83)
    love.graphics.rectangle('fill',0,0,U.w,U.h)
end
function U.button(label,x,y,w,h,action,selected)
    local index=#U.buttons+1
    U.buttons[index]={label=label,x=x,y=y,w=w,h=h,action=action}
    U.panel(x,y,w,h)
    if selected or U.focus==index then
        love.graphics.setColor(0.36,0.84,1,0.8)
        love.graphics.rectangle('fill',x,y+10,3,h-20,2)
    end
    U.text(label,x+16,y+(h-22)/2,22,selected and {0.4,0.88,1} or nil,w-32,'center')
end
function U.header(title,subtitle,back)
    U.text(title,28,26,40)
    if subtitle then U.text(subtitle,30,76,14,{0.65,0.73,0.85}) end
    if back then U.button('BACK',U.w-112,28,84,44,back) end
end
function U.click(x,y)
    for i,b in ipairs(U.buttons) do
        if x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then
            U.focus=i
            A.sound('confirmMenu')
            b.action()
            return true
        end
    end
    return false
end
function U.key(key)
    if #U.buttons==0 then return end
    if key=='up' or key=='down' or key=='tab' then
        U.focus=(U.focus-1+(key=='up' and -1 or 1))%#U.buttons+1
        A.sound('scrollMenu')
        return true
    elseif key=='return' or key=='space' then
        local b=U.buttons[U.focus] or U.buttons[1]
        A.sound('confirmMenu')
        b.action()
        return true
    end
end
function U.layout()
    local radius=math.min(U.w*0.28,U.h*0.21)*S.settings.radius
    local center=math.max(30,math.min(40,U.w*0.07))
    return U.w/2,U.h*0.48,radius,center
end
function U.field(time,nextNote,gesture)
    local cx,cy,r,c=U.layout()
    local vec={{0,-1},{0,1},{-1,0},{1,0}}
    local pulse=S.settings.motion==1 and 1+math.sin(time*math.pi*4)*0.025 or 1
    love.graphics.setLineWidth(2)
    for i,v in ipairs(vec) do
        local x,y=cx+v[1]*r,cy+v[2]*r
        local active=nextNote and nextNote.dir==i and nextNote.time-time<=1.2
        love.graphics.setColor(0.08,0.12,0.19,0.9)
        love.graphics.circle('fill',x,y,c*1.18)
        A.arrow(i,x,y,c*1.65*(active and pulse or 1),active,U.colors[i])
        if active then
            local delta=math.max(0,nextNote.time-time)
            love.graphics.setColor(U.colors[i][1],U.colors[i][2],U.colors[i][3],0.8)
            love.graphics.circle('line',x,y,c*(1.22+math.min(1.2,delta)*0.7))
        end
    end
    love.graphics.setColor(0.45,0.84,1,gesture.id and 0.9 or 0.35)
    love.graphics.circle('line',cx,cy,c)
    if gesture.id then
        love.graphics.line(cx,cy,gesture.x,gesture.y)
        love.graphics.circle('fill',gesture.x,gesture.y,5)
    end
    U.text(gesture.armed and 'SLIDE' or gesture.id and 'RETURN' or 'HOLD',cx-c-8,cy-7,14,nil,c*2+16,'center')
end
return U
