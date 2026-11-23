local id=SCRIPT_PATH:match('/([^/]+)/global%.lua/?$')
local controller
function init()
    if type(requireAddon)~='function' then error('SlideBeat requires a current Light-Engine build with native addon modules') end
    if not id then error('SlideBeat must be installed inside its own addon directory') end
    controller=requireAddon(id,'integration').new(id)
    local instance=controller
    script.closeCallback:add(function() instance:dispose() end)
end
function preStateEnter(nextState)
    if controller then controller:beforeState(nextState) end
end
function update(dt)
    if controller then controller:update(dt) end
end
