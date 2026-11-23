function love.conf(t)
    t.identity = 'slidebeat-v2'
    t.version = '11.5'
    t.window.title = 'SlideBeat'
    t.window.width = 1120
    t.window.height = 800
    t.window.resizable = true
    t.window.minwidth = 360
    t.window.minheight = 640
    t.window.highdpi = true
    t.window.vsync = 1
    t.modules.physics = false
    t.modules.video = false
end
