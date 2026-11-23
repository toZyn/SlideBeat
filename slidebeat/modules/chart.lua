local C={window=0.16}
local mapping={[0]=3,[1]=2,[2]=1,[3]=4}
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<math.huge end
function C.convert(chart)
    if type(chart)~='table' or type(chart.notes)~='table' or type(chart.notes.player)~='table' then return nil,'Chart has no player notefield' end
    local input={}
    for _,note in ipairs(chart.notes.player) do
        if not finite(note.t) or not finite(note.d) or note.d%1~=0 or note.t<0 then return nil,'Invalid player note timestamp or direction' end
        local length=note.l or 0
        if not finite(length) or length<0 then return nil,'Invalid sustain length' end
        input[#input+1]={time=note.t/1000,dir=mapping[note.d%4],ending=(note.t+length)/1000}
    end
    table.sort(input,function(a,b) return a.time==b.time and a.dir<b.dir or a.time<b.time end)
    local notes={}
    for _,note in ipairs(input) do
        local group=notes[#notes]
        if not group or math.abs(group.time-note.time)>0.001 then
            group={time=note.time,dirs={},ends={},count=0}
            notes[#notes+1]=group
        end
        group.dirs[note.dir]=true
        group.ends[note.dir]=math.max(group.ends[note.dir] or 0,note.ending)
        group.count=group.count+1
    end
    if #notes==0 then return nil,'This chart has no playable player notes' end
    return notes
end
function C.new(notes,practice)
    return {notes=notes,index=1,score=0,combo=0,maxCombo=0,health=1,judged=0,weight=0,counts={0,0,0,0},holds={},practice=practice,errors={}}
end
function C.judge(g,grade,delta)
    g.judged=g.judged+1
    g.counts[grade]=g.counts[grade]+1
    if grade==4 then g.combo=0 g.health=math.max(0,g.health-0.075)
    else
        local weight=({1,0.7,0.4})[grade]
        g.score=g.score+math.floor(1000*weight)
        g.weight=g.weight+weight
        g.combo=g.combo+1
        g.maxCombo=math.max(g.maxCombo,g.combo)
        g.health=math.min(1,g.health+0.018)
        if delta then g.errors[#g.errors+1]=delta*1000 end
    end
    if g.health<=0 and not g.practice then g.failed=true end
end
function C.update(g,time,holding)
    for i=#g.holds,1,-1 do
        local hold=g.holds[i]
        if time>=hold.ending-0.03 then C.judge(g,1) table.remove(g.holds,i)
        elseif not holding then C.judge(g,4) table.remove(g.holds,i) end
    end
    local missed=0
    while not g.failed and g.notes[g.index] and time-g.notes[g.index].time>C.window do
        C.judge(g,4)
        g.index=g.index+1
        missed=missed+1
    end
    return missed
end
function C.hit(g,dir,time,holding)
    C.update(g,time,holding)
    if g.failed then return end
    local n=g.notes[g.index]
    if not n or math.abs(time-n.time)>C.window then return end
    local target=g.index
    for i=g.index+1,#g.notes do
        if g.notes[i].time-time>C.window then break end
        if math.abs(g.notes[i].time-time)<math.abs(g.notes[target].time-time) then target=i end
    end
    while g.index<target and not g.failed do C.judge(g,4) g.index=g.index+1 end
    if g.failed then return 4 end
    n=g.notes[g.index]
    local delta=time-n.time
    local grade=not n.dirs[dir] and 4 or math.abs(delta)<=0.055 and 1 or math.abs(delta)<=0.105 and 2 or 3
    C.judge(g,grade,delta)
    if grade<4 and n.ends[dir]>n.time+0.05 and n.ends[dir]>time+0.03 then g.holds[#g.holds+1]={ending=n.ends[dir],dir=dir} end
    g.index=g.index+1
    return grade,delta*1000
end
function C.accuracy(g) return g.judged==0 and 100 or g.weight/g.judged*100 end
function C.rank(g)
    local a=C.accuracy(g)
    return a>=99.5 and 'S' or a>=95 and 'A' or a>=85 and 'B' or a>=70 and 'C' or 'D'
end
return C
