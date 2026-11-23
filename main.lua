local App=require('core.app')
function love.load(args) App:load(args) end
function love.update(dt) App:update(dt) end
function love.draw() App:draw() end
function love.resize() App:resize() end
function love.keypressed(k,scan,repeatKey) App:key(k,repeatKey) end
function love.mousepressed(x,y,b,touch) if b==1 and not touch then App:press('mouse',x,y) end end
function love.mousemoved(x,y,dx,dy,touch) if not touch then App:move('mouse',x,y) end end
function love.mousereleased(x,y,b,touch) if b==1 and not touch then App:release('mouse',x,y) end end
function love.touchpressed(id,x,y) App:press(id,x,y) end
function love.touchmoved(id,x,y) App:move(id,x,y) end
function love.touchreleased(id,x,y) App:release(id,x,y) end
function love.wheelmoved(x,y) App:wheel(y) end
function love.focus(f) if not f then App:suspend() end end
function love.visible(v) if not v then App:suspend() end end
function love.lowmemory() collectgarbage('collect') end
function love.quit() require('core.save').write() end
