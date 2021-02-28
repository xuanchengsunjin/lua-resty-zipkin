local class = require "libs.classic"

local _M = class:extend()

function _M:new(hight)
    self.hight = hight 
end

function _M:IsEmpty()
    return self.hight == 0
end

function _M:String()
   return string.format("%016x", self.hight)
end

return _M