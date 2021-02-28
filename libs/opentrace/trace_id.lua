local class = require "libs.classic"

local _M = class:extend()

function _M:new(hight, low)
    self.hight = hight
    self.low = low
end

function _M:IsEmpty()
    return self.hight == 0 and self.low == 0
end

function _M:String()
    if self.low then
        return string.format("%016x%016x", self.hight, self.low)
    end
    return string.format("%016x", self.hight)
end

function _M:__tostring()
    if self.low then
        return string.format("%016x%016x", self.hight, self.low)
    end
    return string.format("%016x", self.hight)
end

return _M