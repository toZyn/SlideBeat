local U=require('core.ui')
local S=require('core.save')
local M={}
function M:enter() self.page=0 end
function M:wheel(app,y) self.page=math.max(0,math.min(math.ceil(#app.songs/4)-1,self.page+(y>0 and -1 or 1))) end
function M:key(app,k) if k=='down' or k=='up' then self:wheel(app,k=='up' and 1 or -1) return true end end
function M:draw(app)
    U.background({0.7,0.5,1},0.86)
    U.header('RECORDS','Best completed runs / practice excluded',function() app:switch('menu') end)
    for row=1,4 do
        local song=app.songs[self.page*4+row]
        if not song then break end
        local y=126+(row-1)*132
        U.panel(26,y,U.w-52,118)
        U.text(song.title,44,y+12,28,song.color)
        for j,diff in ipairs({'easy','normal','hard'}) do
            local r=S.records[song.id..':'..diff]
            U.text(diff:upper()..'  '..(r and string.format('%07d / %.1f%%',r.score,r.accuracy) or '--'),44,y+43+(j-1)*21,14,{0.75,0.83,0.93})
        end
    end
    if #app.songs>4 then
        U.button('PREVIOUS',26,U.h-76,(U.w-64)/2,48,function() self:wheel(app,1) end)
        U.button('NEXT',U.w/2+6,U.h-76,(U.w-64)/2,48,function() self:wheel(app,-1) end)
    else U.center('Finish a track to set your first personal best.',U.h-44,14,{0.65,0.75,0.85}) end
end
function M:back(app) app:switch('menu') end
return M
