local M = {}
M.window = 0.16
function M.new(notes, practice)
    local copy = {}
    for i,n in ipairs(notes) do copy[i] = {time=n.time,dir=n.dir} end
    return {notes=copy,index=1,combo=0,maxCombo=0,score=0,weight=0,judged=0,health=1,counts={0,0,0,0},errors={},practice=practice}
end
function M.judge(g,grade,errorMs)
    local n = g.notes[g.index]
    if not n then return end
    n.grade = grade
    g.counts[grade] = g.counts[grade]+1
    g.judged = g.judged+1
    if grade==4 then
        g.combo=0
        g.health=math.max(0,g.health-0.075)
    else
        g.combo=g.combo+1
        g.maxCombo=math.max(g.maxCombo,g.combo)
        local weight=({1,0.7,0.4})[grade]
        g.weight=g.weight+weight
        g.score=g.score+math.floor(1000*weight)
        g.health=math.min(1,g.health+0.018)
        g.errors[#g.errors+1]=errorMs
    end
    g.index=g.index+1
    if g.health<=0 and not g.practice then g.failed=true end
end
function M.update(g,time)
    local count=0
    while not g.failed and g.notes[g.index] and time-g.notes[g.index].time>M.window do
        M.judge(g,4)
        count=count+1
    end
    return count
end
function M.hit(g,dir,time)
    M.update(g,time)
    if g.failed then return nil end
    local next=g.notes[g.index]
    if not next or math.abs(next.time-time)>M.window then return nil end
    local target=g.index
    for i=g.index+1,#g.notes do
        local n=g.notes[i]
        if n.time-time>M.window then break end
        if math.abs(n.time-time)<math.abs(g.notes[target].time-time) then target=i end
    end
    while g.index<target and not g.failed do M.judge(g,4) end
    if g.failed then return 4 end
    local n=g.notes[g.index]
    local delta=time-n.time
    local grade=n.dir~=dir and 4 or math.abs(delta)<=0.055 and 1 or math.abs(delta)<=0.105 and 2 or 3
    M.judge(g,grade,delta*1000)
    return grade,delta*1000
end
function M.accuracy(g) return g.judged==0 and 100 or g.weight/g.judged*100 end
function M.rank(g)
    local a=M.accuracy(g)
    return a>=99.5 and 'S' or a>=95 and 'A' or a>=85 and 'B' or a>=70 and 'C' or 'D'
end
return M
