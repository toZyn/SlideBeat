local S={settings={music=0.8,sfx=0.55,offset=0,dim=0.82,motion=1,hitsound=1,radius=1,fullscreen=0},records={}}
function S.load()
    local text=love.filesystem.read('profile.txt') or ''
    for line in text:gmatch('[^\r\n]+') do
        local key,n=line:match('^setting ([%w_]+) ([-%d%.]+)$')
        n=tonumber(n)
        if key and S.settings[key]~=nil and n and n==n then S.settings[key]=n end
        local id,diff,score,accuracy,combo=line:match('^record ([%w_-]+) (%w+) (%d+) ([%d%.]+) (%d+)$')
        if id then S.records[id..':'..diff]={score=tonumber(score),accuracy=tonumber(accuracy),combo=tonumber(combo)} end
    end
    for _,k in ipairs({'music','sfx','dim','motion','hitsound','fullscreen'}) do S.settings[k]=math.max(0,math.min(1,S.settings[k])) end
    S.settings.offset=math.max(-0.3,math.min(0.3,S.settings.offset))
    S.settings.radius=math.max(0.75,math.min(1.2,S.settings.radius))
end
function S.write()
    local lines={}
    for k,v in pairs(S.settings) do lines[#lines+1]='setting '..k..' '..v end
    for key,r in pairs(S.records) do
        local id,diff=key:match('^([^:]+):(.+)$')
        lines[#lines+1]=string.format('record %s %s %d %.4f %d',id,diff,r.score,r.accuracy,r.combo)
    end
    local data=table.concat(lines,'\n')..'\n'
    local old=love.filesystem.read('profile.txt')
    if old then love.filesystem.write('profile.backup.txt',old) end
    local ok,err=love.filesystem.write('profile.txt',data)
    S.error=not ok and tostring(err) or nil
    return ok
end
function S.record(id,diff,score,accuracy,combo)
    local key=id..':'..diff
    local old=S.records[key]
    local better=not old or score>old.score or score==old.score and accuracy>old.accuracy
    if better then S.records[key]={score=score,accuracy=accuracy,combo=combo} S.write() end
    return better
end
return S
