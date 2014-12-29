--[[--
Metaball implementation for LUA by Dark
For bruteforce usage, nor efficient nor fast

Force scales to from inf to 1 at R
--]]--
local _M = {}
local sqrt = math.sqrt
local cos = math.cos
local sin = math.sin
local abs = math.abs
local zero_value = 0x80000000

--Classic ball
local MetaBall = {x=0, y=0, radius=0, goo=1, type="MetaBall"}
MetaBall.__index = MetaBall
_M.MetaBall=MetaBall

function MetaBall:new(x, y, radius, goo)
  goo = goo or 1
  return setmetatable({x=x, y=y, radius=radius, goo=goo}, MetaBall)
end

function MetaBall:force(x, y)
  --Calculate force at point x y
  local force = (sqrt( (x - self.x)^2 + (y - self.y)^2 ) )^self.goo
  if force == 0 then return zero_value end
  return self.radius/force
end

--Ellipse 
local MetaEllipse  = {x=0, y=0, radius=0, angle=0, x_scale=1, y_scale=1, type="MetaEllipse"}
MetaEllipse.__index = MetaEllipse
_M.MetaEllipse=MetaEllipse

function MetaEllipse:new(x, y, radius, angle, x_scale, y_scale, goo)
  angle = angle or 0
  x_scale = x_scale or 1
  y_scale = y_scale or 1
  goo = goo or 1
  return setmetatable({x=x, y=y, radius=radius, angle=angle, x_scale=x_scale^2, y_scale=y_scale^2, goo=goo}, MetaEllipse)
end

function MetaEllipse:force(x, y)
  --Calculate force at point x y
  local force = sqrt( (( (x - self.x)*cos(self.angle) + (y - self.y)*sin(self.angle) )^2)/(self.x_scale) + 
                      (( (y - self.y)*cos(self.angle) - (x - self.x)*sin(self.angle) )^2)/(self.y_scale) )^self.goo
  if force == 0 then return zero_value end
  return self.radius/force
end

--SquareBalls
local MetaSquare = {x=0, y=0, radius=0, angle=0, x_scale=1, y_scale=1, type="MetaSquare"}
MetaSquare.__index = MetaSquare
_M.MetaSquare=MetaSquare

function MetaSquare:new(x, y, radius, angle, x_scale, y_scale, goo)
  angle = angle or 0
  x_scale = x_scale or 1
  y_scale = y_scale or 1
  goo = goo or 1
  return setmetatable({x=x, y=y, radius=radius, angle=angle, x_scale=x_scale^2, y_scale=y_scale^2, goo=goo}, MetaSquare)
end

function MetaSquare:force(x, y)
  --Calculate force at point x y
  local force = ( abs( (x - self.x)*cos(self.angle) + (y - self.y)*sin(self.angle) )/self.x_scale + 
                  abs( (y - self.y)*cos(self.angle) - (x - self.x)*sin(self.angle) )/self.y_scale )^self.goo 
  if force == 0 then return zero_value end
  return self.radius/force
end

--Donuts
local MetaDonut = {x=0, y=0, radius=0, angle=0, x_scale=1, y_scale=1, type="MetaDonut"}
MetaDonut.__index = MetaDonut
_M.MetaDonut=MetaDonut

function MetaDonut:new(x, y, out_r, int_r, angle, x_scale, y_scale, goo)
  angle = angle or 0
  x_scale = x_scale or 1
  y_scale = y_scale or 1
  goo = goo or 1
  if int_r >= out_r then error("int_r >= out_r"); return; end
  local radius = (out_r - int_r)*0.5
  local radius2 = (radius2 + radius)*0.5
  return setmetatable({x=x, y=y, radius=radius, radius2=radius2, x_scale=x_scale^2, y_scale=y_scale^2, goo=goo}, MetaDonut)
end

function MetaDonut:force(x, y)
  --Calculate force at point x y
  local force = abs(self.radius2 - sqrt( (( (x - self.x)*cos(self.angle) + (y - self.y)*sin(self.angle) )^2)/(self.x_scale) + 
                                         (( (y - self.y)*cos(self.angle) - (x - self.x)*sin(self.angle) )^2)/(self.y_scale) )^self.goo)
  if force == 0 then return zero_value end
  return self.radius/force
  
end

return _M