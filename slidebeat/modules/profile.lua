local P={}
local engine=game
function P.get()
    local data=engine.save.data
    if type(data.slidebeat)~='table' then data.slidebeat={records={},practice=false,offset=0,size=1} end
    local p=data.slidebeat
    if type(p.records)~='table' then p.records={} end
    p.offset=math.max(-0.3,math.min(0.3,tonumber(p.offset) or 0))
    p.size=math.max(0.75,math.min(1.2,tonumber(p.size) or 1))
    return p
end
function P.save() return engine.save.bind('funkin') end
function P.key(song,diff) return tostring(Mods and Mods.currentMod or '_base')..'/'..paths.formatToSongPath(song)..':'..tostring(diff):lower() end
function P.record(song,diff,g,accuracy)
    local p=P.get()
    if g.practice or g.failed then return false end
    local key=P.key(song,diff)
    local old=p.records[key]
    if not old or g.score>old.score or g.score==old.score and accuracy>old.accuracy then
        p.records[key]={score=g.score,accuracy=accuracy,combo=g.maxCombo}
        P.save()
        return true
    end
    return false
end
return P
