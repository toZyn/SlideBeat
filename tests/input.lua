local now, playing, touches, strokes = 0, false, 0, 0
local source = {}
function source:play() playing=true end
function source:pause() playing=false end
function source:stop() playing=false now=0 end
function source:tell() return now end
function source:isPlaying() return playing end
function source:setVolume() end
local noop=function() end
love={graphics={},filesystem={},audio={},timer={},event={}}
for _,name in ipairs({'setBackgroundColor','setFont','setColor','printf','rectangle','push','translate','rotate','polygon','pop','circle','setLineWidth','line'}) do love.graphics[name]=noop end
function love.graphics.getDimensions() return 1000,760 end
function love.graphics.getWidth() return 1000 end
function love.graphics.newFont(size) return {getHeight=function() return size end} end
function love.filesystem.read() return nil end
function love.filesystem.write() return true end
function love.audio.newSource() return source end
function love.timer.getTime() return 0 end
love.event.quit=noop
local rhythm=require('rhythm')
local hit=rhythm.hit
rhythm.hit=function(...) strokes=strokes+1 return hit(...) end
require('main')
love.load()
love.draw()
love.keypressed('space')
love.draw()
now=4
love.mousepressed(500,402.8,1,false)
love.mousemoved(500,220,0,0,false)
assert(strokes==1,'center-to-up must trigger')
love.mousemoved(500,210,0,0,false)
assert(strokes==1,'holding outside must not retrigger')
now=4.5
love.mousemoved(500,402.8,0,0,false)
love.mousemoved(700,402.8,0,0,false)
assert(strokes==2,'return must rearm')
love.mousereleased(700,402.8,1,false)
love.mousepressed(700,402.8,1,false)
love.mousemoved(500,200,0,0,false)
assert(strokes==2,'outside press must not arm')
love.touchpressed('a',500,402.8)
love.touchmoved('b',500,200)
assert(strokes==2,'second finger must not control')
love.mousemoved(500,200,0,0,true)
assert(strokes==2,'synthetic mouse must be ignored')
now=5
love.touchmoved('a',500,600)
assert(strokes==3,'touch must trigger')
love.focus(false)
assert(not playing,'focus loss must pause')
love.touchmoved('a',500,402.8)
love.touchmoved('a',300,402.8)
assert(strokes==3)
love.draw()
love.keypressed('space')
assert(playing)
love.touchmoved('a',300,402.8)
assert(strokes==3,'resume must clear held pointer')
love.touchpressed('c',500,402.8)
love.resize()
love.touchmoved('c',300,402.8)
assert(strokes==3,'resize must clear gesture')
now=45
love.update(0.01)
love.draw()
assert(not playing,'results must stop audio')
love.keypressed('escape')
love.draw()
love.mousepressed(500,520,1,false)
love.draw()
love.keypressed('escape')
love.draw()
love.keypressed('space')
now=10
love.update(0.01)
now,playing=0,false
love.update(0.01)
love.draw()
love.keypressed('space')
assert(playing,'audio end must reach results, allowing replay')
print('PASS: mouse, touch, rearming, focus, resize, results and screens')
