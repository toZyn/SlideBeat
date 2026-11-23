local U=require('core.ui')
local A=require('core.assets')
local M={}
function M:draw(app)
    U.background({0.8,0.55,0.9},0.88)
    U.header('CREDITS','SlideBeat 2.0.0',function() app:switch('menu') end)
    U.panel(26,132,U.w-52,U.h-220)
    A.icon('bf',U.w/2,205,100)
    U.center('ZYN',280,40,{0.4,0.85,1})
    U.center('Game creator / direction',330,18)
    U.center('LIGHT-ENGINE',398,28)
    U.center('Menu backgrounds, arrow atlas, countdown,\nratings, icons, font and menu sound effects.',440,18,{0.7,0.8,0.9})
    U.center("The Funkin' Crew Inc.\nThe FNF LOVE Authors",526,18)
    U.center('Original SlideBeat music and charts\ncreated for this project.',600,14,{0.7,0.8,0.9})
    U.center('Asset origins and original terms: assets/light/',U.h-54,14,{0.6,0.7,0.8})
end
function M:back(app) app:switch('menu') end
return M
