local U=require('core.ui')
local E={}
function E:enter(app,message) self.message=message require('core.assets').stopMusic() end
function E:draw(app)
    U.background({0.9,0.4,0.45},0.9)
    U.header('CANNOT LOAD','The song or resource could not be opened.')
    U.panel(26,150,U.w-52,U.h-300)
    U.text(self.message,48,180,18,{1,0.7,0.7},U.w-96)
    U.button('RETURN TO MENU',26,U.h-100,U.w-52,56,function() app:switch('menu') end)
end
function E:back(app) app:switch('menu') end
return E
