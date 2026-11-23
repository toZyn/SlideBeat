local C={cache={}}
function C.meta(text)
    local out={}
    for line in (text..'\n'):gmatch('(.-)\r?\n') do
        local key,value=line:match('^([%w_]+)%s*=%s*(.-)%s*$')
        if key then out[key]=value end
    end
    return out
end
function C.chart(text,duration)
    local notes,last={},-1
    for line in (text..'\n'):gmatch('(.-)\r?\n') do
        if line:match('%S') and not line:match('^%s*#') then
            local t,d=line:match('^%s*([%d%.]+)%s+([1-4])%s*$')
            t,d=tonumber(t),tonumber(d)
            if not t or t~=t or t<=last or t<0 or t>duration-0.2 then return nil,'Invalid or unordered note: '..line end
            notes[#notes+1]={time=t,dir=d}
            last=t
        end
    end
    if #notes==0 then return nil,'Chart has no notes' end
    return notes
end
function C.scan()
    local songs,errors={},{}
    for _,id in ipairs(love.filesystem.getDirectoryItems('songs')) do
        if id:match('^[%w_-]+$') and love.filesystem.getInfo('songs/'..id..'/meta.txt') then
            local base='songs/'..id..'/'
            local data=C.meta(love.filesystem.read(base..'meta.txt') or '')
            local bpm,duration=tonumber(data.bpm),tonumber(data.duration)
            if bpm and bpm>=30 and bpm<=400 and duration and duration>5 and duration<=1800 and data.title and love.filesystem.getInfo(base..'music.ogg') then
                local color={}
                for n in (data.color or '90 190 255'):gmatch('%d+') do color[#color+1]=math.min(255,tonumber(n))/255 end
                songs[#songs+1]={id=id,path=base,title=data.title:sub(1,64),artist=(data.artist or 'Unknown'):sub(1,64),bpm=bpm,duration=duration,color=#color==3 and color or {0.4,0.8,1},icon=data.icon=='pico' and 'pico' or data.icon=='dad' and 'dad' or 'bf',description=data.description or '',order=tonumber(data.order) or 99,preview=tonumber(data.preview) or 8}
            else errors[#errors+1]=id..': invalid metadata or missing music.ogg' end
        end
    end
    table.sort(songs,function(a,b) return a.order==b.order and a.id<b.id or a.order<b.order end)
    return songs,errors
end
function C.load(song,difficulty)
    local key=song.path..difficulty
    if C.cache[key] then return C.cache[key] end
    local text=love.filesystem.read(song.path..difficulty..'.txt')
    if not text then return nil,'Missing '..difficulty..'.txt for '..song.title end
    local notes,err=C.chart(text,song.duration)
    if notes then C.cache[key]=notes end
    return notes,err
end
return C
