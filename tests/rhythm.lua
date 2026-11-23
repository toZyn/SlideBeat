package.path = './?.lua;' .. package.path
local r = require('rhythm')
assert(r.direction(0,0,10)==nil)
assert(r.direction(0,-10,10)==1)
assert(r.direction(0,10,10)==2)
assert(r.direction(-10,0,10)==3)
assert(r.direction(10,0,10)==4)
for level=1,3 do
    local g=r.new(level)
    local previous=-1
    for _,n in ipairs(g.notes) do
        assert(n.time>previous and n.direction>=1 and n.direction<=4)
        previous=n.time
        assert(r.hit(g,n.direction,n.time)=='PERFECT')
    end
    assert(g.hits==#g.notes and g.misses==0 and r.accuracy(g)==100)
end
local g=r.new(1)
assert(r.hit(g,1,0)=='EARLY' and g.index==1)
assert(r.hit(g,2,4)=='WRONG' and g.misses==1)
assert(r.update(g,100)==#g.notes-1 and g.misses==#g.notes)
assert(r.accuracy(g)==0)
g=r.new(1)
assert(r.hit(g,1,4.1)=='GOOD')
assert(r.hit(g,4,4.66)=='LATE / EARLY')
assert(g.score==1100 and g.combo==2)
print('PASS: direction, charts, timing, misses, score and accuracy')
