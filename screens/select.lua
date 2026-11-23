local U=require('core.ui')
local A=require('core.assets')
local S=require('core.save')
local C=require('core.catalog')
local M={}
function M:preview(app)
    local song=app.songs[app.selection]
    if song then
        local source,err=A.music(song.path..'music.ogg',true,song.preview)
        if not source then app:error(err) end
    end
end
function M:enter(app) self:preview(app) end
function M:change(app,delta)
    app.selection=(app.selection-1+delta)%#app.songs+1
    A.sound('scrollMenu')
    self:preview(app)
end
function M:diff(app,delta) app.difficulty=(app.difficulty-1+delta)%3+1 A.sound('scrollMenu') end
function M:draw(app)
    local song=app.songs[app.selection]
    U.background(song.color,0.80)
    U.header('MUSIC',string.format('%02d / %02d   -   Preview playing',app.selection,#app.songs),function() app:switch('menu') end)
    local start=math.max(1,math.min(app.selection-1,#app.songs-2))
    for row=0,2 do
        local i=start+row
        local item=app.songs[i]
        if item then
            local y=124+row*88
            U.button('',26,y,U.w-52,76,function() app.selection=i self:preview(app) end,i==app.selection)
            A.icon(item.icon,68,y+38,52)
            U.text(item.title,108,y+13,28,i==app.selection and item.color or nil,U.w-160)
            U.text(item.artist..'  /  '..item.bpm..' BPM',108,y+47,14,{0.65,0.74,0.86},U.w-160)
        end
    end
    local diff=({'easy','normal','hard'})[app.difficulty]
    local record=S.records[song.id..':'..diff]
    local notes,err=C.load(song,diff)
    U.panel(26,396,U.w-52,128)
    U.text(song.description,44,412,18,nil,U.w-88)
    U.text(string.format('%d:%02d  /  %s notes',math.floor(song.duration/60),song.duration%60,notes and #notes or '?'),44,463,14,{0.65,0.8,0.95})
    U.text(record and string.format('BEST %07d  /  %.2f%%',record.score,record.accuracy) or 'PERSONAL BEST: --',44,491,14,{0.8,0.84,0.9})
    U.button('<',26,542,56,46,function() self:diff(app,-1) end)
    U.button(diff:upper(),94,542,U.w-188,46,function() self:diff(app,1) end)
    U.button('>',U.w-82,542,56,46,function() self:diff(app,1) end)
    U.button(app.practice and 'PRACTICE: ON / NO RECORDS' or 'PRACTICE: OFF',26,602,U.w-52,44,function() app.practice=not app.practice end)
    U.button('PLAY '..song.title:upper(),26,U.h-82,U.w-52,56,function() if notes then app:play() else app:error(err) end end)
end
function M:key(app,key)
    if key=='up' then self:change(app,-1)
    elseif key=='down' then self:change(app,1)
    elseif key=='left' then self:diff(app,-1)
    elseif key=='right' then self:diff(app,1)
    elseif key=='return' or key=='space' then app:play()
    elseif key=='p' then app.practice=not app.practice
    else return false end
    return true
end
function M:wheel(app,y) self:change(app,y>0 and -1 or 1) end
function M:back(app) app:switch('menu') end
return M
