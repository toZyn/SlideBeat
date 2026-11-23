local U=require('core.ui')
local A=require('core.assets')
local M={}
function M:enter(app) app:menuMusic() end
function M:draw(app)
    U.background({0.9,0.74,0.4},0.78)
    U.center('SLIDEBEAT',52,64)
    U.center('Find your flow.',126,18,{0.7,0.8,0.95})
    local width=math.min(480,U.w-64)
    local rows={{'MUSIC SELECT','select'},{'HOW TO PLAY','tutorial'},{'SETTINGS','settings'},{'RECORDS','records'},{'CREDITS','credits'}}
    for i,row in ipairs(rows) do
        local dest=row[2]
        U.button(row[1],(U.w-width)/2,198+(i-1)*78,width,60,function() app:switch(dest) end)
    end
    U.center(#app.songs..' tracks / 3 difficulties / mouse + touch',U.h-64,14,{0.72,0.8,0.9})
    U.center('UP / DOWN to navigate  -  ENTER to select',U.h-36,14,{0.5,0.6,0.7})
end
function M:back(app) app:switch('title') end
return M
