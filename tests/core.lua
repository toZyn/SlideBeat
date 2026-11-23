package.path='./?.lua;'..package.path
local M=require('core.model')
local G=require('core.gesture')
local C=require('core.catalog')
local function read(path) local f=assert(io.open(path)) local s=f:read('*a') f:close() return s end
local function check(condition,message) assert(condition,message) end
local total=0
for _,id in ipairs({'01-first-steps','02-neon-circuit','03-moonlit','04-redline'}) do
    local meta=C.meta(read('songs/'..id..'/meta.txt'))
    for _,difficulty in ipairs({'easy','normal','hard'}) do
        local notes=assert(C.chart(read('songs/'..id..'/'..difficulty..'.txt'),tonumber(meta.duration)))
        local game=M.new(notes,false)
        for _,note in ipairs(notes) do check(M.hit(game,note.dir,note.time)==1,'perfect chart run') end
        check(game.score==#notes*1000 and game.maxCombo==#notes and M.rank(game)=='S','score and combo')
        check(game.counts[4]==0 and M.accuracy(game)==100,'perfect accuracy')
        check(not notes[1].grade,'original chart must not be mutated')
        local practice=M.new(notes,true)
        M.update(practice,10000)
        check(not practice.failed and practice.counts[4]==#notes,'practice never fails')
        local fail=M.new(notes,false)
        M.update(fail,10000)
        check(fail.failed and fail.health==0,'life must cause failure')
        total=total+#notes
    end
end
local g=M.new({{time=1,dir=1},{time=1.5,dir=2},{time=2,dir=3},{time=2.5,dir=4}},false)
check(M.hit(g,1,0.2)==nil and g.index==1,'early stroke must not consume notes')
check(M.hit(g,1,1.08)==2,'good timing')
check(M.hit(g,2,1.64)==3,'late timing')
check(M.hit(g,4,2)==4 and g.combo==0,'wrong direction resets combo')
M.update(g,3)
check(g.counts[4]==2 and g.score==1100,'expiry and score')
local close=M.new({{time=1,dir=1},{time=1.1,dir=2}},true)
check(M.hit(close,2,1.1)==1 and close.counts[4]==1,'nearest note must avoid wrong old target')
local gesture=G.new()
check(not gesture:press('a',100,0,0,0,20),'press outside rejected')
check(gesture:press('a',0,0,0,0,20),'center press accepted')
check(not gesture:press('b',0,0,0,0,20),'second pointer rejected')
check(gesture:move('b',0,-100,0,0,80,20)==nil,'second pointer ignored')
check(gesture:move('a',0,-100,0,0,80,20)==1,'up stroke')
check(gesture:move('a',0,-120,0,0,80,20)==nil,'outside cannot retrigger')
check(gesture:move('a',0,100,0,0,80,20)==2,'crossing center between events rearms')
gesture:release()
check(gesture:move('a',100,0,0,0,80,20)==nil,'release clears gesture')
check(C.chart('1 1\n0.5 2',5)==nil,'unordered chart rejected')
check(C.chart('1 5',5)==nil,'invalid direction rejected')
check(C.chart('99 1',5)==nil,'out of range rejected')
check(C.chart('',5)==nil,'empty chart rejected')
local storage={}
love={filesystem={read=function(p) return storage[p] end,write=function(p,v) storage[p]=v return true end}}
local S=require('core.save')
S.load()
check(S.record('track','easy',1000,100,1),'first record')
check(not S.record('track','easy',500,50,1),'worse score rejected')
check(S.record('track','hard',400,40,1),'difficulties separate')
S.settings.offset=0.12
S.write()
S.settings.offset=0
S.records={}
S.load()
check(S.settings.offset==0.12 and S.records['track:easy'].score==1000,'save round trip')
storage['profile.txt']='setting offset 999\nsetting music -99\nrecord broken'
S.load()
check(S.settings.offset==0.3 and S.settings.music==0,'invalid preferences clamped')
package.loaded['screens.lifecycle_fixture']={enter=function(self) self.entered=true end}
local App=require('core.app')
App:switch('lifecycle_fixture')
local previous=App.screen
previous.finished=true
App:switch('lifecycle_fixture')
check(App.screen~=previous and App.screen.entered and not App.screen.finished,'every screen entry must have fresh instance state')
print('PASS: 12 full charts / '..total..' notes, scoring, failure, practice, gestures, validation and persistence')
