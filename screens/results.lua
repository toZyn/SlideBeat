local U=require('core.ui')
local A=require('core.assets')
local S=require('core.save')
local Model=require('core.model')
local R={}
function R:enter(app,data)
    self.data=data
    self.newRecord=false
    if not data.practice then self.newRecord=S.record(data.song.id,data.difficulty,data.game.score,Model.accuracy(data.game),data.game.maxCombo) end
    app:menuMusic()
end
function R:draw(app)
    local d=self.data
    local g=d.game
    U.background(d.song.color,0.88)
    U.header('RESULTS',d.song.title..' / '..d.difficulty:upper())
    U.center(Model.rank(g),122,64,{0.4,0.9,1})
    U.center(string.format('%07d',g.score),208,40)
    U.center(string.format('ACCURACY %.2f%%  /  MAX COMBO %d',Model.accuracy(g),g.maxCombo),268,18)
    U.center(d.practice and 'PRACTICE / RECORD NOT SAVED' or self.newRecord and 'NEW PERSONAL BEST' or 'TRACK COMPLETE',305,14,{0.7,0.85,0.95})
    if g.counts[4]==0 then U.center('FULL COMBO',334,18,{0.45,0.95,0.7}) end
    U.panel(26,376,U.w-52,146)
    for i,label in ipairs({'PERFECT','GOOD','EARLY / LATE','MISS'}) do
        U.text(label,46,390+(i-1)*29,18,{0.7,0.8,0.92},U.w-180)
        U.text(g.counts[i],U.w-120,390+(i-1)*29,18,nil,70,'right')
    end
    local mean=0
    for _,v in ipairs(g.errors) do mean=mean+v end
    mean=#g.errors>0 and mean/#g.errors or 0
    U.center(string.format('Average timing: %+.0f ms',mean),550,14,{0.7,0.8,0.9})
    love.graphics.setColor(0.3,0.45,0.6)
    love.graphics.line(48,592,U.w-48,592)
    love.graphics.setColor(0.4,0.85,1)
    for _,v in ipairs(g.errors) do
        local x=48+(math.max(-160,math.min(160,v))+160)/320*(U.w-96)
        love.graphics.line(x,586,x,598)
    end
    U.button('REPLAY',26,U.h-142,(U.w-64)/2,52,function() app:play() end)
    U.button('NEXT TRACK',U.w/2+6,U.h-142,(U.w-64)/2,52,function() app.selection=app.selection%#app.songs+1 app:play() end)
    U.button('MUSIC SELECT',26,U.h-76,U.w-52,50,function() app:switch('select') end)
end
function R:back(app) app:switch('select') end
return R
