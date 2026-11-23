local U=require('core.ui')
local S=require('core.save')
local A=require('core.assets')
local M={}
local rows={
    {'MUSIC VOLUME','music',0,1,0.1},
    {'SOUND VOLUME','sfx',0,1,0.1},
    {'TIMING OFFSET','offset',-0.3,0.3,0.01},
    {'BACKGROUND DIM','dim',0.4,1,0.05},
    {'PLAYFIELD SIZE','radius',0.75,1.2,0.05},
    {'ANIMATIONS','motion',0,1,1},
    {'HIT SOUNDS','hitsound',0,1,1}
}
function M:enter() self.row=1 end
function M:adjust(index,delta)
    local r=rows[index]
    S.settings[r[2]]=math.max(r[3],math.min(r[4],S.settings[r[2]]+delta*r[5]))
    if A.current then A.current:setVolume(S.settings.music) end
    S.write()
end
function M:draw(app)
    U.background({0.45,0.65,1},0.88)
    U.header('SETTINGS','Saved automatically',function() app:switch('menu') end)
    for i,r in ipairs(rows) do
        local y=122+(i-1)*69
        local value=S.settings[r[2]]
        local label=r[2]=='offset' and string.format('%+d ms',math.floor(value*1000+0.5)) or r[5]==1 and (value==1 and 'ON' or 'OFF') or math.floor(value*100+0.5)..'%'
        U.panel(26,y,U.w-52,58)
        U.text(r[1],42,y+10,14,i==self.row and {0.4,0.85,1} or nil,U.w-200)
        U.text(label,42,y+30,18,nil,U.w-200)
        U.button('-',U.w-150,y+7,48,44,function() self.row=i self:adjust(i,-1) end)
        U.button('+',U.w-92,y+7,48,44,function() self.row=i self:adjust(i,1) end)
    end
    U.center('Positive offset: gesture later than the audio beat.\nUse the same headphones while calibrating.',622,14,{0.65,0.75,0.88})
    U.button('TAP CALIBRATION',26,U.h-82,U.w-52,54,function() app:switch('calibration') end)
end
function M:key(app,k)
    if k=='up' then self.row=(self.row-2)%#rows+1
    elseif k=='down' then self.row=self.row%#rows+1
    elseif k=='left' then self:adjust(self.row,-1)
    elseif k=='right' then self:adjust(self.row,1)
    else return false end
    return true
end
function M:back(app) S.write() app:switch('menu') end
return M
