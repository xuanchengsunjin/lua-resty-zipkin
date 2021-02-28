local class = require "libs.classic"
local util = require "libs.opentrace.util"

local _M = class:extend()

--- 构造函数
function _M:new(value, endpoint, timestamp)
    self.value = value
    self.endpoint = endpoint
    self.timestamp = timestamp or util.get_timestamp_now()
end

function _M:property()
    local obj = table.new(0, 3)
    obj.value = self.value
    obj.timestamp = self.timestamp
    obj.endpoint = self.endpoint:property()
end

return _M