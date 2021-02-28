local class = require "libs.classic"

local _M = class:extend()

--- 构造函数
function _M:new(serviceName, ipv4, port)
    if not serviceName then
        return
    end
    self.serviceName = serviceName
    self.ipv4 = ipv4
    self.port = port
    return _M
end

function _M:property()
    local obj = table.new(0, 4)
    obj.serviceName = self.serviceName
    obj.ipv4 = self.ipv4 or ngx.var.server_addr
    obj.port = tonumber(ngx.var.server_port) or self.port
    return obj
end

return _M