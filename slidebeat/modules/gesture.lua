local G={}
G.__index=G
function G.new() return setmetatable({},G) end
function G:clear() self.id,self.x,self.y,self.armed=nil,nil,nil,false end
function G:press(id,x,y,cx,cy,center)
    if self.id or (x-cx)^2+(y-cy)^2>center^2 then return false end
    self.id,self.x,self.y,self.armed=id,x,y,true
    return true
end
function G:move(id,x,y,cx,cy,radius,center)
    if self.id~=id then return end
    local ox,oy=self.x-cx,self.y-cy
    local dx,dy=x-cx,y-cy
    local vx,vy=dx-ox,dy-oy
    local length=vx*vx+vy*vy
    local t=length==0 and 0 or math.max(0,math.min(1,-(ox*vx+oy*vy)/length))
    if (ox+t*vx)^2+(oy+t*vy)^2<=center^2 then self.armed=true end
    self.x,self.y=x,y
    if self.armed and dx*dx+dy*dy>=radius*radius then
        self.armed=false
        if math.abs(dx)>math.abs(dy) then return dx<0 and 3 or 4 end
        return dy<0 and 1 or 2
    end
end
return G
