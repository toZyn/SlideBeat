local B={}
B.__index=B
local api=love
local pairs_=pairs
function B.new(owner)
    local self=setmetatable({context={owner=owner},originals={},wrappers={}},B)
    local context=self.context
    local function bind(name,after)
        local original=api[name]
        local wrapper=function(...)
            if original then original(...) end
            local target=context.owner
            if target then after(target,...) end
        end
        self.originals[name],self.wrappers[name]=original,wrapper
        api[name]=wrapper
    end
    bind('mousepressed',function(target,x,y,button,touch) if button==1 and not touch then target:press('mouse',x,y) end end)
    bind('mousemoved',function(target,x,y,dx,dy,touch) if not touch then target:move('mouse',x,y) end end)
    bind('mousereleased',function(target,x,y,button,touch) if button==1 and not touch then target:release('mouse',x,y) end end)
    bind('touchpressed',function(target,id,x,y) target:press(id,x,y) end)
    bind('touchmoved',function(target,id,x,y) target:move(id,x,y) end)
    bind('touchreleased',function(target,id,x,y) target:release(id,x,y) end)
    return self
end
function B:close()
    self.context.owner=nil
    for name,wrapper in pairs_(self.wrappers) do
        if api[name]==wrapper then api[name]=self.originals[name] end
    end
    self.wrappers,self.originals={},{}
end
return B
